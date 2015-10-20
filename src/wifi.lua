attempts = 0
staip = 0

local setap = function()
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
end

setap()

-- get AP IP, don't know why, but without it everything breaks
-- tmr.alarm(2, 500, 0, wifi.ap.getip)


local unescape = function (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

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
        local header = dofile("header.lua")

        if wifi.sta.status() ~= 5 then
            --parse GET response
            local parameters = string.match(payload, "^GET (.*) HTTP\/1.1")
            print("Parameters: "..parameters)

            local _GET = {}
            if (parameters ~= nil) then
                for k, v in string.gmatch(parameters, "([_%w]+)=([^%&]+)&*") do
                    print("KEY "..k.." value "..v)
                    _GET[k] = unescape(v)
                end
            end

            if _GET.ssid and _GET.password then
                --wait for 30 seconds and refresh webpage (wait for IP)
                local refresh = dofile("reload.lua")

                conn:send(header)
                conn:send(refresh)
                conn:close()

                print("ssid: '".._GET.ssid.."' password: '".._GET.password.."'")
                --switch to STATIONAP and connect
                wifi.setmode(wifi.STATIONAP)
                -- configure the module so it can connect to the network using the received SSID and password
                wifi.sta.config(_GET.ssid, _GET.password)
                wifi.sta.autoconnect(1)

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

                --wait for IP
                attempts = 0
                tmr.alarm (11, 1000, 1, function ()
                    if wifi.sta.getip () ~= nil then
                        tmr.stop(11)
                        staip = wifi.sta.getip()
                        -- setap()
                        print("Config done, IP is " .. staip)
                    end
                    if attempts > 50 then
                        tmr.stop(11)
                        -- setap()
                        print("Cannot connect to AP")
                    end
                    print(attempts)
                    attempts = attempts + 1
                end)
            else
                --Main configuration web page
                if(parameters == "/ip") then
                    local buf = cjson.encode({ip = staip})
                    payloadLen = string.len(buf)
                    conn:send("HTTP/1.1 200 OK\r\n")
                    conn:send("Content-Type    application/json; charset=UTF-8\r\n")
                    conn:send("Content-Length:" .. tostring(payloadLen) .. "\r\n")
                    conn:send("Connection:close\r\n\r\n")
                    conn:send(buf, function(client) client:close() end);
                else

                    conn:send(header)

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

                    local index = dofile("index.lua")
                    index = template(index)
                    buffered(index, function(chunk)
                        conn:send(chunk)
                    end, function()
                        conn:close()
                    end)
                end
            end
        else
            --Successfully configured message
            local success = dofile("success.lua")
            success = template(success)

            conn:send(header)
            conn:send(success)
            conn:close()

            print('Configuration complete - reboot')
            tmr.alarm (0, 4000,0, function()
                node.restart()
            end)
        end
    end)

    conn:on("sent",function(conn)
        print("Sent...close and collectgarbage")
        conn:close()
        collectgarbage()
    end)
end)

function template(buf)
    return buf:gsub('($%b{})', function(w)
        return _G[w:sub(3, -2)] or ""
    end)
end

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
