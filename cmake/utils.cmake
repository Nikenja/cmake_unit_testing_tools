include(CMakeParseArguments)

set(UNIT_TESTING_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin")
message(STATUS "Output directory: ${UNIT_TESTING_OUTPUT_DIR}")

set(UNIT_TESTING_LIBRARY_DIR "${UNIT_TESTING_OUTPUT_DIR}") 
set(UNIT_TESTING_BINARY_DIR "${UNIT_TESTING_OUTPUT_DIR}")
set(UNIT_TESTING_FILE_DIR "${UNIT_TESTING_OUTPUT_DIR}")
set(UNIT_TESTING_FILE_PATH "${UNIT_TESTING_FILE_DIR}/")

set(UNIT_TESTING_DEFINITIONS
    "UNIT_TESTING"
    "UNIT_TESTING_FILE_PATH=\"${UNIT_TESTING_FILE_PATH}\""
)

set(UNIT_TESTING_ENABLED true)

# копирует файлы, которые необходимы для теста
function(add_unit_files test)
    foreach(data_file ${ARGN})
        add_custom_target(
            ${test}_${data_file}
            DEPENDS "${UNIT_TESTING_FILE_DIR}/${data_file}"
        )
        add_custom_command(
            OUTPUT "${UNIT_TESTING_FILE_DIR}/${data_file}"
            COMMAND cp -f "${CMAKE_CURRENT_SOURCE_DIR}/${data_file}" "${UNIT_TESTING_FILE_DIR}/${data_file}" || true
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${data_file}"
        )
        add_dependencies(${test} ${test}_${data_file})
    endforeach(data_file)
endfunction(add_unit_files)

# задает выходные каталоги для библиотек и исполняемых файлов
function(add_output_dirs target)
    set_target_properties(${target}
        PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${UNIT_TESTING_LIBRARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${UNIT_TESTING_LIBRARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${UNIT_TESTING_BINARY_DIR}"
    )
endfunction(add_output_dirs)

# задает опции компиляции
function(add_unit_def target)
    if("${ARGN}" STREQUAL "")
        set(DEFINITIONS "${UNIT_TESTING_DEFINITIONS}")
    else()
        set(DEFINITIONS "${ARGN}")
    endif()
    set_target_properties(${target} PROPERTIES COMPILE_DEFINITIONS "${DEFINITIONS}")
endfunction(add_unit_def)

# добавляет исполняемый таргет
function(add_unit_exe_target exe)
    set(SRCS ${exe}.cpp ${ARGN})
    add_executable(${exe} ${SRCS})
endfunction(add_unit_exe_target)

# добавляет таргет библиотеки с заданным типом (STATIC или SHARED)
function(add_unit_lib_target lib type)
    add_library(${lib} ${type} ${ARGN})
endfunction(add_unit_lib_target)

# добавляет исполняемый таргет, апгументами можно задать:
# исходные файлы, библиотеки для линковки, опции компиляции
function(add_unit_exe exe)
    set(multiValueArgs SRCS LINK DEF)
    cmake_parse_arguments(ARG "" "" "${multiValueArgs}" ${ARGN})

    add_unit_exe_target(${exe} ${ARG_SRCS})
    add_unit_def(${exe} ${ARG_DEF})
    add_output_dirs(${exe})

    target_link_libraries(${exe} ${ARG_LINK})
endfunction(add_unit_exe)

# добавляет библиотеку, агрументами можно задать:
# исходные файлы, библиотеки для линковки, опции компиляции, тип библиотеки
function(add_unit_lib lib)
    set(multiValueArgs SRCS LINK DEF TYPE)
    cmake_parse_arguments(ARG "" "" "${multiValueArgs}" ${ARGN})

    add_unit_lib_target(${lib} ${ARG_TYPE} ${ARG_SRCS})
    add_unit_def(${lib} ${ARG_DEF})
    add_output_dirs(${lib})

    target_link_libraries(${lib} ${ARG_LINK})
endfunction(add_unit_lib)

# добавляет тест, агрументами можно задать:
# исходные файлы, библиотеки для линковки, файлы для теста, опции компиляции
function(add_unit_test test)
    set(multiValueArgs SRCS LINK COPY DEF)
    cmake_parse_arguments(ARG "" "" "${multiValueArgs}" ${ARGN})
    # добавляем тест
    add_unit_exe(${test} SRCS ${ARG_SRCS} LINK ${ARG_LINK} DEF ${ARG_DEF})
    add_test(NAME ${test} COMMAND ${test} WORKING_DIRECTORY ${UNIT_TESTING_BINARY_DIR})
    add_unit_files(${test} ${ARG_COPY})

    target_link_libraries(${test}
        GTest::gmock
        GTest::gmock_main
        Boost::unit_test_framework
    )
endfunction(add_unit_test)

# добавляет тестовые подпроекты модулей. каталог модуля должен
# содержать каталог tests с файлом CMakeLists.txt
function(add_modules_tests modules_dirs)
    foreach(module_dir ${modules_dirs})
        get_filename_component(module_name ${module_dir} NAME)
        add_subdirectory("${module_dir}/tests" "${UNIT_TESTING_BUILD_DIR}/${module_name}")
    endforeach()
endfunction(add_modules_tests)
