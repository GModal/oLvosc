local oLvosc = require "oLv/oLvosc"
local cli
local val = 0
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
--    timetag test
-- +++++++++++++++++++++++++++++++++++++++++++++++++++

local isec, ifrac, ffrac, epoch = oLvosc.time()
print(isec, ifrac, ffrac, epoch)

local mytime = oLvosc.packTIME(isec, ifrac)
print (oLvosc.unpackTIME(mytime))