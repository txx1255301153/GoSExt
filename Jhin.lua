if myHero.charName ~= "Jhin" then return end

local Q, W, E, R, Config
local _________ = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}

local CastSpell = function(spell, pos, range, delay)
        local delay = delay or 250
        local ticker = GetTickCount()
        if _________.state == 0 and myHero.pos:DistanceTo(pos) < range and ticker - _________.casting > delay + Game.Latency()then
                _________.state = 1
                _________.mouse = mousePos
                _________.tick = ticker
        end
        if _________.state == 1 then
                if ticker - _________.tick < Game.Latency() then
                        Control.SetCursorPos(pos)
                        Control.KeyDown(spell)
                        Control.KeyUp(spell)
                        _________.casting = ticker + delay
                        DelayAction(function()
                                if _________.state == 1 then
                                        Control.SetCursorPos(_________.mouse)
                                        _________.state = 0
                                end
                        end,Game.Latency()/1000)
                end
                if ticker - _________.casting > Game.Latency() then
                        Control.SetCursorPos(_________.mouse)
                        _________.state = 0
                end
        end
end

local Icons = {
        ["H"] = "http://i.imgur.com/1lOJ2Qf.png",
        ["S"] = "http://i.imgur.com/tpdLJ2S.png",
        ["Q"] = "http://i.imgur.com/Sa2J5dK.png",
        ["W"] = "http://i.imgur.com/QPwfBkF.png",
        ["E"] = "http://i.imgur.com/jX0JzcU.png",
        ["R"] = "http://i.imgur.com/w7anaQo.png"
}

local Menu = function()
        Config = MenuElement({type = MENU, name = "Jhin",  id = "Jhin", leftIcon = Icons["H"]})

        Config:MenuElement({type = MENU, name = "Combo",  id = "Combo", leftIcon = Icons["S"]})

        Config.Combo:MenuElement({type = MENU, name = "[Q] Dancing Grenade",  id = "Q", leftIcon = Icons["Q"]})
        Config.Combo.Q:MenuElement({name = "Use [Q]",  id = "Use", value = true, leftIcon = Icons["Q"]})

        Config.Combo:MenuElement({type = MENU, name = "[W] Deadly Flourish",  id = "W", leftIcon = Icons["W"]})
        Config.Combo.W:MenuElement({name = "Use [W]",  id = "Use", value = true, leftIcon = Icons["W"]})
        Config.Combo.W:MenuElement({name = "Use [W] Only When Stunnable",  id = "Stun", value = true, leftIcon = Icons["W"]})

        Config.Combo:MenuElement({type = MENU, name = "[E] Captive Audience",  id = "E", leftIcon = Icons["E"]})
        Config.Combo.E:MenuElement({name = "Use [E]",  id = "Use", value = true, leftIcon = Icons["E"]})
        Config.Combo.E:MenuElement({name = "Use [E] Only When Immobile",  id = "Stun", value = true, leftIcon = Icons["E"]})

        Config.Combo:MenuElement({type = MENU, name = "[R] Curtain Call",  id = "R", leftIcon = Icons["R"]})
        Config.Combo.R:MenuElement({name = "Use [R]",  id = "Use", value = true, leftIcon = Icons["R"]})
        Config.Combo.R:MenuElement({name = "Tap Key",  id = "Key", value = true, key = string.byte("G"), toggle = false, leftIcon = Icons["R"]})

        Config.Combo:MenuElement({name = "Combo Key",  id = "Key",key = string.byte(" "), toggle = false, leftIcon = Icons["S"]})

        -----
        Config:MenuElement({type = MENU, name = "Harass",  id = "Harass", leftIcon = Icons["S"]})

        Config.Harass:MenuElement({type = MENU, name = "[Q] Dancing Grenade",  id = "Q", leftIcon = Icons["Q"]})
        Config.Harass.Q:MenuElement({name = "Use [Q]",  id = "Use", value = true, leftIcon = Icons["Q"]})

        Config.Harass:MenuElement({type = MENU, name = "[W] Deadly Flourish",  id = "W", leftIcon = Icons["W"]})
        Config.Harass.W:MenuElement({name = "Use [W]",  id = "Use", value = true, leftIcon = Icons["W"]})
        Config.Harass.W:MenuElement({name = "Use [W] Only When Stunnable",  id = "Stun", value = true, leftIcon = Icons["W"]})

        Config.Harass:MenuElement({type = MENU, name = "[E] Captive Audience",  id = "E", leftIcon = Icons["E"]})
        Config.Harass.E:MenuElement({name = "Use [E]",  id = "Use", value = true, leftIcon = Icons["E"]})
        Config.Harass.E:MenuElement({name = "Use [E] Only When Immobile",  id = "Stun", value = true, leftIcon = Icons["E"]})

        Config.Harass:MenuElement({name = "Mana Manager(%)",  id = "Mana", value = 50, min = 0, max = 100 ,leftIcon = Icons["S"]})
        Config.Harass:MenuElement({name = "Harass Key",  id = "Key",key = string.byte("C"), toggle = false, leftIcon = Icons["S"]})

        -----

        Config:MenuElement({type = MENU, name = "Drawings",  id = "Draw", leftIcon = Icons["S"]})

        Config.Draw:MenuElement({type = MENU, name = "[Q] Dancing Grenade",  id = "Q", leftIcon = Icons["Q"]})
        Config.Draw.Q:MenuElement({name = "[Q] Draw range",  id = "Draw", value = true,leftIcon = Icons["Q"]})
        Config.Draw.Q:MenuElement({name = "[Q] Color",  id = "Color", color = Draw.Color(255, 255, 255, 255), leftIcon = Icons["Q"]})
        Config.Draw.Q:MenuElement({name = "[Q] Width",  id = "Width", value = 1, min = 1, max = 10, leftIcon = Icons["Q"]})

        Config.Draw:MenuElement({type = MENU, name = "[W] Deadly Flourish",  id = "W", leftIcon = Icons["W"]})
        Config.Draw.W:MenuElement({name = "[W] Draw range",  id = "Draw", value = true,leftIcon = Icons["W"]})
        Config.Draw.W:MenuElement({name = "[W] Color",  id = "Color", color = Draw.Color(255, 255, 255, 255), leftIcon = Icons["W"]})
        Config.Draw.W:MenuElement({name = "[W] Width",  id = "Width", value = 1, min = 1, max = 10, leftIcon = Icons["W"]})

        Config.Draw:MenuElement({type = MENU, name = "[E] Captive Audience",  id = "E", leftIcon = Icons["E"]})
        Config.Draw.E:MenuElement({name = "[E] Draw range",  id = "Draw", value = true,leftIcon = Icons["E"]})
        Config.Draw.E:MenuElement({name = "[E] Color",  id = "Color", color = Draw.Color(255, 255, 255, 255), leftIcon = Icons["E"]})
        Config.Draw.E:MenuElement({name = "[E] Width",  id = "Width", value = 1, min = 1, max = 10, leftIcon = Icons["E"]})

        Config.Draw:MenuElement({type = MENU, name = "[R] Curtain Call",  id = "R", leftIcon = Icons["R"]})
        Config.Draw.R:MenuElement({name = "[R] Draw range",  id = "Draw", value = true,leftIcon = Icons["R"]})
        Config.Draw.R:MenuElement({name = "[R] Color",  id = "Color", color = Draw.Color(255, 255, 255, 255), leftIcon = Icons["R"]})
        Config.Draw.R:MenuElement({name = "[R] Width",  id = "Width", value = 1, min = 1, max = 10, leftIcon = Icons["R"]})

        Config.Draw:MenuElement({name = "Disable All Drawings",  id = "Disable", value = false, leftIcon = Icons["S"]})
end

local Spells = function()
        Q = { range = 600, delay = 250, IsReady = function() return Game.CanUseSpell(_Q) == READY end }
        W = { range = 2550, width = 40, speed = 5000, delay = 750, IsReady = function() return Game.CanUseSpell(_W) == READY end }
        E = { range = 750 , width = 300, speed = 1600, delay = 850, IsReady = function() return Game.CanUseSpell(_E) == READY end }
        R = { range = 3500 , width = 80, speed = 4500, delay = 200, IsReady = function() return Game.CanUseSpell(_R) == READY end }
end

local Mode = function()
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
        return ""
end

local GetPercentHP = function(unit)
        return 100 * unit.health / unit.maxHealth
end

local GetPercentMP = function(unit)
        return 100 * unit.mana / unit.maxMana
end

local GetTarget = function(range, damageType, from)
        return _G.SDK.TargetSelector:GetTarget(range, damageType, from)
end

local GetBuffs = function(unit)
        local t = {}
        for i = 0, unit.buffCount do
                local buff = unit:GetBuff(i)
                if buff.count > 0 then
                        table.insert(t, buff)
                end
        end
        return t
end

local HasBuff = function(unit, buffname)
        for K, Buff in pairs(GetBuffs(unit)) do
                if Buff.name:lower() == buffname:lower() then
                        return true
                end
        end
        return false
end

local IsImmune = function(unit)
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

local IsValidTarget = function(unit, range, checkTeam, from)
        local range = range == nil and math.huge or range
        if type(range) ~= "number" then error("{IsValidTarget}: bad argument #2 (number expected, got "..type(range)..")") end
        if type(checkTeam) ~= "nil" and type(checkTeam) ~= "boolean" then error("{IsValidTarget}: bad argument #3 (boolean or nil expected, got "..type(checkTeam)..")") end
        if type(from) ~= "nil" and type(from) ~= "userdata" then error("{IsValidTarget}: bad argument #4 (vector or nil expected, got "..type(from)..")") end
        if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or IsImmune(unit) or (checkTeam and unit.isAlly) then 
                return false 
        end 
        return unit.pos:DistanceTo(from.pos and from.pos or myHero.pos) < range 
end

local IsImmobileTarget = function(unit)
        for i = 0, unit.buffCount do
                local buff = unit:GetBuff(i)
                if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
                        return true
                end
        end
        return false    
end

local CalcAngle = function(v1, v2)
        return math.acos(v1.x*v2.x+v1.y*v2.y+v1.z*v2.z)/(v1:Len()*v2:Len())
end

local GetDistance = function(p1, p2)
        return p1:DistanceTo(p2)
end

local Stunnable = function(unit)
        return HasBuff(unit, "jhinespotteddebuff")
end

local Missile = function()
        return myHero:GetSpellData(_R).name == "JhinRShot"
end

local CastQ = function(target)
        if Q.IsReady() and IsValidTarget(target, Q.range, true, myHero) then
                CastSpell(HK_Q, target.pos, Q.range, Q.delay)
        end
end

local CastW = function(target)
        if W.IsReady() and IsValidTarget(target, W.range, true, myHero) then
                local Prediction = target:GetPrediction(W.speed, W.delay/100)
                CastSpell(HK_W, Prediction, W.range, W.delay)
        end
end

local CastE = function(target)
        if E.IsReady() and IsValidTarget(target, E.range, true, myHero) then
                local Prediction = target:GetPrediction(E.speed, E.delay/100)
                CastSpell(HK_E, Prediction, E.range, E.delay)
        end
end

local CastR1 = function(target)
        if R.IsReady() and IsValidTarget(target, R.range, true, myHero) then
                CastSpell(HK_R, target.pos, R.range)
        end
end

local CastR2 = function(target)
        if R.IsReady() and IsValidTarget(target, R.range, true, myHero) then
                local Prediction = target:GetPrediction(R.speed, R.delay/100)
                CastSpell(HK_R, Prediction, R.range, 500)
        end
end

local Combo = function()
        local target = GetTarget(W.range, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)

        if target == nil then return end

        if Mode() == "Combo" or Config.Combo.Key:Value() then
                if myHero.attackData.state ~= STATE_WINDUP then
                        if Config.Combo.Q.Use:Value() then
                                CastQ(target)
                        end
                        if Config.Combo.W.Use:Value() then
                                if Config.Combo.W.Stun:Value() then
                                        if Stunnable(target) then 
                                                CastW(target)    
                                        end 
                                else
                                        CastW(target)
                                end
                        end
                end 
                if Config.Combo.E.Use:Value() then
                        if Config.Combo.E.Stun:Value() then
                                if IsImmobileTarget(target) then
                                        CastE(target)
                                end
                        else
                                CastE(target)
                        end
                end
        end
end

local Harass = function()
        local target = GetTarget(W.range, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)

        if target == nil then return end

        if Mode() == "Harass" or Config.Harass.Key:Value() and GetPercentMP(myHero) > Config.Harass.Mana:Value() then
                if myHero.attackData.state ~= STATE_WINDUP then
                        if Config.Harass.Q.Use:Value() then
                                CastQ(target)
                        end
                        if Config.Harass.W.Use:Value() then
                                if Config.Harass.W.Stun:Value() then
                                        if Stunnable(target) then 
                                                CastW(target)    
                                        end 
                                else
                                        CastW(target)
                                end
                        end
                end 
                if Config.Harass.E.Use:Value() then
                        if Config.Harass.E.Stun:Value() then
                                if IsImmobileTarget(target) then
                                        CastE(target)
                                end
                        else
                                CastE(target)
                        end
                end
        end
end

local Ultimate = function()
        local target = GetTarget(R.range, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)

        if target == nil then return end

        if Config.Combo.R.Use:Value() and Config.Combo.R.Key:Value() then
                if not Missile() then
                        CastR1(target)
                else
                        CastR2(target)
                end
        end
end

local Tick = function()
        Combo()
        Harass()
        Ultimate()
end

local Draw = function()
        if Config.Draw.Disable:Value() or myHero.dead then return end

        if Config.Draw.Q.Draw:Value() and Q.IsReady() then
                Draw.Circle(myHero.pos, Q.range, Config.Draw.Q.Width:Value(), Config.Draw.Q.Color:Value())
        end
        if Config.Draw.W.Draw:Value() and W.IsReady() then
                Draw.Circle(myHero.pos, W.range, Config.Draw.W.Width:Value(), Config.Draw.W.Color:Value())
        end
        if Config.Draw.E.Draw:Value() and E.IsReady() then
                Draw.Circle(myHero.pos, E.range, Config.Draw.E.Width:Value(), Config.Draw.E.Color:Value())
        end
        if Config.Draw.R.Draw:Value() and R.IsReady() then
                Draw.Circle(myHero.pos, R.range, Config.Draw.R.Width:Value(), Config.Draw.R.Color:Value())
        end
end

function OnLoad()
        require("DamageLib")
        Menu()
        Spells()
        Callback.Add("Tick", function() Tick() end)
        Callback.Add("Draw", function() Draw() end)
end
