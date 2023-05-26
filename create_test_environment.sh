#!/bin/bash
# Author: Shedbalkar, Akshay (GH2)

#####################################################################################################################################
if 
    [[ $# -ne 1 ]]; then 
    echo "Please provide exactly one argument." 
    echo "Usage: ./create_test_environment.sh <project_name>"
    exit 1
fi
PROJECT_NAME=$1

#####################################################################################################################################
extract_version()
{
    local precision=${2:-0} 
    precision=$(($precision + 1))

    local ver=$($1 --version 2> /dev/null | head -n 1| grep -Po "\d+\.\d+\.\d+")
    ver=$(echo $ver|cut -d"." -f-$precision)

    echo $ver
}

echo ""
echo "Checking dependencies..."

ready=0
programs=("cmake" "gcc" "git" "clang-format")
versions=("3.20" "0" "0" "14")

for p in {0..3}
do
    program=${programs[p]}
    required=${versions[p]}
    ver=$(extract_version $program 1)

    if command -v "$program" &>/dev/null; then
        if awk "BEGIN {exit !( $ver >= $required )}"; then
            printf "%-20s %-20s %s\n" "[x] $program" "(Required >= $required;" "Installed = $ver)" 
        else
            printf "%-20s %-20s %s\n" "[-] $program" "(Required >= $required;" "Installed = $ver)"
            ready=1
        fi
    else
        printf "%-20s %s\n" "[ ] $program" "(Required >= $required)"
        ready=2
    fi
done

if [[ ready -eq 1 ]]; then
    echo ""
    echo "Warning: Installed versions for some programs are too low. Some components may not work correctly. Continuing setup anyway..."
    echo ""
elif [[ ready -eq 2 ]]; then
    echo ""
    echo "Error: Required programs not installed. Please install them and try again. "
    echo "Aborting!"
    exit 0
else
    echo ""
    echo "All dependencies satisfied."
    echo ""
fi

#####################################################################################################################################
ROOT_CMAKE="cmake_minimum_required(VERSION 3.20)

##Project name and type
project($PROJECT_NAME VERSION 0.1.0.0)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES OFF)
# set(CMAKE_C_INCLUDE_WHAT_YOU_USE include-what-you-use)

##Define executables, libraries here with relative path
add_library(${PROJECT_NAME}_interface INTERFACE)
add_library(${PROJECT_NAME}_library STATIC)
add_executable($PROJECT_NAME test/test.cpp)

##Subdirectories which are part of the project
add_subdirectory(test)

##Compiler defines, options and features
#target_compile_features(${PROJECT_NAME}_library PUBLIC cxx_std_20)
#target_compile_options(${PROJECT_NAME}_library PUBLIC -Wall)
#target_compile_definitions(${PROJECT_NAME}_library PUBLIC foo)

##Linker options, external libraries/objects to link against
target_link_libraries(${PROJECT_NAME}_library PUBLIC ${PROJECT_NAME}_interface Catch2::Catch2WithMain)
target_link_libraries($PROJECT_NAME PRIVATE ${PROJECT_NAME}_library)

##Set target properties
set_target_properties($PROJECT_NAME
    PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY \"\${PROJECT_BINARY_DIR}/bin\"
        ARCHIVE_OUTPUT_DIRECTORY \"\${PROJECT_BINARY_DIR}/lib\"
        LIBRARY_OUTPUT_DIRECTORY \"\${PROJECT_BINARY_DIR}/lib\"
    )

##Helpful commands for various functionalities if needed

# Ensure dependencies exist
# find_package(Boost COMPONENTS filesystem system iostreams)

#Install git hooks correctly even in git submodules
execute_process(COMMAND git rev-parse --path-format=absolute --git-path hooks OUTPUT_VARIABLE hook_dir OUTPUT_STRIP_TRAILING_WHITESPACE)
configure_file(\"\${PROJECT_SOURCE_DIR}/config/git/pre-commit.in\" \"\${hook_dir}/pre-commit\" COPYONLY FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
configure_file(\"\${PROJECT_SOURCE_DIR}/config/git/prepare-commit-msg.in\" \"\${hook_dir}/prepare-commit-msg\" COPYONLY FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)

# Update version numbers throughout the project
configure_file(\"\${PROJECT_SOURCE_DIR}/config/cmake/version.h.in\" \"\${PROJECT_SOURCE_DIR}/test/version.h\")

# OS dependant compiler flags / tasks
# if(\${CMAKE_SYSTEM_NAME} MATCHES \"Linux\")
# elseif(\${CMAKE_SYSTEM_NAME} MATCHES \"Windows\")
# endif()

#Testing framework
Include(FetchContent)
FetchContent_Declare(
  Catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG        v3.3.2
)
FetchContent_MakeAvailable(Catch2)

list(APPEND CMAKE_MODULE_PATH \${catch2_SOURCE_DIR}/extras)
include(CTest)
include(Catch)
catch_discover_tests(${PROJECT_NAME})"

SRC_CMAKE="##Following subdirectories are part of the project
#add_subdirectory(stuff)

##All .h files in this directory are to be included
target_include_directories(${PROJECT_NAME}_interface 
    INTERFACE \${CMAKE_CURRENT_SOURCE_DIR}
    )

##List here the source files in current directory (Correct way to include sources)
target_sources(${PROJECT_NAME}_library
  PRIVATE test.cpp
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

which clang-format &>/dev/null
if [[ \$? -eq 0 ]]; then
    for FILE in \$(git diff --cached --name-only --diff-filter=d| grep -E '\.(cpp|h|c)$')
    do
        clang-format -i -style=file \$FILE
        git add \$FILE
    done 
fi"

GIT_MSG="#!/bin/bash

FILE=\$1
MESSAGE=\$(cat \$FILE)
TICKET=[\$(git branch --show-current | grep -Eo '/\w+[-_][0-9.]+' | grep -Eo '\w+[-_][0-9.]+' | tr '\n' ' '| head -c -1)]
if [[ \$TICKET == \"[]\" || \"\$MESSAGE\" == \"\$TICKET\"* ]]; then
    exit 0;
fi

echo \"\$TICKET \$MESSAGE\" > \$FILE"

FORMAT_STYLE="{BasedOnStyle: mozilla, BreakBeforeBraces: Allman, QualifierAlignment: Right, PointerAlignment: Right, SortIncludes: false}"


IGNORE="/build
/.cache"

#####################################################################################################################################
INT_MAIN="#include \"version.h\"


/* Catch2 example */
#include <catch2/catch_test_macros.hpp>
#include <cstdint>

uint32_t factorial( uint32_t number ) {
    return number <= 1 ? number : factorial(number-1) * number;
}

TEST_CASE( \"dummy_catch2\", \"[factorial]\" ) {
    REQUIRE( factorial( 1) == 1 );
    REQUIRE( factorial( 2) == 2 );
    REQUIRE( factorial( 3) == 6 );
    REQUIRE( factorial(10) == 3'628'800 );
    REQUIRE( factorial( 0) == 1 );
}


/* fff example */
#include \"fff.h\"
DEFINE_FFF_GLOBALS;

FAKE_VOID_FUNC(DISPLAY_init);
TEST_CASE(\"dummy_fff\", \"[dummy]\")
{
    REQUIRE(DISPLAY_init_fake.call_count == 0);
    REQUIRE(DISPLAY_init_fake.call_count == 1);
}
"
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

mkdir -p test
cd test
echo "$SRC_CMAKE" > CMakeLists.txt
echo "$INT_MAIN" > test.cpp
curl -Lo fff.h https://raw.githubusercontent.com/meekrosoft/fff/master/fff.h &>/dev/null
if [[ $? -ne 0 ]]; then
    read -p "Enter NTUSER username: " uname
    read -s -p "Enter NTUSER password: " pw
    curl -Lo fff.h --proxy "http://$uname:$pw@proxy.in.audi.vwg:8080" https://raw.githubusercontent.com/meekrosoft/fff/master/fff.h &>/dev/null
fi
cd $R_PATH

#####################################################################################################################################
echo "Setting up git and clang-format..."
echo ""

git init --initial-branch=main &>/dev/null
clang-format -style="${FORMAT_STYLE}" -dump-config > .clang-format 2>/dev/null

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

echo "Done!"
