# AUTOGENERATED, DON'T CHANGE THIS FILE!

if (NOT Hiredis_FIND_VERSION OR Hiredis_FIND_VERSION VERSION_LESS 0.13.3)
    set(Hiredis_FIND_VERSION 0.13.3)
endif()

if (NOT USERVER_CHECK_PACKAGE_VERSIONS)
  unset(Hiredis_FIND_VERSION)
endif()

if (TARGET Hiredis)
  if (NOT Hiredis_FIND_VERSION)
      set(Hiredis_FOUND ON)
      return()
  endif()

  if (Hiredis_VERSION)
      if (Hiredis_FIND_VERSION VERSION_LESS_EQUAL Hiredis_VERSION)
          set(Hiredis_FOUND ON)
          return()
      else()
          message(FATAL_ERROR
              "Already using version ${Hiredis_VERSION} "
              "of Hiredis when version ${Hiredis_FIND_VERSION} "
              "was requested."
          )
      endif()
  endif()
endif()

set(FULL_ERROR_MESSAGE "Could not find `Hiredis` package.\n\tDebian: sudo apt update && sudo apt install libhiredis-dev\n\tMacOS: brew install hiredis\n\tFedora: sudo dnf install hiredis-devel")


include(FindPackageHandleStandardArgs)

find_library(Hiredis_LIBRARIES_hiredis
  NAMES hiredis
)
list(APPEND Hiredis_LIBRARIES ${Hiredis_LIBRARIES_hiredis})

find_path(Hiredis_INCLUDE_DIRS_hiredis_hiredis_h
  NAMES hiredis/hiredis.h
)
list(APPEND Hiredis_INCLUDE_DIRS ${Hiredis_INCLUDE_DIRS_hiredis_hiredis_h})



if (Hiredis_VERSION)
  set(Hiredis_VERSION ${Hiredis_VERSION})
endif()

if (Hiredis_FIND_VERSION AND NOT Hiredis_VERSION)
  include(DetectVersion)

  if (UNIX AND NOT APPLE)
    deb_version(Hiredis_VERSION libhiredis-dev)
    rpm_version(Hiredis_VERSION hiredis-devel)
  endif()
  if (APPLE)
    brew_version(Hiredis_VERSION hiredis)
  endif()
endif()

 
find_package_handle_standard_args(
  Hiredis
    REQUIRED_VARS
      Hiredis_LIBRARIES
      Hiredis_INCLUDE_DIRS
      
    FAIL_MESSAGE
      "${FULL_ERROR_MESSAGE}"
)
mark_as_advanced(
  Hiredis_LIBRARIES
  Hiredis_INCLUDE_DIRS
  
)

if (NOT Hiredis_FOUND)
  if (Hiredis_FIND_REQUIRED)
      message(FATAL_ERROR "${FULL_ERROR_MESSAGE}. Required version is at least ${Hiredis_FIND_VERSION}")
  endif()

  return()
endif()

if (Hiredis_FIND_VERSION)
  if (Hiredis_VERSION VERSION_LESS Hiredis_FIND_VERSION)
      message(STATUS
          "Version of Hiredis is '${Hiredis_VERSION}'. "
          "Required version is at least '${Hiredis_FIND_VERSION}'. "
          "Ignoring found Hiredis."
          "Note: Set -DUSERVER_CHECK_PACKAGE_VERSIONS=0 to skip package version checks if the package is fine."
      )
      set(Hiredis_FOUND OFF)
      return()
  endif()
endif()

 
if (NOT TARGET Hiredis)
  add_library(Hiredis INTERFACE IMPORTED GLOBAL)

  target_include_directories(Hiredis INTERFACE ${Hiredis_INCLUDE_DIRS})
  target_link_libraries(Hiredis INTERFACE ${Hiredis_LIBRARIES})
  
  # Target Hiredis is created
endif()

if (Hiredis_VERSION)
  set(Hiredis_VERSION "${Hiredis_VERSION}" CACHE STRING "Version of the Hiredis")
endif()
