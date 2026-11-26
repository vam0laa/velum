cmake_minimum_required(VERSION 3.22)
project(velum VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# the version a release carries, e.g. 0.1.0-beta.1
set(VELUM_RELEASE "" CACHE STRING "Full version, if different from the project version")
if(VELUM_RELEASE STREQUAL "")
    set(VELUM_RELEASE ${PROJECT_VERSION})
endif()
file(STRINGS ${CMAKE_SOURCE_DIR}/data/update.pub VELUM_UPDATE_KEY LIMIT_COUNT 1)

find_package(OpenSSL 3 REQUIRED)
find_package(Qt6 6.9 REQUIRED COMPONENTS Concurrent Network Sql Quick QuickControls2 WebEngineQuick Test)
qt_standard_project_setup(REQUIRES 6.9)

# what differs between the systems
if(WIN32)
    set(SYSTEM_SOURCES src/passwords_win.cpp src/procinfo_win.cpp)
    set(SYSTEM_LIBS advapi32 psapi ws2_32 userenv bcrypt ntdll crypt32 synchronization)
    set(NOTIFIER_HEADER src/notifier_win.h)
    set(BLOCKER_NAME velumblock.lib)
else()
    find_package(Qt6 6.9 REQUIRED COMPONENTS DBus)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(SECRET REQUIRED IMPORTED_TARGET libsecret-1)
    set(SYSTEM_SOURCES src/passwords.cpp src/procinfo.cpp)
    set(SYSTEM_LIBS PkgConfig::SECRET Qt6::DBus ${CMAKE_DL_LIBS} pthread m)
    set(NOTIFIER_HEADER src/notifier.h)
    set(BLOCKER_NAME libvelumblock.a)
endif()
if(MSVC)
    add_compile_options(/utf-8)       # the Turkish texts in the sources
    add_compile_definitions(NOMINMAX WIN32_LEAN_AND_MEAN)
endif()

# The blocking engine is written in Rust (blocker/) and linked in as a static library.
find_program(CARGO cargo REQUIRED)
set(BLOCKER_LIB ${CMAKE_BINARY_DIR}/cargo/release/${BLOCKER_NAME})
add_custom_command(
    OUTPUT ${BLOCKER_LIB}
    COMMAND ${CARGO} build --release --locked --target-dir ${CMAKE_BINARY_DIR}/cargo
    DEPENDS blocker/src/lib.rs blocker/Cargo.toml blocker/Cargo.lock
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/blocker
    COMMENT "Building the blocking engine (Rust)"
    VERBATIM)
add_custom_target(blocker_build DEPENDS ${BLOCKER_LIB})

# The parts that have no window live in a small library, so tests can use them alone.
add_library(velumcore STATIC src/blocker.cpp src/crx.cpp src/historystore.cpp src/importer.cpp src/instance.cpp src/lists.cpp src/notice.cpp src/passwords_common.cpp src/library.cpp src/scriptlets.cpp src/held.cpp src/update.cpp ${SYSTEM_SOURCES} src/address.cpp src/graphics.cpp src/palette.cpp src/widevine.cpp)
target_include_directories(velumcore PUBLIC src)
add_dependencies(velumcore blocker_build)
target_link_libraries(velumcore PUBLIC Qt6::Core Qt6::Network Qt6::Sql OpenSSL::Crypto ${BLOCKER_LIB} ${SYSTEM_LIBS})

qt_add_executable(velum src/main.cpp src/shield.cpp)
set_source_files_properties(qml/Theme.qml qml/Lang.qml qml/Keymap.qml qml/Access.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
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
        qml/ClassicStart.qml
        qml/MonthCard.qml
        qml/HomeCss.qml
        qml/HomeBox.qml
        qml/HomeText.qml
        qml/HomeWidget.qml
        qml/HomeEditor.qml
        qml/Recommended.qml
        qml/ThemeWash.qml
        qml/BrowserPreview.qml
        qml/ChoiceCard.qml
        qml/WebStart.qml
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
        qml/Keymap.qml
        qml/KeyList.qml
        qml/ColorMath.qml
        qml/ThemePreview.qml
        qml/ThemeStudio.qml
        qml/StudioPicker.qml
        qml/StudioCard.qml
        qml/SafeButton.qml
        qml/SyncLogic.qml
        qml/SyncCard.qml
        qml/Access.qml
        qml/WindowLogic.qml
        qml/TabLogic.qml
        qml/TabSearch.qml
        qml/GroupMenu.qml
        qml/PermissionList.qml
        qml/CookieList.qml
        qml/BackupLogic.qml
        qml/HistoryPage.qml
        qml/BackupCard.qml
        qml/ToolLogic.qml
        qml/DevTools.qml
        qml/HistoryMenu.qml
        qml/PageOverlay.qml
        qml/PageView.qml
        qml/MainMenu.qml
        qml/TabMenu.qml
        qml/Shortcuts.qml
        qml/CommandList.qml
        qml/HomeLogic.qml
        qml/BookmarkDialog.qml
        qml/BookmarkLogic.qml
        qml/DownloadLogic.qml
        qml/SpaceLogic.qml
        qml/PowerLogic.qml
        qml/PageLogic.qml
        qml/PasswordLogic.qml
        qml/ExtensionLogic.qml
        qml/SiteLogic.qml
        qml/AskLogic.qml
        qml/DemoLogic.qml
        qml/ShapeEditor.qml
        qml/CssEditor.qml
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
        qml/SpaceBar.qml
        qml/SpaceDialog.qml
        qml/MiniPlayer.qml
        qml/BookmarksPage.qml
        qml/ImportPanel.qml
        qml/Reader.qml
        qml/LoginScript.qml
        qml/PasswordBar.qml
        qml/PasswordList.qml
        qml/ThemePicker.qml
        qml/Card.qml
        qml/ShieldButton.qml
        qml/DownloadButton.qml
        qml/TopBar.qml
        qml/Welcome.qml
        qml/ExtensionList.qml
        qml/Backdrop.qml
        qml/SiteIcon.qml
        qml/PopIn.qml
        qml/PopOut.qml
        qml/Shadow.qml
        qml/Dropdown.qml
        qml/AccentDots.qml
        qml/WindowButton.qml
        qml/PageButtons.qml
        qml/Sparkle.qml
        qml/PermissionBar.qml
        qml/TextButton.qml
        qml/ConfirmDialog.qml
    RESOURCES data/velum.svg data/sky.jpg data/sky-night.jpg data/scanline.png data/logos/tr.svg data/logos/gb.svg data/logos/duckduckgo.png data/logos/brave.png data/logos/google.png data/logos/startpage.svg data/logos/ublock.png data/logos/darkreader.png data/logos/sponsorblock.png data/fonts/VT323-Regular.ttf data/fonts/GoogleSansFlex.ttf
        data/fonts/extra/audiowide.ttf
        data/fonts/extra/bricolagegrotesque.ttf
        data/fonts/extra/bungee.ttf
        data/fonts/extra/caveat.ttf
        data/fonts/extra/chakrapetch.ttf
        data/fonts/extra/comfortaa.ttf
        data/fonts/extra/dancingscript.ttf
        data/fonts/extra/jetbrainsmono.ttf
        data/fonts/extra/lexend.ttf
        data/fonts/extra/lobster.ttf
        data/fonts/extra/majormonodisplay.ttf
        data/fonts/extra/monoton.ttf
        data/fonts/extra/outfit.ttf
        data/fonts/extra/pacifico.ttf
        data/fonts/extra/patrickhand.ttf
        data/fonts/extra/playfairdisplay.ttf
        data/fonts/extra/pressstart2p.ttf
        data/fonts/extra/quicksand.ttf
        data/fonts/extra/righteous.ttf
        data/fonts/extra/rubikglitch.ttf
        data/fonts/extra/sora.ttf
        data/fonts/extra/spacegrotesk.ttf
        data/fonts/extra/syne.ttf
        data/fonts/extra/audiowide-OFL.txt
        data/fonts/extra/bricolagegrotesque-OFL.txt
        data/fonts/extra/bungee-OFL.txt
        data/fonts/extra/caveat-OFL.txt
        data/fonts/extra/chakrapetch-OFL.txt
        data/fonts/extra/comfortaa-OFL.txt
        data/fonts/extra/dancingscript-OFL.txt
        data/fonts/extra/jetbrainsmono-OFL.txt
        data/fonts/extra/lexend-OFL.txt
        data/fonts/extra/lobster-OFL.txt
        data/fonts/extra/majormonodisplay-OFL.txt
        data/fonts/extra/monoton-OFL.txt
        data/fonts/extra/outfit-OFL.txt
        data/fonts/extra/pacifico-OFL.txt
        data/fonts/extra/patrickhand-OFL.txt
        data/fonts/extra/playfairdisplay-OFL.txt
        data/fonts/extra/pressstart2p-OFL.txt
        data/fonts/extra/quicksand-OFL.txt
        data/fonts/extra/righteous-OFL.txt
        data/fonts/extra/rubikglitch-OFL.txt
        data/fonts/extra/sora-OFL.txt
        data/fonts/extra/spacegrotesk-OFL.txt
        data/fonts/extra/syne-OFL.txt
    SOURCES src/addressbridge.h src/desktopcolors.h src/shield.h src/historybridge.h src/resources.h ${NOTIFIER_HEADER} src/files.h src/gpubridge.h src/librarybridge.h src/updatebridge.h src/importbridge.h src/passwordbridge.h src/storebridge.h src/defaultbrowser.h
    IMPORTS QtQuick
)
set_target_properties(velum PROPERTIES QT_QML_MODULE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Velum)
target_compile_definitions(velum PRIVATE VELUM_VERSION="${VELUM_RELEASE}" VELUM_UPDATE_KEY="${VELUM_UPDATE_KEY}")
if(WIN32)
    set_target_properties(velum PROPERTIES WIN32_EXECUTABLE TRUE)
    target_sources(velum PRIVATE installer/velum.rc)
endif()
target_include_directories(velum PRIVATE src)
target_link_libraries(velum PRIVATE velumcore Qt6::Concurrent Qt6::Quick Qt6::QuickControls2 Qt6::WebEngineQuick)

enable_testing()
add_executable(test_core tests/test_core.cpp)
target_link_libraries(test_core PRIVATE velumcore Qt6::Test)
add_test(NAME core COMMAND test_core)
if(NOT WIN32)
add_test(NAME keyring COMMAND ${CMAKE_SOURCE_DIR}/tests/run-keyring.sh $<TARGET_FILE:test_core>)
set_tests_properties(keyring PROPERTIES SKIP_RETURN_CODE 77)
endif()
if(NOT WIN32)
add_test(NAME ui COMMAND ${CMAKE_SOURCE_DIR}/tests/run-ui.sh)
endif()

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
