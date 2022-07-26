local oLvosc = require "oLv/oLvosc"
local cli
local val = 0
-- +++++++++++++++++++++++++++++++++++++++++++++++++++

-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local port = 8000
print('sending to port: '..port) 

cli = oLvosc.cliSetup('224.0.0.1', port)
	
while 1 do
  oLvosc.sleep(1)
  local packet = oLvosc.oscPacket('/myOSC/ping', 'i', { val } )
  val = val + 1
	oLvosc.sendOSC(cli, packet) 
  
  local t1, t2, t3 = oLvosc.time()
  
  print('time: npt sec '..t1..' frac '..t2..' epoch '..t3)
end
