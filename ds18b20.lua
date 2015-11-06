local M
do

-- DS18B20 dq pin
local pin = nil
-- DS18B20 default pin
local defaultPin = 4
-- Delay in ms for parasite power
local delay = 700
-- Return values
local ipart = nil
local fpart = nil
local msg = nil
local unit = nil
local addr = nil

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
  pin = dq or defaultPin
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
  delay = t
end

function tcb(cb)
  local present = ow.reset(pin)
  ow.select(pin, addr)
  ow.write(pin,0xBE,1)
  -- print("P="..present)
  local data = string.char(ow.read(pin))
  for i = 1, 8 do
    data = data .. string.char(ow.read(pin))
  end
  -- print(data:byte(1,9))
  local crc = ow.crc8(string.sub(data,1,8))
  -- print("CRC="..crc)
  if (crc == data:byte(9)) then
    local t = (data:byte(1) + data:byte(2) * 256)
    if (t > 32767) then
      t = t - 65536
    end

    if (addr:byte(1) == 0x28) then
      t = t * 625  -- DS18B20, 4 fractional bits
    else
      t = t * 5000 -- DS18S20, 1 fractional bit
    end

    if(unit == nil or unit == 'C') then
      unit = 'C'
    elseif(unit == 'F') then
      t = (t * 900) / 500 + 320000
    elseif(unit == 'K') then
      t = t + 2731500
    else
      msg="Invalid unit: "..unit
      alrm(1,cb)
      return
    end

    ipart = t / 10000
    fpart = t - (ipart * 10000)
    msg = unit
    alrm(1,cb)
    return
  else
    msg = "Invalid CRC!"
    alrm(1,cb)
    return
  end
end

function printTemp()
  local i,f,m=get()
  print ("DS18B20 temp: "..i.."."..f.." deg "..m)
end

function readTemp(cb, address, uts)
  ipart = nil
  fpart = nil
  unit = uts
  addr = address
  cb = cb or printTemp
  if address == nil then
    local devs = addrs(1)
    if table.getn(devs) == 0 then
      msg = "No one wire devices found on pin "..pin
      alrm(1,cb)
      return
    end
    addr=devs[1]
  end
  local crc = ow.crc8(string.sub(addr,1,7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      -- print("Device is a DS18S20 family device.")
      ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin, 0x44, 1)
      if delay < 1 then delay = 1 end
      alrm(delay,function () tcb(cb) end)
      return
    else
      msg = "Device family is not recognized."
      alrm(1,cb)
      return
    end
  else
    msg = "Invalid CRC!"
    alrm(1,cb)
    return
  end
end

function get()
  return ipart, fpart, msg
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
