**Goal:**

This script initializes a cmake project suitable for C or C++.

**Features:**
- modern cmake: target based
- cmake compile commands export turned on (needed for things like language servers)
- cmake include-what-you-use can be turned on by commenting in the appropriate line
- cmake project versioning
- binary and library output folders configured
- optional command template for os-dependant commands
- optional command template for copying build variables to arbitrary source file
- folder is initialized as a git repository
- clang format file is generated
- Doxygen support
- Support for including code generators in a modular manner
- git hook to automatically format code is installed
- git hook to automatically insert (JIRA) ticket numbers in commit messages is installed
- Dependency checks to ensure you have everything needed!
- Testing ready: interface, static libs and macros to start testing immediately
- Separate script for creating a test environment with catch2 and fff

**Usage:**
1) Essentially all you need to do is execute the script with a single argument, which is the project name `./create_cmake_project.sh <project_name>`. The project is now generated. You can now build or edit the project as you like.
    
2) To build, change to the build directory and build using cmake (use -G option to use appropriate generator):
    ```
    cd <project_name>/build
    CC=gcc CXX=g++ cmake ..
    make
    ```

That's it!
