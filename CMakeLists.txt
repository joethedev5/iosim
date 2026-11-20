cmake_minimum_required(VERSION 3.16)
project(iosim C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

add_executable(iosim-run
  loader/main.c
  loader/macho.c
  loader/fixups.c
  loader/symbols.c
  loader/shims.c
  loader/context.c
  loader/objc_runtime.c
  loader/start.S
)
target_include_directories(iosim-run PRIVATE loader)
target_compile_options(iosim-run PRIVATE -Wall -Wextra -Wno-unused-parameter)
target_link_libraries(iosim-run PRIVATE dl)
