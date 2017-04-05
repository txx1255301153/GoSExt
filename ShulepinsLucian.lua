if myHero.charName ~= "Lucian" then return end 

if FileExist(SCRIPT_PATH.."Orbwalker.lua") then	
	loadfile(SCRIPT_PATH.."Orbwalker.lua")()
else
	print("IC's Orbwalker Not Found. You need to install IC's Orbwalker before using this script")
	return
end	

local Menu, Q, Q2, W, E, R

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

local GetTarget = function(range, damageType, from)
        return _G.SDK.TargetSelector:GetTarget(range, damageType, from)
end

local GetMinions = function()
        return _G.SDK.ObjectManager:GetEnemyMinions(1500)
end

local ValidTarget =  function(unit, range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end

local GetPercentHP = function(unit)
        return 100 * unit.health / unit.maxHealth
end

local CircleCircleIntersection = function(c1, c2, r1, r2) 
        local D = c1:DistanceTo(c2)
        if D > r1 + r2 or D <= math.abs(r1 - r2) then return nil end 
        local A = (r1 * r2 - r2 * r1 + D * D) / (2 * D) 
        local H = math.sqrt(r1 * r1 - A * A)
        local Direction = (c2 - c1):Normalized() 
        local PA = c1 + A * Direction 
        local S1 = PA + H * Direction:Perpendicular() 
        local S2 = PA - H * Direction:Perpendicular() 
        return S1, S2 
end

local ClosestToMouse = function(p1, p2) 
        if mousePos:DistanceTo(p1) > mousePos:DistanceTo(p2) then return p2 else return p1 end
end

local DrawLine3D = function(x1, y1, z1, x2, y2, z2, width, color)
	local xyz_1 = Vector(x1, y1, z1):To2D()
	local xyz_2 = Vector(x2, y2, z2):To2D()
	Draw.Line(xyz_2.x, xyz_2.y, xyz_1.x, xyz_1.y, width or 1, color or Draw.Color(255, 255, 255, 255))
end

local DrawTriangle = function(vector3, color, thickness, size, rot, speed, yShift, yLevel) 	
        if not vector3 then vector3 = Vector(myHero.pos) end 	
        if not color then color = Draw.Color(255, 255, 255, 255) end 	
        if not thickness then thickness = 3 end 	
        if not size then size = 75 end 	
        if not speed then speed = 1 else speed = 1-speed end
        vector3.y = vector3.y + yShift + (rot * yLevel) 
        local a2v = function(a, m) m = m or 1 return math.cos(a) * m, math.sin(a) * m end
        local RX1, RZ1 = a2v((rot*speed), size) 	
        local RX2, RZ2 = a2v((rot*speed) + math.pi*0.33333, size) 	
        local RX3, RZ3 = a2v((rot*speed) + math.pi*0.66666, size) 	
        local PX1 = vector3.x + RX1 	
        local PZ1 = vector3.z + RZ1 	
        local PX2 = vector3.x + RX2 	
        local PZ2 = vector3.z + RZ2 	
        local PX3 = vector3.x + RX3 	
        local PZ3 = vector3.z + RZ3 	
        local PXT1 = vector3.x - (PX1 - vector3.x) 	
        local PZT1 = vector3.z - (PZ1 - vector3.z) 	
        local PXT3 = vector3.x - (PX3 - vector3.x) 	
        local PZT3 = vector3.z - (PZ3 - vector3.z)  	
        DrawLine3D(PXT1, vector3.y, PZT1, PXT3, vector3.y, PZT3, thickness, color) 	
        DrawLine3D(PXT3, vector3.y, PZT3, PX2, vector3.y, PZ2, thickness, color) 	
        DrawLine3D(PX2, vector3.y, PZ2, PXT1, vector3.y, PZT1, thickness, color) 
end

local GetItemSlot = function(unit, id)
        for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == id and unit:GetSpellData(i).currentCd == 0 then 
			return i
		end
	end
	return nil
end

local CastQ = function(target) 
        Control.CastSpell(HK_Q, target) 
end 

local CastQ2 = function(target) 
        local pred = target:GetPrediction(Q.speed, Q.delay)
        if pred == nil then return end 
        local targetPos = Vector(myHero.pos):Extended(pred, Q2.range) 
        if Q.IsReady() and ValidTarget(target, Q2.range) and myHero.pos:DistanceTo(pred) <= Q2.range then 
        	for i, minion in pairs(GetMinions()) do 
        		if minion and not minion.dead and ValidTarget(minion, Q.range) then 
        			local minionPos = Vector(myHero.pos):Extended(Vector(minion.pos), Q2.range)
        			if targetPos:DistanceTo(minionPos) <= Q2.width/2 then 
        				Control.CastSpell(HK_Q, minion) 
        			end 
        		end 
        	end 
        end 
end

local CastW = function(target, fast) 
        if not fast then 
        	local pred = target:GetPrediction(W.speed, W.delay)
        	local col = target:GetCollision(W.width, W.speed, W.delay)
        	if col < 1 then
        		Control.CastSpell(HK_W, pred) 
        	end
        else 
        	Control.CastSpell(HK_W, target.pos)
        end 
end

local CastE = function(target, mode, range) 
        if mode == 1 then 
        	local c1, c2, r1, r2 = Vector(myHero.pos), Vector(target.pos), myHero.range, 525 
        	local O1, O2 = CircleCircleIntersection(c1, c2, r1, r2) 
        	if O1 or O2 then 
        		local pos = c1:Extended(Vector(ClosestToMouse(O1, O2)), range)
        		Control.CastSpell(HK_E, pos) 
        	end 
        elseif mode == 2 then 
        	local pos = Vector(myHero.pos):Extended(mousePos, range)
        	Control.CastSpell(HK_E, pos) 
        elseif mode == 3 then 
        	local pos = Vector(myHero.pos):Extended(Vector(target.pos), range)
        	Control.CastSpell(HK_E, pos)
        end 
end 

local KB = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6 }
local BWC = GetItemSlot(myHero, 3144)
local BOTRK = GetItemSlot(myHero, 3153)

local UseItems = function(target)
        BWC   = GetItemSlot(myHero, 3144)
        BOTRK = GetItemSlot(myHero, 3153)
        if Menu.Items.BOTRK.Use:Value() and BOTRK and ValidTarget(target, 550) and GetPercentHP(myHero) <= Menu.Items.BOTRK.MyHP:Value() and GetPercentHP(target) <= Menu.Items.BOTRK.EnemyHP:Value() then
        	Control.CastSpell(KB[BOTRK], target)
        elseif Menu.Items.BWC.Use:Value() and BWC and ValidTarget(target, 550) then
        	Control.CastSpell(KB[BWC], target)
        end
end

local Tick = function()
        local target = GetTarget(1500, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)
        if target == nil then return end
        if Mode() == "Combo" then  
                UseItems(target)    	
        	if Menu.Combo.Q.Use2:Value() then 
        		CastQ2(target) 
        	end 
        end
        if Menu.Harass.UseExtQ:Value() and (100 * myHero.mana / myHero.maxMana) >= Menu.Harass.Mana:Value() then
        	CastQ2(target)
        end
end

local Draw = function()
        if myHero.dead or Menu.Draw.Disable:Value() then return end
	local target = GetTarget(1500, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)
	if target == nil then return end
	if not inc then inc = 0 end 	
        inc = inc + 0.002 	
        if inc > 6.28318 then inc = 0 end 
        DrawTriangle(target.pos, Draw.Color(255, 255, 255, 0), 2, 75, inc, 10, 0, 0)
end

local AfterAttack = function()
        local target = GetTarget(1500, _G.SDK.DAMAGE_TYPE_PHYSICAL, myHero.pos)
        local ComboRotation = Menu.Combo.ComboRotation:Value() - 1

	if Mode() == "Combo" then
		if ComboRotation == 3 then
	        	if Menu.Combo.W.Use:Value() and W.IsReady() and ValidTarget(target, W.range) then
		                CastW(target, Menu.Combo.W.UseFast:Value())
	                elseif Menu.Combo.E.Use:Value() and E.IsReady() and ValidTarget(target, E.range*2) then
		                CastE(target, Menu.Combo.E.Mode:Value(), Menu.Combo.E.Range:Value())
	                elseif Menu.Combo.Q.Use:Value() and Q.IsReady() and ValidTarget(target, Q.range) then
		                CastQ(target)
	                end
	        end
		if Menu.Combo.Q.Use:Value() and (ComboRotation == 0 or Game.CanUseSpell(ComboRotation) ~= READY) and Q.IsReady() and ValidTarget(target, Q.range) then
		        CastQ(target)
	        elseif Menu.Combo.E.Use:Value() and (ComboRotation == 2 or Game.CanUseSpell(ComboRotation) ~= READY) and E.IsReady() and ValidTarget(target, E.range*2) then
		        CastE(target, Menu.Combo.E.Mode:Value(), Menu.Combo.E.Range:Value())
	        elseif Menu.Combo.W.Use:Value() and (ComboRotation == 1 or Game.CanUseSpell(ComboRotation) ~= READY) and W.IsReady() and ValidTarget(target, W.range) then
		        CastW(target, Menu.Combo.W.UseFast:Value())
	        end
        end
end

local Load = function()        
        Menu = MenuElement({type = MENU, name = "Shulepin's Lucian",  id = "Lucian"})
        Menu:MenuElement({type = MENU, name = "Combo",  id = "Combo"})
        Menu.Combo:MenuElement({type = MENU, name = "[Q] Piercing Light",  id = "Q"})
        Menu.Combo.Q:MenuElement({name = "Use Q In Combo", id = "Use", value = true})
        Menu.Combo.Q:MenuElement({name = "Use Extended Q In Combo", id = "Use2", value = true})
        Menu.Combo:MenuElement({type = MENU, name = "[W] Ardent Blaze",  id = "W"})
        Menu.Combo.W:MenuElement({name = "Use W In Combo", id = "Use", value = true})
        Menu.Combo.W:MenuElement({name = "Use Fast W In Combo", id = "UseFast", value = true})
        Menu.Combo:MenuElement({type = MENU, name = "[E] Relentless Pursuit",  id = "E"})
        Menu.Combo.E:MenuElement({name = "Use E In Combo", id = "Use", value = true})
        Menu.Combo.E:MenuElement({name = "E Mode", id = "Mode", value = 1, drop = {"Side", "Mouse", "Target"}})
        Menu.Combo.E:MenuElement({name = "E Dash Range", id = "Range", value = 125, min = 100, max = 425, step = 5})
        Menu.Combo:MenuElement({name = "Combo Rotation Priority",  id = "ComboRotation", value = 3, drop = {"Q", "W", "E", "EW"}})

        Menu:MenuElement({type = MENU, name = "Auto Harass",  id = "Harass"})
        Menu.Harass:MenuElement({name = "Auto Harass With Extended Q", id = "UseExtQ", value = true})
        Menu.Harass:MenuElement({name = "Mana Manager(%)", id = "Mana", value = 50, min = 1, max = 100, step = 1})

        Menu:MenuElement({type = MENU, name = "Items",  id = "Items"})
        Menu.Items:MenuElement({type = MENU, name = "Bilgewater Cutlass",  id = "BWC"})
        Menu.Items.BWC:MenuElement({name = "Use In Combo",  id = "Use", value = true})
        Menu.Items:MenuElement({type = MENU, name = "Blade of the Ruined King",  id = "BOTRK"})
        Menu.Items.BOTRK:MenuElement({name = "Use In Combo",  id = "Use", value = true})
        Menu.Items.BOTRK:MenuElement({name = "My HP(%)",  id = "MyHP", value = 100, min = 1, max = 100, step = 1})
        Menu.Items.BOTRK:MenuElement({name = "Enemy HP(%)",  id = "EnemyHP", value = 50, min = 1, max = 100, step = 1})
  
        Menu:MenuElement({type = MENU, name = "Drawings",  id = "Draw"})
        Menu.Draw:MenuElement({name = "Disable All Drawings", id = "Disable", value = false})

        Q    = { range = 650                                                                                                }         
        Q2   = { range = 900 , delay = 0.35, speed = math.huge, width = 25, collision = false, aoe = false, type = "linear" }         
        W    = { range = 1000, delay = 0.30, speed = 1600     , width = 80, collision = true , aoe = true , type = "linear" }         
        E    = { range = 425                                                                                                }         
        R    = { range = 1200, delay = 0.10, speed = 2500     , width = 110                                                 }       

        Q.IsReady = function() return Game.CanUseSpell(_Q) == READY end         
        W.IsReady = function() return Game.CanUseSpell(_W) == READY end         
        E.IsReady = function() return Game.CanUseSpell(_E) == READY end         
        R.IsReady = function() return Game.CanUseSpell(_R) == READY end          

        Callback.Add("Tick", function() Tick() end)         
        Callback.Add("Draw", function() Draw() end)
        _G.SDK.Orbwalker:OnPostAttack(function() AfterAttack() end)           
end 

function OnLoad() Load() end
