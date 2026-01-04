local module = {}

function module.getbits(value: number, startBit: number, endBit: number): number
    local width = endBit - startBit + 1
    local mask = bit32.lshift(1, width) - 1
    return bit32.band(bit32.rshift(value, startBit), mask)
end

function module.setbit(v, b, x)
    if x == 1 then
        return bit32.bor(v, bit32.lshift(1, b))
    else
        return bit32.band(v, bit32.bnot(bit32.lshift(1, b)))
    end
end

return module