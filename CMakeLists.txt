cmake_minimum_required(VERSION 3.13)

##Project name and type
project(test)
set(CMAKE_BUILD_TYPE Debug)

##Define executables, libraries here with relative path
# add_library(my_library STATIC src/my_test.cpp)
add_executable(my_test src/my_test.cpp)

##Subdirectories which are part of the project
add_subdirectory(src)

##Compiler defines, options and features
target_compile_features(my_test 
    PRIVATE 
        cxx_std_17
)
# target_compile_options(my_test 
#     PRIVATE 
#         -Wall
# )
# target_compile_definitions(my_test 
#      PRIVATE 
#          foo
#  )

##Linker options, external libraries/objects to link against
# target_link_libraries(my_test 
#      PRIVATE 
#          blabla
#  )
# target_link_options(my_test 
#      PRIVATE 
#          blabla
#  )

##Set target properties
set_target_properties(my_test
    PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)
