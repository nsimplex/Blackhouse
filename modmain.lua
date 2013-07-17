-----
--[[ Blackhouse ]] VERSION="1.2"
--
-- Last updated: 2013-07-17
-----

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

The file favicon/blackhouse.tex is based on textures from Klei Entertainment's
Don't Starve and is not covered under the terms of this license.
]]--


MODNAME = modname:upper()

_NAME = modname
_VERSION = VERSION


modimport('src/imports.lua')
modimport('src/customizability.lua')

LoadConfigs('rc.defaults.lua')
LoadConfigs('rc.lua')

modimport('src/flowerlogic.lua')


local Probability = GLOBAL.require(modname:lower() .. '.math.probability')
local function NormalVar(mu)
	return Probability.TruncatedNormalVariable(mu, mu*math.sqrt(TUNING[MODNAME].NORMAL_RANDOM_TIME_VARIANCE))
end


local function MakeFueledCorruptor(inst)
	if inst.components.corruptionaura then return inst end

	inst:AddComponent("corruptionaura")
	inst.components.corruptionaura:SetRadius(TUNING[MODNAME].NIGHTLIGHT_CORRUPTION_RADIUS)
	inst.components.corruptionaura:SetCorruptionCapacity(TUNING[MODNAME].NIGHTLIGHT_CORRUPTION_CAPACITY)

	if inst.components.burnable then
		-- The parameters inst below will always be the same as our current inst, so there should be no naming confusion.

		inst:ListenForEvent("onignite", function(inst)
			if inst.components.corruptionaura then
				inst.components.corruptionaura:StartCorrupting()
			end
		end)

		inst:ListenForEvent("onextinguish", function(inst)
			if inst.components.corruptionaura then
				inst.components.corruptionaura:StopCorrupting()
			end
		end)

		if inst.components.burnable:IsBurning() then
			inst.components.corruptionaura:StartCorrupting()
		end
	end

	if inst.components.fueled then
		inst.components.corruptionaura:SetStopPrediction(function(inst)
			if inst.components.fueled then
				return inst.components.fueled.currentfuel/inst.components.fueled.rate
			end
		end)
	end

	return inst
end

nightlightpostinit = MakeFueledCorruptor

local FlowerRand = NormalVar(TUNING[MODNAME].FLOWER_CORRUPTION_TIME)
function flowerpostinit(inst)
	inst:AddComponent("corruptible")
	inst.components.corruptible:SetCorruptionBaseTime( FlowerRand() )
	inst.components.corruptible:SetCorruptedPrefab("flower_evil")
	inst.components.corruptible:AddPostCorruptFn( NewIncinerator(TUNING[MODNAME].FLOWER_IGNITE_CHANCE) )
	inst.components.corruptible:AddPostCorruptFn( NewOnPickedPunishmentSpawnerChain( "firehound", TUNING[MODNAME].FLOWER_REDHOUND_SPAWN_CHANCE ) )
end

local VeggieRand = NormalVar(TUNING[MODNAME].VEGGIE_CORRUPTION_TIME)
function veggiepostinit(inst)
	inst:AddComponent("corruptible")
	inst.components.corruptible:SetCorruptionBaseTime( VeggieRand() )
	inst.components.corruptible:SetCorruptedPrefab("durian")
end

local BeeRand = NormalVar(TUNING[MODNAME].BEE_CORRUPTION_TIME)
function beepostinit(inst)
	inst:AddComponent("corruptible")
	inst.components.corruptible:SetCorruptionBaseTime( BeeRand() )
	inst.components.corruptible:SetCorruptedPrefab("killerbee")
end

local ButterRand = NormalVar(TUNING[MODNAME].BUTTERFLY_CORRUPTION_TIME)
function butterflypostinit(inst)
	inst:AddComponent("corruptible")
	inst.components.corruptible:SetCorruptionBaseTime( math.max(0.01, ButterRand()) )
	inst.components.corruptible:SetCorruptedPrefab("mosquito")
end

AddPrefabPostInit("nightlight", nightlightpostinit)

AddPrefabPostInit("flower", flowerpostinit)

-- I don't like doing this, but I see no way around it.
GLOBAL.require 'prefabs.veggies'
for v in pairs(GLOBAL.VEGGIES) do
	AddPrefabPostInit(v, veggiepostinit)
end

AddPrefabPostInit("bee", beepostinit)

AddPrefabPostInit("butterfly", butterflypostinit)

AddSimPostInit(function()
	print('Thank you, ' .. (GLOBAL.STRINGS.NAMES[GLOBAL.GetPlayer().prefab:upper()] or "player") .. ', for using ' .. modname .. ' Mod ' .. VERSION .. '.')
	print(modname .. ' is free software, licensed under the terms of the GNU GPLv2.')
end)

