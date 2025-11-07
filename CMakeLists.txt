cmake_minimum_required(VERSION 3.21)
project(HMI_Mk1 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add Multimedia for RTSP playback
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Quick3D Multimedia)
qt_standard_project_setup()

qt_add_executable(appHMI_Mk1
    main.cpp
)

# Mark Theme.qml as a singleton BEFORE qt_add_qml_module
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
        pages/CamerasPage.qml
)

target_link_libraries(appHMI_Mk1
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Quick3D
        Qt6::Multimedia
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
