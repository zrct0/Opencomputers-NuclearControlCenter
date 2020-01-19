local RRCScreen = {}

local event = require("event")
local rrcn = require("RRCNetwork")
local ithread = require("IThread")
local CMDsGpu = require("CMDsGpu")
local RRCGpu = require("RRCGpu")
local RRCBlockCMDs = require("RRCBlockCMDs")
local utils = require("IUtils")

local blocks = {}

local RLMsCount = 0
local RLMsName = {}
local RLMsName2ID = {}
local w, h = 0, 0
local gpu

local startX, startY, blockW, blockH = {}, {}, 0, 0
local blocksColor = {}
local blocksConnectState = {}

local color = {}
color.running = 0x002400
color.disconnet = 0x0F0F0F

function RRCScreen:initialize()
  CMDsGpu:initialize()  
  gpu, w, h = RRCGpu:adapte()
  CMDsGpu:setPrintPosition(h-7, h-2)
  RRCGpu:clear()
  blockW = w/2 - 1
  blockH = h/2 - 9
  startX = {0, w/2 + 2, 0, w/2 + 2}  
  startY = {9, 9, 10 + blockH, 10 + blockH}  
  blocksConnectState = {false, false, false, false}
  blocksColor = {color.disconnet, color.disconnet, color.disconnet, color.disconnet}
  RRCGpu:DrawBox(0, 0 , w+1, 8, " ", 0x3300C0)   --draw title bander
  RRCGpu:drawPaint("/home/lib/rrc_title.gi", w/2 - 15, 1, 0xFFFFFF)
  RRCGpu:DrawBox(0, 8 , w+1, h-14, " ", 0x000040) --draw background
  for i=1, 4 do
    RRCGpu:DrawBox(startX[i], startY[i] , blockW, blockH, " ", blocksColor[i]) --draw blocks background	
	blocks[i] = RRCBlockCMDs:new(startX[i], startY[i] , blockW, blockH)
  end  

  rrcn:initialize(self.onLCCome, self.onRLMDisconneted)
end

function RRCScreen:onRLMDisconneted(RLMName)  
  local RLMId = RLMsName2ID[RLMName]   
  if RLMId ~= nil then
    utils:error("[onRLMDisconneted]"..RLMId.." :"..RLMName)  
  end
end

function RRCScreen:onLCCome(name, data)  
  local RLMId = RLMsName2ID[name]
  if not RLMId then
    RLMsName[RLMsCount] = name
	RLMsName2ID[name] = RLMsCount
	RLMId = RLMsCount
	RLMsCount = RLMsCount + 1    
  end    
  RRCScreen:printCMDtoBlock(RLMId, name, data)
end

function RRCScreen:printCMDtoBlock(blockId, RLMName, data)
  local CMDBlock = blocks[blockId + 1]  
  CMDBlock:writeCMDsCache(data[1], data[2])  
  CMDBlock:printCMDsCache(blocksColor[blockId + 1])
end

return RRCScreen