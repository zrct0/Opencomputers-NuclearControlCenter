local ReactorTransposer = {}

local ic = require("IComponent")
local utils = require("IUtils")
local serialization = require("serialization")
local cp = require("component")
local chestName = "tile.chest"

ReactorTransposer.isAdapted = false
ReactorTransposer.tp = nil
ReactorTransposer.itemsCount = 0
ReactorTransposer.itemsName = {}
ReactorTransposer.itemsName2Id = {}
ReactorTransposer.itemsSide = {}
ReactorTransposer.reactorSide = 0
ReactorTransposer.reactorMap = {}
ReactorTransposer.chestItemsCount = {}
ReactorTransposer.itemsAlias = {}

function ReactorTransposer:adapte()  
  utils:init("Transposer start adapte")
  self.tp = ic:invoke("transposer", nil, "Cannot Find Component [Transposer]") 
  if self.tp == nil then return end
  self.itemsCount = 0
  for i=0, 5 do
    local inventoryName = self.tp.getInventoryName(i)	
	if inventoryName == chestName then
	  local slot, item = self:getItem(i)
      if item ~= nil then
        self.itemsName[self.itemsCount] = item.name	  
		self.itemsAlias[self.itemsCount] = self:getItemAlias(item.name)	 
	    self.itemsSide[self.itemsCount] = i
		self.chestItemsCount[self.itemsCount] = 0
	    self.itemsName2Id[item.name] = self.itemsCount		
        self.itemsCount = self.itemsCount + 1	
      else
	    utils:warn("Side "..i.." Chest is Empty")
      end	  
	elseif inventoryName == "blockReactorChamber" then
	  self.reactorSide = i
	end	
  end  
  utils:init("Reactor side:", self.reactorSide)
  utils:init("Find "..self.itemsCount.." Items")
  for i=0, self.itemsCount-1 do
    utils:init(">side "..self.itemsSide[i].."  "..self.itemsName[i])
  end
  utils:init("Transposer adapte finished")
  self.isAdapted = true
end

function ReactorTransposer:getItemAlias(name)  
  if #name > 5 then   
    local alias = ""
    for i=1,#name do
      local chr = string.sub(name,i,i)	 
	  if i == 1 or string.byte(chr) < 97 then
	    alias = alias..chr
	  end
    end
    return alias
  else
    return name
  end  
end

function ReactorTransposer:getChestItem()
  utils:debug("Scan chest's items count")
  for i=0, #self.itemsSide do
    local side = self.itemsSide[i]
    local chestInventorySize = self.tp.getInventorySize(side)
	local chestItemCount = 0
	for j=1, chestInventorySize do
	  local slotSize = self.tp.getSlotStackSize(side, j)
	  chestItemCount = chestItemCount + slotSize	
      os.sleep(0.2)	  
	end
	self.chestItemsCount[i] = chestItemCount	
  end
  utils:debug("Scan chest's items count Finished")
  return self.chestItemsCount, self.itemsAlias
end

function ReactorTransposer:scanReactorItem()  
  utils:info("Start scan reactor's item")
  self.tp = ic:invoke("transposer", nil, "Cannot Find Component [Transposer]") 
  if self.tp == nil then return end
  local reactorInventorySize = self.tp.getInventorySize(self.reactorSide)
  for k=1, reactorInventorySize do
     os.sleep(0.2)
    local slotSize = self.tp.getSlotStackSize(self.reactorSide, k)
	if slotSize > 0 then
	  local slotStack = self.tp.getStackInSlot(self.reactorSide, k)
	  for i=0, self.itemsCount-1 do
	    self.reactorMap[k] = slotStack.name
	  end 
	end	
  end
  self:saveReactorMap() 
  utils:info("scan reactor's items finished")  
end

function ReactorTransposer:reductionReactorMap()  
  utils:info("Start reduction")
  self.tp = ic:invoke("transposer", nil, "Cannot Find Component [Transposer]") 
  if self.tp == nil then return end
  if #self.reactorMap == 0 then      
    if not self:loadReactorMap() then
	  return false
	end
  end
  local reactorInventorySize = self.tp.getInventorySize(self.reactorSide)
  local reactorMapSize = #self.reactorMap
  local iterSize = reactorInventorySize > reactorMapSize and reactorInventorySize or reactorMapSize
  local transferCounts = 0
  for slot=1,iterSize  do   
    mapName = self.reactorMap[slot]
	if mapName ~= nil then
      if self:transferItemToReactor(slot, mapName) then
	    transferCounts = transferCounts + 1
      end
    end   	
  end
  utils:info("Transfer "..transferCounts.." items")
  utils:info("Reduction finished")
  return true
end

function ReactorTransposer:transferItemToReactor(reactorSlot, ItemName)  
  os.sleep(0.5) 
  local result = false
  local itemId = self.itemsName2Id[ItemName]
  if itemId ~= nil then
    local slot, item = self:getItem(self.itemsSide[itemId])
    if item ~= nil then
      reactorItem = self:getReactorItem(reactorSlot)
	  if reactorItem == nil then
	    self.tp.transferItem(self.itemsSide[itemId], self.reactorSide, 1, slot, reactorSlot)
	    utils:info("Transfer "..ItemName.." to Reactor")
	    result = true
      end
    else
      utils:error(ItemName.." is Empty")
    end
  else
    utils:error(ItemName.." Cannot find")
  end
  return result  
end

function ReactorTransposer:transferAllItemReturnChest()
  utils:info("Start Return All Item to Chest")   
  self.tp = ic:invoke("transposer", nil, "Cannot Find Component [Transposer]") if self.tp == nil then return end   
  local returnCounts = 0
  local reactorInventorySize = self.tp.getInventorySize(self.reactorSide)
  for k=1, reactorInventorySize do
    local slotSize = self.tp.getSlotStackSize(self.reactorSide, k)
	if slotSize > 0 then
	  local slotStack = self.tp.getStackInSlot(self.reactorSide, k)
	  local itemId = self.itemsName2Id[slotStack.name]
      if itemId ~= nil then
	    local emptySolt = self:getEmptySlot(self.itemsSide[itemId])
		if emptySolt ~= nil then
	      self.tp.transferItem(self.reactorSide, self.itemsSide[itemId], 1, k, emptySolt)
		  utils:info("Return "..slotStack.name)
		else
		  utils:error("Return "..slotStack.name.." False")
		end
	  end
	end	
	os.sleep(0.5)
  end
  utils:info("Total rRturn "..returnCounts.." Items")
  utils:info("Return Items Finished")
end


function ReactorTransposer:saveReactorMap()
  local str = serialization.serialize(self.reactorMap)  
  utils:writeFile(str, "reactor_scan_map")
  utils:info("Saving reactor map finished")
end

function ReactorTransposer:loadReactorMap()
  if not utils:fileExist("/home/reactor_scan_map") then
    utils:warn("Cannot find remap file")
    return false
  end
  local str = utils:readFile("reactor_scan_map")  
  self.reactorMap = serialization.unserialize(str)  
  utils:info("reactorMap size:"..#self.reactorMap)
  utils:info("Loading reactor map finished")
  return true
end

function reactorCoor2Index(x, y)
  return x * 9 + y + 1
end



function ReactorTransposer:getReactorItem(reactorSlot)
  local slotStack = self.tp.getStackInSlot(self.reactorSide, reactorSlot)
  return slotStack
end
  
function ReactorTransposer:getItem(side)
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

function ReactorTransposer:getEmptySlot(side)
  local inventorySize = self.tp.getInventorySize(side)
  for j=1, inventorySize do
    local slotSize = self.tp.getSlotStackSize(side, j)
	if slotSize == 0 then	  
	  return j
	end
  end	
  return nil
end

return ReactorTransposer