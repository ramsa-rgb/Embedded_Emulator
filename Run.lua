local CPU = require("./MS/S5PV210/CPU")
local IROM = require("./MS/S5PV210/DEVICES/IROMIRAM/DEVICE")

local IROM_CODE = {
    "MOV r0, #5",
    "MOV r1, #3",
    "ADD R2, R0, R1",
    "SUB R3, R0, R1",
    "MUL R4, R0, R1",
}

for index, value in ipairs(IROM_CODE) do
    print("IROM Writing... " .. index .. " / " .. #IROM_CODE .. " : " .. value)
    IROM.WRITE(index, value)
end

CPU.Run()