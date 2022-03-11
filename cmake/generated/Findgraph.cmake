# AUTOGENERATED, DON'T CHANGE THIS FILE!


if (NOT USERVER_CHECK_PACKAGE_VERSIONS)
  unset(graph_FIND_VERSION)
endif()

if (TARGET graph)
  if (NOT graph_FIND_VERSION)
      set(graph_FOUND ON)
      return()
  endif()

  if (graph_VERSION)
      if (graph_FIND_VERSION VERSION_LESS_EQUAL graph_VERSION)
          set(graph_FOUND ON)
          return()
      else()
          message(FATAL_ERROR
              "Already using version ${graph_VERSION} "
              "of graph when version ${graph_FIND_VERSION} "
              "was requested."
          )
      endif()
  endif()
endif()

set(FULL_ERROR_MESSAGE "Could not find `graph` package.\n\tDebian: sudo apt update && sudo apt install libboost-graph-dev\n\tMacOS: brew install boost\n\tFedora: sudo dnf install boost-devel")


include(FindPackageHandleStandardArgs)

find_library(graph_LIBRARIES_boost_graph
  NAMES boost_graph
)
list(APPEND graph_LIBRARIES ${graph_LIBRARIES_boost_graph})

find_path(graph_INCLUDE_DIRS_boost_graph_astar_search_hpp
  NAMES boost/graph/astar_search.hpp
)
list(APPEND graph_INCLUDE_DIRS ${graph_INCLUDE_DIRS_boost_graph_astar_search_hpp})



if (graph_VERSION)
  set(graph_VERSION ${graph_VERSION})
endif()

if (graph_FIND_VERSION AND NOT graph_VERSION)
  include(DetectVersion)

  if (UNIX AND NOT APPLE)
    deb_version(graph_VERSION libboost-graph-dev)
    rpm_version(graph_VERSION boost-devel)
  endif()
  if (APPLE)
    brew_version(graph_VERSION boost)
  endif()
endif()

 
find_package_handle_standard_args(
  graph
    REQUIRED_VARS
      graph_LIBRARIES
      graph_INCLUDE_DIRS
      
    FAIL_MESSAGE
      "${FULL_ERROR_MESSAGE}"
)
mark_as_advanced(
  graph_LIBRARIES
  graph_INCLUDE_DIRS
  
)

if (NOT graph_FOUND)
  if (graph_FIND_REQUIRED)
      message(FATAL_ERROR "${FULL_ERROR_MESSAGE}. Required version is at least ${graph_FIND_VERSION}")
  endif()

  return()
endif()

if (graph_FIND_VERSION)
  if (graph_VERSION VERSION_LESS graph_FIND_VERSION)
      message(STATUS
          "Version of graph is '${graph_VERSION}'. "
          "Required version is at least '${graph_FIND_VERSION}'. "
          "Ignoring found graph."
          "Note: Set -DUSERVER_CHECK_PACKAGE_VERSIONS=0 to skip package version checks if the package is fine."
      )
      set(graph_FOUND OFF)
      return()
  endif()
endif()

 
if (NOT TARGET graph)
  add_library(graph INTERFACE IMPORTED GLOBAL)

  if (TARGET Boost::graph)
    target_link_libraries(graph INTERFACE Boost::graph)
  endif()
  target_include_directories(graph INTERFACE ${graph_INCLUDE_DIRS})
  target_link_libraries(graph INTERFACE ${graph_LIBRARIES})
  
  # Target graph is created
endif()

if (graph_VERSION)
  set(graph_VERSION "${graph_VERSION}" CACHE STRING "Version of the graph")
endif()
