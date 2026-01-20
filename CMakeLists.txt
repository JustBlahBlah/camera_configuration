cmake_minimum_required(VERSION 3.10)

if(WIN32)
    set(VCPKG_TARGET_TRIPLET "x64-windows-static" CACHE STRING "" FORCE)
endif()

project(CameraConfigurator)

set(CMAKE_CXX_STANDARD 17)

find_package(libssh CONFIG REQUIRED)

add_executable(cameraconfig src/main.cpp)

if(TARGET ssh::ssh)
    target_link_libraries(cameraconfig PRIVATE ssh::ssh)
elseif(TARGET ssh)
    target_link_libraries(cameraconfig PRIVATE ssh)
else()
    message(FATAL_ERROR "libssh found, but target name is unknown!")
endif()
