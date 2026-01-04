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
		
		local LOG = ""

		for N, V in pairs(module.Registers) do
			LOG = LOG .. N .. " : " .. V .. " "
		end

		print(LOG .. " LOG END.")

		module.Registers.R15 += 1
	end
end

function module.FLAGSUPDATE(VALUE, SRC0, SRC1)
	if (VALUE > 0xFFFFFFFF) then
		module.Registers.CPSR = bitmgr.setbit(CPSR, 29, 1)
	end

	if (bit32.band(
		bit32.bnot(bit32.bxor(SRC0, SRC1)),
		bit32.bxor(SRC0, VALUE)
	)) then
		module.Registers.CPSR = bitmgr.setbit(CPSR, 28, 1)
	end

	if (VALUE == 0) then
		module.Registers.CPSR = bitmgr.setbit(CPSR, 30, 1)
	end

	if (VALUE < 0) then
		module.Registers.CPSR = bitmgr.setbit(CPSR, 31, 1)
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

	if (CMD:sub(1, 3) == "ADC") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]

		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] + module.Registers[SRCBREG] + tonumber(bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] + module.Registers[SRCBIMM] + tonumber(bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end

	elseif (CMD == "ADD") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]
		
		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] + module.Registers[SRCBREG]
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] + tonumber(SRCBIMM)
		end

		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end

	elseif (CMD == "SUB") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]
		
		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] - module.Registers[SRCBREG]
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] - tonumber(SRCBIMM)
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD == "SBC") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]

		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG] - module.Registers[SRCBREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = module.Registers[SRCAREG] - module.Registers[SRCBIMM] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD == "RSB") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]
		
		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCBREG] - module.Registers[SRCAREG]
		else
			module.Registers[DESTREG] = tonumber(SRCBIMM) - module.Registers[SRCAREG]
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD == "RSC") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCBREG = STRSPLIT[4]:upper():split(",")[1]
		local SRCBIMM = STRSPLIT[4]:upper():split("#")[2]

		if (SRCBIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCBREG] - module.Registers[SRCAREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		else
			module.Registers[DESTREG] = module.Registers[SRCBIMM] - module.Registers[SRCAREG] - tonumber(1 - bitmgr.getbits(module.Registers.CPSR, 29, 29))
		end
		
		if (CMD:sub(4, 4) == "S") then
			module.FLAGSUPDATE(module.Registers[DESTREG], module.Registers[SRCAREG], SRCBIMM == nil and module.Registers[SRCBREG] or tostring(SRCBIMM))
		end
	elseif (CMD == "MOV") then
		local DESTREG = STRSPLIT[2]:upper():split(",")[1]
		local SRCAREG = STRSPLIT[3]:upper():split(",")[1]
		local SRCAIMM = STRSPLIT[3]:upper():split("#")[2]
		
		if (SRCAIMM == nil) then
			module.Registers[DESTREG] = module.Registers[SRCAREG]
		else
			module.Registers[DESTREG] = tonumber(SRCAIMM)
		end
	end
end

return module