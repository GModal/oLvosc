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
  local isec, ifrac, ffrac, epoch = oLvosc.time()
  local mytime = oLvosc.packTIME(isec, ifrac)
  
  local packet = oLvosc.oscPacket('/myOSC/ping', 'it', { val, mytime } )
  val = val + 1
	oLvosc.sendOSC(cli, packet) 
end


--local mytime = oLvosc.packTIME(isec, ifrac)
--print (oLvosc.unpackTIME(mytime))