#!/bin/bash

if 
    [[ $# -ne 1 ]]; 
then 
    echo "Please provide exactly one argument." 
    echo "Usage: ./create_cmake_project.sh <project_name>"
    exit 1
fi

PROJECT_NAME=$1
ROOT_CMAKE="cmake_minimum_required(VERSION 3.13)

##Project name and type
project($PROJECT_NAME)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES OFF)

##Define executables, libraries here with relative path
# add_library($PROJECT_NAME STATIC src/main.cpp)
add_executable($PROJECT_NAME src/main.cpp)

##Subdirectories which are part of the project
add_subdirectory(src)

##Compiler defines, options and features
# target_compile_features($PROJECT_NAME
#     PRIVATE
#         cxx_std_20
# )
# target_compile_options($PROJECT_NAME
#     PRIVATE
#         -Wall
# )
# target_compile_definitions($PROJECT_NAME
#      PRIVATE
#          foo
#  )

##Linker options, external libraries/objects to link against
# target_link_libraries($PROJECT_NAME
#      PRIVATE
#          blabla
#  )
# target_link_options($PROJECT_NAME
#      PRIVATE
#          blabla
#  )

##Set target properties
set_target_properties($PROJECT_NAME
    PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY \"\${CMAKE_BINARY_DIR}/bin\"
        ARCHIVE_OUTPUT_DIRECTORY \"\${CMAKE_BINARY_DIR}/lib\"
        LIBRARY_OUTPUT_DIRECTORY \"\${CMAKE_BINARY_DIR}/lib\"
)

##Helpful commands for various functionalities if needed
# find_package(Boost COMPONENTS filesystem system iostreams)

# if(\${CMAKE_SYSTEM_NAME} MATCHES \"Linux\")
# elseif(\${CMAKE_SYSTEM_NAME} MATCHES \"Windows\")
# endif()

# configure_file(\${CMAKE_SOURCE_DIR}/stocks.config \${CMAKE_BINARY_DIR}/bin/stocks.config)

# add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
#     COMMAND \${CMAKE_COMMAND} -E copy_if_different
#     \"\${PROJECT_SOURCE_DIR}/extern/lib/libcurl-x64.dll\"
#     $<TARGET_FILE_DIR:${PROJECT_NAME}>)

# FILE(READ \${CMAKE_SOURCE_DIR}/src/main.h main)
# STRING(REGEX REPLACE \"VERSION_MAJOR\ [0-9]*\" \"VERSION_MAJOR\ \${${PROJECT_NAME}_VERSION_MAJOR}\" main \"\${main}\")
# FILE(WRITE \${CMAKE_SOURCE_DIR}/src/main.h \"\${main}\")

# if(EXISTS \"\${CMAKE_SOURCE_DIR}/.git\" AND EXISTS \"\${CMAKE_SOURCE_DIR}/scripts/install_git_hooks.sh\")
#     execute_process(COMMAND bash -c \"\${CMAKE_SOURCE_DIR}/scripts/install_git_hooks.sh\" )
# endif()"

SRC_CMAKE="##Following subdirectories are part of the project
# add_subdirectory(blabla)

##All .h files in this directory are to be included
target_include_directories($PROJECT_NAME
    PRIVATE
        \${CMAKE_CURRENT_SOURCE_DIR}
)

##List here the source files in current directory (Good way to include sources)
target_sources($PROJECT_NAME
    PRIVATE
        main.cpp
)

##All .cpp files in this directory are source files (Quick and dirty way to include sources)
#file(GLOB SOURCES \"*.cpp\")
#target_sources($PROJECT_NAME PRIVATE \${SOURCES})"

mkdir -p $PROJECT_NAME
cd $PROJECT_NAME
echo "$ROOT_CMAKE" > CMakeLists.txt

mkdir -p build

mkdir -p src
cd src
echo "$SRC_CMAKE" > CMakeLists.txt
echo "" > main.cpp
