local ReactorStatus = {}

local serialization = require("serialization")
local term = require("term")
local cp = require("component")
local rn = require("ReactorName")
local ic = require("IComponent")
local rt = require("ReactorTransposer")
local utils = require("IUtils")
local CMDsGpu = require("CMDsGpu")
local config = require("IConfig")

local network = nil

ReactorStatus.reactor = nil
ReactorStatus.isRunning = false
ReactorStatus.action = "idle"
ReactorStatus.controlStatus = "auto"
ReactorStatus.heat = 0
ReactorStatus.maxHeat = 0
ReactorStatus.EUOutput = 0
ReactorStatus.EnergyOutput = 0
ReactorStatus.mfeStored = 0
ReactorStatus.mfeCapacity = 0
ReactorStatus.isInitialize = false

ReactorStatus.chestItemsCount = nil
ReactorStatus.itemsAlias = nil

local screenTier = 1
local printCols = {2, 30, 55}
local printTimeCol = {25,55, 55}

function ReactorStatus:initialize(_network)    
  self.isInitialize = true 
  network = _network
  screenTier = CMDsGpu:getTier()
  if screenTier == 1 then
    printCols = {1, 21, 36}
  end
  
end

function ReactorStatus:setAction(_action)
  utils:warn("Action Change:"..ReactorStatus.action.."==>".._action)
  ReactorStatus.action = _action
end

function ReactorStatus:setControlStatus(cs, force)
  if cs == "auto" or cs == "manual" or force then
    utils:warn("Control Status Change:"..ReactorStatus.controlStatus.."==>"..cs)
    ReactorStatus.controlStatus = cs
	return true   
  end
  return false
end

function ReactorStatus:pullInfo()  
  self.reactor = ic:invoke("reactor_chamber", nil, "Cannot Find Component [Reactor_chamber]")
  if self.reactor == nil then return end
  self.isRunning = self.reactor.producesEnergy()
  self.heat = self.reactor.getHeat()
  self.maxHeat = self.reactor.getMaxHeat()
  self.EUOutput = self.reactor.getReactorEUOutput()
  self.EnergyOutput = self.reactor.getReactorEnergyOutput()
  self.mfeStored = ic:invoke(config.power_storage, "getStored", nil, "nil")
  self.mfeCapacity = ic:invoke(config.power_storage, "getCapacity", nil, 0)  
end

function ReactorStatus:scanChestItemsCountThread()
  while true do
    self.chestItemsCount , self.itemsAlias = rt:getChestItem()	
  end
end

function ReactorStatus:printInfo(startLine) 
  local col1, col2, col3 = printCols[1], printCols[2] , printCols[3] 
  local pad1, pad2, pad3 = col2-1, col3-col2 , 30      
  CMDsGpu:print(col1, startLine + 0, "REACTOR #"..rn.name, nil, screenTier <= 1 and (printTimeCol[screenTier] - 1) or 160)
  CMDsGpu:print(col1, startLine + 1, self.isRunning and "Running" or "Stop", self.isRunning and 0x00FF00 or 0xFF0000, pad1)
  CMDsGpu:print(col1, startLine + 2, "Heat:"..self.heat.."/"..self.maxHeat, self.heat > 2000 and 0xFFFF00 or 0xFFFFFF, pad1)
  CMDsGpu:print(col1, startLine + 3, "EU output"..self.EUOutput, nil, pad1)
  CMDsGpu:print(col1, startLine + 4, "Energy output:"..self.EnergyOutput, nil, pad1)
  CMDsGpu:print(col1, startLine + 5, string.upper(config.power_storage).." :"..tostring(cp.isAvailable(config.power_storage) and  (self.mfeStored.."/"..self.mfeCapacity) or "Not Connected"), nil, pad1) 
  CMDsGpu:fill(col1, startLine + 6, screenTier > 1 and (printTimeCol[screenTier]-2) or 160, 1, "=")  
  
  
  CMDsGpu:print(col2, startLine + 1, "Action: "..string.upper(self.action), self.action == "idle" and 0xFFFFFF or 0xFFFF00, pad2)
  CMDsGpu:print(col2, startLine + 2, (screenTier > 1 and "Control Status: " or "CTRL: ")..string.upper(self.controlStatus), self.controlStatus == "auto" and 0xFFFFFF or 0xFF0000, pad2)
  CMDsGpu:print(col2, startLine + 3, " ", nil, pad2)
  CMDsGpu:print(col2, startLine + 4, "RRM: "..(network:isConnentRRM() and "Connecting" or "Disconnected"), nil, pad2)
  CMDsGpu:print(col2, startLine + 5, "RRC: "..(network:isConnentRRM() and "Connecting" or "Disconnected"), nil, pad2)    

  if self.chestItemsCount and self.itemsAlias then
    for i=0, 4 do
	  if i <= #self.chestItemsCount then
        CMDsGpu:print(col3, startLine + 1 + i, self.itemsAlias[i]..":"..self.chestItemsCount[i], nil, pad3)
      else
        CMDsGpu:print(col3, startLine + 1 + i, " ", nil, pad3)  
	  end
	end
  end
  CMDsGpu:print(printTimeCol[screenTier], startLine + (screenTier > 1 and 6 or 0), "Cureent: "..os.date(), nil, pad3)    
  
end



function ReactorStatus:getSerializeInfo() 
  local data = {self.isRunning, self.action, self.controlStatus, self.heat, self.EUOutput, self.EnergyOutput, self.mfeStored }
  return serialization.serialize(data)
end


return ReactorStatus