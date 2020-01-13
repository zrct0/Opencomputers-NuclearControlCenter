local IComponent = {}

local cp = require("component")
local event = require("event")
local utils = require("IUtils")


function IComponent:component_available(componentType)
  utils.info(_, componentType.. "  Connected" )
  self:setComponentValue(componentType, true)
end

function IComponent:component_unavailable(componentType)
  utils.IUtils.error(_, componentType.. " Disconnected" )
    self:setComponentValue(componentType, false)
end

function IComponent:adapte()
  utils:init("Start Adapte Component")
  event.listen("component_available", IComponent.component_available)
  event.listen("component_unavailable", IComponent.component_unavailable)
end

function IComponent:invoke(name, func, falseInfo, falseValue, falseError)
  if cp.isAvailable(name) then  
    local result = cp.getPrimary(name)
	if func then	    
	  result = cp.invoke(result.address, func)     	
    end	
	return result
  elseif falseError then
    error(falseError)
  elseif falseInfo then   
    utils:error(falseInfo)	
  else  
    return falseValue
  end
end

return IComponent