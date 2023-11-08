local oLvosc = require "oLv/oLvosc"
local cli
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local port = 7770
print('sending to port: '..port) 

cli = oLvosc.cliSetup('224.0.0.1', port)

-- Bundle packet creation added !
--		This code has few error checks...
--		DON'T create circular references (like adding a bundle to itself)
-- 	Functions:

-- bundle_dt oLvosc.oLvosc.newBundle(oscTimetag)
--		Creates a new, empty bundle dt (data table)

--		A bundle_dt is a data table which holds the bundle
--		structure & data, pre-build. A bundle osc packet is built  
--		from this preliminary information & framework.

-- bool oLvosc.addMsgToBundle(bundle_dt, msg_packet)
--		Add an osc Msg packet to a bundle_dt
--			if rval == false, the bundle is locked, or the bundle is invalid

-- nil oLvosc.addBundleToBundle(parentBundle, childBundle)
--		No additional data can be added to the child (sub-bundle) after this operation.
--			Once added, the child bundle is locked, and addMsgToBundle() won't function on the child.
--			Therefore, sub-bundles should be fully populated before adding to a parent bundle.
--		However, additional elements (msgs & bundles) can be added to the parent bundle.

-- bundle_packet oLvosc.oscBundlePack(bundle_dt)
--		Generate a transmissible bundle packet from a populated bundle_dt

--create empty bundle dt's (bundle data tables)
local parent = oLvosc.newBundle(oLvosc.packTIME(2, 32555))
local child = oLvosc.newBundle(oLvosc.TT_IMMEDIATE)
local grandchild = oLvosc.newBundle(oLvosc.TT_IMMEDIATE)	

-- populate the grandchild bundle
local packetG1 = oLvosc.oscPacket('/my/aMsg', 'm', { oLvosc.packMIDI(0xff, 0xf7, 0xAA, 0x00)})
local packetG2 = oLvosc.oscPacket('/my/aMsg', 's', { 'Deepest bundle (grandchild) contains a midi packet'} )
oLvosc.addMsgToBundle(grandchild, packetG1)
oLvosc.addMsgToBundle(grandchild, packetG2)

-- populate the child bundle
local packetC1 = oLvosc.oscPacket('/my/aMsg', 'ff', { 23.3333 , 65.5} )
local packetC2 = oLvosc.oscPacket('/my/aMsg', 'ss', { 'HelloMyCrazy, Babba badda radda', 'Sending nonsense lyrics in packet'} )
oLvosc.addMsgToBundle(child, packetC1)
oLvosc.addMsgToBundle(child, packetC2)

-- populate the parent bundle
local packetP1 = oLvosc.oscPacket('/myOSC/aMsg', 'is', { 44434 , 'A msg for my bundle'} )
local packetP2 = oLvosc.oscPacket('/myOSC/aMsg', 'ffs', { 80.5 , 34.255, 'Sending CC Mod'} )
oLvosc.addMsgToBundle(parent, packetP1)
oLvosc.addMsgToBundle(parent, packetP2)

-- add grandchild to child, child to parent
oLvosc.addBundleToBundle(child, grandchild)
oLvosc.addBundleToBundle(parent, child)

-- add msg after the child bundle
local packetP3 = oLvosc.oscPacket('/my/aMsg', 'ss', { 'The Fifth', 'This msg should be in the top level after the second bundle'} )
oLvosc.addMsgToBundle(parent, packetP3)

-- build the bundle packet
local bundlePacket = oLvosc.oscBundlePack(parent)
-- send it
oLvosc.sendOSC(cli, bundlePacket) 
