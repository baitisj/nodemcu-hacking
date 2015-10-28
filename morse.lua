local M
do
  local wb=require ("ringbuffer")
  local t = {}
	t[48]='-----' --0
	t[49]='.----'
	t[50]='..---'
	t[51]='...--'
	t[52]='....-'
	t[53]='.....'
	t[54]='-....'
	t[55]='--...'
	t[56]='---..'
	t[57]='----.' --9
	t[65]='.-' -- A
	t[66]='-...'
	t[67]='-.-.'
	t[68]='-..'
	t[69]='.'
	t[70]='..-.'
	t[71]='--.'
	t[72]='....'
	t[73]='..'
	t[74]='.---'
	t[75]='-.-'
	t[76]='.-..'
	t[77]='--'
	t[78]='-.'
	t[79]='---'
	t[80]='.--.'
	t[81]='--.-'
	t[82]='.-.'
	t[83]='...'
	t[84]='-'
	t[85]='..-'
	t[86]='...-'
	t[87]='.--'
	t[88]='-..-'
	t[89]='-.--'
	t[90]='--..' -- Z

  local p=0
  local active=0
  local br=600

  local curWord=nil

  local g = require("gpio")
  local alrm = function(t,nxt) tmr.alarm(1,t,0,nxt) end

  function cancel()
    tmr.cancel(1) 
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

  function queue(str)
    r = wb.push(str:upper())
    if r ~= nil then
      tx()
    end
    return r
  end

  function tx()
    if active == 0 then
      active = 1
      toot(wb.pop(), 1, wordDone)
    end
  end

  function letters(w, i)
    if i > w:len() then 
      return wordDone()
    end
    toot(w, 1, function() letters(w,i+1) end)
  end

  function toot(w,idx,cb)
    if idx > w:len() then
      return wpause(cb)
    end
    bval=w:byte(idx)
    ms=t[bval]
    print(bval,ms)
    doBlinks(ms,1,function() toot(w,idx+1,cb) end)
  end

  function doBlinks(ms,idx,cb)
    if idx > ms:len() then
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
      nxt = wb.pop()
      if nxt ~= nil then wpause(function() toot(nxt,1,wordDone) end) 
      else active = 0
      end
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
    print("blink")
    alrm(t/2, function () off() alrm(t/2, cb) end)
  end
  
  -- expose
  M = {
    setPort = setPort,
    queue = queue,
    cancel = cancel
  }
end
return M
