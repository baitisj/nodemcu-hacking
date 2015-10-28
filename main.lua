local M
do
  local m = require("morse")
  m.setPort(0)
  local pin = 4
  local port = 60124
  local t = {}
  t[dht.OK] = "OK"
  t[dht.ERROR_CHECKSUM] = "ERROR_CHECKSUM"
  t[dht.ERROR_TIMEOUT] = "TIMEOUT"

  function postTemp() 

    status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)
    --m.queue("T"..math.floor(temp))
    local ip="192.168.8.2"
    header = "node,status,uptime,temp,humidity"
    dat = string.format(
      "%d,%s,%d,%d.%03d,%d.%03d\n",
      node.chipid(),
      t[status],
      tmr.now(),
      math.floor(temp),
      temp_decimial,
      math.floor(humi),
      humi_decimial
    )

    if temp < 0 then
      m.send("N"..temp)
    else
      m.send(""..temp)
    end

    sk=net.createConnection(net.TCP,0)
    sk:on("receive", function(sck,c) print(c) end)
    sk:on("connection", function(sck,c)
      sck:send("GET /iot/update?data="..dat.." HTTP/1.1\r\nHost: "..ip.."\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
    end)
    sk:on("sent", function(sck,c)
      sck:close()
    end)
    sk:connect(port,ip)

    print (header)
    print (dat)
    m.setNotify(function() tmr.alarm(1,10000,0,postTemp) end)
  end
  -- expose
  M = {
    postTemp = postTemp
  }
end
M.postTemp()
