local reload = [[<script type='text/javascript'>
    window.REDIRECT = 'http://192.168.1.1';
    var timeout = 30;window.onload=function(){function countdown() {
    if ( typeof countdown.counter == 'undefined' ) {countdown.counter = timeout;}
    if(countdown.counter > 0){document.getElementById('count').innerHTML = countdown.counter--; setTimeout(countdown, 1000);}
    else {location.href = window.REDIRECT;};};countdown();};
    </script><h2>Autoconfiguration will end in <span id='count'></span> seconds</h2>
    <p>If the device disconnects, just reboot...</p>
    </body></html>]]

return reload
