set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network Positioning Quick)

add_library(HMI_Backend
    backend/NavigationBackend.cpp
    backend/GlobalReceiver.cpp
    backend/GlobalTransmitter.cpp
    backend/SettingsBackend.cpp
    backend/LoggerBackend.cpp
    backend/InternetBackend.cpp
    backend/TerminalBackend.cpp
    backend/CameraFramesBackend.cpp
    backend/LogBackupBackend.cpp
    proto/HMI_RX_CONTROLS.pb.cc
    proto/HMI_RX_PERCEPTION.pb.cc
    proto/HMI_TX_CONTROLS.pb.cc
    # HMI_RX_CAN compiled by app (root CMakeLists) to avoid duplicate symbols
)

target_include_directories(HMI_Backend PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/backend
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
)

target_link_libraries(HMI_Backend
    Qt6::Core
    Qt6::Network
    Qt6::Positioning
    Qt6::Quick
    ${Protobuf_LIBRARIES}
)
