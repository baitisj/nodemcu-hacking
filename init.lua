b=1
local wifi=wifi
local led=require("led")
local tmr=tmr
wifi.setmode(wifi.STATION)
wifi.sta.config("BaitisBasement","1011121110")
wifi.sta.connect()
led.blink(300)
print ("Waiting for 802.11 link")
print ("type b=0 to prevent boot")

function checkWIFI()
  local ip,nm,gw=wifi.sta.getip()
  if ip ~= nil then         
    print("\n802.11 up:",ip,nm,gw)         
    led.cancel()
    tmr.alarm(0, 5000, 0, function () if b==1 then dofile("main.lua") end end)
  end
end

tmr.alarm(0, 1000, 1, checkWIFI)
