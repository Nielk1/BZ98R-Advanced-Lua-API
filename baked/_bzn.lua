--- BZ98R LUA Extended API BZN Parser.
---
--- BZN reading logic.
--- Based on https://github.com/Nielk1/bz2-bzn_binary-format-tools
--- Try to keep any changes to the BZN format synchronized.
---
--- @module '_bzn'
--- @author John "Nielk1" Klein

local customsavetype = require("_customsavetype");
local logger = require("_logger");
local paramdb = require("_paramdb");

logger.print(logger.LogLevel.DEBUG, nil, "_bzn Loading");

--- Binary field type enum (add/adjust as needed)
--- @enum BinaryFieldType
local BinaryFieldType = {
    DATA_VOID = 0,
    DATA_BOOL = 1,
    DATA_CHAR = 2,
    DATA_SHORT = 3,
    DATA_LONG = 4,
    DATA_FLOAT = 5,
    DATA_DOUBLE = 6,
    DATA_ID = 7,
    DATA_PTR = 8,
    DATA_VEC3D = 9,
    DATA_VEC2D = 10,
    DATA_MAT3DOLD = 11,
    DATA_MAT3D = 12,
    DATA_STRING = 13,
    DATA_QUAT = 14,
    --DATA_UNKNOWN = 255
}

--- @class BZNToken
--- @field IsBinary fun(self: BZNToken): boolean
--- @field GetCount fun(self: BZNToken): integer
--- @field GetBoolean fun(self: BZNToken, index: integer?): boolean
--- @field GetInt32 fun(self: BZNToken, index: integer?): integer
--- @field GetUInt32 fun(self: BZNToken, index: integer?): integer
--- @field GetUInt32H fun(self: BZNToken, index: integer?): integer
--- @field GetUInt32Raw fun(self: BZNToken, index: integer?): integer
--- @field GetInt16 fun(self: BZNToken, index: integer?): integer
--- @field GetUInt16 fun(self: BZNToken, index: integer?): integer
--- @field GetInt8 fun(self: BZNToken, index: integer?): integer
--- @field GetUInt8 fun(self: BZNToken, index: integer?): integer
--- @field GetSingle fun(self: BZNToken, index: integer?): number
--- @field GetString fun(self: BZNToken, index: integer?): string
--- @field GetMatrixOld fun(self: BZNToken, index: integer?): Matrix
--- @field GetVector2D fun(self: BZNToken, index: integer?): Vector
--- @field GetVector3D fun(self: BZNToken, index: integer?): Vector
--- @field GetEuler fun(self: BZNToken, index: integer?): Euler
--- @field GetBytes fun(self: BZNToken, index: integer?, length: integer?): string
--- @field GetRaw fun(self: BZNToken, index: integer?, length: integer?): string
--- @field IsValidationOnly fun(self: BZNToken): boolean
--- @field Validate fun(self: BZNToken, name: string?, type: BinaryFieldType?): boolean

--- @class _bzn
local M = {};

--- @enum VEHICLE_STATE
M.VEHICLE_STATE = {
    UNDEPLOYED = 0,
    DEPLOYING = 1,
    DEPLOYED = 2,
    UNDEPLOYING = 3
};


--- Parses a little-endian float from a string.
--- @param str string
--- @param offset integer ZERO BASED index
--- @return number
local function parseFloatLE(str, offset)
    offset = (offset or 0) + 1
    local strlen = #str
    --print("parseFloatLE input:", str:gsub(".", function(c) return string.format("%02X ", string.byte(c)) end), "offset:", offset, "str length:", strlen)
    --print("parseFloatLE substring:", str:sub(offset, offset + 3):gsub(".", function(c) return string.format("%02X ", string.byte(c)) end))
    if offset + 3 > strlen then
        error(string.format("parseFloatLE: not enough bytes (offset=%d, strlen=%d)", offset, strlen))
    end
    local b1, b2, b3, b4 = str:byte(offset, offset + 3)
    local sign = bit.band(bit.rshift(b4, 7), 0x1)
    local exponent = bit.bor(bit.lshift(bit.band(b4, 0x7F), 1), bit.rshift(b3, 7))
    local mantissa = bit.bor(bit.lshift(bit.band(b3, 0x7F), 16), bit.lshift(bit.band(b2, 0xFF), 8), bit.band(b1, 0xFF))

    if exponent == 0 then
        if mantissa == 0 then
            return sign == 1 and -0.0 or 0.0
        else
            return ((-1)^sign) * (mantissa / 2^23) * 2^-126
        end
    elseif exponent == 255 then
        if mantissa == 0 then
            return sign == 1 and -math.huge or math.huge
        else
            return 0/0 -- NaN
        end
    else
        return ((-1)^sign) * (1 + mantissa / 2^23) * 2^(exponent - 127)
    end
end

-- BZNTokenBinary
local BZNTokenBinary = {}
BZNTokenBinary.__index = BZNTokenBinary
function BZNTokenBinary.new(fieldType, data)
    return setmetatable({
        type = fieldType,
        data = data,
    }, BZNTokenBinary)
end
function BZNTokenBinary:IsBinary() return true end
function BZNTokenBinary:GetCount()
    local len = #self.data
    local t = self.type
    if t == BinaryFieldType.DATA_VOID then return math.floor(len / 4)
    elseif t == BinaryFieldType.DATA_BOOL then return len
    elseif t == BinaryFieldType.DATA_CHAR then return len
    elseif t == BinaryFieldType.DATA_SHORT then return math.floor(len / 2)
    elseif t == BinaryFieldType.DATA_LONG then return math.floor(len / 4)
    elseif t == BinaryFieldType.DATA_FLOAT then return math.floor(len / 4)
    elseif t == BinaryFieldType.DATA_ID then return math.floor(len / 4)
    elseif t == BinaryFieldType.DATA_PTR then return math.floor(len / 4)
    else error("NotImplemented: GetCount for type " .. tostring(t)) end
end
function BZNTokenBinary:GetBoolean(index)
    index = (index or 0) + 1
    if index > #self.data then error("Index out of range") end
    return self.data:byte(index) ~= 0
end
function BZNTokenBinary:GetInt32(index)
    index = (index or 0)
    local offset = index * 4 + 1
    if offset + 3 > #self.data then error("Index out of range") end
    local b1, b2, b3, b4 = self.data:byte(offset, offset+3)
    return b4*0x1000000 + b3*0x10000 + b2*0x100 + b1
end
function BZNTokenBinary:GetUInt32(index)
    return self:GetInt32(index) -- Lua numbers are doubles, so this is fine
end
function BZNTokenBinary:GetInt32H(index)
    return self:GetInt32(index)
end
function BZNTokenBinary:GetUInt32H(index)
    return self:GetUInt32(index)
end
function BZNTokenBinary:GetUInt32Raw(index)
    return self:GetUInt32(index)
end
function BZNTokenBinary:GetInt16(index)
    index = (index or 0)
    local offset = index * 2 + 1
    if offset + 1 > #self.data then error("Index out of range") end
    local b1, b2 = self.data:byte(offset, offset+1)
    return b2*0x100 + b1
end
function BZNTokenBinary:GetUInt16(index)
    return self:GetInt16(index)
end
function BZNTokenBinary:GetInt8(index)
    index = (index or 0) + 1
    if index > #self.data then error("Index out of range") end
    local b = self.data:byte(index)
    return b > 127 and b - 256 or b
end
function BZNTokenBinary:GetUInt8(index)
    index = (index or 0) + 1
    if index > #self.data then error("Index out of range") end
    return self.data:byte(index)
end

function BZNTokenBinary:GetString(index)
    index = (index or 0) + 1
    if index > 1 then error("Index out of range") end
    local nul = string.find(self.data, "\0", 1, true)
    if nul then
        return self.data:sub(1, nul - 1)
    end
    return self.data
end

function BZNTokenBinary:GetSingle(index)
    index = (index or 0)
    local offset = index * 4
    if offset > #self.data then error("Index out of range") end
    return parseFloatLE(self.data, offset)
end

--- Get a 3D vector from the binary data
--- @param index integer
--- @return Vector
function BZNTokenBinary:GetVector3D(index)
    index = (index or 0)
    local base = index * 3
    if base * 4 > #self.data then error("Index out of range") end
    return SetVector(
        self:GetSingle(base + 0),
        self:GetSingle(base + 1),
        self:GetSingle(base + 2)
    )
end

--- Get a 2D vector from the binary data
--- @param index integer
--- @return Vector
function BZNTokenBinary:GetVector2D(index)
    index = (index or 0)
    local base = index * 2
    if base * 4 > #self.data then error("Index out of range") end
    return SetVector(
        self:GetSingle(base + 0),
        0,
        self:GetSingle(base + 1)
    )
end

--- Get a 2D vector from the binary data
--- @param index integer
--- @return Matrix
function BZNTokenBinary:GetMatrixOld(index)
    index = (index or 0)
    local base = index * 4
    local right  = self:GetVector3D(base + 0)
    local up     = self:GetVector3D(base + 1)
    local front  = self:GetVector3D(base + 2)
    local posit  = self:GetVector3D(base + 3)
    return SetMatrix(
        right.x, right.y, right.z,
           up.x,    up.y,    up.z,
        front.x, front.y, front.z,
        posit.x, posit.y, posit.z
    )
end

--- Get a 4x4 matrix from the binary data
--- @param index integer
--- @return Matrix
function BZNTokenBinary:GetMatrix(index)
    local rightx = self:GetSingle(index * 16 +  0)
    local righty = self:GetSingle(index * 16 +  1)
    local rightz = self:GetSingle(index * 16 +  2)
    local rightw = self:GetSingle(index * 16 +  3)
    local    upx = self:GetSingle(index * 16 +  4)
    local    upy = self:GetSingle(index * 16 +  5)
    local    upz = self:GetSingle(index * 16 +  6)
    local    upw = self:GetSingle(index * 16 +  7)
    local frontx = self:GetSingle(index * 16 +  8)
    local fronty = self:GetSingle(index * 16 +  9)
    local frontz = self:GetSingle(index * 16 + 10)
    local frontw = self:GetSingle(index * 16 + 11)
    local positx = self:GetSingle(index * 16 + 12)
    local posity = self:GetSingle(index * 16 + 13)
    local positz = self:GetSingle(index * 16 + 14)
    local positw = self:GetSingle(index * 16 + 15)
    return SetMatrix(
        rightx, righty, rightz,
           upx,    upy,    upz,
        frontx, fronty, frontz,
        positx, posity, positz
    )
end

function BZNTokenBinary:Validate(name, type)
    if not self.type then return true end
    return self.type == type
end

-- BZNTokenString
local BZNTokenString = {}
BZNTokenString.__index = BZNTokenString
function BZNTokenString.new(name, values)
    return setmetatable({
        name = name,
        values = values
    }, BZNTokenString)
end
function BZNTokenString:IsBinary() return false end
function BZNTokenString:GetCount() return #self.values end
function BZNTokenString:GetBoolean(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v == "0" then return false end
    if v == "1" then return true end
    return v == "true"
end
function BZNTokenString:GetInt32(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    return tonumber(self.values[index])
end
function BZNTokenString:GetInt32H(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    if (self.values[index]:sub(1, 1) == '-') then
        return tonumber(self.values[index]:sub(2), 16)
    end
    return tonumber(self.values[index], 16)
end
function BZNTokenString:GetUInt32(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v:sub(1, 1) == '-' then
        local signed = tonumber(v)
        if not signed then error("Invalid integer value: " .. tostring(v)) end
        return signed + 4294967296
    end
    local num = tonumber(v)
    if not num then error("Invalid UInt32 value: " .. tostring(v)) end
    return num
end
function BZNTokenString:GetUInt32H(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v:sub(1, 1) == '-' then
        local signed = tonumber(v, 16)
        if not signed then error("Invalid hex integer value: " .. tostring(v)) end
        return signed + 4294967296
    end
    local num = tonumber(v, 16)
    if not num then error("Invalid UInt32H value: " .. tostring(v)) end
    return num
end
function BZNTokenString:GetUInt32Raw(index)
    index = (index or 0)
    local raw = self:GetRaw(index * 4, 4)
    local b1, b2, b3, b4 = raw:byte(1, 4)
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end
function BZNTokenString:GetInt16(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    return tonumber(self.values[index])
end
function BZNTokenString:GetUInt16(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v:sub(1, 1) == '-' then
        local signed = tonumber(v)
        if not signed then error("Invalid integer value: " .. tostring(v)) end
        return (signed + 65536) % 65536
    end
    local num = tonumber(v)
    if not num then error("Invalid UInt16 value: " .. tostring(v)) end
    return num
end
function BZNTokenString:GetUInt16H(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v:sub(1, 1) == '-' then
        local signed = tonumber(v, 16)
        if not signed then error("Invalid hex integer value: " .. tostring(v)) end
        return (signed + 65536) % 65536
    end
    local num = tonumber(v, 16)
    if not num then error("Invalid UInt16H value: " .. tostring(v)) end
    return num
end
function BZNTokenString:GetInt8(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    return tonumber(self.values[index])
end
function BZNTokenString:GetUInt8(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v:sub(1, 1) == '-' then
        local signed = tonumber(v)
        if not signed then error("Invalid integer value: " .. tostring(v)) end
        return (signed + 256) % 256
    end
    local num = tonumber(v)
    if not num then error("Invalid UInt8 value: " .. tostring(v)) end
    return num
end
function BZNTokenString:GetSingle(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local v = self.values[index]
    if v == "-1.#QNAN" then return 0/0 end
    if v == "" then return 0 end
    return tonumber(v)
end
function BZNTokenString:GetString(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    return self.values[index]
end
--- comment Get raw bytes from the string token
--- @param index integer? ZERO BASED index
--- @param length integer? Number of bytes to read or nil
function BZNTokenString:GetRaw(index, length)
    index = (index or 0) + 1
    if #self.values > 1 then error("Invalid raw data") end
    if not length then return self.values[1] end
    return self.values[1]:sub(index, index + length - 1)
end
function BZNTokenString:IsValidationOnly() return false end
function BZNTokenString:Validate(name, type)
    if self.name == name then return true end
    return false
end

-- BZNTokenNestedString
local BZNTokenNestedString = {}
BZNTokenNestedString.__index = BZNTokenNestedString
function BZNTokenNestedString.new(name, values)
    return setmetatable({
        name = name,
        values = values
    }, BZNTokenNestedString)
end
function BZNTokenNestedString:IsBinary() return false end
function BZNTokenNestedString:GetCount() error("InvalidOperation: Nested tokens have no count") end
function BZNTokenNestedString:GetBoolean(index) error("InvalidOperation") end
function BZNTokenNestedString:GetInt32(index) error("InvalidOperation") end
function BZNTokenNestedString:GetInt32H(index)
    return self:GetInt32(index)
end
function BZNTokenNestedString:GetUInt32(index) error("InvalidOperation") end
function BZNTokenNestedString:GetUInt32H(index)
    return self:GetUInt32(index)
end
function BZNTokenNestedString:GetUInt32Raw(index)
    return self:GetUInt32(index)
end
function BZNTokenNestedString:GetInt16(index) error("InvalidOperation") end
function BZNTokenNestedString:GetUInt16(index) error("InvalidOperation") end
function BZNTokenNestedString:GetInt8(index) error("InvalidOperation") end
function BZNTokenNestedString:GetUInt8(index) error("InvalidOperation") end
function BZNTokenNestedString:GetSingle(index) error("InvalidOperation") end
function BZNTokenNestedString:GetString(index) error("InvalidOperation") end

function BZNTokenNestedString:GetVector3D(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local subToks = self.values[index]
    if not subToks[1]:Validate("x") then error("Failed to parse x") end
    if not subToks[2]:Validate("y") then error("Failed to parse y") end
    if not subToks[3]:Validate("z") then error("Failed to parse z") end
    return SetVector(
        subToks[1]:GetSingle(),
        subToks[2]:GetSingle(),
        subToks[3]:GetSingle()
    )
end

function BZNTokenNestedString:GetVector2D(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local subToks = self.values[index]
    if not subToks[1]:Validate("x") then error("Failed to parse x") end
    if not subToks[2]:Validate("z") then error("Failed to parse z") end
    return SetVector(
        subToks[1]:GetSingle(),
        0,
        subToks[2]:GetSingle()
    )
end

function BZNTokenNestedString:GetMatrixOld(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local subToks = self.values[index]
    if not subToks[1]:Validate("right_x") then error("Failed to parse right_x") end
    if not subToks[2]:Validate("right_y") then error("Failed to parse right_y") end
    if not subToks[3]:Validate("right_z") then error("Failed to parse right_z") end
    if not subToks[4]:Validate("up_x") then error("Failed to parse up_x") end
    if not subToks[5]:Validate("up_y") then error("Failed to parse up_y") end
    if not subToks[6]:Validate("up_z") then error("Failed to parse up_z") end
    if not subToks[7]:Validate("front_x") then error("Failed to parse front_x") end
    if not subToks[8]:Validate("front_y") then error("Failed to parse front_y") end
    if not subToks[9]:Validate("front_z") then error("Failed to parse front_z") end
    if not subToks[10]:Validate("posit_x") then error("Failed to parse posit_x") end
    if not subToks[11]:Validate("posit_y") then error("Failed to parse posit_y") end
    if not subToks[12]:Validate("posit_z") then error("Failed to parse posit_z") end
    return SetMatrix(
        subToks[1]:GetSingle(),  subToks[2]:GetSingle(),  subToks[3]:GetSingle(),
        subToks[4]:GetSingle(),  subToks[5]:GetSingle(),  subToks[6]:GetSingle(),
        subToks[7]:GetSingle(),  subToks[8]:GetSingle(),  subToks[9]:GetSingle(),
        subToks[10]:GetSingle(), subToks[11]:GetSingle(), subToks[12]:GetSingle()
    )
end

function BZNTokenNestedString:GetMatrix(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local subToks = self.values[index]
    if not subToks[1]:Validate("right.x") then error("Failed to parse right.x") end
    if not subToks[2]:Validate("right.y") then error("Failed to parse right.y") end
    if not subToks[3]:Validate("right.z") then error("Failed to parse right.z") end
    if not subToks[4]:Validate("up.x") then error("Failed to parse up.x") end
    if not subToks[5]:Validate("up.y") then error("Failed to parse up.y") end
    if not subToks[6]:Validate("up.z") then error("Failed to parse up.z") end
    if not subToks[7]:Validate("front.x") then error("Failed to parse front.x") end
    if not subToks[8]:Validate("front.y") then error("Failed to parse front.y") end
    if not subToks[9]:Validate("front.z") then error("Failed to parse front.z") end
    if not subToks[10]:Validate("posit.x") then error("Failed to parse posit.x") end
    if not subToks[11]:Validate("posit.y") then error("Failed to parse posit.y") end
    if not subToks[12]:Validate("posit.z") then error("Failed to parse posit.z") end
    return SetMatrix(
        subToks[1]:GetSingle(),  subToks[2]:GetSingle(),  subToks[3]:GetSingle(),
        subToks[4]:GetSingle(),  subToks[5]:GetSingle(),  subToks[6]:GetSingle(),
        subToks[7]:GetSingle(),  subToks[8]:GetSingle(),  subToks[9]:GetSingle(),
        subToks[10]:GetSingle(), subToks[11]:GetSingle(), subToks[12]:GetSingle()
    )
end

function BZNTokenNestedString:GetEuler(index)
    index = (index or 0) + 1
    if index > #self.values then error("Index out of range") end
    local subToks = self.values[index]
    if not subToks[1]:Validate("mass") then error("Failed to parse mass") end
    if not subToks[2]:Validate("mass_inv") then error("Failed to parse mass_inv") end
    if not subToks[3]:Validate("v_mag") then error("Failed to parse v_mag") end
    if not subToks[4]:Validate("v_mag_inv") then error("Failed to parse v_mag_inv") end
    if not subToks[5]:Validate("I") then error("Failed to parse I") end
    if not subToks[6]:Validate("k_i") then error("Failed to parse k_i") end
    if not subToks[7]:Validate("v") then error("Failed to parse v") end
    if not subToks[8]:Validate("omega") then error("Failed to parse omega") end
    if not subToks[9]:Validate("Accel") then error("Failed to parse Accel") end
    return {
        mass      = subToks[1]:GetSingle(),
        mass_inv  = subToks[2]:GetSingle(),
        v_mag     = subToks[3]:GetSingle(),
        v_mag_inv = subToks[4]:GetSingle(),
        I         = subToks[5]:GetSingle(),
        I_inv     = subToks[6]:GetSingle(),
        v         = subToks[7]:GetVector3D(),
        omega     = subToks[8]:GetVector3D(),
        Accel     = subToks[9]:GetVector3D()
    }
end

function BZNTokenNestedString:IsValidationOnly() return false end
function BZNTokenNestedString:Validate(name, type) return self.name == name end

-- BZNTokenValidation
local BZNTokenValidation = {}
BZNTokenValidation.__index = BZNTokenValidation
function BZNTokenValidation.new(name) return setmetatable({ name = name }, BZNTokenValidation) end
function BZNTokenValidation:IsBinary() return false end
function BZNTokenValidation:GetCount() error("Validation Tokens have no data") end
function BZNTokenValidation:GetBoolean(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetInt32(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetInt32H(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetUInt32(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetUInt32H(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetUInt32Raw(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetInt16(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetUInt16(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetInt8(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetUInt8(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetSingle(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetString(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetVector3D(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetVector2D(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetMatrixOld(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetMatrix(index) error("Validation Tokens have no data") end
function BZNTokenValidation:GetEuler(index) error("Validation Tokens have no data") end
function BZNTokenValidation:IsValidationOnly() return true end
function BZNTokenValidation:Validate(name, type) return self.name == name end



--- @class Tokenizer
--- @field data string The raw data to tokenize
--- @field pos number The current position in the token stream
--- @field marks table A stack of marked positions
--- @field binary_offset number|nil The offset at which binary mode was detected
--- @field version number|nil The version of the token stream
--- @field type_size number The size of each token type
--- @field size_size number The size of the size field
--- @field quote_strings boolean Whether to quote strings
--- @field complex_map table A map of complex token types
local Tokenizer = {}
Tokenizer.__index = Tokenizer

function Tokenizer.new(data)
    return setmetatable({
        data = data,
        pos = 1,
        marks = {}, -- stack for rewinding
        binary_offset = nil, -- set when binary mode detected
        version = nil,
        type_size = 2,
        size_size = 2,
        quote_strings = false,
        complex_map = {
            points = 2,
            pos = 3,
            v = 3,
            omega = 3,
            Accel = 3,
            euler = 9,
            dropMat = 12,
            transform = 12,
            startMat = 12,
            saveMatrix = 12,
            buildMatrix = 12,
            bumpers = 3,
            Att = 4
        }
    }, Tokenizer)
end

--- Marks the current position in the token stream
--- @param self Tokenizer
function Tokenizer:mark()
    table.insert(self.marks, self.pos)
end

--- Rewinds the token stream to the last marked position
--- @param self Tokenizer
function Tokenizer:rewind()
    if #self.marks > 0 then
        self.pos = table.remove(self.marks)
    end
end

--- Jumps to a specific position in the token stream
--- @param self Tokenizer
function Tokenizer:goto(offset)
    self.pos = offset
end

--- Checks if the token stream has reached the end
--- @param self Tokenizer
--- @return boolean
function Tokenizer:atEnd()
    return self.pos > #self.data
end

--- Checks if the token stream is in binary mode
--- @param self Tokenizer
--- @return boolean
function Tokenizer:inBinary()
    return self.binary_offset and self.pos >= self.binary_offset or false
end

--- Splits a string into a table with a maximum number of splits
--- @param str string
--- @param sep string
--- @param max integer
--- @return string[]
local function splitMax(str, sep, max)
    local result = {}
    local start = 1
    local splits = 0
    max = max or math.huge
    while splits < max - 1 do
        local s, e = string.find(str, sep, start, true)
        if not s then break end
        table.insert(result, string.sub(str, start, s - 1))
        start = e + 1
        splits = splits + 1
    end
    table.insert(result, string.sub(str, start))
    return result
end

--- Smart string split with leading space preservation
--- @param input string
--- @param count integer
--- @return string[]
local function SmartStringSplit(input, count)
    if not input then return {} end

    local trimmed = input:match("^%s*(.*)$")
    local leadingSpaceCount = #input - #trimmed

    local retVal = splitMax(trimmed, " ", count)
    retVal[1] = string.rep(" ", leadingSpaceCount) .. retVal[1]
    return retVal
end

--- Helper: ReadStringLine (Lua version)
function Tokenizer:ReadStringLine()
    if self:atEnd() then return "" end
    local start = self.pos
    local crlf = self.data:find("\r\n", self.pos, true)
    local lf = self.data:find("\n", self.pos, true)
    local line_end = crlf or lf or (#self.data + 1)
    local line = self.data:sub(self.pos, line_end - 1)
    self.pos = line_end + ((crlf and 2) or 1)
    return line
end

--- Main string token logic
--- @return BZNToken?
function Tokenizer:ReadStringToken()
    if self:atEnd() then return nil end
    while not self:atEnd() do
        local rawLine = self:ReadStringLine()
        if #rawLine > 0 then
            if rawLine:sub(1,1) == "[" and rawLine:sub(-1,-1) == "]" then
                return BZNTokenValidation.new(rawLine:sub(2, -2))
            end
            return self:ReadStringValueToken(rawLine)
        end
    end
    return nil
end

--- @return BZNToken
function Tokenizer:ReadStringValueToken(rawLine)
    if not rawLine:match(" =$") and not rawLine:find(" = ") and rawLine:find("=") then
        rawLine = rawLine:gsub("=", " = ")
    end

    local line = SmartStringSplit(rawLine, 4)
    if line[2] == "=" then
        line = splitMax(rawLine, " ", 3);
        local name = line[1]

        -- Indented children detection
        local countIndentedLines = 0
        local seenKeys = {}
        local offsetStartChildren = self.pos
        local countSpacesHead = 0
        while true do
            local nextRawLine = self:ReadStringLine()
            if nextRawLine:match("^ +") and nextRawLine:find("=") then
                local countSpacesHead2 = #nextRawLine - #nextRawLine:match("^%s*(.*)$")
                if countSpacesHead == 0 then countSpacesHead = countSpacesHead2 end
                local key = nextRawLine:match("([^= %[%.]+)"):gsub("%s+$", "")
                if countSpacesHead == countSpacesHead2 and not seenKeys[key] then
                    seenKeys[key] = true
                    countIndentedLines = countIndentedLines + 1
                    self:ReadStringValueToken(nextRawLine) -- parse but discard
                else
                    self.pos = offsetStartChildren
                    break
                end
            else
                self.pos = offsetStartChildren
                break
            end
        end

        if countIndentedLines == 0 and self.complex_map[name] then
            countIndentedLines = self.complex_map[name]
        end

        if countIndentedLines > 0 then
            local count = 1
            local values = {}
            for subSectionCounter = 1, count do
                values[subSectionCounter] = {}
                for constructCounter = 1, countIndentedLines do
                    local rawLineInner = self:ReadStringLine():gsub("[\r\n]+$", ""):match("^%s*(.*)$")
                    if #rawLineInner > 0 then
                        values[subSectionCounter][constructCounter] = self:ReadStringValueToken(rawLineInner)
                    end
                end
            end
            return BZNTokenNestedString.new(name, values)
        else
            if #line == 2 then
                return BZNTokenString.new(name, { "" })
            end
            local value = line[3]
            if self.quote_strings then
                value = value:match('^"(.-)"$') or value
            end
            return BZNTokenString.new(name, { value })
        end
    elseif line[3] == "=" then
        -- Array value
        local name = line[1]
        local count = tonumber(line[2]:match("%[(%d+)%]")) or 0
        if count == 0 then return BZNTokenString.new(name, {}) end

        local countIndentedLines = 0
        local seenKeys = {}
        local offsetStartChildren = self.pos
        local countSpacesHead = 0
        while true do
            local nextRawLine = self:ReadStringLine()
            if nextRawLine:match("^ +") and nextRawLine:find("=") then
                local countSpacesHead2 = #nextRawLine - #nextRawLine:match("^%s*(.*)$")
                if countSpacesHead == 0 then countSpacesHead = countSpacesHead2 end
                local key = nextRawLine:match("([^= %[%.]+)"):gsub("%s+$", "")
                if countSpacesHead == countSpacesHead2 and not seenKeys[key] then
                    seenKeys[key] = true
                    countIndentedLines = countIndentedLines + 1
                    self:ReadStringValueToken(nextRawLine) -- parse but discard
                else
                    self.pos = offsetStartChildren
                    break
                end
            else
                self.pos = offsetStartChildren
                break
            end
        end

        if countIndentedLines == 0 and self.complex_map[name] then
            countIndentedLines = self.complex_map[name]
        end

        if countIndentedLines > 0 then
            local values = {}
            for subSectionCounter = 1, count do
                values[subSectionCounter] = {}
                for constructCounter = 1, countIndentedLines do
                    local rawLineInner = self:ReadStringLine():gsub("[\r\n]+$", ""):match("^%s*(.*)$")
                    if #rawLineInner > 0 then
                        values[subSectionCounter][constructCounter] = self:ReadStringValueToken(rawLineInner)
                    end
                end
            end
            return BZNTokenNestedString.new(name, values)
        else
            local values = {}
            for lineNum = 1, count do
                local new_pos = self.pos
                local new_rawLine = self:ReadStringLine():gsub("[\r\n]+$", "")
                local new_line = SmartStringSplit(new_rawLine:match("^%s*(.*)$"), 4)
                if (#new_line > 1 and new_line[2] == "=") or (#new_line > 2 and new_line[3] == "=") then
                    values[lineNum] = ""
                    self.pos = new_pos
                else
                    values[lineNum] = new_rawLine
                end
            end
            return BZNTokenString.new(name, values)
        end
    else
        error('Error reading ASCII data, "=" not found where expected.')
    end
end

--- Binary token logic (updated for alignment/padding)
--- @return BZNToken?
function Tokenizer:ReadBinaryToken()
    if self:atEnd() then return nil end
    local start = self.pos

    -- read the first byte of the type, which is all that's used
    -- by BZ1 even though it wastes 2 whole bytes to save it
    local type = string.byte(self.data, self.pos)

    -- advance by the type size
    self.pos = self.pos + self.type_size

    -- read the size, which is more bytes
    local size = string.byte(self.data, self.pos)
    for i = 1, self.size_size - 1 do
        size = bit.bor(size, bit.lshift(string.byte(self.data, self.pos + i), 8 * i))
    end

    -- advance by the size size
    self.pos = self.pos + self.size_size

    -- read the value as string (byte array)
    local value = self.data:sub(self.pos, self.pos + size - 1)

    -- advanced by the size
    self.pos = self.pos + size

    return BZNTokenBinary.new(type, value)
end

--- @param name string
--- @return integer
function Tokenizer:ReadBZ1_PtrDepricated(name)
    local tok

    if self:inBinary() then
        -- untested
        tok = self:ReadToken();
        if not tok or not tok:Validate(name, BinaryFieldType.DATA_VOID) then
            error(string.format("Failed to parse %s/PTR", name or "???"));
        end
        return tok:GetUInt32H();
    else
        -- untested
        tok = self:ReadToken();
        if not tok or not tok:Validate(name, BinaryFieldType.DATA_VOID) then
            error(string.format("Failed to parse %s/PTR", name or "???"));
        end
        --return tok:GetUInt32H()
        return tok:GetUInt32Raw() -- might be only version 1001 of BZ1
    end
end

--- @param name string
--- @return integer
function Tokenizer:ReadBZ1_Ptr(name)
    local tok
    
    tok = self:ReadToken();
    if not tok or not tok:Validate(name, BinaryFieldType.DATA_PTR) then
        error(string.format("Failed to parse %s/PTR", name or "???"));
    end
    return tok:GetUInt32H();
end

function Tokenizer:GetAiCmdInfo()
    local retVal = {}

    local tok = self:ReadToken()
    if not tok or not tok:Validate("priority", BinaryFieldType.DATA_LONG) then error("Failed to parse priority/LONG") end
    retVal.priority = tok:GetUInt32()

    tok = self:ReadToken()
    if not tok or not tok:Validate("what", BinaryFieldType.DATA_VOID) then error("Failed to parse what/VOID") end

    tok = self:ReadToken()
    if not tok or not tok:Validate("who", BinaryFieldType.DATA_LONG) then error("Failed to parse who/LONG") end
    retVal.who = tok:GetInt32()

    tok = self:ReadToken()
    if self.version == 1001 or self.version == 1011 or self.version == 1012 then
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then error("Failed to parse undefptr/PTR") end
    else
        if not tok or not tok:Validate("where", BinaryFieldType.DATA_PTR) then error("Failed to parse where/PTR") end
    end
    retVal.where = tok:GetUInt32H()

    -- param parsing can be rather broken, it's handled in the C# parser but here it's a bit crude at least for now until we learn more
    tok = self:ReadToken()
    if self.version >= 2012 then
        if not tok or not tok:Validate("param", BinaryFieldType.DATA_ID) then error("Failed to parse param/ID") end
        local tmp = tok:GetString()
        if tmp == "" then
            retVal.param = 0
        else
            --param = tok.GetUInt32();

            --local raw = tok:GetRaw(0, 8)
            local raw = tok:GetRaw(0, nil)
            -- this value is just completely fucked up if it's longer than 6 bytes
            if #raw > 6 then
                retVal.param = raw -- just store the string, I hate my life
            else
                retVal.param = 0
                for i = 1, #raw do
                    retVal.param = retVal.param + raw:byte(i) * 2^((i - 1) * 8)
                end
            end
        end
    else
        if not tok or not tok:Validate("param", BinaryFieldType.DATA_LONG) then error("Failed to parse param/LONG") end
        retVal.param = tok:GetUInt32()
    end

    return retVal
end

function Tokenizer:GetEuler()
    if self:inBinary() then
        local tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_mass = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_mass_inv = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_v_mag = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_v_mag_inv = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_I = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse euler's FLOAT");
        end
        local euler_k_i = tok:GetSingle();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_VEC3D) then
            error("Failed to parse euler's VEC3D");
        end
        local euler_v = tok:GetVector3D();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_VEC3D) then
            error("Failed to parse euler's VEC3D");
        end
        local euler_omega = tok:GetVector3D();

        tok = self:ReadToken();
        if not tok or not tok:Validate(nil, BinaryFieldType.DATA_VEC3D) then
            error("Failed to parse euler's VEC3D");
        end
        local euler_Accel = tok:GetVector3D();

        local euler = {
            mass = euler_mass,
            mass_inv = euler_mass_inv,
            v_mag = euler_v_mag,
            v_mag_inv = euler_v_mag_inv,
            I = euler_I,
            I_inv = euler_k_i,
            v = euler_v,
            omega = euler_omega,
            Accel = euler_Accel
        };

        return euler;
    else
        local tok = self:ReadToken()
        if not tok or not tok:Validate("euler") then
            error("Failed to parse euler/VOID");
        end
        return tok:GetEuler();
    end
end

--- @return BZNToken?
function Tokenizer:ReadToken()
    if self:atEnd() then return nil end
    if self:inBinary() then
        return self:ReadBinaryToken()
    else
        return self:ReadStringToken()
    end
end




local ClassReaders = {};

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.ammopack = function(go, reader, extend)
    local obj = extend or {}
    local tok

    ClassReaders.powerup(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.apc = function(go, reader, extend)
    local obj = extend or {}
    local tok;

    tok = reader:ReadToken();
    if not tok or not tok:Validate("soldierCount", BinaryFieldType.DATA_LONG) then
        error("Failed to parse soldierCount/LONG");
    end
    obj.soldierCount = tok:GetInt32()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("state", BinaryFieldType.DATA_VOID) then
        error("Failed to parse state/VOID");
    end
    obj.state = tok:GetUInt32() -- state --- @todo (VEHICLE_STATE)

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.armory = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.producer(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.barracks = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.i76building = function(go, reader, extend)
    local obj = extend or {};
    local tok;

    obj.tempBuilding = false;

    ClassReaders.gameobject(go, reader, obj)

    return obj
end
ClassReaders.i76building2 = ClassReaders.i76building;
ClassReaders.i76sign = ClassReaders.i76building;
ClassReaders.repairdepot = ClassReaders.i76building;
ClassReaders.artifact = ClassReaders.i76building;

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.camerapod = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.powerup(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.commtower = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.constructionrig = function(go, reader, extend)
    local obj = extend or {};
    local tok;

    if reader.version > 1030 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("dropMat", BinaryFieldType.DATA_MAT3DOLD) then error("Failed to parse dropMat/MAT3DOLD") end
        obj.dropMat = tok:GetMatrixOld()

        tok = reader:ReadToken();
        if not tok or not tok:Validate("dropClass", BinaryFieldType.DATA_ID) then error("Failed to parse dropClass/ID") end
        obj.dropClass = tok:GetString()

        if reader.version >= 2001 then
            tok = reader:ReadToken();
            --if (!tok:Validate("lastRecycled", BinaryFieldType.DATA_FLOAT)) throw new Exception("Failed to parse lastRecycled/FLOAT");
            if not tok or not tok:Validate("lastRecycled", BinaryFieldType.DATA_LONG) then error("Failed to parse lastRecycled/LONG") end
            --lastRecycled = tok:GetSingle();
        end
    else
        obj.dropMat = obj.transform
    end

    ClassReaders.producer(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.craft = function(go, reader, extend)
    local obj = extend or {};
    local tok;

    if reader.version < 1019 then
        -- obsolete
        if reader.version > 1001 then
            tok = reader:ReadToken() -- energy0current
            tok = reader:ReadToken() -- energy0maximum
            tok = reader:ReadToken() -- energy1current
            tok = reader:ReadToken() -- energy1maximum
            tok = reader:ReadToken() -- energy2current
            tok = reader:ReadToken() -- energy2maximum

            tok = reader:ReadToken() -- bumpers
        else
            tok = reader:ReadToken() -- bumpers or armor, 24 0x00s raw
            tok = reader:ReadToken() -- bumpers, 6 VEC3
        end
    end

    if reader.version > 1027 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("abandoned", BinaryFieldType.DATA_LONG) then
            error("Failed to parse abandoned/LONG")
        end
        obj.abandoned = tok:GetInt32()
    end

    -- guesses: omit version 2016, 2011
    if reader.version >= 2000 then
        if reader.version < 2002 then
            tok = reader:ReadToken()
            if not tok or not tok:Validate("cloakTransitionTime", BinaryFieldType.DATA_FLOAT) then
                error("Failed to parse cloakTransitionTime/FLOAT")
            end
            local cloakTransitionTime = tok:GetSingle()
        end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("cloakState", BinaryFieldType.DATA_VOID) then
            error("Failed to parse cloakState/VOID")
        end
        local cloakState = tok:GetUInt32H()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("cloakTransBeginTime", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse cloakTransBeginTime/FLOAT")
        end
        local cloakTransBeginTime = tok:GetSingle()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("cloakTransEndTime", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse cloakTransEndTime/FLOAT")
        end
        local cloakTransEndTime = tok:GetSingle()
    end

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.daywrecker = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.powerup(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.factory = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.producer(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.flare = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.mine(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table?
ClassReaders.gameobject = function(go, reader, extend)
    local obj = extend or {}
    local tok;

    tok = reader:ReadToken();
    if not tok or not tok:Validate("illumination", BinaryFieldType.DATA_FLOAT) then error("Failed to parse illumination/FLOAT") end
    obj.illumination = tok:GetSingle()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("pos", BinaryFieldType.DATA_VEC3D) then error("Failed to parse pos/VEC3D") end
    obj.pos = tok:GetVector3D()

    obj.euler = reader:GetEuler()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("seqNo", BinaryFieldType.DATA_LONG) then error("Failed to parse seqNo/LONG") end
    --seqNo = tok:GetUInt16();
    obj.seqNo = tok:GetUInt32()

    -- broke this section, need to fix it
    if reader.version > 1030 then
        if reader.version < 1145 then
            tok = reader:ReadToken();
            if not tok or not tok:Validate("name", BinaryFieldType.DATA_CHAR) then error("Failed to parse name/CHAR") end
            obj.name = tok:GetString()
        else
            tok = reader:ReadToken();
            if not tok or not tok:Validate("name", BinaryFieldType.DATA_CHAR) then error("Failed to parse name/CHAR") end
            obj.name = tok:GetString()
        end
    end

    local saveFlags = 0

    if (reader.version >= 1046 and reader.version < 2000) or reader.version >= 2010 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("isCritical", BinaryFieldType.DATA_BOOL) then error("Failed to parse isCritical/BOOL") end
        --isCritical = tok:GetBoolean();
    end

    if reader.version == 1001 or reader.version == 1011 or reader.version == 1012 or reader.version == 1017 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("liveColor") then error("Failed to parse liveColor/UNKNOWN") end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("deadColor") then error("Failed to parse deadColor/UNKNOWN") end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("teamNumber") then error("Failed to parse teamNumber/UNKNOWN") end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("teamSlot") then error("Failed to parse teamSlot/UNKNOWN") end
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("isObjective", BinaryFieldType.DATA_BOOL) then error("Failed to parse isObjective/BOOL") end
    obj.isObjective = tok:GetBoolean()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("isSelected", BinaryFieldType.DATA_BOOL) then error("Failed to parse isSelected/BOOL") end
    obj.isSelected = tok:GetBoolean()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("isVisible", BinaryFieldType.DATA_LONG) then error("Failed to parse isVisible/LONG") end
    obj.isVisible = tok:GetUInt32H()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("seen", BinaryFieldType.DATA_LONG) then error("Failed to parse seen/LONG") end
    local seen = tok:GetUInt32H()
    if bit.band(seen, 0xFFFF0000) ~= 0 then
        local HasSignBit = bit.band(seen, 0x80000000) ~= 0
        local HasOtherOverflowBits = bit.band(seen, 0x7FFF0000) ~= 0
        if HasSignBit and not HasOtherOverflowBits then
            if HasSignBit and not HasOtherOverflowBits then
                -- issue was caused by a bad sign bit forcing a mis-write of the data as a decimal number instead of hex
                -- TODO note malformation
                seen = bit.band(seen, 0x0000FFFF)
            else
                -- issue is undetermined other than it being decimal instead of hex
                -- TODO note malformation
            end
        elseif not tok.IsBinary and tok:GetString():find("[^1234567890]") then
            -- assume this is a decimal number instead of hex
            seen = tok:GetUInt32()
            HasSignBit = bit.band(seen, 0x80000000) ~= 0
            HasOtherOverflowBits = bit.band(seen, 0x7FFF0000) ~= 0
            if HasSignBit and not HasOtherOverflowBits then
                -- issue was caused by a bad sign bit forcing a mis-write of the data as a decimal number instead of hex
                -- TODO note malformation
                seen = bit.band(seen, 0x0000FFFF)
            else
                -- issue is undetermined other than it being decimal instead of hex
                -- TODO note malformation
            end
        else
            -- TODO note malformation
        end
    end
    obj.seen = seen

    --[10:03:38 PM] Kenneth Miller: I think I may have figured out what that stuff is, maybe
    --[10:03:50 PM] Kenneth Miller: They're timestamps
    --[10:04:04 PM] Kenneth Miller: playerShot, playerCollide, friendShot, friendCollide, enemyShot, groundCollide
    --[10:04:13 PM] Kenneth Miller: the default value is -HUGE_NUMBER (-1e30)
    --[10:04:26 PM] Kenneth Miller: And due to the nature of the game, groundCollide is the most likely to get set first
    --[10:05:02 PM] Kenneth Miller: Old versions of the mission format used to contain those values but later versions only include them in the savegame
    --[10:05:05 PM] Kenneth Miller: (not the mission)
    --[10:05:31 PM] Kenneth Miller: (version 1033 was where they were removed from the mission)
    if reader.version < 1033 then
        tok = reader:ReadToken() -- float (-HUGE_NUMBER) -- playerShot
        tok = reader:ReadToken() -- float (-HUGE_NUMBER) -- playerCollide
        tok = reader:ReadToken() -- float (-HUGE_NUMBER) -- friendShot
        tok = reader:ReadToken() -- float (-HUGE_NUMBER) -- friendCollide
        tok = reader:ReadToken() -- float (-HUGE_NUMBER) -- enemyShot
        tok = reader:ReadToken() -- float                -- groundCollide
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("healthRatio", BinaryFieldType.DATA_FLOAT) then error("Failed to parse healthRatio/FLOAT") end
    obj.healthRatio = tok:GetSingle()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("curHealth", BinaryFieldType.DATA_LONG) then error("Failed to parse curHealth/LONG") end
    obj.curHealth = tok:GetUInt32()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("maxHealth", BinaryFieldType.DATA_LONG) then error("Failed to parse maxHealth/LONG") end
    obj.maxHealth = tok:GetUInt32()

    if reader.version < 1015 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("heatRatio", BinaryFieldType.DATA_FLOAT) then error("Failed to parse heatRatio/FLOAT") end
        local heatRatio = tok:GetSingle()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("curHeat", BinaryFieldType.DATA_LONG) then error("Failed to parse curHeat/LONG") end
        local curHeat = tok:GetInt32()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("maxHeat", BinaryFieldType.DATA_LONG) then error("Failed to parse maxHeat/LONG") end
        local maxHeat = tok:GetInt32()
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("ammoRatio", BinaryFieldType.DATA_FLOAT) then error("Failed to parse ammoRatio/FLOAT") end
    obj.ammoRatio = tok:GetSingle()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("curAmmo", BinaryFieldType.DATA_LONG) then error("Failed to parse curAmmo/LONG") end
    obj.curAmmo = tok:GetInt32()

    tok = reader:ReadToken()
    if not tok or not tok:Validate("maxAmmo", BinaryFieldType.DATA_LONG) then error("Failed to parse maxAmmo/LONG") end
    obj.maxAmmo = tok:GetInt32()

    -- start read of AiCmdInfo
    if reader.version == 1001 or reader.version == 1011 or reader.version == 1012 then
        obj.curCmd = reader:GetAiCmdInfo();
    end
    obj.nextCmd = reader:GetAiCmdInfo();
    -- end read of AiCmdInfo

    -- aiProcess?
    if reader.version == 1001 or reader.version == 1011 or reader.version == 1012 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_BOOL) then error("Failed to parse aiProcess/BOOL") end
        obj.aiProcess = tok:GetUInt32H() ~= 0
    elseif reader.version ~= 1017 and reader.version ~= 1018 then -- TODO get range for these
        tok = reader:ReadToken()
        if not tok or not tok:Validate("aiProcess", BinaryFieldType.DATA_BOOL) then error("Failed to parse aiProcess/BOOL") end
        obj.aiProcess = tok:GetBoolean()
    end

    if reader.version > 1007 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("isCargo", BinaryFieldType.DATA_BOOL) then error("Failed to parse isCargo/BOOL") end
        obj.isCargo = tok:GetBoolean()
    end

    if reader.version > 1016 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("independence", BinaryFieldType.DATA_LONG) then error("Failed to parse independence/LONG") end
        obj.independence = tok:GetUInt32()
    end

    if reader.version > 1016 then
        if reader.version < 1030 then
            tok = reader:ReadToken()
            if not tok or not tok:Validate("hasPilot", BinaryFieldType.DATA_BOOL) then error("Failed to parse hasPilot/BOOL") end
            local hasPilot = tok:GetBoolean()
            if obj ~= nil then obj.curPilot = hasPilot and (obj.isUser and (go.PrjID:sub(1, 1) .. "suser") or (go.PrjID:sub(1, 1) .. "spilo")) or "" end
        else
            tok = reader:ReadToken()
            if not tok or not tok:Validate("curPilot", BinaryFieldType.DATA_ID) then error("Failed to parse curPilot/ID") end
            if obj ~= nil then obj.curPilot = tok:GetString() end
        end
    end

    if reader.version > 1031 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("perceivedTeam", BinaryFieldType.DATA_LONG) then error("Failed to parse perceivedTeam/LONG") end
        obj.perceivedTeam = tok:GetInt32()
    else
        obj.perceivedTeam = -1
    end

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.geyser = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.repairkit = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.powerup(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.hover = function(go, reader, extend)
    local obj = extend or {}

    if reader.version > 1001 and reader.version < 1026 then
        reader:ReadToken(); --- @todo is this line an error?
        reader:ReadToken(); -- accelDragStop
        reader:ReadToken(); -- accelDragFull
        reader:ReadToken(); -- alphaTrack
        reader:ReadToken(); -- alphaDamp
        reader:ReadToken(); -- pitchPitch
        reader:ReadToken(); -- pitchThrust
        reader:ReadToken(); -- rollStrafe
        reader:ReadToken(); -- rollSteer
        reader:ReadToken(); -- velocForward
        reader:ReadToken(); -- velocReverse
        reader:ReadToken(); -- velocStrafe
        reader:ReadToken(); -- accelThrust
        reader:ReadToken(); -- accelBrake
        reader:ReadToken(); -- omegaSpin
        reader:ReadToken(); -- omegaTurn
        reader:ReadToken(); -- alphaSteer
        reader:ReadToken(); -- accelJump
        reader:ReadToken(); -- thrustRatio
        reader:ReadToken(); -- throttle
        reader:ReadToken(); -- airBorne
    end

    ClassReaders.craft(go, reader, obj)
    
    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.howitzer = function(go, reader, extend)
    local obj = extend or {};

    if reader.version < 1020 then
        ClassReaders.hover(go, reader, obj)
        return obj
    end

    ClassReaders.turrettank(go, reader, obj)
    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.magnet = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.mine(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.mine = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.minelayer = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.person = function(go, reader, extend)
    local obj = extend or {}
    local tok

    tok = reader:ReadToken()
    if not tok or not tok:Validate("nextScream", BinaryFieldType.DATA_FLOAT) then
        error("Failed to parse nextScream/FLOAT")
    end
    if obj then obj.nextScream = tok:GetSingle() end

    ClassReaders.craft(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.portal = function(go, reader, extend)
    local obj = extend or {}
    local tok

    if reader.version >= 2004 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("portalState", BinaryFieldType.DATA_LONG) then
            error("Failed to parse portalState/LONG")
        end
        local portalState = tok:GetUInt32H()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("portalBeginTime", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse portalBeginTime/FLOAT")
        end
        local portalBeginTime = tok:GetSingle()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("portalEndTime", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse portalEndTime/FLOAT")
        end
        local portalEndTime = tok:GetSingle()

        tok = reader:ReadToken()
        if not tok or not tok:Validate("isIn", BinaryFieldType.DATA_BOOL) then
            error("Failed to parse isIn/BOOL")
        end
        local isIn = tok:GetBoolean()
    end

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.powerplant = function(go, reader, extend)
    local obj = extend or {};

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.powerup = function(go, reader, extend)
    local obj = extend or {}
    local tok

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.producer = function(go, reader, extend)
    local obj = extend or {}
    local tok;

    if reader.version < 1011 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("setAltitude", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse setAltitude/FLOAT");
        end
        local setAltitude = tok:GetSingle();
    end

    if reader.version ~= 1042 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("timeDeploy", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse timeDeploy/FLOAT");
        end
        if obj then obj.timeDeploy = tok:GetSingle(); end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("timeUndeploy", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse timeUndeploy/FLOAT");
        end
        if obj then obj.timeUndeploy = tok:GetSingle(); end
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
        error("Failed to parse undefptr/PTR");
    end
    if obj then obj.undefptr2 = tok:GetUInt32H(); end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("state", BinaryFieldType.DATA_VOID) then
        error("Failed to parse state/VOID");
    end
    --state = tok:GetBytes(0, 4); // probably need to reverse for n64
    if obj then obj.state = tok:GetUInt32(); end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("delayTimer", BinaryFieldType.DATA_FLOAT) then
        error("Failed to parse delayTimer/FLOAT");
    end
    if obj then obj.delayTimer = tok:GetSingle(); end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("nextRepair", BinaryFieldType.DATA_FLOAT) then
        error("Failed to parse nextRepair/FLOAT");
    end
    if obj then obj.nextRepair = tok:GetSingle(); end

    if reader.version >= 1006 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("buildClass", BinaryFieldType.DATA_ID) then
            error("Failed to parse buildClass/ID");
        end
        if obj then obj.buildClass = tok:GetString(); end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("buildDoneTime", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse buildDoneTime/FLOAT");
        end
        if obj then obj.buildDoneTime = tok:GetSingle(); end

        if reader.version <= 1026 then
            -- dummied out and unused
            reader:ReadToken() -- buildCost [1] =
                               -- -842150451
            reader:ReadToken() -- buildUpdateTime [1] =
                               -- -4.31602e+008
            reader:ReadToken() -- buildDt [1] =
                               -- -4.31602e+008
            reader:ReadToken() -- buildDc [1] =
                               -- -842150451
        end
    end

    if reader.version <= 1010 then
        ClassReaders.craft(go, reader, obj)
        return obj
    end
    ClassReaders.hover(go, reader, obj)
    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.proximity = function(go, reader, extend)
    local obj = extend or {}
    local tok

    ClassReaders.mine(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.recycler = function(go, reader, extend)
    local obj = extend or {}
    local tok

    tok = reader:ReadToken()
    if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
        error("Failed to parse undefptr/PTR")
    end
    obj.undefptr = tok:GetUInt32H() --- @todo what is this?

    ClassReaders.producer(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.sav = function(go, reader, extend)
    local obj = extend or {}
    local tok

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.scavenger = function(go, reader, extend)
    local obj = extend or {}
    local tok

    if (reader.version >= 1039 and reader.version < 2000) or reader.version > 2004 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("scrapHeld", BinaryFieldType.DATA_LONG) then
            error("Failed to parse scrapHeld/LONG")
        end
        if obj then obj.scrapHeld = tok:GetUInt32() end
    end

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.scrap = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.scrapfield = function(go, reader, extend)
    local obj = extend or {}
    local tok
    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.scrapsilo = function(go, reader, extend)
    local obj = extend or {}
    local tok

    if reader.version > 1020 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/LONG")
        end
        if obj then obj.undefptr = tok:GetUInt32H() end
    end

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.shieldtower = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.spawnpnt = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.gameobject(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.spraybomb = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.supplydepot = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.i76building(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.torpedo = function(go, reader, extend)
    local obj = extend or {}

    if reader.version < 1031 then
        if reader.version < 1019 then
            -- obsolete
            reader:ReadToken()
            reader:ReadToken()
            reader:ReadToken()
            reader:ReadToken()
            reader:ReadToken()
            reader:ReadToken()

            local tok = reader:ReadToken()
            if not tok or not tok:Validate(nil, BinaryFieldType.DATA_VEC3D) then
                error("Failed to parse ???/VEC3D");
            end
            -- there are 6 vectors here, but we don't know what they are for and are probably able to be forgotten
        elseif reader.version > 1027 then
            -- read in abandoned flag
            reader:ReadToken();
        end
    end

    if reader.version < 1031 then
        ClassReaders.gameobject(go, reader, obj)
        return obj;
    end

    ClassReaders.powerup(go, reader, obj)
    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.tug = function(go, reader, extend)
    local obj = extend or {}
    local tok

    tok = reader:ReadToken();
    if reader.version == 1045 then
        -- This is due to bvapc26, assumed to be a tug,in "bdmisn26.bzn"
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            if not tok or not tok:Validate("state", BinaryFieldType.DATA_PTR) then
                error("Failed to parse undefptr/state/PTR");
            end
        end
    else
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/PTR");
        end
    end
    obj.undefptr = tok:GetUInt32H(); -- cargo

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.turret = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.craft(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.turrettank = function(go, reader, extend)
    local obj = extend or {}
    local tok

    if reader.version > 1000 then
        if reader.version ~= 1042 then
            -- obsolete

            tok = reader:ReadToken();
            if not tok or not tok:Validate("undeffloat", BinaryFieldType.DATA_FLOAT) then error("Failed to parse undeffloat/FLOAT") end
            if obj then obj.omegaTurret = tok:GetSingle() end -- omegaTurret

            tok = reader:ReadToken();
            if not tok or not tok:Validate("undeffloat", BinaryFieldType.DATA_FLOAT) then error("Failed to parse undeffloat/FLOAT") end
            if obj then obj.alphaTurret = tok:GetSingle() end -- alphaTurret

            tok = reader:ReadToken();
            if not tok or not tok:Validate("undeffloat", BinaryFieldType.DATA_FLOAT) then error("Failed to parse undeffloat/FLOAT") end
            if obj then obj.timeDeploy = tok:GetSingle() end -- timeDeploy

            tok = reader:ReadToken();
            if not tok or not tok:Validate("undeffloat", BinaryFieldType.DATA_FLOAT) then error("Failed to parse undeffloat/FLOAT") end
            if obj then obj.timeUndeploy = tok:GetSingle() end -- timeUndeploy
        end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undefraw", BinaryFieldType.DATA_VOID) then error("Failed to parse undefraw/VOID") end
        if obj then obj.state = tok:GetUInt32() end -- state

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undeffloat", BinaryFieldType.DATA_FLOAT) then error("Failed to parse undeffloat/FLOAT") end
        if obj then obj.delayTimer = tok:GetSingle() end -- delayTimer

        if reader.version ~= 1042 then
            -- obsolete

            tok = reader:ReadToken();
            if not tok or not tok:Validate("undefbool", BinaryFieldType.DATA_BOOL) then error("Failed to parse undefbool/BOOL") end
            if obj then obj.wantTurret = tok:GetBoolean() end -- wantTurret
        end
    end

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.walker = function(go, reader, extend)
    local obj = extend or {}
    
    if reader.version > 1001 and reader.version < 1026 then
        -- junk hovercraft params
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
        reader:ReadToken();
    end

    ClassReaders.craft(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.weaponmine = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.mine(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.wpnpower = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.powerup(go, reader, obj)

    return obj
end

--- @param reader Tokenizer
--- @param extend table?
--- @return table
ClassReaders.wingman = function(go, reader, extend)
    local obj = extend or {}

    ClassReaders.hover(go, reader, obj)

    return obj
end

--- Hydrate a GameObject from the BZN
--- @param reader Tokenizer
--- @return GameObjectWrapper
local function HydrateGameObject(reader)
    local obj = {}
    local tok

    if not reader:inBinary() then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("GameObject") then
            error("Failed to parse [GameObject]")
        end
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("PrjID", BinaryFieldType.DATA_ID) then
        error("Failed to parse [PrjID]")
    end
    obj.PrjID = tok:GetString()
    if reader.version == 1001 then
        local nul = string.find(obj.PrjID, "\0", 1, true)
        if nul then
            obj.PrjID = obj.PrjID:sub(1, nul - 1)
        end
    end

    local classlabel = paramdb.GetClassLabel(obj.PrjID .. ".odf")
    if not classlabel then
        error(string.format("Object [%s] not found", obj.PrjID))
    end

    tok = reader:ReadToken()
    if not tok or not tok:Validate("seqno", BinaryFieldType.DATA_SHORT) then
        error("Failed to parse [seqno]")
    end
    obj.seqNo = tok:GetUInt16()
    --print(tostring(obj.seqNo) .. ": " .. obj.PrjID .. " (" .. classlabel .. ")")

    tok = reader:ReadToken();
    if not tok or not tok:Validate("pos", BinaryFieldType.DATA_VEC3D) then
        error("Failed to parse pos/VEC3D")
    end
    obj.pos = tok:GetVector3D()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("team", BinaryFieldType.DATA_LONG) then
        error("Failed to parse team/LONG")
    end
    obj.team = tok:GetUInt32()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("label", BinaryFieldType.DATA_CHAR) then
        error("Failed to parse label/CHAR")
    end
    obj.label = tok:GetString()

    tok = reader:ReadToken();
    if not tok or not tok:Validate("isUser", BinaryFieldType.DATA_LONG) then
        error("Failed to parse isUser/LONG")
    end
    local isUser = tok:GetUInt32()
    obj.isUser = isUser ~= 0

    if reader.version < 1002 then
        obj.obj_addr = reader:ReadBZ1_PtrDepricated("obj_addr") -- string name unconfirmed
    else
        obj.obj_addr = reader:ReadBZ1_Ptr("obj_addr")
    end

    if reader.version > 1001 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("transform", BinaryFieldType.DATA_MAT3DOLD) then
            error("Failed to parse transform/MAT3DOLD");
        end
        if obj then obj.transform = tok:GetMatrixOld(); end
    end

    local HydrateClass = ClassReaders[classlabel];
    if not HydrateClass then
        error(string.format("No builder found for classlabel [%s]", classlabel))
    end

    --print("Hydrating " .. tostring(obj.seqNo) .. " " .. obj.PrjID .. " as " .. classlabel)

    obj.gameObject = HydrateClass(obj, reader)

    return obj
end

--- Hydrate a BZN file
--- @param bzn FileReferenceBZN
--- @param reader Tokenizer
local function Hydrate(bzn, reader)
    local tok;

    -- get count of GameObjects
    tok = reader:ReadToken()
    if not tok or not tok:Validate("size", BinaryFieldType.DATA_LONG) then
        error("Failed to parse size/LONG")
    end
    local CountItems = tok:GetInt32()
    --print(string.format("size: %d", CountItems))

    -- TODO hoist this up to property and ensure we can scan it for Malformations to be able to do a "has malformations" check
    -- malformations, depending on what kind, might also let us rank mulitple options when the class is unclear
    local GameObjects = {}
    for gameObjectCounter = 1, CountItems do
        --print(string.format("Hydrating GameObject %d of %d", gameObjectCounter, CountItems))
        GameObjects[gameObjectCounter] = HydrateGameObject(reader)
    end

    bzn.entities = GameObjects;

    tok = reader:ReadToken();
    if not tok or not tok:Validate("name", BinaryFieldType.DATA_CHAR) then
        error("Failed to parse name/CHAR");
    end
    --print(string.format("Mission: %s", tok.GetString()));
    bzn.Mission = tok:GetString();

    -- read the old sObject ptr, not sure what can be done with it
    if reader.version < 1002 then
        local sObject = reader:ReadBZ1_PtrDepricated("sObject");
    else
        local sObject = reader:ReadBZ1_Ptr("sObject");
    end

    -- BZ1 sometimes has a bool here?
    -- looks like it's based on what mission is used
    -- but it looks like AIMission starts with the header, so no idea what this extra bool is for
    if reader.version == 1044 then
        local rem_pos = reader.pos
        tok = reader:ReadToken()
        if not tok or not tok:Validate("undefbool", BinaryFieldType.DATA_BOOL) then
            -- unknown what this is or why it happens
            reader.pos = rem_pos
        end
    end

    if not reader:inBinary() then
        tok = reader:ReadToken();
        if not tok or not tok:IsValidationOnly() or not tok:Validate("AiMission") then
            error("Failed to parse [AiMission]");
        end
    end

    if reader.version == 1001 or reader.version == 1011 or reader.version == 1012 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("size", BinaryFieldType.DATA_LONG) then
            error("Failed to parse size/LONG");
        end
        local UnknownSize = tok:GetInt32();
    end

    if reader.version == 1011 or reader.version == 1012 then
        -- this might also be due to the above count being 1 instead of 0, unknown, for now we're using the version

        tok = reader:ReadToken();
        if not tok or not tok:Validate("name", BinaryFieldType.DATA_CHAR) then
            error("Failed to parse name/CHAR");
        end
        --tok.GetBytes(); // "AiMission"

        -- read the old sObject ptr, not sure what can be done with it
        if reader.version < 1002 then
            local sObject = reader:ReadBZ1_PtrDepricated("sObject");
        else
            local sObject = reader:ReadBZ1_Ptr("sObject");
        end

        if not reader:inBinary() then
            tok = reader:ReadToken();
            if not tok or not tok:IsValidationOnly() or not tok:Validate("UserProcess") then
                error("Failed to parse [UserProcess]");
            end
        end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/PTR");
        end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("cycle") then
            error("Failed to parse cycle/UNKNOWN");
        end
        --tok.GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("cycleMax") then
            error("Failed to parse cycleMax/UNKNOWN");
        end
        --tok.GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("selectList") then
            error("Failed to parse selectList/UNKNOWN");
        end
        --tok.GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/PTR");
        end
        --tok.GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/PTR");
        end
        --tok.GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("exited") then
            error("Failed to parse exited/UNKNOWN");
        end
        --tok.GetUInt32H();
    end

    -- if reader.SaveType != 0

    if not reader:inBinary() then
        tok = reader:ReadToken();
        if not tok or not tok:IsValidationOnly() or not tok:Validate("AOIs") then
            error("Failed to parse [AOIs]");
        end
    end

    tok = reader:ReadToken();
    if not tok or not tok:Validate("size", BinaryFieldType.DATA_LONG) then
        error("Failed to parse size/LONG");
    end
    local CountAOIs = tok:GetInt32();

    if CountAOIs > 0 then
        bzn.AOIs = {}
    end

    for i = 1, CountAOIs do
        --- @type BZN_AOI
        --- @diagnostic disable-next-line: missing-fields
        local newAOI = {}
        bzn.AOIs[i] = newAOI

        if not reader:inBinary() then
            tok = reader:ReadToken();
            if not tok or not tok:IsValidationOnly() or not tok:Validate("AOI") then
                error("Failed to parse [AOI]");
            end
        end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("undefptr", BinaryFieldType.DATA_PTR) then
            error("Failed to parse undefptr/PTR");
        end
        newAOI.undefptr = tok:GetUInt32H();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("team", BinaryFieldType.DATA_LONG) then
            error("Failed to parse team/LONG");
        end
        newAOI.team = tok:GetUInt32();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("interesting", BinaryFieldType.DATA_BOOL) then
            error("Failed to parse interesting/BOOL");
        end
        newAOI.interesting = tok:GetBoolean();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("inside", BinaryFieldType.DATA_BOOL) then
            error("Failed to parse inside/BOOL");
        end
        newAOI.inside = tok:GetBoolean();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("value", BinaryFieldType.DATA_LONG) then
            error("Failed to parse value/LONG");
        end
        newAOI.value = tok:GetUInt32();

        tok = reader:ReadToken();
        if not tok or not tok:Validate("force", BinaryFieldType.DATA_LONG) then
            error("Failed to parse force/LONG");
        end
        newAOI.force = tok:GetUInt32();
    end

    if not reader:inBinary() then
        tok = reader:ReadToken();
        if not tok or not tok:IsValidationOnly() or not tok:Validate("AiPaths") then
            error("Failed to parse [AiPaths]");
        end
    end

    tok = reader:ReadToken();
    if not tok or not tok:Validate("count", BinaryFieldType.DATA_LONG) then
        error("Failed to parse count/LONG");
    end
    local CountPaths = tok:GetInt32();

    if CountPaths > 0 then
        bzn.AiPaths = {}
    end
    for i = 1, CountPaths do
        --- @type BZN_Path
        --- @diagnostic disable-next-line: missing-fields
        local newPath = {}
        bzn.AiPaths[i] = newPath
        
        --print("AiPath " .. tostring(i))
        if not reader:inBinary() then
            tok = reader:ReadToken()
            if not tok or not tok:IsValidationOnly() or not tok:Validate("AiPath") then
                error("Failed to parse [AiPath]");
            end
        end

        if reader.version >= 2016 then
            -- 2016
            tok = reader:ReadToken();
            if not tok or not tok:Validate("old_ptr", BinaryFieldType.DATA_PTR) then
                error("Failed to parse old_ptr/PTR");
            end
        else
            -- 1030 1032 1034 1035 1037 1038 1039 1040 1043 1044 1045 1049 2003 2004 2010 2011
            tok = reader:ReadToken();
            if not tok or not tok:Validate("old_ptr", BinaryFieldType.DATA_VOID) then
                error("Failed to parse old_ptr/VOID");
            end
        end

        local label = nil
        tok = reader:ReadToken()
        if not tok or not tok:Validate("size", BinaryFieldType.DATA_LONG) then
            error("Failed to parse size/LONG")
        end
        local labelSize = tok:GetInt32()
        --print("labelSize: " .. tostring(labelSize))

        if labelSize > 0 then
            tok = reader:ReadToken()
            if not tok or not tok:Validate("label", BinaryFieldType.DATA_CHAR) then
                error("Failed to parse label/CHAR")
            end
            label = tok:GetString()
            if #label > labelSize then
                label = label:sub(1, labelSize)
            end
            --print("label: " .. tostring(label))
            newPath.label = label
        end
        --Console.WriteLine($"AiPath[{i.ToString().PadLeft(CountPaths.ToString().Length)}]: {(label ?? string.Empty)}");

        tok = reader:ReadToken()
        if not tok or not tok:Validate("pointCount", BinaryFieldType.DATA_LONG) then
            error("Failed to parse pointCount/LONG")
        end
        local pointCount = tok:GetInt32();
        --print("pointCount: " .. tostring(pointCount))

        if pointCount > 0 then
            newPath.points = {}
        end

        tok = reader:ReadToken();
        if not tok or not tok:Validate("points", BinaryFieldType.DATA_VEC2D) then
            error("Failed to parse point/VEC2D")
        end
        for j = 0, pointCount - 1 do
            --print("  Point " .. tostring(j))
            local point = tok:GetVector2D(j)
            --Console.WriteLine($"{new string(' ', CountPaths.ToString().Length + 9)} [{j.ToString().PadLeft(pointCount.ToString().Length)}] {point.x}, {point.z}")

            newPath.points[j + 1] = point
        end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("pathType", BinaryFieldType.DATA_VOID) then
            error("Failed to parse pathType/VOID")
        end
        --Int32 pathType = tok.GetUInt32H();
        newPath.pathType = tok:GetUInt32H();
    end

    if reader.version == 1001 or reader.version == 1011 or reader.version == 1012 then
        if not reader:inBinary() then
            tok = reader:ReadToken()
            if not tok or not tok:IsValidationOnly() or not tok:Validate("AiTasks") then
                error("Failed to parse [AiTasks]")
            end
        end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("count", BinaryFieldType.DATA_LONG) then
            error("Failed to parse count/LONG")
        end
        local CountAiTasks = tok:GetInt32()

        for i = 1, CountAiTasks do

        end
    end

    if reader.version == 1001 then
        if not reader:inBinary() then
            tok = reader:ReadToken()
            if not tok or not tok:IsValidationOnly() or not tok:Validate("Terrain") then
                error("Failed to parse [Terrain]")
            end
        end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("Name") then
            error("Failed to parse Name/UNKNOWN")
        end
        --Console.WriteLine($"TerrainName: {TerrainName}");
    end

    return bzn
end

--- As Lua only runs for a small subset of Mission Classes, we alias them here
--- @alias MissionClass "Inst03Mission"|"Inst04Mission"|"MultDMMission"|"MultSTMission"|"LuaMission"

--- @class BZN_Path
--- @field label string?
--- @field points Vector[]
--- @field pathType integer

--- @class BZN_AOI
--- @field undefptr integer
--- @field team integer
--- @field interesting boolean
--- @field inside boolean
--- @field value integer
--- @field force integer

--- @class FileReferenceBZN : CustomSavableType
--- @field filename string
--- @field version integer
--- @field binary boolean
--- @field msn_filename string?
--- @field seq_count integer
--- @field missionSave boolean?
--- @field TerrainName string?
--- @field entities table<number, table>
--- @field Mission MissionClass
--- @field AiPaths BZN_Path[]?
--- @field AOIs BZN_AOI[]? not yet worked out, is this vestigial?
local FileReferenceBZN = {}
FileReferenceBZN.__index = FileReferenceBZN
FileReferenceBZN.__type = "FileReferenceBZN";

--- Save a BZN file
---
--- {INTERNAL USE}
--- @param self FileReferenceBZN
--- @return string filename with extension
function FileReferenceBZN:Save()
    return self.filename;
end

--- Load a BZN file
---
--- {INTERNAL USE}
--- @param filename string filename with extension
--- @return FileReferenceBZN?
function FileReferenceBZN.Load(filename)
    return M.Open(filename);
end

--- Open a BZN file
--- @param name string filename with extension
--- @return FileReferenceBZN?
function M.Open(name)
    local filedata = UseItem(name)
    if not filedata then
        return nil
    end

    local reader = Tokenizer.new(filedata)

    local bzn = {}
    bzn.filename = name
    bzn = setmetatable(bzn, FileReferenceBZN)

    -- BZN version
    local tok = reader:ReadToken()
    if not tok or not tok:Validate("version") then
        error("Failed to parse version")
    end
    bzn.version = tok:GetInt32()
    reader.version = bzn.version

    -- We think version 1022 and under are always text but don't know for sure
    if bzn.version > 1022 then
        -- Binary Save flag
        tok = reader:ReadToken()
        if not tok or not tok:Validate("binarySave") then
            error("Failed to parse binarySave")
        end
        bzn.binary = tok:GetBoolean()
        --print(string.format("binarySave: %d", tok:GetBoolean()))

        if bzn.binary then
            reader.binary_offset = reader.pos
        end

        tok = reader:ReadToken()
        if not tok or not tok:Validate("msn_filename", BinaryFieldType.DATA_CHAR) then
            error("Failed to parse msn_filename/CHAR")
        end
        bzn.msn_filename = tok:GetString()
        --print(string.format("msn_filename: \"%s\"", tok:GetString()))
    end
    
    if bzn.version <= 1001 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("seq_count", BinaryFieldType.DATA_LONG) then
            error("Failed to parse seq_count/LONG");
        end
        bzn.seq_count = tok:GetInt32();
        --print(string.format("seq_count: %d", seq_count));
    else
        -- Why does SeqCount exist if there's a GameObject counter too?
        -- It appears to be the next seqno so we can calculate it for BZN64 via MAX+1.
        tok = reader:ReadToken();
        if not tok or not tok:Validate("seq_count", BinaryFieldType.DATA_LONG) then
            error("Failed to parse seq_count/LONG");
        end
        bzn.seq_count = tok:GetInt32();
        --print(string.format("seq_count: %d", seq_count));
    end

    if  bzn.version >= 1016 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("missionSave", BinaryFieldType.DATA_BOOL) then
            error("Failed to parse missionSave/BOOL")
        end
        bzn.missionSave = tok:GetBoolean()
        --print(string.format("missionSave: %s", tostring(missionSave)))
    end

    if bzn.version ~= 1001 then
        tok = reader:ReadToken();
        if not tok or not tok:Validate("TerrainName", BinaryFieldType.DATA_CHAR) then
            error("Failed to parse TerrainName/CHAR")
        end
        bzn.TerrainName = tok:GetString()
        --print(string.format("TerrainName: %s", TerrainName))
    end

    if bzn.version == 1011 or bzn.version == 1012 then
        tok = reader:ReadToken()
        if not tok or not tok:Validate("start_time", BinaryFieldType.DATA_FLOAT) then
            error("Failed to parse start_time/FLOAT")
        end
        local start_time = tok:GetSingle()
        --print(string.format("start_time: %f", start_time))
    end

    Hydrate(bzn, reader)

    return bzn

end

customsavetype.Register(FileReferenceBZN);

logger.print(logger.LogLevel.DEBUG, nil, "_bzn Loaded");

return M;


--- @class Euler
--- @field v Vector
--- @field omega Vector
--- @field Accel Vector
--- @field Alpha Vector
--- @field Pos Vector
--- @field mass number
--- @field mass_inv number
--- @field I number
--- @field I_inv number
--- @field v_mag number
--- @field v_mag_inv number

--- @class GameObjectClass
--- @field illumination number
--- @field pos Vector
--- @field euler Euler
--- @field seqNo integer
--- @field name string
--- @field isObjective boolean
--- @field isSelected boolean
--- @field isVisible integer
--- @field seen integer
--- @field healthRatio number
--- @field curHealth integer
--- @field maxHealth integer
--- @field ammoRatio number
--- @field curAmmo integer
--- @field maxAmmo integer
--- @field priority integer
--- @field what integer
--- @field who integer
--- @field where integer
--- @field param integer
--- @field aiProcess boolean
--- @field isCargo boolean
--- @field independence integer
--- @field curPilot string
--- @field perceivedTeam integer

--- @class GameObjectWrapper
--- @field obj GameObjectClass