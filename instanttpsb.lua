-- ================================================================
-- xylent
-- ================================================================

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
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

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local checkCharacter = remoteEvents and remoteEvents:FindFirstChild("CheckCharacter")

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

local function fireCheckCharacter()
    if checkCharacter then
        pcall(function()
            checkCharacter:FireServer(lp.Character)
            print("[SYNC] CheckCharacter fired")
        end)
    end
end

local function fixCamera(charCopy)
    pcall(function()
        local root = charCopy:FindFirstChild("HumanoidRootPart")
        local hum = charCopy:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        -- Set subject
        cam.CameraSubject = hum or root
        cam.CameraType = Enum.CameraType.Custom

        -- Force camera to snap to new character position
        if root then
            cam.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 6), root.Position)
        end

        task.wait(0.05)

        -- Re-set subject after snap so it follows normally
        cam.CameraSubject = hum or root
    end)
end

local function reloadAnims(charCopy)
    pcall(function()
        local hum = charCopy:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Stop semua track yang lagi main dulu
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end

        -- Restart Animate script (ini yang drive idle/walk/run)
        local animScript = charCopy:FindFirstChild("Animate")
        if animScript then
            animScript.Disabled = true
            task.wait(0.05)
            animScript.Disabled = false
            print("[ANIM] Animate script restarted")
        else
            print("[ANIM] Animate script not found, forcing state")
        end

        -- Force humanoid state biar trigger idle
        task.wait(0.1)
        hum:ChangeState(Enum.HumanoidStateType.Landed)
        task.wait(0.05)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
end

local isTeleporting = false

local function copyPasteTeleport(pos)
    if isTeleporting then return end
    isTeleporting = true

    local char = lp.Character
    if not char then
        isTeleporting = false
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        isTeleporting = false
        return
    end

    print("[TP] Cloning character...")

    local charCopy = safeClone(char, charactersFolder)
    charCopy.Name = char.Name

    -- Pindah posisi via root CFrame langsung (no SetPrimaryPartCFrame)
    local rootCopy = charCopy:FindFirstChild("HumanoidRootPart")
    if rootCopy then
        rootCopy.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    end

    -- Setup humanoid clone
    local newHum = charCopy:FindFirstChildOfClass("Humanoid")
    if newHum then
        newHum.Health = newHum.MaxHealth
        newHum.PlatformStand = false
        newHum.Sit = false
    end

    -- Swap karakter
    lp.Character = charCopy
    task.wait(0.1)

    -- Hapus karakter lama
    destroyIfExisting(char)

    -- Fix POV / kamera
    fixCamera(charCopy)

    -- Fire sync ke server
    task.wait(0.05)
    fireCheckCharacter()

    -- Reload animasi
    reloadAnims(charCopy)

    -- Fix kamera lagi setelah anim load biar subject ga lepas
    task.wait(0.15)
    fixCamera(charCopy)

    print("[TP] Selesai ke:", pos.X, pos.Y, pos.Z)
    isTeleporting = false
end

-- ================================================================
-- GUI
-- ================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "xylent.tp"
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
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
title.Text = "xylent.tp"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.BorderSizePixel = 0
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -35, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 100, 100)
close.TextSize = 18
close.Font = Enum.Font.GothamBold
close.Parent = title
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #Locations * 45)
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
scroll.BorderSizePixel = 0
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
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    btn.Parent = scroll

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    end)

    btn.MouseButton1Click:Connect(function()
        copyPasteTeleport(loc[2])
    end)
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)

print("xylent on top")
