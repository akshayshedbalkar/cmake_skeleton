##All .h files in this directory are to be included
target_include_directories(my_test 
    PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}
)

##List here the source files in current directory
target_sources(my_test 
    PRIVATE 
        my_test.cpp
)


##Following subdirectories are part of the project
# add_subdirectory(blabla)
