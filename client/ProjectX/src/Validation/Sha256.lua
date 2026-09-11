local Sha256 = {}
local bitlib = bit or bit32

local function assertBit()
    if not bitlib then error("sha256 requires bit or bit32") end
end

local band = function(a, b) assertBit(); return bitlib.band(a, b) end
local function bxor(a, b, ...)
    assertBit()
    local value = bitlib.bxor(a, b)
    for index = 1, select("#", ...) do
        value = bitlib.bxor(value, select(index, ...))
    end
    return value
end
local bnot = function(a) assertBit(); return bitlib.bnot(a) end
local rshift = function(a, n) assertBit(); return bitlib.rshift(a, n) end
local lshift = function(a, n) assertBit(); return bitlib.lshift(a, n) end
local function rrotate(a, n)
    if bitlib.rrotate then return bitlib.rrotate(a, n) end
    if bitlib.ror then return bitlib.ror(a, n) end
    return band(bxor(rshift(a, n), lshift(a, 32 - n)), 0xffffffff)
end
local function add(...)
    local value = 0
    for index = 1, select("#", ...) do value = band(value + select(index, ...), 0xffffffff) end
    return value
end

local constants = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
}

function Sha256.hex(message)
    message = message or ""
    local length = #message
    local bitLength = length * 8
    message = message .. string.char(0x80)
    while (#message % 64) ~= 56 do message = message .. string.char(0) end
    local high = math.floor(bitLength / 4294967296)
    local low = bitLength % 4294967296
    local function word(value)
        return string.char(band(rshift(value,24),255), band(rshift(value,16),255), band(rshift(value,8),255), band(value,255))
    end
    message = message .. word(high) .. word(low)
    local h = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    for offset = 1, #message, 64 do
        local w = {}
        for index = 0, 15 do
            local p = offset + index * 4
            w[index] = add(lshift(message:byte(p),24), lshift(message:byte(p+1),16), lshift(message:byte(p+2),8), message:byte(p+3))
        end
        for index = 16, 63 do
            local x = w[index-15]; local y = w[index-2]
            local s0 = bxor(rrotate(x,7), rrotate(x,18), rshift(x,3))
            local s1 = bxor(rrotate(y,17), rrotate(y,19), rshift(y,10))
            w[index] = add(w[index-16], s0, w[index-7], s1)
        end
        local a,b,c,d,e,f,g,hh = h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8]
        for index = 0, 63 do
            local s1 = bxor(rrotate(e,6), rrotate(e,11), rrotate(e,25))
            local choose = bxor(band(e,f), band(bnot(e),g))
            local t1 = add(hh, s1, choose, constants[index+1], w[index])
            local s0 = bxor(rrotate(a,2), rrotate(a,13), rrotate(a,22))
            local majority = bxor(band(a,b), band(a,c), band(b,c))
            local t2 = add(s0, majority)
            hh,g,f,e,d,c,b,a = g,f,e,add(d,t1),c,b,a,add(t1,t2)
        end
        h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8] = add(h[1],a),add(h[2],b),add(h[3],c),add(h[4],d),add(h[5],e),add(h[6],f),add(h[7],g),add(h[8],hh)
    end
    local output = {}
    for index = 1, 8 do output[index] = string.format("%08x", h[index] < 0 and h[index] + 4294967296 or h[index]) end
    return table.concat(output)
end

return Sha256
