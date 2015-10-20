-- Initialize the board but give us a few seconds to send a
-- file.remove('init.lua')

print("init.lua executing")

local BOOT_ALARM = 0
local BOOT_DELAY = 2000
local BOOT_FILE = "boot.lua"

print("starting delay to run "..BOOT_FILE)

tmr.alarm(BOOT_ALARM, BOOT_DELAY, 0, function()
    print("Stop alarm... dofile('"..BOOT_FILE.."')")
    tmr.stop(BOOT_ALARM)
    dofile(BOOT_FILE)
end)
