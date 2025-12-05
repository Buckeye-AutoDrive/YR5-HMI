set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Network Positioning)

add_library(HMI_Backend
    backend/NavigationBackend.cpp
    backend/GlobalReceiver.cpp
    backend/GlobalTransmitter.cpp
    proto/HMI_RX_CONTROLS.pb.cc
    proto/HMI_TX_CONTROLS.pb.cc
)

target_include_directories(HMI_Backend PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/backend
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
)

target_link_libraries(HMI_Backend
    Qt6::Network
    Qt6::Positioning
    ${Protobuf_LIBRARIES}
)
