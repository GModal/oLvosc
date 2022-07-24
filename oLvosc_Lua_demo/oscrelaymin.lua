local oLvosc = require "oLv/oLvosc"
local sudp, cli1, cli2

sudp = oLvosc.servSetup("*", 8000)
cli1 = oLvosc.cliSetup('224.0.0.1', 8001)
cli2 = oLvosc.cliSetup('224.0.0.1', 8002)
	
while 1 do
  local packet = oLvosc.oscPoll(sudp)
	if packet ~= nil then
		oLvosc.sendOSC(cli1, packet) 
    oLvosc.sendOSC(cli2, packet)
	end
end
