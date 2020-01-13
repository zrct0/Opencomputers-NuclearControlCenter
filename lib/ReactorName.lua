local ReactorName = {}

local utils = require("IUtils")

ReactorName.name = ""

function ReactorName:adapte()
  if utils:fileExist("/home/reactor_name") then
    ReactorName.name = utils:readFile("reactor_name")
  else
    print("What this Reactor name is?")
	ReactorName.name = io.read()
	utils:writeFile(ReactorName.name, "reactor_name")
	utils:info("Create name file successed")
  end
end

return ReactorName