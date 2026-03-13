import Quickshell
import QtQuick

Item {
    id: mangoWM
    
    property var sharedData: null
    property var tags: []
    property var workspaces: tags // Compatibility alias
    property var focusedWorkspace: null
    
    Timer {
        id: refreshTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }
    
    function refresh() {
        if (!sharedData || !sharedData.runCommand) return
        
        var tmp = "/tmp/mango_tags_" + Math.random().toString(36).substring(7)
        sharedData.runCommand(['sh', '-c', 'mmsg -g -t > ' + tmp], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    parseTags(out)
                    sharedData.runCommand(['rm', '-f', tmp])
                }
            }
            xhr.send()
        })
    }
    
    function parseTags(data) {
        // Example output:
        // eDP-1 tag 1 0 2 0
        // eDP-1 tag 2 1 1 1
        // ...
        // eDP-1 tags 7 2 0
        
        var lines = data.split('\n')
        var newTags = []
        var primaryFocused = null
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || line.includes("tags")) continue
            
            var parts = line.split(/\s+/)
            if (parts.length >= 6 && parts[1] === "tag") {
                var tagId = parseInt(parts[2])
                var selected = parts[3] === "1"
                var occupied = parts[4] !== "0"
                var urgent = parts[5] === "1"
                
                var tagObj = {
                    id: tagId,
                    selected: selected,
                    occupied: occupied,
                    urgent: urgent,
                    isFocused: selected // In MangoWM, multiple can be selected, but we treat selected as focused for UI
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
    
    function dispatch(command, arg) {
        if (!sharedData || !sharedData.runCommand) return
        
        if (command === "workspace") {
            sharedData.runCommand(['mmsg', '-s', '-t', arg.toString()])
            // Optimistic update or wait for next refresh
            refresh()
        }
    }
}
