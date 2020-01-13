local IUtils = {}

local term = require("term")
local gpu = require("CMDsGpu") 
local filesystem = require("filesystem")


function IUtils:error(str)  
  IUtils:print("error", "]ERROR:"..str)
 end

function IUtils:warn(str)
  IUtils:print("warn", "]WARN:"..str)
end

function IUtils:info(str)
   IUtils:print("info", "]INFO:"..str)
end

function IUtils:init(str)
   IUtils:print("init", "]INIT:"..str)
end

function IUtils:debug(str)
   IUtils:print("debug", "]DEBUG:"..str)
end

function IUtils:print(cmd_type, str)
   gpu:writeCMDsCache(cmd_type, "["..os.date("%X")..str)
   gpu:printCMDsCache()
end

function IUtils:writeFile(data, fileName)
  local file = io.open(fileName, "w")
  file:write(data)
  file:close()
  IUtils:debug("Writed"..fileName)
end

function IUtils:readFile(fileName)
  local file = io.open(fileName, "r")
  str = ""
  for line in file:lines() do
    str = str..line
  end
  IUtils:debug("Readed"..fileName)
  return str
end

function IUtils:fileExist(fileName)
  return filesystem.exists(fileName)
end



return IUtils