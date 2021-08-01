.pragma library

var lastDate = "" // "2016-03-23", date of the last fetched summary
var personalAccessToken = ""

function dateString(date, month, year) {
    var now = new Date()
    if (year === undefined)
        year = now.getFullYear();
    if (month === undefined)
        month = now.getMonth();
    if (date === undefined)
        date = now.getDate();
    now = new Date(year, month, date, 1, 1, 1, 1);
    return
}
