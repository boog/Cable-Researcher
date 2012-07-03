debug = window.location.protocol == 'file:';
serverUrl = debug ? "http://localhost:8080" : "data";
tagsPath = "/tags";
queryPath = "/query";
itemPath = "/item";
DEFAULT_DATE = "2010-02-28";

// Popover cookie name
c_name="CourageIsContagious";
c_value = "SaveBradleyManning";

function setCookie(c_name, value, exdays) {
    var exdate = new Date();
    exdate.setDate(exdate.getDate() + exdays);
    var c_value = escape(value) + ((exdays == null) ? "": "; expires=" + exdate.toUTCString());
    document.cookie = c_name + "=" + c_value;
}

function getCookie(c_name) {
    var i,
    x,
    y,
    ARRcookies = document.cookie.split(";");
    for (i = 0; i < ARRcookies.length; i++)
    {
        x = ARRcookies[i].substr(0, ARRcookies[i].indexOf("="));
        y = ARRcookies[i].substr(ARRcookies[i].indexOf("=") + 1);
        x = x.replace(/^\s+|\s+$/g, "");
        if (x == c_name)
        {
            return unescape(y);
        }
    }
}