local reactorTransposer = {}


reactorTransposer.serialization = require("serialization")
reactorTransposer.component = require("component")
reactorTransposer.tp = require("component").transposer
reactorTransposer.item1Name = "IC2:reactorCoolantSix"
reactorTransposer.item2Name = "IC2:reactorVentGold"
reactorTransposer.item1Side = 0
reactorTransposer.item2Side = 0
reactorTransposer.reactorSide = 0
reactorTransposer.reactorMap = 0

function reactorTransposer:init()
  self:adapte()
end

function reactorCoor2Index(x, y)
  return x * 9 + y + 1
end

function reactorTransposer:scanReactorItem()
  local reactorInventorySize = self.tp.getInventorySize(side)
  for k=1, inventorySize do
    local slotSize = self.tp.getSlotStackSize(side, j)
	if slotSize > 0 then
	  local slotStack = self.tp.getStackInSlot(side, j)
	  if slotStack.name == self.item1Name then
	    self.reactorMap[k] = 1
	  elseif slotStack.name == self.item2Name then
	    self.reactorMap[k] = 2
	  else
	    self.reactorMap[k] = 0
	  end 
	end
  end
  self:writeReactorMap() 
  print("scan finished")  
end

function reactorTransposer:reductionReactorMap()
  local reactorInventorySize = self.tp.getInventorySize(side)
  local reactorMapSize = #reactorMap
  local iterSize = reactorInventorySize > reactorMapSize and reactorInventorySize or reactorMapSize
  for slot=1,iterSize  do
    slotId = reactorMap[slot]
    if slotId == 1 then
	  self:transferItem1ToReactor(slot)
	elseif slotId == 2 then
	  self:transferItem2ToReactor(slot)
	end
  end
  print("Reduction finished")
end

function reactorTransposer:saveReactorMap()
  local str = self.serialization.serialize(self.reactorMap)  
  self:writeFile(str, "reactorScanMap")
  print("Saving reactor map successed")
end

function reactorTransposer:loadReactorMap()
  local str = self:readFile("reactorScanMap")
  self.reactorMap = self.serialization.unserialize(str)  
  print("Loading reactor map successed")
end

function reactorTransposer:writeFile(data, fileName)
  local file = io.open(fileName, "w")
  file:write(data)
  file:close()
  print("Writed"..fileName)
end

function reactorTransposer:readFile(fileName)
  local file = io.open(fileName, "r")
  str = ""
  for line in file:lines() do
    str = str..line
  end
  print("Readed"..fileName)
  return str
end

function reactorTransposer:transferItem1ToReactor(reactorSlot) 
  local slot, item1Item = self:getItem(self.item1Side)
  if item1Item ~= nil then
    reactorItem = self:getReactorItem(reactorSlot)
	if reactorItem == nil then
	  self.tp.transferItem(self.item1Side, self.reactorSide, 1, slot, reactorSlot)
	  print("Transfer 1 "..self.item1Name.." to Reactor")
	end
  else
    error(self.item1Name.." is Empty")
  end  
end

function reactorTransposer:transferItem2ToReactor(reactorSlot) 
  local slot, ventItem = self:getItem(self.item2Side)
  if ventItem ~= nil then
    reactorItem = self:getReactorItem(reactorSlot)
	if reactorItem == nil then
	  self.tp.transferItem(self.item2Side, self.reactorSide, 1, slot, reactorSlot)
	  print("Transfer 1 "..self.item2Name.." to Reactor")
	end
  else
    error(self.item2Name.." is Empty")
  end  
end

function reactorTransposer:getReactorItem(reactorSlot)
  local slotStack = self.tp.getStackInSlot(self.reactorSide, reactorSlot)
  return slotStack
end

function reactorTransposer:adapte()
  for i=0, 5 do
    local inventoryName = self.tp.getInventoryName(i)
	if inventoryName ~= nil then
	  print("Find"..inventoryName.."in Side "..i)
	end
	if inventoryName == "tile.chest" then
	  slot, item = self:getItem(i)
	  itemName = item.name
	  if itemName == self.item1Name then
	    self.item1Side = i
	  elseif itemName == self.item2Name then
	    self.item2Side = i
	  else
	    error("the side "..i.." chest is unidentified")
	  end
	elseif inventoryName == "blockReactorChamber" then
	  self.reactorSide = i
	end	
  end
  print("Transposer adapte successed")
  print("Reactor side:", self.reactorSide)
  print(self.item1Name.." side:", self.item1Side)
  print(self.item2Name.." side:", self.item2Side)
end
  
function reactorTransposer:getItem(side)
  local inventorySize = self.tp.getInventorySize(side)
  for j=1, inventorySize do
    local slotSize = self.tp.getSlotStackSize(side, j)
	if slotSize > 0 then
	  local slotStack = self.tp.getStackInSlot(side, j)
	  return j, slotStack
	end
  end	
  return nil
end

return reactorTransposer