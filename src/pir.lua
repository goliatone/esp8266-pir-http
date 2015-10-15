
local exports = function(config)

    local self = {}
    --- configuration options
    self.PIR = config.pir
    self.LED = config.led
    self.IP = config.ip
    self.PORT = config.port
    self.ENDPOINT = config.endpoint

    print("sensor config: IP "..config.ip)
    print("sensor config: LED "..config.led)
    print("sensor config: PIR "..config.pir)
    print("sensor config: PORT "..config.port)
    print("sensor config: ENDPOINT "..config.endpoint)

    self.movement = 0

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
            util.httpPost(self.IP, self.PORT, self.ENDPOINT, {movement = movement})
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
