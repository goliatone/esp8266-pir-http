attempts = 0
staip = nil

-- AP configuration
apcfg = {}
apcfg.pwd = "weethings"
apcfg.ssid = "WEETHING_"..node.chipid()

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


local unescape = function (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

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
            print("Parameters: "..parameters)

            local _GET = {}
            if (parameters ~= nil) then
                for k, v in string.gmatch(parameters, "([_%w]+)=([^%&]+)&*") do
                    print("KEY "..k.." value "..v)
                    _GET[k] = unescape(v)
                end
                -- ssid = string.match(parameters, "ssid=([a-zA-Z0-9+]+)")
                -- password = string.match(parameters, "password=([a-zA-Z0-9+]+)")
            end

            print("Collected _GET")
            for k , v in pairs(_GET) do
                print(tostring(k).."  "..tostring(v))
            end

            if _GET.ssid and _GET.password then
                --wait for 30 seconds and refresh webpage (wait for IP)
                local refresh = [[<script type='text/javascript'>
                    var timeout = 30;window.onload=function(){function countdown() {
                    if ( typeof countdown.counter == 'undefined' ) {countdown.counter = timeout;}
                    if(countdown.counter > 0){document.getElementById('count').innerHTML = countdown.counter--; setTimeout(countdown, 1000);}
                    else {location.href = 'http://192.168.1.1';};};countdown();};
                    </script><h2>Autoconfiguration will end in <span id='count'></span> seconds</h2>
                    <p>If the device disconnects, just reboot...</p>
                    </body></html>]]
                conn:send(refresh)
                conn:close()

                print("ssid: '".._GET.ssid.."' password: '".._GET.password.."'")
                --switch to STATIONAP and connect
                wifi.setmode(wifi.STATIONAP)
                -- configure the module so it can connect to the network using the received SSID and password
                wifi.sta.config(_GET.ssid, _GET.password)
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
                -- write every variable in the form
                for k,v in pairs(_GET) do
                    file.writeline(k..' = "'..v ..'"')
                end
                file.flush()
                file.close()
                node.compile("config.lua")
                -- file.remove("config.lua")
            else
                --Print error and retry
                if attempts > 50 then
                    if (wifi.sta.status() == 2) then
                        error_message = "Wrong network password, try again"
                    elseif (wifi.sta.status() == 3) then
                        error_message = "Could not find network, try again"
                    else
                        error_message = "Cannot connect to network, try again"
                    end
                    conn:send("<h2 style='color:red'>"..error_message.."</h2>")
                end
                --Main configuration web page
                local index = [[<h2>The module MAC address is: ${ap_mac}</h2>
                    <h2>Enter SSID and Password for your WIFI router</h2>
                    <form action='' method='get' accept-charset='ascii'>
                    SSID:
                    <input type='text' name='ssid' value='' maxlength='32' placeholder='your network name'/>
                    <br/>
                    <label>Password:</label>
                    <input type='password' name='password' value='' maxlength='100' placeholder='network password'/>
                    <label>Service Endpoint:</label>
                    <input type='text' name='service_endpoint' value='' placeholder='Service endpoint'/>
                    <label>Registration Endpoint:</label>
                    <input type='text' name='registration_endpoint' value='' placeholder='Registration endpoint'/>
                    <input type='submit' value='Submit' />
                    </form> </body> </html>]]

                index = template(index)
                conn:send(index)
                conn:close()
            end
        else
            --Successfully configured message
            local success = [[<h3>Configuration is now complete</h3>
                <h4>The module MAC address is: ${ap_mac}</h4>
                <h4>IP address is: ${staip}</h4>
                <h4>Rebooting now...</h4>
                </body> </html>]]

            success = template(success)
            conn:send(success)
            conn:close()
            print('Configuration complete - reboot')
            tmr.alarm (0, 4000,0, function() node.restart() end)
        end
    end)
    conn:on("sent",function(conn) conn:close() end)
end)

function template(buf)
    return buf:gsub('($%b{})', function(w)
        return _G[w:sub(3, -2)] or ""
    end)
end
