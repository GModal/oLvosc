local oLvosc = require "oLv/oLvosc"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ(udp)
	local packet = oLvosc.oscPoll(udp)
	if packet ~= nil then
    local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
    local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
      
    -- simple print of all incoming data to console
    print(oscADDR, oscTYPE)
    if dataT ~= nil then
      for i, v in ipairs(dataT) do
        local tc = oscTYPE:sub(i,i)
        print('  '..i..')', tc, v)
        if tc == 'm' then
          print ('      MIDI: ', oLvosc.unpackMIDI(v))
        end
      end
    end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- OSC receive (server), listen to all
local sudp

local port = 3819
if arg[1] ~= nil then
  port = arg[1]
end
sudp = oLvosc.servSetup("*", port)
print('Listening on port: '..port)
	
while 1 do
  oLvosc.sleep(0.033)
	myServ(sudp)
end
