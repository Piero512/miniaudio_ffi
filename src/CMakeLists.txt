cmake_minimum_required(VERSION 3.4)
project(miniaudio C)
SET(CMAKE_CONFIGURATION_TYPES "Release;MinSizeRel")

add_library(miniaudio SHARED miniaudio.c)

target_compile_definitions(miniaudio PUBLIC MA_DLL=1 MA_IMPLEMENTATION=1 )