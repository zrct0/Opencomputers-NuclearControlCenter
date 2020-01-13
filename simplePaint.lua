local event = require("event")
local term = require("term")
local serialization = require("serialization")
local ithread = require("IThread")
local utils = require("IUtils")
local gpu = require("component").gpu

local w, h = gpu.getResolution()

function paintThread()
  while true do
    local _, screenAddress, x, y, button, playerName = event.pull("touch")     
	if button == 0 then	 
	  gpu.fill(x, y, 1, 1,"▇")
	else	  
	  gpu.fill(x, y, 1, 1," ")
	end
  end
end

function savePaint()
  gpu.set(1, h-2, "Start saving")
  local map = {}
	for y=1, h-1 do
	  map[y] = {}
	  for x=1, w-1 do
		local chr, _, _, _, _ = gpu.get(x, y)
		map[y][x] = chr == " " and 0 or 1
      end
	end
	local data = serialization.serialize(map)	 
	utils:writeFile(data,"paint_data")
	gpu.set(1, h-2, "Save successed")
end



function loadPaint()
  gpu.set(1, h-2, "Start loading")
   term.clear()
  if utils:fileExist("/home/paint_data") then
    local data = utils:readFile("/home/paint_data")
	if data ~= nil then
	  local map = serialization.unserialize(data)	 	
	  for y=1, #map-2 do	 
	    for x=1, #(map[1])-2 do	    
		  gpu.fill(x, y, 1, 1, map[y][x] == 1 and "▇" or " ")
        end
	  end	 
	  gpu.set(1, h-2, "Load successed")
	else
	  gpu.set(1, h-2, "Load successed :paint_data is empty")
    end
  else
    gpu.set(1, h-2, "ERROR: paint_data not exit")
  end  
end

function inputThread()
  while true do    
    local keyboardAddress, chr, code, playerName = event.pull("key_down")    
	if code == 115 then
	  savePaint()
	elseif code == 108 then
	  loadPaint()
	end
  end
end


gpu.setBackground(0x000000)
term.clear()
term.setCursor(1, h-1)
term.write("Use Key 's' to save, 'l' to load")
ithread:create(paintThread)
--ithread:create(inputThread)
inputThread()