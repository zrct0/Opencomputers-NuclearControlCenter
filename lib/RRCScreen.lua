local RRCScreen = {}

local event = require("event")
local rrcn = require("RRCNetwork")
local ithread = require("IThread")
local CMDsGpu = require("CMDsGpu")
local RRCGpu = require("RRCGpu")
local utils = require("RRCUtils")

local RLMsCount = 0
local RLMsName = {}
local RLMsName2ID = {}

function RRCScreen:initialize()
  CMDsGpu:initialize()
  rrcn:initialize(self.onLCCome, self.onRLMDisconneted)
  RRCGpu:clear()
  RRCGpu:DrawBox(0, 0 , w+1, 8, " ", 0x3300C0)   
  RRCGpu:drawPaint("/home/lib/rrc_title.gi", w/2 - 15, 1, 0xFFFFFF)
end

function RRCScreen:onRLMDisconneted(RLMName)  
  local RLMId = RLMsName2ID[RLMName]   
  if RLMId ~= nil then
    utils:error("[onRLMDisconneted]"..RLMId.." :"..RLMName)  
  end
end

function RRCScreen:onLCCome(name, data)  
  local RLMId = RLMsName2ID[name]
  if RLMId then
    RLMsName[RLMsCount] = name
	RLMsName2ID[name] = RLMsCount
	RLMId = RLMsCount
	RLMsCount = RLMsCount + 1    
  end    
  utils:print(data[1], data[2], name)    
end

return RRCScreen