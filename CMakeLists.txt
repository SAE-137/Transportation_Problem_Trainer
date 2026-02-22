cmake_minimum_required(VERSION 3.16)

project(Transportation_Problem_Trainer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Widgets)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appTransportation_Problem_Trainer
    main.cpp
    qml/components/HeaderButton.qml
    qml/components/ActionButton.qml
    qml/components/TabButton.qml
    qml/Matrix.qml
    qml/Main.qml
    qml/components/NumberInput.qml
    qml/components/MatrixView.qml
    qml/components/TheoryScreen.qml
    qml/components/PracticeScreen.qml
    mainwindow.h mainwindow.cpp
    qml/components/MatrixSetupPage.qml
    qml/components/BalanceCheckPage.qml
    qml/components/BalanceFixPage.qml
    qml/components/MinCostPlanPage.qml
)

target_sources(appTransportation_Problem_Trainer PRIVATE
    backend/matrixdata.cpp
    backend/matrixsolver.cpp
    backend/studentcontroller.cpp

    backend/matrixdata.h
    backend/matrixsolver.h
    backend/studentcontroller.h
)

target_include_directories(appTransportation_Problem_Trainer PRIVATE
    backend
    qml
)

set_target_properties(appTransportation_Problem_Trainer PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appTransportation_Problem_Trainer
    PRIVATE Qt6::Quick
)
target_link_libraries(appTransportation_Problem_Trainer PRIVATE Qt6::Widgets)
