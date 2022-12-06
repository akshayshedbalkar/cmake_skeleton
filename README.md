This script initializes a cmake project suitable for C or C++.

Features:
- modern cmake
- cmake compile commands export turned on (needed for things like language servers)
- cmake include-what-you-use can be turned on by commenting in the appropriate line
- cmake project versioning
- binary and library output folders configured
- optional command template for os-dependant commands
- optional command template for copying build variables to arbitrary source file
- folder is initialized as a git repository
- clang format file is generated
- git hook to automatically format code is installed
- git hook to automatically insert (JIRA) ticket numbers in commit messages is installed

Usage:
1) Essentially all you need to do is execute the script with a single argument, which is the project name `create_cmake_project.sh <project_name>`. The project is now generated. You can now build or edit the project as you like.
    
2) To build, change to the build directory and build using cmake:
    ```
    cd <project_name>/build
    CC=gcc CXX=g++ cmake ..
    make
    ```

That's it!
