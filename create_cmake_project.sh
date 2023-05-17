#!/bin/bash
# Author: Shedbalkar, Akshay (GH2)

#####################################################################################################################################
if 
    [[ $# -ne 1 ]]; then 
    echo "Please provide exactly one argument." 
    echo "Usage: ./create_cmake_project.sh <project_name>"
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
add_executable($PROJECT_NAME src/main.cpp)

##Subdirectories which are part of the project
add_subdirectory(src)

#Include external code genertors
configure_file(\"\${CMAKE_SOURCE_DIR}/config/cmake/generate_files.sh.in\" \"\${CMAKE_SOURCE_DIR}/scripts/generate_files.sh\")
add_subdirectory(extern)

##Compiler defines, options and features
#target_compile_features($PROJECT_NAME PRIVATE cxx_std_20)
#target_compile_options($PROJECT_NAME PRIVATE -Wall)
#target_compile_definitions($PROJECT_NAME PRIVATE foo)

##Linker options, external libraries/objects to link against
target_link_libraries(${PROJECT_NAME}_library PRIVATE ${PROJECT_NAME}_interface)
target_link_libraries($PROJECT_NAME PRIVATE ${PROJECT_NAME}_interface ${PROJECT_NAME}_library)

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
configure_file(\"\${CMAKE_SOURCE_DIR}/config/git/pre-commit.in\" \"\${hook_dir}/pre-commit\" COPYONLY FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
configure_file(\"\${CMAKE_SOURCE_DIR}/config/git/prepare-commit-msg.in\" \"\${hook_dir}/prepare-commit-msg\" COPYONLY FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)

#Generate Doxygen documentation with 'make doc'
find_package(Doxygen COMPONENTS dot)
if(DOXYGEN_FOUND)
    set(DOXYGEN_HTML_OUTPUT \"\${CMAKE_BINARY_DIR}/docs\")
    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE \"README.md\")
    set(DOXYGEN_HAVE_DOT \"YES\")
    set(DOXYGEN_CALL_GRAPH \"YES\")
    set(DOXYGEN_CALLER_GRAPH \"YES\")
    set(DOXYGEN_ALWAYS_DETAILED_SEC \"YES\")
    doxygen_add_docs(doc \${CMAKE_SOURCE_DIR})
endif()

# Ensure dependencies exist
# find_package(Boost COMPONENTS filesystem system iostreams)

# OS dependant compiler flags / tasks
# if(\${CMAKE_SYSTEM_NAME} MATCHES \"Linux\")
# elseif(\${CMAKE_SYSTEM_NAME} MATCHES \"Windows\")
# endif()

# Copy dynamic libraries to runtime directories
# add_custom_command(TARGET ${PROJECT_NAME} 
#    POST_BUILD
#    COMMAND \${CMAKE_COMMAND} -E copy_if_different 
#        \"\${CMAKE_SOURCE_DIR}/extern/lib/libcurl-x64.dll\"
#        $<TARGET_FILE_DIR:${PROJECT_NAME}>
#    )

# Update version numbers throughout the project
configure_file(\"\${CMAKE_SOURCE_DIR}/config/cmake/version.h.in\" \"\${CMAKE_SOURCE_DIR}/src/version.h\")
# FILE(READ \${CMAKE_SOURCE_DIR}/src/project.arxml version)
# STRING(REGEX REPLACE \"VERSION_MAJOR\ [0-9]*\" \"VERSION_MAJOR\ \${${PROJECT_NAME}_VERSION_MAJOR}\" version \"\${version}\")
# FILE(WRITE \${CMAKE_SOURCE_DIR}/src/project.arxml \"\${version}\")
#
#Static code analysis with cppcheck
#Call: make sca
add_custom_target(sca
    cmake -E make_directory \${CMAKE_BINARY_DIR}/sca
    COMMAND cppcheck --project=compile_commands.json --enable=all --premium='cert-c-2016 --misra-c-2016 --bughunting' --force --inconclusive --xml --output-file=\${CMAKE_BINARY_DIR}/sca/results.xml --cppcheck-build-dir=\${CMAKE_BINARY_DIR}/sca
    COMMAND python \${CMAKE_SOURCE_DIR}/scripts/platform/cppcheck-htmlreport.py --file=\${CMAKE_BINARY_DIR}/sca/results.xml --report-dir=\${CMAKE_BINARY_DIR}/sca/html_report --source-dir=\${CMAKE_BINARY_DIR}/sca
    COMMAND find \${CMAKE_SOURCE_DIR} -type f -name \"*snalyzerinfo\" -not -path '\${CMAKE_BINARY_DIR}*' | xargs -r mv -f -t \${CMAKE_BINARY_DIR}/sca/
    COMMENT \"Performing static code analysis\"
    )"

SRC_CMAKE="##Following subdirectories are part of the project
add_subdirectory(stuff)

##All .h files in this directory are to be included
target_include_directories(${PROJECT_NAME}_interface 
    INTERFACE \${CMAKE_CURRENT_SOURCE_DIR}
    )

##List here the source files in current directory (Correct way to include sources)
# target_sources(${PROJECT_NAME}_library
#   PRIVATE main.cpp
#   )

##All .cpp files in this directory are source files (Quick and dirty way to include sources)
#file(GLOB SOURCES \"*.cpp\")
#target_sources($PROJECT_NAME PRIVATE \${SOURCES})"


STUFF_CMAKE="##Following subdirectories are part of the project
#add_subdirectory(blabla)

##All .h files in this directory are to be included
target_include_directories(${PROJECT_NAME}_interface 
    INTERFACE \${CMAKE_CURRENT_SOURCE_DIR}
    )

##List here the source files in current directory (Correct way to include sources)
target_sources(${PROJECT_NAME}_library
    PRIVATE stuff.cpp
    )

##All .cpp files in this directory are source files (Quick and dirty way to include sources)
#file(GLOB SOURCES \"*.cpp\")
#target_sources($PROJECT_NAME PRIVATE \${SOURCES})"

EXTERN_CMAKE="#This CMakeLists.txt file provides a robust way to add generated code to project.

##All generated sources must be listed here
set(generated_sources 
    \${CMAKE_CURRENT_SOURCE_DIR}/gen/generated_1.cpp
    \${CMAKE_CURRENT_SOURCE_DIR}/gen/generated_2.cpp
    )

##List generated directories here.
##These should at least be directories containing generated header files.
set(generated_directories
    \${CMAKE_CURRENT_SOURCE_DIR}/gen)

##Invoke code generator here. OUTPUT artifacts are cleaned on \"make clean\". 
add_custom_command(
    OUTPUT \${generated_sources} \${generated_directories}
    COMMAND \"\${CMAKE_SOURCE_DIR}/scripts/generate_files.sh\"
    DEPENDS \"\${CMAKE_SOURCE_DIR}/config/cmake/generate_files.sh.in\"
    COMMENT \"Generating Gen files ...\"
    VERBATIM
    )

##Generated artifacts are sources of intermediate target. 
add_custom_target(gen 
    DEPENDS \${generated_sources}
    )

#Make sure to generate code before main target is created
add_dependencies(${PROJECT_NAME}_library gen)

#Add sources to main target like ususal sources
target_sources(${PROJECT_NAME}_library
    PRIVATE \${generated_sources}
    )

#Specify include directories for main target like usual
target_include_directories(${PROJECT_NAME}_interface
    INTERFACE \${generated_directories}
    )
"

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

CODE_GENERATOR=" #! /bin/bash

mkdir -p \${CMAKE_SOURCE_DIR}/extern/gen
echo \"#ifndef GEN_H 
#define GEN_H
const int get_trouble_code();
const int get_higher_trouble_code();
#endif\" > \${CMAKE_SOURCE_DIR}/extern/gen/generated.h
echo \"#include \\\"generated.h\\\"
const int get_trouble_code(){return 1;}\" > \${CMAKE_SOURCE_DIR}/extern/gen/generated_1.cpp
echo \"#include \\\"generated.h\\\"
const int get_higher_trouble_code(){return 1+1;}\" > \${CMAKE_SOURCE_DIR}/extern/gen/generated_2.cpp"

TESTING_MACROS="#! /bin/bash

#Usage: 
#First argument: file extension (c, cpp etc)
#Second argument: folders to include in search (\"folder1 folder2 ...\")

FILES=\$(find \$2 -type f -name \"*.\$1\")

for f in \$FILES; do
    ff=\${f##*/} 
    ff=\${ff%.\$1}
    sed -i \"1i#if !defined(REMOVE_ALL) || defined(KEEP_\$ff)\n\" \$f
    printf \"\n#endif\" >> \$f
done"

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
#include \"generated.h\"
#include \"stuff.h\"
#include <stdio.h>

int main()
{
    stuff();

    return 0;
}"

STUFF_CPP="#include \"version.h\"
#include \"generated.h\"
#include \"stuff.h\"
#include <stdio.h>

void stuff()
{
    printf(\"\n Version: %d.%d.%d.%d\n\", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, VERSION_TWEAK);

    get_trouble_code();
    get_higher_trouble_code();

}"

STUFF_H="#ifndef STUFF_H
#define STUFF_H

void stuff();

#endif"

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
echo "$CODE_GENERATOR">generate_files.sh.in
chmod 700 generate_files.sh.in
cd $R_PATH

cd config
mkdir git
cd git
echo "$GIT_FORMAT" > pre-commit.in
echo "$GIT_MSG" >  prepare-commit-msg.in
cd $R_PATH

mkdir -p scripts
cd scripts
echo "$TESTING_MACROS" > insert_macros_for_testing.sh
chmod 700 insert_macros_for_testing.sh
cd $R_PATH

mkdir -p extern
cd extern
echo "${EXTERN_CMAKE}">CMakeLists.txt
cd $R_PATH

mkdir -p src
cd src
echo "$SRC_CMAKE" > CMakeLists.txt
echo "$INT_MAIN" > main.cpp
mkdir -p stuff
cd stuff
echo "$STUFF_CMAKE" > CMakeLists.txt
echo "$STUFF_CPP" > stuff.cpp
echo "$STUFF_H" > stuff.h
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
