import QtQuick

QtObject {
    id: utils
    
    // Funkcja formatująca czas w sekundach do formatu MM:SS lub HH:MM:SS
    function formatTime(sec) {
        if (!sec || sec <= 0) return "0:00"
        var s = Math.floor(sec % 60)
        var m = Math.floor((sec / 60) % 60)
        var h = Math.floor(sec / 3600)
        if (h > 0) return h + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
        return m + ":" + (s < 10 ? "0" + s : s)
    }
    
    // Funkcja parsująca czas z różnych formatów do sekund
    function parseTimeToSeconds(str) {
        if (!str) return 0
        var n = parseFloat(str)
        if (!isNaN(n) && str.indexOf(':') === -1) return n
        var parts = str.split(':').map(function(x) { return parseInt(x) || 0 })
        if (parts.length === 2) {
            return parts[0] * 60 + parts[1]
        } else if (parts.length === 3) {
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        }
        return 0
    }
    
    // Funkcja formatująca datę i czas
    function formatDateTime() {
        var now = new Date()
        var hours = now.getHours()
        var minutes = now.getMinutes()
        var timeStr = (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes)
        
        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        
        var dayName = days[now.getDay()]
        var day = now.getDate()
        var month = months[now.getMonth()]
        var year = now.getFullYear()
        
        var dateStr = dayName + ", " + month + " " + day + ", " + year
        
        return { time: timeStr, date: dateStr }
    }
    
    // Shadow helper - returns shadow properties based on elevation level
    // Levels: 0 (none), 1 (subtle), 2 (medium/cards), 3 (modals), 4 (overlays)
    function getShadowProperties(level) {
        switch(level) {
            case 0: return { blur: 0, offset: 0, opacity: 0 }
            case 1: return { blur: 4, offset: 0, opacity: 0.1 }
            case 2: return { blur: 8, offset: 2, opacity: 0.15 }
            case 3: return { blur: 16, offset: 4, opacity: 0.2 }
            case 4: return { blur: 24, offset: 8, opacity: 0.25 }
            default: return { blur: 8, offset: 2, opacity: 0.15 }
        }
    }
    
    // Gradient helper - creates subtle gradient from base color
    function createAccentGradient(baseColor) {
        // Lighten the color by 10% for gradient end
        var r = Qt.color(baseColor).r
        var g = Qt.color(baseColor).g
        var b = Qt.color(baseColor).b
        var lighter = Qt.rgba(Math.min(1, r * 1.1), Math.min(1, g * 1.1), Math.min(1, b * 1.1), 1)
        return [baseColor, lighter]
    }
    
    // Color helper - darken color for pressed states
    function darkenColor(baseColor, factor) {
        var c = Qt.color(baseColor)
        return Qt.rgba(c.r * factor, c.g * factor, c.b * factor, c.a)
    }
    
    // Color helper - lighten color for hover states
    function lightenColor(baseColor, factor) {
        var c = Qt.color(baseColor)
        return Qt.rgba(Math.min(1, c.r * factor), Math.min(1, c.g * factor), Math.min(1, c.b * factor), c.a)
    }
}

