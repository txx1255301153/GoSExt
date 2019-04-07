if myHero.charName ~= "Yasuo" then return end

local Yasuo = {}
Yasuo.Common = {}
Yasuo.Common.Spell = {}
Yasuo.Common.Prediction = {}

function Yasuo.Common.Mode()
	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
                return "Combo"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
                return "Harass"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEARS] then
                return "LaneClear"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
                return "LaneClear"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
                return "LastHit"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
                return "Flee"
        end
end

function Yasuo.Common.HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.name == buffname and buff.count > 0 then
			return true
		end
	end
	return false
end

function Yasuo.Common.GetBuffCount(unit, buffName)
	for i = 0, unit.buffCount do 
		local buff = unit:GetBuff(i)
		if buff and buff.name == buffName and Game.Timer() < buff.expireTime and buff.count > 0 then
			return buff.count
		end
	end
	return 0
end

function Yasuo.Common.HasBuffOfType(unit, type)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.type == type and buff.count > 0 then
			return true
		end
	end
	return false
end

function Yasuo.Common.GetItemSlot(unit, itemID)
	for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == itemID then
			return i
		end
	end
	return 0
end

function Yasuo.Common.IsWindUp(unit)
	local unit = unit or myHero
	return unit.attackData.state == STATE_WINDUP 
end

function Yasuo.Common.IsDashing(unit)
	local unit = unit or myHero
	local path = unit.pathing
	if path.hasMovePath then
		return path.isDashing
	end
end

function Yasuo.Common.GetDistance(p1, p2)
	local p2 = p2 or myHero.pos
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

function Yasuo.Common.GetDistance2D(p1, p2)
	local p2 = p2 or myHero.pos
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end


function Yasuo.Common.GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHero.pos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx * dx + dz * dz

end

function Yasuo.Common.ValidTarget(unit, range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end

function Yasuo.Common.GetTarget(range)
	return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)
end

function Yasuo.Common.GetEnemyHeroes()
	local result = {}
  	for i = 1, Game.HeroCount() do
    		local unit = Game.Hero(i)
    		if unit.isEnemy then
    			result[#result + 1] = unit
  		end
  	end
  	return result
end

function Yasuo.Common.GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
	end
end

function Yasuo.Common.IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

function Yasuo.Common.VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

function Yasuo.Common.EnemyMinionsOnLine(sp, ep, width)
        local c = 0
        for i = 1, Game.MinionCount() do
        	local minion = Game.Minion(i)
        	if minion and not minion.dead and minion.isEnemy then
        		local pointSegment, pointLine, isOnSegment = Yasuo.Common.VectorPointProjectionOnLineSegment(sp, ep, minion.pos)
        		if isOnSegment and Yasuo.Common.GetDistanceSqr(pointSegment, minion.pos) < (width + minion.boundingRadius)^2 and Yasuo.Common.GetDistanceSqr(sp, ep) > Yasuo.Common.GetDistanceSqr(sp, minion.pos) then
				c = c + 1
			end
        	end
        end
        return c
end

function Yasuo.Common.GetBestLinearFarmPos(range, width)
	local pos, hit = nil, 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and not minion.dead and minion.isEnemy then
			local EP = myHero.pos:Extended(minion.pos, range)
			local C = Yasuo.Common.EnemyMinionsOnLine(myHero.pos, EP, width)
			if C > hit then
				hit = C
				pos = minion.pos
			end
		end
	end
	return pos, hit
end

function Yasuo.Common.Prediction:New()
	local this = {}

	this.Vision = {}
	this.Waypoint = {}
	this.VisionT = GetTickCount()

	function this:OnVision(unit)
		if this.Vision[unit.networkID] == nil then this.Vision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
		if this.Vision[unit.networkID].state == true and not unit.visible then this.Vision[unit.networkID].state = false this.Vision[unit.networkID].tick = GetTickCount() end
		if this.Vision[unit.networkID].state == false and unit.visible then this.Vision[unit.networkID].state = true this.Vision[unit.networkID].tick = GetTickCount() end
		return this.Vision[unit.networkID]
	end

	function this:OnVisionF()
		if GetTickCount() - this.VisionT > 100 then
			for i, v in pairs(Yasuo.Common.GetEnemyHeroes()) do
				this:OnVision(v)
			end
		end
	end

	function this:OnWaypoint(unit)
		if this.Waypoint[unit.networkID] == nil then this.Waypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
		if this.Waypoint[unit.networkID].pos ~= unit.posTo then 
			this.Waypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - this.Waypoint[unit.networkID].time)
				local speed = Yasuo.Common.GetDistance2D(this.Waypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - this.Waypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == this.Waypoint[unit.networkID].pos and Yasuo.Common.GetDistance(unit.pos,this.Waypoint[unit.networkID].pos) > 200 then
					this.Waypoint[unit.networkID].speed = Yasuo.Common.GetDistance2D(this.Waypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - this.Waypoint[unit.networkID].time)
				end
			end,0.05)
		end
		return this.Waypoint[unit.networkID]
	end

	function this:GetPosition(unit, speed, delay)
		local speed = speed or math.huge
		local delay = delay or 0.25
		local unitSpeed = unit.ms
		if this:OnWaypoint(unit).speed > unitSpeed then unitSpeed = this:OnWaypoint(unit).speed end
		if this:OnVision(unit).state == false then
			local unitPos = unit.pos + Vector(unit.pos, unit.posTo):Normalized() * ((GetTickCount() - this:OnVision(unit).tick) / 1000 * unitSpeed)
			local predPos = unitPos + Vector(unit.pos, unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos, unitPos) / speed)))
			if Yasuo.Common.GetDistance(unit.pos, predPos) > Yasuo.Common.GetDistance(unit.pos, unit.posTo) then predPos = unit.posTo end	
			return predPos
		else
			if unitSpeed > unit.ms then
				local predPos = unit.pos + Vector(this:OnWaypoint(unit).startPos, unit.posTo):Normalized() * (unitSpeed * (delay + (Yasuo.Common.GetDistance(myHero.pos, unit.pos) / speed)))
				if Yasuo.Common.GetDistance(unit.pos, predPos) > Yasuo.Common.GetDistance(unit.pos, unit.posTo) then predPos = unit.posTo end
		 		return predPos
			elseif Yasuo.Common.IsImmobileTarget(unit) then
				return unit.pos
			else
				return unit:GetPrediction(speed, delay)
			end
		end
	end

	Callback.Add("Tick", function() this:OnVisionF() end)

	return this
end

function Yasuo.Common.Spell:Create(slot, range)
	local this = {}

	this.slot = slot
	this.range = range

	this.pred = Yasuo.Common.Prediction:New()

	function this:SlotToHK()
		return ({[_Q] = HK_Q, [_W] = HK_W, [_E] = HK_E, [_R] = HK_R})[this.slot]
	end

	function this:IsReady()
		return Game.CanUseSpell(this.slot) == READY
	end

	function this:SetSkillShot(delay, width, speed)
		this.delay = delay
		this.width = width
		this.speed = speed
		this.isSkillshot = true
	end

	function this:Data()
		return myHero:GetSpellData(this.slot)
	end

	function this:Cast()
		if not this:IsReady() then return end

		return Control.CastSpell(this:SlotToHK())
	end

	function this:CastOnUnit(unit)
		if not this:IsReady() then return end

		return Control.CastSpell(this:SlotToHK(), unit)
	end

	function this:CastOnPosition(pos)
		if not this:IsReady() then return end

		return Control.CastSpell(this:SlotToHK(), pos)
	end

	function this:CastWithPrediction(unit)
		if not this:IsReady() then return end

		local PredPos = this.pred:GetPosition(unit, this.speed, this.delay)
		if PredPos then
			return Control.CastSpell(this:SlotToHK(), PredPos)
		end
	end

	return this 
end

function Yasuo:Load()
	local this = {}

	this.Q  = Yasuo.Common.Spell:Create(_Q, 425)
	this.W  = Yasuo.Common.Spell:Create(_W, 600)
	this.E  = Yasuo.Common.Spell:Create(_E, 475)
	this.R  = Yasuo.Common.Spell:Create(_R, 1200)

	this.SpellData = {
		["Aatrox"] = {
			["aatroxeconemissile"] = {slot = 2, danger = 2, name = "Blade of Torment", isSkillshot = true}
		},
		["Ahri"] = {
			["ahriorbmissile"] = { slot = 0, danger = 3, name = "Orb of Deception", isSkillshot = true },
			["ahrifoxfiremissiletwo"] = {slot = 1, danger = 2, name = "Fox-Fire", isSkillshot = false},
			["ahriseducemissile"] = {slot = 2, danger = 4, name = "Charm", isSkillshot = true},
			["ahritumblemissile"] = {slot = 3, danger = 2, name = "SpiritRush", isSkillshot = false}
		},
		["Akali"] = {
			["akalimota"] = {slot = 0, danger = 2, name = "Mark of the Assasin", isSkillshot = false}
		},
		["Amumu"] = {
			["sadmummybandagetoss"] = {slot = 0, danger = 4, name = "Bandage Toss", isSkillshot = true}
		},
		["Anivia"] = {
			["flashfrostspell"] = {slot = 0, danger = 2, name = "Flash Frost", isSkillshot = true},
			["frostbite"] = {slot = 2, danger = 3, name = "Frostbite", isSkillshot = false}
		},
		["Annie"] = {
			["disintegrate"] = {slot = 0, danger = 3, name = "Disintegrate", isSkillshot = false}
		},
		["Ashe"] = {
			["volleyattack"] = {slot = 1, danger = 2, name = "Volley", isSkillshot = true},
			["enchantedcrystalarrow"] = {slot = 3, danger = 5, name = "Enchanted Crystal Arrow", isSkillshot = true}
		},
		["AurelionSol"] = {
			["aurelionsolqmissile"] = {slot = 0, danger = 2, name = "Starsurge", isSkillshot = true}
		},
		["Bard"] = {
			["bardqmissile"] = {slot = 0, danger = 4, name = "Cosmic Binding", isSkillshot = true}
		},
		["Blitzcrank"] = {
			["rocketgrabmissile"] = {slot = 0, danger = 5, name = "Rocket Grab", isSkillshot = true}
		},
		["Brand"] = {
			["brandqmissile"] = {slot = 0, danger = 3, name = "Sear", isSkillshot = true},
			["brandr"] = {slot = 3, danger = 5, name = "Pyroclasm", isSkillshot = false}
		},
		["Braum"] = {
			["braumqmissile"] = {slot = 0, danger = 3, name = "Winter's Bite", isSkillshot = true},
			["braumrmissile"] = {slot = 3, danger = 5, name = "Glacial Fissure", isSkillshot = true}
		},
		["Caitlyn"] = {
			["caitlynpiltoverpeacemaker"] = {slot = 0, danger = 2, name = "Piltover Peacemaker", isSkillshot = true},
			["caitlynaceintheholemissile"] = {slot = 3, danger = 4, name = "Ace in the Hole", isSkillshot = false}
		},
		["Cassiopeia"] = {
			["cassiopeiatwinfang"] = {slot = 2, danger = 2, name = "Twin Fang", isSkillshot = false}
		},
		["Corki"] = {
			["phosphorusbombmissile"] = {slot = 0, danger = 2, name = "Phosphorus Bomb", isSkillshot = true},
			["missilebarragemissile"] = {slot = 3, danger = 2, name = "Missile Barrage", isSkillshot = true},
			["missilebarragemissile2"] = {slot = 3, danger = 2, name = "Big Missile Barrage", isSkillshot = true}
		},
		["Diana"] = {
			["dianaarcthrow"] = {slot = 0, danger = 2, name = "Crescent Strike", isSkillshot = true}
		},
		["DrMundo"] = {
			["infectedcleavermissile"] = {slot = 0, danger = 2, name = "Infected Cleaver", isSkillshot = true}
		},
		["Draven"] = {
			["dravenr"] = {slot = 3, danger = 4, name = "Whirling Death", isSkillshot = true}
		},
		["Ekko"] = {
			["ekkoqmis"] = {slot = 0, danger = 2, name = "Timewinder", isSkillshot = true}
		},
		["Elise"] = {
			["elisehumanq"] = {slot = 0, danger = 3, name = "Neurotoxin", isSkillshot = false},
			["elisehumane"] = {slot = 2, danger = 4, name = "Cocoon", isSkillshot = true}
		},
		["Ezreal"] = {
			["ezrealmysticshotmissile"] = {slot = 0, danger = 2, name = "Mystic Shot", isSkillshot = true},
			["ezrealessencefluxmissile"] = {slot = 1, danger = 2, name = "Essence Flux", isSkillshot = true},
			["ezrealarcaneshiftmissile"] = {slot = 2, danger = 1, name = "Arcane Shift", isSkillshot = false},
			["ezrealtrueshotbarrage"] = {slot = 3, danger = 4, name = "Trueshot Barrage", isSkillshot = true}
		},
		["FiddleSticks"] = {
			["fiddlesticksdarkwindmissile"] = {slot = 2, danger = 3, name = "Dark Wind", isSkillshot = false}
		},
		["Gangplank"] = {
			["parley"] = {slot = 0, danger = 2, name = "Parley", isSkillshot = false}
		},
		["Gnar"] = {
			["gnarqmissile"] = {slot = 0, danger = 2, name = "Boomerang Throw", isSkillshot = true},
			["gnarbigqmissile"] = {slot = 0, danger = 3, name = "Boulder Toss", isSkillshot = true}
		},
		["Gragas"] = {
			["gragasqmissile"] = {slot = 0, danger = 2, name = "Barrel Roll", isSkillshot = true},
			["gragasrboom"] = {slot = 3, danger = 4, name = "Explosive Cask", isSkillshot = true}
		},
		["Graves"] = {
			["gravesqlinemis"] = {slot = 0, danger = 2, name = "End of the Line", isSkillshot = true},
			["graveschargeshotshot"] = {slot = 3, danger = 4, name = "Collateral Damage", isSkillshot = true}
		},
		["Illaoi"] = {
			["illaoiemis"] = {slot = 2, danger = 3, name = "Test of Spirit", isSkillshot = true}
		},
		["Irelia"] = {
			["IreliaTranscendentBlades"] = {slot = 3, danger = 2, name = "Transcendent Blades", isSkillshot = true}
		},
		["Janna"] = {
			["howlinggalespell"] = {slot = 0, danger = 1, name = "Howling Gale", isSkillshot = true},
			["sowthewind"] = {slot = 1, danger = 2, name = "Zephyr", isSkillshot = false}
		},
		["Jayce"] = {
			["jayceshockblastmis"] = {slot = 0, danger = 2, name = "Shock Blast", isSkillshot = true},
			["jayceshockblastwallmis"] = {slot = 0, danger = 3, name = "Empowered Shock Blast", isSkillshot = true}
		},
		["Jinx"] = {
			["jinxwmissile"] = {slot = 1, danger = 2, name = "Zap!", isSkillshot = true},
			["jinxr"] = {slot = 3, danger = 4, name = "Super Mega Death Rocket!", isSkillshot = true}
		},
		["Jhin"] = {
			["jhinwmissile"] = {slot = 1, danger = 2, name = "Deadly Flourish", isSkillshot = true},
			["jhinrshotmis"] = {slot = 3, danger = 3, name = "Curtain Call's", isSkillshot = true}
		},
		["Kalista"] = {
			["kalistamysticshotmis"] = {slot = 0, danger = 2, name = "Pierce", isSkillshot = true}
		},
		["Karma"] = {
			["karmaqmissile"] = {slot = 0, danger = 2, name = "Inner Flame ", isSkillshot = true},
			["karmaqmissilemantra"] = {slot = 0, danger = 3, name = "Mantra: Inner Flame", isSkillshot = true}
		},
		["Kassadin"] = {
			["nulllance"] = {slot = 0, danger = 3, name = "Null Sphere", isSkillshot = false}
		},
		["Katarina"] = {
			["katarinaqmis"] = {slot = 0, danger = 3, name = "Bouncing Blade", isSkillshot = false}
		},
		["Kayle"] = {
			["judicatorreckoning"] = {slot = 0, danger = 3, name = "Reckoning", isSkillshot = false}
		},
		["Kennen"] = {
			["kennenshurikenhurlmissile1"] = {slot = 0, danger = 2, name = "Thundering Shuriken", isSkillshot = true}
		},
		["Khazix"] = {
			["khazixwmissile"] = {slot = 1, danger = 3, name = "Void Spike", isSkillshot = true}
		},
		["Kogmaw"] = {
			["kogmawq"] = {slot = 0, danger = 2, name = "Caustic Spittle", isSkillshot = true},
			["kogmawvoidoozemissile"] = {slot = 3, danger = 2, name = "Void Ooze", isSkillshot = true},
		},
		["Leblanc"] = {
			["leblancchaosorbm"] = {slot = 0, danger = 3, name = "Shatter Orb", isSkillshot = false},
			["leblancsoulshackle"] = {slot = 2, danger = 3, name = "Ethereal Chains", isSkillshot = true},
			["leblancsoulshacklem"] = {slot = 2, danger = 3, name = "Ethereal Chains Clone", isSkillshot = true}
		},
		["LeeSin"] = {
			["blindmonkqone"] = {slot = 0, danger = 3, name = "Sonic Wave", isSkillshot = true}
		},
		["Leona"] = {
			["LeonaZenithBladeMissile"] = {slot = 2, danger = 3, name = "Zenith Blade", isSkillshot = true}
		},
		["Lissandra"] = {
			["lissandraqmissile"] = {slot = 0, danger = 2, name = "Ice Shard", isSkillshot = true},
			["lissandraemissile"] = {slot = 2, danger = 1, name = "Glacial Path ", isSkillshot = true}
		},
		["Lucian"] = {
			["lucianwmissile"] = {slot = 1, danger = 1, name = "Ardent Blaze", isSkillshot = true},
			["lucianrmissileoffhand"] = {slot = 3, danger = 3, name = "The Culling", isSkillshot = true}
		},
		["Lulu"] = {
			["luluqmissile"] = {slot = 0, danger = 2, name = "Glitterlance", isSkillshot = true}
		},
		["Lux"] = {
			["luxlightbindingmis"] = {slot = 0, danger = 3, name = "", isSkillshot = true} 
		},
		["Malphite"] = {
			["seismicshard"] = {slot = 0, danger = 3, name = "Seismic Shard", isSkillshot = false}
		},
		["MissFortune"] = {
			["missfortunericochetshot"] = {slot = 0, danger = 3, name = "Double Up", isSkillshot = false}
		},
		["Morgana"] = {
			["darkbindingmissile"] = {slot = 0, danger = 4, name = "Dark Binding ", isSkillshot = true}
		},
		["Nami"] = {
			["namiwmissileenemy"] = {slot = 1, danger = 2, name = "Ebb and Flow", isSkillshot = false}
		},
		["Nunu"] = {
			["iceblast"] = {slot = 2, danger = 3, name = "Ice Blast", isSkillshot = false}
		},
		["Nautilus"] = {
			["nautilusanchordragmissile"] = {slot = 0, danger = 3, name = "", isSkillshot = true}
		},
		["Nidalee"] = {
			["JavelinToss"] = {slot = 0, danger = 2, name = "Javelin Toss", isSkillshot = true}
		},
		["Nocturne"] = {
			["nocturneduskbringer"] = {slot = 0, danger = 2, name = "Duskbringer", isSkillshot = true}
		},
		["Pantheon"] = {
			["pantheonq"] = {slot = 0, danger = 2, name = "Spear Shot", isSkillshot = false}
		},
		["RekSai"] = {
			["reksaiqburrowedmis"] = {slot = 0, danger = 2, name = "Prey Seeker", isSkillshot = true}
		},
		["Rengar"] = {
			["rengarefinal"] = {slot = 2, danger = 3, name = "Bola Strike", isSkillshot = true}
		},
		["Riven"] = {
			["rivenlightsabermissile"] = {slot = 3, danger = 5, name = "Wind Slash", isSkillshot = true}
		},
		["Rumble"] = {
			["rumblegrenade"] = {slot = 2, danger = 2, name = "Electro Harpoon", isSkillshot = true}
		},
		["Ryze"] = {
			["ryzeq"] = {slot = 0, danger = 2, name = "Overload", isSkillshot = true},
			["ryzee"] = {slot = 2, danger = 2, name = "Spell Flux", isSkillshot = false}
		},
		["Sejuani"] = {
			["sejuaniglacialprison"] = {slot = 3, danger = 5, name = "Glacial Prison", isSkillshot = true}
		},
		["Sivir"] = {
			["sivirqmissile"] = {slot = 0, danger = 2, name = "Boomerang Blade", isSkillshot = true}
		},
		["Skarner"] = {
			["skarnerfracturemissile"] = {slot = 0, danger = 2, name = "Fracture ", isSkillshot = true}
		},
		["Shaco"] = {
			["twoshivpoison"] = {slot = 2, danger = 3, name = "Two-Shiv Poison", isSkillshot = false}
		},
		["Sona"] = {
			["sonaqmissile"] = {slot = 0, danger = 3, name = "Hymn of Valor", isSkillshot = false},
			["sonar"] = {slot = 3, danger = 5, name = "Crescendo ", isSkillshot = true}
		},
		["Swain"] = {
			["swaintorment"] = {slot = 2, danger = 4, name = "Torment", isSkillshot = false}
		},
		["Syndra"] = {
			["syndrarspell"] = {slot = 3, danger = 5, name = "Unleashed Power", isSkillshot = false}
		},
		["Teemo"] = {
			["blindingdart"] = {slot = 0, danger = 4, name = "Blinding Dart", isSkillshot = false}
		},
		["Tristana"] = {
			["detonatingshot"] = {slot = 2, danger = 3, name = "Explosive Charge", isSkillshot = false}
		},
		["TahmKench"] = {
			["tahmkenchqmissile"] = {slot = 0, danger = 2, name = "Tongue Lash", isSkillshot = true}
		},
		["Taliyah"] = {
			["taliyahqmis"] = {slot = 0, danger = 2, name = "Threaded Volley", isSkillshot = true}
		},
		["Talon"] = {
			["talonrakemissileone"] = {slot = 1, danger = 2, name = "Rake", isSkillshot = true}
		},
		["TwistedFate"] = {
			["bluecardpreattack"] = {slot = 1, danger = 3, name = "Blue Card", isSkillshot = false},
			["goldcardpreattack"] = {slot = 1, danger = 4, name = "Gold Card", isSkillshot = false},
			["redcardpreattack"] = {slot = 1, danger = 3, name = "Red Card", isSkillshot = false}
		},
		["Urgot"] = {
			--
		},
		["Varus"] = {
			["varusqmissile"] = {slot = 0, danger = 2, name = "Piercing Arrow", isSkillshot = true},
			["varusrmissile"] = {slot = 3, danger = 5, name = "Chain of Corruption", isSkillshot = true}
		},
		["Vayne"] = {
			["vaynecondemnmissile"] = {slot = 2, danger = 3, name = "Condemn", isSkillshot = false}
		},
		["Veigar"] = {
			["veigarbalefulstrikemis"] = {slot = 0, danger = 2, name = "Baleful Strike", isSkillshot = true},
			["veigarr"] = {slot = 3, danger = 5, name = "Primordial Burst", isSkillshot = false}
		},
		["Velkoz"] = {
			["velkozqmissile"] = {slot = 0, danger = 2, name = "Plasma Fission", isSkillshot = true},
			["velkozqmissilesplit"] = {slot = 0, danger = 2, name = "Plasma Fission Split", isSkillshot = true}
 		},
		["Viktor"] = {
			["viktorpowertransfer"] = {slot = 0, danger = 3, name = "Siphon Power", isSkillshot = false},
			["viktordeathraymissile"] = {slot = 2, danger = 3, name = "Death Ray", isSkillshot = true}
		},
		["Vladimir"] = {
			["vladimirtidesofbloodnuke"] = {slot = 2, danger = 3, name = "Tides of Blood", isSkillshot = false}
		},
		["Yasuo"] = {
			["yasuoq3w"] = {slot = 0, danger = 3, name = "Gathering Storm", isSkillshot = true}
		},
		["Zed"] = {
			["zedqmissile"] = {slot = 0, danger = 2, name = "Razor Shuriken ", isSkillshot = true}
		},
		["Zyra"] = {
			["zyrae"] = {slot = 2, danger = 3, name = "Grasping Roots", isSkillshot = true}
		}
	}

	function this:Update()
		if this.Q:Data().name == "YasuoQW" then
			this.Q.range = 425
			this.Q:SetSkillShot(0.25, 30, math.huge)
		elseif this.Q:Data().name == "YasuoQ3W" then
			this.Q.range = 1000
			this.Q:SetSkillShot(0.25, 90, 1200)
		end
	end

	function this:OnTick()
		if myHero.dead then return end

		this:Update()

		local target = Yasuo.Common.GetTarget(1500)

		if this.W:IsReady() then
			this:AutoWindWall()
		end

		if Yasuo.Common.Mode() == "Combo" then
			this:Combo(target)
			this:Ultimate(target)
		elseif Yasuo.Common.Mode() == "Harass" then
			this:Harass(target)
		elseif Yasuo.Common.Mode() == "LastHit" then
			this:LastHit()
		elseif Yasuo.Common.Mode() == "LaneClear" then
			this:LaneClear()
			this:JungleClear()
		elseif Yasuo.Common.Mode() == "Flee" then
			this:Flee()
		end
	end

	function this:Combo(target)
		if target == nil or Yasuo.Common.IsWindUp() then return end

		if this.Menu.Combo.E.Use:Value() and this.E:IsReady() then
			if Yasuo.Common.ValidTarget(target, this.E.range) and not this:IsMarked(target) and Yasuo.Common.GetDistance(this:DashEndPos(target), target.pos) <= Yasuo.Common.GetDistance(myHero.pos, target.pos) then
				this.E:CastOnUnit(target)
			end
			if this.Menu.Combo.E.Gap:Value() then
				local minion = this:GetGapMinion(target)
				if minion and Yasuo.Common.ValidTarget(target, 1500) then
					this.E:CastOnUnit(minion)
				end
			end
		end

		if this.Q:IsReady() and Yasuo.Common.ValidTarget(target, this.Q.range) then
			if this.Menu.Combo.Q.Use:Value() and this.Q:Data().name ~= "YasuoQ3W" then
				if not Yasuo.Common.IsDashing() then
					this.Q:CastWithPrediction(target)
				end
				if this.Menu.Combo.Q.Circle:Value() and Yasuo.Common.IsDashing() and Yasuo.Common.GetDistance(target.pos) <= 220 then
					this.Q:Cast()
				end
			end
			if this.Menu.Combo.Q3.Use:Value() and this.Q:Data().name == "YasuoQ3W" then
				if not Yasuo.Common.IsDashing() then
					this.Q:CastWithPrediction(target)
				end
				if this.Menu.Combo.Q3.Circle:Value() and Yasuo.Common.IsDashing() and Yasuo.Common.GetDistance(target.pos) <= 220 then
					this.Q:Cast()
				end
			end
		end
	end

	function this:Harass(target)
		function Yasuo:CastQ3(target, Q3castPos)
    if LocalGameTimer() - OnWaypoint(target).time > 0.05 and (LocalGameTimer() - OnWaypoint(target).time < 0.125 or LocalGameTimer() - OnWaypoint(target).time > 1.25) then
        if GetDistance(myHero.pos, Q3castPos) <= YasuoQ3.range then
            LocalControlCastSpell(HK_Q, Q3castPos)
				   end
    end
end	
		if target == nil or Yasuo.Common.IsWindUp() then return end
		if this.Q:IsReady() and Yasuo.Common.ValidTarget(target, this.Q.range) then
			if this.Menu.Harass.Q.Use:Value() and this.Q:Data().name ~= "YasuoQ3W" then
				if not Yasuo.Common.IsDashing() then
					this.Q:CastWithPrediction(target)
				end
			end
			if this.Menu.Harass.Q3.Use:Value() and this.Q:Data().name == "YasuoQ3W" then
				if not Yasuo.Common.IsDashing() then
					this.Q:CastWithPrediction(target)
				end
			end
		end
	end

	function this:LastHit()
		if Yasuo.Common.IsWindUp() then return end

		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if minion and minion.isEnemy then
				if this.Menu.LastHit.Q.Use:Value() and this.Q:IsReady() and this.Q:Data().name ~= "YasuoQ3W" and Yasuo.Common.ValidTarget(minion, this.Q.range) and not Yasuo.Common.IsDashing() and this:GetDamage(_Q) > minion.health then
					this.Q:CastWithPrediction(minion)
					break
				elseif this.Menu.LastHit.Q3.Use:Value() and this.Q:IsReady() and this.Q:Data().name == "YasuoQ3W" and Yasuo.Common.ValidTarget(minion, this.Q.range) and not Yasuo.Common.IsDashing() and this:GetDamage(_Q) > minion.health then
					this.Q:CastWithPrediction(minion)
					break
				elseif this.Menu.LastHit.E.Use:Value() and this.E:IsReady() and Yasuo.Common.ValidTarget(minion, this.E.range) and not this:IsMarked(minion) and not this:IsUnderTurret(minion.pos) and not this:IsUnderTurret(this:DashEndPos(minion)) and this:GetDamage(_E) > minion.health then
					this.E:CastOnUnit(minion)
					break
				end
			end
		end
	end

	function this:LaneClear()
		if Yasuo.Common.IsWindUp() then return end

		this:LastHit()

		if this.Menu.LaneClear.Q3.Use:Value() and this.Q:IsReady() and this.Q:Data().name == "YasuoQ3W" then
			local pos, hit = Yasuo.Common.GetBestLinearFarmPos(this.Q.range, this.Q.width)
			if pos and hit >= this.Menu.LaneClear.Q3.Hit:Value() then
				this.Q:CastOnPosition(pos)
			end
		end
	end

	function this:JungleClear()
		if Yasuo.Common.IsWindUp() then return end

		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if minion and minion.team == 300 then
				if this.Menu.JungleClear.Q.Use:Value() and this.Q:IsReady() and this.Q:Data().name ~= "YasuoQ3W" and Yasuo.Common.ValidTarget(minion, this.Q.range) then
					this.Q:CastWithPrediction(minion)
					break
				elseif this.Menu.JungleClear.Q3.Use:Value() and this.Q:IsReady() and this.Q:Data().name == "YasuoQ3W" and Yasuo.Common.ValidTarget(minion, this.Q.range) then
					this.Q:CastWithPrediction(minion)
					break
				elseif this.Menu.JungleClear.E.Use:Value() and this.E:IsReady() and Yasuo.Common.ValidTarget(minion, this.E.range) and not this:IsMarked(minion) then
					this.E:CastOnUnit(minion)
					break
				end
			end
		end
	end

	function this:Flee()
		if this.E:IsReady() and this.Menu.Flee.Use:Value() then
			local minion = this:GetFleeMinion()
			if minion then
				this.E:CastOnUnit(minion)
			end
		end
	end

	function this:Ultimate(target)
		if target == nil then return end --this.Menu.Combo.R.BlackList[target.charName]:Value()
		if this.Menu.Combo.R.Use:Value() and this.R:IsReady() and Yasuo.Common.ValidTarget(target, this.R.range) and not this:IsUnderTurret(target.pos) then 
			if this:IsKnockedUp(target) then
				this.R:Cast()
			end
		end
	end

	function this:AutoWindWall()
		for i = 1, Game.MissileCount() do
			local spell = nil
			local obj = Game.Missile(i)
			local data = obj.missileData
			local source = Yasuo.Common.GetHeroByHandle(data.owner)
			if source then 
				if this.SpellData[source.charName] then
					spell = this.SpellData[source.charName][data.name:lower()]
				end
				if spell and not spell.isSkillshot and data.target == myHero.handle then
					if this.Menu.Windwall.DetectedSpells[spell.name].Use:Value() and this.Menu.Windwall.DetectedSpells[spell.name].Danger:Value() >= this.Menu.Windwall.Danger:Value() then
						this.W:CastOnPosition(obj.pos)
						return
					end
				end
				if spell and spell.isSkillshot and obj.isEnemy and data.speed and data.width and data.endPos and obj.pos then
					if this.Menu.Windwall.DetectedSpells[spell.name].Use:Value() and this.Menu.Windwall.DetectedSpells[spell.name].Danger:Value() >= this.Menu.Windwall.Danger:Value() then
						local pointSegment, pointLine, isOnSegment = Yasuo.Common.VectorPointProjectionOnLineSegment(obj.pos, data.endPos, myHero.pos)
						if isOnSegment and myHero.pos:DistanceTo(Vector(pointSegment.x, myHero.pos.y, pointSegment.y)) < data.width + myHero.boundingRadius then
							this.W:CastOnPosition(obj.pos)
						end
					end
				end
			end
		end
	end

	function this:IsMarked(unit)
		return Yasuo.Common.HasBuff(unit, "YasuoDashWrapper")
	end

	function this:IsKnockedUp(unit)
		return Yasuo.Common.HasBuffOfType(unit, 29) or Yasuo.Common.HasBuffOfType(unit, 30)
	end

	function this:GetClosestTurret(pos)
		local bestTurret = nil
		local closest = math.huge
		for i = 1, Game.TurretCount() do
			local turret = Game.Turret(i)
			if turret and turret.isEnemy and not turret.dead then
				local distance = Yasuo.Common.GetDistance(turret.pos, pos)
				if distance < closest then
					closest = distance
					bestTurret = turret
				end
			end
		end
		return bestTurret
	end

	function this:GetGapMinion(target)
		local bestMinion = nil
		local closest = math.huge
		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if Yasuo.Common.ValidTarget(minion, this.E.range) and not this:IsMarked(minion) and not this:IsUnderTurret(target.pos) then
				if Yasuo.Common.GetDistance(target.pos, this:DashEndPos(minion)) < Yasuo.Common.GetDistance(myHero.pos, target.pos) and Yasuo.Common.GetDistance(this:DashEndPos(minion), target.pos) < closest then
					bestMinion = minion
					closest = Yasuo.Common.GetDistance(this:DashEndPos(minion), target.pos)
				end
			end
		end
		return bestMinion
	end

	function this:GetFleeMinion()
		local bestMinion = nil
		local closest = math.huge
		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if Yasuo.Common.ValidTarget(minion, this.E.range) then
				local DistanceM = Yasuo.Common.GetDistance(myHero.pos, mousePos)
				local DistanceP = Yasuo.Common.GetDistance(this:DashEndPos(minion), mousePos)
				local DistanceC = Yasuo.Common.GetDistance(this:DashEndPos(minion), myHero.pos)
				if DistanceP < DistanceM and DistanceC < closest and not this:IsMarked(minion) then
					bestMinion = minion
					closest = DistanceC
				end
			end
		end
		return bestMinion
	end

	function this:IsUnderTurret(pos)
		local turret = this:GetClosestTurret(pos)
		return turret and Yasuo.Common.GetDistance(turret.pos, pos) <= 775 + (turret.boundingRadius * 2) 
	end

	function this:DashEndPos(unit)
		return myHero.pos + (unit.pos - myHero.pos):Normalized() * 600
	end

	function this:GetDamage(spell)
		local level = myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).level or 1
		if spell == _Q then
			local crit = myHero.critChance
			local critDamage = Yasuo.Common.GetItemSlot(myHero, 3031) > 0 and 2.25 or 1.75
			local AD = (crit == 1 and myHero.totalDamage * critDamage or myHero.totalDamage)
			return 20 * level + AD
		elseif spell == _E then
			local stacks = Yasuo.Common.GetBuffCount(myHero, "YasuoDashScalar")
			return ((50 + (10 * level)) * (1 + (0.25 * stacks))) + (myHero.bonusDamage * 0.2) + (myHero.ap * 0.6)
		end
	end

	function this:LoadMenu()
		this.Menu = MenuElement({type = MENU, name = "PROJECT | Yasuo",  id = "Yasuo", leftIcon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/89/Yasuo_PROJECT_Trace_4.png"})
		this.Menu:MenuElement({name = " ", drop = {"General Features"}})
        	this.Menu:MenuElement({type = MENU, name = "Combo",  id = "Combo"})
        		this.Menu.Combo:MenuElement({type = MENU, name = "[Q] Steel Tempest",  id = "Q"}) 
        			this.Menu.Combo.Q:MenuElement({name = "Use Q In Combo", id = "Use", value = true})
        			this.Menu.Combo.Q:MenuElement({name = "Allow Circle Cast", id = "Circle", value = true})
        		this.Menu.Combo:MenuElement({type = MENU, name = "[Q3] Gathering Storm",  id = "Q3"})
        			this.Menu.Combo.Q3:MenuElement({name = "Use Q3 In Combo", id = "Use", value = true})
        			this.Menu.Combo.Q3:MenuElement({name = "Allow Circle Cast", id = "Circle", value = true})
        		this.Menu.Combo:MenuElement({type = MENU, name = "[E] Sweeping Blade",  id = "E"})
        			this.Menu.Combo.E:MenuElement({name = "Use E In Combo", id = "Use", value = true})
        			this.Menu.Combo.E:MenuElement({name = "Allow Gapclose With E", id = "Gap", value = true})
        		this.Menu.Combo:MenuElement({type = MENU, name = "[R] Last Breath",  id = "R"})
        			this.Menu.Combo.R:MenuElement({name = "Use R In Combo", id = "Use", value = true})
        			this.Menu.Combo.R:MenuElement({type = MENU, name = "Black List", id = "BlackList"})
        				this.Menu.Combo.R.BlackList:MenuElement({id = "info", name = "Detecting Heroes, Please Wait...", drop = {" "}})
        				do
        					local Delay = Game.Timer() > 30 and 0 or 30 - Game.Timer()
						local Added = false
						DelayAction(function()
        						for i, enemy in pairs(Yasuo.Common.GetEnemyHeroes()) do
        							if not Added then
        								this.Menu.Combo.R.BlackList:MenuElement({name = enemy.charName, id = enemy.charName, value = false})
        								Added = true
        							end
        						end
        					this.Menu.Combo.R.BlackList.info:Remove()
        					end, Delay)
        				end

        	this.Menu:MenuElement({type = MENU, name = "Harass",  id = "Harass"})
        		this.Menu.Harass:MenuElement({type = MENU, name = "[Q] Steel Tempest",  id = "Q"}) 
        			this.Menu.Harass.Q:MenuElement({name = "Use Q In Combo", id = "Use", value = true})
        		this.Menu.Harass:MenuElement({type = MENU, name = "[Q3] Gathering Storm",  id = "Q3"})
        			this.Menu.Harass.Q3:MenuElement({name = "Use Q3 In Combo", id = "Use", value = true})

        	this.Menu:MenuElement({type = MENU, name = "Last Hit",  id = "LastHit"})
        		this.Menu.LastHit:MenuElement({type = MENU, name = "[Q] Steel Tempest",  id = "Q"}) 
        			this.Menu.LastHit.Q:MenuElement({name = "Last Hit With Q", id = "Use", value = true})
        		this.Menu.LastHit:MenuElement({type = MENU, name = "[Q3] Gathering Storm",  id = "Q3"})
        			this.Menu.LastHit.Q3:MenuElement({name = "Last Hit With Q3", id = "Use", value = true})
        		this.Menu.LastHit:MenuElement({type = MENU, name = "[E] Sweeping Blade",  id = "E"})
        			this.Menu.LastHit.E:MenuElement({name = "Last Hit With E", id = "Use", value = true})

        	this.Menu:MenuElement({type = MENU, name = "Lane Clear",  id = "LaneClear"})
        		this.Menu.LaneClear:MenuElement({type = MENU, name = "[Q3] Gathering Storm",  id = "Q3"})
        			this.Menu.LaneClear.Q3:MenuElement({name = "Use Q3 In Lane Clear", id = "Use", value = true})
        			this.Menu.LaneClear.Q3:MenuElement({name = "Min. Hit Count", id = "Hit", value = 3, min = 1, max = 6, step = 1})

        	this.Menu:MenuElement({type = MENU, name = "Jungle Clear",  id = "JungleClear"})
        		this.Menu.JungleClear:MenuElement({type = MENU, name = "[Q] Steel Tempest",  id = "Q"}) 
        			this.Menu.JungleClear.Q:MenuElement({name = "Use Q In Jungle Clear", id = "Use", value = true})
        		this.Menu.JungleClear:MenuElement({type = MENU, name = "[Q3] Gathering Storm",  id = "Q3"})
        			this.Menu.JungleClear.Q3:MenuElement({name = "Use Q3 In Jungle Clear", id = "Use", value = true})
        		this.Menu.JungleClear:MenuElement({type = MENU, name = "[E] Sweeping Blade",  id = "E"})
        			this.Menu.JungleClear.E:MenuElement({name = "Use E In Jungle Clear", id = "Use", value = true})

        	this.Menu:MenuElement({type = MENU, name = "Flee", id = "Flee"})
        		this.Menu.Flee:MenuElement({name = "Enabled", id = "Use", value = true})

        	this.Menu:MenuElement({name = " ", drop = {"Advanced Features"}})
        	this.Menu:MenuElement({type = MENU, name = "Auto Windwall",  id = "Windwall"})
        		this.Menu.Windwall:MenuElement({id = "Use", name = "Enabled", value = true})
        		this.Menu.Windwall:MenuElement({id = "Danger", name = "Min. Danger To Use WindWall", value = 3, min = 1, max = 5, step = 1})
        		this.Menu.Windwall:MenuElement({type = MENU, id = "DetectedSpells", name = "Spells"})
        			this.Menu.Windwall.DetectedSpells:MenuElement({id = "info", name = "Detecting Spells, Please Wait...", drop = {" "}})
        				do
        					local Delay = Game.Timer() > 30 and 0 or 30 - Game.Timer()
						local Added = false
						DelayAction(function()
        						for i, enemy in pairs(Yasuo.Common.GetEnemyHeroes()) do
        							if this.SpellData[enemy.charName] then
        								for i, v in pairs(this.SpellData[enemy.charName]) do
        									if enemy and v then
        										local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]
        										this.Menu.Windwall.DetectedSpells:MenuElement({type = MENU, id = v.name, name = enemy.charName.." | "..SlotToStr.." | "..v.name, value = true})
        										this.Menu.Windwall.DetectedSpells[v.name]:MenuElement({id = "Use", name = "Enabled", value = true})
        										this.Menu.Windwall.DetectedSpells[v.name]:MenuElement({id = "Danger", name = "Danger", value = v.danger, min = 1, max = 5, step = 1})
        										Added = true
        									end
        								end
        							end
        						end
        					this.Menu.Windwall.DetectedSpells.info:Remove()
        					if not Added then
        						this.Menu.Windwall.DetectedSpells:MenuElement({id = "info", name = "No Spells Detected", drop = {" "}})
        					end
        					end, Delay)
        				end


        	this.Menu:MenuElement({type = MENU, name = "(WIP) Auto Harass",  id = "AutoHarass"})
        	this.Menu:MenuElement({type = MENU, name = "(WIP) Auto Level Up",  id = "lvlup"})
        	this.Menu:MenuElement({type = MENU, name = "(WIP) Activator",  id = "Items"})
        	this.Menu:MenuElement({type = MENU, name = "(WIP) Drawings",  id = "Draw"})
        	this.Menu:MenuElement({name = " ", drop = {"Script Info"}})
       		this.Menu:MenuElement({name = "Script Version", drop = {"0.1"}})
        	this.Menu:MenuElement({name = "League Version", drop = {"7.15"}})
        	this.Menu:MenuElement({name = "Author", drop = {"Shulepin"}})
	end

	this:LoadMenu()
	Callback.Add("Tick", function() this:OnTick() end)

	return this
end

function OnLoad() Yasuo:Load() end
