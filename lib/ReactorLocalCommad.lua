local ReactorLocalCommad = {}

local term = require("term")
local text = require("text")

local rs = require("ReactorStatus")
local rn = require("ReactorName")
local ithread = require("IThread")
local utils = require("IUtils")
local CMDsGpu = require("CMDsGpu")
local rt = require("ReactorTransposer")
local rrio = require("ReactorRedStoreIO")

ReactorLocalCommad.commandList = 
{
  ["exit"] = function(scom)   
    term.clear()
	ithread:killAllThread()
  end,   
  ["start"] = function(coms) 
    rrio:reactorStartup()
  end,
  ["stop"] = function(coms) 
    rrio:reactorStop()
  end,
  ["scan"] = function(coms) 
    rs:setAction("scan")      
	rt:scanReactorItem()	
	rs:setAction("idle")      
  end,
  ["remap"] = function(coms) 
    rs:setAction("remap")  
	rt:reductionReactorMap()
	rs:setAction("idle")  
  end,
  ["return"] = function(coms)
    rs:setAction("return")    
	rt:transferAllItemReturnChest()
	rs:setAction("idle")  
  end,  
  ["msgt"] = function(coms)     
    if coms[2] == nil then	  
	  CMDsGpu:printLine(1, "Usage: msgt <type>", nil, true)	     
	else	  	  
	  if not CMDsGpu:setCmdType(coms[2]) then	      
	    CMDsGpu:printLine(1, "Usage type: debug init info warn error", nil, true)	     
	  end
	end
   end,
  ["cs"] = function(coms)     
	if coms[2] == nil then	  
	  CMDsGpu:printLine(1, "Usage: cs <control statue>", nil, true)	     
	else	  
	  if not rs:setControlStatus(coms[2]) then	
	    CMDsGpu:printLine(1, "Usage type: auto  manual", nil, true)	
	  end
	end
  end,
}


function ReactorLocalCommad:thread()
  w, h, xo, yo ,rx, ry = term.getViewport()
  while true do  
    term.setCursor(1, h)	
    term.write(" # ")   
    self:execute(io.read())
  end
end

function ReactorLocalCommad:initialize()
  rn:adapte()
  rt:adapte()
  rrio:adapte()
  term.clear()  
  ithread:create(self.thread, self, "ReactorLocalCommad")
  --self:thread()
end

function ReactorLocalCommad:execute(com) 
   coms = text.tokenize(com) 
   local commandFunc = self.commandList[coms[1]]
	if commandFunc ~= nil then
	  CMDsGpu:printLine(1, " ", nil, true)	
	  utils:info("Execute "..com)
	  commandFunc(coms)
	else	  
	  local usage = "Usage:  "	 
	  for key, value in pairs(self.commandList) do 
        usage = usage.."  "..key
      end
	  CMDsGpu:printLine(1, usage, nil, true)	  
	end
end

return ReactorLocalCommad