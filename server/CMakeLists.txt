cmake_minimum_required(VERSION 3.16)
project(kapai_server_compat CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB SERVER_SRC CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/tinyxml/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/gyu/*.cpp"
)

add_executable(kapai ${SERVER_SRC})

if(MSVC)
    target_compile_options(kapai PRIVATE /utf-8 /FS)
    target_link_options(kapai PRIVATE /STACK:67108864)
    target_compile_options(kapai PRIVATE /FI"${CMAKE_CURRENT_SOURCE_DIR}/src/win_compat.h")
    target_compile_definitions(kapai PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX _WINSOCKAPI_ _WINSOCK_DEPRECATED_NO_WARNINGS)
endif()

target_include_directories(kapai PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/tinyxml"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/gyu"
    "${CMAKE_CURRENT_SOURCE_DIR}/../client/ProjectX/frameworks/cocos2d-x/external/zlib/include"
)

set(DEFAULT_LUA_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../client/ProjectX/frameworks/cocos2d-x/external/lua/luajit/include")
set(DEFAULT_LUA_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/../client/ProjectX/frameworks/cocos2d-x/external/lua/luajit/prebuilt/win32/lua51.lib")

set(BOOST_ROOT "" CACHE PATH "Boost root directory")
find_package(Boost REQUIRED COMPONENTS thread system serialization)
target_link_libraries(kapai PRIVATE Boost::thread Boost::system Boost::serialization)

find_package(ZLIB QUIET)
if(ZLIB_FOUND)
    target_link_libraries(kapai PRIVATE ZLIB::ZLIB)
endif()

find_package(OpenSSL QUIET)
if(OpenSSL_FOUND)
    target_link_libraries(kapai PRIVATE OpenSSL::Crypto)
endif()

if(WIN32)
    target_link_libraries(kapai PRIVATE ws2_32)
else()
    target_link_libraries(kapai PRIVATE pthread)
endif()

# Set these manually if CMake cannot find your local MySQL and Lua packages.
set(MYSQL_INCLUDE_DIR "" CACHE PATH "MySQL include directory")
set(MYSQL_LIBRARY "" CACHE FILEPATH "MySQL client library")
set(SQLITE3_INCLUDE_DIR "" CACHE PATH "SQLite include directory")
set(SQLITE3_LIBRARY "" CACHE FILEPATH "SQLite static library")
set(LUA_INCLUDE_DIR "${DEFAULT_LUA_INCLUDE_DIR}" CACHE PATH "Lua include directory")
set(LUA_LIBRARY "${DEFAULT_LUA_LIBRARY}" CACHE FILEPATH "Lua library")
option(KAPAI_BUILD_DATABASE_SMOKE "Build the standalone database adapter smoke test" OFF)

if(MYSQL_INCLUDE_DIR)
    target_include_directories(kapai PRIVATE "${MYSQL_INCLUDE_DIR}")
endif()
if(MYSQL_LIBRARY)
    target_link_libraries(kapai PRIVATE "${MYSQL_LIBRARY}")
endif()
if(SQLITE3_INCLUDE_DIR AND SQLITE3_LIBRARY)
    target_include_directories(kapai PRIVATE "${SQLITE3_INCLUDE_DIR}")
    target_link_libraries(kapai PRIVATE "${SQLITE3_LIBRARY}")
    target_compile_definitions(kapai PRIVATE GYU_ENABLE_SQLITE=1)
endif()
if(LUA_INCLUDE_DIR)
    target_include_directories(kapai PRIVATE "${LUA_INCLUDE_DIR}")
endif()
if(LUA_LIBRARY)
    target_link_libraries(kapai PRIVATE "${LUA_LIBRARY}")
endif()

if(KAPAI_BUILD_DATABASE_SMOKE)
    if(NOT SQLITE3_INCLUDE_DIR OR NOT SQLITE3_LIBRARY)
        message(FATAL_ERROR "KAPAI_BUILD_DATABASE_SMOKE requires SQLITE3_INCLUDE_DIR and SQLITE3_LIBRARY")
    endif()
    add_executable(kapai_database_smoke
        "${CMAKE_CURRENT_SOURCE_DIR}/tests/database_smoke.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/gyu/g_database.cpp"
    )
    target_include_directories(kapai_database_smoke PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/gyu"
        "${MYSQL_INCLUDE_DIR}"
        "${SQLITE3_INCLUDE_DIR}"
    )
    target_compile_definitions(kapai_database_smoke PRIVATE GYU_ENABLE_SQLITE=1)
    target_link_libraries(kapai_database_smoke PRIVATE Boost::thread Boost::system "${MYSQL_LIBRARY}" "${SQLITE3_LIBRARY}")
    if(MSVC)
        target_compile_options(kapai_database_smoke PRIVATE /utf-8 /FS)
        target_compile_definitions(kapai_database_smoke PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
    endif()
endif()
