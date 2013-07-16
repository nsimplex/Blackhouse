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


local bhutils = require 'blackhouse.utils'
--local PreorderedArray = require 'blackhouse.math.preorder'
local Set = require 'blackhouse.math.set'

local Notify = bhutils.NewNotifier("(Corruption Aura component) ")

local DEBUG = TUNING.BLACKHOUSE.DEBUG

--
-- CorruptionAura component.
--
-- Since objects with this component may deal with a lot of nearby Corruptibles, its updating process is done by hand, much like the component Propagator, to avoid unnecessary overhead. 
--
local CorruptionAura = Class(function(self, inst)
	self.inst = inst
	self.radius = 0

	self.updater_task = nil

	-- Period after which we update the list of affected Corruptibles.
	self:SetPeriod(TUNING.BLACKHOUSE.CORRUPTION_AURA_PERIOD)

	-- Maximum amount of corruptibles affected at once.
	self:SetCorruptionCapacity(1)

	self.victims = Set()

	self.victims_preorder = function(a, b)
		return self.inst:GetDistanceSqToInst(a) < self.inst:GetDistanceSqToInst(b)
	end

	-- Predicts (or at least estimates) how long in seconds it will take for the Corruption Aura to be stopped. Used in LongUpdate to update the victims.
	self:SetStopPrediction(function(inst)
		return 0
	end)
end)

function CorruptionAura:GetRadius()
	if bhutils.IsCallable(self.radius) then
		return self:radius()
	else
		return self.radius
	end
end

function CorruptionAura:SetRadius(r)
	assert(type(r) == "number" or bhutils.IsCallable(r), "Invalid CorruptionAura radius.")
	self.radius = r
	return r
end

function CorruptionAura:IsActive()
	-- The initially apparently redundant "and true or false" is the distinction between the DS serializer blowing up or not.
	return self.updater_task and true or false
end

CorruptionAura.IsCorrupting = CorruptionAura.IsActive

function CorruptionAura:GetPeriod()
	return self.period
end

function CorruptionAura:SetPeriod(p)
	assert(type(p) == "number" and p > 0)
	self.period = p
end

function CorruptionAura:GetCorruptionCapacity()
	return self.corruption_capacity
end

function CorruptionAura:SetCorruptionCapacity(n)
	assert(type(n) == "number" and n > 0 and n == math.floor(n))
	self.corruption_capacity = n
	return n
end

function CorruptionAura:SetStopPrediction(f)
	assert(bhutils.IsCallable(f))
	self.stop_prediction_function = f
	return f
end

function CorruptionAura:PredictStop()
	return self.stop_prediction_function(self.inst)
end


function CorruptionAura:MightAffect(inst)
	-- Lua is smart, it implements exponentiation through C stdlib's pow, which sees that the exponent is integral and performs binary exponentiation (or at least it does under any decent implementation of libc).
	-- Thus hand-written multiplication would be no more efficient.
	return inst.components.corruptible and self.inst:GetDistanceSqToInst(inst) < self:GetRadius()^2
end

CorruptionAura.IsInAreaOfEffect = CorruptionAura.MightAffect

function CorruptionAura:Affects(inst)
	return inst.components.corruptible and self.victims:Has(inst)
end

function CorruptionAura:Victims()
	return self.victims:Elements()
end

function CorruptionAura:GetDebugString()
	local max
	local maxvalue

	if DEBUG then
		for v in self:Victims() do
			if v.components.corruptible then
				local value = v.components.corruptible:GetCorruptionProgress()
				if not maxvalue or maxvalue < value then
					max = v
					maxvalue = value
				end
			end
		end
	end

	local strtable = {'Corruption Aura from "', self.inst.prefab, '" affecting ', ("%d/%d"):format( self.victims:Size(), self:GetCorruptionCapacity() ), ' entities, and predicted to end in ', self:PredictStop(), " seconds."}

	if DEBUG and max then
		table.insert(strtable, '\nThe closest to corruption is: ')
		table.insert(strtable, max.components.corruptible:GetDebugString())
	end

	return table.concat(strtable)
end

function CorruptionAura:TentativeVictimsArray()
	if not self.inst or not self.inst:IsValid() or self.inst:IsInLimbo() then return {} end
	
	local tentative_victims = {}

	local r = self:GetRadius()
	if type(r) == "number" and r > 0 and self.inst.Transform then
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local E = TheSim:FindEntities(x, y, z, r)
		
		for _, e in ipairs(E) do
			if e.components.corruptible then
				table.insert(tentative_victims, e)
			end
		end
	end

	return tentative_victims
end

function CorruptionAura:TentativeVictims()
	return bhutils.ArrayValueIterator(self:TentativeVictimsArray())
end

local function ChangeVictimsSet(self, newv)
	local oldv = self.victims
	--oldv:InsertionResort()
	
	Set.DisjointlyApply(
		oldv,
		newv,
		function(inst)
			if inst:IsValid() and inst.components.corruptible then
				inst.components.corruptible:RemoveCorruptor(self.inst)
			end
		end,
		function(inst)
			if inst:IsValid() and inst.components.corruptible then
				inst.components.corruptible:AddCorruptor(self.inst)
			end
		end,
		function(inst)
			if inst:IsValid() and inst.components.corruptible then
				inst.components.corruptible:AddCorruptor(self.inst)
			end
		end
	)

	self.victims = newv
end

function CorruptionAura:SpreadCorruption()
	if DEBUG then
		Notify('CorruptionAura:SpreadCorruption()')
	end
	assert(self:IsActive())
	
	local newvictims = Set(
		bhutils.LeastElementsOf( self:TentativeVictimsArray(), self:GetCorruptionCapacity(), self.victims_preorder )
	)
	ChangeVictimsSet(self, newvictims)

	self.stop_prediction_countdown = self:PredictStop()

	if DEBUG then
		Notify(self:GetDebugString())
	end
end

function CorruptionAura:ContainCorruption()
	self.victims:Apply(function(v)
		if v.components.corruptible then
			v.components.corruptible:RemoveCorruptor(self.inst)
		end
	end)
end

function CorruptionAura:DispelEffects()
	for v in self:TentativeVictims() do
		v.components.corruptible:RemoveTentativeCorruptor(self.inst)
	end
	-- Just for insurance, to avoid an unlikely (and theoretical) bug out of a race condition.
	for v in self:Victims() do
		v.components.corruptible:RemoveTentativeCorruptor(self.inst)
	end

	self.victims:MakeEmpty()

	self.stop_prediction_countdown = 0
end

function CorruptionAura:OnUpdate(dt)
	return self:SpreadCorruption()
end

function CorruptionAura:LongUpdate(dt)
	if DEBUG then
		Notify('CorruptionAura:LongUpdate()')
	end

	-- Effective dt
	local edt = math.min(dt, self.stop_prediction_countdown or 0)

	for v in self:Victims() do
		if v:IsValid() and v.components.corruptible and v.components.corruptible.OnUpdate then
			v.components.corruptible:OnUpdate(edt)
		end
	end

	self.stop_prediction_countdown = 0

	if edt < dt then
		self:StopCorrupting()
	else
		if self:IsActive() then
			self.updater_task:Cancel()
			self.updater_task = nil
		end
		self:StartCorrupting()
	end

	if DEBUG then
		Notify(self:GetDebugString())
	end
end

function CorruptionAura:StartCorrupting()
	if DEBUG then
		Notify('CorruptionAura:StartCorrupting()')
	end
	
	if not self:IsActive() then
		self.victims:MakeEmpty()
		--self.inst:StartUpdatingComponent(self)
		local dt = self:GetPeriod()
		self.updater_task = self.inst:DoPeriodicTask(dt, function() return self:OnUpdate(dt) end)
	end
end

function CorruptionAura:StopCorrupting()
	if DEBUG then
		Notify('CorruptionAura:StopCorrupting()')
	end

	if self:IsActive() then
		self:ContainCorruption()
		--self.inst:StopUpdatingComponent(self)
		self.updater_task:Cancel()
		self.updater_task = nil
	end
end

function CorruptionAura:OnSave()
	return {
		active = self:IsActive()
	}
end

function CorruptionAura:OnLoad(data)
	if data and data.active then
		self:StartCorrupting()
	end
end

function CorruptionAura:OnRemoveEntity()
	self:StopCorrupting()
	self:DispelEffects()
end

return CorruptionAura
