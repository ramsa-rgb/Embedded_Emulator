local CPU = require("./MS/S5PV210/CPU")
local IROM = require("./MS/S5PV210/DEVICES/IROMIRAM/DEVICE")

local IROM_CODE = {
    "MOV R0, #5",
    "MOV R1, #3",

    "ADD R2, R0, R1",
    "ADC R3, R0, R1",

    "SUB R4, R0, R1",
    "SBC R5, R0, R1",

    "RSB R6, R0, R1",
    "RSC R7, R0, R1",

    "AND R8, R0, R1",
    "EOR R9, R0, R1",
    "ORR R10, R0, R1",
    "BIC R11, R0, R1",

    "MOV R12, #0xFF",
    "AND R13, R12, #0x0F",
    "ORR R14, R12, #0x01",
    "EOR R15, R12, #0xFF"
}

for index, value in ipairs(IROM_CODE) do
    print("IROM Writing... " .. index .. " / " .. #IROM_CODE .. " : " .. value)
    IROM.WRITE(index - 1, value)
    print(IROM.READ(index - 1))
end

CPU.Run()