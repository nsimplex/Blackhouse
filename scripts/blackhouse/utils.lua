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
]]--


local type = type
local tostring = tostring
local getmetatable = getmetatable
local table = table
local pairs = pairs
local ipairs = ipairs
local math = math
local assert = assert
local date = (os and os.date) or date
local print = print

local TUNING = TUNING

module(...)

-- The DS API's print does something like this already, except that it inserts those nasty tabs between pieces, just like Lua's standard print.
function NewNotifier(prefix)
	return function(...)
		local t = {date("[%X]"), " (Blackhouse Mod ", tostring(TUNING.BLACKHOUSE.VERSION), ") ", tostring(prefix)}
		
		for i,v in ipairs{...} do
			table.insert(t, tostring(v))
		end
		
		print(table.concat(t))
	end
end

function NilFunction() end

function ArrayValueIterator(t)
	local idx = 0
	
	return function(s)
		idx = idx + 1
		return s[idx]
	end,
	t
end

function TableValueIterator(t)
	local idx = nil

	return function(s)
		idx = next(s, idx)
		return idx and s[idx]
	end,
	t
end

function IsCallable(f)
	return type(f) == "function" or (getmetatable(f) and getmetatable(f).__call)
end

function Less(a, b)
	return a < b
end

-- Returns the k least elements of the array A in O(k*#A + k*log(k)) time.
-- @param cmp should be a total preorder. Defaults to Less.
function LeastElementsOf(A, k, cmp)
	assert(k > 0)

	cmp = cmp or Less

	local n = #A
	local L = {}

	for i=1, math.min(k, n) do
		L[i] = A[i]
	end

	table.sort(L, cmp)

	for i=k+1, n do
		if cmp(A[i], L[k]) then
			table.remove(L)

			local pred_idx = k-1
			while pred_idx > 0 do
				if not cmp(A[i], L[pred_idx]) then break end
				pred_idx = pred_idx - 1
			end
			
			-- The case pred_idx == 0 isn't exceptional.
			table.insert(L, pred_idx + 1, A[i])
		end
	end

	return L
end


-- f should be a table, treated here as a function (of finite domain).
--
-- If i or j are given, only the array part of f inclusively between these indices will be considered.
-- The standard Lua conventions are adopted when only one is given, or when either is negative.
--
-- Runs in linear time on the size of the table we're effectively considering.
--
-- The term fiber is used in its set theoretic sense.
function TableFiber(f, i, j)
	local g = {}

	if i or j then
		if not i then i = 1 end
		if not j then j = #f end
		if i < 0 then i = #f + i + 1 end
		if j < 0 then j = #f + j + 1 end

		for x=i, j do
			if g[f[x]] then
				table.insert(g[f[x]], x)
			else
				g[f[x]] = {x}
			end
		end
	else
		for x,y in pairs(f) do
			if g[y] then
				table.insert(g[y], x)
			else
				g[y] = {x}
			end
		end
	end

	return g
end

return _M
