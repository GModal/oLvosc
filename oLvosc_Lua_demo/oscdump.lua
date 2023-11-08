local oLvosc = require "oLv/oLvosc"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local packetCount = 0
local viewType = ''
local unpack = unpack or table.unpack

local function spaces(reps)
	return (string.rep('    ', reps))
end
--helper print function
local function print_msgformat(oscTYPE, dataT, indent)
	local form = '\27[3m'
	local clear_form = '\27[0m'
	
	local fstr = string.format(spaces(indent))
	if dataT ~= nil then
		for i, v in ipairs(dataT) do
			local tc = oscTYPE:sub(i,i)
			if tc == 's' then
				fstr = string.format(fstr..' '..form..'"'..v..'"'..clear_form)
			elseif tc == 'm' then
				local m1, m2, m3, m4 = oLvosc.unpackMIDI(v)
				local midistr = string.format(' 0x%02X 0x%02X 0x%02X 0x%02X ', m1, m2, m3, m4)
				fstr = string.format(fstr..' MIDI: '..'['..midistr..']' )
			else
				fstr = string.format(fstr..' '..v)
			end
		end
	end
	print(fstr)
end
--another helper print function, simpler 
local function print_msg(packet, label)
	if packet[1] == 'msg' then
		local dType, level, tc, oscPACKET = unpack(packet)
		local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(oscPACKET)
		local tsec, tfrac = oLvosc.unpackTIME(tc)
		print(label, ' Msg     '..oscADDR, oscTYPE, 'Level: '.. level..'   Time: ['..tsec..':'..tfrac..']' )
	elseif packet[1] == 'bun' then
		local dType, level, tsec, tfrac = unpack(packet)
		print(label, '\27[1m'..'Bundle     '..'\27[97m'..'Level: '..level..'   Time: ['..tsec..':'..tfrac..']'..'\27[0m' )
	end
end

-- recursively print a formatted display of the nested tables in an unpacked bundle 
local function bundleView(bdata)
	local dType, blevel, tsec, tfrac
	if type(bdata) == 'table' then
		for  _,be in ipairs(bdata) do
			if be[1] == 'bun' then
				dType, blevel, tsec, tfrac = unpack(be)
				--print()
				print(spaces((blevel-1))..'\27[1m'..'BUNDLE:  ( Lev: '..blevel .. '  Time: ['.. tsec..':'..tfrac .. '] )'..'\27[0m')
				isbun = true
			elseif be[1] == 'msg' then
				local dType, tlevel, tc, oscPACKET = unpack(be)
				local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(oscPACKET)
				local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
				print(spaces(tlevel-1)..' -MSG: '..oscADDR..'  \27[7m'.. oscTYPE..'\27[0m  ( Lev: '.. tlevel..'  Time: ['.. tsec..':'..tfrac .. '] )')
				print_msgformat(oscTYPE, dataT, tlevel-1)
			else
				bundleView(be)
			end	
		end
	end
end

-- poll the OSC server
function myServ(udp)
	local packet = oLvosc.oscPoll(udp)
	if packet == nil then return end
	packetCount = packetCount + 1
	print('\n    Packet Count: ', packetCount)
			
	if oLvosc.isBundle(packet) then -- handle bundled messages
		local bundle_unpack = oLvosc.oscUnpackBundle(packet)
		
		-- print the bundle tree
		if viewType ~= 'l' then
			bundleView( bundle_unpack )
		end
		-- flatten bundle to list, print
		if viewType ~= 't' then
			print('\n  List :')
			local bunlist = oLvosc.bundleResultsToList(bundle_unpack)
			for _, blist in ipairs(bunlist) do
				print_msg(blist, '->')
			end
		end

	else  -- print a single osc message packet
		local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
		local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
		print('^ '..oscADDR, oscTYPE)
		print_msgformat(oscTYPE, dataT, 0)
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- OSC receive (server), listen to all
local sudp

local port = 3819
if arg[1] ~= nil then
	port = arg[1]
end
if arg[2] == 't' or arg[2] == 'l' then
	viewType = arg[2]
end
sudp = oLvosc.servSetup("*", port)
print('Listening on port: '..port)

while 1 do
	oLvosc.sleep(0.033)
	myServ(sudp)
end
