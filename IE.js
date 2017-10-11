function CheckIE()
{
	var Browser;
    Browser = navigator.userAgent;
    if (Browser.indexOf("Trident") == -1)
    {
        
    }
    else
    {
    	window.alert("It looks like you're using Internet Explorer! The tool will only work in Mozilla Firefox or Google Chrome.")
    }
}

window.onload = CheckIE()