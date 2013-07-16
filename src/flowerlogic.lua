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
Below, good refers to a Flower inst, and evil to an Evil Flower inst.
]]--

local DEBUG = TUNING[MODNAME].DEBUG
local bhutils = require(modname:lower() .. '.utils')

assert(GLOBAL[modname:lower()].utils == bhutils)

local Notify = bhutils.NewNotifier("(FlowerLogic) ")

local GetWorld = GLOBAL.GetWorld
local GetPlayer = GLOBAL.GetPlayer
local SpawnPrefab = GLOBAL.SpawnPrefab
local Vector3 = GLOBAL.Vector3
local TheSim = GLOBAL.TheSim

local function SpawnPunishment(prefab, origin_pt, keep_loot)
	if DEBUG then
		Notify('SpawnPunishment(): Spawning "', prefab, '" from origin ', ("(%.1f, %.1f, %.1f)"):format(origin_pt:Get()), '.')
	end
	local monster = SpawnPrefab(prefab)
	if monster then
		if not keep_loot and monster.components.lootdropper then
			monster.components.lootdropper:SetLoot({"houndfire","houndfire","houndfire"})
			for i=1, 3 do
				monster.components.lootdropper:AddChanceLoot("houndfire", 1/3)
			end
		end

		local monster_offset = GLOBAL.FindWalkableOffset(origin_pt, 2*math.pi*math.random(), TUNING[MODNAME].OFFSCREEN_SPAWN_DIST, 16, true)
		if monster_offset then
			local monster_pt = origin_pt + monster_offset

			monster.Transform:SetPosition( monster_pt:Get() ) 
			monster:FacePoint(origin_pt)

			if monster.components.combat then
				monster.components.combat:SuggestTarget(GetPlayer())
			end

			if DEBUG then
				Notify('SpawnPunishment(): Spawned at ', ("(%.1f, %.1f, %.1f)"):format(monster_pt:Get()), '.')
			end
		end
	end
end

-- chance_at_node should be a function that returns a probability (0 <= p <= 1) for a corruptible node to spawn a punishment, or that returns nil if the node is to be ignored. It can also be a constant.
-- Is applied over every other corruptible tentatively affected by our tentative corruptors.
function NewOnPickedPunishmentSpawnerChain(prefab, chance_at_node, keep_loot)
	return function(good, evil)
		if DEBUG then
			Notify('OnPickedPunishmentSpawner() for "', good, '" using prefab="', prefab, '".')
		end
		local tentatives = {}
		for C in good.components.corruptible:TentativeCorruptors() do
			table.insert(tentatives, C)
		end

		if DEBUG then
			Notify('OnPickedPunishmentSpawner(): "', good, '" has ', #tentatives, ' tentative corruptors.')
		end
		
		if evil.components.pickable then
			local oldonpickedfn = evil.components.pickable.onpickedfn
			evil.components.pickable.onpickedfn = function(inst, picker)
				for _, C in ipairs(tentatives) do
					if C:IsValid() and not C:IsInLimbo() and C.components.corruptionaura then
						
						local x, y, z = C.Transform:GetWorldPosition()
						local E = TheSim:FindEntities(x, y, z, C.components.corruptionaura:GetRadius())
						for _, f in ipairs(E) do
							if f ~= evil and f.prefab == "flower_evil" then
								local p = type(chance_at_node) == "number" and chance_at_node or chance_at_node(f)
								if DEBUG then
									Notify('OnPickedPunishmentSpawner(): Running spawn check for "', f, '"...')
								end
								if p and math.random() < p then
									if DEBUG then
										Notify('PASSED')
									end
									local pt = Vector3( f.Transform:GetWorldPosition() )
									SpawnPunishment(prefab, pt, keep_loot)
								elseif DEBUG then
									Notify('FAILED')
								end
							end
						end
					end
				end
				return oldonpickedfn(inst, picker)
			end
		elseif DEBUG then
			Notify('OnPickedPunishmentSpawner(): "', evil, '" isn\'t pickable! (maybe it\'s burning...)')
		end
	end
end

-- Is applied over the changed flower itself.
function NewIncinerator(chance_at_node)
	return function(good, evil)
		if DEBUG then
			Notify('Incinerator() test running for "', evil, '"...')
		end
		local p = type(chance_at_node) == "number" and chance_at_node or chance_at_node(good)
		
		if p and math.random() < p and evil.components.burnable then
			if DEBUG then
				Notify('PASSED')
			end
			evil.components.burnable:Ignite()
		elseif DEBUG then
			Notify('FAILED')
		end
	end
end
