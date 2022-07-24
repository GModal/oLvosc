-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- "oLvosc" by Doug Garmon, 2022
-- MINI1MAL OSC packing/unpacking & send/receive implementation for lua/love2d
-- 	License: "The Unlicense"
-- 	For more information, please refer to <https://unlicense.org/>
do
-- KEEP this do
local oLvosc = {}

local socket = require "socket"
local mtab = {0, 3, 2, 1}

local function lpak(_, fmt, ttbl)
  return string.pack(fmt, ttbl)
end

-- function substitues so this module will work with love2d (>=11) and lua (>=5.3)
local oLvpk
if love ~= nil then
  oLvpk= {pack = love.data.pack, unpack = love.data.unpack}
else
  oLvpk= {pack = lpak, unpack = string.unpack}
end

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- osc private functions
local endpad = string.char(0, 0, 0, 0)
function oscString (Str)
local newS, mod
	newS = Str..string.char(0x0)
	mod = string.len(newS) % 4
return(newS..string.sub(endpad, 1, mtab[mod + 1]))
end

function oscType (Str)
return(oscString(','..Str))
end

function oscSymbol (Str)
local s1, _ = string.find(Str, " ")
return(oscString(string.sub(Str, 1, s1)))
end

function oLvosc.sleep(tm)
    socket.sleep(tm)
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- some utility functions
-- pack MIDI data for send
function oLvosc.packMIDI(mChan, mStatus, mByte1, mByte2)
  local mPack 
  mPack = oLvpk.pack('string','BBBB', mChan, mStatus, mByte1, mByte2)
  return mPack
end

-- unpack MIDI data 
function oLvosc.unpackMIDI(mPack)
  local mChan, mStatus, mByte1, mByte2 = oLvpk.unpack('BBBB', mPack)
  return mChan, mStatus, mByte1, mByte2
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- osc client functions START
-- init Client
function oLvosc.cliSetup(caddr, cport)
	local cudp = socket.udp()
  if cudp ~= nil then
    cudp:settimeout(0)
    -- the address and port of the client
    cudp:setpeername(caddr, cport)
  end
  return cudp
end
-- send OSC message
function oLvosc.sendOSC(cudp, pack)
	if cudp ~= nil then
		cudp:send(pack)
	end
end

-- Creates an OSC packet
-- currently accepts the following types (NOTE: some 1.0 types have collisions with newly defined types- 'F','I'):
-- s  string
-- S  alt string
-- f  float (32-bit)
-- i  int (32-bit)
-- h  signed int (64-bit)
-- H  unsigned int (64-bit)
-- d  double float (64-bit)
-- m  MIDI: 32 bit # -- midi channel, Status byte (msg type), data1, data2

--        The following have no data block
-- N  NIL
-- T  TRUE
-- F  FALSE
-- I  Infinitum
function oLvosc.oscPacket (addrS, typeS, msgTab)
local strl, types

if  typeS == nil then
  strl = oscString(addrS)..oscType('') -- no type & no data...EMPTY type block included in msg (comma and three zeros)
else
	strl = oscString(addrS)..oscType(typeS)
  
    if msgTab ~= nil then -- add data if type has arguments...some do not
    for argC = 1, #msgTab do
      types = string.sub(typeS, argC, argC)
        if types == 's' then 
          strl = strl..oscString(msgTab[argC])
        elseif types == 'S' then
          strl = strl..oscSymbol(msgTab[argC])
        elseif types == 'f' then
          strl = strl..oLvpk.pack('string', '>f', msgTab[argC])
        elseif types == 'i' then
          strl = strl..oLvpk.pack('string', '>i', msgTab[argC])
        elseif types == 'h' then
          strl = strl..oLvpk.pack('string', '>i8', msgTab[argC])
        elseif types == 'H' then
          strl = strl..oLvpk.pack('string', '>I8', msgTab[argC])
        elseif types == 'd' then
          strl = strl..oLvpk.pack('string', '>d', msgTab[argC])
        elseif types == 'm' then
          strl = strl..oLvpk.pack('string', 'c4', msgTab[argC])
        elseif types == 'N' or types == 'T' or types == 'F' or types == 'I' then
        end
      end
    end
  end
return(strl)
end
-- osc client functions END
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- osc server functions START
-- start a server on port
function oLvosc.servSetup(raddr, rport)
	local rudp = socket.udp()
	-- Don't block, setting the 'timeout' to zero
  if rudp ~= nil then
    rudp:settimeout(0)
    rudp:setsockname(raddr, rport)
  end
  return(rudp)
end
-- poll the receiving UDP port (nonblocking)
function oLvosc.oscPoll(rudp)
local data = nil
local msg_or_ip, port_or_nil
  if rudp ~= nil then
    data, msg_or_ip, port_or_nil = rudp:receivefrom()
    if data == nil then
      if msg_or_ip ~= 'timeout' then
        error("Unknown network error: "..tostring(msg_or_ip))
      end
    end
  end
return data
end
-- close the socket, client or server
function oLvosc.close(udp)
  if udp ~= nil then
    udp:close()
  end
end
-- unpack UDP OSC msg packet into:
--	oscAddr = oA
--	oscType = oT
--	oscData = oD
-- **************************
function oLvosc.oscUnpack(udpM)
local oA ,oT, oD
	oA = udpM:match("^[%p%w]+%z+")
  oT = udpM:match(",%a+")
  if oA ~= nil then
    local aBlk = #oA 
    oA = oA:gsub('%z', '')
    if oT ~= nil then
      local dataBlk = aBlk + (math.floor((#oT)/4) + 1) * 4
      oD = string.sub(udpM, dataBlk + 1)
      oT = oT:match('[^,]+')
    end
  end
  return oA, oT, oD
end
-- returns the last text portion of the addr, after the last /
function oLvosc.oscAddrCmd(addr)
  return addr:match('[^/]+$')
end
-- returns the components of an address
function oLvosc.oscAddrSplit(addr)
  local splt = {}
    for x in addr:gmatch('([^/]+)') do
      table.insert(splt, x)
    end
  return splt
end
-- unpack OSC data block
-- currently unpacks the following types (some are liblo extended):
-- s  string
-- S  alt string
-- i  int (32-bit)
-- I  unsigned int (32-bit) -- we SEND an 'Infinitum', but RECEIVE an 'unsigned INT'... thanks Ardour :-)
-- m  MIDI data, four bytes: channel, status, d1, d2
-- f  float (32-bit)
-- h  signed int (64-bit)
-- H  unsigned int (64-bit)   -- There are ISSUES with 64 bit Ints in Love 11.3, this might not work as expected
-- d  double float (64-bit)
function oLvosc.oscDataUnpack(oT, oD)
local tc, iv, nx, zloc
local dTbl = {}
  if oT ~= nil then
    for i = 1, #oT do
      tc = oT:sub(i,i)
      if tc == 'f' then
        iv, nx = oLvpk.unpack(">f", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 's' or tc == 'S' then
        zloc, nx = string.find(oD, '\0')
        local tmpS = string.sub(oD, 1, zloc - 1)
        iv = string.format("%s", tmpS)
        nx = zloc + mtab[zloc % 4 + 1]
        oD = string.sub(oD, nx + 1)
        table.insert(dTbl, tostring(iv))
      elseif tc == 'i' then
        iv, nx = oLvpk.unpack(">i", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'I' then
        iv, nx = oLvpk.unpack(">I", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'm' then
        iv, nx = oLvpk.unpack("c4", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, iv)
      elseif tc == 'h' then
        iv, nx = oLvpk.unpack(">i8", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'H' then
        iv, nx = oLvpk.unpack(">I8", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'd' then
        iv, nx = oLvpk.unpack(">d", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, tonumber(iv))
      end
    end
  end
	return dTbl
end
-- osc/udp server functions END.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
return oLvosc
-- KEEP this end
end