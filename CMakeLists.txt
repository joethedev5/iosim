cmake_minimum_required(VERSION 3.16)
project(iosim C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

find_package(Freetype REQUIRED)

option(IOSIM_USE_ZIG_ASM "Build the TLV getter from Zig inline assembly" OFF)

add_executable(iosim-run
  loader/main.c
  loader/macho.c
  loader/fixups.c
  loader/symbols.c
  loader/shims.c
  loader/context.c
  loader/objc_runtime.c
  loader/framebuffer.c
  loader/events.c
  loader/services.c
  loader/image.c
  loader/pthread_compat.c
  loader/tlv.c
  loader/ccrypto.c
  loader/start.S
)
if(IOSIM_USE_ZIG_ASM)
  find_program(ZIG_EXECUTABLE NAMES zig)
  if(NOT ZIG_EXECUTABLE)
    message(FATAL_ERROR "IOSIM_USE_ZIG_ASM=ON requires zig on PATH (or -DZIG_EXECUTABLE=...)")
  endif()
  set(TLV_ZIG_OBJECT ${CMAKE_BINARY_DIR}/tlv_zig.o)
  add_custom_command(
    OUTPUT ${TLV_ZIG_OBJECT}
    COMMAND ${ZIG_EXECUTABLE} build-obj ${CMAKE_SOURCE_DIR}/loader/tlv.zig
            -target x86_64-linux-gnu -O ReleaseSmall
            -femit-bin=${TLV_ZIG_OBJECT}
    DEPENDS ${CMAKE_SOURCE_DIR}/loader/tlv.zig
    COMMENT "Building TLV getter with Zig inline assembly")
  add_custom_target(tlv_zig_object DEPENDS ${TLV_ZIG_OBJECT})
  target_sources(iosim-run PRIVATE ${TLV_ZIG_OBJECT})
  add_dependencies(iosim-run tlv_zig_object)
else()
  target_sources(iosim-run PRIVATE loader/tlv.S)
endif()

target_include_directories(iosim-run PRIVATE loader)
target_compile_options(iosim-run PRIVATE -Wall -Wextra -Wno-unused-parameter)
target_link_libraries(iosim-run PRIVATE dl m z png Freetype::Freetype)
