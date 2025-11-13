cmake_minimum_required(VERSION 3.21)
project(HMI_Mk1 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Quick3D Multimedia Location Positioning)
qt_standard_project_setup()

# Executable
qt_add_executable(appHMI_Mk1
    main.cpp
)

# QML Module
set_source_files_properties(ui/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appHMI_Mk1
    URI HMI_Mk1
    VERSION 1.0
    QML_FILES
        Main.qml
        ui/Theme.qml
        ui/SideNav.qml
        ui/DataTable.qml
        pages/MapPage.qml
        pages/AVActionsPage.qml
        pages/CamerasPage.qml
)

# Protobuf
add_compile_definitions(PROTOBUF_USE_UNSAFE_LOGGING=1)
find_package(Protobuf REQUIRED)
add_subdirectory(src)
find_package(absl REQUIRED)
file(GLOB PROTO_FILES "${CMAKE_SOURCE_DIR}/src/proto/*.proto")
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILES})
target_sources(appHMI_Mk1 PRIVATE ${PROTO_SRCS} ${PROTO_HDRS})
target_include_directories(appHMI_Mk1 PRIVATE
    ${Protobuf_INCLUDE_DIRS}
)

target_link_libraries(appHMI_Mk1
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Quick3D
        Qt6::Multimedia
        Qt6::Location
        Qt6::Positioning
        protobuf::libprotobuf
        absl::base
        absl::strings
        absl::log
        absl::status
        absl::spinlock_wait
    PRIVATE HMI_Backend
)

set_target_properties(appHMI_Mk1 PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appHMI_Mk1
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
