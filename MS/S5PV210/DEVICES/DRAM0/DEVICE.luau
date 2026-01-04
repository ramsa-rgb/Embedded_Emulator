local module = {}

local RAM = require("../../RAM")

function module.WRITE(ADDRESS, DATA)
	print("DRAM WRITE")
	RAM.WRITE(ADDRESS, DATA)
end

function module.READ(ADDRESS) : number
	print("DRAM READ")
	return RAM.READ(ADDRESS)
end

return module
