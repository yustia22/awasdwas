-- XYLUS | ALL IN ONE (SPLIX UI) + BYPASS - FIXED VERSION

local MemoryStoreService = game:GetService("MemoryStoreService")

-- ====================== BYPASS ANTI-CHEAT (SAFER) =======================
local Bypass = {
    Hooks = {},
    Stealth = {},
    Patterns = {},
    killFakeHandshake = {}
}

-- Kill fake handshake safely
local function killFakeHandshake()
    local fake = MemoryStoreService:FindFirstChild("Hyphon_Check")
    if fake and fake:IsA("RemoteEvent") then
        pcall(function() fake:Destroy() end)
    end
end
killFakeHandshake()

-- SAFER hook - only target specific functions without breaking everything
Bypass.Hooks = {
    Trampoline = function(target, funcName, hook)
        local oldFunc = target[funcName]
        if oldFunc then
            target[funcName] = hook
            return oldFunc
        end
        return nil
    end,
    Environment = function()
        -- Only modify environment for our own scripts, not global
        pcall(function()
            local env = getfenv(2)
            if env then
                setfenv(2, setmetatable({}, {
                    __index = function(t, k)
                        if k == "debug" then return nil end
                        return env[k]
                    end,
                    __newindex = function(t, k, v)
                        if k ~= "LoadLibrary" then env[k] = v end
                    end
                }))
            end
        end)
    end
}

-- SAFER stealth - don't break core game functions
Bypass.Stealth = {
    Memory = function()
        -- Only hook if game doesn't have critical checks
        pcall(function()
            local mt = getmetatable(game)
            if mt and mt.__index and not rawget(mt, "_bypassed") then
                rawset(mt, "_bypassed", true)
                -- Don't override the entire __index
            end
        end)
    end
}

-- Run bypass checks but don't interfere with FastCast
spawn(function()
    while true do
        pcall(Bypass.Hooks.Environment)
        pcall(Bypass.Stealth.Memory)
        wait(math.random(1, 3))
    end
end)

-- ==================== LOAD LIBRARY ====================
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Splix"))()

-- ==================== CUSTOMIZABLE SETTINGS ====================
local uiSettings = {
    textsize = 13,
    font = Enum.Font.RobotoMono,
    name = "XYLUS | All in One",
    color = Color3.fromRGB(0, 255, 136),
    size = UDim2.new(0, 450, 0, 500)
}

-- Buat window dengan setting custom
local window = library:new(uiSettings)

-- ==================== TAB ====================
local combatTab = window:page({name = "Combat"})
local playerTab = window:page({name = "Player"})
local teleportTab = window:page({name = "Teleport"})
local vteleportTab = window:page({name = "VTeleport"})
local visualsTab = window:page({name = "Visuals"})
local settingsTab = window:page({name = "Settings"})

-- ==================== SECTION ====================
local combatSection = combatTab:section({name = "Silent Aim", side = "left", size = 300})
local playerSection = playerTab:section({name = "Player Stats", side = "left", size = 300})
local teleportSection = teleportTab:section({name = "Teleport (Respawn)", side = "left", size = 300})
local vteleportSection = vteleportTab:section({name = "Vehicle Teleport", side = "left", size = 300})
local visualsSection = visualsTab:section({name = "ESP & Visuals", side = "left", size = 300})
local settingsSection = settingsTab:section({name = "UI Settings", side = "left", size = 300})

-- ==================== VARIABEL GLOBAL ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

-- ==================== SILENT AIM (FIXED) ====================
local SilentAim = false
local SilentAimPart = "HumanoidRootPart"
local SilentAimWallbang = false
local MaxWallbangDistance = 500

local FovCircle = Drawing.new("Circle")
FovCircle.Radius = 150
FovCircle.NumSides = 64
FovCircle.Thickness = 1.5
FovCircle.Visible = false
FovCircle.Color = Color3.fromRGB(0, 255, 0)
FovCircle.Transparency = 0.6
FovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    FovCircle.Position = UserInputService:GetMouseLocation()
    FovCircle.Visible = SilentAim
end)

-- SAFER way to find FastCast functions
local FastCastModule = nil
local CastBlacklistFunc = nil
local CastWhitelistFunc = nil

-- Find the FastCast module properly
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "FireWithBlacklist") then
        FastCastModule = v
        break
    end
end

-- Find CastBlacklist and CastWhitelist from the module's upvalues
if FastCastModule then
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info and info.name == "CastBlacklist" then
                CastBlacklistFunc = v
            elseif info and info.name == "CastWhitelist" then
                CastWhitelistFunc = v
            end
        end
    end
end

local function GetFovTarget(Circle, HitPart)
    local Target = nil
    local LowestDistance = math.huge
    
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            local Char = v.Character
            if Char then
                local Part = Char:FindFirstChild(HitPart)
                local Humanoid = Char:FindFirstChild("Humanoid")
                if Part and Humanoid and Humanoid.Health > 0 then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local Distance = (Circle.Position - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                        if Distance < Circle.Radius and Distance < LowestDistance then
                            Target = v
                            LowestDistance = Distance
                        end
                    end
                end
            end
        end
    end
    return Target
end

-- Hook FastCast functions safely
if CastBlacklistFunc and CastWhitelistFunc then
    local OldCastBlacklist = hookfunction(CastBlacklistFunc, function(...)
        local Target = GetFovTarget(FovCircle, SilentAimPart)
        if Target and SilentAim then
            local args = {...}
            local part = Target.Character and Target.Character:FindFirstChild(SilentAimPart)
            if part then
                args[2] = part.Position - args[1]
                if SilentAimWallbang then
                    if args[2].Magnitude <= MaxWallbangDistance then
                        args[3] = {Target.Character}
                        return CastWhitelistFunc(unpack(args))
                    end
                end
                return OldCastBlacklist(unpack(args))
            end
        end
        return OldCastBlacklist(...)
    end)
    print("✅ Silent Aim hooked successfully!")
else
    print("⚠️ FastCast functions not found, Silent Aim may not work")
end

-- UI Silent Aim
combatSection:toggle({name = "Silent Aim", def = false, callback = function(v) SilentAim = v end})
combatSection:dropdown({name = "Target Part", def = "HumanoidRootPart", max = 4, options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, callback = function(v) SilentAimPart = v end})
combatSection:slider({name = "FOV Radius", def = 150, max = 500, min = 10, rounding = true, callback = function(v) FovCircle.Radius = v end})
combatSection:toggle({name = "Wallbang", def = false, callback = function(v) SilentAimWallbang = v end})
combatSection:slider({name = "Wallbang Distance", def = 500, max = 5000, min = 10, rounding = true, callback = function(v) MaxWallbangDistance = v end})

-- ==================== INFINITE STAMINA ====================
local staminaHooked = false
local heartbeatConnection = nil

playerSection:toggle({
    name = "Infinite Stamina",
    def = false,
    callback = function(Value)
        if Value and not staminaHooked then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    for k, _ in pairs(v) do
                        if k == "Stamina" then
                            local mt = getmetatable(v)
                            if mt then
                                setreadonly(mt, false)
                                local oldIndex = mt.__index
                                mt.__index = function(t, k2)
                                    if k2 == "Stamina" then return 100 end
                                    return oldIndex and oldIndex(t, k2)
                                end
                                staminaHooked = true
                            end
                            heartbeatConnection = RunService.Heartbeat:Connect(function()
                                if Value then v.Stamina = 100 end
                            end)
                            break
                        end
                    end
                end
                if staminaHooked then break end
            end
        elseif not Value and heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end
})

-- ==================== WALKSPEED ====================
local walkspeedEnabled = false
local currentWalkspeed = 13

playerSection:toggle({
    name = "Enable Walkspeed",
    def = false,
    callback = function(state)
        walkspeedEnabled = state
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = state and currentWalkspeed or 13 end
    end
})

playerSection:slider({
    name = "Walkspeed Value",
    def = 13, max = 23, min = 0, rounding = true,
    callback = function(value)
        currentWalkspeed = value
        if walkspeedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end
})

-- Auto apply walkspeed saat respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if walkspeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = currentWalkspeed end
    end
end)

-- ==================== TELEPORT (RESPAWN METHOD) ====================
local tpLocs = {
    {"Dealership", 753.20, 4.63, 437.04},
    {"Marshmellow", 510.996, 3.587, 598.393},
    {"Casino", 1154.86, 4.29, -46.85},
    {"GS Ujung", -465.51, 4.79, 360.47},
    {"GS Mid", 218.57, 4.65, -173.54},
    {"Apart 1", 1141.80, 11.04, 450.35},
    {"Apart 2", 1142.49, 11.04, 421.64},
    {"Bank", -43.01, 4.66, -353.96},
}

local tpDestination = nil
local isRespawning = false

local function onCharacterAdded(char)
    if not tpDestination then return end
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:WaitForChild("Humanoid", 10)
        if hrp and hum then
            repeat task.wait(0.1) until hum.Health > 0
            task.wait(0.5)
            pcall(function() hrp.CFrame = CFrame.new(tpDestination.x, tpDestination.y + 3, tpDestination.z) end)
        end
        tpDestination = nil
        isRespawning = false
    end)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

local function tpTo(x, y, z)
    if isRespawning then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    tpDestination = {x = x, y = y, z = z}
    isRespawning = true
    if hum and hum.Health > 0 then hum.Health = 0 end
end

for _, loc in ipairs(tpLocs) do
    teleportSection:button({name = loc[1], callback = function() tpTo(loc[2], loc[3], loc[4]) end})
end

-- ==================== VEHICLE TELEPORT ====================
local cachedSeat = nil

local function updateSeatCache()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    cachedSeat = hum and hum.SeatPart or nil
end

local function hookCharacter(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then hum:GetPropertyChangedSignal("SeatPart"):Connect(updateSeatCache) end
    updateSeatCache()
end

if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

local function tpVehicle(x, y, z)
    if not cachedSeat then return end
    local vehModel = cachedSeat:FindFirstAncestorWhichIsA("Model")
    if vehModel and vehModel.PrimaryPart then
        vehModel:SetPrimaryPartCFrame(CFrame.new(x, y + 2, z))
    elseif cachedSeat then
        cachedSeat.CFrame = CFrame.new(x, y + 2, z)
    end
end

local vtpLocs = {
    {"Dealership", 753.20, 4.63, 437.04},
    {"Marshmellow", 510.996, 3.587, 598.393},
    {"Casino", 1154.86, 4.29, -46.85},
    {"Apart 1", 1108.93, 11.03, 455.77},
    {"Apart 2", 1109.15, 11.04, 427.29},
    {"Bank", -43.01, 4.66, -353.96},
}

for _, loc in ipairs(vtpLocs) do
    vteleportSection:button({name = loc[1], callback = function() tpVehicle(loc[2], loc[3], loc[4]) end})
end

-- ==================== PLAYER ESP ====================
local espEnabled = false
local espMaxDist = 150
local espCache = {}

local function createESP(player)
    if espCache[player] then
        for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
    end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(0, 255, 136)
    box.Filled = false
    local nameL = Drawing.new("Text")
    nameL.Text = player.Name
    nameL.Size = 10
    nameL.Font = 1
    nameL.Color = Color3.fromRGB(255, 255, 255)
    nameL.Outline = true
    nameL.Center = true
    local hpBg = Drawing.new("Square")
    hpBg.Thickness = 1
    hpBg.Color = Color3.fromRGB(30, 30, 30)
    hpBg.Filled = true
    local hpFl = Drawing.new("Square")
    hpFl.Thickness = 1
    hpFl.Color = Color3.fromRGB(0, 255, 80)
    hpFl.Filled = true
    local dL = Drawing.new("Text")
    dL.Size = 10
    dL.Font = 1
    dL.Color = Color3.fromRGB(180, 220, 255)
    dL.Outline = true
    dL.Center = true
    espCache[player] = {box, nameL, hpBg, hpFl, dL}
end

local function removeESP(player)
    if espCache[player] then
        for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
        espCache[player] = nil
    end
end

for _, plr in pairs(Players:GetPlayers()) do if plr ~= LocalPlayer then createESP(plr) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

visualsSection:toggle({name = "Player ESP", def = false, callback = function(v) espEnabled = v end})
visualsSection:slider({name = "ESP Max Distance", def = 150, max = 500, min = 10, rounding = true, callback = function(v) espMaxDist = v end})

RunService.Heartbeat:Connect(function()
    if not espEnabled then
        for _, drawings in pairs(espCache) do for _, o in pairs(drawings) do pcall(function() o.Visible = false end) end end
        return
    end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myHRP and myHRP.Position
    for player, drawings in pairs(espCache) do
        local box, nameL, hpBg, hpFl, dL = unpack(drawings)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if not (char and hum and root and head and hum.Health > 0) then
            for _, o in pairs(drawings) do o.Visible = false end
        else
            local dist = myPos and (root.Position - myPos).Magnitude or 0
            if dist > espMaxDist then
                for _, o in pairs(drawings) do o.Visible = false end
            else
                local rootPos, rootOn = Camera:WorldToViewportPoint(root.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if rootOn and headOn then
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.7 + 8
                    local width = height * 0.55
                    local boxX = rootPos.X - width / 2
                    local boxY = headPos.Y - 4
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(boxX, boxY)
                    box.Visible = true
                    nameL.Position = Vector2.new(rootPos.X, boxY - 14)
                    nameL.Visible = true
                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    hpBg.Size = Vector2.new(4, height - 4)
                    hpBg.Position = Vector2.new(boxX - 8, boxY + 2)
                    hpBg.Visible = true
                    hpFl.Color = Color3.fromRGB(255 * (1 - hpPercent), 255 * hpPercent, 80)
                    hpFl.Size = Vector2.new(2, (height - 6) * hpPercent)
                    hpFl.Position = Vector2.new(boxX - 7, boxY + 3 + (height - 6) * (1 - hpPercent))
                    hpFl.Visible = true
                    dL.Text = math.floor(dist) .. "m"
                    dL.Position = Vector2.new(rootPos.X, boxY + height + 2)
                    dL.Visible = true
                else
                    for _, o in pairs(drawings) do o.Visible = false end
                end
            end
        end
    end
end)

-- ==================== NAME SPOOFER ====================
local spoofEnabled = false
local spoofName = "Xylus"

local function applyNameSpoof()
    local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(LocalPlayer.Name)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local nameTag = head:FindFirstChild("NameTag")
    if nameTag and nameTag:FindFirstChild("MainFrame") and nameTag.MainFrame:FindFirstChild("NameLabel") then
        nameTag.MainFrame.NameLabel.Text = spoofName
    end
    local rankTag = head:FindFirstChild("RankTag")
    if rankTag and rankTag:FindFirstChild("MainFrame") and rankTag.MainFrame:FindFirstChild("NameLabel") then
        rankTag.MainFrame.NameLabel.Text = spoofName
    end
end

visualsSection:toggle({name = "Name Spoofer", def = false, callback = function(v)
    spoofEnabled = v
    if v then applyNameSpoof() end
end})
visualsSection:textbox({name = "Custom Name", def = "Xylus", placeholder = "Nama baru", callback = function(v)
    spoofName = v
    if spoofEnabled then applyNameSpoof() end
end})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if spoofEnabled then applyNameSpoof() end
end)

-- ==================== NOCLIP & DELETE WALL ====================
local noclipEnabled = false
local deleteWallEnabled = false
local hoverPart = nil
local mouse = LocalPlayer:GetMouse()
local deletedHistory = {}
local MAX_HISTORY = 20

-- Noclip function
local roadsSidewalksFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Roads/Sidewalks")
local opp = {}

local function setHiddenProperty(instance, property, value)
    pcall(function() sethiddenproperty(instance, property, value) end)
end

local function exlusionssf(part)
    return (roadsSidewalksFolder and part:IsDescendantOf(roadsSidewalksFolder)) or
        (part.Name == "default") or (part.Name == "Sidewalk") or (part.Name == "Floor") or
        (part.Name == "Collision") or (part.Name == "QuaterCylinder") or
        part:IsDescendantOf(LocalPlayer.Character) or
        (part.Parent and part.Parent:IsA("Model") and Players:GetPlayerFromCharacter(part.Parent) ~= nil) or
        (part:IsA("VehicleSeat") or part:IsA("Vehicle"))
end

local function updmommy()
    local pp = Camera.CFrame.Position
    local radius = 15
    local region = Region3.new(pp - Vector3.new(radius, radius, radius), pp + Vector3.new(radius, radius, radius))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and not exlusionssf(part) then
            if not opp[part] then
                opp[part] = { CanCollide = part.CanCollide }
                setHiddenProperty(part, "CanCollide", false)
            end
        end
    end
end

local function resetNoclip()
    for part, props in pairs(opp) do
        if part:IsA("BasePart") then
            setHiddenProperty(part, "CanCollide", props.CanCollide)
        end
    end
    opp = {}
end

-- UI Noclip
visualsSection:toggle({
    name = "Noclip (Tembus Dinding)",
    def = false,
    callback = function(enabled)
        noclipEnabled = enabled
        if noclipEnabled then
            task.spawn(function()
                while noclipEnabled do
                    updmommy()
                    task.wait(0.1)
                end
            end)
        else
            resetNoclip()
        end
    end
})

-- Delete Wall dengan Undo
local function savePartForUndo(part)
    if #deletedHistory >= MAX_HISTORY then table.remove(deletedHistory, 1) end
    table.insert(deletedHistory, {
        name = part.Name, parent = part.Parent, cframe = part.CFrame,
        size = part.Size, transparency = part.Transparency, color = part.Color,
        material = part.Material, canCollide = part.CanCollide, anchored = part.Anchored
    })
end

local function undoLastDelete()
    if #deletedHistory == 0 then return end
    local data = deletedHistory[#deletedHistory]
    table.remove(deletedHistory)
    local newPart = Instance.new("Part")
    newPart.Name = data.name
    newPart.Size = data.size
    newPart.CFrame = data.cframe
    newPart.Transparency = data.transparency
    newPart.Color = data.color
    newPart.Material = data.material
    newPart.CanCollide = data.canCollide
    newPart.Anchored = data.anchored
    newPart.Parent = data.parent
end

-- Hover detection
RunService.RenderStepped:Connect(function()
    if deleteWallEnabled then
        local target = mouse.Target
        if target and target:IsA("BasePart") then
            local isImportant = target:IsDescendantOf(LocalPlayer.Character) or
                                (target.Parent and Players:GetPlayerFromCharacter(target.Parent) ~= nil) or
                                target:IsA("VehicleSeat")
            hoverPart = isImportant and nil or target
        else
            hoverPart = nil
        end
    end
end)

-- Delete E
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if deleteWallEnabled and input.KeyCode == Enum.KeyCode.E and hoverPart then
        savePartForUndo(hoverPart)
        hoverPart:Destroy()
        hoverPart = nil
    end
    if deleteWallEnabled and input.KeyCode == Enum.KeyCode.U then
        undoLastDelete()
    end
end)

visualsSection:toggle({
    name = "Delete Wall (Tekan E)",
    def = false,
    callback = function(state)
        deleteWallEnabled = state
    end
})
visualsSection:label({name = "🗑️ E = Hapus | U = Undo"})

-- ==================== SETTINGS (CUSTOMIZABLE UI) ====================
settingsSection:label({name = "UI Size (Resolusi)"})

settingsSection:slider({
    name = "Width",
    def = 450, min = 300, max = 800, rounding = true,
    callback = function(v)
        if window.frame then
            window.frame.Size = UDim2.new(0, v, 0, window.frame.Size.Y.Offset)
        end
    end
})

settingsSection:slider({
    name = "Height",
    def = 500, min = 300, max = 800, rounding = true,
    callback = function(v)
        if window.frame then
            window.frame.Size = UDim2.new(0, window.frame.Size.X.Offset, 0, v)
        end
    end
})

settingsSection:label({name = "Warna UI"})
settingsSection:colorpicker({
    name = "Accent Color",
    cpname = "color",
    def = Color3.fromRGB(0, 255, 136),
    callback = function(v)
        -- Optional: implement UI color change
    end
})

settingsSection:label({name = "Keybind"})
settingsSection:keybind({
    name = "Toggle GUI Keybind",
    def = Enum.KeyCode.RightControl,
    callback = function(key)
        window.key = key
    end
})

settingsSection:button({
    name = "Unload Script",
    callback = function()
        if window.frame then window.frame:Destroy() end
        FovCircle:Remove()
        for _, drawings in pairs(espCache) do
            for _, o in pairs(drawings) do
                pcall(function() o:Remove() end)
            end
        end
        if heartbeatConnection then heartbeatConnection:Disconnect() end
        resetNoclip()
    end
})

-- Default keybind
window.key = Enum.KeyCode.RightControl

-- ==================== NOTIFIKASI ====================
print("✅ XYLUS | All in One (Splix UI) + Bypass - Tekan RightControl untuk toggle GUI")
