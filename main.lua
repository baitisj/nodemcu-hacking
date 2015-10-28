local M
do
  local m = require("morse")
  m.setPort(0)
  local pin = 4
  local port = 80
  local t = {}
  t[dht.OK] = "OK"
  t[dht.ERROR_CHECKSUM] = "ERROR_CHECKSUM"
  t[dht.ERROR_TIMEOUT] = "TIMEOUT"

  function postTemp() 
    sk=net.createConnection(net.TCP,0)
    sk:on("receive", function(sck,c) print(c) end)
    sk:connect(port,ip)

    status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)
    m.queue("T"..math.floor(temp))
    local ip="192.168.8.2"
    header = ("node,","status,","uptime,","temp,","humidity")
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

    sk:on("connection", function(sck,c)
      sk:send("GET /iot/update?data="..dat.."HTTP/1.1\nHost: "..ip.."\nConnection: keep-alive\nAccept: */*\n\n")
      sk:close()
      m.queue("SK")
    end)

    print (header)
    print (dat)
