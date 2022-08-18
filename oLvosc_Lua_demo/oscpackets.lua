local oLvosc = require "oLv/oLvosc"
local sudp

function align4(n)
  return (math.floor((n)/4) + 1) * 4
end

function oscDumpBin(udpM)
  local padtab = {4, 3, 2, 1}
  local wd = 12
  local oA, oT, oD, cnt
  local addrBlk, typeBlk, dataBlk, dataBlkLoc = 0, 0, 0, 0
  local bd, bpc = '', ''
  local bc = '\27[37m'
  local curcol = '\27[37m'
  
  oA, oT, oD = oLvosc.oscUnpack(udpM)
  addrBlk = align4(#oA)
  
  if oT ~= nil then
    typeBlk = align4(#oT+1)
    dataBlkLoc = addrBlk + typeBlk
    dataBlk = #udpM - dataBlkLoc
  end
  
  io.write('\27[37m')
  print('_____________________Info______________________')
  print('   Address:\t'..oA)
  print('     Types:\t'..oT)
  print('ADDR bkSz','TYPE bkSz','DATA bkSz','DATA blk @')
  print(addrBlk..'     \t\t'..typeBlk..'     \t\t'..dataBlk..'     \t\t'..dataBlkLoc)
  
  if dataBlkLoc > 0 then
    print('_____________________Data______________________')
    
    oD = string.sub(udpM, dataBlkLoc + 1)
    local ptab = oLvosc.oscDataUnpack(oT, oD)
    for i, v in ipairs(ptab) do
      local tc = oT:sub(i,i)
      if string.find('sScifdhINTF[]', tc, 1 , true) then
        print('    '..i..')', tc, v)
      elseif tc == 'm' then
        print('    '..i..')', tc,  'MIDI:', oLvosc.unpackMIDI(v))
      elseif tc == 't' then
        print('    '..i..')', tc,  'TIME:', oLvosc.unpackTIME(v))
      elseif tc == 'b' then
        local bls, _ = oLvosc.unpackBLOB(v)
        print('    '..i..')', tc,  'BLOB (sz):', bls)
      end
    end
  end
  print()
  
  print('___________________________________')
  print('______________Packet_______________')
  
  for i = 1, #udpM do
    local d1, d2 = string.unpack('B', udpM, i) -- get a single char
    
    bd = bd..string.format("%X\t",d1)
    bcp = string.format("%c",d1)
     if i > dataBlkLoc then
      bcp, _ = string.gsub(bcp, '[%c]', '.')  -- replace all cntl chars in data blk
    end   
    bc = bc..bcp..'\t'
    
    if i == dataBlkLoc then  -- start of data
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
  
  if cnt ~= 0 then
    print('\n')
  end

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
