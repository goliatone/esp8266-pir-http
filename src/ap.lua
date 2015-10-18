attempts = 0
staip = nil

-- AP configuration
apcfg = {}
apcfg.ssid="WEETHING_"..node.chipid()
apcfg.pwd="weethings"

ipcfg = {}
ipcfg.ip = "192.168.1.1"
ipcfg.netmask = "255.255.255.0"
ipcfg.gateway = "192.168.1.1"

--create AP
wifi.setmode(wifi.SOFTAP)
wifi.ap.config(apcfg)

ap_mac = wifi.ap.getmac()

wifi.ap.setip(ipcfg)

print(wifi.ap.getip())

-- get AP IP, don't know why, but without it everything breaks
tmr.alarm(2, 500, 0, wifi.ap.getip)

--create HTTP server
srv = net.createServer(net.TCP)

srv:listen(80, function(conn)
    conn:on("receive", function(conn, payload)
        --print(payload)
        --webpage header
        local header = "<!DOCTYPE html><html lang='en'><body><h1>Wireless setup</h1><br/>"
        conn:send(header)
        --print(wifi.sta.status())
        if wifi.sta.status() ~= 5 then
            --TODO better getting of ssid and password
            --parse GET response
            local parameters = string.match(payload, "^GET(.*)HTTP\/1.1")
            if parameters then
                ssid = string.match(parameters, "SSID=([a-zA-Z0-9+]+)")
                password = string.match(parameters, "PASS=([a-zA-Z0-9+]+)")
            end
            if ssid and password then
                --wait for 30 seconds and refresh webpage (wait for IP)
                local refresh = [[<script type='text/javascript'>
                    var timeout = 30;window.onload=function(){function countdown() {
                    if ( typeof countdown.counter == 'undefined' ) {countdown.counter = timeout;}
                    if(countdown.counter > 0){document.getElementById('count').innerHTML = countdown.counter--; setTimeout(countdown, 1000);}
                    else {location.href = 'http://192.168.1.1';};};countdown();};
                    </script><h2>Autoconfiguration will end in <span id='count'></span> seconds</h2></body></html>]]
                conn:send(refresh)
                conn:close()

                ssid = string.gsub(ssid,'+',' ')
                print("ssid: '"..ssid.."' password: '"..password.."'")
                --switch to STATIONAP and connect
                wifi.setmode(wifi.STATIONAP)
                -- configure the module so it can connect to the network using the received SSID and password
                wifi.sta.config(ssid, password)
                wifi.sta.autoconnect(1)
                attempts = 0
                --wait for IP
                tmr.alarm (1, 500, 1, function ()
                    if wifi.sta.getip () ~= nil then
                        tmr.stop(1)
                        staip = wifi.sta.getip()
                        print("Config done, IP is " .. staip)
                    end
                    if attempts > 50 then
                        tmr.stop(1)
                        --print("Cannot connect to AP")
                    end
                    print(attempts)
                    attempts = attempts + 1
                end)
                --save config to file
                file.open("config.lua","w+")
                file.writeline('ssid = "'..ssid..'"')
                file.writeline('password = "'..password..'"')
                file.flush()
                file.close()
                node.compile("config.lua")
                file.remove("config.lua")
            else
                --Print error and retry
                if attempts > 50 then
                    if (wifi.sta.status() == 2) then
                        error_message = "Wrong network password, try again"
                        conn:send(error_message)
                    elseif (wifi.sta.status() == 3) then
                        error_message = "Could not find network, try again"
                    else
                        error_message = "Cannot connect to network, try again"
                    end
                    conn:send("<h2 style='color:red'>"..error_message.."</h2>")
                end
                --Main configuration web page
                local index = [[<h2>The module MAC address is: ]].. ap_mac..[[</h2>
                    <h2>Enter SSID and Password for your WIFI router</h2>
                    <form action='' method='get' accept-charset='ascii'>
                    SSID:
                    <input type='text' name='SSID' value='' maxlength='32' placeholder='your network name'/>
                    <br />
                    Password:
                    <input type='text' name='PASS' value='' maxlength='100' placeholder='network password'/>
                    <input type='submit' value='Submit' />
                    </form> </body> </html>]]
                conn:send(index)
                conn:close()
            end
        else
            --Successfully configured message
            local success = [[<h3>Configuration is now complete</h3>
                <h4>The module MAC address is: ]].. ap_mac..[[</h4>
                <h4>IP address is: ]]..staip..[[</h4>
                <h4>Rebooting now...</h4>
                </body> </html>]]
            conn:send(success)
            conn:close()
            print('Configuration complete - reboot')
            tmr.alarm (0, 4000,0, function() node.restart() end)
        end
    end)
    conn:on("sent",function(conn) conn:close() end)
end)
