local RRCNetwork = {}

local serialization = require("serialization")
local utils = require("IUtils")
local network = require("INetwork")
local ithread = require("IThread")

RRCNetwork.RLMsAddress = {}
RRCNetwork.RLMsAddress2Name = {}
RRCNetwork.RLMsLastMsgTime = {}
RRCNetwork.RLMsAlive = {}
RRCNetwork.LCCallback = nil
RRCNetwork.RLMDisconnetedCallback = nil

RRCNetwork.commandList = 
{
  ["Require OCC Address"] = function(address, msg) 
    if msg ~= "" and msg ~= nil then	
	  RRCNetwork.RLMsAddress[msg] = address
	  RRCNetwork.RLMsAddress2Name[address] = msg	  	  
      RRCNetwork.sendRLM(RRCNetwork, msg, "Respond RRC Address", "RRC")
	  utils:info("Connet to RLM:", address)
	end    	
  end,

  ["Respond Address"] = function(address, msg) 
    if msg ~= "" and msg ~= nil then	
	  RRCNetwork.RLMsAddress[msg] = address
	  RRCNetwork.RLMsAddress2Name[address] = msg	    
	  utils:info("Connet to RLM:", address)
	end    	
  end,  
  
  ["Respond RLM ALive"] = function(address, msg) 
    local RLMName = RRCNetwork.RLMsAddress2Name[address]
    if RLMName then    
      RRCNetwork.RLMsLastMsgTime[RLMName] = os.clock()
      RRCNetwork.RLMsAlive[RLMName] = true	
    end  	
  end, 
  
  ["LC"] = function(address, msg)   
	local name = RRCNetwork.RLMsAddress2Name[address]
    if name ~= nil then
      if RRCNetwork.LCCallback ~= nil then
	    local data = serialization.unserialize(msg)	  
        RRCNetwork.LCCallback(_, name, data)
	  end
	else
	  network:send(address, "Require RLM Address", "RRC")
	end
  end,
  
}

function RRCNetwork:sendRLM(RLMName, CMD, Msg)
  local RLMAddress = self.RLMsAddress[RLMName]
  utils:debug("[sendRLM]["..RLMName.."]"..CMD..":"..Msg) 
  if RLMAddress == nil then
    utils:error("Cannot Find the Address of RLM("..RLMName..")")
  else
    network:send(RLMAddress, CMD, Msg)
  end
end

function RRCNetwork:sendRLMLocalCommad(RLMName, localCommad)
  self:sendRLM(RLMName, "Local CMD", localCommad)
end

function RRCNetwork:onMessageCome(address, CMD, Msg)
  local RLMName = RRCNetwork.RLMsAddress2Name[address]  
  utils:debug("[Net Msg]@name:"..(RLMName and RLMName or "unname")..", CMD:"..CMD..", Msg:"..Msg)
  RRCNetwork.execute(RRCNetwork, address, CMD, Msg) 
  if RLMName ~= nil then    
    RRCNetwork.RLMsLastMsgTime[RLMName] = os.clock()
    RRCNetwork.RLMsAlive[RLMName] = true	
  end
end

function RRCNetwork:thread()
  while true do
    local askTime = os.clock()
	for RLMName, RLMAddress in pairs(RRCNetwork.RLMsAddress) do
	  RRCNetwork:sendRLM(RLMName, "Ask RLM Alive", "RRC")
	end	
    os.sleep(1)	
    for RLMName, RLMMsgTime in pairs(RRCNetwork.RLMsLastMsgTime) do	
      local timeout = RLMMsgTime - askTime	
	  if RRCNetwork.RLMsAlive[RLMName] and  timeout > 0 then	   
	    RRCNetwork.RLMsAlive[RLMName] = false			
		if RRCNetwork.RLMDisconnetedCallback ~= nil then
	      RRCNetwork.RLMDisconnetedCallback(_, RLMName, timeout)
        end		   
	  end
	end
    os.sleep(5)
  end
end

function RRCNetwork:initialize(_LCCallback, _RLMDisconnetedCallback) 
  self.LCCallback = _LCCallback   
  self.RLMDisconnetedCallback = _RLMDisconnetedCallback  
  network:initialize(self.onMessageCome)
  network:broadcast("Require RLM Address", "RRC")
  utils:debug("Require RLM Address")  
  ithread:create(self.thread, self, "RRCNetwork")
  --self:thread()
end

function RRCNetwork:execute(address, com, msg)  
   local commandFunc = self.commandList[com]
	if commandFunc ~= nil then
	  --utils:debug("Execute Net CMD:"..com)
	  commandFunc(address, msg)
	else
	  utils:warn("Cannot recognise Net CMD:"..com)
	end
end

return RRCNetwork