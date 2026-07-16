cmake_minimum_required(VERSION 3.16)
project(csb_dump LANGUAGES CXX)

if(NOT DEFINED COCOS2DX_ROOT)
    message(FATAL_ERROR "Set COCOS2DX_ROOT to client/ProjectX/frameworks/cocos2d-x")
endif()

add_executable(csb_dump csb_dump.cpp)
target_compile_features(csb_dump PRIVATE cxx_std_11)
target_include_directories(csb_dump PRIVATE
    "${COCOS2DX_ROOT}/external"
    "${COCOS2DX_ROOT}/cocos/editor-support/cocostudio"
)

if(MSVC)
    target_compile_options(csb_dump PRIVATE /W4 /EHsc /utf-8 /wd4244 /wd4267)
endif()
