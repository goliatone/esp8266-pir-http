
local exports = function()
    self = {}
    self.movement = 0

    function build_post_request(path, value)
        payload = cjson.encode(value)

        return "POST " .. path .. " HTTP/1.1\r\n" ..
        "Host: " .. IP .. "\r\n" ..
        "Connection: close\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: " .. string.len(payload) .. "\r\n" ..
        "\r\n" .. payload
    end

    function result_post(payload)

        conn = net.createConnection(net.TCP, 0)
        conn:connect(PORT, IP)

        --- Create HTTP POST raw headers and body
        request = build_post_request(ENDPOINT, payload)

        conn:send(request, function()
            print("Request sent")
            conn:close()
        end)
    end

    --- Get temp and send data to thingspeak.com
    local function collect_data()
        --- Read PIR value
        local movement = gpio.read(PIR)

        --- If we have a change in state
        if self.movement == movement then
            --- and the current state is off
            if self.movement == 0 then
                --- switch LED off
                gpio.write(LED, gpio.HIGH)
            end
        else
            print("Movement")
            --- we store our current state
            self.movement = movement
            --- switch LED on
            gpio.write(LED, gpio.LOW)
            --- POST current value
            result_post({movement = movement})
        end
    end

    ------ MAIN ------
    -- send data every X ms to thing speak
    function self.initialize()
        print("Initializing PIR module")
        --- set GPIO modes
        gpio.mode(LED, gpio.OUTPUT)
        gpio.mode(PIR, gpio.INT)

        --- capture changes on PIR
        gpio.trig(PIR, "both", collect_data)

        --- check every 2 seconds the PIR status
        tmr.alarm(2, 2000, 1, collect_data)
    end

    return self
end

return exports
