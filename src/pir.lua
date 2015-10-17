
local exports = function(config)

    local pir = {}
    --- configuration options
    pir.PIR = config.pir
    pir.LED = config.led

    pir.IP = config.ip
    pir.PORT = config.port
    pir.ENDPOINT = config.endpoint

    print("------")
    print("sensor config: LED "..config.led)
    print("sensor config: PIR "..config.pir)
    print("sensor config: IP "..config.ip)
    print("sensor config: PORT "..config.port)
    print("sensor config: ENDPOINT "..config.endpoint)

    pir.movement = 0

    --- TODO: move out
    function pir.build_post_request(ip, path, value)
        local payload = cjson.encode(value)
        print("ip "..ip.." path "..path.." value "..payload)

        local content = "POST " .. path .. " HTTP/1.1\r\n" ..
        "Host: " .. ip .. "\r\n" ..
        "Connection: close\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: " .. string.len(payload) .. "\r\n" ..
        "\r\n" .. payload

        return content
    end

    function pir.httpPost(ip, port, endpoint, payload)

        local conn = net.createConnection(net.TCP, 0)
        conn:connect(port, ip)

        --- Create HTTP POST raw headers and body
        local request = pir.build_post_request(ip, endpoint, payload)

        conn:send(request, function()
            print("Request sent")
            conn:close()
        end)
    end
    ---

    --- Get temp and send data to thingspeak.com
    function pir.collect_data()
        --- Read PIR value
        local movement = gpio.read(pir.PIR)

        --- If we have a change in state
        if pir.movement == movement then
            --- and the current state is off
            if pir.movement == 0 then
                --- switch LED off
                gpio.write(pir.LED, gpio.HIGH)
            end
        else
            print("Movement: "..movement)
            --- we store our current state
            pir.movement = movement
            --- switch LED on
            gpio.write(pir.LED, gpio.LOW)

            --- POST current value
            pir.httpPost(pir.IP, pir.PORT, pir.ENDPOINT, {movement = movement})
        end
    end

    ------ MAIN ------
    -- send data every X ms to thing speak
    function pir.initialize()
        print("Initializing PIR module led: ".. pir.LED .." pir: ".. pir.PIR)

        --- set GPIO modes
        gpio.mode(pir.LED, gpio.OUTPUT)
        gpio.mode(pir.PIR, gpio.INT)

        --- capture changes on PIR
        gpio.trig(pir.PIR, "both", pir.collect_data)

        --- check every 2 seconds the PIR status
        tmr.alarm(2, 2000, 1, pir.collect_data)
    end

    return pir
end

return exports
