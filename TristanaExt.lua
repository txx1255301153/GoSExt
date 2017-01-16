if myHero.charName ~= "Tristana" then return end

require("DamageLib")

function OnLoad() Tristana() end

class "Tristana"

function Tristana:__init()
	self:Menu()

	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Tristana:Menu()
    local Icons = {
    ["Champion"] = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/Tristana.png",
    ["Q"] = "http://static.lolskill.net/img/abilities/64/Tristana_Q.png",
    ["W"] = "http://static.lolskill.net/img/abilities/64/Tristana_W.png",
    ["E"] = "http://static.lolskill.net/img/abilities/64/Tristana_E.png",
    ["R"] = "http://static.lolskill.net/img/abilities/64/Tristana_R.png"
}

	self.Config = MenuElement({type = MENU, name = "Tristana", id = "Tristana", leftIcon = Icons["Champion"]})

	self.Config:MenuElement({type = MENU, name = "Combo Settings", id = "Combo"})
	self.Config.Combo:MenuElement({type = MENU, name = "Rapid Fire (Q)", id = "Q", leftIcon = Icons["Q"]})
	self.Config.Combo.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Combo.Q:MenuElement({name = "Only If Target Has E Debuff", id = "QE", value = false})
	self.Config.Combo:MenuElement({type = MENU, name = "Explosive Charge (E)", id = "E", leftIcon = Icons["E"]})
	self.Config.Combo.E:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Combo.E:MenuElement({type = MENU, name = "WhiteList", id = "WhiteList"})
	for K, Enemy in pairs(Utility:GetEnemyHeroes()) do
		self.Config.Combo.E.WhiteList:MenuElement({name = Enemy.charName, id = Enemy.charName, value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/"..Enemy.charName..".png"})
	end
	self.Config.Combo:MenuElement({type = MENU, name = "Buster Shot (R)", id = "R", leftIcon = Icons["R"]})
	self.Config.Combo.R:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Combo.R:MenuElement({name = "Use E + R Finisher", id = "ER", value = true})

	self.Config:MenuElement({type = MENU, name = "Harass Settings", id = "Harass"})
	self.Config.Harass:MenuElement({type = MENU, name = "Rapid Fire (Q)", id = "Q", leftIcon = Icons["Q"]})
	self.Config.Harass.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Harass.Q:MenuElement({name = "Only If Target Has E Debuff", id = "QE", value = false})
	self.Config.Harass:MenuElement({type = MENU, name = "Explosive Charge (E)", id = "E", leftIcon = Icons["E"]})
	self.Config.Harass.E:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Harass.E:MenuElement({type = MENU, name = "WhiteList", id = "WhiteList"})
	for K, Enemy in pairs(Utility:GetEnemyHeroes()) do
		self.Config.Harass.E.WhiteList:MenuElement({name = Enemy.charName, id = Enemy.charName, value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/"..Enemy.charName..".png"})
	end
	self.Config.Harass:MenuElement({name = "Mana Manager", id = "Mana", value = 45, min = 0, max = 100, step = 1})

	self.Config:MenuElement({type = MENU, name = "Kill Steal Settings", id = "KillSteal"})
	self.Config.KillSteal:MenuElement({type = MENU, name = "Buster Shot (R)", id = "R", leftIcon = Icons["R"]})
	self.Config.KillSteal.R:MenuElement({name = "Enabled", id = "Enabled", value = true})

	self.Config:MenuElement({type = MENU, name = "Draw Settings", id = "Draw"})
	self.Config.Draw:MenuElement({type = MENU, name = "Rapid Fire (Q)", id = "Q", leftIcon = Icons["Q"]})
	self.Config.Draw.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Draw.Q:MenuElement({name = "Color:", id = "Color", color = Draw.Color(255, 255, 255, 255)})
	self.Config.Draw:MenuElement({type = MENU, name = "Rocket Jump (W)", id = "W", leftIcon = Icons["W"]})
	self.Config.Draw.W:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Draw.W:MenuElement({name = "Color:", id = "Color", color = Draw.Color(255, 255, 255, 255)})
	self.Config.Draw:MenuElement({type = MENU, name = "Explosive Charge (E)", id = "E", leftIcon = Icons["E"]})
	self.Config.Draw.E:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Draw.E:MenuElement({name = "Color:", id = "Color", color = Draw.Color(255, 255, 255, 255)})
	self.Config.Draw:MenuElement({type = MENU, name = "Buster Shot (R)", id = "R", leftIcon = Icons["R"]})
	self.Config.Draw.R:MenuElement({name = "Enabled", id = "Enabled", value = true})
	self.Config.Draw.R:MenuElement({name = "Color:", id = "Color", color = Draw.Color(255, 255, 255, 255)})
	self.Config.Draw:MenuElement({name = "Disable All Drawings", id = "Disabled", value = false})
end

function Tristana:GetTarget(range)
	local GetEnemyHeroes = Utility:GetEnemyHeroes()
	local Target = nil
        for i = 1, #GetEnemyHeroes do
    	local Enemy = GetEnemyHeroes[i]
        if Utility:IsValidTarget(Enemy, range, false, myHero.pos) then
            Target   = Enemy
        end
    end
    return Target
end

function Tristana:GetQRange()
	local lvl = (myHero.levelData.lvl - 1) * 7
	local Q = 605 + lvl
	return Q
end

function Tristana:GetERange()
	local lvl = (myHero.levelData.lvl - 1) * 7
	local E = 635 + lvl
	return E
end

function Tristana:GetRRange()
	local lvl = (myHero.levelData.lvl - 1) * 7
	local R = 635 + lvl
	return R
end

function Tristana:Update()
	self:GetQRange()
	self:GetERange()
	self:GetRRange()
	self:KillSteal()
end

function Tristana:Tick()
	self:Update()
	if not myHero.dead then
		local target = self:GetTarget(2000)

		if target then
			if Utility:Mode() == "Combo" then
				self:Combo(target)
			elseif Utility:Mode() == "Harass" then
				self:Harass(target)
			end
		end
	end
end

function Tristana:Combo(target)
	if target then
		if self.Config.Combo.R.Enabled:Value() then
			if getdmg("R", target, myHero) > target.health then
				self:CastR(target)
			end
			if self.Config.Combo.R.ER:Value() then
				local DMG = getdmg("R", target, myHero) + getdmg("E", target, myHero) * (0.5 * Utility:GetBuffData(target, "tristanaecharge").count + 1)
				if DMG > target.health + 25 then
					self:CastR(target)
				end
			end
		end
		if self.Config.Combo.Q.Enabled:Value() then
			if self.Config.Combo.Q.QE:Value() then
				if Utility:HasBuff(target, "tristanaecharge") then
					self:CastQ(target)
				end
			else
				self:CastQ(target)
			end
		end
		if self.Config.Combo.E.Enabled:Value() then
			if self.Config.Combo.E.WhiteList[target.charName]:Value() then
				self:CastE(target)
			end
		end
	end
end

function Tristana:Harass(target)
	if target and Utility:GetPercentMP(myHero) >= self.Config.Harass.Mana:Value() then
		if self.Config.Harass.Q.Enabled:Value() then
			if self.Config.Harass.Q.QE:Value() then
				if Utility:HasBuff(target, "tristanaecharge") then
					self:CastQ(target)
				end
			else
				self:CastQ(target)
			end
		end
		if self.Config.Harass.E.Enabled:Value() then
			if self.Config.Harass.E.WhiteList[target.charName]:Value() then
				self:CastE(target)
			end
		end
	end
end

function Tristana:KillSteal()
	for K, Enemy in pairs(Utility:GetEnemyHeroes()) do
		if self.Config.KillSteal.R.Enabled:Value() then
			if getdmg("R", Enemy, myHero) > Enemy.health then
				self:CastR(Enemy)
			end
		end
	end
end

function Tristana:CastQ(target)
	if target and Utility:IsValidTarget(target, self:GetQRange(), false, myHero.pos) then
		if Utility:IsReady(_Q) then
			Control.CastSpell(HK_Q)
	    end
	end
end

function Tristana:CastE(target)
	if target and Utility:IsValidTarget(target, self:GetERange(), false, myHero.pos) then
		if Utility:IsReady(_E) then
			Control.CastSpell(HK_E, target.pos)
	    end
	end
end

function Tristana:CastR(target)
	if target and Utility:IsValidTarget(target, self:GetRRange(), false, myHero.pos) then
		if Utility:IsReady(_R) then
			Control.CastSpell(HK_R, target.pos)
	    end
	end
end

function Tristana:Draw()
	if self.Config.Draw.Disabled:Value() then return end

	if self.Config.Draw.Q.Enabled:Value() and Utility:IsReady(_Q) then
		Draw.Circle(myHero.pos, self:GetQRange(), 1, self.Config.Draw.Q.Color:Value())
	end
	if self.Config.Draw.W.Enabled:Value() and Utility:IsReady(_W) then
		Draw.Circle(myHero.pos, myHero:GetSpellData(_W).range, 1, self.Config.Draw.W.Color:Value())
	end
	if self.Config.Draw.E.Enabled:Value() and Utility:IsReady(_E) then
		Draw.Circle(myHero.pos, self:GetERange(), 1, self.Config.Draw.E.Color:Value())
	end
	if self.Config.Draw.R.Enabled:Value() and Utility:IsReady(_R) then
		Draw.Circle(myHero.pos, self:GetRRange(), 1, self.Config.Draw.R.Color:Value())
	end
end

class "Utility"

function Utility:__init()
end

function Utility:Mode()
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

Utility()
