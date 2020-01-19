local RRCCommad = {}

local term = require("term")
local text = require("text")

local utils = require("IUtils")
local CMDsGpu = require("CMDsGpu")
local rrcn = require("RRCNetwork")
local ithread = require("IThread")

RRCCommad.commandList = 
{
  ["exit"] = function(scom)   
    term.clear()
	ithread:killAllThread()
  end,   
  ["start"] = function(coms) 
    RRCCommad:executeRemoteCommad(coms)
  end,
  ["stop"] = function(coms) 
    RRCCommad:executeRemoteCommad(coms)
  end,
  ["scan"] = function(coms) 
    RRCCommad:executeRemoteCommad(coms)
  end,
  ["remap"] = function(coms) 
    RRCCommad:executeRemoteCommad(coms)
  end,
  ["return"] = function(coms)
    RRCCommad:executeRemoteCommad(coms)
  end,   
  ["cs"] = function(coms)     
	RRCCommad:executeRemoteCommad(coms)
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
}

function RRCCommad:executeRemoteCommad(coms)
  comName = coms[1]
  if coms[2] == nil then
    CMDsGpu:printLine(1, "Usage: "..comName.." <reactor name>", nil, true)	 
  else
    local scom = comName
    for i=3, #coms do
	  scom = scom.." "..coms[i]
	end
	utils:info("Send Remote Commad:"..scom)
    rrcn:sendRLMLocalCommad(coms[2], scom)
  end      
end

function RRCCommad:thread()
  w, h, xo, yo ,rx, ry = term.getViewport()
  while true do  
    term.setCursor(1, h)	
    term.write(" # ")   
    self:execute(io.read())
  end
end

function RRCCommad:initialize()  
  ithread:create(self.thread, self, "RRCCommad")
  --self:thread()
end

function RRCCommad:execute(com) 
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

return RRCCommad