local M
do
  local g = require("gpio")
  local port = 0

  function lOn(t,p)
    g.write(p,g.LOW)
    lOff = function (t,p)
      g.write(p,g.HIGH)
      tmr.alarm(1,t,0,function () lOn(t,p) end)
    end
    tmr.alarm(1,t,0,function () lOff(t,p) end)
  end

  function cancel()
    tmr.stop(1)
    g.write(port,g.HIGH)
  end

  function blink(t)
    g.mode(port, g.OUTPUT)
    lOn(t,port)
  end

  -- expose
  M = {
    blink = blink,
    cancel = cancel
  }
end
return M
