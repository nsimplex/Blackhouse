---
--- All distances are measured in meters (a wall's side is 1 meter long, a tile's side is 4 meters long).
--- All measures of time are in seconds.
--- All probabilities should be in the range [0, 1].
---

-- Radius of the Corruption Aura of a lit Night Light.
NIGHTLIGHT_CORRUPTION_RADIUS = 8

-- Maximum amount of Corruptibles affected at once.
--@example NIGHTLIGHT_CORRUPTION_CAPACITY = 32
NIGHTLIGHT_CORRUPTION_CAPACITY = 16

-- How long a Flower takes to turn into an Evil Flower while under the influence of a lit Night Light.
--@example FLOWER_CORRUPTION_TIME = 0.5*TUNING.TOTAL_DAY_TIME
FLOWER_CORRUPTION_TIME = 1*TUNING.TOTAL_DAY_TIME

-- How long a Bee takes to turn into a Killer Bee while under the influence of a lit Night Light.
--@example BEE_CORRUPTION_TIME = 15
BEE_CORRUPTION_TIME = 0.1*TUNING.TOTAL_DAY_TIME

-- How long a vegetable takes to turn into a Durian while under the influence of a lit Night Light.
VEGGIE_CORRUPTION_TIME = 0.25*TUNING.TOTAL_DAY_TIME

-- How long a butterfly takes to turn into a Mosquito while under the influence of a lit Night Light.
BUTTERFLY_CORRUPTION_TIME = 10

-- The chance for a Flower to burst into flames when turning into an Evil Flower.
--@example FLOWER_IGNITE_CHANCE = 0.1
FLOWER_IGNITE_CHANCE = 0.075

-- The chance that an unpicked Evil Flower around a Night Light will spawn a Red Hound when another nearby Evil Flower is picked.
--@example FLOWER_REDHOUND_SPAWN_CHANCE = 0
FLOWER_REDHOUND_SPAWN_CHANCE = 0.10
--@stopreading

----
--- The following configurations should generally be left unchanged.
----

-- Distance adopted for an offscreen spawn.
OFFSCREEN_SPAWN_DIST = 30

-- Period after which we update the list of affected Corruptibles.
CORRUPTION_AURA_PERIOD = 1

-- Period after which a Corruptible updates its status.
CORRUPTIBLE_UPDATE_PERIOD = 1/2

-- Variance to be adopted by a normal random time variable. Gets multiplied by the square of the mean.
NORMAL_RANDOM_TIME_VARIANCE = 0.075^2

-- Turn on debugging.
DEBUG = false
