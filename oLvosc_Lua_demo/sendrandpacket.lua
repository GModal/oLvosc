-- sendrandpacket.lua
--	sends random packets (OSC messages and bundles) for testing.

--	the buildRandBun() function is recursive and the recursion limit is set by the
--		<recusionLimit> variable. An earlier, non-limited version sent a bundle that
--		was nested 22 levels deep. That crashed the oscdump.lua utility (recursive print),
--		but not this script, which happily kept generating valid bundles.

--	Increase or decrease <recusionLimit> to suit.
local oLvosc = require "oLv/oLvosc"
local cli
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local port = 7770
local recusionLimit = 6

local words1 = {'my','the','welcome','ardour','carla','teensy','arduino','PureData','first','message','lyrics','stream'}
local words2 = {'pray','enchanted','bottle','obsequious','heady','noxious','eggs','soap','large','pink','insidious','Chanel','hulking'}
local types = 'sfim'

local function buildStr(stab, reps, sep)
	local rstr = ''
	for i = 1, reps, 1 do
		rstr = rstr..stab[math.random(12)]
		if i < reps then
			rstr = rstr..sep
		end
	end
	return (rstr)
end

-- build a random message
local function buildRandMsg()
	local typetag = ''
	local addrtag = '/'..buildStr(words1, math.random(2,4), '/')
	local msgs = {}
	local numOfArgs = math.random(5)
	for i = 1, numOfArgs, 1 do
		local tr = math.random(#types)
		typ = string.sub(types, tr, tr)
		if typ == 's' then
			msgs[i] = buildStr(words2, math.random(3,7), ' ')
		elseif typ == 'f' then
			msgs[i] = math.random() + math.random(1, 80)
		elseif typ == 'i' then
			msgs[i] = math.random(1, 256)
		elseif typ == 'm' then
			msgs[i] = oLvosc.packMIDI(0xff, 0xf7, 0xAA, 0x00)
		end
		typetag = typetag..typ
	end

	return (oLvosc.oscPacket(addrtag, typetag, msgs))
end

-- build bundles recursively
--	<rlimit> sets the recursion limit
local function buildRandBundle(rlimit)
	local bundle = oLvosc.newBundle(oLvosc.packTIME(math.random(1, 80), math.random(1, 9999999)))
	
	local numOfElem = math.random(2, 5)
	for i = 1, numOfElem, 1 do
		local dice = math.random(1, 6)
		if dice < 6 then
			local bpack = buildRandMsg()
			oLvosc.addMsgToBundle(bundle, bpack)
		elseif rlimit < recusionLimit then
			local bun2 = buildRandBundle(rlimit + 1)
			oLvosc.addBundleToBundle(bundle, bun2)
		end
	end
	return bundle
end

----------------------------------------------------------------------
port = 7770
if arg[1] ~= nil then
	port = arg[1]
end

print('sending to port: '..port) 
cli = oLvosc.cliSetup('224.0.0.1', port)

local scount = 1

math.randomseed (os.time ())
while 1 do
  oLvosc.sleep(4)
	local randpacket
	local dice = math.random(1, 8)
	if dice < 5 then
		randpacket = buildRandMsg()
	else
		randpacket = oLvosc.oscBundlePack(buildRandBundle(1))
	end
	
	print('sending #'..scount)
	scount = scount + 1
	oLvosc.sendOSC(cli, randpacket)
end  
