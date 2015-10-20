-- Copyright (c) 2015 Sebastian Hodapp
-- https://github.com/sebastianhodapp/ESPbootloader

-- Improved by Simonarde Jr.
-- https://github.com/simonardejr/ESPbootloader


-- Change ssid and password of AP in configuration mode
ssid = "WEETHING_" ..node.chipid()
psw  = "weethings"

print("AP SETTINGS: SSID "..ssid.." PSW "..psw)

-- If GPIO0 changes during the countdown, launch config
gpio.mode(3, gpio.INT)
gpio.trig(3,"both",function()
    print("we pressed GPIO0")
     tmr.stop(0)
     dofile("run_config.lua")
end)

local function test_config()
    return pcall(function ()
      dofile("config.lc")
    end)
end

local countdown = 5


tmr.alarm(1, 5000, 1, function()
	if wifi.sta.getip() == nil or not test_config() then
		print("IP unavailable, waiting.")
	else
        tmr.stop(0)
		tmr.stop(1)
		print("Connected, IP is "..wifi.sta.getip())
		dofile("run_program.lua")
	end
end)

tmr.alarm(0, 1000, 1, function()
    print("Check: "..countdown)
    countdown = countdown -1
    if (countdown == 0) then
        gpio.mode(3, gpio.FLOAT)
        tmr.stop(0)
        if pcall(function ()
            dofile("config.lc")
        end) then
            print("We found config file")
            tmr.stop(1)
            dofile("run_program.lua")
        else
            print("Enter configuration mode")
            dofile("run_config.lua")
        end
    end
end)
