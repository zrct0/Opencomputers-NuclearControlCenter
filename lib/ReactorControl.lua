local ReactorControl = {}

local serialization = require("serialization")
local rs = require("ReactorStatus")
local rlc = require("ReactorLocalCommad")
local network = require("ReactorLocalNetwork")
local ithread = require("IThread")
local utils = require("IUtils")
local CMDsGpu = require("CMDsGpu")

ReactorControl.logic = nil

ReactorControl.stopErrorMsgPrint = false
ReactorControl.remapLastTryTime = 0
ReactorControl.remapTryCount = 0

function ReactorControl:initialize(reactorLogic)  
  self.logic = reactorLogic
  if self.logic == nil then
    utils:error("(ReactorControl:initialize) reactorLogic is nil")  
  end
  CMDsGpu:setCMDMsgCallback(self.onCMDMsgCreate)
  network:initialize()
  rs:initialize(network)
  ithread:create(self.thread, self, "ReactorControl")
  ithread:create(rs.scanChestItemsCountThread, rs, "RS:ScanChestItemsCount")
  self:thread()  
  
end

function ReactorControl:thread()
  while true do
    rs:pullInfo()
    rs:printInfo(1)	
	self.logic(rs, rs.heat)	
	if network:isConnentRRM() then	 
	  local pkg = rs:getSerializeInfo()
	  network:sendRRM("RSI", pkg)
	end
	os.sleep(1)
  end
end

function ReactorControl:onCMDMsgCreate(cmd) 
  if network:isConnentRRM() then	  
	  local pkg = serialization.serialize(cmd)
	  network:sendRRC("LC", pkg)
  end
end

function ReactorControl:stop()  
  if rs.controlStatus == "auto" then
    rlc:execute("stop")
    utils:warn("[RC]REACTOR STOP") 
	rs:setControlStatus("auto stop", true)
	self.stopErrorMsgPrint = false
  elseif rs.controlStatus == "manual" and not self.stopErrorMsgPrint then
    utils:error("[RC]Auto Stop False! CS is on "..rs.controlStatus) 
  end  
end

function ReactorControl:remap()
  if rs.action == "idle" then 
    if rs.controlStatus == "auto" then
      if os.clock() - self.remapLastTryTime < 0.1 then	    
	    self.remapTryCount = self.remapTryCount + 1	
        utils:error("[RC]RETRY REMAP time:"..self.remapTryCount)		
		if self.remapTryCount >= 3 then
		  utils:error("[RC]TRY REMAP False, STOP REACTOR")	
          self:stop()
		end
	  else
	    if self.remapTryCount > 0 then
	      self.remapTryCount = 0
		  utils:info("[RC]REMAP time reset")
		end
	  end
      utils:warn("[RC]REACTOR REMAP")  
      rlc:execute("stop")
      rlc:execute("remap")
      rlc:execute("start")
      utils:warn("[RC]REACTOR REMAP Finished") 
      self.remapLastTryTime = os.clock()
	end
  else
    utils:warn("[RC]REMAP False :BUSY("..rs.action..")")  
  end  
end

return ReactorControl