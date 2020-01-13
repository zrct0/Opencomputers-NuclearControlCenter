local ReactorRedStoreIO = {}

local ic = require("IComponent")
local utils = require("IUtils")
local cp = require("component")
local reactor = nil

ReactorRedStoreIO.redstone = nil
ReactorRedStoreIO.isAdapted = false
ReactorRedStoreIO.reactorSide = -1

function ReactorRedStoreIO:adapte()  
  utils:init("RedStoreIO start adapte")
  self.redstone = ic:invoke("redstone", nil, "Cannot Find Component [Redstone IO]")
  reactor = ic:invoke("reactor_chamber", nil, "Cannot Find Component [Reactor_chamber]")
  if self.redstone == nil or reactor == nil then return end
  local lastRSStatus = self.redstone.setOutput({0,0,0,0,0,0}) 
  utils:init("Close all side output")  
  os.sleep(0.5)
  for side = 0, 5 do
    utils:init("RedStoreIO start testing Side "..side)
    self.redstone.setOutput(side,7)
	os.sleep(0.5)
    isRunning = reactor.producesEnergy()
	if isRunning then
	  self.reactorSide = side
	  utils:init("Find reactor in Side "..side)
	  self.redstone.setOutput(side,lastRSStatus[side])
	  os.sleep(0.5)
	  utils:init("RedStoreIO adapte finished")	
      self.isAdapted = true	  
	  return true
	end
	self.redstone.setOutput(side,0)
	os.sleep(0.5)
  end
  utils:error("Cannot find reactor")
  return false
end

function ReactorRedStoreIO:reactorStartup(value)
  self:sendRedStoreToReactor(7)  
end

function ReactorRedStoreIO:reactorStop(value)
  self:sendRedStoreToReactor(0)  
end

function ReactorRedStoreIO:sendRedStoreToReactor(value)
  if cp.isAvailable("redstone") then  
    cp.redstone.setOutput(self.reactorSide,value)
	utils:warn("Send RedStore To Reactor :"..value)
  end
end

return ReactorRedStoreIO