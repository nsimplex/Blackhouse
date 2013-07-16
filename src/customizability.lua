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


modimport('src/configuration_schema.lua')

TUNING[MODNAME] = TUNING[MODNAME] or {VERSION = VERSION}

local rawset = GLOBAL.rawset


local function BuildErrorMessage(optname, bad_nodes)
	assert(#bad_nodes > 0)
	local chunks = {tostring(optname), " is "}

	if #bad_nodes == 1 then
		table.insert(chunks, "not ")
		table.insert(chunks, bad_nodes[1])
	else
		table.insert(chunks, "neither ")
		table.insert(chunks, bad_nodes[1])
		for i=2, #bad_nodes-1 do
			table.insert(chunks, ", ")
			table.insert(chunks, bad_nodes[i])
		end
		table.insert(chunks, " nor ")
		table.insert(chunks, bad_nodes[#bad_nodes])
	end

	table.insert(chunks, ".")

	return table.concat(chunks)
end


function LoadConfigs(file)
	local cfg = GLOBAL.kleiloadlua(MODROOT .. file)
	if type(cfg) ~= "function" then return error(cfg or "Unable to load " .. file .. ' (does it exist?)') end

	local bad_options = {}
	
	-- A sandbox inside a sandbox!
	setfenv(cfg, setmetatable(
	{
		TUNING = TUNING,
		_NAME = _NAME,
		VERSION = VERSION,
		_VERSION = _VERSION,
		math = math,
		table = table,
		string = string,
		tostring = tostring,
		tonumber = tonumber,
	},
	{
		__index = TUNING[MODNAME],
		__newindex = function(env, k, v)
			if TUNING[MODNAME] then
				if RC_SCHEMA[k] then
					local status, bad_nodes = RC_SCHEMA[k](v)
					if not status then
						table.insert(bad_options, BuildErrorMessage(k, bad_nodes))
					end
					TUNING[MODNAME][k] = v
				end
			else
				rawset(env, k, v)
			end
		end
	}))

	cfg()
	
	if #bad_options > 0 then
		table.insert(bad_options, 1, 'Invalid values in ' .. file .. ' for the options:')
		return error(table.concat(bad_options, "\n"))
	end
end

