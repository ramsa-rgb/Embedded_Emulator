local module = {}

module.IROM = {}

function module.WRITE(ADDRESS, DATA)
	module.IROM[ADDRESS] = DATA
	
end

function module.READ(ADDRESS) : number
	if (module.IROM[ADDRESS]) then
		return module.IROM[ADDRESS]
	else
		module.WRITE(0, ADDRESS, 0x00000000)
		return module.IROM[ADDRESS]
	end
	
end

return module
