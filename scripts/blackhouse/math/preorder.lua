---
--- Small library for dealing with totally preordered arrays.
---

---
--- NO LONGER USED (for the time being).
---

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


--[[

A total preorder is an order that needs not be antisymmetric, i.e. A <= B and A >= B does not necessarily imply A = B. A totally preordered array can undergo many algorithms for dealing with ordered arrays, with minor extra considerations.

If X is a totally preordered set, we can define a relation over elements of X by
a ~ b if and only if a <= b and a >= b
This is an equivalence relation. For every x in X, let [x] be the equivalence class of x under ~, i.e. the set of all y in X such that x ~ y. Let X/~ be the set of all the equivalence classes of X under ~. Then X/~ is a totally ordered set where
[x] <= [y] if and only if x <= y
and the above comparison does not depend on the choice of representatives x and y. This construction is the crux of the algorithms implemented below.

Two objects will be considered equal if they are equal by raw comparison, i.e. if they map to the same hash value as keys to a Lua table. That's a compromise of flexibility for efficiency.

]]--

local bhutils = require 'blackhouse.utils'

-- The assertion cmp(A, B) should mean A < B.
local PreorderedArray = Class(function(self, cmp)
	assert(bhutils.IsCallable(cmp), "Comparison function is not callable.")

	self.V = {}
	self.cmp = cmp
end)

function PreorderedArray:GetComparisonFunction()
	return self.cmp
end

function PreorderedArray:MakeEmpty()
	self.V = {}
	return self
end

function PreorderedArray:Size()
	return #self.V
end

function PreorderedArray:Get(i)
	return self.V[i]
end

function PreorderedArray:ipairs()
	return ipairs(self.V)
end

function PreorderedArray:Values()
	return bhutils.ArrayValueIterator(self.V)
end

function PreorderedArray:Apply(f)
	for i,v in self:ipairs() do
		f(v, i)
	end
end

-- Assumes that V is already preordered by cmp. Uses V as the internal array for the returned PreorderedArray object.
function PreorderedArray.BuildFromOrdered(V, cmp)
	local A = PreorderedArray(cmp)
	A.V = V
	return A
end

-- Insertion
function PreorderedArray:Add(x)
	for k=#self.V, 0, -1 do
		-- if A[k] is undefined or x >= A[k]
		if k == 0 or not self.cmp(x, self.V[k]) then
			table.insert(self.V, k+1, x)
			break
		end
	end
	
	return x
end

function PreorderedArray:Fiber()
	return bhutils.TableFiber(self.V)
end

function PreorderedArray:Resort()
	table.sort(self.V, self.cmp)
end

-- Should be used when the expected number of inversions in the array is small, so that run time will be linear.
function PreorderedArray:InsertionResort()
	local n = #self.V
	local cmp = self.cmp

	for i=1, n do
		local j = n
		while j > i do
			if cmp(self.V[j], self.V[i]) then
				self.V[i], self.V[j] = self.V[j], self.V[i]
			end
			j = j - 1
		end	
	end
end

-- Binary search, adjusted for preorders.
-- Worst-case complexity: O(self:Size())
-- Average complexity for a uniformly random distribution of values: O(log(self:Size()))
function PreorderedArray:Has(x)
	local l, r = 1, self:Size()
	local m
	
	local cmp = self.cmp
	
	while l <= r do
		m = math.floor((l + r)/2)
		if cmp(self.V[m], x) then
			l = m + 1
		elseif cmp(x, self.V[m]) then
			r = m - 1
		else
			break
		end
	end

	-- If l <= r, we have found a suitable m. Now we only have to wander around m to check against all the elements A[k] such that A[k] <= A[m] and A[k] >= A[m].
	if l <= r then
		for k=m, 1, -1 do
			if rawequal(self.V[k], x) then return true end
			if cmp(self.V[k], self.V[m]) then break end
		end
		for k=m+1, self:Size() do
			if rawequal(self.V[k], x) then return true end
			if cmp(self.V[m], self.V[k]) then break end
		end
	end

	return false
end

--[[
Receives PreorderedArrays A and B with the same order, and functions f, g and h.

Applies f to all pairs (a, i) where a == A[i] and a does not belong to B.

Applies g to all triples (c, i, j) where c == A[i] and c == B[j]

Applies h to all pairs (b, j) where b == B[j] and b does not belong to A.


Each of these functions will receive their arguments in non-decreasing order.

Care should be taken when using this, because we do not check that the comparison functions are actually equal, since they can be distinct by raw comparison while being functionally identical.

Complexity: O(A:Size() + B:Size())
(which is possible only through our use of hash tables, under the assumption that hash operations are O(1))
]]--
function PreorderedArray.DisjointlyApply(A, B, f, g, h)	
	local An, Bn = #A.V, #B.V
	local i, j = 1, 1
	
	local cmp = A.cmp
	
	while i <= An and j <= Bn do
		if cmp(A.V[i], B.V[j]) then
			f(A.V[i], i)
			i = i + 1
		elseif cmp(B.V[j], A.V[i]) then
			h(B.V[j], j)
			j = j + 1
		else
			-- This is the part where the algorithm gets trickier than the totally ordered case.
			
			-- We have found a mutual class of equivalence under the order.
			-- We are currently over the first element in each array that belongs to the class.
			-- We need to find up to where these classes go (luckily for us, they are segments, i.e. their elements have consecutive indices).
			
			local i_end, j_end = i, j
			while i_end < An and not cmp(A.V[i], A.V[i_end + 1]) do i_end = i_end + 1 end
			while j_end < Bn and not cmp(B.V[j], B.V[j_end + 1]) do j_end = j_end + 1 end
			
			local VA, VB = bhutils.TableFiber(A.V, i, i_end), bhutils.TableFiber(B.V, j, j_end)
			
			repeat
				local dual_set = VB[A.V[i]]
				if not dual_set then
					f(A.V[i], i)
				else
					for _, dual_j in ipairs(dual_set) do
						g(A.V[i], i, dual_j)
					end
				end
				
				i = i + 1
			until i > i_end
			
			repeat
				if not VA[B.V[j]] then
					h(B.V[j], j)
				end
				
				j = j + 1
			until j > j_end
		end
	end
	
	while i <= An do
		f(A.V[i], i)
		i = i + 1
	end
	while j <= Bn do
		h(B.V[j], j)
		j = j + 1
	end
end


return PreorderedArray
