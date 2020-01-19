local RRMGpu = {}

local component = require("component")
local term = require("term")
local text = require("text")
local serialization = require("serialization")
local CMDsGpu = require("CMDsGpu")
local utils = require("IUtils")


local mainGpu = nil
local secondaryGpu = nil
local w, h = 0, 0

RRMGpu.mainGpu = nil
RRMGpu.mainScreen = nil

function RRMGpu:adapte()
  utils:init("Start RRMGpu Adapte")
  local components = component.list()
  local screens, gpus = {}, {}
  local screensCount, gpusCount = 0, 0  
  for address, name in pairs(components) do
    if name == "screen" then	  
	  utils:init(">Find #",screensCount," Screen:", address)
	  screens[screensCount] = component.proxy(address)
	  screensCount = screensCount + 1
	elseif name == "gpu" then
	  utils:init(">Find #",gpusCount," Gpu:", address)
	  gpus[gpusCount] = component.proxy(address)
	  gpusCount = gpusCount + 1
	end
  end
  if screensCount < 2 or gpusCount < 2 then
    utils:init("Use 1 Gpus to display")
	mainGpu = component.gpu	
	self.mainScreen = component.screen
	mainGpu.setResolution(100, 37) 
	w, h = mainGpu.getResolution()
	CMDsGpu:initialize(mainGpu)	
	CMDsGpu:setPrintPosition(h-7, h)
	RRMGpu.mainGpu = mainGpu
	utils:init("RRMGpu adapte finished")
	return mainGpu, w, h
  else
    utils:init("Use 2 Gpus to display")
    local g0w, g0h = gpus[0].getResolution()
	local g1w, g1h = gpus[1].getResolution()
    if (g0w * g0h) > (g1w * g1h) then
	  mainGpu = gpus[0]	
	  secondaryGpu = gpus[1]
	else
	  mainGpu = gpus[1]
	  secondaryGpu = gpus[0]
	end 
    local s0w, s0h = screens[0].getAspectRatio()
	local s1w, s1h = screens[1].getAspectRatio()
	if s0w * s0h > s1w * s1h then
	  utils:init("MainGpu", mainGpu.address ," Bind to ", screens[0].address, "(", mainGpu.bind(screens[0].address))
	  utils:init("secondaryGpu(", secondaryGpu.address ,") Bind to Screen(", screens[1].address, "):", secondaryGpu.bind(screens[1].address))
	  RRMGpu.mainScreen = screens[0]
	else
	  utils:init("MainGpu", mainGpu.address ," Bind to ", screens[1].address, "(", mainGpu.bind(screens[1].address), ")")
	  utils:init("secondaryGpu(", secondaryGpu.address ,") Bind to Screen(", screens[0].address, "):", secondaryGpu.bind(screens[0].address))
	  RRMGpu.mainScreen = screens[1]
	end	  
  os.sleep(1)
  mainGpu.setResolution(100, 30) 
  --secondaryGpu.setResolution(60, 15)  
  w, h = mainGpu.getResolution()
  RRMGpu.mainGpu = mainGpu
  term.bind(secondaryGpu)
  CMDsGpu.initialize(secondaryGpu)
  utils:init("RRMGpu adapte finished")
  return mainGpu, w, h
  end  
end

function RRMGpu:DrawBox(_x, _y ,_w, _h, chr, color)
  mainGpu.setForeground(0xFFFFFF)
  mainGpu.setBackground(color)
  mainGpu.fill(_x, _y, _w, _h, chr)
end 

function RRMGpu:drawPaint(fileName, sx, sy, color, gpu)
  if gpu == nil then
    gpu = self.mainGpu
  end
  local oldColor = gpu.getBackground()
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
  gpu.setBackground(oldColor)
end

function RRMGpu:print(x, y, str, color, padRight, gpu) 
  if gpu == nil then
    gpu = self.mainGpu
  end
  if color == nil or gpu.getDepth() < 4 then
    color = 0xFFFFFF
  end
  if padRight == nil then
    padRight = w
  end
  gpu.setForeground(color)  
  gpu.set(x, y, text.padRight(str, padRight))
  gpu.setForeground(0xFFFFFF)
end

function RRMGpu:clear()
  local w, h = mainGpu.getResolution()
  mainGpu.fill(1, 1, w, h, " ")
end

return RRMGpu