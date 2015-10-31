morse=require("morse")
tp=require("postTemp")
morse.setPort(0)

function run()
  morse.send(tp.postTemp())
end

morse.setNotify(function() tmr.alarm(2,10000,0,run) end)
run()
