cmake_minimum_required(VERSION 3.25.0)

project(unit_testing)

get_filename_component(PROJECT_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.." REALPATH)
message(STATUS "Project root directory: ${PROJECT_ROOT_DIR}")

enable_testing()

set(UNIT_TESTING_BUILD_DIR "${CMAKE_BINARY_DIR}")
message(STATUS "Build directory: ${UNIT_TESTING_BUILD_DIR}")

include(cmake/utils.cmake)
include(cmake/boost.cmake)
include(cmake/gtest.cmake)

add_compile_definitions(UNIT_TESTING)

# список путей до корневых каталогов модулей, которые
# должны содержать каталог tests с файлом CMakeLists.txt
set(MODULES_DIRS)
add_modules_tests("${MODULES_DIRS}")
