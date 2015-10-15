PIR = 2
LED = 0
DEBUG = true
IP = "192.168.1.146"
PORT = 8976
ENDPOINT = "/pir/movement"

--- Self registration 
SELF_REGISTRATION = "register.lua"
REGISTRATION_ENDPOINT = "/pir/movement"

chipId = node.chipid()
gpio.mode(LED, gpio.OUTPUT)
gpio.mode(PIR, gpio.INT)

movement = 0


local manager = dofile(SELF_REGISTRATION)(IP, PORT, REGISTRATION_ENDPOINT)
manager.register()

function build_post_request(path, value)
    payload = cjson.encode(value)

    return "POST " .. path .. " HTTP/1.1\r\n" ..
    "Host: " .. IP .. "\r\n" ..
    "Connection: close\r\n" ..
    "Content-Type: application/json\r\n" ..
    "Content-Length: " .. string.len(payload) .. "\r\n" ..
    "\r\n" .. payload
end

function result_post(alarm)
    
    conn = net.createConnection(net.TCP, 0)
    conn:connect(PORT, IP)

    --- Create HTTP POST raw headers and body
    request = build_post_request(ENDPOINT, {movement = alarm})

    conn:send(request, function()
        print("Request sent")
        conn:close()
    end)
end

--- Get temp and send data to thingspeak.com
local function collect_data()
    
    local alarm = gpio.read(PIR)
    
    if movement == alarm then
        if movement == 0 then
            gpio.write(LED, gpio.HIGH)
        end
    else
        print("Movement")
        published = true
        movement = alarm
        gpio.write(LED, gpio.LOW)
        result_post(alarm)
    end
end

------ MAIN ------
-- send data every X ms to thing speak
gpio.trig(PIR, "both", collect_data)

tmr.alarm(2, 2000, 1, collect_data)
