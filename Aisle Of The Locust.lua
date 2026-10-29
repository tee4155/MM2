--[[
    ============================================================
    AISLES OF THE LOCUST - LOCUST ESP (MOBILE EDITION)
    ✅ แสดงตัว Locust / มอนสเตอร์ ผ่านกำแพง
    ✅ แสดงผู้เล่น, เส้นวางเป้า (Tracer), ระยะทาง
    ✅ ปุ่มลอยย้ายได้ + UI กระทัดรัดสำหรับมือถือ
    ✅ ตรวจจับมอนสเตอร์อัตโนมัติ (Humanoid ที่ไม่ใช่ผู้เล่น)
    ============================================================
]]

--// SERVICES
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// STATE
local State = {
    LocustESP   = true,   -- เปิด ESP Locust อัตโนมัติ
    PlayerESP   = false,
    Tracer      = false,  -- เส้นวางเป้า
    ShowDist    = true,
    ShowName    = true,
    MaxRange    = math.huge, -- ไม่จำกัดระยะ
    LocustColor = Color3.fromRGB(255, 60, 60),  -- สีแดง Locust
    PlayerColor = Color3.fromRGB(60, 180, 255), -- สีฟ้า ผู้เล่น
}

local Connections = {}
local Highlights  = {} -- [instance] = Highlight
local DrawCache   = {} -- [instance] = {NameText, DistText, TracerLine}
local IsDead      = false

local function addConnection(conn)
    table.insert(Connections, conn)
    return conn
end

--// UTILITY
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end

--// ✅ ตรวจจับ Locust / มอนสเตอร์ อัตโนมัติ
-- กฎ: Model ที่มี Humanoid แต่ไม่ใช่ตัวละครของผู้เล่นใครๆ = มอนสเตอร์
local playerChars = {}
local function refreshPlayerChars()
    table.clear(playerChars)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
end

local function isMonster(model)
    if not model or not model:IsA("Model") then return false end
    if playerChars[model] then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    -- กรองตัวเอง (เผื่อ)
    if model == LocalPlayer.Character then return false end
    -- ชื่อที่มักเป็นมอนสเตอร์ (เพิ่มความมั่นใจ)
    local name = model.Name:lower()
    local isLikelyMonster = name:find("locust") or name:find("monster") or name:find("enemy")
        or name:find("ai") or name:find("entity") or name:find("scp") or name:find("creature")
        or name:find("the ") or name:find("npc")
    return isLikelyMonster or true -- ถ้ามี Humanoid และไม่ใช่ผู้เล่น = ถือว่าเป็นมอนสเตอร์เลย
end

--// ล้าง Highlight / Drawing
local function clearOne(inst)
    if Highlights[inst] then pcall(function() Highlights[inst]:Destroy() end) Highlights[inst] = nil end
    local d = DrawCache[inst]
    if d then
        if d.NameText then pcall(function() d.NameText:Remove() end) end
        if d.DistText then pcall(function() d.DistText:Remove() end) end
        if d.Tracer then pcall(function() d.Tracer:Remove() end) end
        DrawCache[inst] = nil
    end
end

local function clearAll()
    for inst, _ in pairs(Highlights) do clearOne(inst) end
    table.clear(Highlights)
    table.clear(DrawCache)
end

--// ตรวจสอบว่า Drawing API พร้อมไหม
local DrawingOK = (Drawing and Drawing.new) ~= nil

--// ลูปหลัก ESP
addConnection(RunService.RenderStepped:Connect(function()
    if IsDead then return end
    refreshPlayerChars()

    local myChar = LocalPlayer.Character
    local myHRP  = getHRP(myChar)

    -- 1. รวบรวมเป้าหมายทั้งหมด
    local targets = {} -- {inst=Model, color=Color3, label=string}

    if State.LocustESP then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isMonster(obj) then
                targets[obj] = {color = State.LocustColor, label = "LOCUST"}
            end
        end
    end

    if State.PlayerESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                targets[p.Character] = {color = State.PlayerColor, label = p.Name}
            end
        end
    end

    -- 2. ลบของที่ไม่มีอยู่แล้ว
    for inst, _ in pairs(Highlights) do
        if not inst or not inst.Parent or not targets[inst] then
            clearOne(inst)
        end
    end

    -- 3. สร้าง/อัพเดทเป้าหมาย
    for model, info in pairs(targets) do
        local hrp = getHRP(model)
        local hum = getHum(model)
        if not hrp then
            clearOne(model)
        else
            -- Highlight (ใช้ได้เสมอ ไม่ต้องอาศัย Drawing)
            local hl = Highlights[model]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.Name = "ESP_" .. info.label
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = model
                Highlights[model] = hl
            end
            hl.FillColor = info.color
            hl.OutlineColor = info.color
            hl.Enabled = true

            -- Drawing text + tracer (ถ้า executor รองรับ)
            if DrawingOK and myHRP then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local dist = myHRP and (hrp.Position - myHRP.Position).Magnitude or 0

                if onScreen and dist <= State.MaxRange then
                    local d = DrawCache[model]
                    if not d then
                        d = {}
                        if State.ShowName then
                            d.NameText = Drawing.new("Text")
                            d.NameText.Size = 14; d.NameText.Center = true; d.NameText.Outline = true; d.NameText.Font = 2
                        end
                        if State.ShowDist then
                            d.DistText = Drawing.new("Text")
                            d.DistText.Size = 12; d.DistText.Center = true; d.DistText.Outline = true; d.DistText.Font = 2
                        end
                        if State.Tracer then
                            d.Tracer = Drawing.new("Line")
                            d.Tracer.Thickness = 1.5
                        end
                        DrawCache[model] = d
                    end

                    if d.NameText then
                        d.NameText.Color = info.color
                        d.NameText.Text = "[" .. info.label .. "]"
                        d.NameText.Position = Vector2.new(pos.X, pos.Y - 40)
                        d.NameText.Visible = State.ShowName
                    end
                    if d.DistText then
                        d.DistText.Color = info.color
                        d.DistText.Text = math.floor(dist) .. "m"
                        d.DistText.Position = Vector2.new(pos.X, pos.Y - 24)
                        d.DistText.Visible = State.ShowDist
                    end
                    if d.Tracer then
                        d.Tracer.Color = info.color
                        d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        d.Tracer.To = Vector2.new(pos.X, pos.Y)
                        d.Tracer.Visible = State.Tracer
                    end
                else
                    local d = DrawCache[model]
                    if d then
                        if d.NameText then d.NameText.Visible = false end
                        if d.DistText then d.DistText.Visible = false end
                        if d.Tracer then d.Tracer.Visible = false end
                    end
                end
            end
        end
    end
end))

--// UI CREATION
local function makeDraggable(frame, dragArea)
    local dragging, dragInput, dragStart, startPos
    addConnection(dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    addConnection(dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

pcall(function() if _G.LocustESP_Cleanup then _G.LocustESP_Cleanup() end end)
pcall(function() if _G.LocustESP_GUI then _G.LocustESP_GUI:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Locust_ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    else ScreenGui.Parent = game:GetService("CoreGui") end
end)
_G.LocustESP_GUI = ScreenGui

-- ปุ่มลอย
local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(1, -65, 1, -65)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Icon.BorderSizePixel = 0
Icon.Text = "L"
Icon.Font = Enum.Font.GothamBold
Icon.TextSize = 22
Icon.TextColor3 = Color3.fromRGB(255, 60, 60)
Icon.AutoButtonColor = false
Icon.Parent = ScreenGui
local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 12); ic.Parent = Icon
local ist = Instance.new("UIStroke"); ist.Color = Color3.fromRGB(255, 60, 60); ist.Thickness = 1.5; ist.Parent = Icon
makeDraggable(Icon, Icon)

-- หน้าต่างหลัก
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 340)
Main.Position = UDim2.new(0.5, -160, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", Main); ms.Color = Color3.fromRGB(80, 80, 120); ms.Thickness = 1

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)
makeDraggable(Main, TitleBar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "LOCUST ESP v1.0"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -52)
Content.Position = UDim2.new(0, 8, 0, 46)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main
local cl = Instance.new("UIListLayout", Content); cl.Padding = UDim.new(0, 6); cl.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", Content).PaddingBottom = UDim.new(0, 8)

local yIndex = 0
local function sectionLabel(text)
    yIndex = yIndex + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = yIndex
    lbl.Parent = Content
end

local function createToggle(name, stateKey, color)
    yIndex = yIndex + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    row.BorderSizePixel = 0
    row.LayoutOrder = yIndex
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 22)
    toggle.Position = UDim2.new(1, -48, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = row
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    knob.BorderSizePixel = 0
    knob.Parent = row
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    -- ย้าย knob ไปอยู่ใน toggle
    knob.Parent = toggle

    local onColor = color or Color3.fromRGB(60, 200, 90)
    local function updateVisual()
        if State[stateKey] then
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = onColor}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8)}):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8)}):Play()
        end
    end
    toggle.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        updateVisual()
        if not State.LocustESP and not State.PlayerESP then clearAll() end
    end)
    updateVisual()
end

--// สร้างเมนู
sectionLabel("🦗  LOCUST / มอนสเตอร์")
createToggle("แสดง Locust ESP", "LocustESP", Color3.fromRGB(255, 80, 80))

sectionLabel("👥  ผู้เล่น")
createToggle("แสดงผู้เล่น ESP", "PlayerESP", Color3.fromRGB(60, 140, 255))

sectionLabel("⚙️  ตัวเลือกเพิ่มเติม")
createToggle("แสดงชื่อ", "ShowName", Color3.fromRGB(100, 200, 255))
createToggle("แสดงระยะทาง", "ShowDist", Color3.fromRGB(100, 200, 255))
createToggle("เส้นวางเป้า (Tracer)", "Tracer", Color3.fromRGB(160, 80, 255))

--// เปิดปิด UI ด้วยปุ่มลอย
local uiOpen = false
local pressTime, pressPos = nil, nil
addConnection(Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pressTime = tick(); pressPos = input.Position
    end
end))
addConnection(Icon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if pressTime and pressPos then
            local dur = tick() - pressTime
            local moved = (input.Position - pressPos).Magnitude
            if dur < 0.35 and moved < 6 then
                uiOpen = not uiOpen
                Main.Visible = uiOpen
            end
            pressTime, pressPos = nil, nil
        end
    end
end))

--// Cleanup
local function fullCleanup()
    IsDead = true
    clearAll()
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    task.wait(0.05)
    pcall(function() ScreenGui:Destroy() end)
    _G.LocustESP_GUI = nil
    _G.LocustESP_Cleanup = nil
end
CloseBtn.MouseButton1Click:Connect(fullCleanup)
_G.LocustESP_Cleanup = fullCleanup

print("[Locust ESP] โหลดสำเร็จ! แตะไอคอน L เพื่อเปิดเมนู — Locust จะแสดงเป็นสีแดงผ่านกำแพงpressPos
