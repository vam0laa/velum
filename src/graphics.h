#pragma once
#include <QByteArray>
#include <QString>

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

// Chooses how to draw. Must run before the application is made.
// VELUM_WAYLAND=1 keeps Wayland; VELUM_USE_NVIDIA=1 leaves the graphics cards alone.
void prepare();

// Puts back the settings meant only for Velum, so that programs it starts do not get them.
// Call once the application exists.
void restoreEnvironment();

}
