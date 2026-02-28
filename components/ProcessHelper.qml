import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    width: 0
    height: 0

    property var runCommand: _runCommand
    property var setTimeout: _setTimeout

    function _runCommand(args, onDone) {
        if (!Array.isArray(args)) return
        var proc = processLauncher.createObject(root, { command: args })
        proc.onRunningChanged.connect(function() {
            if (!proc.running) {
                if (typeof onDone === 'function') onDone()
                proc.destroy()
            }
        })
        proc.running = true
    }

    function _setTimeout(callback, interval) {
        var timer = timerComponent.createObject(root, { interval: interval || 0 })
        timer.triggered.connect(function() {
            if (typeof callback === 'function') callback()
            timer.destroy()
        })
        timer.running = true
    }

    Component {
        id: processLauncher
        Process { }
    }

    Component {
        id: timerComponent
        Timer { repeat: false }
    }
}
