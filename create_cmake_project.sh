#!/bin/bash
# Author: Shedbalkar, Akshay (GH2)

#####################################################################################################################################
if 
    [[ $# -ne 1 ]]; 
then 
    echo "Please provide exactly one argument." 
    echo "Usage: ./create_cmake_project.sh <project_name>"
    exit 1
fi
PROJECT_NAME=$1

#####################################################################################################################################
echo ""
echo "Checking dependencies..."
ready=1
programs=("cmake" "gcc" "git" "clang-format")
for program in "${programs[@]}"
do
    which "$program" 1>/dev/null 2>/dev/null
    if [[ $? -eq 0 ]]; then
       echo "[x] $program" 
    else
        echo "[ ] $program"
        ready=0
    fi
done

if [[ ready -ne 1 ]]; then
    echo "Please install required programs."
    echo "Aborting!"
    exit 0
else
    echo "All dependencies satisfied."
    echo ""
fi

#####################################################################################################################################
ROOT_CMAKE="cmake_minimum_required(VERSION 3.13)

##Project name and type
project($PROJECT_NAME VERSION 0.1.0.0)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES OFF)
# set(CMAKE_C_INCLUDE_WHAT_YOU_USE include-what-you-use)

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

#Install git hooks correctly even in git submodules
execute_process(COMMAND git rev-parse --path-format=absolute --git-path hooks OUTPUT_VARIABLE hook_dir OUTPUT_STRIP_TRAILING_WHITESPACE)
configure_file(\"\${CMAKE_SOURCE_DIR}/config/git/pre-commit.in\" \"\${hook_dir}/pre-commit\" COPYONLY)
configure_file(\"\${CMAKE_SOURCE_DIR}/config/git/prepare-commit-msg.in\" \"\${hook_dir}/prepare-commit-msg\" COPYONLY)
configure_file(\"\${CMAKE_SOURCE_DIR}/config/cmake/version.h.in\" \"\${CMAKE_SOURCE_DIR}/src/version.h\")

#Generate Doxygen documentation with 'make doc'
find_package(Doxygen COMPONENTS dot)
if(DOXYGEN_FOUND)
    set(DOXYGEN_OUTPUT_DIRECTORY \"\${CMAKE_SOURCE_DIR}/doc\")
    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE \"README.md\")
    set(DOXYGEN_HAVE_DOT \"YES\")
    set(DOXYGEN_CALL_GRAPH \"YES\")
    set(DOXYGEN_CALLER_GRAPH \"YES\")
    doxygen_add_docs(
        doc
        \${CMAKE_SOURCE_DIR}
        )
endif()

# Ensure dependencies exist
# find_package(Boost COMPONENTS filesystem system iostreams)

# OS dependant compiler flags / tasks
# if(\${CMAKE_SYSTEM_NAME} MATCHES \"Linux\")
# elseif(\${CMAKE_SYSTEM_NAME} MATCHES \"Windows\")
# endif()

# Copy dynamic libraries to runtime directories
# add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
#     COMMAND \${CMAKE_COMMAND} -E copy_if_different
#     \"\${CMAKE_SOURCE_DIR}/extern/lib/libcurl-x64.dll\"
#     $<TARGET_FILE_DIR:${PROJECT_NAME}>)

# Update version numbers throughout the project
# FILE(READ \${CMAKE_SOURCE_DIR}/src/project.arxml version)
# STRING(REGEX REPLACE \"VERSION_MAJOR\ [0-9]*\" \"VERSION_MAJOR\ \${${PROJECT_NAME}_VERSION_MAJOR}\" version \"\${version}\")
# FILE(WRITE \${CMAKE_SOURCE_DIR}/src/project.arxml \"\${version}\")"

SRC_CMAKE="##Following subdirectories are part of the project
# add_subdirectory(blabla)

##All .h files in this directory are to be included
target_include_directories($PROJECT_NAME
    PRIVATE
        \${CMAKE_CURRENT_SOURCE_DIR}
)

##List here the source files in current directory (Proper way to include sources)
target_sources($PROJECT_NAME
    PRIVATE
        main.cpp
)

##All .cpp files in this directory are source files (Quick and dirty way to include sources)
#file(GLOB SOURCES \"*.cpp\")
#target_sources($PROJECT_NAME PRIVATE \${SOURCES})"

#####################################################################################################################################
VERSION_CONFIG="#ifndef VERSION_H
#define VERSION_H

/* Version number is automatically updated by cmake */
/* To update version, update PROJECT version in the root CMakeLists.txt */ 
/* To update this file template, update project_root/config/version.h.in */

#define VERSION_MAJOR @PROJECT_VERSION_MAJOR@
#define VERSION_MINOR @PROJECT_VERSION_MINOR@
#define VERSION_PATCH @PROJECT_VERSION_PATCH@
#define VERSION_TWEAK @PROJECT_VERSION_TWEAK@

#endif"

#####################################################################################################################################
GIT_FORMAT="#! /bin/bash

which clang-format 1>/dev/null 2>/dev/null
if [[ \$? -eq 0 ]]; then
    for FILE in \$(git diff --cached --name-only --diff-filter=d| grep -E '.(cpp|h|c)$')
    do
        clang-format -i -style=file \$FILE
        git add \$FILE
    done 
fi"

GIT_MSG="#!/bin/bash

FILE=\$1
MESSAGE=\$(cat \$FILE)
TICKET=[\$(git branch --show-current | grep -Eo '/\w+[-_][0-9.]+' | grep -Eo '\w+[-_][0-9.]+' | tr '\n' ' '| head -c -1)]
if [[ \$TICKET == \"[]\" || \"\$MESSAGE\" == \"\$TICKET\"* ]];then
exit 0;
fi

echo \"\$TICKET \$MESSAGE\" > \$FILE"

FORMAT_STYLE="{BasedOnStyle: mozilla, BreakBeforeBraces: Allman, QualifierAlignment: Right, PointerAlignment: Right, SortIncludes: false}"

IGNORE="/build
/.cache"

#####################################################################################################################################
INT_MAIN="#include \"version.h\"
#include <stdio.h>

int main()
{
    printf(\"\n Version: %d.%d.%d.%d\n\", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, VERSION_TWEAK);
    return 0;
}"

#####################################################################################################################################
if [[ -d $PROJECT_NAME ]]; then
    echo "Project directory already exists"
    exit 0
fi
echo "Creating project..."

mkdir -p $PROJECT_NAME
cd $PROJECT_NAME
R_PATH=$PWD
echo "$ROOT_CMAKE" > CMakeLists.txt
echo "$IGNORE" > .gitignore

mkdir -p build

mkdir -p config
cd config
mkdir cmake
cd cmake
echo "$VERSION_CONFIG"> version.h.in
cd $R_PATH
cd config
mkdir git
cd git
echo "$GIT_FORMAT" > pre-commit.in
echo "$GIT_MSG" >  prepare-commit-msg.in
cd $R_PATH

mkdir -p src
cd src
echo "$SRC_CMAKE" > CMakeLists.txt
echo "$INT_MAIN" > main.cpp
cd $R_PATH

#####################################################################################################################################
echo "Setting up git and clang-format..."

clang-format -style="${FORMAT_STYLE}" -dump-config > .clang-format
git init --initial-branch=main 1>/dev/null 2>/dev/null
chmod 700 config/git/pre-commit.in
chmod 700 config/git/prepare-commit-msg.in

#####################################################################################################################################
#Uncomment these lines out if you want to do do this automatically
# echo ""
# echo "First time setup..."

# cd build
# CC=gcc CXX=g++ cmake ..
# make

# cd ..
# git add .
# git commit -m "Initial commit"

#####################################################################################################################################

echo ""
echo "Done!"
