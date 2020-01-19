local RRMMainScreen = {}

local event = require("event")
local rrnn = require("RRMNetwork")
local ithread = require("IThread")
local RRMGpu = require("RRMGpu")
local utils = require("IUtils")
local text = require("text")
local mainGpu = nil
local w, h = 0, 0

local RLMsCount = 0
local RLMsName = {}
local RLMsName2ID = {}
local RLMSID2BlockID = {}
local startX, startY, blockW, blockH = {}, {}, 0, 10
local blocksColor = {}
local blocksOutputCache = {nil, nil, nil, nil}
local blocksConnectState = {}

local color = {}
color.running = 0x004900
color.disconnet = 0x2D2D2D

function RRMMainScreen:onRSICome(name, data)  
  local RLMId = RLMsName2ID[name]
  if RLMId == nil then
    RLMsName[RLMsCount] = name
	RLMsName2ID[name] = RLMsCount	
	RLMId = RLMsCount
	RLMSID2BlockID[RLMsCount] = RLMId
	RLMsCount = RLMsCount + 1    
  end  
  blocksOutputCache[RLMId] = {name, data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9]} 
  RRMMainScreen.printRSI(RRMMainScreen, RLMId)  
end

function RRMMainScreen:orderBlockIDTable()
  for i=0, RLMsCount-1 do
    local name = RLMsName[i]
    local orderSpac = self:getNameOrderSpac(name)
  end
end

function RRMMainScreen:getNameOrderSpac(name)
  local numberName = ""
  for i=1,#name do
    local chr = string.sub(name,i,i)	
	local ascii = string.byte(chr)
	if ascii > 47 and ascii < 58 then
	  numberName = numberName..chr
	end
  end
  local orderSpac = tonumber(numberName)
  if orderSpac then
    return orderSpac
  end
  return 0
end

function RRMMainScreen:onRLMDisconneted(RLMName, timeout)  
  local RLMId = RLMsName2ID[RLMName]   
  if RLMId ~= nil then
    utils:error("[onRLMDisconneted]ID:"..RLMId..", name:"..RLMName..",timeout:"..timeout) 
    RRMMainScreen.setBlockConetedStatus(RRMMainScreen, RLMId, false)
  end
end

function RRMMainScreen:thread()
  while true do
    local _, screenAddress, x, y, button, playerName = event.pull("touch")     
	if RRMGpu.mainScreen.address == screenAddress then
      self:onMainScreenTouch(x, y)
	end
  end
end

function RRMMainScreen:initialize()
  mainGpu, w, h = RRMGpu:adapte() 
  --RRMGpu:clear()
  startX = {0, w/2 + 2, 0, w/2 + 2}  
  startY = {9, 9, 20, 20}  
  blockW = w/2 - 1
  blocksConnectState = {false, false, false, false}
  blocksColor = {color.disconnet, color.disconnet, color.disconnet, color.disconnet}
  RRMGpu:DrawBox(0, 0 , w+1, h-6, " ", 0x000040) --draw background
  RRMGpu:DrawBox(0, 0 , w+1, 8, " ", 0x3300C0)   --draw title bander
  for i=1, 4 do
    RRMGpu:DrawBox(startX[i], startY[i] , blockW, blockH, " ", blocksColor[i]) --draw blocks background
  end
  RRMGpu:drawPaint("/home/lib/rrm_title.gi", w/2 - 15, 1, 0xFFFFFF, mainGpu) --draw title
  rrnn:initialize(self.onRSICome, self.onRLMDisconneted)
  ithread:create(self.thread, self, "RRMMainScreen")
  --self:thread()
end

function RRMMainScreen:printRSI(id)
  self:setBlockConetedStatus(id, true)
  self:printBlockCache(id)  
end

function RRMMainScreen:printBlockCache(id)      
  local sx, sy = startX[id+1] + 2, startY[id+1]
  local blockOutputCache = blocksOutputCache[id]
    if blockOutputCache ~= nil then
    if blockOutputCache[2] then
      RRMGpu:DrawBox(sx + 1, sy + 2 , 2, 1, " ", 0x00FF00)
    else
      RRMGpu:DrawBox(sx + 1, sy + 2 , 2, 1, " ", 0xFF0000)
    end
  
    local lsx, lsy = sx + 4, sy + 1
	local col2 = lsx + 25
    mainGpu.setBackground(blocksColor[id+1])
    RRMGpu:print(lsx, lsy + 1, "Reactor #"..blockOutputCache[1], nil, col2)
    RRMGpu:print(lsx, lsy + 2, "Action:"..string.upper(blockOutputCache[3]), blockOutputCache[3] == "idle" and 0xFFFFFF or 0xFFFF00, col2)
    RRMGpu:print(lsx, lsy + 3, "Control Status:"..string.upper(blockOutputCache[4]), blockOutputCache[4] == "auto" and 0xFFFFFF or 0xFF0000, col2)
    RRMGpu:print(lsx, lsy + 4, "Heat:"..blockOutputCache[5].."/10000".."("..tostring(math.ceil(tonumber(blockOutputCache[5])*100/10000)).."%)", blockOutputCache[5] > 2000 and 0xFFFF00 or 0xFFFFFF, col2)
    RRMGpu:print(lsx, lsy + 5, "EUOutput:"..blockOutputCache[6], nil, col2)
    RRMGpu:print(lsx, lsy + 6, "EnergyOutput:"..blockOutputCache[7], nil, col2)
	if blockOutputCache[8] ~= "nil" then
      RRMGpu:print(lsx, lsy + 7, "MFE:"..blockOutputCache[8].."/4000000".."("..tostring(math.ceil(tonumber(blockOutputCache[8])*100/4000000)).."%)", nil, col2)
    else
	  RRMGpu:print(lsx, lsy + 7, "MFE : Not Connected", nil, col2)    
    end
	
	--Draw items count	
	if blockOutputCache[9] and blockOutputCache[10] then
	  local chestItemsCount, itemsAlias = blockOutputCache[9], blockOutputCache[10]
	  for i=0, 4 do
	    if i <= #chestItemsCount then
          RRMGpu:print(col2 + 1, lsy + i + 2, itemsAlias[i]..":"..chestItemsCount[i], nil, 10)
        else
          RRMGpu:print(col2 + 1, lsy + i + 2,  " ", nil, 10)  
	    end
	  end
	end
  end
end

function RRMMainScreen:onMainScreenTouch(x, y)    
    for i=0, 3 do
	  if self:isBlockContainPoint(i, x, y) then
	    self:onBlockTouch(i)
	  end
	end
end

function RRMMainScreen:isBlockContainPoint(blockId, x, y)
    local sx, sy = startX[blockId+1], startY[blockId+1]
	return x >= sx and x < sx + blockW and y >= sy and y < sy + blockH
end

function RRMMainScreen:onBlockTouch(blockId)    
	local RLMName = RLMsName[blockId]	
	if RLMName ~= nil then
	  local isRunning = blocksOutputCache[blockId][2]
	  rrnn:sendRLMLocalCommad(RLMName, isRunning and "stop" or "start")
	end	
end

function RRMMainScreen:setBlockConetedStatus(blockId, isConnected)  
  if  blocksConnectState[blockId + 1] ~= isConnected then    
    blocksConnectState[blockId + 1] = isConnected
    local color = isConnected and color.running or color.disconnet
    blocksColor[blockId + 1] = color
    RRMGpu:DrawBox(startX[blockId + 1], startY[blockId + 1] , blockW, blockH, " ", color)
    if 	not isConnected then
	  self:printBlockCache(blockId)  
	end
  end
end

return RRMMainScreen