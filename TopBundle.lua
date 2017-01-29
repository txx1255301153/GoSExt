class "Poppy"

function Poppy:__init()
	require("MapPositionGoS")

	self:Variables()
	self:Menu()
	self:Callbacks()
end

function Poppy:Menu()
    self.Icons = {
        ["H"] = "http://static.lolskill.net/img/champions/64/poppy.png",
        ["Q"] = "http://static.lolskill.net/img/abilities/64/Poppy_Q.png",
        ["W"] = "http://static.lolskill.net/img/abilities/64/Poppy_W.png",
        ["E"] = "http://static.lolskill.net/img/abilities/64/Poppy_E.png",
        ["R"] = "http://static.lolskill.net/img/abilities/64/Poppy_R.png"
    }
    
    -->Main Menu
	self.Config = MenuElement({type = MENU, name = "Top Bundle | Poppy",  id = "Poppy", leftIcon = self.Icons["H"]})
	    -->TargetSelector Menu
	        self.Config:MenuElement({type = MENU, name = "Target Selector", id = "TS"})
	            -->TargetSelector Menu: Settings
	            self.Config.TS:MenuElement({name = "Mode", id = "Mode", value = 1, drop = {"Closest To You", "Closest To Mouse"}})
	            self.Config.TS:MenuElement({name = "Attack Selected Target", id = "AST", value = true})
        -->Combo Menu
	    self.Config:MenuElement({type = MENU, name = "Combo", id = "Combo"})
	        -->Combo Menu: Settings
	        self.Config.Combo:MenuElement({name = "Use Q", id = "Q", value = true, leftIcon = self.Icons["Q"]})
	        self.Config.Combo:MenuElement({name = "Use W", id = "W", value = true, leftIcon = self.Icons["W"]})
	        self.Config.Combo:MenuElement({name = "Use E", id = "E", value = true, leftIcon = self.Icons["E"]})
	        self.Config.Combo:MenuElement({type = SPACE})
	        self.Config.Combo:MenuElement({name = "Combo Key", id = "Key", key = string.byte(" ")})
	    -->Harass Menu
	    self.Config:MenuElement({type = MENU, name = "Harass", id = "Harass"})
	        -->Harass Menu: Settings
	        self.Config.Harass:MenuElement({name = "Use Q", id = "Q", value = true, leftIcon = self.Icons["Q"]})
	        self.Config.Harass:MenuElement({name = "Use W", id = "W", value = false, leftIcon = self.Icons["W"]})
	        self.Config.Harass:MenuElement({name = "Use E", id = "E", value = true, leftIcon = self.Icons["E"]})
	        self.Config.Harass:MenuElement({type = SPACE})
	        self.Config.Harass:MenuElement({name = "Harass Key", id = "Key", key = string.byte("C")})
	        self.Config.Harass:MenuElement({name = "Mana Manager", id = "Mana", min = 0, max = 100, value = 45, step = 1})
	    -->Draw Menu
	        self.Config:MenuElement({type = MENU, name = "Drawings", id = "Drawings"})
	        -->Draw Menu: Settings
	            self.Config.Drawings:MenuElement({name = "Draw Q Range", id = "Q", value = false, leftIcon = self.Icons["Q"]})
	            self.Config.Drawings:MenuElement({name = "Color:", id = "QColor", color = Draw.Color(255, 255, 255, 255)})
	            self.Config.Drawings:MenuElement({name = "Draw W Range", id = "W", value = false, leftIcon = self.Icons["W"]})
	            self.Config.Drawings:MenuElement({name = "Color:", id = "WColor", color = Draw.Color(255, 255, 255, 255)})
	            self.Config.Drawings:MenuElement({name = "Draw E Range", id = "E", value = true, leftIcon = self.Icons["E"]})
	            self.Config.Drawings:MenuElement({name = "Color:", id = "EColor", color = Draw.Color(255, 255, 255, 255)})
	            self.Config.Drawings:MenuElement({name = "Draw R Range", id = "R", value = false, leftIcon = self.Icons["R"]})
	            self.Config.Drawings:MenuElement({name = "Color:", id = "RColor", color = Draw.Color(255, 255, 255, 255)})
	            self.Config.Drawings:MenuElement({type = SPACE})
	            self.Config.Drawings:MenuElement({name = "Draw Selected Target", id = "S", value = true})
	            self.Config.Drawings:MenuElement({name = "Draw E End Pos", id = "EndPos", value = true})
	            self.Config.Drawings:MenuElement({name = "Disable All Drawings", id = "Disabled", value = false})
end

function Poppy:Variables()
	self.SelectedTarget = nil

	self.TSMode = {
	    [1] = function() return Utility:Closest() end,
	    [2] = function() return Utility:ClosestM() end
	}
end

function Poppy:Callbacks()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	Callback.Add("WndMsg", function(MSG, KEY) self:WndMsg(MSG, KEY) end)
end

function Poppy:Tick()
	local target = self:GetTarget()
	if target then
		self:Combo(target)
		self:Harass(target)
	end
end

function Poppy:Draw()
	if self.Config.Drawings.Disabled:Value() then return end
	local k = true
	if k then
		local target = self.SelectedTarget
		if target then
			if self.Config.Drawings.S:Value() then Draw.Circle(target.pos, 100, 3, Draw.Color(255, 255, 0, 0)) end
			if self.Config.Drawings.EndPos:Value() then 
			    Draw.Circle(E_EndPos(target), target.boundingRadius, 1)
		        Draw.Line(target.pos:To2D().x, target.pos:To2D().y, E_EndPos(target):To2D().x, E_EndPos(target):To2D().y)
		    end
		end
	end

	if self.Config.Drawings.Q:Value() and Utility:IsReady(_Q) then
		Draw.Circle(myHero.pos, myHero:GetSpellData(_Q).range, 1, self.Config.Drawings.QColor:Value())
	end
	if self.Config.Drawings.W:Value() and Utility:IsReady(_W) then
		Draw.Circle(myHero.pos, myHero:GetSpellData(_W).range, 1, self.Config.Drawings.WColor:Value())
	end
	if self.Config.Drawings.E:Value() and Utility:IsReady(_E) then
		Draw.Circle(myHero.pos, myHero:GetSpellData(_E).range, 1, self.Config.Drawings.EColor:Value())
	end
	if self.Config.Drawings.R:Value() and Utility:IsReady(_R) then
		Draw.Circle(myHero.pos, myHero:GetSpellData(_R).range, 1, self.Config.Drawings.RColor:Value())
	end
end

function Poppy:WndMsg(MSG, KEY) 
	if MSG == 513 and KEY == 0 then
		for _, ENEMY in pairs(Utility:GetEnemyHeroes()) do
			if not ENEMY.dead and mousePos:DistanceTo(ENEMY.pos) <= ENEMY.boundingRadius * 2 then
				self.SelectedTarget = ENEMY
				return
			end
		end
		self.SelectedTarget = nil
	end
end

function Poppy:GetTarget()
	if self.Config.TS.AST:Value() and self.SelectedTarget then
		return self.SelectedTarget
	end
	return self.TSMode[self.Config.TS.Mode:Value()]()
end

function Poppy:Combo(target)
	if target and Utility:ImOk() then
		if Utility:Mode() == "Combo" or self.Config.Combo.Key:Value() then
			if self.Config.Combo.W:Value() then self:CastW(target) end
			if self.Config.Combo.E:Value() then self:CastE(target) end
			if self.Config.Combo.Q:Value() then self:CastQ(target) end
		end
	end
end

function Poppy:Harass(target)
	if target and Utility:ImOk() and Utility:GetPercentMP(myHero) >= self.Config.Harass.Mana:Value() and Utility:ImOk() then
		if Utility:Mode() == "Harass" or self.Config.Harass.Key:Value() then
			if self.Config.Harass.W:Value() then self:CastW(target) end
			if self.Config.Harass.E:Value() then self:CastE(target) end
			if self.Config.Harass.Q:Value() then self:CastQ(target) end
		end
	end
end

function E_EndPos(target)
	return target.pos:Extended(myHero.pos, -425)
end

function Poppy:CastQ(target)
	if target then
		if Utility:IsReady(_Q) and Utility:IsValidTarget(target, myHero:GetSpellData(_Q).range, false, myHero.pos) then
			local Speed = myHero:GetSpellData(spell).speed
			local Delay = myHero:GetSpellData(spell).delay
			local Prediction = target:GetPrediction(Speed, Delay)
			Utility:CastSpell(HK_Q, Prediction, myHero:GetSpellData(_Q).range)
		end
	end
end

function Poppy:CastW(target)
	if target then
		if Utility:IsReady(_W) and Utility:IsValidTarget(target, myHero:GetSpellData(_W).range, false, myHero.pos) then
			Control.CastSpell(HK_W)
		end
	end
end

function Poppy:CastE(target)
	if target then
		if Utility:IsReady(_E) and Utility:IsValidTarget(target, myHero:GetSpellData(_E).range, false, myHero.pos) then
			if MapPosition:inWall(E_EndPos(target)) then
				Utility:CastSpell(HK_E, target.pos, myHero:GetSpellData(_E).range)
			end
		end
	end
end

class "Utility"

castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
function Utility:CastSpell(spell,pos,range,delay)
local delay = delay or 250
local ticker = GetTickCount()
	if castSpell.state == 0 and myHero.pos:DistanceTo(pos) < range and ticker - castSpell.casting > delay + Game.Latency()then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < Game.Latency() then
			Control.SetCursorPos(pos)
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					Control.SetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,Game.Latency()/1000)
		end
		if ticker - castSpell.casting > Game.Latency() then
			Control.SetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

function Utility:Mode()
	if EOWLoaded then
		return EOW:Mode()
	else
		if Orbwalker["Combo"].__active then
		    return "Combo"
	    elseif Orbwalker["Farm"].__active then
		    return "LaneClear" 
	    elseif Orbwalker["LastHit"].__active then
		    return "LastHit"
	    elseif Orbwalker["Harass"].__active then
		    return "Harass"
	    end
	    return ""
	end
end

function Utility:Closest()
	local c = math.huge
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do
		if e.distance < c then
			c = e.distance
			t = e
		end
	end
	return t
end

function Utility:ClosestM()
	local c = math.huge
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do
		if e.pos:DistanceTo(mousePos) < c then
			c = e.pos:DistanceTo(mousePos)
			t = e
		end
	end
	return t
end

function Utility:HighestAD()
	local c = 0
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do
		if e.totalDamage > c then
			c = e.totalDamage
			t = e 
		end
	end
	return t
end

function Utility:HighestAP()
	local c = 0
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do
		if e.ap > c then
			c = e.ap
			t = e
		end
	end		
end

function Utility:HighestHP()
	local c = 0
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do 
		if e.health > c then
			c = e.health
			t = e 
		end
	end
	return t
end

function Utility:LowestHP()
	local c = math.huge
	local t = nil
	for _, e in pairs(Utility:GetEnemyHeroes()) do 
		if e.health < c then
			c = e.health
			t = e
		end
	end
	return t
end

function Utility:GetPercentHP(unit)
	return 100 * unit.health / unit.maxHealth
end

function Utility:GetPercentMP(unit)
	return 100 * unit.mana / unit.maxMana
end

function Utility:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Utility:GetEnemyMinions()
	self.EnemyMinions = {}
	for i = 1, Game.MinionCount() do
		local Minion = Game.Minion(i)
		if Minion.isEnemy then
			table.insert(self.EnemyMinions, Minion)
		end
	end
	return self.EnemyMinions
end

function Utility:GetAllyHeroes()
	self.AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and not Hero.isMe then
			table.insert(self.AllyHeroes, Hero)
		end
	end
	return self.AllyHeroes
end

function Utility:GetBuffs(unit)
	self.T = {}
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.count > 0 then
			table.insert(self.T, Buff)
		end
	end
	return self.T
end

function Utility:HasBuff(unit, buffname)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if Buff.name:lower() == buffname:lower() then
			return true
		end
	end
	return false
end

function Utility:GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.name:lower() == buffname:lower() and Buff.count > 0 then
			return Buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end

function Utility:IsImmune(unit)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if (Buff.name == "kindredrnodeathbuff" or Buff.name == "undyingrage") and self:GetPercentHP(unit) <= 10 then
			return true
		end
		if Buff.name == "vladimirsanguinepool" or Buff.name == "judicatorintervention" then 
            return true
        end
	end
	return false
end

function Utility:IsValidTarget(unit, range, checkTeam, from)
    local range = range == nil and math.huge or range
    if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or self:IsImmune(unit) or (checkTeam and unit.isAlly) then 
        return false 
    end 
    return unit.pos:DistanceTo(from and from or myHero) < range 
end

function Utility:IsReady(slot)
	if myHero:GetSpellData(slot).currentCd < 0.01 and myHero.mana > myHero:GetSpellData(slot).mana then
		return true
	end
	return false
end

function Utility:ImOk()
	for i = 0, myHero.buffCount do
		local buff = myHero:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 ) and buff.count > 0 then
			return false
		end
	end
	return true
end

function OnLoad()
	if _G[myHero.charName] then _G[myHero.charName]() end
end
