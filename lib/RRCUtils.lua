local RRCUtils = {}

local utils = require("IUtils")

function RRCUtils:error(str)  
  utils:print("error", "][RRC SYSTEM]ERROR:"..str)
 end

function RRCUtils:warn(str)
  utils:print("warn", "][RRC SYSTEM]WARN:"..str)
end

function RRCUtils:info(str)
   utils:print("info", "][RRC SYSTEM]INFO:"..str)
end

function RRCUtils:init(str)
   utils:print("init", "][RRC SYSTEM]INIT:"..str)
end

function RRCUtils:debug(str)
   utils:print("debug", "][RRC SYSTEM]DEBUG:"..str)
end

function RRCUtils:print(info, str, RLMName)
   utils:print(info, "]["..RLMName.."]DEBUG:"..str)
end

return RRCUtils