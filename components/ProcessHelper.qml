import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    width: 0
    height: 0

    property var runCommand: _runCommand
    property var _pendingCallback: null
    property var _queue: []

    function _runCommand(args, onDone) {
        if (!Array.isArray(args)) return
        var proc = processLauncher.createObject(root, { command: args })
        if (onDone) {
            proc.onRunningChanged.connect(function() {
                if (!proc.running) {
                    onDone()
                    proc.destroy()
                }
            })
        }
        proc.running = true
    }

    Component {
        id: processLauncher
        Process {
        }
    }
}
