--- Set up WiFi, we want to move this to a config web portal
print("Executing boot.lua")
print("Setting up wifi")

--- define default values
SSID = ""
PSWD = ""

--- we load config file
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
        dofile(PROGRAM_FILE)
    end
end)
