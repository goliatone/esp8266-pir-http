-- Start your normal program routines here
print("Execute code")
dofile("config.lc")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid,password)
wifi.sta.connect()

ssid=nil
password=nil

-- We made it here...
print("We are here... ready to go!")
