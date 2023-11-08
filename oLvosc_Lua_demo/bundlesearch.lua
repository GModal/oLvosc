local oLvosc = require "oLv/oLvosc"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local unpack = unpack or table.unpack
local function spaces(reps)
	return (string.rep('    ', reps))
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

-- recursively search the nested tables in an unpacked bundle
--		returns a nested table, can be flattened by resultsToList()
local function bundleSearch(bdata, addrStr, lev)
	local rdata = {}
	if type(bdata) == 'table' then
		for  _,be in ipairs(bdata) do
			if be[1] == 'msg' then
				local dType, tlevel, tc, oscPACKET = unpack(be)
				local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(oscPACKET)
				if string.match(oscADDR, addrStr) then
					if lev == nil or lev == tlevel then
						table.insert(rdata, {'msg', tlevel, tc, oscPACKET})
					end
				end
			elseif be[1] ~= 'bun' then
				table.insert(rdata, bundleSearch(be, addrStr, lev))
			end	
		end
	end
	return(rdata)
end

-- poll the OSC server
function myServ(udp, searchFor, searchLevel)
	local packet = oLvosc.oscPoll(udp)
	if packet == nil then return end

	if oLvosc.isBundle(packet) then -- handle bundled messages
		local bundle_unpack = oLvosc.oscUnpackBundle(packet, 1)
		local search_results = bundleSearch(bundle_unpack, searchFor, searchLevel)

		local search_list = oLvosc.bundleResultsToList(search_results)
		for _, srcMsgs in ipairs(search_list) do
			print_msg(srcMsgs, 'Found:')
		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- OSC receive (server), listen to all
local sudp
local sTerm = 'Bundle'
local sLevel = nil
local sLevelTxt = 'n/a'

local port = 3819
if arg[1] ~= nil then
	port = arg[1]
end

if arg[2] ~= nil then
	sTerm = arg[2]
end

if arg[3] ~= nil then
	local tlev = tonumber(arg[3])
	if type(tlev) == 'number' then
		sLevel = tlev
	end
end
sudp = oLvosc.servSetup("*", port)

if sLevel ~= nil then
	sLevelTxt = tostring(sLevel)
end
print('Listening on port: '..port)
print('Searching Bundles-- Str in Addr: '..sTerm..'  on Level: '..sLevelTxt)

while 1 do
	oLvosc.sleep(0.033)
	myServ(sudp, sTerm, sLevel)
end
