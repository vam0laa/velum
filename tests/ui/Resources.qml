pragma Singleton
import QtQuick
// Stand-in for the C++ reader of /proc.
QtObject { function sample(pids) { return { total: { memory: 0, cpu: 0 } } } }
