import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: mangoWM
    
    property var sharedData: null
    property var tags: []
    property var workspaces: tags // Compatibility alias
    property var focusedWorkspace: null
    
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
