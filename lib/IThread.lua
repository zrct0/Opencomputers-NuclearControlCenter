local IThread = {}

local thread = require("thread")
local utils = require("IUtils")

IThread.threads = {}
IThread.threadsInfo = {}
IThread.counts = 0

IThread.isInitialize = false

function IThread:create(func, self_pointer, name)
  if not name then
    name = "unname"
  end
  utils:debug("create thread ["..name.."] ")  
  self.threads[self.counts] = thread.create(func, self_pointer)
  self.threadsInfo[self.counts] = {func, self_pointer, name}  
  self.counts = self.counts + 1

  if not self.isInitialize then
    self:initialize()
  end  
end

function IThread:killAllThread()
  for i=0, self.counts do
    (self.threads[i]):kill()
  end
end

function IThread:initialize()
  self.isInitialize = true
  self:create(self.threadMonitor, self, "IThread")
  --IThread:threadMonitor()  
end

function IThread:threadMonitor()
  while true do       
    utils:debug("Scan thread, count:"..self.counts)   
    for i=0, self.counts - 1 do
      local t = self.threads[i]	  
	  if t:status() == "dead" then
	    utils:error("thread ["..self.threadsInfo[i][3].."] "..t:status())       
	    self.threads[i] = thread.create(self.threadsInfo[i][1], self.threadsInfo[i][2])
	    utils:warn("restart thread ["..self.threadsInfo[i][3].."]")  	  
	  end      
    end
    os.sleep(5) 	
  end
end

return IThread