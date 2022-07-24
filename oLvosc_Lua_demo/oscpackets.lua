local oLvosc = require "oLv/oLvosc"
local sudp

function oscDumpBin(udpM)
  local padtab = {4, 3, 2, 1}
  local wd = 12
  local oA, oT, oD, cnt
  local typePad = 0
  local typeBlk = 0
  local dataBlk = 0
  local bd = ''
  local bc = '\27[37m'
  local curcol = '\27[37m'
  io.write('\27[37m')
  
  oA = udpM:match("^[%p%w]+")
  oT = udpM:match(",%a+")
  local addrPad = padtab[#oA % 4 + 1]
  local addrBlk = #oA + addrPad
  if oT ~= nil then
    typePad = padtab[#oT % 4 + 1]  
    typeBlk = #oT + typePad
    dataBlk = addrBlk + typeBlk
  end
  print('___________________________________')
  print('______________Packet_______________')
  
  for i = 1, #udpM do
    local d1, d2 = string.unpack('B', udpM, i)
    bd = bd..string.format("%X\t",d1)
    bc = bc..string.format("%c\t",d1)
    
    if i == dataBlk then  -- start of data
      bd = bd..'\27[36m'
      curcol = '\27[36m'
    end
    if i == addrBlk then  -- end of ADDR is start of TYPE
      bd = bd..'\27[32m'
      curcol = '\27[32m'
    end
    
    if i % wd == 0 then
      print(bd)
      print(bc)
      print()
      bd = curcol
      bc = '\27[37m' 
    end
    cnt = i % wd
  end
  
  print(bd)
  print(bc)

  io.write('\27[37m')
  if cnt ~= 0 then
    print('\n\n')
  end
  print('_____________________Info______________________')
  print('Addr bkSz:'..addrBlk, 'Type bkSz:'..typeBlk, 'Data blk @:'..dataBlk)
  
  if dataBlk > 0 then
    print('_____________________Data______________________')
    
    oD = string.sub(udpM, dataBlk + 1)
    local ptab = oLvosc.oscDataUnpack(oT, oD)
    for i, v in ipairs(ptab) do
      local tc = oT:sub(i+1,i+1)
      print('    '..i..')', tc, v)
      if tc == 'm' then
        print ('      MIDI: ', oLvosc.unpackMIDI(v))
      end
    end
  end
  print()
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ()
	local packet = oLvosc.oscPoll(sudp)
	if packet ~= nil then
    oscDumpBin(packet)
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++

-- and OSC receive (server)
local port = 3819
if arg[1] ~= nil then
  port = arg[1]
end
sudp = oLvosc.servSetup("*", port)
print('Looks best if tabs are set with: tabs 3')
print('Listening on port: '..port)
	
  
while 1 do
  oLvosc.sleep(0.025)
	myServ()
end
