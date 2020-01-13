local RRMNetwork = {}

local serialization = require("serialization")
local utils = require("IUtils")
local network = require("INetwork")
local ithread = require("IThread")

RRMNetwork.RLMsAddress = {}
RRMNetwork.RLMsAddress2Name = {}
RRMNetwork.RLMsLastMsgTime = {}
RRMNetwork.RLMsAlive = {}
RRMNetwork.RSICallback = nil
RRMNetwork.RLMDisconnetedCallback = nil

RRMNetwork.commandList = 
{
  ["Require OCC Address"] = function(address, msg) 
    if msg ~= "" and msg ~= nil then	
	  RRMNetwork.RLMsAddress[msg] = address
	  RRMNetwork.RLMsAddress2Name[address] = msg	  	  
      RRMNetwork.sendRLM(RRMNetwork, msg, "Respond RRM Address", "RRM")
	  utils:info("Connet to RLM:", address)
	end    	
  end,

  ["Respond Address"] = function(address, msg) 
    if msg ~= "" and msg ~= nil then	
	  RRMNetwork.RLMsAddress[msg] = address
	  RRMNetwork.RLMsAddress2Name[address] = msg	    
	  utils:info("Connet to RLM:", address)
	end    	
  end,  
  
  ["RSI"] = function(address, msg)   
	local name = RRMNetwork.RLMsAddress2Name[address]
    if name ~= nil then
      if RRMNetwork.RSICallback ~= nil then
	    local data = serialization.unserialize(msg)	  
        RRMNetwork.RSICallback(_, name, data)
	  end
	else
	  network:send(address, "Require RLM Address", "RRM")
	end
  end,
  
}

function RRMNetwork:sendRLM(RLMName, CMD, Msg)
  local RLMAddress = self.RLMsAddress[RLMName]
  utils:debug("[sendRLM]["..RLMName.."]"..CMD..":"..Msg) 
  if RLMAddress == nil then
    utils:warn("Cannot Find the Address of RLM("..RLMName..")")
  end
  network:send(RLMAddress, CMD, Msg)
end

function RRMNetwork:sendRLMLocalCommad(RLMName, localCommad)
  self:sendRLM(RLMName, "Local CMD", localCommad)
end

function RRMNetwork:onMessageCome(address, CMD, Msg)
  local RLMName = RRMNetwork.RLMsAddress2Name[address]  
  utils:debug("[Net Msg]@name:"..(RLMName and RLMName or "unname")..", CMD:"..CMD..", Msg:"..Msg)
  RRMNetwork.execute(RRMNetwork, address, CMD, Msg)
  if RLMName ~= nil then    
    RRMNetwork.RLMsLastMsgTime[RLMName] = os.clock()
    RRMNetwork.RLMsAlive[RLMName] = true	
  end
end

function RRMNetwork:thread()
  while true do
    local now = os.clock()
    for RLMName, RLMMsgTime in pairs(RRMNetwork.RLMsLastMsgTime) do	
      local timeout = now - RLMMsgTime	
	  if RRMNetwork.RLMsAlive[RLMName] and  timeout > 0.025 then	   
	    RRMNetwork.RLMsAlive[RLMName] = false			
		if RRMNetwork.RLMDisconnetedCallback ~= nil then
	      RRMNetwork.RLMDisconnetedCallback(_, RLMName, timeout)
        end		   
	  end
	end
    os.sleep(1)
  end
end

function RRMNetwork:initialize(_RSICallback, _RLMDisconnetedCallback) 
  self.RSICallback = _RSICallback   
  self.RLMDisconnetedCallback = _RLMDisconnetedCallback  
  network:initialize(self.onMessageCome)
  network:broadcast("Require RLM Address", "RRM")
  utils:debug("Require RLM Address")  
  ithread:create(self.thread, self, "RRMNetwork")
  --self:thread()
end

function RRMNetwork:execute(address, com, msg)  
   local commandFunc = self.commandList[com]
	if commandFunc ~= nil then
	  --utils:info("Execute Net CMD:"..com)
	  commandFunc(address, msg)
	else
	  utils:warn("Cannot recognise Net CMD:"..com)
	end
end

return RRMNetwork