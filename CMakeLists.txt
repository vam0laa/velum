cmake_minimum_required(VERSION 3.22)
project(velum VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.9 REQUIRED COMPONENTS DBus Network Sql Quick QuickControls2 WebEngineQuick Test)
qt_standard_project_setup(REQUIRES 6.9)

# The blocking engine is written in Rust (blocker/) and linked in as a static library.
find_program(CARGO cargo REQUIRED)
set(BLOCKER_LIB ${CMAKE_BINARY_DIR}/cargo/release/libvelumblock.a)
add_custom_command(
    OUTPUT ${BLOCKER_LIB}
    COMMAND ${CARGO} build --release --locked --target-dir ${CMAKE_BINARY_DIR}/cargo
    DEPENDS blocker/src/lib.rs blocker/Cargo.toml blocker/Cargo.lock
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/blocker
    COMMENT "Building the blocking engine (Rust)"
    VERBATIM)
add_custom_target(blocker_build DEPENDS ${BLOCKER_LIB})

# The parts that have no window live in a small library, so tests can use them alone.
add_library(velumcore STATIC src/blocker.cpp src/historystore.cpp src/instance.cpp src/lists.cpp src/notice.cpp src/procinfo.cpp src/address.cpp src/graphics.cpp src/palette.cpp src/widevine.cpp)
target_include_directories(velumcore PUBLIC src)
add_dependencies(velumcore blocker_build)
target_link_libraries(velumcore PUBLIC Qt6::Core Qt6::Network Qt6::Sql ${BLOCKER_LIB} ${CMAKE_DL_LIBS} pthread m)

qt_add_executable(velum src/main.cpp src/shield.cpp)
set_source_files_properties(qml/Theme.qml qml/Lang.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(velum
    URI Velum
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/Sidebar.qml
        qml/AddressField.qml
        qml/IconButton.qml
        qml/TabItem.qml
        qml/StartPage.qml
        qml/Icon.qml
        qml/Hint.qml
        qml/AppMenu.qml
        qml/CommandBar.qml
        qml/ShieldPanel.qml
        qml/DownloadsPanel.qml
        qml/ResourcePanel.qml
        qml/FindBar.qml
        qml/ProblemPage.qml
        qml/Lang.qml
        qml/Toggle.qml
        qml/Segments.qml
        qml/SettingsPage.qml
        qml/AppMenuItem.qml
        qml/AppMenuLine.qml
        qml/PageMenu.qml
        qml/Bevel.qml
        qml/TitleBar.qml
        qml/Panel.qml
        qml/WindowBackground.qml
        qml/Kicker.qml
        qml/SpaceBar.qml
        qml/SpaceDialog.qml
        qml/MiniPlayer.qml
        qml/BookmarksPage.qml
        qml/PermissionBar.qml
        qml/TextButton.qml
        qml/ConfirmDialog.qml
    RESOURCES data/velum.svg data/fonts/GoogleSansFlex.woff data/fonts/VT323-Regular.ttf
    SOURCES src/addressbridge.h src/desktopcolors.h src/shield.h src/historybridge.h src/resources.h src/notifier.h
    IMPORTS QtQuick
)
set_target_properties(velum PROPERTIES QT_QML_MODULE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Velum)
target_compile_definitions(velum PRIVATE VELUM_VERSION="${PROJECT_VERSION}")
target_include_directories(velum PRIVATE src)
target_link_libraries(velum PRIVATE velumcore Qt6::DBus Qt6::Quick Qt6::QuickControls2 Qt6::WebEngineQuick)

enable_testing()
add_executable(test_core tests/test_core.cpp)
target_link_libraries(test_core PRIVATE velumcore Qt6::Test)
add_test(NAME core COMMAND test_core)
add_test(NAME ui COMMAND ${CMAKE_SOURCE_DIR}/tests/run-ui.sh)

include(GNUInstallDirs)
install(TARGETS velum RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
# The launcher names the program with its full path: desktop sessions often do not have
# ~/.local/bin on their PATH. The prefix is only known while installing.
install(CODE "
    file(READ \"${CMAKE_SOURCE_DIR}/data/velum.desktop\" entry)
    string(REPLACE \"Exec=velum\" \"Exec=\${CMAKE_INSTALL_PREFIX}/bin/velum\" entry \"\${entry}\")
    file(WRITE \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATADIR}/applications/velum.desktop\" \"\${entry}\")
")
install(FILES data/velum.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
