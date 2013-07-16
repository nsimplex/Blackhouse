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
local WeakSet = require 'blackhouse.math.weakset'

local Notify = bhutils.NewNotifier("(Corruptible component) ")

local DEBUG = TUNING.BLACKHOUSE.DEBUG

local infinity = math.huge
assert( 1/0 == infinity and 1/infinity == 0 and 0*infinity ~= 1 )

local Corruptible = Class(function(self, inst)
	self.inst = inst

	-- Corruptors (entities with a corruptionaura component) that could have the Corruptible within their effect radius (although the concept of a Corruption Aura's area of effect is not dealt with here directly, that's handled only by the CorruptionAura class for encapsulation).
	-- Their EntityScripts objects are stored as (weak) keys.
	self.tentative_corruptor_set = WeakSet()

	-- Subset of the above, has the corruptors currently affecting the Corruptible.
	self.corruptor_set = WeakSet()

	-- How far we are into the corruption. Increases from 0 to 1. Preserved over saving/reloading.
	self:SetCorruptionProgress(0)

	-- The (unmodified) time it takes for the corruption to complete.
	self:SetCorruptionBaseTime(infinity)

	-- The speed modifier for the corruption. Together with self:GetCorruptionBaseTime() determines how longthe corruption will take to complete. However, the base time is a constant of the object (can only be changed when self:GetCorruptionProgress() == 0, unless we are initializing the object, so that it may be changed freely as a mod configuration option), while the speed can change dinamically over the process of corruption. The implementation presumes (in terms of choices regarding efficiency) that the speed won't change often, if at all. The speed can also be negative. That won't change back a turned entity, but will progressively reverse the effects of a corruption that hasn't completed yet.
	self:SetCorruptionSpeed(1)

	-- What we turn into.
	self:SetCorruptedPrefab("deerclops")

	self.precorruptfns = {}
	self.postcorruptfns = {}
	
	self.updater_task = nil

	-- Update period
	self:SetPeriod(TUNING.BLACKHOUSE.CORRUPTIBLE_UPDATE_PERIOD)
end)

function Corruptible:GetPeriod()
	return self.period
end

function Corruptible:SetPeriod(t)
	assert(type(t) == "number" and t > 0)
	self.period = t
	return t
end

function Corruptible:IsActive()
	return self.updater_task and true or false
end

function Corruptible:GetDebugString()
	return "Corruptible \"" .. self.inst.prefab.. "\" at " .. ("%.1f%%"):format(100*self:GetCorruptionProgress()) .. "."
end

function Corruptible:GetCorruptionProgress()
	return self.progress
end

function Corruptible:SetCorruptionProgress(p)
	assert(type(p) == "number", "Invalid corruption progress.")
	self.progress = math.min(1, math.max(0, p))

	if self.progress == 1 then
		self:Corrupt()
	end

	return self.progress
end

-- Can be negative
function Corruptible:OffsetCorruptionProgress(amount)
	self:SetCorruptionProgress(self:GetCorruptionProgress() + amount)
end

function Corruptible:GetCorruptionSpeed()
	return self.speed
end

function Corruptible:SetCorruptionSpeed(s)
	assert(type(s) == "number")
	self.speed = s
	return s
end

function Corruptible:GetCorruptionBaseTime()
	return self.corruption_time
end

function Corruptible:SetCorruptionBaseTime(t)
	if self:GetCorruptionBaseTime() and self:GetCorruptionProgress() > 0 then
		-- Just ignore it
		return self:GetCorruptionBaseTime()
		--return error("Attempt to change the base corruption time of an entity whose corruption has already begun.")
	end

	assert(type(t) == "number")
	self.corruption_time = math.max(1, t)
	return self.corruption_time
end

function Corruptible:GetCorruptedPrefab()
	return self.corrupted_prefab
end

function Corruptible:SetCorruptedPrefab(p)
	assert(type(p) == "string", "The corrupted prefab should be a string.")

	self.corrupted_prefab = p

	return p
end

function Corruptible:HasCorruptors()
	return not self.corruptor_set:IsEmpty()
end

function Corruptible:TentativeCorruptors()
	return self.tentative_corruptor_set:Elements()
end

function Corruptible:Corruptors()
	return self.corruptor_set:Elements()
end

function Corruptible:AffectedBy(inst)
	if inst:IsValid() and not inst:IsInLimbo() and inst.components.corruptionaura then
		return inst.components.corruptionaura:Affects(self.inst)
	end
end

function Corruptible:StartProgressing()
	assert(not self:IsActive())

	if DEBUG then
		Notify('Corruptible:StartProgressing()')
	end

	local dt = self:GetPeriod()
	self.updater_task = self.inst:DoPeriodicTask(dt, function() return self:OnUpdate(dt) end)
end

function Corruptible:StopProgressing()
	if DEBUG then
		Notify('Corruptible:StopProgressing()')
	end

	self.updater_task:Cancel()
	self.updater_task = nil
end

function Corruptible:AddTentativeCorruptor(inst)
	if inst.components.corruptionaura then
		self.tentative_corruptor_set:Add(inst)
	end
end

function Corruptible:RemoveTentativeCorruptor(inst)
	self:RemoveCorruptor(inst)

	self.tentative_corruptor_set:Remove(inst)
end

function Corruptible:HasCorruptor(inst)
	return self.corruptor_set:Has(inst)
end

function Corruptible:AddCorruptor(inst)
	if DEBUG and not self:HasCorruptor(inst) then
		Notify('Corruptible:AddCorruptor()')
	end
	self:AddTentativeCorruptor(inst)

	if inst.components.corruptionaura then
		local wasempty = not self:HasCorruptors()
	
		self.corruptor_set:Add(inst)
		
		if wasempty then
			self:StartProgressing()
		end
	end

	return inst
end

function Corruptible:RemoveCorruptor(inst)
	if DEBUG and self:HasCorruptor(inst) then
		Notify('Corruptible:RemoveCorruptor()')
	end
	if self.corruptor_set:Has(inst) then
		self.corruptor_set:Remove(inst)

		if not self:HasCorruptors() then
			self:StopProgressing()
		end
	end
end

function Corruptible:CleanupTentativeCorruptors()
	local bad_corruptors = {}
	
	for c in self:TentativeCorruptors() do
		if not ( c.components.corruptionaura and c.components.corruptionaura:MightAffect(self.inst) ) then
			table.insert(bad_corruptors, c)
		end
	end
	
	for _,c in ipairs(bad_corruptors) do
		self:RemoveTentativeCorruptor(c)
	end
end

function Corruptible:CleanupCorruptors()
	local bad_corruptors = {}
	
	for c in self:Corruptors() do
		if not ( c.components.corruptionaura and c.components.corruptionaura:Affects(self.inst)	) then
			table.insert(bad_corruptors, c)
		end
	end
	
	for _,c in ipairs(bad_corruptors) do
		self:RemoveCorruptor(c)
	end
end

function Corruptible:OnUpdate(dt)
	return self:OffsetCorruptionProgress( -- Changing the location of this parenthesis, relative to the function identifier, introduces a parsing ambiguity. 

			(
			dt
		*
			self:GetCorruptionSpeed()
			)
	/
		self:GetCorruptionBaseTime()

	) -- This parenthesis looks quite odd here. It really screws up the syntax tree above.
end

function Corruptible:AddPreCorruptFn(fn)
	table.insert(self.precorruptfns, fn)
end

function Corruptible:AddPostCorruptFn(fn)
	table.insert(self.postcorruptfns, fn)
end

function Corruptible:Corrupt()
	if DEBUG then
		Notify('Corruptible:Corrupt()')
	end
	
	self:CleanupTentativeCorruptors()
	self:CleanupCorruptors()

	local DrJekyll = self.inst
	local MrHyde = SpawnPrefab(self.corrupted_prefab)

	for _,f in ipairs(self.precorruptfns) do
		f(DrJekyll)
	end

	if MrHyde then
		MrHyde.Transform:SetPosition(DrJekyll.Transform:GetWorldPosition())
		MrHyde.Transform:SetRotation(DrJekyll.Transform:GetRotation())
		if DrJekyll.components.stackable and MrHyde.components.stackable then
			MrHyde.components.stackable:SetStackSize( DrJekyll.components.stackable:StackSize() )
		end
		if DrJekyll.components.perishable and MrHyde.components.perishable then
			MrHyde.components.perishable:SetPercent( DrJekyll.components.perishable:GetPercent() )
		end
		-- It's more fun to leave this out, so corrupted entities will just hang around.
		--[[
		if DrJekyll.components.homeseeker and DrJekyll.components.homeseeker:HasHome() then
			DrJekyll.components.homeseeker.home:TakeOwnership(MrHyde)
		end
		]]--
		if MrHyde.sg then
			MrHyde.sg:GoToState("idle")
		end
		if MrHyde.components.combat then
			if DrJekyll.components.combat and DrJekyll.components.combat.target and MrHyde.components.combat:IsValidTarget( DrJekyll.components.combat.target ) then
				MrHyde.components.combat:SetTarget( DrJekyll.components.combat.target )
			else
				MrHyde.components.combat:TryRetarget()
			end
		end
		
		for _,f in ipairs(self.postcorruptfns) do
			f(DrJekyll, MrHyde)
		end
		
		DrJekyll:Remove()
	end

	return MrHyde or DrJekyll
end

function Corruptible:OnSave()
	if DEBUG then
		Notify('Corruptible:OnSave()')
	end
	return {
		progress = self:GetCorruptionProgress()
	}
end

function Corruptible:OnLoad(data)
	if DEBUG then
		Notify('Corruptible:OnLoad()')
	end
	if data and data.progress then
		self:SetCorruptionProgress(data.progress)
	end
end

return Corruptible
