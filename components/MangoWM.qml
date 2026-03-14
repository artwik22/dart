import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: mangoWM
    
    property var sharedData: null
    property var tags: []
    property var workspaces: tags // Compatibility alias
    property var focusedWorkspace: null
    property bool fullscreen: false
    
    Timer {
        id: refreshTimer
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    function refresh() {
        if (!sharedData || !sharedData.runCommand) return
        
        var tmp = "/tmp/mango_tags_refresh"
        var fs_tmp = "/tmp/mango_fullscreen_refresh"
        
        // Refresh tags
        sharedData.runCommand(['sh', '-c', 'mmsg -g -t > ' + tmp], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    parseTags(out)
                }
            }
            xhr.send()
        })
        
        // Refresh fullscreen status
        sharedData.runCommand(['sh', '-c', 'mmsg -g -m > ' + fs_tmp], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + fs_tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    parseFullscreen(out)
                }
            }
            xhr.send()
        })
    }

    function parseFullscreen(data) {
        var lines = data.split('\n')
        var isFullscreen = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
            var parts = line.split(/\s+/)
            // Format: "output fullscreen status" (e.g., "eDP-1 fullscreen 1")
            if (parts.length >= 3 && parts[1] === "fullscreen") {
                if (parts[2] === "1") {
                    isFullscreen = true
                    break
                }
            }
        }
        if (mangoWM.fullscreen !== isFullscreen) {
            mangoWM.fullscreen = isFullscreen
        }
    }

    function parseTags(data) {
        var lines = data.split('\n')
        var newTags = []
        var primaryFocused = null
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || line.includes("tags")) continue
            
            var parts = line.split(/\s+/)
            if (parts.length >= 6 && parts[1] === "tag") {
                var tagId = parseInt(parts[2])
                if (tagId > 4) continue // Limit to 4 tags
                
                var selected = parts[3] === "1"
                var occupied = parts[4] !== "0"
                var urgent = parts[5] === "1"
                
                var tagObj = {
                    id: tagId,
                    selected: selected,
                    occupied: occupied,
                    urgent: urgent,
                    isFocused: selected
                }
                
                newTags.push(tagObj)
                if (selected && primaryFocused === null) {
                    primaryFocused = tagObj
                }
            }
        }
        
        if (newTags.length > 0) {
            mangoWM.tags = newTags
            mangoWM.focusedWorkspace = primaryFocused
        }
    }
    
    Component.onCompleted: refresh()

    function dispatch(command, arg) {
        if (!sharedData || !sharedData.runCommand) return
        
        if (command === "workspace") {
            sharedData.runCommand(['mmsg', '-s', '-t', arg.toString()])
            refreshTimer.start() // Immediate poll trigger
        }
    }
}
