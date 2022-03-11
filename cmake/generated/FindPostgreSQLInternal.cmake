# AUTOGENERATED, DON'T CHANGE THIS FILE!


if (NOT USERVER_CHECK_PACKAGE_VERSIONS)
  unset(PostgreSQLInternal_FIND_VERSION)
endif()

if (TARGET PostgreSQLInternal)
  if (NOT PostgreSQLInternal_FIND_VERSION)
      set(PostgreSQLInternal_FOUND ON)
      return()
  endif()

  if (PostgreSQLInternal_VERSION)
      if (PostgreSQLInternal_FIND_VERSION VERSION_LESS_EQUAL PostgreSQLInternal_VERSION)
          set(PostgreSQLInternal_FOUND ON)
          return()
      else()
          message(FATAL_ERROR
              "Already using version ${PostgreSQLInternal_VERSION} "
              "of PostgreSQLInternal when version ${PostgreSQLInternal_FIND_VERSION} "
              "was requested."
          )
      endif()
  endif()
endif()

set(FULL_ERROR_MESSAGE "Could not find `PostgreSQLInternal` package.\n\tDebian: sudo apt update && sudo apt install libpq-dev postgresql-12 postgresql-server-dev-12\n\tMacOS: brew install postgres\n\tFedora: sudo dnf install postgresql-server-devel postgresql-static")


include(FindPackageHandleStandardArgs)

find_library(PostgreSQLInternal_LIBRARIES_libpq_a
  NAMES libpq.a
)
list(APPEND PostgreSQLInternal_LIBRARIES ${PostgreSQLInternal_LIBRARIES_libpq_a})
find_library(PostgreSQLInternal_LIBRARIES_libpgcommon_a
  NAMES libpgcommon.a
  PATHS /usr/lib/postgresql/12/lib /usr/lib/postgresql/13/lib /usr/lib/postgresql/14/lib
)
list(APPEND PostgreSQLInternal_LIBRARIES ${PostgreSQLInternal_LIBRARIES_libpgcommon_a})
find_library(PostgreSQLInternal_LIBRARIES_libpgport_a
  NAMES libpgport.a
  PATHS /usr/lib/postgresql/12/lib /usr/lib/postgresql/13/lib /usr/lib/postgresql/14/lib
)
list(APPEND PostgreSQLInternal_LIBRARIES ${PostgreSQLInternal_LIBRARIES_libpgport_a})

find_path(PostgreSQLInternal_INCLUDE_DIRS_postgres_fe_h
  NAMES postgres_fe.h
  PATH_SUFFIXES postgresql/internal pgsql/server
)
list(APPEND PostgreSQLInternal_INCLUDE_DIRS ${PostgreSQLInternal_INCLUDE_DIRS_postgres_fe_h})



if (PostgreSQLInternal_VERSION)
  set(PostgreSQLInternal_VERSION ${PostgreSQLInternal_VERSION})
endif()

if (PostgreSQLInternal_FIND_VERSION AND NOT PostgreSQLInternal_VERSION)
  include(DetectVersion)

  if (UNIX AND NOT APPLE)
    deb_version(PostgreSQLInternal_VERSION libpq-dev)
    rpm_version(PostgreSQLInternal_VERSION postgresql-server-devel)
  endif()
  if (APPLE)
    brew_version(PostgreSQLInternal_VERSION postgres)
  endif()
endif()

 
find_package_handle_standard_args(
  PostgreSQLInternal
    REQUIRED_VARS
      PostgreSQLInternal_LIBRARIES
      PostgreSQLInternal_INCLUDE_DIRS
      
    FAIL_MESSAGE
      "${FULL_ERROR_MESSAGE}"
)
mark_as_advanced(
  PostgreSQLInternal_LIBRARIES
  PostgreSQLInternal_INCLUDE_DIRS
  
)

if (NOT PostgreSQLInternal_FOUND)
  if (PostgreSQLInternal_FIND_REQUIRED)
      message(FATAL_ERROR "${FULL_ERROR_MESSAGE}. Required version is at least ${PostgreSQLInternal_FIND_VERSION}")
  endif()

  return()
endif()

if (PostgreSQLInternal_FIND_VERSION)
  if (PostgreSQLInternal_VERSION VERSION_LESS PostgreSQLInternal_FIND_VERSION)
      message(STATUS
          "Version of PostgreSQLInternal is '${PostgreSQLInternal_VERSION}'. "
          "Required version is at least '${PostgreSQLInternal_FIND_VERSION}'. "
          "Ignoring found PostgreSQLInternal."
          "Note: Set -DUSERVER_CHECK_PACKAGE_VERSIONS=0 to skip package version checks if the package is fine."
      )
      set(PostgreSQLInternal_FOUND OFF)
      return()
  endif()
endif()

 
if (NOT TARGET PostgreSQLInternal)
  add_library(PostgreSQLInternal INTERFACE IMPORTED GLOBAL)

  target_include_directories(PostgreSQLInternal INTERFACE ${PostgreSQLInternal_INCLUDE_DIRS})
  target_link_libraries(PostgreSQLInternal INTERFACE ${PostgreSQLInternal_LIBRARIES})
  
  # Target PostgreSQLInternal is created
endif()

if (PostgreSQLInternal_VERSION)
  set(PostgreSQLInternal_VERSION "${PostgreSQLInternal_VERSION}" CACHE STRING "Version of the PostgreSQLInternal")
endif()
