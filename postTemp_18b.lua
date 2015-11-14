local M
do
local host = "192.168.8.2"
local port = 8000
local net = net
local ds=require("ds18b20")
local sk = nil
local sck = nil
local r = nil
local alrm = function(t,nxt) tmr.alarm(5,t,0,nxt) end
local a = nil
local active = false
local ATMOUT=4

function s_tmout()
  tmr.alarm(ATMOUT,5000,0,rescue)
end

function getData()
  r = ds.get()
  alrm(1,start)
end

function rescue()
  if sck ~= nil then
    sck:close()
  end
  sck = nil
  sk = nil
  active = false
end

function postTemp()
  if active then return end
  a = a or ds.addrs()
  ds.readTemp(getData, a, 'F')
  active = true
end

function itr(idx,cb)
  tmr.stop(ATMOUT)
  if idx > #r then
    if sck ~= nil then 
      sck:close() 
      sck = nil
      sk = nil
      active = false
    end
    if cb ~= nil then cb() end
    return
  end
  local t = nil
  local id = nil
  if r[idx][1] ~= nil then
    local h="%02x"
    id = string.format(h:rep(8),r[idx][1]:byte(1,8))
  end
  if r[idx][2] ~= nil then
    t = r[idx][2].."."..r[idx][3]
  end
  if id and t then
    send(idx,id,t)
    return
  end
  alrm(1,function() itr(idx+1,sck,cb) end)
end

function start(cb)
  s_tmout()
  if (sk == nil) then
    sk = net.createConnection(net.TCP,0)
    sk:on("receive", function(s,c) print(c) end)
    sk:on("connection", function(s,c) sck=s itr(1,cb) end)
  end
  sk:connect(port,host)
end

function send(i,id,t)
  s_tmout()
  sk:on("sent", function(s,c) sck=s itr(i+1,cb) end)
  sck:send("GET /iot/update?data="..id..","..t.." HTTP/1.1\r\nHost: "..host.."\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
end
-- expose
M = {
  postTemp = postTemp
}

end
return M
