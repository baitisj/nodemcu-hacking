local M
do

-- DS18B20 dq pin
local pin = 4
-- DS18B20 default pin
local defaultPin = 4
-- Delay in ms for parasite power
local rdelay = 700
local sdelay = 1
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

function setDelay(r,s)
  rdelay = r or 1
  sdelay = s or 1
  if r < 1 then rdelay = 1 end
end

function printTemp()
  if response == nil then return end
  local err = "ERR"
  print ("\n")
  for i = 1, #response, 1 do
    local s,t = err,err
    if response[i][1] ~= nil then
      local h="%02x"
      s = string.format(h:rep(8),response[i][1]:byte(1,8))
    end
    if response[i][2] ~= nil then
      t = response[i][2] .. "." .. response[i][3] .. " deg"
    end
    local m = response[i][4] or err
    print ("Temp at "..s..": "..t.." "..m)
  end
end

function readTemp(cb, ads, uts)
  response={}
  adrs = ads
  unit = uts or 'C'
  cb = cb or printTemp
  if ads == nil then
    adrs = addrs(1)
  end
  if #adrs == 0 then
    table.insert(response, {nil,nil,nil,"No one wire devices found on pin "..pin} )
    alrm(1,cb)
    return
  end
  lcnvrt(1,cb)
end

function rscratch(idx, cb)
  if idx > #adrs then 
    alrm(1, cb)
    return
  end
  local data,crc = rdT(adrs[idx])
  if (crc ~= data:byte(9)) then
    table.insert(response, {adrs[idx],nil,nil,"Invalid TX CRC"} )
  else
    local t = (data:byte(1) + data:byte(2) * 256)
    if (t > 32767) then
      t = t - 65536
    end

    if (adrs[idx]:byte(1) == 0x28) then
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
      table.insert(response, {adrs[idx],nil,nil,"Invalid unit: "..unit} )
      alrm(1,cb)
      return
    end
    local ip = t / 10000
    local fp = t - (ip * 10000)
    table.insert(response, {adrs[idx],ip,fp,unit} )
  end
  alrm(sdelay, function() rscratch(idx+1, cb) end)
  return
end

function lcnvrt(idx, cb)
  if idx > #adrs then 
    alrm(rdelay, function() rscratch(1, cb) end)
    return
  else
    local crc = ow.crc8(string.sub(adrs[idx],1,7))
    if (crc ~= adrs[idx]:byte(8)) then
      table.insert(response, {adrs[idx],nil,nil,"Address CRC mismatch"} )
    else
      cnvrtT(adrs[idx])
    end
  end
  alrm(rdelay, function() lcnvrt(idx+1, cb) end)
  return
end

function rdT (addr)
  ow.reset(pin)
  ow.select(pin, addr)
  ow.write(pin,0xBE,1)
  local data = string.char(ow.read(pin))
  for j = 1, 8 do
    data = data .. string.char(ow.read(pin))
  end
  local crc = ow.crc8(string.sub(data,1,8))
  return data,crc
end

function cnvrtT (addr)
  if (addr:byte(1) == 0x10) or (addr:byte(1) == 0x28) then
    -- print("Device is a DS18S20 family device.")
    ow.reset(pin)
    ow.select(pin, addr)
    ow.write(pin, 0x44, 1)
  else
    table.insert(response, {addr,nil,nil,"Device family not recognized"} )
  end
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

