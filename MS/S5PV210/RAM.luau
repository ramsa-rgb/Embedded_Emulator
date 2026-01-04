local module = {}

-- MMIO에 나온 DRAM0, DARM1에 맞춤.

module.DRAM0 = {}
module.DRAM1 = {}

function module.WRITE(ADDRESS, DATA)
	
	if (ADDRESS < 0x3FFFFFFF) then
		module.DRAM0[ADDRESS] = DATA
	else
		module.DRAM1[ADDRESS] = DATA
	end
	
end

function module.READ(ADDRESS) : number
	
	if (ADDRESS < 0x3FFFFFFF) then
		if (module.DRAM0[ADDRESS]) then
			return module.DRAM0[ADDRESS]
		else
			module.WRITE(0, ADDRESS, 0x00000000)
			return module.DRAM0[ADDRESS]
		end
	else
		if (module.DRAM1[ADDRESS]) then
			return module.DRAM1[ADDRESS]
		else
			module.WRITE(1, ADDRESS, 0x00000000)
			return module.DRAM1[ADDRESS]
		end
	end
	
end

return module
