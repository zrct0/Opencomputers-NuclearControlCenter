local ReactorLocalNetwork = {}

local utils = require("IUtils")
local network = require("INetwork")

local rlc = require("ReactorLocalCommad")
local rn = require("ReactorName")

ReactorLocalNetwork.RRMAddress = nil
ReactorLocalNetwork.RRCAddress = nil

ReactorLocalNetwork.commandList = 
{
  ["Respond RRM Address"] = function(address, msg) 
    ReactorLocalNetwork.RRMAddress = address
	utils:info("Connet to RRM:", address)
  end,  
  
  ["Respond RRC Address"] = function(address, msg) 
    ReactorLocalNetwork.RRCAddress = address
	utils:info("Connet to RRC:", address)
  end,  
  
  ["Require RLM Address"] = function(address, msg)
    if msg == "RRM" then
	  ReactorLocalNetwork.RRMAddress = address
	  ReactorLocalNetwork.sendRRM(ReactorLocalNetwork,"Respond Address", rn.name)
	  utils:info("Connet to RRM:", address)
	elseif msg == "RRC" then
	  ReactorLocalNetwork.RRCAddress = address
	  ReactorLocalNetwork.sendRRC(ReactorLocalNetwork,"Respond Address", rn.name)
	  utils:info("Connet to RRC:", address)
    end	    	
  end,
  
  ["Ask RLM Alive"] = function(address, msg) 
    ReactorLocalNetwork.sendRRC(ReactorLocalNetwork,"Respond RLM ALive", rn.name)
  end,
  
  ["Local CMD"] = function(address, msg) 
    rlc:execute(msg)
  end,
}

function ReactorLocalNetwork:isConnentRRM()
    return self.RRMAddress 
end

function ReactorLocalNetwork:isConnentRRC()
    return self.RRCAddress
end

function ReactorLocalNetwork:sendRRM(CMD, Msg)
  utils:debug("[sendRRM]"..CMD..":"..Msg) 
  if self.RRMAddress then
    network:send(self.RRMAddress, CMD, Msg)
  end  
end

function ReactorLocalNetwork:sendRRC(CMD, Msg)
  utils:debug("[sendRRC]"..CMD..":"..Msg) 
  if self.RRCAddress then
    network:send(self.RRCAddress, CMD, Msg)
  end  
end

function ReactorLocalNetwork:onMessageCome(Address, CMD, Msg)
  utils:debug("@Address:", Address, ", CMD:", CMD, ", Msg:", Msg)
  ReactorLocalNetwork.execute(ReactorLocalNetwork, Address, CMD, Msg)
end

function ReactorLocalNetwork:initialize()   
  network:initialize(self.onMessageCome)   
  network:broadcast("Require OCC Address", rn.name)
  utils:init("Require OCC Address")   
end

function ReactorLocalNetwork:execute(address, com, msg)  
   local commandFunc = self.commandList[com]
	if commandFunc ~= nil then
	  if com == "Ask RLM Alive" then
	    utils:debug("Execute Net CMD:"..com)
	  else
	    utils:warn("Execute Net CMD:"..com)
	  end
	  commandFunc(address, msg)
	else
	  utils:warn("Cannot recognise Net CMD:"..com)
	end
end

return ReactorLocalNetwork