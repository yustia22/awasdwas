-- ================================================================
-- XYLUS - COPY-PASTE TP + ANIMASI + HUMANoid SCALING
-- ================================================================

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charactersFolder = workspace:FindFirstChild("Characters") or workspace

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

-- ========== UTILITY FUNCTIONS ==========
local function safeClone(instance, parent)
    local oldArchivable = instance.Archivable
    instance.Archivable = true
    local clone = instance:Clone()
    clone.Parent = parent
    instance.Archivable = oldArchivable
    return clone
end

local function destroyIfExisting(instance)
    if instance and instance.Parent then
        instance:Destroy()
    end
end

-- ========== FORCE HUMANoid SCALING (BIAR POV NORMAL) ==========
local function fixHumanoidScaling(hum)
    if not hum then return end
    
    -- Enable AutoRotate biar ga aneh
    hum.AutoRotate = true
    
    -- Force platform stand false
    hum.PlatformStand = false
    
    -- Reset CameraMinZoomDistance
    lp.CameraMinZoomDistance = 0.5
    lp.CameraMaxZoomDistance = 20
    
    -- Force Humanoid state ke Running biar normal
    hum:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Disable disabled states (biar bisa gerak normal)
    local disabledStates = {"Flying", "Swimming", "Climbing", "FallingDown", "Jumping", "Seated", "PlatformStanding"}
    for _, state in pairs(disabledStates) do
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType[state], true)
        end)
    end
    
    print("[SCALE] Humanoid scaling fixed")
end

-- ========== LOAD ANIMATIONS (DARI SCRIPT LO) ==========
local AnimationIds = {
    idle = "http://www.roblox.com/asset/?id=11784200339",
    walk = "http://www.roblox.com/asset/?id=18644713850",
    run = "http://www.roblox.com/asset/?id=507767714",
    swim = "http://www.roblox.com/asset/?id=507784897",
    swimidle = "http://www.roblox.com/asset/?id=507785072",
    jump = "http://www.roblox.com/asset/?id=507765000",
    fall = "http://www.roblox.com/asset/?id=507767968",
    climb = "http://www.roblox.com/asset/?id=507765644",
    sit = "http://www.roblox.com/asset/?id=507768133",
    toolslash = "http://www.roblox.com/asset/?id=507768375",
    toollunge = "http://www.roblox.com/asset/?id=507768375",
    wave = "http://www.roblox.com/asset/?id=507770239",
    dance = "http://www.roblox.com/asset/?id=507771019",
    dance2 = "http://www.roblox.com/asset/?id=507776043",
    dance3 = "http://www.roblox.com/asset/?id=507777268",
    lean = "http://www.roblox.com/asset/?id=11404949032",
    gunpose = "http://www.roblox.com/asset/?id=14183808901",
    laugh = "http://www.roblox.com/asset/?id=507770818",
    cheer = "http://www.roblox.com/asset/?id=507770677",
    party = "http://www.roblox.com/asset/?id=3333499508",
    oj = "http://www.roblox.com/asset/?id=3138237587"
}

local animations = {}
local currentAnim = nil

local function loadAnimations(hum)
    local animator = hum:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    
    for name, id in pairs(AnimationIds) do
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        anim.Name = name
        animations[name] = animator:LoadAnimation(anim)
    end
    
    print("[ANIM] Loaded", #animations, "animations")
end

local function playAnimation(animName)
    if currentAnim and currentAnim.IsPlaying then
        currentAnim:Stop()
    end
    local anim = animations[animName]
    if anim then
        anim:Play()
        currentAnim = anim
    end
end

-- ========== COPY-PASTE TELEPORT ==========
local function copyPasteTeleport(pos)
    local char = lp.Character
    if not char then 
        print("[TP] Gak ada karakter")
        return 
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then 
        print("[TP] Gak ada humanoid")
        return 
    end
    
    print("[TP] Cloning character...")
    
    -- 1. Clone karakter
    local charCopy = safeClone(char, charactersFolder)
    charCopy.Name = char.Name
    
    -- 2. Teleport clone ke target (tinggi 2 stud biar ga nembus tanah)
    local targetCF = CFrame.new(pos.X, pos.Y + 2, pos.Z)
    charCopy:SetPrimaryPartCFrame(targetCF)
    
    -- 3. Setup Humanoid clone
    local newHum = charCopy:FindFirstChildOfClass("Humanoid")
    if newHum then
        -- Load animasi
        loadAnimations(newHum)
        playAnimation("idle")
        
        -- Fix scaling
        fixHumanoidScaling(newHum)
    end
    
    -- 4. Set sebagai karakter player
    lp.Character = charCopy
    
    -- 5. Hapus karakter asli
    task.wait(0.1)
    destroyIfExisting(char)
    
    -- 6. Fix camera
    local rootPart = charCopy:FindFirstChild("HumanoidRootPart")
    if rootPart then
        workspace.CurrentCamera.CameraSubject = rootPart
    end
    
    print("[TP] Copy-paste teleport ke:", pos.X, pos.Y, pos.Z)
end

-- ========== GUI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "CopyPasteAnimTP"
gui.Parent = lp:WaitForChild("PlayerGui")
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
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
title.Text = "XYLUS | COPY-PASTE TP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 40)
close.Position = UDim2.new(1, -40, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 100, 100)
close.TextSize = 18
close.Parent = title
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #Locations * 45)
scroll.ScrollBarThickness = 3
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
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = scroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        copyPasteTeleport(loc[2])
    end)
end

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)

print("[XYLUS] COPY-PASTE TP + ANIMASI + SCALING LOADED")
print("[XYLUS] Tekan INSERT untuk toggle GUI")
