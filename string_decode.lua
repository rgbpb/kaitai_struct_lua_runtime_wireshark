--
-- String decoder functions
--

local stringdecode = {}

--
-- Lua 5.3+ removed the 'bit32' library (replaced by native bitwise
-- operators). Polyfill it here too, since this file can be loaded
-- independently of kaitaistruct.lua.
--
if not bit32 then
    local native_src = [[
        local bit32 = {}
        local MASK32 = 0xFFFFFFFF
        function bit32.band(a, b) return (a & b) & MASK32 end
        function bit32.bor(a, b) return (a | b) & MASK32 end
        function bit32.lshift(a, n)
            if n <= -32 or n >= 32 then return 0 end
            if n < 0 then return (a & MASK32) >> (-n) end
            return (a << n) & MASK32
        end
        return bit32
    ]]
    local loader, load_err = load(native_src, "bit32_polyfill")
    if not loader then
        error("bit32 is missing and this Lua interpreter doesn't support " ..
              "native bitwise operators either (" .. tostring(load_err) .. ")")
    end
    bit32 = loader()
end

-- From http://lua-users.org/wiki/LuaUnicode
local function utf8_to_32(utf8str)
    assert(type(utf8str) == "string")
    local res, seq, val = {}, 0, nil

    for i = 1, #utf8str do
        local c = string.byte(utf8str, i)
        if seq == 0 then
            table.insert(res, val)
            seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
                  c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
                error("Invalid UTF-8 character sequence")
            val = c & (2^(8-seq) - 1)
        else
            val = (val << 6) | (c & 0x3F)
        end

        seq = seq - 1
    end

    table.insert(res, val)

    return res
end

function stringdecode.decode(str, encoding)
    local enc = encoding and encoding:lower() or "ascii"

    if enc == "ascii" then
        return str
    elseif enc == "utf-8" then
        local code_points = utf8_to_32(str)

        return utf8.char(table.unpack(code_points))
    else
        error("Encoding " .. encoding .. " not supported")
    end
end

return stringdecode
