-- ================================================================
-- XYLENT - FREEZE BYPASS 2 DETIK (TELEPORT -> FREEZE -> JATUH)
-- ================================================================

local players = game:GetService('Players')
local lplr = players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Locations = {
    {"Dealer NPC", Vector3.new(770.992, 3.71, 433.75)},
    {"NPC Marshmallow", Vector3.new(510.061, 4.476, 600.548)},
    {"Apart 1", Vector3.new(1137.992, 9.932, 449.753)},
    {"Apart 2", Vector3.new(1139.174, 9.932, 420.556)},
    {"Apart 3", Vector3.new(984.856, 9.932, 247.280)},
    {"Apart 4", Vector3.new(988.311, 9.932, 221.664)},
    {"Apart 5", Vector3.new(923.954, 9.932, 42.202)},
    {"Apart 6", Vector3.new(895.721, 9.932, 41.928)},
    {"Casino", Vector3.new(1166.33, 3.36, -29.77)},
    {"GS UJUNG", Vector3.new(-466.525, 3.862, 357.661)},
    {"GS BINARY", Vector3.new(-280.351, 3.742, 248.872)},
    {"GS MID", Vector3.new(218.427, 3.737, -176.975)}
}

-- ========== BYPASS CORE (FREEZE TOTAL) ==========
local heartbeatConn = nil
local propertyConn = nil
local lastCF = nil
local bypassActive = false
local currentRootPart = nil

-- Matiin bypass
local function stopBypass()
    bypassActive = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    if propertyConn then propertyConn:Disconnect() end
    heartbeatConn = nil
    propertyConn = nil
    lastCF = nil
    currentRootPart = nil
    print("[BYPASS] Mati - lo mulai jatuh normal")
end

-- Nyalain bypass (FREEZE TOTAL)
local function startBypass(rootPart)
    if bypassActive then stopBypass() end
    
    bypassActive = true
    currentRootPart = rootPart
    lastCF = rootPart.CFrame
    
    -- Heartbeat buat nyimpen CFrame
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not bypassActive or not currentRootPart or not currentRootPart.Parent then return end
        lastCF = currentRootPart.CFrame
    end)
    
    -- PropertyChanged buat nolak setiap perubahan CFrame dari server
    propertyConn = currentRootPart:GetPropertyChangedSignal("CFrame"):Connect(function()
        if not bypassActive or not currentRootPart or not currentRootPart.Parent then return end
        if currentRootPart.CFrame ~= lastCF then
            currentRootPart.CFrame = lastCF  -- LEMPAR BALIK TERUS
        end
    end)
    
    print("[BYPASS] FREEZE NYALA - lo gabisa gerak")
end

-- Teleport + freeze 2 detik
local function teleportAndFreeze(pos)
    local char = lplr.Character
    if not char then 
        print("[TP] Gak ada karakter")
        return 
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rootPart = hum and hum.RootPart
    if not rootPart then 
        print("[TP] Gak ada root part")
        return 
    end
    
    -- 1. Nyalain FREEZE dulu
    startBypass(rootPart)
    task.wait(0.05)
    
    -- 2. Teleport ke posisi (melayang)
    rootPart.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)  -- +5 biar di udara
    lastCF = rootPart.CFrame
    
    print("[TP] Teleport + freeze di udara:", pos)
    
    -- 3. Biarin freeze 2 detik (server terpaksa save posisi ini)
    task.wait(2)
    
    -- 4. Matiin bypass, lo bakal jatuh ke tanah
    stopBypass()
    
    print("[TP] Bypass mati, sekarang jatuh bebas - GA ADA SETBACK!")
end

-- ========== INIT ==========
lplr.CharacterAdded:Connect(function()
    stopBypass()
end)

lplr.CharacterRemoving:Connect(function()
    stopBypass()
end)

-- ========== GUI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "XylusFreezeTP"
gui.Parent = lplr:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 420)
frame.Position = UDim2.new(0, 10, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
title.BackgroundTransparency = 0.2
title.Text = "XYLUS TP (FREEZE 2 DETIK)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -35, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 100, 100)
close.TextSize = 18
close.Parent = title
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #Locations * 45)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

for _, loc in pairs(Locations) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.Text = loc[1]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = scroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        teleportAndFreeze(loc[2])
    end)
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)

print("[XYLUS] FREEZE BYPASS 2 DETIK LOADED - Tekan Insert")
print("[XYLUS] Teleport -> freeze 2 detik -> mati bypass -> jatuh normal")
print("[XYLUS] GA ADA SETBACK, GA ADA FREEZE BERKEPANJANGAN!")
