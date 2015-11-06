local M
do

-- DS18B20 dq pin
local pin = 4
-- DS18B20 default pin
local defaultPin = 4
-- Delay in ms for parasite power
local delay = 700
-- Return values
local unit = 'C'
local adrs = nil

local response = {}

-- Table module
local table = table
-- String module
local string = string
-- One wire module
local ow = ow
-- Timer module
local tmr = tmr
local alrm = function(t,nxt) tmr.alarm(6,t,0,nxt) end

function setup(dq)
  pin = dq or pin
  ow.setup(pin)
end

function addrs(max_devs)
  max_devs = max_devs or 100
  setup(pin)
  local devs = {}
  ow.reset_search(pin)
  local n = 0
  repeat
    local a = ow.search(pin)
    if(a ~= nil) then
      table.insert(devs, a)
      n = n + 1
    end
    tmr.wdclr()
  until ((a == nil) or (n == max_devs))
  ow.reset_search(pin)
  return devs
end

function setDelay(t)
  delay = t or 1
  if t < 1 then delay = 1 end
end

function tcb(cb)
  response = {}
  local present = ow.reset(pin)
  for i = 1, #adrs, 1 do
    tmr.wdclr()
    ow.select(pin, adrs[i])
    ow.write(pin,0xBE,1)
    local data = string.char(ow.read(pin))
    for j = 1, 8 do
      data = data .. string.char(ow.read(pin))
    end
    local crc = ow.crc8(string.sub(data,1,8))
    if (crc ~= data:byte(9)) then
      table.insert(response, {adrs[i],null,null,"Invalid TX CRC"} )
    else
      local t = (data:byte(1) + data:byte(2) * 256)
      if (t > 32767) then
        t = t - 65536
      end

      if (adrs[i]:byte(1) == 0x28) then
        t = t * 625  -- DS18B20, 4 fractional bits
      else
        t = t * 5000 -- DS18S20, 1 fractional bit
      end

      if(unit == 'C') then
        -- nada
      elseif(unit == 'F') then
        t = (t * 900) / 500 + 320000
      elseif(unit == 'K') then
        t = t + 2731500
      else
        table.insert(response, {adrs[i],null,null,"Invalid unit: "..unit} )
        alrm(1,cb)
        return
      end
      local ip = t / 10000
      local fp = t - (ip * 10000)
      table.insert(response, {adrs[i],ip,fp,unit} )
    end
  end
  alrm(1,cb)
end

function printTemp()
  if response == nil then return end
  local err = "ERR"
  for i = 1, #response, 1 do
    local s = response[i][1] or err
    local t = err
    if response[i][2] ~= nil then
      local t = response[i][2] .. "." .. response[i][3] .. " deg "
    end
    local m = response[i][4] or err
    print ("Temp of "..s..": "..t..m)
  end
end

function readTemp(cb, ads, uts)
  response={}
  adrs = ads
  unit = uts or 'C'
  cb = cb or printTemp
  if ads == nil then
    adrs  = addrs(1)
    if #adrs == 0 then
      table.insert(response, {null,null,null,"No one wire devices found on pin "..pin} )
      alrm(1,cb)
      return
    end
  end
  for i = 1, #adrs, 1 do
    local crc = ow.crc8(string.sub(adrs[i],1,7))
    if (crc ~= adrs[i]:byte(8)) then
      table.insert(response, {adrs[i],null,null,"Invalid RX CRC"} )
    else
      if ((adrs[i]:byte(1) == 0x10) or (adrs[i]:byte(1) == 0x28)) then
        -- print("Device is a DS18S20 family device.")
        ow.reset(pin)
        ow.select(pin, adrs[i])
        ow.write(pin, 0x44, 1)
      else
        table.insert(response, {adrs[i],null,null,"Device family not recognized"} )
      end
    end
  end
  alrm(delay,function () tcb(cb) end)
end

function get() return response
end

-- expose
M = {
  get = get,
  readTemp = readTemp,
  addrs = addrs,
  setDelay = setDelay,
  setup = setup
}

end
return M

