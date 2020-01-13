local INetwork = {}

local serialization = require("serialization")
local event = require("event")
local ic = require("IComponent")
local cp = require("component")
local utils = require("IUtils")
local ithread = require("IThread")

local m = nil

local m_port = 100

local NetPackage = 
{  
  "CMD","Msg"
}

INetwork.callback = nil

function INetwork:thread()
  while true do
    local _, _, from, port, _, message = event.pull("modem_message")    
	local pkg = serialization.unserialize(message)	
	if self.callback ~= nil then
	  self.callback(_, from, pkg[1], pkg[2])
	else
	  utils:debug("INetwork callback is nil")
	end
  end
end

function INetwork:initialize(_callback)
  m = ic:invoke("modem", nil, "Cannot Find Component [modem]") 
  if m == nil then return end
  self.callback = _callback   
  utils:init("Modem Open PORT "..m_port.." :"..tostring(m.open(m_port)))
  ithread:create(self.thread, self, "INetwork")
  --self:thread()
end

function INetwork:broadcast(CMD, Msg)
  m = ic:invoke("modem", nil, "Cannot Find Component [modem]") 
  if m == nil then return end
  local pkg = serialization.serialize({CMD, Msg})  
  m.broadcast(m_port, pkg)
end

function INetwork:send(address, CMD, Msg)
  m = ic:invoke("modem", nil, "Cannot Find Component [modem]") 
  if m == nil then return end
  local pkg = serialization.serialize({CMD, Msg})
  m.send(address, m_port, pkg)
end

return INetwork