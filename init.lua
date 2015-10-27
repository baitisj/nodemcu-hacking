wifi.setmode(wifi.STATION)
wifi.sta.config("BaitisBasement","1011121110")
wifi.sta.connect()

local led=require("led")
led.blink(300)

tmr.alarm(0, 1000, 1, function()   
  print("Waiting for WLAN. Press USER to cancel.")
  ip,nm,gw=wifi.sta.getip()
  if ip ~= nil then         
    print(ip,nm,gw)         
    tmr.stop(0)
    led.cancel()

    dofile("main.lua")
  end
end)

