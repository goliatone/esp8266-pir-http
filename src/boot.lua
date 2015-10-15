--- Set up WiFi, we want to move this to a config web portal
print("Executing boot.lua")
print("Setting up wifi")

--- Include utils
-- util = dofile("util.lua")()

--- we load config file, hardcoded values in config.lua
--- file, declared as global
CONFIG_FILE = "config.lua"
c = file.list()
if c[CONFIG_FILE] then
  dofile(CONFIG_FILE)
end


wifi.setmode(wifi.STATION)
wifi.sleeptype(wifi.NONE_SLEEP)
wifi.sta.config(SSID, PSWD)

wifi.sta.connect()

--- Start the WiFi connection
local cnt = 0

local WIFI_ALARM = 1
local WIFI_DELAY = 1000
local PROGRAM_FILE = "pir.lua"

tmr.alarm(WIFI_ALARM, WIFI_DELAY, 1, function()
    if wifi.sta.status() ~= 5 and cnt < 20 then
        print("Connecting..."..cnt)
        cnt = cnt + 1
    else
        tmr.stop(WIFI_ALARM)
        print("** Done..."..wifi.sta.getip())

        --- create sensor instance
        local sensor = dofile(PROGRAM_FILE)({
            ip = IP,
            port = PORT,
            endpoint = ENDPOINT,
            pir = PIR,
            led = LED
        })

        --- trigger self registration script
        local manager = dofile(SELF_REGISTRATION)(IP, PORT, REGISTRATION_ENDPOINT)

        manager.register(function()
            print("On self registration complete.")
            --- manager is registered, fire it up!
            sensor.initialize()
        end)
    end
end)
