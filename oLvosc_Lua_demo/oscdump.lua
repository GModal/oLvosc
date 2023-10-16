local oLvosc = require "oLv/oLvosc"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++

--helper print function
local function print_data(oscTYPE, dataT)
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

-- poll the OSC server 
function myServ(udp)
	local packet = oLvosc.oscPoll(udp)
	if packet == nil then return end

  if oLvosc.isBundle(packet) then -- handle bundled messages
    local msgs = oLvosc.oscUnpackBundle(packet)
    -- simple print of all incoming data to console
    for i, m in ipairs(msgs) do
      local oscADDR, oscTYPE, oscDATA = table.unpack(m)
      local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
      print(oscADDR, oscTYPE)
      print_data(oscTYPE, dataT)
    end
  else  --handle a single message
    local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
    local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
    print(oscADDR, oscTYPE)
    print_data(oscTYPE, dataT)
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
