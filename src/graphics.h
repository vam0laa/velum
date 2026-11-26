#pragma once
#include <QByteArray>
#include <QString>
#include <QStringList>

// On laptops with an NVIDIA card next to an AMD or Intel one, the engine may draw the page
// on NVIDIA while the window lives on the other card. The picture cannot cross over and the
// page stays black.
namespace graphics {

// True when `drm` (normally /sys/class/drm) lists an NVIDIA card and also another maker's card.
bool hybridWithNvidia(const QString &drm);

// On Hyprland, a window moved to another workspace could stop drawing and show its old
// picture stretched over half of it (Qt's Wayland side). Through XWayland it does not.
// Returns the screen's scale when XWayland will stay sharp, else 0. The arguments are the
// answers of "hyprctl monitors -j" and "hyprctl getoption xwayland:force_zero_scaling -j".
double xwaylandScale(const QByteArray &monitors, const QByteArray &zeroScaling);

// The engine switches for the one "use the graphics card" setting, to be added to its
// command line. `careful`: the last start with the extra switches did not finish, so
// leave them out. `linux_` adds the video decoding switches that only Linux has.
QByteArray engineFlags(bool accelerate, bool careful, bool linux_);

// Through XWayland a program does not learn the desktop's mouse pointer and would show
// another one. `answer` is what "gsettings get org.gnome.desktop.interface cursor-theme"
// said; returns that theme's name if it is installed in one of `folders`, else nothing.
QByteArray cursorTheme(const QByteArray &answer, const QStringList &folders);

// The library that draws X pointers ignores XCURSOR_THEME: it takes the theme called
// "default" from the folders in XCURSOR_PATH. This writes such a theme into `folder`
// that means `theme`.
bool writePointerFolder(const QString &folder, const QByteArray &theme);

// The desktop's pointer size, from the answer about "cursor-size"; 0 if unusable. It is
// passed on as it is: the compositor enlarges an XWayland pointer to the screen's scale.
int cursorSize(const QByteArray &answer);

// Chooses how to draw. Must run before the application is made.
// VELUM_WAYLAND=1 keeps Wayland; VELUM_USE_NVIDIA=1 leaves the graphics cards alone.
void prepare();

// Puts back the settings meant only for Velum, so that programs it starts do not get them.
// Call once the application exists.
void restoreEnvironment();

}
