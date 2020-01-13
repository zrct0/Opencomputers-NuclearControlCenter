local CMDsGpu = require("CMDsGpu")
local RRCScreen = require("RRCScreen")
local RRCCommad = require("RRCCommad")
local term = require("term")

term.clear()
print("==========================================")
print("=           Welcome Use RRC OS           =")
print("=         Reactor Remote Commad          =")
print("==========================================")

CMDsGpu:initialize()
RRCCommad:initialize()
RRCScreen:initialize()
