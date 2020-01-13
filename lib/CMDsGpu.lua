local CMDsGpu = {}

local computer = require("computer")
local text = require("text")

local CMDsCache = {}
local CMDsCount = 0
local CMDsIter = 0
local MAX_CMDs_COUNT = 20
local w, h = 0
local MAIN_INFO_HEIGHT = 0
local CMDs_INFO_HEIGHT = 0
local cmd_type_id = {["all"] = -1, ["debug"] = 0, ["init"] = 1, ["info"] = 2, ["warn"] = 3, ["error"] = 4}
local cmd_type_color = {["debug"] = 0xFFFFFF, ["init"] = 0xFF00FF, ["info"] = 0x0000FF, ["warn"] = 0xFFFF00, ["error"] = 0xFF0000}
local isInitialize = false
local current_cmd_type = "init"

local CMDMsgCallback = nil
local gpu

function CMDsGpu:initialize(_gpu)
  if not _gpu then 
    _gpu = require("component").gpu
  end   
  gpu = _gpu
  w, h = gpu.getViewport()
  MAIN_INFO_HEIGHT = 9
  CMDs_INFO_HEIGHT = h - MAIN_INFO_HEIGHT - 1
  local totalMemory = computer.freeMemory() 
  local Memory_1T = 19300
  if totalMemory > Memory_1T * 2 then
    MAX_CMDs_COUNT = 70
  end
  if totalMemory > Memory_1T * 3 then
    MAX_CMDs_COUNT = 200
  end
  if totalMemory > Memory_1T * 4 then
    MAX_CMDs_COUNT = 600
  end
  print("totalMemory:"..totalMemory..", MAX_CMDs_COUNT:"..MAX_CMDs_COUNT)
  isInitialize = true
end

function CMDsGpu:setCMDMsgCallback(_CMDMsgCallback)  
  CMDMsgCallback = _CMDMsgCallback
end

function CMDsGpu:getTier()  
  if w <= 50 then
    return 1
  elseif w <= 80 then
    return 2
  else
    return 3
  end  
end

function CMDsGpu:writeCMDsCache(cmd_type, cmd)
  local cache = {cmd_type, tostring(CMDsIter < 10 and "[0" or "[")..CMDsIter.."]"..cmd}
  CMDsCache[CMDsIter] = cache
  CMDsIter = CMDsIter + 1
  if CMDsIter >= MAX_CMDs_COUNT then
    CMDsIter = 0
  end 
  if CMDsCount < MAX_CMDs_COUNT then
    CMDsCount = CMDsCount + 1
  end
  
  if cmd_type_id[cmd_type] >= cmd_type_id["init"] then
    if CMDMsgCallback then
      CMDMsgCallback(_, cache)
	end
  end
end

function CMDsGpu:printLine(line, str, color, line_count_backwards, padRight)
  if line_count_backwards then
    line = h - line
  end
  self:print(2, line, str, color, padRight)
end

function CMDsGpu:print(x, y, str, color, padRight)

  if color == nil or gpu.getDepth() < 4 then
    color = 0xFFFFFF
  end
  if padRight == nil then
    padRight = w
  end
  gpu.setForeground(color)
  gpu.setBackground(0x000000)
  gpu.set(x, y, text.padRight(str, padRight))
  gpu.setForeground(0xFFFFFF)
end

function CMDsGpu:fill(x, y, w, h, chr, color)

  if color == nil or gpu.getDepth() < 4 then
    color = 0xFFFFFF
  end
  gpu.setForeground(color)
  gpu.setBackground(0x000000)
  gpu.fill(x, y, w, h ,chr)
  gpu.setForeground(0xFFFFFF)
end

function CMDsGpu:printCMDsCache()
  if not gpu then 
    gpu = require("component").gpu
	w, h = gpu.getViewport()
	CMDs_INFO_HEIGHT = 5
  end 
  
  local CMDsTypeCache, CMDsTypeCacheCount = self:getCMDsCache(CMDs_INFO_HEIGHT)
  local lastLine = math.min(CMDs_INFO_HEIGHT, CMDsTypeCacheCount - 1)
  local line = h - 2
  for i=0, lastLine do
    gpu.setForeground(self:getCMDColor(CMDsTypeCache[i][1]))
    gpu.setBackground(0x000000)
    gpu.set(2, line, text.padRight(CMDsTypeCache[i][2], w))
    line = line - 1
  end 
  gpu.setForeground(0xFFFFFF)

end

function CMDsGpu:getCMDColor(cmd_type)
  if gpu.getDepth() >= 4 then
    return cmd_type_color[cmd_type]
  else
    return 0xFFFFFF
  end
end

function CMDsGpu:setCmdType(cmd_type)  
  if cmd_type_id[cmd_type] ~= nil then
    gpu.fill(1, MAIN_INFO_HEIGHT, w, h, " ")   
	self:writeCMDsCache("info", "["..os.date("%X").."]INFO:"..str)
    self:printCMDsCache()   
    current_cmd_type = cmd_type
	return true
  end
  return false
end

function CMDsGpu:getCMDsCache(count)
  local CMDsTypeCache = {}
  local CMDsTypeCacheIter = 0
  for i=CMDsIter-1, 0, -1 do  
    if current_cmd_type == "all" or cmd_type_id[CMDsCache[i][1]] >= cmd_type_id[current_cmd_type] then
	  if CMDsTypeCacheIter < count then
        CMDsTypeCache[CMDsTypeCacheIter] = CMDsCache[i]	
        CMDsTypeCacheIter = CMDsTypeCacheIter + 1	
	  else
		break
      end		
	end
  end   
  
  for i=CMDsCount-1, CMDsIter, -1  do
    if current_cmd_type == "all" or cmd_type_id[CMDsCache[i][1]] >= cmd_type_id[current_cmd_type] then
	  if CMDsTypeCacheIter < count then	    
         CMDsTypeCache[CMDsTypeCacheIter] = CMDsCache[i]
	     CMDsTypeCacheIter = CMDsTypeCacheIter + 1	
	  else
		 break
	  end
	end
  end
  return CMDsTypeCache, CMDsTypeCacheIter
end

return CMDsGpu