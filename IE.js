window.onload = CheckIE

function CheckIE()
{
	var Browser;
    Browser = navigator.userAgent;
    if (Browser.indexOf("Trident") == -1)
    {
        
    }
    else alert("Welcome! Just a quick reminder that I cannot be run in Internet Explorer, try Mozille Firefox or Google Chrome instead.")
}