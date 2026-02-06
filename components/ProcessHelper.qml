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
        _queue.push({ cmd: args, cb: onDone || null })
        _processNext()
    }

    function _processNext() {
        if (sharedProcess.running || _queue.length === 0) return
        var next = _queue.shift()
        sharedProcess.command = next.cmd
        _pendingCallback = next.cb
        sharedProcess.running = true
    }

    Process {
        id: sharedProcess
        onRunningChanged: {
            if (!sharedProcess.running) {
                if (root._pendingCallback) {
                    var cb = root._pendingCallback
                    root._pendingCallback = null
                    if (typeof cb === "function") cb()
                }
                root._processNext()
            }
        }
    }
}
