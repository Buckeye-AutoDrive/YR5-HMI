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

# Generate qmldir for ui/ and pages/ so subdirectory QML components import correctly (Qt 6.8+)
qt_policy(SET QTP0004 NEW)

# Traffic sign PNGs: sign_0.png ... sign_17.png in src/icons/ (sign_type_id per HMI_RX_PERCEPTION.proto)
file(GLOB TRAFFIC_SIGN_PNGS "${CMAKE_SOURCE_DIR}/src/icons/sign_*.png")
list(SORT TRAFFIC_SIGN_PNGS)
set(TRAFFIC_SIGN_PNGS_REL "")
foreach(f IN LISTS TRAFFIC_SIGN_PNGS)
    file(RELATIVE_PATH rel "${CMAKE_SOURCE_DIR}" "${f}")
    list(APPEND TRAFFIC_SIGN_PNGS_REL "${rel}")
endforeach()

# Perception object icons: object_1.svg ... object_9.svg (object_type_id per HMI_RX_PERCEPTION.proto)
file(GLOB OBJECT_ICON_SVGS "${CMAKE_SOURCE_DIR}/src/icons/object_*.svg")
list(SORT OBJECT_ICON_SVGS)
set(OBJECT_ICON_SVGS_REL "")
foreach(f IN LISTS OBJECT_ICON_SVGS)
    file(RELATIVE_PATH rel "${CMAKE_SOURCE_DIR}" "${f}")
    list(APPEND OBJECT_ICON_SVGS_REL "${rel}")
endforeach()

qt_add_qml_module(appHMI_Mk1
    URI HMI_Mk1
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        Main.qml
        ui/Theme.qml
        ui/SideNav.qml
        ui/DataTable.qml
        ui/DestList.qml
        ui/AVPanel.qml
        pages/MapPage.qml
        pages/AVActionsPage.qml
        pages/CamerasPage.qml
        pages/AVWarnPage.qml
        pages/TerminalPage.qml
        pages/SettingsPage.qml
        pages/LoggerPage.qml

    RESOURCES
        src/models/car.glb
        src/fonts/UniversalSans.ttf
        src/fonts/UniversalSansDisplay.ttf
        src/icons/auto_on.svg
        src/icons/auto_off.svg
        src/icons/gnss_on.svg
        src/icons/gnss_off.svg
        src/icons/lan_on.svg
        src/icons/lan_off.svg
        src/icons/sensors_on.svg
        src/icons/sensors_off.svg
        src/icons/can_on.svg
        src/icons/can_off.svg
        src/icons/internet_on.svg
        src/icons/internet_off.svg
        src/icons/record.svg
        src/icons/save.svg
        src/icons/pause.svg
        src/icons/resume.svg
        src/icons/discard.svg
        ${OBJECT_ICON_SVGS_REL}
        ${TRAFFIC_SIGN_PNGS_REL}
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
