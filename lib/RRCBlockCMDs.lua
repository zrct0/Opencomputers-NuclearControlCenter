local RRCBlockCMDs = {}

local computer = require("computer")
local text = require("text")
local utils = require("IUtils")

local cmd_type_id = {["all"] = -1, ["debug"] = 0, ["init"] = 1, ["info"] = 2, ["warn"] = 3, ["error"] = 4}
local cmd_type_color = {["debug"] = 0xFFFFFF, ["init"] = 0xFF00FF, ["info"] = 0x0000FF, ["warn"] = 0xFFFF00, ["error"] = 0xFF0000}
local gpu

RRCBlockCMDs.CMDsCache = {}
RRCBlockCMDs.CMDsCount = 0
RRCBlockCMDs.CMDsIter = 0
RRCBlockCMDs.MAX_CMDs_COUNT = 20
RRCBlockCMDs.x = 0
RRCBlockCMDs.y = 0
RRCBlockCMDs.w = 0
RRCBlockCMDs.h = 0
RRCBlockCMDs.MAIN_INFO_HEIGHT = 0
RRCBlockCMDs.CMDs_INFO_HEIGHT = 0
RRCBlockCMDs.CMDPOS_BOTTOM = 0
RRCBlockCMDs.isInitialize = false
RRCBlockCMDs.current_cmd_type = "init"

function RRCBlockCMDs:new(_x, _y ,_w ,_h, _gpu)
  t = {}
  setmetatable(t, self)
  self.__index = self
  t:initialize(_x, _y ,_w ,_h, _gpu)
  return t
end

function RRCBlockCMDs:initialize(_x, _y ,_w ,_h, _gpu)
  if not _gpu then 
    _gpu = require("component").gpu
  end   
  gpu = _gpu
  self.x, self.y, self.w, self.h = _x + 6 , _y , _w - 7 , _h - 1
  self.MAIN_INFO_HEIGHT = self.y
  self.CMDs_INFO_HEIGHT = self.h
  self.CMDPOS_BOTTOM = self.y + self.h
  local totalMemory = computer.freeMemory() 
  local Memory_1T = 19300
  if totalMemory > Memory_1T * 2 then
    self.MAX_CMDs_COUNT = 30
  end
  if totalMemory > Memory_1T * 3 then
    self.MAX_CMDs_COUNT = 60
  end
  if totalMemory > Memory_1T * 4 then
    self.MAX_CMDs_COUNT = 100
  end  
  isInitialize = true
  return self
end

function RRCBlockCMDs:writeCMDsCache(cmd_type, cmd)
  local cache = {cmd_type, cmd}
  self.CMDsCache[self.CMDsIter] = cache
  self.CMDsIter = self.CMDsIter + 1
  if self.CMDsIter >= self.MAX_CMDs_COUNT then
    self.CMDsIter = 0
  end 
  if self.CMDsCount < self.MAX_CMDs_COUNT then
    self.CMDsCount = self.CMDsCount + 1
  end 
end

function RRCBlockCMDs:fill(x, y, w, h, chr, color)

  if color == nil or gpu.getDepth() < 4 then
    color = 0xFFFFFF
  end
  gpu.setForeground(color)
  gpu.setBackground(0x000000)
  gpu.fill(x, y, w, h ,chr)
  gpu.setForeground(0xFFFFFF)
end

function RRCBlockCMDs:printCMDsCache(bgColor)
  
  local CMDsTypeCache, CMDsTypeCacheCount = self:getCMDsCache(self.CMDs_INFO_HEIGHT)
  local lastLine = math.min(self.CMDs_INFO_HEIGHT, CMDsTypeCacheCount - 1)
  local line = self.CMDPOS_BOTTOM  
  for i=0, lastLine do
    gpu.setForeground(self:getCMDColor(CMDsTypeCache[i][1]))
    gpu.setBackground(bgColor)
    gpu.set(self.x, line, text.padRight(CMDsTypeCache[i][2], self.w))
    line = line - 1
  end 
  gpu.setForeground(0xFFFFFF)

end

function RRCBlockCMDs:getCMDColor(cmd_type)
  if gpu.getDepth() >= 4 then
    return cmd_type_color[cmd_type]
  else
    return 0xFFFFFF
  end
end

function RRCBlockCMDs:setCmdType(cmd_type)  
  if cmd_type_id[cmd_type] ~= nil then
    gpu.fill(1, MAIN_INFO_HEIGHT, w, h, " ")   
	self:writeCMDsCache("info", "["..os.date("%X").."]INFO:"..str)
    self:printCMDsCache()   
    self.current_cmd_type = cmd_type
	return true
  end
  return false
end

function RRCBlockCMDs:getCMDsCache(count)
  local CMDsTypeCache = {}
  local CMDsTypeCacheIter = 0
  for i=self.CMDsIter-1, 0, -1 do 
    if current_cmd_type == "all" or cmd_type_id[self.CMDsCache[i][1]] >= cmd_type_id[self.current_cmd_type] then
	  if CMDsTypeCacheIter < count then
        CMDsTypeCache[CMDsTypeCacheIter] = self.CMDsCache[i]	
        CMDsTypeCacheIter = CMDsTypeCacheIter + 1	
	  else
		break
      end		
	end
  end   
  
  for i=self.CMDsCount-1, self.CMDsIter, -1  do
    if current_cmd_type == "all" or cmd_type_id[CMDsCache[i][1]] >= cmd_type_id[current_cmd_type] then
	  if CMDsTypeCacheIter < count then	    
         CMDsTypeCache[CMDsTypeCacheIter] = self.CMDsCache[i]
	     CMDsTypeCacheIter = CMDsTypeCacheIter + 1	
	  else
		 break
	  end
	end
  end
  return CMDsTypeCache, CMDsTypeCacheIter
end

return RRCBlockCMDs