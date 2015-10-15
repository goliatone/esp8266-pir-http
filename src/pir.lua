
local exports = function(config)

    local self = {}
    --- configuration options
    self.PIR = config.pir
    self.LED = config.led

    self.IP = config.ip
    self.PORT = config.port
    self.ENDPOINT = config.endpoint

    print("------")
    print("sensor config: LED "..config.led)
    print("sensor config: PIR "..config.pir)
    print("sensor config: IP "..config.ip)
    print("sensor config: PORT "..config.port)
    print("sensor config: ENDPOINT "..config.endpoint)

    self.movement = 1

    --- TODO: move out
    function self.build_post_request(ip, path, value)
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

    function self.httpPost(ip, port, endpoint, payload)

        local conn = net.createConnection(net.TCP, 0)
        conn:connect(port, ip)

        --- Create HTTP POST raw headers and body
        local request = self.build_post_request(ip, endpoint, payload)

        conn:send(request, function()
            print("Request sent")
            conn:close()
        end)
    end
    ---

    --- Get temp and send data to thingspeak.com
    function self.collect_data()
        --- Read PIR value
        local movement = gpio.read(self.PIR)

        --- If we have a change in state
        if self.movement == movement then
            --- and the current state is off
            if self.movement == 0 then
                --- switch LED off
                gpio.write(self.LED, gpio.HIGH)
            end
        else
            print("Movement: "..movement)
            --- we store our current state
            self.movement = movement
            --- switch LED on
            gpio.write(self.LED, gpio.LOW)

            --- POST current value
            self.httpPost(self.IP, self.PORT, self.ENDPOINT, {movement = movement})
        end
    end

    ------ MAIN ------
    -- send data every X ms to thing speak
    function self.initialize()
        print("Initializing PIR module led: ".. self.LED .." pir: ".. self.PIR)

        --- set GPIO modes
        gpio.mode(self.LED, gpio.OUTPUT)
        gpio.mode(self.PIR, gpio.INT)

        --- capture changes on PIR
        gpio.trig(self.PIR, "both", self.collect_data)

        --- check every 2 seconds the PIR status
        tmr.alarm(2, 2000, 1, self.collect_data)
    end

    return self
end

return exports
