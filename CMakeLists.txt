cmake_minimum_required(VERSION 3.10)
project(CameraConfigurator)

set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(LIBSSH IMPORTED_TARGET libssh)
endif()

find_package(libssh QUIET)

add_executable(cameraconfig src/main.cpp)

if(TARGET ssh::ssh)
    target_link_libraries(cameraconfig PRIVATE ssh::ssh)
elseif(TARGET PkgConfig::LIBSSH)
    target_link_libraries(cameraconfig PRIVATE PkgConfig::LIBSSH)
else()
    target_link_libraries(cameraconfig PRIVATE ssh)
endif()
