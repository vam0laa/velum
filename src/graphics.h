#pragma once
#include <QString>

// On laptops with an NVIDIA card next to an AMD or Intel one, the engine may draw the page
// on NVIDIA while the window lives on the other card. The picture cannot cross over and the
// page stays black.
namespace graphics {

// True when `drm` (normally /sys/class/drm) lists an NVIDIA card and also another maker's card.
bool hybridWithNvidia(const QString &drm);

// Keeps the engine on the same card as the window. Must run before the engine starts.
// Setting VELUM_USE_NVIDIA=1 turns this off.
void prepare();

}
