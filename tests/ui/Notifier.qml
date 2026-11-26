pragma Singleton
import QtQuick
// Stand-in for the C++ desktop notifications.
QtObject { signal activated(); function show(n) {} }
