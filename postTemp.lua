local M
do
  local pin = 4
  local port = 60124
  local t = {}
  t[dht.OK] = "OK"
  t[dht.ERROR_CHECKSUM] = "ERROR_CHECKSUM"
  t[dht.ERROR_TIMEOUT] = "TIMEOUT"

  function postTemp() 
    status,tempr,humi,temp_decimial,humi_decimial = dht.read(pin)
    --m.queue("T"..math.floor(temp))
    local ip="192.168.8.2"
    header = "node,status,uptime,temp,humidity"
    dat = string.format(
      "%d,%s,%d,%d.%03d,%d.%03d\n",
      node.chipid(),
      t[status],
      tmr.now(),
      math.floor(tempr),
      temp_decimial,
      math.floor(humi),
      humi_decimial
    )

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

    if tempr < 0 then
      return("N"..tempr)
    else
      return(""..tempr)
    end
  end
  -- expose
  M = {
    postTemp = postTemp
  }
end
return M
