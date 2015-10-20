--- Set up WiFi, we want to move this to a config web portal
print("Executing boot.lua")
print("Setting up wifi")

--- Include utils
-- util = dofile("util.lua")()

--- we load config file, hardcoded values in config.lua
--- file, declared as global

c = file.list()
if not c["config.lc"] then
    dofile("wifi.lua")
else

    dofile("config.lc")

    wifi.setmode(wifi.STATION)
    wifi.sleeptype(wifi.NONE_SLEEP)
    wifi.sta.config(ssid, password)

    wifi.sta.connect()

    --- Start the WiFi connection
    local count = 0
    local maxtries = 20

    local WIFI_ALARM = 1
    local WIFI_DELAY = 1000

    tmr.alarm(WIFI_ALARM, WIFI_DELAY, 1, function()
        if wifi.sta.status() ~= 5 and count < maxtries then
            print("Connecting..."..count)
            count = count + 1
        else
            tmr.stop(WIFI_ALARM)
            if count == maxtries then
                print("Unable to connect to WiFi")
            else
                print("** Done..."..wifi.sta.getip())
                dofile("main.lua")
            end
        end
    end)
end
