local oLvosc = require "oLv/oLvosc"
local sudp, cli1, cli2
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ(udp)
	local packet = oLvosc.oscPoll(udp)
	if packet ~= nil then
		oLvosc.sendOSC(cli1, packet) 
    oLvosc.sendOSC(cli2, packet)
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local port = 8000
local rports = {8001, 8002}
print('Listening on port: '..port..'    Relay to '..rports[1]..', '..rports[2]) 

sudp = oLvosc.servSetup("*", port)
cli1 = oLvosc.cliSetup('224.0.0.1', rports[1])
cli2 = oLvosc.cliSetup('224.0.0.1', rports[2])
	
while 1 do
	myServ(sudp)
end
