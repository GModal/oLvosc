-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- "oLvosc" by Doug Garmon, 2022
-- MINI1MAL OSC packing/unpacking & send/receive implementation for lua/love2d
-- MIT License
-- Copyright (c) 2022 Doug Garmon
do
-- KEEP this do
local oLvosc = {}

local socket = require "socket"
local utf8 = require("utf8")
local mtab = {0, 3, 2, 1}

local function lpak(_, ...)
  return string.pack(...)
end

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
	local newS = Str..string.char(0x0)
	local mod = string.len(newS) % 4
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

function align4(n)
  return (math.floor((n-1)/4) + 1) * 4
end

function padBin(binD)
  local nwD = binD
  for i=1, align4(#binD)-#binD do nwD = nwD..string.char(0) end
  return nwD
end

-- returns int secs, int fraction, float fraction, epoch time
function oLvosc.time()
  local tm = socket.gettime()
  local i,f  = math.modf(tm + 2208988800)
    return i, math.floor(f * 2147483647), f, tm
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- some utility functions
-- pack MIDI data for send
function oLvosc.packMIDI(mChan, mStatus, mByte1, mByte2) 
  local mPack = oLvpk.pack('string','BBBB', mChan, mStatus, mByte1, mByte2)
  return mPack
end

-- unpack MIDI data 
function oLvosc.unpackMIDI(mPack)
  local mChan, mStatus, mByte1, mByte2 = oLvpk.unpack('BBBB', mPack)
  return mChan, mStatus, mByte1, mByte2
end

function oLvosc.packTIME(tsec, tfrac)
  local tpk = oLvpk.pack('string','II', tsec, tfrac)
  return tpk
end

function oLvosc.unpackTIME(tPack)
  local tsec, tfrac = oLvpk.unpack('II', tPack)
  return tsec, tfrac
end

function oLvosc.unpackBLOB(bPack)
  iv, nx = oLvpk.unpack(">i", bPack)
  return iv, string.sub(bPack, 5, iv + 4)
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
-- currently accepts the following types:
-- s  string
-- S  alt string
-- c  a char (32 bit int)
-- i  int (32-bit)
-- m  MIDI data, four bytes: channel, status, d1, d2
-- t  TIME data, two 32 ints: seconds, fraction of seconds
-- f  float (32-bit)
-- b  BLOB data, binary bytes
-- h  signed int (64-bit)
-- d  double float (64-bit)
--        The following have NO data block (but are DEcoded to a string: 'NIL', 'TRUE', etc...
-- N  NIL
-- T  TRUE
-- F  FALSE
-- I  Infinitum
-- [  Array begin
-- ]  Array end
function oLvosc.oscPacket (addrS, typeS, msgTab)
local strl, types --, tBlb

if  typeS == nil then
  strl = oscString(addrS)..oscType('') -- no type & no data...EMPTY type block included in msg (comma and three zeros)
else
	strl = oscString(addrS)..oscType(typeS)
  
    if msgTab ~= nil then -- add data if type has arguments...some do not
    for argC = 1, #msgTab do
      types = string.sub(typeS, argC, argC)
        if types == 's' or types == 'S' then 
          strl = strl..oscString(msgTab[argC])
        elseif types == 'f' then
          strl = strl..oLvpk.pack('string', '>f', msgTab[argC])
        elseif types == 'i' then
          strl = strl..oLvpk.pack('string', '>i', msgTab[argC])
        elseif types == 'b' then 
          local tBlb = padBin(msgTab[argC])
          strl = strl..oLvpk.pack('string', '>i', #msgTab[argC])..tBlb
        elseif types == 'h' then
          strl = strl..oLvpk.pack('string', '>i8', msgTab[argC])
        elseif types == 'd' then
          strl = strl..oLvpk.pack('string', '>d', msgTab[argC])
        elseif types == 'c' then
          strl = strl..oLvpk.pack('string', '>I', tostring( utf8.codepoint(msgTab[argC])))
        elseif types == 'm' then
          strl = strl..oLvpk.pack('string', 'c4', msgTab[argC])
        elseif types == 't' then
          strl = strl..oLvpk.pack('string', 'c8', msgTab[argC])
        elseif types == 'N' or types == 'T' or types == 'F' or types == 'I' or types == string.char(91) or types == string.char(93) then
          -- no data
        else
          return (nil)  -- unknown type
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
--check if packet is a bundle
function oLvosc.isBundle(udpM)
  local b = udpM:match("^#bundle")
  return b ~= nil
end
-- parse multiple messages as a table of unpacked messages via oLvosc.oscUnpack
-- {{oscADDR, oscTYPE, oscDATA}, {oscADDR, oscTYPE, oscDATA}, ...}
function oLvosc.oscUnpackBundle(udpM)
  local mpos = 17 -- skip '#bundle+timestamp'
  local packed_messages = udpM
  local num_bytes = string.len(packed_messages)
  -- bundle message pattern: size(4byte) followed by regular message
  local parsed_messages = {}
  while mpos < num_bytes do
    local packet_size = oLvpk.unpack(">i", packed_messages:sub(mpos, mpos + 4))
    local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packed_messages:sub(mpos + 4, mpos + 4 + packet_size))
    table.insert(parsed_messages, {oscADDR, oscTYPE, oscDATA})
    mpos = mpos + 4 + packet_size
  end
  return parsed_messages
end
-- unpack UDP OSC msg packet into:
--	oscAddr = oA
--	oscType = oT
--	oscData = oD
-- **************************
function oLvosc.oscUnpack(udpM)
local oA ,oT, oD
  
	oA = udpM:match("^[%p%w]+%z+")
  oT = udpM:match(',[%a%[+%]+]+')
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
-- currently unpacks the following types:
-- s  string
-- S  alt string
-- c  a char (but 32 bit int)
-- i  int (32-bit)
-- m  MIDI data, four bytes: channel, status, d1, d2
-- t  TIME data, two 32 ints: seconds, fraction of seconds
-- f  float (32-bit)
-- b  BLOB data, binary bytes
-- h  signed int (64-bit)
-- d  double float (64-bit)
--        These have no data block; a string ID is inserted in unpack table:
-- N  'NIL'
-- T  'TRUE'
-- F  'FALSE'
-- I  'INFINITUM'
-- [  'ARRAY_BEGIN'
-- ]  'ARRAY_END'
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
      elseif tc == 'b' then
        iv, nx = oLvpk.unpack(">i", oD)
        local blb = string.sub(oD, 1, iv + nx)  
        oD = string.sub(oD, align4(iv -1) + nx)
        table.insert(dTbl, blb)
      elseif tc == 'i' or tc == 'r' then
        iv, nx = oLvpk.unpack(">i", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'c' then
        iv, nx = oLvpk.unpack(">i", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, utf8.char(iv))
      elseif tc == 'm' then
        iv, nx = oLvpk.unpack("c4", oD)
        oD = string.sub(oD, 5)
        table.insert(dTbl, iv)
      elseif tc == 't' then
        iv, nx = oLvpk.unpack("c8", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, iv)
      elseif tc == 'h' then
        iv, nx = oLvpk.unpack(">i8", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'd' then
        iv, nx = oLvpk.unpack(">d", oD)
        oD = string.sub(oD, 9)
        table.insert(dTbl, tonumber(iv))
      elseif tc == 'I' then
        table.insert(dTbl, 'INFINITUM')
      elseif tc == 'T' then
        table.insert(dTbl, 'TRUE')
      elseif tc == 'F' then
        table.insert(dTbl, 'FALSE')
      elseif tc == 'N' then
        table.insert(dTbl, 'NIL')
      elseif tc == string.char(91) then
        table.insert(dTbl, 'ARRAY_BEGIN')
      elseif tc == string.char(93) then
        table.insert(dTbl, 'ARRAY_END')
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