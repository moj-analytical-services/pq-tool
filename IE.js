function CheckIE()
{
	var Browser;
    Browser = navigator.userAgent;
    if (Browser.indexOf("Trident") == -1)
    {
        
    }
    else
    {
    	window.alert("Welcome! Just a quick reminder that I cannot be run in Internet Explorer, try Mozilla Firefox or Google Chrome instead.")
    }
}

window.onload = CheckIE()


