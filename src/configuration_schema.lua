--
-- Lists the tests for each configuration value.
--

--[[
Copyright (C) 2013  simplex

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]


local bhutils = require(modname:lower() .. '.utils')

local type = type
local tostring = tostring
local table = table
local ipairs = ipairs
local JoinArrays = GLOBAL.JoinArrays

local _M = {}
_M._M = _M
RC_SCHEMA = _M
setfenv(1, _M)

local function And(p, q)
	return function(x)
		local b, id

		b, id = p(x)
		if not b then return false, id end

		b, id = q(x)
		if not b then return false, id end

		return true
	end
end

local function Or(p, q)
	return function(x)
		local b, p_id, q_id

		b, p_id = p(x)
		if b then return true end

		b, q_id = q(x)
		if b then return true end

		return false, JoinArrays(p_id, q_id)
	end
end

local function IsType(t) return function(x) return type(x) == t, {"a " .. t} end end
local function IsInRange(a, b) return function(x) return a <= x and x <= b, {"between " .. a .. " and " .. b} end end

local IsNumber = IsType("number")
local IsPositive = function(x) return x > 0, {"positive"} end
local IsPositiveNumber = And(IsNumber, IsPositive)
local IsInteger = function(x) return (IsNumber(x)) and x % 1 == 0, {"an integer"} end
local IsPositiveInteger = And(IsInteger, IsPositive)
local IsCallable = function(x) return (bhutils.IsCallable(x)), {"a function"} end


NIGHTLIGHT_CORRUPTION_RADIUS = IsPositiveNumber

NIGHTLIGHT_CORRUPTION_CAPACITY = IsPositiveInteger


local Times = {
	"FLOWER_CORRUPTION_TIME",
	"BEE_CORRUPTION_TIME",
	"VEGGIE_CORRUPTION_TIME",
	"BUTTERFLY_CORRUPTION_TIME",
}

for _, t in ipairs(Times) do
	_M[t] = IsPositiveNumber
end


local Chances = {
	"FLOWER_IGNITE_CHANCE",
	"FLOWER_REDHOUND_SPAWN_CHANCE",
}

for _, p in ipairs(Chances) do
	_M[p] = Or(And(IsNumber, IsInRange(0, 1)), IsCallable)
end


OFFSCREEN_SPAWN_DIST = IsPositiveNumber


CORRUPTION_AURA_PERIOD = IsPositiveNumber


CORRUPTIBLE_UPDATE_PERIOD = IsPositiveNumber


NORMAL_RANDOM_TIME_VARIANCE = IsPositiveNumber


DEBUG = IsType("boolean")


return _M
