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


local rawget = rawget
local rawset = rawset
local getmetatable = getmetatable
local setmetatable = setmetatable
local type = type
local table = table
local next = next
local pairs = pairs
local ipairs = ipairs
local math = math
local tostring = string
local assert = assert
local Class = Class

-- Set theory needs to be pure.
setfenv(1, {})


local Set = Class(function(self, crudeset)
    self:MakeEmpty()

    if type(crudeset) == "table" and not getmetatable(crudeset) then
	for i,v in ipairs(crudeset) do
		self:Add(v)
        end
    elseif type(crudeset) == "table" and crudeset.is_a and crudeset:is_a(Set) then
	crudeset:CopyInto(self)
    else
	if crudeset then
		self:Add(crudeset)
	end
    end

    return self
end)


function Set:MakeEmpty()
	self.table = {}
	self.size = 0
	return self
end

function Set:Size()
    return self.size
end

function Set:Empty()
    --assert( (self:Size() == 0 or next(self.table) ~= nil) and (self:Size() ~= 0 or next(self.table) == nil) )
    return self:Size() == 0
end

Set.IsEmpty = Set.Empty

function Set:Get(k)
    return self.table[k]
end

function Set:Has(k)
    return self:Get(k) and true or false
end

function Set:Update(k, v)
    if not v then
        v = nil
        if self:Has(k) then
            self.size = self.size - 1
        end
    else
        if not self:Has(k) then
            self.size = self.size + 1
        end
    end
    self.table[k] = v
end

Set.Set = Set.Update

function Set:Add(k, v)
    if not v then v = true end
    self:Update(k, v)
end

function Set:Remove(k)
    self:Update(k, nil)
end

Set.Erase = Set.Remove

function Set:Elements()
    return pairs(self.table)
end

-- Persistant implementation of the Axiom of Substition (Zermelo-Fraenkel set theory)
function Set:Substitute(f)
    for x, v in self:Elements() do
        y = f(x, v)
        if y ~= nil then
            Y:Update(y, v)
        end
    end
    return Y
end

-- Implementation of the Schema of Separation, through its standard set theoretic formulation is terms of the Axiom of Substitution and partially defined functions.
function Set:Separate(P)
    return self:Substitute(function(x, v) if P(x, v) then return x end end)
end

function Set:Includes(A)
    if A:Size() > self:Size() then
        return false
    end

    for x in A:Elements() do
        if not self:Has(x) then
            return false
        end
    end

    return true
end

Set.Contains = Set.Includes
Set.Superset = Set.Includes

function Set:IncludedBy(B)
    return B:Includes(self)
end

Set.IncludedIn = Set.IncludedBy
Set.ContainedBy = Set.IncludedBy
Set.ContainedIn = Set.IncludedBy
Set.Subset = Set.IncludedBy

function Set:CopyInto(A)
	for x, v in self:Elements() do
		A:Update(x, v)
	end
end

function Set.Equals(A, B)
    return A:Size() == B:Size() and A:Subset(B)
end

function Set.Union(A, B)
    local C = Set()

    A:CopyInto(C)
    B:CopyInto(C)

    return C
end

function Set:Copy()
    return self:CopyInto(Set())
end

function Set.Intersection(A, B)
    local C = Set()

    local m, M = (function()
        if A.size() <= B.size() then
            return A, B
        else
            return B, A
        end
    end)()

    for x, v in m:Elements() do
        if M:Has(x) then
            C:Update(x, v)
        end
    end
    
    return C
end

function Set.Difference(A, B)
    local C = Set()

    for x, v in A:Elements() do
        if not B:Has(x) then
            C:Update(x, v)
        end
    end

    return C
end

Set.__mul = Set.Intersection
Set.__concat = Set.Union
Set.__sub = Set.Difference

Set.__div = Set.Separate

-- f % X means the image of X through f, i.e. the set of all points f(x) s.t. x is in X.
Set.__mod = function(f, X)
	return X:Subtitute(f)
end

Set.__eq = Set.Equals
Set.__le = Set.Subset
Set.__lt = function(A, B)
    return A:Size() < B:Size() and A <= B
end

function Set:Apply(f)
	for x, v in self:Elements() do
		f(x, v)
	end
end

-- Applies f to A \setminus B, g to A \cap B and h to B - a.
function Set.DisjointlyApply(A, B, f, g, h)
	for a, v in A:Elements() do
		local w = B:Get(a)
		if not w then
			f(a, v)
		else
			g(a, v, w)
		end
	end
	for b, w in B:Elements() do
		if not A:Has(b) then
			h(b, w)
		end
	end
end

Set.__tostring = function(X)
    local L = {}
    for x in X:Elements() do
        table.insert(L, tostring(x))
    end
    
    return '{' .. table.concat(L, ', ') .. '}'
end


Set.EmptySet = Set()

return Set
