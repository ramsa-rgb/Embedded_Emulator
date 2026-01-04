local module = {}

local bitmgr = require("../../bitmgr/bitmgr")

module.Registers = {
	IFAR = 0x00000000,
	IFSR = 0x00000000,
	
	DFAR = 0x00000000,
	DFSR = 0x00000000,
	
	R0 = 0x00000000,
	R1 = 0x00000000,
	R2 = 0x00000000,
	R3 = 0x00000000,
	R4 = 0x00000000,
	R5 = 0x00000000,
	R6 = 0x00000000,
	R7 = 0x00000000,
	R8 = 0x00000000,
	R9 = 0x00000000,
	R10 = 0x00000000,
	R11 = 0x00000000,
	R12 = 0x00000000,
	R8_fiq = 0x00000000,
	R9_fiq = 0x00000000,
	R10_fiq = 0x00000000,
	R11_fiq = 0x00000000,
	R12_fiq = 0x00000000,
	SP_fiq = 0x00000000,
	LR_fiq = 0x00000000,
	SP_abt = 0x00000000,
	LR_abt = 0x00000000,
	SP_svc = 0x00000000,
	LR_svc = 0x00000000,
	SP_und = 0x00000000,
	LR_und = 0x00000000,
	SP_mon = 0x00000000,
	LR_mon = 0x00000000,
	SP_hyp = 0x00000000,
	
	SP_EL0 = 0x00000000,
	SP_EL1 = 0x00000000,
	SP_EL2 = 0x00000000,
	SP_EL3 = 0x00000000,
	
	SPSR_EL1 = 0x00000000,
	SPSR_EL2 = 0x00000000,
	SPSR_EL3 = 0x00000000,
	
	ELR_EL1 = 0x00000000,
	ELR_EL2 = 0x00000000,
	ELR_EL3 = 0x00000000,
	
	R13 = 0x00000000,
	R14 = 0x00000000,
	R15 = 0x00000000,
	
	CPSR = 0x00000000,
	APSR = 0x00000000,
	SPSR = 0x00000000,
	SPSR_fiq = 0x00000000,
	SPSR_irq = 0x00000000,
	SPSR_abt = 0x00000000,
	SPSR_svc = 0x00000000,
	SPSR_und = 0x00000000,
	SPSR_mon = 0x00000000,
	SPSR_hyp = 0x00000000,
	ELR_hyp = 0x00000000,
}

local Abort = false

local MMIO = require("./MMIO")

function module.Abort(ADDRESS, STATUS, FAULT, ABORTID)
	if (ABORTID == 0) then
		-- Prefetch Abort
		
		module.Registers.IFAR = ADDRESS
		module.Registers.IFSR = 0b00000000 -- 구현 중에 있음.
	elseif (ABORTID == 1) then
		-- Data Abort
		
		module.Registers.DFAR = ADDRESS
		module.Registers.DFSR = 0b00000000 -- 구현 중에 있음.
	end

	print("!!ABORT!!\nPC : " .. tostring(ADDRESS) .. " | ABORT : " .. (ABORTID == 1 and "DATA ABORT" or "PREFETCH ABORT"))
	
	Abort = true	
end

local Reset_vector = 0x00000000

function module.Run()
	module.Registers.R15 = Reset_vector
	
	while (Abort == false) do
		local COMMAND = MMIO.AccessMMIO(0, module.Registers.R15)
		module.Execute(COMMAND)

		module.Registers.R15 += 1
	end
end

function module.FLAGSUPDATE(VALUE, SRC0, SRC1)
	if (VALUE > 0xFFFFFFFF) then
		module.Registers.CPSR = bitmgr.setbit(module.Registers.CPSR, 29, 1)
	end

	if (bit32.band(
		bit32.bnot(bit32.bxor(SRC0, SRC1)),
		bit32.bxor(SRC0, VALUE)
	)) then
		module.Registers.CPSR = bitmgr.setbit(module.Registers.CPSR, 28, 1)
	end

	if (VALUE == 0) then
		module.Registers.CPSR = bitmgr.setbit(module.Registers.CPSR, 30, 1)
	end

	if (VALUE < 0) then
		module.Registers.CPSR = bitmgr.setbit(module.Registers.CPSR, 31, 1)
	end
end

function module.Execute(CMDLINE:string) -- 32bit command
	local STRSPLIT
	Success, error = pcall(function()
		STRSPLIT = string.split(CMDLINE, " ")
	end)

	if (Success == false) then
		module.Abort(module.Registers.R15, 0, 0, 0)
		return
	end

	local CMD = STRSPLIT[1]:upper()
	print(CMDLINE)

	local DESTREG -- R0
	local DESTIMM -- #0x55

	local SRCAREG -- R1
	local SRCAIMM -- #0x55

	local SRCBREG -- R2
	local SRCBIMM -- #0x55

	local PREINDEX = false
	local ADDRESSREGUPDATE = false

	local DESTMMREG -- [R0]
	local DESTMMIMM -- [0x55]
	
	local SRCAMMREG -- [R1]
	local SRCAMMIMM -- [0x55]

	local SRCBMMREG -- [R2]
	local SRCBMMIMM -- [0x55]

	pcall(function() -- DESTREG
		DESTREG = STRSPLIT[2]:upper():gsub(",", "")
	end)

	pcall(function() -- DESTIMM
		DESTIMM = STRSPLIT[2]:upper():gsub("#", "")
	end)

	pcall(function() -- SRCAREG
		SRCAREG = STRSPLIT[3]:upper():gsub(",", "")
	end)

	pcall(function() -- SRCAIMM
		SRCAIMM = STRSPLIT[3]:upper():gsub("#", "")
	end)

	pcall(function() -- SRCBREG
		SRCBREG = STRSPLIT[4]:upper():gsub(",", "")
	end)
	
	pcall(function() -- SRCBIMM
		SRCBIMM = STRSPLIT[4]:upper():gsub("#", "")
	end)

	pcall(function() -- DESTMMREG
		DESTMMREG = STRSPLIT[2]:upper():gsub("[,%[%]]", "")
	end)

	pcall(function() -- DESTMMIMM
		PREINDEX = ((STRSPLIT[2]:upper():sub(#STRSPLIT[2]:upper() - 1, #STRSPLIT[2]:upper() - 1) == "]" or STRSPLIT[2]:upper():sub(#STRSPLIT[2]:upper(), #STRSPLIT[2]:upper()) == "]") and true or false)
		ADDRESSREGUPDATE = (STRSPLIT[2]:upper():sub(#STRSPLIT[2]:upper(), #STRSPLIT[2]:upper()) == "!" and true or false)
		DESTMMIMM = STRSPLIT[2]:upper():gsub("[,%[%]#]", "")
	end)

	pcall(function() -- SRCAMMREG
		SRCAMMREG = STRSPLIT[3]:upper():gsub("[,%[%]]", "")
	end)

	pcall(function() -- SRCAMMIMM
		PREINDEX = STRSPLIT[3]:upper():sub(#STRSPLIT[3]:upper(), #STRSPLIT[3]:upper()) == "]" and true or false
		ADDRESSREGUPDATE = (STRSPLIT[3]:upper():sub(#STRSPLIT[3]:upper(), #STRSPLIT[3]:upper()) == "!" and true or false)
		SRCAMMIMM = STRSPLIT[3]:upper():gsub("[,%[%]#]", "")
	end)

	pcall(function() -- SRCBMMREG
		SRCBMMREG = STRSPLIT[4]:upper():gsub("[,%[%]]", "")
	end)

	pcall(function() -- SRCBMMIMM
		PREINDEX = STRSPLIT[4]:upper():sub(#STRSPLIT[4]:upper(), #STRSPLIT[4]:upper()) == "]" and true or false
		ADDRESSREGUPDATE = (STRSPLIT[4]:upper():sub(#STRSPLIT[4]:upper(), #STRSPLIT[4]:upper()) == "!" and true or false)
		SRCBMMIMM = STRSPLIT[4]:upper():gsub("[,%[%]#]", "")
	end)
	
	local RESULTVALUE = 0

	if (CMD:sub(1, 3) == "ADC") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] + module.Registers[SRCBREG] + tonumber(bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] + tonumber(SRCBIMM) + tonumber(bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end

	elseif (CMD:sub(1, 3) == "ADD") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] + module.Registers[SRCBREG]
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] + tonumber(SRCBIMM)
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "SUB") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] - module.Registers[SRCBREG]
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] - tonumber(SRCBIMM)
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "SBC") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] - module.Registers[SRCBREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] - tonumber(SRCBIMM) - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "RSB") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCBREG] - module.Registers[SRCAREG]
		else
			module.Registers[DESTREG] = tonumber(SRCBIMM) - module.Registers[SRCAREG]
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "RSC") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCBREG] - module.Registers[SRCAREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = tonumber(SRCBIMM) - module.Registers[SRCAREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "AND") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = bit32.band(module.Registers[SRCAREG], module.Registers[SRCBREG])
		else
			module.Registers[DESTREG] = bit32.band(module.Registers[SRCAREG], tonumber(SRCBIMM))
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "EOR") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = bit32.bxor(module.Registers[SRCAREG], module.Registers[SRCBREG])
		else
			module.Registers[DESTREG] = bit32.bxor(module.Registers[SRCAREG], tonumber(SRCBIMM))
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end

	elseif (CMD:sub(1, 3) == "ORR") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = bit32.bor(module.Registers[SRCAREG], module.Registers[SRCBREG])
		else
			module.Registers[DESTREG] = bit32.bor(module.Registers[SRCAREG], tonumber(SRCBIMM))
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "BIC") then
		if (tonumber(SRCBIMM) == nil) then
			module.Registers[DESTREG] = bit32.band(module.Registers[SRCAREG], bit32.bnot(module.Registers[SRCBREG]))
		else
			module.Registers[DESTREG] = bit32.band(module.Registers[SRCAREG], bit32.bnot(tonumber(SRCBIMM)))
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD:sub(1, 3) == "MOV") then		
		if (tonumber(SRCAIMM) == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG]
		else
			module.Registers[DESTREG] = tonumber(SRCAIMM)
		end
	elseif (CMD:sub(1, 3) == "MVN") then		
		if (tonumber(SRCAIMM) == nil) then
			module.Registers[DESTREG] = bit32.bnot(module.Registers[SRCAREG])
		else
			module.Registers[DESTREG] = bit32.bnot(tonumber(SRCAIMM))
		end
	elseif (CMD:sub(1, 3) == "TST") then
		RESULTVALUE = bit32.band(tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))

		module.FLAGSUPDATE(RESULTVALUE, tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))
	elseif (CMD:sub(1, 3) == "TEQ") then
		RESULTVALUE = bit32.bxor(tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))

		module.FLAGSUPDATE(RESULTVALUE, tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))
	elseif (CMD:sub(1, 3) == "CMP") then
		RESULTVALUE = tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM) - tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM)

		module.FLAGSUPDATE(RESULTVALUE, tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))
	elseif (CMD:sub(1, 3) == "CMN") then
		RESULTVALUE = tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM) + tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM)

		module.FLAGSUPDATE(RESULTVALUE, tonumber(DESTIMM) == nil and module.Registers[DESTREG] or tonumber(DESTIMM), tonumber(SRCAIMM) == nil and module.Registers[SRCAREG] or tonumber(SRCAIMM))
	elseif (CMD:sub(1, 3) == "LDR") then
		if (PREINDEX == true) then
			module.Registers[DESTREG] = MMIO.AccessMMIO(0, (tonumber(SRCAMMIMM) == nil and module.Registers[SRCAMMREG] or tonumber(SRCAMMIMM)) + (SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)))
			if (ADDRESSREGUPDATE == true) then
				module.Registers[SRCAMMREG] += SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)
			end
		else
			module.Registers[DESTREG] = MMIO.AccessMMIO(0, tonumber(SRCAMMIMM) == nil and module.Registers[SRCAMMREG] or tonumber(SRCAMMIMM))
			module.Registers[SRCAMMREG] += SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)
		end
	elseif (CMD:sub(1, 3) == "STR") then
		if (PREINDEX == true) then
			MMIO.AccessMMIO(1, (tonumber(SRCAMMIMM) == nil and module.Registers[SRCAMMREG] or tonumber(SRCAMMIMM)) + (SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)), module.Registers[DESTREG])
			if (ADDRESSREGUPDATE == true) then
				module.Registers[SRCAMMREG] += SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)
			end
		else
			MMIO.AccessMMIO(1, tonumber(SRCAMMIMM) == nil and module.Registers[SRCAMMREG] or tonumber(SRCAMMIMM), module.Registers[DESTREG])
			module.Registers[SRCAMMREG] += SRCBMMIMM == nil and 0 or tonumber(SRCBMMIMM)
		end
	end
end

return module