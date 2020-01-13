local RRCGpu = {}

local serialization = require("serialization")
local utils = require("IUtils")
local gpu = require("component").gpu


function RRCGpu:DrawBox(_x, _y ,_w, _h, chr, color)
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(color)
  gpu.fill(_x, _y, _w, _h, chr)
end 

function RRCGpu:drawPaint(fileName, sx, sy, color)  
  gpu.setBackground(color)
  local data = utils:readFile(fileName)	
  local map = serialization.unserialize(data)	 	
  for y=1, #map-2 do	 
    for x=1, #(map[1])-2 do	
      if map[y][x] == 1 then		
	    gpu.fill(sx + x, sy + y, 1, 1, " ")
      end
    end	
  end  
end

function RRCGpu:clear()
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

return RRCGpu