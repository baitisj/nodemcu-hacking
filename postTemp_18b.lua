local M
do
local host = "192.168.8.2"
local port = 60124
local net = net
local ds=require("ds18b20")
local nextCB = nil
local sk = nil
local r = nil
local idx = 1
local alrm = function(t,nxt) tmr.alarm(5,t,0,nxt) end
local a = nil

function getData()
  r = ds.get()
  alrm(1,start)
end

function postTemp()
  a = a or ds.addrs()
  ds.readTemp(getData, a, 'F')
end

function itr(idx,sck,cb)
  print ("->itr")
  if idx > #r then
    if sck ~= nil then sck:close() end
    if cb ~= nil then cb() end
    return
  end
  local t = nil
  local id = nil
  if r[i][1] ~= nil then
    local h="%02x"
    id = string.format(h:rep(8),r[i][1]:byte(1,8))
  end
  if r[i][2] ~= nil then
    t = r[i][2].."."..r[i][3]
  end
  if id and t then
    send(itr,sck,id,r)
    return
  end
  alrm(1,function() itr(i+1,sck,cb) end)
end

function start(cb)
  print("->start")
  sk = sk or net.createConnection(net.TCP,0)
  sk:on("receive", function(sck,c) print(c) end)
  sk:on("connection", function(sck,c) itr(1,sck,cb) end)
  sk:on("sent", function(sck,c) nextCB(sck) end)
  sk:connect(port,ip)
end

function send(itr,sck,id,r)
  print("->send")
  nextCB = function(sck) alrm(1,itr(i+1,sck,cb)) end
  sk:on("sent", function(sck,c) nextCB(sck) end)
  sck:send("GET /iot/update?data="..id..","..r.." HTTP/1.1\r\nHost: "..host.."\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
end
-- expose
M = {
  postTemp = postTemp
}

end
return M
