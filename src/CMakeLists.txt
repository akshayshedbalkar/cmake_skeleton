##All .h files in this directory are to be included
target_include_directories(my_test 
    PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}
)

##List here the source files in current directory (Good way to include sources)
#target_sources(my_test 
#    PRIVATE 
#        my_test.cpp
#)

##All .cpp files in this directory are source files (Quick and dirty way to include sources)
file(GLOB SOURCES "*.cpp")
target_sources(my_test PRIVATE ${SOURCES})

##Following subdirectories are part of the project
# add_subdirectory(blabla)
