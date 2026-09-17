cmake_minimum_required(VERSION 3.19)
get_filename_component(DOOM_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(QUARTUS_ROOT "C:/altera_lite/25.1std" CACHE PATH "Quartus installation")
set(DOOM_PYTHON "C:/Python314/python.exe" CACHE FILEPATH "Python interpreter")
set(DOOM_WAD "${DOOM_ROOT}/assets/freedoom-0.13.0/freedoom1.wad" CACHE FILEPATH "Game IWAD")
option(DOOM_FPS_OVERLAY "Include live FPS overlay" ON)
set(CMAKE_C_COMPILER "${QUARTUS_ROOT}/riscfree/toolchain/riscv32-unknown-elf/bin/riscv32-unknown-elf-gcc.exe")
set(CMAKE_ASM_COMPILER "${CMAKE_C_COMPILER}")
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
# Keep every IDE configuration at the validated optimization level.
set(CMAKE_C_FLAGS_DEBUG "")
set(CMAKE_C_FLAGS_RELEASE "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "")
set(CMAKE_C_FLAGS_MINSIZEREL "")
project(doom_fps_app LANGUAGES C ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(extra_args)
if(DOOM_FPS_OVERLAY)
    list(APPEND extra_args --fps)
endif()
# Reuse source preparation, patches, WAD validation and flags from the CLI build.
execute_process(COMMAND "${DOOM_PYTHON}" "${CMAKE_CURRENT_SOURCE_DIR}/prepare.py"
    --wad "${DOOM_WAD}" ${extra_args} --output "${CMAKE_CURRENT_BINARY_DIR}/doom-inputs.cmake"
    WORKING_DIRECTORY "${DOOM_ROOT}" RESULT_VARIABLE preparation_result)
if(NOT preparation_result EQUAL 0)
    message(FATAL_ERROR "DOOM source preparation failed; see output above")
endif()
include("${CMAKE_CURRENT_BINARY_DIR}/doom-inputs.cmake")
if(NOT EXISTS "${DOOM_ROOT}/build/bsp/make_build/libhal2_bsp.a")
    message(FATAL_ERROR "Build the project BSP first: python tools/build_hardware.py --bsp")
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/prepare.py"
    "${DOOM_ROOT}/tools/build_software.py" "${DOOM_ROOT}/tools/instrument_engine.py"
    "${DOOM_WAD}")
add_executable(doom ${DOOM_SOURCES})
set_target_properties(doom PROPERTIES SUFFIX ".elf" RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
target_compile_options(doom PRIVATE ${DOOM_FLAGS})
target_link_options(doom PRIVATE ${DOOM_FLAGS} "-Wl,--gc-sections" "-Wl,-Map,${CMAKE_CURRENT_BINARY_DIR}/doom.map")
target_link_libraries(doom PRIVATE ${DOOM_LIBS})
# Relink when the validated prebuilt HAL or linker script changes.
set_property(TARGET doom APPEND PROPERTY LINK_DEPENDS
    "${DOOM_ROOT}/build/bsp/make_build/libhal2_bsp.a" "${DOOM_ROOT}/build/bsp/linker.x")
