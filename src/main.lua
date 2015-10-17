http = require('http')

--- SERVICE
local service = {
    url = "http://192.168.1.147:8976/pir/movement"
}

function service.register(url, done)
    local payload = {}
    payload.status = "online"
    payload.type = "ESP8266"
    payload.tag = "PIR"
    payload.alias = node.chipid()

    local value = cjson.encode(payload)

    print("payload "..value)

    local contentType = "application/json"

    http.postContent(service.url, value, contentType, done)
end

--- PIR module
local pir = {
    LED = LED,
    PIR = PIR,
    movement = 0,
    url = "http://192.168.1.147:8976/pir/movement"
}

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
        local value = cjson.encode({movement = movement})
        print("payload "..value)
        local contentType = "application/json"
        http.postContent(pir.url, value, contentType, function()
            print("POSTED")
        end)
    end
end

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

--- RUN MAIN PROGRAM
service.register(url, function()
    print("Aaaand...we are done!")
    pir.initialize()
end)
