#pragma once

/// @file cache/base_mongo_cache.hpp
/// @brief @copybrief components::MongoCache

#include <cache/cache_statistics.hpp>
#include <cache/caching_component_base.hpp>
#include <cache/mongo_cache_type_traits.hpp>
#include <formats/bson/document.hpp>
#include <formats/bson/inline.hpp>
#include <formats/bson/value_builder.hpp>
#include <storages/mongo/operations.hpp>
#include <storages/mongo/options.hpp>

// Autogenerated
#include <storages/mongo_collections/collections.hpp>
#include <storages/mongo_collections/component.hpp>

namespace components {

// clang-format off

/// @brief %Base class for all caches polling mongo collection
///
/// You have to provide a traits class in order to use this.
/// All fields below (except for function overrides) are mandatory.
///
/// Example of traits for MongoCache:
///
/// ```
/// struct MongoCacheTraitsExample {
///   // Component name for component
///   static constexpr auto kName = "mongo-taxi-config";
///
///   // Collection to read from
///   static constexpr auto kMongoCollectionsField =
///       &storages::mongo::Collections::config;
///   // Update field name to use for incremental update (optional).
///   // When missing, incremental update is disabled.
///   // Please use reference here to avoid global variables
///   // initialization order issues.
///   static constexpr const std::string& kMongoUpdateFieldName =
///       mongo::db::taxi::config::kUpdated;
///
///   // Cache element type
///   using ObjectType = CachedObject;
///   // Cache element field name that is used as an index in the cache map
///   static constexpr auto kKeyField = &CachedObject::name;
///   // Type of kKeyField
///   using KeyType = std::string;
///   // Type of cache map, e.g. unordered_map, map, bimap
///   using DataType = std::unordered_map<KeyType, ObjectType>;
///
///   // Whether the cache prefers to read from replica (if true, you might get stale data)
///   static constexpr bool kIsSecondaryPreferred = true;
///
///   // Optional function that overrides BSON to ObjectType conversion
///   static constexpr auto DeserializeObject = &CachedObject::FromBson;
///   // or
///   static ObjectType DeserializeObject(const formats::bson::Document& doc) {
///     return doc["value"].As<ObjectType>();
///   }
///   // (default implementation calls doc.As<ObjectType>())
///
///   // Optional function that overrides data retrieval operation
///   static storages::mongo::operations::Find GetFindOperation(
///       cache::UpdateType type,
///       const std::chrono::system_clock::time_point& last_update) {
///     mongo::operations::Find find_op({});
///     find_op.SetOption(mongo::options::Projection{"key", "value"});
///     return find_op;
///   }
///   // (default implementation queries kMongoUpdateFieldName: {$gt: last_update}
///   // for incremental updates)
///
///   // Whether update part of the cache even if failed to parse some documents
///   static constexpr bool kAreInvalidDocumentsSkipped = false;
/// };
/// ```

// clang-format on

template <class MongoCacheTraits>
class MongoCache
    : public CachingComponentBase<typename MongoCacheTraits::DataType> {
 public:
  static constexpr const char* kName = MongoCacheTraits::kName;

  MongoCache(const ComponentConfig&, const ComponentContext&);

  ~MongoCache();

 private:
  void Update(cache::UpdateType type,
              const std::chrono::system_clock::time_point& last_update,
              const std::chrono::system_clock::time_point& now,
              cache::UpdateStatisticsScope& stats_scope) override;

  typename MongoCacheTraits::ObjectType DeserializeObject(
      const formats::bson::Document& doc) const;

  storages::mongo::operations::Find GetFindOperation(
      cache::UpdateType type,
      const std::chrono::system_clock::time_point& last_update);

  std::shared_ptr<typename MongoCacheTraits::DataType> GetData(
      cache::UpdateType type);

  storages::mongo::CollectionsPtr mongo_collections_;
  storages::mongo::Collection* mongo_collection_;
};

template <class MongoCacheTraits>
MongoCache<MongoCacheTraits>::MongoCache(const ComponentConfig& config,
                                         const ComponentContext& context)
    : CachingComponentBase<typename MongoCacheTraits::DataType>(
          config, context, MongoCacheTraits::kName) {
  [[maybe_unused]] mongo_cache::impl::CheckTraits<MongoCacheTraits>
      check_traits;

  if (CachingComponentBase<
          typename MongoCacheTraits::DataType>::AllowedUpdateTypes() ==
          cache::AllowedUpdateTypes::kFullAndIncremental &&
      !mongo_cache::impl::kHasUpdateFieldName<MongoCacheTraits> &&
      !mongo_cache::impl::kHasFindOperation<MongoCacheTraits>) {
    throw std::logic_error(
        "Incremental update support is requested in config but no update field "
        "name is specified in traits of '" +
        config.Name() + "' cache");
  }

  auto& mongo_component = context.FindComponent<components::MongoCollections>();
  mongo_collections_ = mongo_component.GetCollections();
  mongo_collection_ =
      &((*mongo_collections_).*MongoCacheTraits::kMongoCollectionsField);

  // TODO: update CacheConfig from TaxiConfig

  this->StartPeriodicUpdates();
}

template <class MongoCacheTraits>
MongoCache<MongoCacheTraits>::~MongoCache() {
  this->StopPeriodicUpdates();
}

template <class MongoCacheTraits>
void MongoCache<MongoCacheTraits>::Update(
    cache::UpdateType type,
    const std::chrono::system_clock::time_point& last_update,
    const std::chrono::system_clock::time_point& /*now*/,
    cache::UpdateStatisticsScope& stats_scope) {
  namespace sm = storages::mongo;

  auto* collection = mongo_collection_;
  auto find_op = GetFindOperation(type, last_update);
  auto cursor = collection->Execute(find_op);
  if (type == cache::UpdateType::kIncremental && !cursor) {
    // Don't touch the cache at all
    LOG_INFO() << "No changes in cache " << MongoCacheTraits::kName;
    stats_scope.FinishNoChanges();
    return;
  }

  auto new_cache = GetData(type);
  for (const auto& doc : cursor) {
    stats_scope.IncreaseDocumentsReadCount(1);

    try {
      auto object = DeserializeObject(doc);
      auto key = (object.*MongoCacheTraits::kKeyField);

      if (type == cache::UpdateType::kIncremental ||
          new_cache->count(key) == 0) {
        (*new_cache)[key] = std::move(object);
      } else {
        LOG_ERROR() << "Found duplicate key for 2 items in cache "
                    << MongoCacheTraits::kName << ", key=" << key;
      }
    } catch (const std::exception& e) {
      LOG_ERROR() << "Failed to deserialize cache item of cache "
                  << MongoCacheTraits::kName
                  << ", _id=" << doc["_id"].template ConvertTo<std::string>()
                  << ", what(): " << e;
      stats_scope.IncreaseDocumentsParseFailures(1);

      if (!MongoCacheTraits::kAreInvalidDocumentsSkipped) throw;
    }
  }

  this->Set(new_cache);
  stats_scope.Finish(new_cache->size());
}

template <class MongoCacheTraits>
typename MongoCacheTraits::ObjectType
MongoCache<MongoCacheTraits>::DeserializeObject(
    const formats::bson::Document& doc) const {
  if constexpr (mongo_cache::impl::kHasDeserializeObject<MongoCacheTraits>) {
    return MongoCacheTraits::DeserializeObject(doc);
  } else {
    return doc.As<typename MongoCacheTraits::ObjectType>();
  }
}

template <class MongoCacheTraits>
storages::mongo::operations::Find
MongoCache<MongoCacheTraits>::GetFindOperation(
    cache::UpdateType type,
    const std::chrono::system_clock::time_point& last_update) {
  namespace bson = formats::bson;
  namespace sm = storages::mongo;

  auto find_op = [&]() -> sm::operations::Find {
    if constexpr (mongo_cache::impl::kHasFindOperation<MongoCacheTraits>) {
      return MongoCacheTraits::GetFindOperation(type, last_update);
    } else {
      bson::ValueBuilder query_builder(bson::ValueBuilder::Type::kObject);
      if constexpr (mongo_cache::impl::kHasUpdateFieldName<MongoCacheTraits>) {
        if (type == cache::UpdateType::kIncremental) {
          query_builder[MongoCacheTraits::kMongoUpdateFieldName] =
              bson::MakeDoc("$gt", last_update);
        }
      }
      return sm::operations::Find(query_builder.ExtractValue());
    }
  }();

  if (MongoCacheTraits::kIsSecondaryPreferred) {
    find_op.SetOption(sm::options::ReadPreference::kSecondaryPreferred);
  }
  return find_op;
}

template <class MongoCacheTraits>
std::shared_ptr<typename MongoCacheTraits::DataType>
MongoCache<MongoCacheTraits>::GetData(cache::UpdateType type) {
  if (type == cache::UpdateType::kIncremental)
    return std::make_shared<typename MongoCacheTraits::DataType>(*this->Get());
  else
    return std::make_shared<typename MongoCacheTraits::DataType>();
}

}  // namespace components
