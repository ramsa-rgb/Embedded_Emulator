local CPU = require("./MS/S5PV210/CPU")
local IROM = require("./MS/S5PV210/DEVICES/IROMIRAM/DEVICE")

local IROM_CODE = {
"MOV R0, #0x12345678",        -- R0 = 0x12345678
"MVN R1, R0",                 -- R1 = NOT R0 = 0xEDCBA987

"TST R0, #0xFF00FF00",        -- 플래그만 업데이트, 결과 버림
"TEQ R0, #0x12340000",        -- 플래그만 업데이트, 결과 버림
"CMP R0, #0x12345678",        -- Z=1 (같음)
"CMN R0, #0x1",               -- Z=0 (R0+1 != 0)

"LDR R2, [#0xAA55AA55]",             -- R2 = 주소 of value
"LDR R3, [R2]",               -- R3 = 0xAA55AA55
"STR R3, [R2, #4]",           -- [value+4] = 0xAA55AA55

"LDRB R4, [R2]",              -- R4 = 0x55
"STRB R4, [R2, #5]",          -- [value+5] = 0x55
"LDRH R5, [R2]",              -- R5 = 0xAA55
"STRH R5, [R2, #6]",          -- [value+6] = 0xAA55

"LDRSB R6, [R2]",             -- R6 = 0x55 (부호 확장)
"LDRSH R7, [R2]",             -- R7 = 0xAA55 (부호 확장)

"STMFD SP!, {R0-R3}",         -- 스택에 R0-R3 저장
"LDMFD SP!, {R8-R11}",        -- 스택에서 R8-R11 로드

"BL subroutine",              -- LR = 다음 주소, 분기
"B branch_target",            -- 무조건 분기
"BX LR",                      -- LR로 복귀
"BLX LR",                     -- LR로 분기, 모드 변경 가능

"NOP",                        -- 아무 동작 없음

"MRS R0, CPSR",               -- R0 = CPSR 읽기
"MSR CPSR_c, R0",             -- CPSR condition 필드 설정

"MOV R1, #0x00F00000",
"CLZ R2, R1",                 -- R2 = 8 (선행 0 비트 개수)

"LDR R3, =value2",
"LDR R4, [R3]",               -- R4 = 0xDEADBEEF
"MOV R5, #0x12345678",
"SWP R6, R5, [R3]",           -- R6 = 이전 메모리 값, [R3] = R5
"SWPB R7, R5, [R3]",          -- 바이트 단위 교환

-- "value: DCD 0xAA55AA55, 0x0",
-- "value2: DCD 0xDEADBEEF"
-- 여기는 테스트 코드라 챗지피티 사용했습니다.
}

for index, value in ipairs(IROM_CODE) do
    print("IROM Writing... " .. index .. " / " .. #IROM_CODE .. " : " .. value)
    IROM.WRITE(index - 1, value)
    print(IROM.READ(index - 1))
end

CPU.Run()