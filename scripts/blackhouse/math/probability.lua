--[[
-- Probability stuff.
--]]

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


local math = math
local Class = Class

local bhutils = require 'blackhouse.utils'

module(...)

--[[
-- Approximation to the inverse of $erf(x) = \frac{2}{\sqrt{\pi}} \int_{0}^{x}{ e^{-t^2} dt }$.
--]]
function erfinv(x)
	local a = (8*(math.pi - 3))/(3*math.pi*(4 - math.pi))

	return
	(x >= 0 and 1 or -1)
	*
	math.sqrt(
		math.sqrt(
			( (2/(math.pi*a)) + math.log(1 - x^2)/2 )^2
			-
			math.log(1 - x^2)/a
		)
		-
		(
			2/(math.pi*a)
			+
			math.log(1 - x^2)/2
		)
	)
end

-- invCDF: Inverse cumulative distribution function.
RandomVariable = Class(function(self, invCDF, rng)
	self.invCDF = invCDF
	self.rng = rng or math.random
end)

function RandomVariable:__call()
	return self.invCDF(self.rng())
end

function NormalDistribution(mu, sigma)
	local function phiinv(x)
		if x >= 1/2 then
			return math.sqrt(2)*erfinv(2*x - 1)
		else
			return -math.sqrt(2)*erfinv(1 - 2*x)
		end
	end

	return function(x)
		return mu + sigma*phiinv(x)
	end
end

function TruncatedNormalDistribution(mu, sigma)
	local f = NormalDistribution(mu, sigma)
	return function(x)
		return f(math.max(0.1, math.min(0.9, x)))
	end
end

function TruncatedNormalVariable(mu, sigma, rng)
	return RandomVariable(TruncatedNormalDistribution(mu, sigma), rng)
end

return _M
