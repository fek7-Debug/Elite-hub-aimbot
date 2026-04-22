--[[
    MIT LICENSE
    Copyright (c) 2026 fek7-Debug (Elite Hub Team)
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
]]

-- FIX PARA CARGA EN EXECUTORS (DELTA/FLUXUS)
if not game:IsLoaded() then game.Loaded:Wait() end

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end)

if not success or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end

local Window = Rayfield:CreateWindow({
   Name = "Elite Hub V6 | Aim Configs",
   LoadingTitle = "Organizando Pestañas...",
   ConfigurationSaving = {Enabled = false}
})

-- --- VARIABLES DE CONTROL ---
local aimbotEnabled, wallCheck, teamCheck = false, false, false
local includeNPCsCombat, includeNPCsVisuals = false, false
local aimbotFOV, smoothing = 300, 1
local highlightEnabled = false
local spinEnabled = false

-- --- FOV CONFIG (Círculo en pantalla) ---
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Radius = 300

-- 1. PESTAÑA COMBATE
local TabCombat = Window:CreateTab("🔥 Combate")
TabCombat:CreateToggle({Name = "Aimbot Assist", CurrentValue = false, Callback = function(V) aimbotEnabled = V end})
TabCombat:CreateToggle({Name = "Detect NPC (Aimbot)", CurrentValue = false, Callback = function(V) includeNPCsCombat = V end})
TabCombat:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(V) teamCheck = V end})
TabCombat:CreateToggle({Name = "Wall Detect", CurrentValue = false, Callback = function(V) wallCheck = V end})

-- 2. PESTAÑA AIM CONFIGS
local TabAimSet = Window:CreateTab("⚙️ Aim Configs")
TabAimSet:CreateSection("Ajustes de Precisión")
TabAimSet:CreateSlider({Name = "Smoothing (Suavizado)", Range = {1, 30}, Increment = 1, CurrentValue = 1, Callback = function(V) smoothing = V end})
TabAimSet:CreateSlider({Name = "FOV Range", Range = {50, 600}, Increment = 10, CurrentValue = 300, Callback = function(V) aimbotFOV = V; FOVCircle.Radius = V end})
TabAimSet:CreateToggle({Name = "Ver Círculo FOV", CurrentValue = false, Callback = function(V) FOVCircle.Visible = V end})

-- 3. PESTAÑA VISUALES ESP
local TabEsp = Window:CreateTab("👁️ Visuales ESP")
TabEsp:CreateToggle({Name = "Activar Highlight (Rojo)", CurrentValue = false, Callback = function(V) highlightEnabled = V end})
TabEsp:CreateToggle({Name = "Detect NPC (Highlight)", CurrentValue = false, Callback = function(V) includeNPCsVisuals = V end})

-- 4. EXTRAS
local TabMisc = Window:CreateTab("🌀 Extras")
TabMisc:CreateToggle({Name = "360 SpinBot", CurrentValue = false, Callback = function(V) spinEnabled = V end})
TabMisc:CreateSlider({Name = "Velocidad", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(V) 
    pcall(function() game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = V end)
end})

-- Función para el ESP de Brillo
local function applyH(obj)
    local h = obj:FindFirstChild("EliteHighlight") or Instance.new("Highlight")
    h.Name = "EliteHighlight"; h.Parent = obj
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.Enabled = highlightEnabled
end

-- --- LOOP MAESTRO (Renderizado) ---
game:GetService("RunService").RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local lp = game.Players.LocalPlayer
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    FOVCircle.Position = center

    -- Visuales ESP
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local isP = game.Players:GetPlayerFromCharacter(v)
            local shouldH = highlightEnabled and ((isP and isP ~= lp) or (not isP and includeNPCsVisuals))
            if shouldH then
                applyH(v)
                v.EliteHighlight.Enabled = true
            elseif v:FindFirstChild("EliteHighlight") then
                v.EliteHighlight.Enabled = false
            end
        end
    end

    -- Lógica de Aimbot
    if aimbotEnabled and lp.Character then
        local closest, dist = nil, aimbotFOV
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Humanoid.Health > 0 then
                local isP = game.Players:GetPlayerFromCharacter(v)
                local valid = false
                
                if isP and isP ~= lp then
                    if teamCheck then 
                        if isP.Team ~= lp.Team then valid = true end 
                    else 
                        valid = true 
                    end
                elseif not isP and includeNPCsCombat then
                    valid = true
                end

                if valid then
                    local pos, vis = cam:WorldToViewportPoint(v.Head.Position)
                    if vis then
                        local m = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if m < dist then
                            if wallCheck then
                                local obs = cam:GetPartsObscuringTarget({v.Head.Position}, {lp.Character, v})
                                if #obs == 0 then dist = m; closest = v.Head end
                            else 
                                dist = m; closest = v.Head 
                            end
                        end
                    end
                end
            end
        end
        -- Suavizado de mira
        if closest then 
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, closest.Position), 1/smoothing) 
        end
    end
    
    -- SpinBot
    if spinEnabled and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, 0.4, 0)
    end
end)
