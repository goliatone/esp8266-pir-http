-- Start your normal program routines here
dofile("config.lc")
print("Execute code ssid"..ssid.." psw "..password)
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid,password)
wifi.sta.connect()

ssid=nil
password=nil

-- We made it here...
print("We are here... ready to go!")
