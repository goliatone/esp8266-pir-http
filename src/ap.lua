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


--create HTTP server
if srv ~= nil then
    srv.close()
    print("Closing existing server")
end
srv = net.createServer(net.TCP)

srv:listen(80, function(conn)
    conn:on("receive", function(conn, payload)

        print(payload)

        --webpage header
        local header = [[<!DOCTYPE html>
        <html lang='en'>
        <style>
        html { height:95%; font-family: Helvetica, Verdana,serif; color:#fafafa;background-color:#212121; margin:30px; }
        body{ width:80%; margin-left:auto; margin-right:auto; max-width:600px;}
        table,input[type=text],input[type=password] {width:100%}
        tr{line-height:30px;}
        </style>
        <body><h1>Wireless setup</h1><hr/>]]
        conn:send(header)
        --print(wifi.sta.status())
        if wifi.sta.status() ~= 5 then
            --parse GET response
            local parameters = string.match(payload, "^GET(.*)HTTP\/1.1")
            print("Parameters: "..parameters)

            local _GET = parsequery(parameters)

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
                    ]]
                    -- </body></html>]]
                conn:send(refresh)
                -- conn:close()

                print("ssid: '".._GET.ssid.."' password: '".._GET.password.."'")
                --switch to STATIONAP and connect
                wifi.setmode(wifi.STATIONAP)

                -- configure the module so it can connect to the network using the received SSID and password
                wifi.sta.config(_GET.ssid, _GET.password)
                wifi.sta.autoconnect(1)

                --wait for IP
                attempts = 0
                tmr.alarm (1, 500, 1, function ()
                    if wifi.sta.getip () ~= nil then
                        tmr.stop(1)
                        staip = wifi.sta.getip()
                        conn:send("<script>location.href = '"..staip.."';</script>", function(conn)
                            conn:close()
                        end)
                        print("Config done, IP is " .. staip)
                    end
                    if attempts > 50 then
                        tmr.stop(1)
                        conn:close()
                        print("Cannot connect to AP")
                    end
                    print(attempts)
                    attempts = attempts + 1
                end)

                --save config to file
                saveconfig(_GET, false)
            else
                --Print error and retry
                if attempts > 50 then
                    local error_message = geterror()
                    conn:send("<h2 style='color:red'>"..error_message.."</h2>")
                end
                --Main configuration web page
                --TODO: Make form dynamically using config object
                local index = [[<h2>The module MAC address is: <b>${ap_mac}</b></h2> <h3>Enter SSID and Password for your WIFI router</h3> <form action='' method='get' accept-charset='ascii'> <table><tbody> <tr> <td><label>SSID:</label></td></tr><tr> <td><input type='text' name='ssid' value='' maxlength='32' placeholder='your network name'/></td></tr><tr> <td><label>Password:</label></td></tr><tr> <td><input type='password' name='password' value='' maxlength='100' placeholder='network password'/></td></tr><tr> <td><label>Service Endpoint:</label></td></tr><tr> <td><input type='text' name='service_endpoint' value='' placeholder='Service endpoint'/></td></tr><tr> <td><label>Registration Endpoint:</label></td></tr><tr> <td><input type='text' name='registration_endpoint' value='' placeholder='Registration endpoint'/></td></tr><tr> <td><input type='submit' value='Submit'/></td></tr></tbody></table> </form> </body> </html>]]
                index = template(index)

                buffered(index, function(chunk)
                    conn:send(chunk)
                end, function()
                    conn:close()
                end)
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

    conn:on("sent", function(conn)
        print("connection sent, closing now")
        conn:close()
        collectgarbage()
    end)
end)

--[[
    Replace tokens from string using
    either the provided context or the
    global namespace `_G`.
]]
function template(buf, context)

    if context == nil
        context = _G
    end

    return buf:gsub('($%b{})', function(w)
        return context[w:sub(3, -2)] or ""
    end)
end

--[[
    Brek a string in chunks smaller than max frame
    length 1460.
]]
function buffered(str, send, ondone)
    print("buffering chunks")

    -- 1460 is the max we can send. Frames are actually 1500, but header
    index = 0; offset = 1400; total = string.len(str); i = 0;

    repeat
        chunk = string.sub(str, index, index + offset)
        index = index + offset
        send(chunk, index > total)
        i = i + 1
    until (index > total) or (i > 100)

    if ondone ~= nil then
        ondone()
    end
end

function saveconfig(dic, remove)
    file.open("config.lua","w+")
    -- write every variable in the form
    for k,v in pairs(dic) do
        file.writeline(k..' = "'..v ..'"')
    end

    file.flush()
    file.close()

    node.compile("config.lua")

    if remove then
        file.remove("config.lua")
    end
end

function geterror()
    local error_message = "Cannot connect to network, try again"

    if (wifi.sta.status() == 2) then
        error_message = "Wrong network password, try again"
    elseif (wifi.sta.status() == 3) then
        error_message = "Could not find network, try again"
    end

    return error_message
end

function parsequery(query)
    local payload = {}

    if (query ~= nil) then
        for k, v in string.gmatch(query, "([_%w]+)=([^%&]+)&*") do
            print("KEY "..k.." value "..v)
            payload[k] = unescape(v)
        end
    end

    return payload
end

function unescape(s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end
