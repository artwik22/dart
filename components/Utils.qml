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
}

