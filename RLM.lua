local IComponent = require("IComponent")
local reactorLocalCommad = require("ReactorLocalCommad")
local reactorControl = require("ReactorControl")
local CMDsGpu = require("CMDsGpu")

require("term").clear()
print("==========================================")
print("=           Welcome Use RLM OS           =")
print("=        Reactor Location Monitor        =")
print("==========================================")

function reactorLogic(rs, heat)
  if heat > 5000 then
    reactorControl:stop()
  elseif heat > 2000 then
    reactorControl:remap()
  end
end

CMDsGpu:initialize()
IComponent:adapte()
reactorLocalCommad:initialize()
reactorControl:initialize(reactorLogic)





