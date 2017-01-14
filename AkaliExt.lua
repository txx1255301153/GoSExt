if myHero.charName ~= "Akali" then return end

require("DamageLib")

-------------------------------------------------UTILITY---------------------------------------------------------------

local TickH, TickL = 0, 0

local _AllyHeroes

function GetAllyHeroes()
  if _AllyHeroes then return _AllyHeroes end
  _AllyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly then
      table.insert(_AllyHeroes, unit)
    end
  end
  return _AllyHeroes
end

local _EnemyHeroes

function GetEnemyHeroes()
  if _EnemyHeroes then return _EnemyHeroes end
  _EnemyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isEnemy then
      table.insert(_EnemyHeroes, unit)
    end
  end
  return _EnemyHeroes
end

function GetPercentHP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.health/unit.maxHealth
end

function GetPercentMP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.mana/unit.maxMana
end

function GetRange(spell)
  return myHero:GetSpellData(spell).range
end

function GetSpeed(spell)
    return myHero:GetSpellData(spell).speed
end

function GetWidth(spell)
    return myHero:GetSpellData(spell).width
end

local function GetBuffs(unit)
  local t = {}
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.count > 0 then
      table.insert(t, buff)
    end
  end
  return t
end

function HasBuff(unit, buffname)
  if type(unit) ~= "userdata" then error("{HasBuff}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  if type(buffname) ~= "string" then error("{HasBuff}: bad argument #2 (string expected, got "..type(buffname)..")") end
  for i, buff in pairs(GetBuffs(unit)) do
    if buff.name == buffname then 
      return true
    end
  end
  return false
end

function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(unit).itemID == id then
      return i
    end
  end
  return 0 -- 
end

function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

function GetMinions(team) --> " " - All | 100 - Ally | 200 - Enemy | 300 - Jungle
    local Minions
    if Minions then return Minions end
    Minions = {}
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if team then
            if Minion.team == team then
                table.insert(Minions, Minion)
            end
        else
            table.insert(Minions, Minion)
        end
    end
    return Minions
end

function IsImmune(unit)
  if type(unit) ~= "userdata" then error("{IsImmune}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  for i, buff in pairs(GetBuffs(unit)) do
    if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and GetPercentHP(unit) <= 10 then
      return true
    end
    if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
      return true
    end
  end
  return false
end 

function IsValidTarget(unit, range, checkTeam, from)
  local range = range == nil and math.huge or range
  if type(range) ~= "number" then error("{IsValidTarget}: bad argument #2 (number expected, got "..type(range)..")") end
  if type(checkTeam) ~= "nil" and type(checkTeam) ~= "boolean" then error("{IsValidTarget}: bad argument #3 (boolean or nil expected, got "..type(checkTeam)..")") end
  if type(from) ~= "nil" and type(from) ~= "userdata" then error("{IsValidTarget}: bad argument #4 (vector or nil expected, got "..type(from)..")") end
  if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or IsImmune(unit) or (checkTeam and unit.isAlly) then 
    return false 
  end 
  return unit.pos:DistanceTo(from and from or myHero) < range 
end

function CountAlliesInRange(point, range)
  if type(point) ~= "userdata" then error("{CountAlliesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
  local range = range == nil and math.huge or range 
  if type(range) ~= "number" then error("{CountAlliesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
  local n = 0
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly and not unit.isMe and IsValidTarget(unit, range, false, point) then
      n = n + 1
    end
  end
  return n
end

function CountEnemiesInRange(point, range)
  if type(point) ~= "userdata" then error("{CountEnemiesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
  local range = range == nil and math.huge or range 
  if type(range) ~= "number" then error("{CountEnemiesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
  local n = 0
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if IsValidTarget(unit, range, true, point) then
      n = n + 1
    end
  end
  return n
end

function CanUseSpell(unit, spell)
    if unit:GetSpellData(spell).currentCd == 0 and unit.mana > unit:GetSpellData(spell).mana then
        return true
    else
        return false
    end
end

local fountain

for i = 1, Game.ObjectCount() do
  local object = Game.Object(i)
  if object.isEnemy or object.type ~= Obj_AI_SpawnPoint then 
    goto continue
  end
  fountain = object
  break
  ::continue::
end

function InFountain(unit)
  if type(unit) ~= "userdata" then error("{InFountain}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  local range = Game.mapID() == SUMMONERS_RIFT and 1100 or 750
  return unit.visible and unit.pos:DistanceTo(fountain)-unit.boundingRadius <= range
end

function InShop(unit)
  if type(unit) ~= "userdata" then error("{InShop}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  local range = Game.mapID() == SUMMONERS_RIFT and 1000 or 750
  return unit.visible and unit.pos:DistanceTo(fountain)-unit.boundingRadius <= range
end

local function AngleBetween(p1, p2)
  local theta = p1:Polar() - p2:Polar()
  if theta < 0 then
    theta = theta + 360
  end
  if theta > 180 then
    theta = 360 - theta
  end
  return theta
end

function IsFacing(unit, target)
  if type(unit) ~= "userdata" then error("{IsFacing}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  if type(target) ~= "userdata" then error("{IsFacing}: bad argument #2 (userdata expected, got "..type(target)..")") end
  return AngleBetween(unit.dir, target.pos-unit.pos) < 90
end

function IsOnScreen(pos)
  if type(pos) ~= "userdata" then error("{IsOnScreen}: bad argument #1 (vector expected, got "..type(pos)..")") end
  local p = pos.pos2D
  local res = Game.Resolution()
  return p.x > 0 and p.y > 0 and p.x <= res.x and p.y <= res.y
end

function UnderEnemyTurret(unit)
        for i = 1, Game.TurretCount() do
            local turret = Game.Turret(i)
            local range = (turret.boundingRadius + 750 + myHero.boundingRadius / 2)
            if turret.valid and turret.isEnemy and unit.pos:DistanceTo(turret.pos) <= range then
                return true
            end
        end
        return false
end

-------------------------------------------------AKALI-----------------------------------------------------------------

local Config = MenuElement({type = MENU, name = "Akali", id = "Akali", leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/Akali.png"})

Config:MenuElement({type = MENU, name = "Combo Settings", id = "Combo"})

Config.Combo:MenuElement({type = MENU, name = "Mark of the Assassin (Q)", id = "Q", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliMota.png"})
Config.Combo.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})

--Config.Combo:MenuElement({type = MENU, name = "Twilight Shroud (W)", id = "W", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliTwilightShroud.png"})
--Config.Combo.W:MenuElement({name = "Enabled", id = "Enabled", value = true})

Config.Combo:MenuElement({type = MENU, name = "Crescent Slash (E)", id = "E", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliCrescentSlash.png"})
Config.Combo.E:MenuElement({name = "Enabled", id = "Enabled", value = true})

Config.Combo:MenuElement({type = MENU, name = "Shadow Dance (R)", id = "R", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliShadowDance.png"})
Config.Combo.R:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.Combo.R:MenuElement({name = "Turret Check", id = "Turret", value = true})
Config.Combo.R:MenuElement({type = MENU, name = "GapClose Settings", id = "GapClose"})
Config.Combo.R.GapClose:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.Combo.R.GapClose:MenuElement({name = "Min. R Stacks", id = "Stacks", value = 2, min = 0, max = 3, step = 1})
Config.Combo.R.GapClose:MenuElement({name = "Max. Enemies Around Target", id = "Enemies", value = 0, min = 0, max = 4, step = 1})

Config:MenuElement({type = MENU, name = "Harass Settings", id = "Harass"})

Config.Harass:MenuElement({type = MENU, name = "Mark of the Assassin (Q)", id = "Q", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliMota.png"})
Config.Harass.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.Harass.Q:MenuElement({type = MENU, name = "Auto Q Settings", id = "Auto"})
Config.Harass.Q.Auto:MenuElement({name = "Enabled", id = "Enabled", value = false})
Config.Harass.Q.Auto:MenuElement({name = "Energy Manager", id = "Energy", value = 100, min = 0, max = 200, step = 5})
Config.Harass.Q.Auto:MenuElement({type = MENU, name = "White List", id = "WhiteList"})
for _, Enemy in pairs(GetEnemyHeroes()) do
        Config.Harass.Q.Auto.WhiteList:MenuElement({name = Enemy.charName, id = Enemy.charName, value = true})
end

Config.Harass:MenuElement({type = MENU, name = "Crescent Slash (E)", id = "E", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliCrescentSlash.png"})
Config.Harass.E:MenuElement({name = "Enabled", id = "Enabled", value = true})

Config.Harass:MenuElement({name = "Energy Manager", id = "Energy", value = 100, min = 0, max = 200, step = 5})

Config:MenuElement({type = MENU, name = "Last Hit Settings", id = "LastHit"})

Config.LastHit:MenuElement({type = MENU, name = "Mark of the Assassin (Q)", id = "Q", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliMota.png"})
Config.LastHit.Q:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.LastHit.Q:MenuElement({type = MENU, name = "Auto Q Settings", id = "Auto"})
Config.LastHit.Q.Auto:MenuElement({name = "Enabled", id = "Enabled", value = false})
Config.LastHit.Q.Auto:MenuElement({name = "Energy Manager", id = "Energy", value = 100, min = 0, max = 200, step = 5})

Config.LastHit:MenuElement({type = MENU, name = "Crescent Slash (E)", id = "E", leftIcon = "http://static.lolskill.net/img/abilities/64/AkaliCrescentSlash.png"})
Config.LastHit.E:MenuElement({name = "Enabled", id = "Enabled", value = true})

Config.LastHit:MenuElement({name = "Energy Manager", id = "Energy", value = 100, min = 0, max = 200, step = 5})

Config:MenuElement({type = MENU, name = "Key Settings", id = "Key"})

Config.Key:MenuElement({id = "Combo", name = "Combo", key = 32})
Config.Key:MenuElement({id = "Harass", name = "Harass", key = string.byte("C")})
Config.Key:MenuElement({id = "LastHit", name = "Last Hit", key = string.byte("X")})
Config.Key:MenuElement({id = "HarassAuto", name = "Auto Harass Q", key = string.byte("T")})
Config.Key:MenuElement({id = "LastHitAuto", name = "Auto LastHit Q", key = string.byte("G")})

function OnTick()
        SwitchHarass()
        SwitchLastHit()
        if not myHero.dead then
                local target = GetTarget(3000)
                if target then
                        Combo(target)
                        Harass(target)
                        AutoHarass()
                end
                LastHit()
                AutoLastHit()
        end
end

function MinionForGap(target)
        local ClosestMinion, NearestDistance = nil, 0

        for _, Minion in pairs(GetMinions(200)) do
                if not Minion.dead then
                        if myHero.pos:DistanceTo(Minion.pos) <= GetRange(_R) and target and target.pos:DistanceTo(Minion.pos) <= GetRange(_R) then
                                if NearestDistance < myHero.pos:DistanceTo(Minion.pos) then
                                        NearestDistance = myHero.pos:DistanceTo(Minion.pos)
                    ClosestMinion = Minion
                                end
                        end
                end
        end
    return ClosestMinion
end

function GetTarget(range)
        local target, _ = nil, nil
        for i = 1, #GetEnemyHeroes() do
        local Enemy = GetEnemyHeroes()[i]
        if IsValidTarget(Enemy, range, false, myHero.pos) then
            local K = Enemy.health / getdmg("AA", Enemy, myHero)
            if not _ or K < _ then
                target = Enemy
                _ = K
            end
        end
    end
    return target
end

function Combo(target)
        if Config.Key.Combo:Value() then
                if Config.Combo.Q.Enabled:Value() then
                        if CanUseSpell(myHero, _Q) and IsValidTarget(target, GetRange(_Q), false, myHero.pos) then
                                Control.CastSpell(HK_Q, target.pos)
                        end
                end
                if Config.Combo.E.Enabled:Value() then
                        if CanUseSpell(myHero, _E) and IsValidTarget(target, GetRange(_E), false, myHero.pos) then
                                Control.CastSpell(HK_E)
                        end
                end
                if Config.Combo.R.Enabled:Value() then
                        if CanUseSpell(myHero, _R) and IsValidTarget(target, GetRange(_R), false, myHero.pos) then
                                if Config.Combo.R.Turret:Value() then
                                        if not UnderEnemyTurret(target) then
                                                Control.CastSpell(HK_R, target.pos)
                                        end
                                else
                                        Control.CastSpell(HK_R, target.pos)
                                end
                        end
                        if Config.Combo.R.GapClose.Enabled:Value() then
                             if CanUseSpell(myHero, _R) and IsValidTarget(target, GetRange(_R) * 2 + 100, false, myHero.pos) then
                                if myHero.pos:DistanceTo(target.pos) > GetRange(_R) then
                                        if MinionForGap(target) ~= nil and myHero:GetSpellData(_R).ammo > Config.Combo.R.GapClose.Stacks:Value() and CountEnemiesInRange(target, 950) <= Config.Combo.R.GapClose.Enemies:Value() then
                                                if Config.Combo.R.Turret:Value() then
                                                    if not UnderEnemyTurret(target) then
                                                            Control.CastSpell(HK_R, MinionForGap(target).pos)
                                                    end
                                            else
                                                    Control.CastSpell(HK_R, MinionForGap(target).pos)
                                            end
                                        end
                                end
                             end                
                        end
                end
        end
end

function Harass(target)
        if Config.Key.Harass:Value() and myHero.mana >= Config.Harass.Energy:Value() then
                if Config.Harass.Q.Enabled:Value() then
                        if CanUseSpell(myHero, _Q) and IsValidTarget(target, GetRange(_Q), false, myHero.pos) then
                                Control.CastSpell(HK_Q, target.pos)
                        end
                end
                if Config.Harass.E.Enabled:Value() then
                        if CanUseSpell(myHero, _E) and IsValidTarget(target, GetRange(_E), false, myHero.pos) then
                                Control.CastSpell(HK_E)
                        end
                end
        end
end

function LastHit()
        for _, Minion in pairs(GetMinions(200)) do
                if Config.Key.LastHit:Value() and myHero.mana >= Config.LastHit.Energy:Value() then
                    if Config.LastHit.Q.Enabled:Value() and getdmg("Q", Minion, myHero) > Minion.health then
                            if CanUseSpell(myHero, _Q) and IsValidTarget(Minion, GetRange(_Q), false, myHero.pos) then
                                    Control.CastSpell(HK_Q, Minion.pos)
                            end
                    end
                    if Config.LastHit.E.Enabled:Value() and getdmg("E", Minion, myHero) > Minion.health then
                        if CanUseSpell(myHero, _E) and IsValidTarget(Minion, GetRange(_E), false, myHero.pos) then
                                    Control.CastSpell(HK_E)
                            end
                    end
            end
        end
end

function AutoHarass()
        if Config.Harass.Q.Auto.Enabled:Value() and myHero.mana > Config.Harass.Q.Auto.Energy:Value() then
                for _, Enemy in pairs(GetEnemyHeroes()) do
                        if Config.Harass.Q.Auto.WhiteList[Enemy.charName]:Value() then
                                if CanUseSpell(myHero, _Q) and IsValidTarget(Enemy, GetRange(_Q), false, myHero.pos) then
                                    Control.CastSpell(HK_Q, Enemy.pos)
                            end
                        end
                end
        end
end

function AutoLastHit()
        if Config.LastHit.Q.Auto.Enabled:Value() and myHero.mana > Config.LastHit.Q.Auto.Energy:Value() then
                for _, Minion in pairs(GetMinions(200)) do
                        if getdmg("Q", Minion, myHero) > Minion.health then
                                if CanUseSpell(myHero, _Q) and IsValidTarget(Minion, GetRange(_Q), false, myHero.pos) then
                                    Control.CastSpell(HK_Q, Minion.pos)
                            end
                        end
                end
        end
end

function SwitchHarass()
        if Config.Key.HarassAuto:Value() then
                if TickH+200 < GetTickCount() then
                        if Config.Harass.Q.Auto.Enabled:Value() == true then
                                Config.Harass.Q.Auto.Enabled:Value(false)
                        elseif Config.Harass.Q.Auto.Enabled:Value() == false then
                                Config.Harass.Q.Auto.Enabled:Value(true)
                        end
                        TickH = GetTickCount()
                end
        end
end

function SwitchLastHit()
        if Config.Key.LastHitAuto:Value() then
                if TickL+200 < GetTickCount() then
                        if Config.LastHit.Q.Auto.Enabled:Value() == true then
                                Config.LastHit.Q.Auto.Enabled:Value(false)
                        elseif Config.LastHit.Q.Auto.Enabled:Value() == false then
                                Config.LastHit.Q.Auto.Enabled:Value(true)
                        end
                        TickL = GetTickCount()
                end
        end
end

function OnDraw()
        local target = GetTarget(3000)
        if target and MinionForGap(target) ~= nil then
                Draw.Circle(MinionForGap(target).pos, 75, 1)
        end

        local ColorGrey = Draw.Color(255, 153, 153, 153)

        if Config.Harass.Q.Auto.Enabled:Value() then
                Draw.Text("Auto Harass [Q]: On", 16 ,myHero.pos2D.x-45, myHero.pos2D.y+30)
        else
                Draw.Text("Auto Harass [Q]: Off", 16 ,myHero.pos2D.x-45, myHero.pos2D.y+30, ColorGrey)
        end
        if Config.LastHit.Q.Auto.Enabled:Value() then
                Draw.Text("Auto LastHit [Q]: On", 16 ,myHero.pos2D.x-45, myHero.pos2D.y+47)
        else
                Draw.Text("Auto LastHit [Q]: Off", 16 ,myHero.pos2D.x-45, myHero.pos2D.y+47, ColorGrey)
        end
end
