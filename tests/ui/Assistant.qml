pragma Singleton
import QtQuick
// Stand-in for the assistant, whose talking is tested in C++.
QtObject {
    property bool enabled: false
    property string address: "http://127.0.0.1:11434"
    property string model: "small"
    property var models: ["small"]
    property string server: "ok"
    property bool busy: false
    property string answer: ""
    property string problem: ""
    property var asked: []
    function look() {}
    function ask(question, material, turkish) { if (!enabled) return; asked.push({ question: question, material: material }); answer = "yanıt" }
    function cancel() { busy = false }
    function forget() { answer = ""; problem = "" }
}
