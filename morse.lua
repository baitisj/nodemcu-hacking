local M
do
  local tbl = require ("morse_table")
  local active=false
  local notify=nil
  local debug=nil

  local br=600

  local p=0
  local g = require("gpio")
  local alrm = function(t,nxt) tmr.alarm(1,t,0,nxt) end

  function stop()
    tmr.stop(1) 
    off()
  end

  function on()
    g.write(p,g.LOW)
  end

  function off()
    g.write(p,g.HIGH)
  end

  function setPort(pt)
    p=pt
  end

  function setNotify(cb)
    notify=cb
  end

  function send(str)
    if active == true then
      return nil
    end
    active = true
    toot(str:upper(), 1, wordDone)
  end

  function toot(w,idx,cb)
    if idx > w:len() then
      return wpause(cb)
    end
    ms=tbl.getMCode(w,idx)
    if debug ~= nil then print(ms) end
    doBlinks(ms,1,function() toot(w,idx+1,cb) end)
  end

  function setDebug(s)
    debug=s
  end

  function doBlinks(ms,idx,cb)
    if ms == nil or idx > ms:len() then
      return lpause(cb)
    end
    c=ms:sub(idx,idx)
    if c == "." then
      dot(function() doBlinks(ms,idx+1,cb) end)
    elseif c=="-" then
      dash(function() doBlinks(ms,idx+1,cb) end)
    end
  end
  
  function wordDone()
    wpause(function()
      active = false
      if notify ~= nil then notify() end
    end)
  end

  function dot(cb)
    blink(br/3, cb)
  end

  function dash(cb)
    blink(br, cb)
  end

  function lpause(cb)
    alrm(br/2, cb)
  end

  function wpause(cb)
    alrm(br*2, cb)
  end

  function blink(t, cb)
    on()
    if debug ~= nil then print("blink") end
    alrm(t/2, function () off() alrm(t/2, cb) end)
  end
  
  -- expose
  M = {
    setPort = setPort,
    send = send,
    stop = stop,
    setDebug = setDebug,
    setNotify = setNotify
  }
end
return M
