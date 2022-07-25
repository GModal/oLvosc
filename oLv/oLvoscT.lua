-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- "oLvoscT" by Doug Garmon, 2022
-- OSC threaded (blocking) server, for LÖVE
-- MIT License
-- Copyright (c) 2022 Doug Garmon
do
-- KEEP this do
local oLvoscT = {}
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
-- check error status
function oLvoscT.error(threadT)
    if threadT ~= nill then
      local error = threadT:getError()
      assert( not error, error )
    end
end
-- return the channel of the thread terminator
function oLvoscT.getTermChan(nm)
  return love.thread.getChannel(nm..'_x')
end
-- send the server thread a msg (literally anything) to kill the thread
function oLvoscT.closeServ(chan)
  chan:push('buhbye')
end
-- osc server functions START
-- start a server on port
function oLvoscT.servSetup(raddr, rport, nm, tO)
    if tO == nil then tO = 1.5 end  -- set timeout, 1.5 def
    local rthread = love.thread.newThread(oLvoscT.oscServT)
    rthread:start( raddr, rport, nm, tO)
  return rthread
end
-- open & poll the receiving UDP port (threaded, blocking)
oLvoscT.oscServT = [[
local socket = require "socket"
local ad, pt, nm, tO = ...
local data, r1
local chn = love.thread.getChannel(nm)
local xchn = love.thread.getChannel(nm..'_x')
local sudp = socket.udp()
if sudp ~= nil then
sudp:settimeout(tO)
sudp:setsockname(ad, pt)
  while (xchn:getCount() == 0) do
    data, r1, _ = sudp:receivefrom()
    if data ~= nil then
      chn:push(data)
    else
      if r1 ~= 'timeout' then error("Unknown network error") end      
    end
  end
sudp:close()
end
]]
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
return oLvoscT
-- KEEP this end
end