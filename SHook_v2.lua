-- =======================================================
-- [第一部分] 密鑰驗證系統 (Key System)
-- =======================================================
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local CorrectKey = "RAGEWITHSKILL"
local IsAuthenticated = false

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "SecurityKeySystem"
KeyGui.ResetOnSpawn = false
KeyGui.Parent = (gethui and gethui()) or CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = KeyGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "SHook_v2 腳本驗證"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(0.8, 0, 0, 35)
KeyInput.Position = UDim2.new(0.1, 0, 0.35, 0)
KeyInput.PlaceholderText = "請輸入密鑰..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 14
KeyInput.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = KeyInput

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.5, 0, 0, 35)
SubmitBtn.Position = UDim2.new(0.25, 0, 0.65, 0)
SubmitBtn.Text = "驗證"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 16
SubmitBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = SubmitBtn

SubmitBtn.MouseButton1Click:Connect(function()
    if KeyInput.Text == CorrectKey then
        SubmitBtn.Text = "驗證成功！"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        task.wait(1)
        IsAuthenticated = true
        KeyGui:Destroy()
    else
        SubmitBtn.Text = "密鑰錯誤！"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        SubmitBtn.Text = "驗證"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        KeyInput.Text = ""
    end
end)

repeat task.wait(0.1) until IsAuthenticated

-- =======================================================
-- [第二部分] Ragebot 玩家偵測系統 (每五秒掃描)
-- =======================================================
getgenv().RageTargetList = {"All"} 
getgenv().SpecificRageTarget = "All" 

task.spawn(function()
    while task.wait(5) do
        local currentPlayers = {"All"}
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                table.insert(currentPlayers, p.Name)
            end
        end
        getgenv().RageTargetList = currentPlayers
    end
end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 安全 GUI 父級容器
local TargetParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- [S3] 初始化與預設值記錄
-- ==========================================
local FacingColorRemote = ReplicatedStorage:FindFirstChild("TestGUI_SetFacingColor")
if not FacingColorRemote then
    pcall(function() FacingColorRemote = ReplicatedStorage:WaitForChild("TestGUI_SetFacingColor", 5) end)
end

local DefaultAmbient = Lighting.Ambient
local DefaultOutdoorAmbient = Lighting.OutdoorAmbient
local DefaultFogColor = Lighting.FogColor
local DefaultFogStart = Lighting.FogStart
local DefaultFogEnd = Lighting.FogEnd

local MapAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local DefaultAtmosphereDensity = MapAtmosphere and MapAtmosphere.Density or nil
local DefaultAtmosphereColor = MapAtmosphere and MapAtmosphere.Color or nil
local DefaultAtmosphereHaze = MapAtmosphere and MapAtmosphere.Haze or nil

local WorldColorFilter = Lighting:FindFirstChild("TestGUI_WorldFilter") or Instance.new("ColorCorrectionEffect")
WorldColorFilter.Name = "TestGUI_WorldFilter"
WorldColorFilter.Enabled = false
WorldColorFilter.Parent = Lighting

local ColorFilter = Lighting:FindFirstChild("SLC_WorldFilter") or Instance.new("ColorCorrectionEffect")
ColorFilter.Name = "SLC_WorldFilter"
ColorFilter.Enabled = false
ColorFilter.Parent = Lighting

local ExcludedPartNames = { HumanoidRootPart = true }
local NeonGlowLights = {}
local FOG_MAX_END = 1000
local FOG_MIN_END = 20

-- ==========================================
-- 1. 核心配置 (整合修訂版)
-- ==========================================
local ESPSettings = { 
    Box = false, 
    Skeleton = false, 
    Health = false, 
    HeadESP = false,    
    HeadESPColorIndex = 1, 
    HeadESPGradient = false,                        
    HeadESPColor1 = Color3.fromRGB(91, 168, 252),    
    HeadESPColor2 = Color3.fromRGB(255, 130, 240),   
    NameShow = false,         
    
    -- 👁️ Visual 新增：面向視野視線條
    LookLine = false,
    LookLineLength = 500,                        -- 預設長度 (可拉到 1500)
    LookLineNoTargetColor = Color3.fromRGB(0, 255, 0), -- 沒人時綠色
    LookLineHasTargetColor = Color3.fromRGB(255, 0, 0),-- 直視發現敵人變紅色

    Aimbot = false,     
    AimbotWallCheck = true, 
    AimbotLockNearest = false, 
    AimbotFOV = 150,        
    AimbotMode = "Rage Lock", 
    CustomHeadChance = 50,    
    CustomBodyChance = 50,    
    AimbotSmoothness = 100,   

    SilentAim = false,
    SilentAimFOV = 150,
    SilentAimWallCheck = true,
    
    Ragebot = false,           
    RageAttackSpeed = 0.2,     
    RageHideVoid = 0.4,        
    RagebotHitPartIndex = 1, 
    
    Flight = false,
    Speed = false,
    SpeedValue = 50, 
    Spin = false,
    SpinSpeed = 20,
    Noclip = false,
    AutoJump = false,

    -- Misc 精簡保留與新增項目
    PlayerFOV = 60,
    SpoofSelf = false,
    SpoofSelfName = "fate",
    SpoofOthers = false,
    SpoofOthersName = " ",
    ThirdPerson = false,
    WallTransparencySwitch = false,
    WallTransparency = 0.5,
    
    -- 準星配置
    CrosshairEnabled = false,
    CrosshairColor = Color3.fromRGB(255, 0, 0),
    CrosshairSize = 10,
    CrosshairThickness = 2,
    CrosshairGap = 6,
    CrosshairDotEnabled = true,
    CrosshairLinesEnabled = true,
    CrosshairRotationEnabled = false,
    CrosshairRotationSpeed = 90,

    -- Color Test 配置
    SceneEffect = false,
    SceneColor = Color3.fromRGB(255, 255, 255),
    SceneIntensity = 50,
    FogV9Enabled = false,
    FogV9Color = Color3.fromRGB(255, 255, 255),
    FogV9Intensity = 50,
    CharApplyColor = false,
    CharColor = Color3.fromRGB(255, 255, 255),
    CharMaterialIntensity = 50,
    CharMaterial = Enum.Material.Plastic,
    SnowV9Enabled = false,
    SnowV9Color = Color3.fromRGB(255, 255, 255),
    SnowV9Intensity = 60
}

local HitParts = {"Head", "HumanoidRootPart", "LeftFoot"}
local HitPartNames = {"頭部 (Head)", "身體 (Body)", "腳部 (Foot)"}
local ESPTable = {} 
local Connections = {} 
local isRightMouseDown = false 
local ragebotActiveThread = false 
local rageBtnGlobal = nil 

-- 面向視野線條物件 (超細線條設定)
if getgenv().LookLineDrawing then pcall(function() getgenv().LookLineDrawing:Remove() end) end
local LookLineDrawing = Drawing.new("Line")
LookLineDrawing.Thickness = 1.2
LookLineDrawing.Transparency = 1
LookLineDrawing.Visible = false
getgenv().LookLineDrawing = LookLineDrawing

-- FOV 圈圈
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(91, 168, 252)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Filled = false
FOVCircle.Transparency = 0.6

local SilentFOVCircle = Drawing.new("Circle")
SilentFOVCircle.Color = Color3.fromRGB(255, 130, 240)
SilentFOVCircle.Thickness = 1.5
SilentFOVCircle.NumSides = 60
SilentFOVCircle.Filled = false
SilentFOVCircle.Transparency = 0.6

-- ==========================================
-- ❄️ 多發射器大雪系統 (Color Test)
-- ==========================================
local SnowEmittersV9 = {}
local SnowEmitterCount = 5

for i = 1, SnowEmitterCount do
    local part = Instance.new("Part")
    part.Name = "TestGUI_SnowEmitter_" .. i
    part.Size = Vector3.new(200, 1, 200)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CastShadow = false
    part.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "TestGUI_SnowParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(2, 3) 
    emitter.Speed = NumberRange.new(3, 7)
    emitter.SpreadAngle = Vector2.new(40, 40)
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.5)})
    emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    emitter.Acceleration = Vector3.new(0, -10, 0)
    emitter.RotSpeed = NumberRange.new(-40, 40)
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Color = ColorSequence.new(ESPSettings.SnowV9Color)
    emitter.Parent = part

    table.insert(SnowEmittersV9, {part = part, emitter = emitter, offsetIndex = i})
end

-- ==========================================
-- 🎯 準星系統 (Crosshair)
-- ==========================================
local CrosshairGui = Instance.new("ScreenGui")
CrosshairGui.Name = "TestGUI_Crosshair"
CrosshairGui.ResetOnSpawn = false
CrosshairGui.DisplayOrder = 100
CrosshairGui.IgnoreGuiInset = true
CrosshairGui.Parent = TargetParent

local CrosshairContainer = Instance.new("Frame")
CrosshairContainer.Name = "Container"
CrosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairContainer.Size = UDim2.new(0, 1, 0, 1)
CrosshairContainer.BackgroundTransparency = 1
CrosshairContainer.Visible = false
CrosshairContainer.Parent = CrosshairGui

local function MakeCrosshairBar(name)
    local bar = Instance.new("Frame")
    bar.Name = name
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.BorderSizePixel = 0
    bar.Parent = CrosshairContainer
    return bar
end
local CrosshairTop = MakeCrosshairBar("Top")
local CrosshairBottom = MakeCrosshairBar("Bottom")
local CrosshairLeft = MakeCrosshairBar("Left")
local CrosshairRight = MakeCrosshairBar("Right")

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "Dot"
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Parent = CrosshairContainer
local CrosshairDotCorner = Instance.new("UICorner")
CrosshairDotCorner.CornerRadius = UDim.new(1, 0)
CrosshairDotCorner.Parent = CrosshairDot

local function ApplyThemeGradient(instance)
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(91, 168, 252)),  
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 240))  
    })
    Gradient.Rotation = 45
    Gradient.Parent = instance
    return Gradient
end

-- ==========================================
-- 2. GUI 主面板建立 (含動態漸層標題)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SHOOK_v1_Gui"
ScreenGui.Parent = TargetParent
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 540, 0, 420) 
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 1
MainFrame.Visible = true 
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(45, 48, 60)
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

-- 🌟 SHOOK_v1 動態色彩流動標題
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
Title.BorderSizePixel = 0
Title.Text = "   SHOOK_v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.ZIndex = 2
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- EC91FF 往 000A91 移動漸層特效
local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 145, 255)), -- #EC91FF
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 10, 145)),  -- #000A91
    ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 145, 255))
})
TitleGradient.Rotation = 0
TitleGradient.Parent = Title

task.spawn(function()
    local offset = -1
    while Title.Parent do
        offset = offset + 0.008
        if offset > 1 then offset = -1 end
        TitleGradient.Offset = Vector2.new(offset, 0)
        task.wait()
    end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -42)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SidebarScroll.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -40)
ContentContainer.Position = UDim2.new(0, 140, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 2
ContentContainer.Parent = MainFrame

local Pages = {}
local PageButtons = {}

local function CreatePage(pageName)
    local PageFrame = Instance.new("ScrollingFrame") 
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.BackgroundTransparency = 1
    PageFrame.Visible = false
    PageFrame.ZIndex = 3
    PageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageFrame.ScrollBarThickness = 2
    PageFrame.Parent = ContentContainer
    Pages[pageName] = PageFrame
    return PageFrame
end

local VisualPage = CreatePage("Visual")
local AimPage = CreatePage("Lock Aim")
local SilentPage = CreatePage("Silent Aim")
local RagePage = CreatePage("Ragebot")
local MovementPage = CreatePage("Movement")
local MiscPage = CreatePage("Misc")
local CrosshairPage = CreatePage("Crosshair")
local ColorTestPage = CreatePage("Color Test")

-- 🚫 已移除 World 分頁
local tabIcons = {
    ["Visual"] = "👁️", ["Lock Aim"] = "🎯", ["Silent Aim"] = "🔇", ["Ragebot"] = "🔥", 
    ["Movement"] = "🏃", ["Misc"] = "🧩", ["Crosshair"] = "➕", ["Color Test"] = "🎨"
}
local tabNames = {"Visual", "Lock Aim", "Silent Aim", "Ragebot", "Movement", "Misc", "Crosshair", "Color Test"}

for i, name in ipairs(tabNames) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -12, 0, 32)
    Btn.Position = UDim2.new(0, 6, 0, 10 + (i - 1) * 36)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
    Btn.BorderSizePixel = 0
    Btn.Text = "  " .. (tabIcons[name] or "•") .. "  " .. name
    Btn.TextColor3 = Color3.fromRGB(140, 145, 160)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextSize = 13
    Btn.ZIndex = 4
    Btn.Parent = SidebarScroll
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Color = Color3.fromRGB(45, 48, 62)
    BtnStroke.Parent = Btn
    
    PageButtons[name] = Btn
    
    Btn.MouseButton1Click:Connect(function()
        for pName, frame in pairs(Pages) do frame.Visible = (pName == name) end
        for pName, button in pairs(PageButtons) do
            local isCurrent = (pName == name)
            button.BackgroundColor3 = isCurrent and Color3.fromRGB(35, 38, 55) or Color3.fromRGB(24, 26, 35)
            button.TextColor3 = isCurrent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 160)
            button:FindFirstChildOfClass("UIStroke").Color = isCurrent and Color3.fromRGB(91, 168, 252) or Color3.fromRGB(45, 48, 62)
        end
    end)
end

local ExitBtn = Instance.new("TextButton")
ExitBtn.Size = UDim2.new(1, -12, 0, 32)
ExitBtn.Position = UDim2.new(0, 6, 1, -42)
ExitBtn.BackgroundColor3 = Color3.fromRGB(35, 22, 26)
ExitBtn.BorderSizePixel = 0
ExitBtn.Text = "❌ UNLOAD"
ExitBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
ExitBtn.Font = Enum.Font.SourceSansBold
ExitBtn.TextSize = 13
ExitBtn.ZIndex = 4
ExitBtn.Parent = Sidebar

local ExitCorner = Instance.new("UICorner")
ExitCorner.CornerRadius = UDim.new(0, 6)
ExitCorner.Parent = ExitBtn

-- ==========================================
-- 3. UI 元素產生器 (通用模組)
-- ==========================================
local function AddButton(displayName, settingKey, parentPage, yIndex, isSub)
    local Btn = Instance.new("TextButton")
    Btn.Size = isSub and UDim2.new(1, -30, 0, 32) or UDim2.new(1, -16, 0, 34)
    Btn.Position = isSub and UDim2.new(0, 20, 0, 12 + (yIndex - 1) * 38) or UDim2.new(0, 8, 0, 12 + (yIndex - 1) * 38)
    Btn.BorderSizePixel = 0
    Btn.Font = Enum.Font.SourceSansSemibold
    Btn.TextSize = 14
    Btn.Text = displayName
    Btn.ZIndex = 5
    Btn.Parent = parentPage

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Parent = Btn
    local UIUiGradient = nil

    if settingKey == "Ragebot" then rageBtnGlobal = Btn end

    local function updateUI()
        local enabled = ESPSettings[settingKey]
        if settingKey == "Ragebot" then Btn.Text = enabled and "🔥 Ragebot [P]: ON" or "🔥 Ragebot [P]: OFF"
        else Btn.Text = displayName end

        if enabled then
            Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Btn.TextColor3 = Color3.fromRGB(15, 15, 20)
            BtnStroke.Color = Color3.fromRGB(255, 255, 255)
            BtnStroke.Transparency = 0.8
            if not UIUiGradient then UIUiGradient = ApplyThemeGradient(Btn) end
        else
            Btn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
            Btn.TextColor3 = Color3.fromRGB(170, 175, 190)
            BtnStroke.Color = Color3.fromRGB(45, 48, 62)
            BtnStroke.Transparency = 0
            if UIUiGradient then UIUiGradient:Destroy() UIUiGradient = nil end
        end
    end

    Btn.MouseButton1Click:Connect(function()
        ESPSettings[settingKey] = not ESPSettings[settingKey]
        updateUI()
    end)
    updateUI()
    return Btn
end

local function AddToggle(displayName, settingKey, parentPage, yIndex, isSub, onChange)
    local Card = Instance.new("Frame")
    Card.Size = isSub and UDim2.new(1, -30, 0, 34) or UDim2.new(1, -16, 0, 36)
    Card.Position = isSub and UDim2.new(0, 20, 0, 12 + (yIndex - 1) * 38) or UDim2.new(0, 8, 0, 12 + (yIndex - 1) * 38)
    Card.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    Card.BorderSizePixel = 0
    Card.ZIndex = 5
    Card.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Card
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(45, 48, 62)
    Stroke.Parent = Card

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -64, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = displayName
    Label.TextColor3 = Color3.fromRGB(220, 222, 230)
    Label.Font = Enum.Font.SourceSansSemibold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 6
    Label.Parent = Card

    local SwitchTrack = Instance.new("Frame")
    SwitchTrack.Size = UDim2.new(0, 42, 0, 22)
    SwitchTrack.AnchorPoint = Vector2.new(1, 0.5)
    SwitchTrack.Position = UDim2.new(1, -12, 0.5, 0)
    SwitchTrack.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
    SwitchTrack.BorderSizePixel = 0
    SwitchTrack.ZIndex = 6
    SwitchTrack.Parent = Card
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = SwitchTrack

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(170, 175, 190)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 7
    Knob.Parent = SwitchTrack
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local Click = Instance.new("TextButton")
    Click.Size = UDim2.new(1, 0, 1, 0)
    Click.BackgroundTransparency = 1
    Click.Text = ""
    Click.ZIndex = 8
    Click.Parent = Card

    local function updateUI()
        local enabled = ESPSettings[settingKey]
        TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 175, 190)
        }):Play()
        TweenService:Create(SwitchTrack, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and Color3.fromRGB(91, 168, 252) or Color3.fromRGB(45, 48, 62)
        }):Play()
        if enabled and not SwitchTrack:FindFirstChildOfClass("UIGradient") then ApplyThemeGradient(SwitchTrack) end
        if not enabled then
            local g = SwitchTrack:FindFirstChildOfClass("UIGradient")
            if g then g:Destroy() end
        end
    end

    Click.MouseButton1Click:Connect(function()
        ESPSettings[settingKey] = not ESPSettings[settingKey]
        updateUI()
        if onChange then onChange() end
    end)
    updateUI()
    return Card
end

local function AddModernSlider(name, valueKey, min, max, parentPage, yIndex, isSub, onChange)
    local Card = Instance.new("Frame")
    Card.Size = isSub and UDim2.new(1, -30, 0, 36) or UDim2.new(1, -16, 0, 38)
    Card.Position = isSub and UDim2.new(0, 20, 0, 12 + (yIndex - 1) * 38) or UDim2.new(0, 8, 0, 12 + (yIndex - 1) * 38)
    Card.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    Card.BorderSizePixel = 0
    Card.ZIndex = 5
    Card.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Card
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(45, 48, 62)
    Stroke.Parent = Card

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 0, 14)
    Label.Position = UDim2.new(0, 10, 0, 3)
    Label.BackgroundTransparency = 1
    Label.Text = string.format("%s: %.1f", name, ESPSettings[valueKey])
    Label.TextColor3 = Color3.fromRGB(220, 222, 230)
    Label.Font = Enum.Font.SourceSansSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 6
    Label.Parent = Card

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 4)
    Track.Position = UDim2.new(0, 12, 0, 25)
    Track.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
    Track.BorderSizePixel = 0
    Track.ZIndex = 6
    Track.Parent = Card
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local startRatio = (ESPSettings[valueKey] - min) / (max - min)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(startRatio, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 6
    Fill.Parent = Track
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill
    ApplyThemeGradient(Fill)

    local Thumb = Instance.new("Frame")
    Thumb.Size = UDim2.new(0, 12, 0, 12)
    Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    Thumb.Position = UDim2.new(startRatio, 0, 0.5, 0)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel = 0
    Thumb.ZIndex = 7
    Thumb.Parent = Track
    local ThumbCorner = Instance.new("UICorner")
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    ThumbCorner.Parent = Thumb
    local ThumbStroke = Instance.new("UIStroke")
    ThumbStroke.Thickness = 2
    ThumbStroke.Color = Color3.fromRGB(91, 168, 252)
    ThumbStroke.Parent = Thumb

    local Trigger = Instance.new("TextButton")
    Trigger.Size = UDim2.new(1, 0, 0, 18)
    Trigger.Position = UDim2.new(0, 0, 0.5, -9)
    Trigger.BackgroundTransparency = 1
    Trigger.Text = ""
    Trigger.ZIndex = 8
    Trigger.Parent = Track

    local function UpdateSlider(input)
        local percentage = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(percentage, 0, 1, 0)
        Thumb.Position = UDim2.new(percentage, 0, 0.5, 0)
        local rawVal = min + (percentage * (max - min))
        if max > 10 then ESPSettings[valueKey] = math.round(rawVal) Label.Text = name .. ": " .. ESPSettings[valueKey]
        else ESPSettings[valueKey] = math.round(rawVal * 10) / 10 Label.Text = string.format("%s: %.1fs", name, ESPSettings[valueKey]) end
        if onChange then onChange() end
    end

    local dragging = false
    Trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true UpdateSlider(input) end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(input) end
    end))
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    return Card
end

local function CreateHexColorInput(labelText, yIndex, settingKey, parentPage, onChange)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -30, 0, 36)
    Frame.Position = UDim2.new(0, 20, 0, 12 + (yIndex - 1) * 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 5
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(45, 48, 62)
    Stroke.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 120, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(170, 175, 190)
    Label.Font = Enum.Font.SourceSansSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 6
    Label.Parent = Frame

    local Preview = Instance.new("Frame")
    Preview.Size = UDim2.new(0, 24, 0, 24)
    Preview.Position = UDim2.new(0, 132, 0.5, -12)
    Preview.BackgroundColor3 = ESPSettings[settingKey]
    Preview.BorderSizePixel = 0
    Preview.ZIndex = 6
    Preview.Parent = Frame
    local PreviewCorner = Instance.new("UICorner")
    PreviewCorner.CornerRadius = UDim.new(0, 4)
    PreviewCorner.Parent = Preview
    local PreviewStroke = Instance.new("UIStroke")
    PreviewStroke.Thickness = 1
    PreviewStroke.Color = Color3.fromRGB(60, 63, 78)
    PreviewStroke.Parent = Preview

    local HexBox = Instance.new("TextBox")
    HexBox.Size = UDim2.new(1, -172, 1, -10)
    HexBox.Position = UDim2.new(0, 164, 0, 5)
    HexBox.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
    local c = ESPSettings[settingKey]
    HexBox.Text = string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    HexBox.TextColor3 = Color3.fromRGB(255, 230, 100)
    HexBox.PlaceholderText = "HEX..."
    HexBox.PlaceholderColor3 = Color3.fromRGB(80, 85, 100)
    HexBox.Font = Enum.Font.SourceSansBold
    HexBox.TextSize = 13
    HexBox.BorderSizePixel = 0
    HexBox.ClearTextOnFocus = false
    HexBox.ZIndex = 6
    HexBox.Parent = Frame
    local HBCorner = Instance.new("UICorner")
    HBCorner.CornerRadius = UDim.new(0, 4)
    HBCorner.Parent = HexBox
    local HBStroke = Instance.new("UIStroke")
    HBStroke.Thickness = 1
    HBStroke.Color = Color3.fromRGB(35, 38, 50)
    HBStroke.Parent = HexBox

    HexBox.FocusLost:Connect(function()
        local hex = HexBox.Text:gsub("^#", ""):gsub("%s", "")
        if #hex == 6 and hex:match("^%x+$") then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            ESPSettings[settingKey] = Color3.fromRGB(r, g, b)
            Preview.BackgroundColor3 = ESPSettings[settingKey]
            HexBox.Text = hex:upper()
            if onChange then onChange() end
        else
            local cur = ESPSettings[settingKey]
            HexBox.Text = string.format("%02X%02X%02X", math.floor(cur.R * 255 + 0.5), math.floor(cur.G * 255 + 0.5), math.floor(cur.B * 255 + 0.5))
        end
    end)
    return Frame
end

-- ==========================================
-- 4. 裝載 UI 元件 (精準調整版)
-- ==========================================

-- Visual Page (加入超細面向視野視線條)
AddToggle("視覺外框 (Box ESP)", "Box", VisualPage, 1, false)
AddToggle("血條狀態 (Health Status)", "Health", VisualPage, 2, false)
AddToggle("發光骨架 (Highlight)", "Skeleton", VisualPage, 3, false)
AddToggle("天際射線 (Head Sky Line)", "HeadESP", VisualPage, 4, false)
AddToggle("顯示玩家名稱 (Name Show)", "NameShow", VisualPage, 5, false) 
AddToggle("└─ 雙色漸層 (關閉則為單色)", "HeadESPGradient", VisualPage, 6, true)
CreateHexColorInput("└─ 射線顏色 1:", 7, "HeadESPColor1", VisualPage, nil)
local HeadESPColor2Row = CreateHexColorInput("└─ 射線顏色 2 (漸層用):", 8, "HeadESPColor2", VisualPage, nil)

AddToggle("👁️ 面向視野視線條 (Look Line)", "LookLine", VisualPage, 9, false)
AddModernSlider("└─ 視線條長度 (最大1500碼)", "LookLineLength", 50, 1500, VisualPage, 10, true)
CreateHexColorInput("└─ 常態顏色 (無人):", 11, "LookLineNoTargetColor", VisualPage, nil)
CreateHexColorInput("└─ 發現敵人變色:", 12, "LookLineHasTargetColor", VisualPage, nil)

-- Lock Aim Page
AddButton("Aimbot (滑鼠右鍵鎖定)", "Aimbot", AimPage, 1, false)
AddButton("├─ 障礙物檢查 (Wall Check)", "AimbotWallCheck", AimPage, 2, true)
AddButton("├─ 優先鎖定近敵 (Lock Nearest)", "AimbotLockNearest", AimPage, 3, true)
AddModernSlider("├─ 自瞄範圍大小 (Aimbot FOV)", "AimbotFOV", 1, 1000, AimPage, 4, true)

local ModeSwitchBtn = Instance.new("TextButton")
ModeSwitchBtn.Size = UDim2.new(1, -30, 0, 32)
ModeSwitchBtn.Position = UDim2.new(0, 20, 0, 12 + (5 - 1) * 38)
ModeSwitchBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
ModeSwitchBtn.BorderSizePixel = 0
ModeSwitchBtn.Font = Enum.Font.SourceSansBold
ModeSwitchBtn.TextSize = 14
ModeSwitchBtn.Text = "⚡ 自瞄分支狀態: " .. ESPSettings.AimbotMode
ModeSwitchBtn.TextColor3 = Color3.fromRGB(255, 215, 100)
ModeSwitchBtn.ZIndex = 5
ModeSwitchBtn.Parent = AimPage
local MSCorner = Instance.new("UICorner") MSCorner.CornerRadius = UDim.new(0, 6) MSCorner.Parent = ModeSwitchBtn
local MSStroke = Instance.new("UIStroke") MSStroke.Thickness = 1 MSStroke.Color = Color3.fromRGB(91, 168, 252) MSStroke.Parent = ModeSwitchBtn

local SlidersContainer = Instance.new("Frame")
SlidersContainer.Size = UDim2.new(1, 0, 0, 120)
SlidersContainer.Position = UDim2.new(0, 0, 0, 12 + (6 - 1) * 38)
SlidersContainer.BackgroundTransparency = 1
SlidersContainer.Parent = AimPage

AddModernSlider("└─ 命中頭部機率 (Head %)", "CustomHeadChance", 0, 100, SlidersContainer, 1, true)
AddModernSlider("└─ 命中身體機率 (Body %)", "CustomBodyChance", 0, 100, SlidersContainer, 2, true)
AddModernSlider("└─ 自瞄平滑度 (Smoothness)", "AimbotSmoothness", 0, 100, SlidersContainer, 3, true)

local function UpdateAimbotBranchUI()
    if ESPSettings.AimbotMode == "Rage Lock" then
        ModeSwitchBtn.Text = "⚡ 自瞄分支狀態: Rage Lock (1ms鎖頭)"
        ModeSwitchBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        MSStroke.Color = Color3.fromRGB(255, 50, 50)
        SlidersContainer.Visible = false
    else
        ModeSwitchBtn.Text = "⚙️ 自瞄分支狀態: Custom (自訂數據)"
        ModeSwitchBtn.TextColor3 = Color3.fromRGB(100, 255, 200)
        MSStroke.Color = Color3.fromRGB(50, 255, 150)
        SlidersContainer.Visible = true
    end
end
ModeSwitchBtn.MouseButton1Click:Connect(function()
    ESPSettings.AimbotMode = ESPSettings.AimbotMode == "Rage Lock" and "Custom" or "Rage Lock"
    UpdateAimbotBranchUI()
end)
UpdateAimbotBranchUI()

-- Silent Aim Page
AddButton("Silent Aim (動態光速對齊)", "SilentAim", SilentPage, 1, false)
AddButton("├─ 靜默障礙檢查 (Wall Check)", "SilentAimWallCheck", SilentPage, 2, true)
AddModernSlider("└─ 靜默自瞄範圍 (Silent FOV)", "SilentAimFOV", 1, 1000, SilentPage, 3, true)

-- Ragebot Page
AddButton("🔥 Ragebot [P]: OFF", "Ragebot", RagePage, 1, false)
local PartCycleBtn = Instance.new("TextButton")
PartCycleBtn.Size = UDim2.new(1, -30, 0, 32)
PartCycleBtn.Position = UDim2.new(0, 20, 0, 12 + (2 - 1) * 38)
PartCycleBtn.BackgroundColor3 = Color3.fromRGB(24, 22, 26)
PartCycleBtn.BorderSizePixel = 0
PartCycleBtn.Font = Enum.Font.SourceSansBold
PartCycleBtn.TextSize = 14
PartCycleBtn.Text = "├─ 鎖定部位: " .. HitPartNames[ESPSettings.RagebotHitPartIndex]
PartCycleBtn.TextColor3 = Color3.fromRGB(255, 140, 160)
PartCycleBtn.ZIndex = 5
PartCycleBtn.Parent = RagePage
local PCCorner = Instance.new("UICorner") PCCorner.CornerRadius = UDim.new(0, 6) PCCorner.Parent = PartCycleBtn
local PCStroke = Instance.new("UIStroke") PCStroke.Thickness = 1 PCStroke.Color = Color3.fromRGB(45, 48, 62) PCStroke.Parent = PartCycleBtn

PartCycleBtn.MouseButton1Click:Connect(function()
    ESPSettings.RagebotHitPartIndex = ESPSettings.RagebotHitPartIndex + 1
    if ESPSettings.RagebotHitPartIndex > #HitParts then ESPSettings.RagebotHitPartIndex = 1 end
    PartCycleBtn.Text = "├─ 鎖定部位: " .. HitPartNames[ESPSettings.RagebotHitPartIndex]
end)
AddModernSlider("├─ 突襲單點滯留 (Attack Speed)", "RageAttackSpeed", 0.1, 3.0, RagePage, 3, true)
AddModernSlider("└─ 虛空躲避間隔 (Hide In Void)", "RageHideVoid", 0.1, 3.0, RagePage, 4, true)

-- Movement Page
AddToggle("飛行模式 (Flight - Space/Shift)", "Flight", MovementPage, 1, false)
AddToggle("開啟 CFrame 速度修改", "Speed", MovementPage, 2, false)
AddModernSlider("角色移動速度 (CFrame Speed)", "SpeedValue", 1, 250, MovementPage, 3, false)
AddToggle("開啟伺服器陀螺 (Spinbot)", "Spin", MovementPage, 4, false)
AddModernSlider("陀螺旋轉速度 (Spin Speed)", "SpinSpeed", 1, 100, MovementPage, 5, false)
AddToggle("穿牆模式 (Noclip)", "Noclip", MovementPage, 6, false)
AddToggle("自動連跳 (Auto Jump)", "AutoJump", MovementPage, 7, false) 

-- 🎯 Misc Page (純淨版：只留第三視角、Name Spoof、FOV、牆壁透明度)
AddModernSlider("玩家視角大小 (Player FOV)", "PlayerFOV", 10, 120, MiscPage, 1, false)
AddToggle("隱藏自己名字 (Spoof Self)", "SpoofSelf", MiscPage, 2, false)
AddToggle("隱藏他人名字 (Spoof Others)", "SpoofOthers", MiscPage, 3, false)
AddToggle("👁️ 強制第三視角 (Third Person)", "ThirdPerson", MiscPage, 4, false)
AddToggle("🧱 牆壁透明度修改開關", "WallTransparencySwitch", MiscPage, 5, false)
AddModernSlider("└─ 牆壁透明大小 (數值)", "WallTransparency", 0, 1, MiscPage, 6, true)

-- ➕ Crosshair 準星標籤頁 (加入關閉旋轉歸位修復)
AddToggle("開啟準星 (Crosshair)", "CrosshairEnabled", CrosshairPage, 1, false)
CreateHexColorInput("└─ 準星顏色:", 2, "CrosshairColor", CrosshairPage, nil)
AddModernSlider("└─ 長度 (Size)", "CrosshairSize", 1, 100, CrosshairPage, 3, true)
AddModernSlider("└─ 粗細 (Thickness)", "CrosshairThickness", 1, 10, CrosshairPage, 4, true)
AddModernSlider("└─ 間距 (Gap)", "CrosshairGap", 0, 50, CrosshairPage, 5, true)
AddToggle("└─ 顯示中心點 (Dot)", "CrosshairDotEnabled", CrosshairPage, 6, true)
AddToggle("└─ 顯示外線 (Lines)", "CrosshairLinesEnabled", CrosshairPage, 7, true)
AddToggle("└─ 開啟旋轉 (Rotation)", "CrosshairRotationEnabled", CrosshairPage, 8, true, function()
    -- ❌ 旋轉關閉時，準星立刻移回最正、最原本的水平垂直位置！
    if not ESPSettings.CrosshairRotationEnabled then
        CrosshairContainer.Rotation = 0
    end
end)
AddModernSlider("└─ 旋轉速度 (Speed)", "CrosshairRotationSpeed", 1, 360, CrosshairPage, 9, true)

-- 🎨 Color Test 測試標籤頁
AddToggle("覆蓋世界顏色 (Scene Color)", "SceneEffect", ColorTestPage, 1, false)
CreateHexColorInput("└─ 世界顏色:", 2, "SceneColor", ColorTestPage, nil)
AddModernSlider("└─ 覆蓋強度 (Intensity)", "SceneIntensity", 0, 100, ColorTestPage, 3, true)

local function ApplyAdvancedFog()
    if not ESPSettings.FogV9Enabled then
        TweenService:Create(Lighting, TweenInfo.new(0.4), { FogColor = DefaultFogColor, FogStart = DefaultFogStart, FogEnd = DefaultFogEnd }):Play()
        if MapAtmosphere then TweenService:Create(MapAtmosphere, TweenInfo.new(0.4), { Density = DefaultAtmosphereDensity, Color = DefaultAtmosphereColor, Haze = DefaultAtmosphereHaze }):Play() end
        return
    end
    local t = ESPSettings.FogV9Intensity / 100
    local baseEnd = math.min(DefaultFogEnd, FOG_MAX_END)
    if baseEnd <= FOG_MIN_END then baseEnd = FOG_MAX_END end
    local fogEnd = baseEnd - t * (baseEnd - FOG_MIN_END)
    
    TweenService:Create(Lighting, TweenInfo.new(0.3), { FogColor = ESPSettings.FogV9Color, FogStart = 0, FogEnd = fogEnd }):Play()
    if MapAtmosphere then
        TweenService:Create(MapAtmosphere, TweenInfo.new(0.3), {
            Density = math.clamp((DefaultAtmosphereDensity or 0.3) + t * 0.6, 0, 1),
            Color = ESPSettings.FogV9Color,
            Haze = math.clamp((DefaultAtmosphereHaze or 0) + t * 4, 0, 10)
        }):Play()
    end
end
AddToggle("進階霧氣 (Advanced Fog)", "FogV9Enabled", ColorTestPage, 4, false, ApplyAdvancedFog)
CreateHexColorInput("└─ 霧氣顏色:", 5, "FogV9Color", ColorTestPage, ApplyAdvancedFog)
AddModernSlider("└─ 霧氣濃度 (Intensity)", "FogV9Intensity", 0, 100, ColorTestPage, 6, true, ApplyAdvancedFog)

AddToggle("進階大雪 (V9 Multi-Snow)", "SnowV9Enabled", ColorTestPage, 7, false)
CreateHexColorInput("└─ 雪花顏色:", 8, "SnowV9Color", ColorTestPage, nil)
AddModernSlider("└─ 大雪強度 (Intensity)", "SnowV9Intensity", 0, 100, ColorTestPage, 9, true)

local function ApplyCharacterAppearance()
    local character = LocalPlayer.Character
    if not character then return end
    local strength = ESPSettings.CharMaterialIntensity / 100
    local isNeon = ESPSettings.CharMaterial == Enum.Material.Neon

    if not isNeon then
        for _, data in ipairs(NeonGlowLights) do if data.light then data.light:Destroy() end end
        table.clear(NeonGlowLights)
    end

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and not ExcludedPartNames[part.Name] and part.Transparency < 1 then
            if ESPSettings.CharApplyColor then part.Color = ESPSettings.CharColor end
            part.Material = ESPSettings.CharMaterial
            part.Reflectance = strength * 0.4
            part.Transparency = (1 - strength) * 0.35

            if isNeon then
                local light = part:FindFirstChild("TestGUI_NeonGlow")
                if not light then
                    light = Instance.new("PointLight") light.Name = "TestGUI_NeonGlow" light.Shadows = false light.Parent = part
                    table.insert(NeonGlowLights, {part = part, light = light})
                end
                light.Color = ESPSettings.CharApplyColor and ESPSettings.CharColor or Color3.fromRGB(255, 255, 255)
                light.Brightness = 1 + strength * 4
                light.Range = 6 + strength * 10
            end
        end
    end
end
AddToggle("啟用角色顏色 (Char Color)", "CharApplyColor", ColorTestPage, 10, false, ApplyCharacterAppearance)
CreateHexColorInput("└─ 角色顏色:", 11, "CharColor", ColorTestPage, ApplyCharacterAppearance)
AddModernSlider("角色材質強度 (Material Intensity)", "CharMaterialIntensity", 0, 100, ColorTestPage, 12, false, ApplyCharacterAppearance)

local function AddMaterialBtn(name, material, yIndex)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -30, 0, 32) Btn.Position = UDim2.new(0, 20, 0, 12 + (yIndex - 1) * 38)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 26, 35) Btn.BorderSizePixel = 0
    Btn.Text = "👉 材質: " .. name Btn.TextColor3 = Color3.fromRGB(200, 205, 220)
    Btn.Font = Enum.Font.SourceSansBold Btn.TextSize = 13 Btn.ZIndex = 5 Btn.Parent = ColorTestPage
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Btn
    local Stroke = Instance.new("UIStroke") Stroke.Thickness = 1 Stroke.Color = Color3.fromRGB(45, 48, 62) Stroke.Parent = Btn
    Btn.MouseButton1Click:Connect(function() ESPSettings.CharMaterial = material ApplyCharacterAppearance() end)
end
AddMaterialBtn("塑膠 (Plastic)", Enum.Material.Plastic, 13)
AddMaterialBtn("光滑塑膠 (SmoothPlastic)", Enum.Material.SmoothPlastic, 14)
AddMaterialBtn("霓虹 (Neon)", Enum.Material.Neon, 15)
AddMaterialBtn("力場 (ForceField)", Enum.Material.ForceField, 16)
AddMaterialBtn("玻璃 (Glass)", Enum.Material.Glass, 17)
AddMaterialBtn("金屬 (Metal)", Enum.Material.Metal, 18)
AddMaterialBtn("木頭 (Wood)", Enum.Material.Wood, 19)

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    table.clear(NeonGlowLights)
    ApplyCharacterAppearance()
end))

Pages["Visual"].Visible = true
PageButtons["Visual"].BackgroundColor3 = Color3.fromRGB(35, 38, 55)
PageButtons["Visual"].TextColor3 = Color3.fromRGB(255, 255, 255)
PageButtons["Visual"]:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(91, 168, 252)

-- ==========================================
-- 5. 尋敵、ESP 與自瞄機制
-- ==========================================
local function IsPlayerVisible(targetChar)
    local localChar = LocalPlayer.Character
    local head = targetChar and targetChar:FindFirstChild("Head")
    if not localChar or not head then return false end
    local raycastParams = RaycastParams.new() raycastParams.FilterType = Enum.RaycastFilterType.Exclude raycastParams.FilterDescendantsInstances = {localChar, targetChar, ScreenGui}
    local result = Workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, raycastParams)
    return result == nil
end

local function GetTarget(maxFOV, wallCheck, lockNearest)
    local closestPlayer = nil
    local shortestMouseDist = maxFOV
    local shortest3DDist = math.huge
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and targetHrp then
                if not wallCheck or IsPlayerVisible(player.Character) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                    if onScreen then
                        if lockNearest and localHrp then
                            local dist3D = (localHrp.Position - targetHrp.Position).Magnitude
                            if dist3D < shortest3DDist then shortest3DDist = dist3D closestPlayer = player end
                        else
                            local mouseLocation = UserInputService:GetMouseLocation()
                            local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                            if mouseDistance < shortestMouseDist then shortestMouseDist = mouseDistance closestPlayer = player end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

task.spawn(function()
    local lastSelectedPart = "Head"
    local nextDecisionTime = 0
    while true do
        task.wait(0.001)
        if not ScreenGui or not ScreenGui.Parent then break end

        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

        if ESPSettings.AutoJump and myHum and myHum.Health > 0 then
            if myHum.FloorMaterial ~= Enum.Material.Air then myHum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end

        if ESPSettings.Aimbot and isRightMouseDown then
            local target = GetTarget(ESPSettings.AimbotFOV, ESPSettings.AimbotWallCheck, ESPSettings.AimbotLockNearest)
            if target and target.Character then
                if ESPSettings.AimbotMode == "Rage Lock" then
                    local head = target.Character:FindFirstChild("Head")
                    if head then Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position) end
                else
                    if tick() > nextDecisionTime then
                        local total = ESPSettings.CustomHeadChance + ESPSettings.CustomBodyChance
                        if total > 0 then lastSelectedPart = (math.random(1, total) <= ESPSettings.CustomHeadChance) and "Head" or "HumanoidRootPart"
                        else lastSelectedPart = "Head" end
                        nextDecisionTime = tick() + 0.1 
                    end
                    local aimTargetPart = target.Character:FindFirstChild(lastSelectedPart) or target.Character:FindFirstChild("Head")
                    if aimTargetPart then
                        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
                        if ESPSettings.AimbotSmoothness >= 100 then Camera.CFrame = targetCF
                        else Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(ESPSettings.AimbotSmoothness / 100, 0.01, 1)) end
                    end
                end
            end
        end

        if ESPSettings.SilentAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local target = GetTarget(ESPSettings.SilentAimFOV, ESPSettings.SilentAimWallCheck, false)
            if target and target.Character and target.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            end
        end

        if isRightMouseDown and not ESPSettings.Ragebot then
            local mousePos = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            if myChar then raycastParams.FilterDescendantsInstances = {myChar, ScreenGui} end
            local rayResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            if rayResult and rayResult.Instance then
                local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
                local hitPlayer = hitModel and Players:GetPlayerFromCharacter(hitModel)
                if hitPlayer and hitPlayer ~= LocalPlayer and hitModel:FindFirstChildOfClass("Humanoid") and hitModel:FindFirstChildOfClass("Humanoid").Health > 0 then mouse1click() end
            end
        end

        if ESPSettings.Ragebot and not ragebotActiveThread and myHrp and myHum and myHum.Health > 0 then
            task.spawn(function() 
                ragebotActiveThread = true 
                for _, player in pairs(Players:GetPlayers()) do 
                    if getgenv().SpecificRageTarget ~= "All" then
                        if player.Name ~= getgenv().SpecificRageTarget then
                            continue
                        end
                    end

                    if not ESPSettings.Ragebot then break end
                    if player ~= LocalPlayer and player.Character then
                        local enemyHum = player.Character:FindFirstChildOfClass("Humanoid")
                        local enemyHrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local activePartName = HitParts[ESPSettings.RagebotHitPartIndex]
                        local enemyTargetPart = player.Character:FindFirstChild(activePartName) or enemyHrp
                        
                        if enemyHum and enemyHum.Health > 0 and enemyHrp and enemyTargetPart then
                            local attackEndTime = tick() + ESPSettings.RageAttackSpeed
                            local Bind
                            Bind = RunService.RenderStepped:Connect(function()
                                if enemyHum.Health > 0 and ESPSettings.Ragebot and myHum.Health > 0 then
                                    myHrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                    myHrp.CFrame = enemyHrp.CFrame * CFrame.new(0, 3.6, 0)
                                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemyTargetPart.Position)
                                    mouse1click()
                                end
                            end)
                            while tick() < attackEndTime and enemyHum.Health > 0 and ESPSettings.Ragebot and myHum.Health > 0 do task.wait(0.01) end
                            if Bind then Bind:Disconnect() end
                            myHrp.CFrame = CFrame.new(myHrp.Position.X, -4500, myHrp.Position.Z)
                            task.wait(ESPSettings.RageHideVoid)
                        end
                    end
                end
                ragebotActiveThread = false
            end)
        end
    end
end)

-- ==========================================
-- 6. Name Spoof 攔截
-- ==========================================
local function ApplyNameSpoof()
    local scanRoots = {}
    local myPlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if myPlayerGui then table.insert(scanRoots, myPlayerGui) end
    for _, p in pairs(Players:GetPlayers()) do if p.Character then table.insert(scanRoots, p.Character) end end
    for _, root in pairs(scanRoots) do
        for _, v in pairs(root:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                if ESPSettings.SpoofSelf and (v.Text:find(LocalPlayer.Name, 1, true) or v.Text:find(LocalPlayer.DisplayName, 1, true)) then
                    v.Text = v.Text:gsub(LocalPlayer.Name, ESPSettings.SpoofSelfName):gsub(LocalPlayer.DisplayName, ESPSettings.SpoofSelfName)
                end
                if ESPSettings.SpoofOthers then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and (v.Text:find(p.Name, 1, true) or v.Text:find(p.DisplayName, 1, true)) then
                            v.Text = v.Text:gsub(p.Name, ESPSettings.SpoofOthersName):gsub(p.DisplayName, ESPSettings.SpoofOthersName)
                        end
                    end
                end
            end
        end
    end
end
task.spawn(function() while ScreenGui.Parent do if ESPSettings.SpoofSelf or ESPSettings.SpoofOthers then pcall(ApplyNameSpoof) end task.wait(1) end end)

-- ==========================================
-- 7. ESP 渲染
-- ==========================================
local function SetupESP(player)
    if player == LocalPlayer then return end
    local function CleanESP()
        if ESPTable[player] then 
            pcall(function() ESPTable[player].Highlight:Destroy() ESPTable[player].Box:Destroy() ESPTable[player].BarGui:Destroy() ESPTable[player].HeadLine:Destroy() ESPTable[player].HeadLineAnchor:Destroy() ESPTable[player].NameGui:Destroy() end)
            ESPTable[player] = nil
        end
    end

    local function CreateElements(char)
        CleanESP() if not char then return end
        task.spawn(function()
            local head = char:WaitForChild("Head", 5) local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if not hrp or not head then return end 

            local hl = Instance.new("Highlight") hl.FillTransparency = 0.5 hl.OutlineColor = Color3.fromRGB(255, 255, 255) hl.Parent = char
            local bg = Instance.new("BillboardGui") bg.AlwaysOnTop = true bg.Size = UDim2.new(4.5, 0, 6, 0) bg.Adornee = hrp bg.Parent = ScreenGui
            local box = Instance.new("Frame") box.Size = UDim2.new(1, 0, 1, 0) box.BackgroundTransparency = 1 box.Parent = bg
            local stroke = Instance.new("UIStroke") stroke.Thickness = 1.5 stroke.Color = Color3.fromRGB(255, 255, 255) stroke.Parent = box

            local barGui = Instance.new("BillboardGui") barGui.AlwaysOnTop = true barGui.Size = UDim2.new(4.5, 0, 6, 0) barGui.Adornee = hrp barGui.Parent = ScreenGui
            local healthBar = Instance.new("Frame") healthBar.Size = UDim2.new(0.05, 0, 0.9, 0) healthBar.Position = UDim2.new(-0.1, 0, 0.05, 0) healthBar.BackgroundColor3 = Color3.fromRGB(91, 168, 252) healthBar.Parent = barGui

            local skyAnchorPart = Instance.new("Part") skyAnchorPart.Anchored = true skyAnchorPart.CanCollide = false skyAnchorPart.CanQuery = false skyAnchorPart.Transparency = 1 skyAnchorPart.Size = Vector3.new(0.1, 0.1, 0.1) skyAnchorPart.Parent = Workspace
            local bottomAtt = Instance.new("Attachment") bottomAtt.Parent = hrp
            local topAtt = Instance.new("Attachment") topAtt.Parent = skyAnchorPart
            local cylinder = Instance.new("Beam") cylinder.Attachment0 = bottomAtt cylinder.Attachment1 = topAtt cylinder.Width0 = 1.2 cylinder.Width1 = 1.2 cylinder.FaceCamera = true cylinder.LightEmission = 1 cylinder.Color = ColorSequence.new(ESPSettings.HeadESPColor1) cylinder.Transparency = NumberSequence.new(1) cylinder.Parent = hrp

            local nameGui = Instance.new("BillboardGui") nameGui.AlwaysOnTop = true nameGui.Size = UDim2.new(0, 200, 0, 30) nameGui.ExtentsOffset = Vector3.new(0, 3.5, 0) nameGui.Adornee = hrp nameGui.Parent = ScreenGui
            local nameLabel = Instance.new("TextLabel") nameLabel.Size = UDim2.new(1, 0, 1, 0) nameLabel.BackgroundTransparency = 1 nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) nameLabel.Font = Enum.Font.SourceSansBold nameLabel.TextSize = 14 nameLabel.Text = player.Name nameLabel.Parent = nameGui
            local nameStroke = Instance.new("UIStroke") nameStroke.Thickness = 2 nameStroke.Color = Color3.fromRGB(0, 0, 0) nameStroke.Parent = nameLabel

            ESPTable[player] = { Highlight = hl, Box = bg, Bar = healthBar, BarGui = barGui, HeadLine = cylinder, HeadLineAnchor = skyAnchorPart, NameGui = nameGui, NameLabel = nameLabel, Char = char }
        end)
    end
    if player.Character then CreateElements(player.Character) end
    table.insert(Connections, player.CharacterAdded:Connect(function(char) task.wait(0.5) CreateElements(char) end))
    table.insert(Connections, player.CharacterRemoving:Connect(CleanESP))
end
for _, p in pairs(Players:GetPlayers()) do SetupESP(p) end
table.insert(Connections, Players.PlayerAdded:Connect(SetupESP))

-- ==========================================
-- 8. 全域渲染引擎與牆壁透明監聽
-- ==========================================
local LastWallSwitchState = nil
local LastWallAlpha = nil

table.insert(Connections, RunService.Heartbeat:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum and hrp and hum.Health > 0 then
        if ESPSettings.Flight then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
            local camCF = Camera.CFrame local moveVec = Vector3.new()
            if not UserInputService:GetFocusedTextBox() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end
            end
            if moveVec.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (moveVec.Unit * (ESPSettings.SpeedValue * deltaTime * 2)) end
        end
        if ESPSettings.Speed and not ESPSettings.Flight and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (ESPSettings.SpeedValue * deltaTime))
        end
        if ESPSettings.Spin then
            hum.AutoRotate = false 
            local bav = hrp:FindFirstChild("SpinbotBAV") or Instance.new("BodyAngularVelocity")
            if not bav.Parent then bav.Name = "SpinbotBAV" bav.MaxTorque = Vector3.new(0, math.huge, 0) bav.Parent = hrp end
            bav.AngularVelocity = Vector3.new(0, ESPSettings.SpinSpeed, 0)
        else
            hum.AutoRotate = true local bav = hrp:FindFirstChild("SpinbotBAV") if bav then bav:Destroy() end
        end
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    Camera.FieldOfView = ESPSettings.PlayerFOV
    FOVCircle.Visible = (ESPSettings.Aimbot and not ESPSettings.AimbotLockNearest)
    if FOVCircle.Visible then FOVCircle.Position = UserInputService:GetMouseLocation() FOVCircle.Radius = ESPSettings.AimbotFOV end
    SilentFOVCircle.Visible = ESPSettings.SilentAim
    if SilentFOVCircle.Visible then SilentFOVCircle.Position = UserInputService:GetMouseLocation() SilentFOVCircle.Radius = ESPSettings.SilentAimFOV end

    -- 🧱 牆壁透明度即時遍歷判定
    if LastWallSwitchState ~= ESPSettings.WallTransparencySwitch or LastWallAlpha ~= ESPSettings.WallTransparency then
        LastWallSwitchState = ESPSettings.WallTransparencySwitch
        LastWallAlpha = ESPSettings.WallTransparency
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(Players) and obj.Name ~= "Terrain" then
                if obj.Name ~= "TestGUI_SnowParticles" then
                    if ESPSettings.WallTransparencySwitch then
                        if not obj:GetAttribute("OriginalTransparency") then obj:SetAttribute("OriginalTransparency", obj.Transparency) end
                        obj.Transparency = ESPSettings.WallTransparency
                    else
                        local orig = obj:GetAttribute("OriginalTransparency")
                        if orig then obj.Transparency = orig obj:SetAttribute("OriginalTransparency", nil) end
                    end
                end
            end
        end
    end

    -- 👁️ Visual 面向視野細線條 (第一人稱隱藏，牆後敵人不變色)
    local isFirstPerson = (Camera.Focus.Position - Camera.CFrame.Position).Magnitude < 1.0
    if ESPSettings.LookLine and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and not isFirstPerson then
        local Head = LocalPlayer.Character.Head
        local Hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local TrueDirection = (Hrp and not ESPSettings.Spin) and Hrp.CFrame.LookVector or Camera.CFrame.LookVector
        
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Exclude
        RayParams.FilterDescendantsInstances = {LocalPlayer.Character, TargetParent, ScreenGui}
        RayParams.IgnoreWater = true
        
        local DynamicLength = ESPSettings.LookLineLength or 500
        local RayResult = Workspace:Raycast(Head.Position, TrueDirection * DynamicLength, RayParams)
        local LineEndPos = Head.Position + (TrueDirection * DynamicLength)
        local IsEnemyVisible = false
        
        if RayResult then
            LineEndPos = RayResult.Position
            local HitPart = RayResult.Instance
            -- 判斷碰到的第一個不透明物體是否為人類，不是牆壁
            local HitModel = HitPart:FindFirstAncestorOfClass("Model")
            if HitModel and HitModel:FindFirstChildOfClass("Humanoid") and HitModel ~= LocalPlayer.Character then
                IsEnemyVisible = true
            end
        end
        
        local Start2D = Camera:WorldToViewportPoint(Head.Position)
local End2D = Camera:WorldToViewportPoint(LineEndPos)

-- 計算攝影機與頭部的距離，小於 2 視為第一人稱
local isFirstPerson = (Camera.CFrame.Position - Head.Position).Magnitude < 2

-- 只要目標點 (Z軸) 在攝影機前方，就進行判定
if Start2D.Z > 0 then 
    -- 如果「不是」第一人稱，才繪製並顯示線條
    if not isFirstPerson then
        LookLineDrawing.From = Vector2.new(Start2D.X, Start2D.Y)
        LookLineDrawing.To = Vector2.new(End2D.X, End2D.Y)
        LookLineDrawing.Color = IsEnemyVisible and ESPSettings.LookLineHasTargetColor or ESPSettings.LookLineNoTargetColor
        LookLineDrawing.Visible = true
    else
        -- 是第一人稱則隱藏線條
        LookLineDrawing.Visible = false
    end
    
    -- 新增：無論是第一人稱還是第三人稱，只要偵測到敵人就觸發自動射擊
    if IsEnemyVisible then
        mouse1click()
    end
else
    -- 如果目標點在攝影機後方，隱藏線條
    LookLineDrawing.Visible = false
end
    else LookLineDrawing.Visible = false end

    -- [S3] 準星繪製
    if ESPSettings.CrosshairEnabled then
        CrosshairContainer.Visible = true
        CrosshairTop.Size = UDim2.new(0, ESPSettings.CrosshairThickness, 0, ESPSettings.CrosshairSize)
        CrosshairTop.Position = UDim2.new(0.5, 0, 0.5, -(ESPSettings.CrosshairGap + ESPSettings.CrosshairSize / 2))
        CrosshairBottom.Size = UDim2.new(0, ESPSettings.CrosshairThickness, 0, ESPSettings.CrosshairSize)
        CrosshairBottom.Position = UDim2.new(0.5, 0, 0.5, ESPSettings.CrosshairGap + ESPSettings.CrosshairSize / 2)
        CrosshairLeft.Size = UDim2.new(0, ESPSettings.CrosshairSize, 0, ESPSettings.CrosshairThickness)
        CrosshairLeft.Position = UDim2.new(0.5, -(ESPSettings.CrosshairGap + ESPSettings.CrosshairSize / 2), 0.5, 0)
        CrosshairRight.Size = UDim2.new(0, ESPSettings.CrosshairSize, 0, ESPSettings.CrosshairThickness)
        CrosshairRight.Position = UDim2.new(0.5, ESPSettings.CrosshairGap + ESPSettings.CrosshairSize / 2, 0.5, 0)

        for _, bar in ipairs({CrosshairTop, CrosshairBottom, CrosshairLeft, CrosshairRight}) do
            bar.BackgroundColor3 = ESPSettings.CrosshairColor
            bar.Visible = ESPSettings.CrosshairLinesEnabled
        end
        local dotSize = math.max(2, ESPSettings.CrosshairThickness + 1)
        CrosshairDot.Size = UDim2.new(0, dotSize, 0, dotSize)
        CrosshairDot.BackgroundColor3 = ESPSettings.CrosshairColor
        CrosshairDot.Visible = ESPSettings.CrosshairDotEnabled

        if ESPSettings.CrosshairRotationEnabled then
            CrosshairContainer.Rotation = (CrosshairContainer.Rotation + ESPSettings.CrosshairRotationSpeed * dt) % 360
        end
    else
        CrosshairContainer.Visible = false
    end

    -- [S3] 世界色彩覆蓋
    if ESPSettings.SceneEffect then
        local t = ESPSettings.SceneIntensity / 100
        local blendedAmbient = DefaultAmbient:Lerp(ESPSettings.SceneColor, t)
        Lighting.Ambient = blendedAmbient
        Lighting.OutdoorAmbient = blendedAmbient
        WorldColorFilter.Enabled = true
        WorldColorFilter.TintColor = ESPSettings.SceneColor
        WorldColorFilter.Saturation = t * 1.2
        WorldColorFilter.Contrast = t * 0.25
    else
        WorldColorFilter.Enabled = false
    end

    -- [S3] V9 進階多點大雪
    local camPos = Camera.CFrame.Position
    for i, data in ipairs(SnowEmittersV9) do
        local angle = (i / SnowEmitterCount) * math.pi * 2
        local radiusOffset = Vector3.new(math.cos(angle) * 60, 40, math.sin(angle) * 60)
        data.part.CFrame = CFrame.new(camPos + radiusOffset)
        data.emitter.Rate = ESPSettings.SnowV9Enabled and (ESPSettings.SnowV9Intensity / 100 * 9000) or 0
        data.emitter.Color = ColorSequence.new(ESPSettings.SnowV9Color)
    end

    -- 強制第三視角
    if ESPSettings.ThirdPerson then LocalPlayer.CameraMode = Enum.CameraMode.Classic LocalPlayer.CameraMaxZoomDistance = 128 LocalPlayer.CameraMinZoomDistance = 10 
    else LocalPlayer.CameraMinZoomDistance = 0.5 end

    -- ESP 繪製
    for player, v in pairs(ESPTable) do
        if v.Char and v.Char.Parent then
            local hum = v.Char:FindFirstChildOfClass("Humanoid") local head = v.Char:FindFirstChild("Head")
            if hum and hum.Health > 0 and head then
                v.Highlight.Enabled = ESPSettings.Skeleton v.Box.Enabled = ESPSettings.Box v.BarGui.Enabled = ESPSettings.Health v.NameGui.Enabled = ESPSettings.NameShow
if ESPSettings.NameShow and v.NameLabel then
    v.NameLabel.Text = ESPSettings.SpoofOthers and ESPSettings.SpoofOthersName or player.Name
    
    -- 新增：即時更新名稱顏色與漸層設定
    if ESPSettings.HeadESPGradient then
        local grad = v.NameLabel:FindFirstChildOfClass("UIGradient")
        if not grad then
            grad = Instance.new("UIGradient")
            grad.Parent = v.NameLabel
        end
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ESPSettings.HeadESPColor1),
            ColorSequenceKeypoint.new(1, ESPSettings.HeadESPColor2)
        })
        v.NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- 漸層需要底色為白
    else
        local grad = v.NameLabel:FindFirstChildOfClass("UIGradient")
        if grad then grad:Destroy() end
        v.NameLabel.TextColor3 = ESPSettings.HeadESPColor1
    end
end
                if ESPSettings.Health then
                    local hp = hum.Health / hum.MaxHealth
                    v.Bar.Size = UDim2.new(0.05, 0, hp * 0.9, 0)
                    v.Bar.BackgroundColor3 = Color3.fromRGB(91, 168, 252):Lerp(Color3.fromRGB(255, 130, 240), 1 - hp)
                end
                if ESPSettings.HeadESP then
                    v.HeadLine.Transparency = NumberSequence.new(0.4)
                    if ESPSettings.HeadESPGradient then v.HeadLine.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, ESPSettings.HeadESPColor1), ColorSequenceKeypoint.new(1, ESPSettings.HeadESPColor2)})
                    else v.HeadLine.Color = ColorSequence.new(ESPSettings.HeadESPColor1) end
                    v.HeadLineAnchor.CFrame = CFrame.new(head.Position + Vector3.new(0, 500, 0))
                else v.HeadLine.Transparency = NumberSequence.new(1) end
            else v.Box.Enabled = false v.BarGui.Enabled = false v.Highlight.Enabled = false v.HeadLine.Transparency = NumberSequence.new(1) v.NameGui.Enabled = false end
        else pcall(function() v.Box.Enabled = false v.BarGui.Enabled = false v.Highlight.Enabled = false v.HeadLine.Transparency = NumberSequence.new(1) v.NameGui.Enabled = false end) end
    end
    if HeadESPColor2Row then HeadESPColor2Row.Visible = ESPSettings.HeadESPGradient end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    if (ESPSettings.Noclip or ESPSettings.Ragebot) and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end
end))

-- ==========================================
-- 9. 輸入監聽與完全還原卸載機制
-- ==========================================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then 
        isRightMouseDown = true TriggerStatusBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 55) TriggerStatusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if not TriggerStatusBtn:FindFirstChildOfClass("UIGradient") then ApplyThemeGradient(TriggerStatusBtn) end
    elseif input.KeyCode == Enum.KeyCode.RightShift then 
        MainFrame.Visible = not MainFrame.Visible 
    elseif input.KeyCode == Enum.KeyCode.P then
        ESPSettings.Ragebot = not ESPSettings.Ragebot
        if rageBtnGlobal then
            local enabled = ESPSettings.Ragebot rageBtnGlobal.Text = enabled and "🔥 Ragebot [P]: ON" or "🔥 Ragebot [P]: OFF"
            if enabled then rageBtnGlobal.BackgroundColor3 = Color3.fromRGB(255, 255, 255) rageBtnGlobal.TextColor3 = Color3.fromRGB(15, 15, 20) if not rageBtnGlobal:FindFirstChildOfClass("UIGradient") then ApplyThemeGradient(rageBtnGlobal) end
            else rageBtnGlobal.BackgroundColor3 = Color3.fromRGB(22, 24, 32) rageBtnGlobal.TextColor3 = Color3.fromRGB(170, 175, 190) local grad = rageBtnGlobal:FindFirstChildOfClass("UIGradient") if grad then grad:Destroy() end end
        end
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then 
        isRightMouseDown = false TriggerStatusBtn.BackgroundColor3 = Color3.fromRGB(18, 20, 26) TriggerStatusBtn.TextColor3 = Color3.fromRGB(140, 145, 160)
        local grad = TriggerStatusBtn:FindFirstChildOfClass("UIGradient") if grad then grad:Destroy() end
    end
end))

local function UnloadScript()
    for _, conn in pairs(Connections) do if conn then conn:Disconnect() end end table.clear(Connections)
    if FOVCircle then FOVCircle:Remove() end
    if SilentFOVCircle then SilentFOVCircle:Remove() end
    if LookLineDrawing then LookLineDrawing:Remove() end
    for _, data in ipairs(SnowEmittersV9) do data.part:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    if CrosshairGui then CrosshairGui:Destroy() end
    if WorldColorFilter then WorldColorFilter:Destroy() end
    for _, player in pairs(Players:GetPlayers()) do
        if ESPTable[player] then
            pcall(function() ESPTable[player].Highlight:Destroy() ESPTable[player].Box:Destroy() ESPTable[player].BarGui:Destroy() ESPTable[player].HeadLine:Destroy() ESPTable[player].HeadLineAnchor:Destroy() ESPTable[player].NameGui:Destroy() end)
        end
    end
    -- 還原牆體透明
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local orig = obj:GetAttribute("OriginalTransparency")
            if orig then obj.Transparency = orig obj:SetAttribute("OriginalTransparency", nil) end
        end
    end
    Lighting.Ambient = DefaultAmbient
    Lighting.OutdoorAmbient = DefaultOutdoorAmbient
    Lighting.FogColor = DefaultFogColor
    Lighting.FogEnd = DefaultFogEnd
    print("【系統】SHOOK_v1 已安全卸載，所有環境與牆體已還原！")
end
ExitBtn.MouseButton1Click:Connect(UnloadScript)
