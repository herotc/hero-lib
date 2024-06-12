--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
local Cache         = HeroCache
-- Lua
local gmatch        = gmatch
local pairs         = pairs
local stringupper   = string.upper
local tableinsert   = table.insert
local tonumber      = tonumber
local type          = type
-- File Locals
local Utils         = {}

--- ======= GLOBALIZE =======
-- Addon
HL.Utils            = Utils


--- ============================ CONTENT ============================
function Utils.BoolToInt(Value)
  return Value and 1 or 0
end

function Utils.IntToBool(Value)
  return Value ~= 0
end

-- Uppercase the first letter in a string
function Utils.UpperCaseFirst(ThisString)
  return (ThisString:gsub("^%l", stringupper))
end

function Utils.ValueIsInTable(Table, SearchValue)
  for _, Value in pairs(Table) do
    if Value == SearchValue then
      return true
    end
  end

  return false
end

function Utils.ValueIsInArray(Array, SearchValue)
  for Index = 1, #Array do
    local Value = Array[Index]
    if Value == SearchValue then
      return true
    end
  end

  return false
end

function Utils.FindValueIndexInArray(Array, SearchValue)
  for Index = 1, #Array do
    local Value = Array[Index]
    if Value == SearchValue then
      return Index
    end
  end
end

-- Merge two tables
function Utils.MergeTable(T1, T2)
  local Table = {}
  for _, Value in pairs(T1) do
    tableinsert(Table, Value)
  end
  for _, Value in pairs(T2) do
    tableinsert(Table, Value)
  end
  return Table
end

-- Merge two tables by key
function Utils.MergeTableByKey(T1, T2)
  local Table = {}
  for Key, Value in pairs(T1) do
    Table[Key] = Value
  end
  for Key, Value in pairs(T2) do
    Table[Key] = Value
  end
  return Table
end

-- Compare two values
local CompareThisTable = {
  [">"] = function(A, B) return A > B end,
  ["<"] = function(A, B) return A < B end,
  [">="] = function(A, B) return A >= B end,
  ["<="] = function(A, B) return A <= B end,
  ["=="] = function(A, B) return A == B end,
  ["min"] = function(A, B) return A < B end,
  ["max"] = function(A, B) return A > B end,
}
function Utils.CompareThis(Operator, A, B)
  return CompareThisTable[Operator](A, B)
end

-- Convert a string to a number if possible, or return the string.
-- If the conversion is nil, it means it's not a number, then return the string.
function Utils.StringToNumberIfPossible(String)
  local Converted = tonumber(String)
  return Converted ~= nil and Converted or String
end

-- Count how many string occurances there is in a string.
function Utils.SubStringCount(String, SubString)
  local Count = 0
  for _ in String:gmatch(SubString) do
    Count = Count + 1
  end
  return Count
end

-- cf. http://lua-users.org/wiki/StringRecipes
-- Determines whether a string begins with the characters of a specified string.
function Utils.StartsWith(String, StartString)
  return String:sub(1, #StartString) == StartString
end
-- Determines whether a string ends with the characters of a specified string.
function Utils.EndsWith(String, EndString)
  return EndString == "" or String:sub(-#EndString) == EndString
end

-- Revert a table index
function Utils.RevertTableIndex(Table)
  local NewTable = {}
  for i = #Table, 1, -1 do
    tableinsert(NewTable, Table[i])
  end
  return NewTable
end

-- Ascending sort function
function Utils.SortASC(a, b)
  return a < b
end

-- Descending sort function
function Utils.SortDESC(a, b)
  return a > b
end

-- Ascending sort function for string + number type
function Utils.SortMixedASC(a, b)
  if type(a) == "string" and type(b) == "number" then
    return a < tostring(b)
  elseif type(a) == "number" and type(b) == "string" then
    return b < tostring(a)
  else
    return a < b
  end
end

function Utils.ShortenHotKey(RawHotKey)
  local HotKey = RawHotKey:upper()
    :gsub(" ", "")
    :gsub("ALT%-", "A")
    :gsub("CTRL%-", "C")
    :gsub("SHIFT%-", "S")
    :gsub("BUTTON", "M")
    :gsub("NUMPAD", "N")
    :gsub("DIVIDE", "%/")
    :gsub("MINUS", "%-")
    :gsub("MULTIPLY", "%*")
    :gsub("PLUS", "%+")

  return HotKey
end
