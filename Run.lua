local CPU = require("./MS/S5PV210/CPU")
local IROM = require("./MS/S5PV210/DEVICES/IROMIRAM/DEVICE")

local IROM_CODE = {
    "MOV r0, #0xffffffff",
    "STR r0, [#0x20000000]",
    "ldr r1, [#0x1FFFFFFF, #1]"
}

for index, value in ipairs(IROM_CODE) do
    print("IROM Writing... " .. index .. " / " .. #IROM_CODE .. " : " .. value)
    IROM.WRITE(index - 1, value)
    print(IROM.READ(index - 1))
end

CPU.Run()