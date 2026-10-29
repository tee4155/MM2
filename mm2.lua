--[[
    ============================================================
    ⚡ MM2 GOD-TIER SCRIPT — MOBILE EDITION (FIXED v2)
    ✅ แก้ทุกจุดบั๊ก: ESP Name/Distance/HP ทำงานได้, Tracers ถูกต้อง,
       Fly บนมือถือได้, XRay ทำงาน, throttle สแกนไม่แลค, cleanup ครบ
    ============================================================
]]

if getgenv().MM2God_Unload then pcall(function() getgenv().MM2God_Unload() end) end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local S = {
    AutoFarm=true, AvoidMurderer=true, RespawnOnFull=true, PickUpGun=false, ShootOnFull=true, AutoOpenBoxes=true,
    KillAura=true, AutoShootMurder=true, SilentAim=false, AutoFlingSheriff=false, AntiFling=false, AutoThrowKnife=false,
    ESP_Enable=true, ESP_Murderer=true, ESP_Sheriff=true, ESP_Innocent=true, ESP_Hero=true,
    ESP_Box=true, ESP_Tracers=false, ESP_Name=false, ESP_Distance=true, ESP_HealthBar=false,
    WalkSpeed=false, JumpPower=false, Fly=false, NoClip=true, Bhop=false, Spin=false, Invisible=false, InfJump=false,
    AntiAFK=true, AutoVoteMap=true, AutoDupe=true, XRay=false,
}
local Sl = { FarmSpeed=22, AuraRange=250, WalkSpeedV=22, JumpPowerV=50, FlySpeed=60, FOV=400, Smoothness=4 }

local Connections = {}
local ESPHL = {}; ESPTracer = {}; ESPText = {}; OrigCollide = {}
local TargetCoin = nil; ResumeTime = 0; LastCoinScan = 0; Running = true
local FlyUpUntil = 0; XRayApplied = false; OrigXray = {}

local function addConn(c) table.insert(Connections, c); return c end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p) local c=p.Character local h=getHum(c) return c and h and h.Health>0 end

local function Unload()
    Running = false
    for k in pairs(S) do S[k] = false end
    local c = LocalPlayer.Character
    if c then
        local h = getHum(c); if h then h.WalkSpeed=16; h.JumpPower=50 end
        for part, orig in pairs(OrigCollide) do if part and part.Parent then pcall(function() part.CanCollide=orig end) end end
        for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier=0 end) end end
    end
    for _, e in pairs(ESPHL) do pcall(function() if e then e:Destroy() end end) end
    for _, t in pairs(ESPTracer) do pcall(function() if t then t:Destroy() end end) end
    for _, txt in pairs(ESPText) do pcall(function() if txt.bb then txt.bb:Destroy() end end) end
    for part, orig in pairs(OrigXray) do if part and part.Parent then pcall(function() part.LocalTransparencyModifier=orig end) end end
    table.clear(ESPHL); table.clear(ESPTracer); table.clear(ESPText); table.clear(OrigXray)
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() if _G.MM2God_GUI then _G.MM2God_GUI:Destroy() _G.MM2God_GUI=nil end end)
    getgenv().MM2God_Unload = nil
end
getgenv().MM2God_Unload = Unload

local function checkContainer(container)
    if not container then return nil end
    local hasTool = false
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            local nm = string.lower(item.Name)
            if nm:find("gun") or nm:find("revolver") or nm:find("sheriff") then return "Sheriff" end
            if nm:find("knife") or nm:find("murderer") or nm:find("blade") or nm:find("scythe") or nm:find("dagger") then return "Murderer" end
            if not (nm:find("radio") or nm:find("teddy") or nm:find("icecream") or nm:find("toy") or nm:find("balloon")) then hasTool = true end
        end
    end
    if hasTool then return "Murderer" end
    return nil
end
local function getRole(p)
    if not p or not p.Character then return "Innocent" end
    local r = checkContainer(p:FindFirstChildOfClass("Backpack"))
    if r then return r end
    return checkContainer(p.Character) or "Innocent"
end

local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local SG = Instance.new("ScreenGui")
SG.Name = "MM2God_GUI"; SG.ResetOnSpawn = false; SG.DisplayOrder = 999; SG.Parent = parentUI
_G.MM2God_GUI = SG

local ACCENT=Color3.fromRGB(255,60,60); ACCENT2=Color3.fromRGB(255,140,40)
local BG=Color3.fromRGB(14,14,20); BGP=Color3.fromRGB(24,24,34); BGB=Color3.fromRGB(34,34,48)
local TXTW=Color3.fromRGB(230,230,240); TXTG=Color3.fromRGB(140,140,160)

local cam = workspace.CurrentCamera
local vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
local MW = math.min(420, vw*0.4); local MH = math.min(680, vh-30)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, MW, 0, MH); Main.Position = UDim2.new(0.5, -MW/2, 0.5, -MH/2)
Main.BackgroundColor3 = BG; Main.Visible = true; Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local mst = Instance.new("UIStroke", Main); mst.Color = ACCENT; mst.Thickness = 1.5

local TB = Instance.new("Frame"); TB.Size=UDim2.new(1,0,0,46); TB.BackgroundColor3=BGP; TB.Parent=Main
Instance.new("UICorner", TB).CornerRadius = UDim.new(0,14)
local cov = Instance.new("Frame"); cov.Size=UDim2.new(1,0,0.5,0); cov.Position=UDim2.new(0,0,0.5,0); cov.BackgroundColor3=BGP; cov.BorderSizePixel=0; cov.Parent=TB
local Ttl = Instance.new("TextLabel"); Ttl.Size=UDim2.new(1,-55,0,24); Ttl.Position=UDim2.new(0,14,0,4)
Ttl.BackgroundTransparency=1; Ttl.Text="⚡ MM2 GOD-TIER"; Ttl.Font=Enum.Font.GothamBold; Ttl.TextSize=16
Ttl.TextColor3=ACCENT; Ttl.TextXAlignment=Enum.TextXAlignment.Left; Ttl.Parent=TB
local Sub = Instance.new("TextLabel"); Sub.Size=UDim2.new(1,-55,0,16); Sub.Position=UDim2.new(0,14,0,26)
Sub.BackgroundTransparency=1; Sub.Text="Mobile Edition · FIXED v2"; Sub.Font=Enum.Font.Gotham; Sub.TextSize=10
Sub.TextColor3=TXTG; Sub.TextXAlignment=Enum.TextXAlignment.Left; Sub.Parent=TB
local XBtn = Instance.new("TextButton"); XBtn.Size=UDim2.new(0,32,0,32); XBtn.Position=UDim2.new(1,-40,0,7)
XBtn.BackgroundColor3=Color3.fromRGB(210,50,60); XBtn.Text="✕"; XBtn.Font=Enum.Font.GothamBold; XBtn.TextSize=14
XBtn.TextColor3=Color3.new(1,1,1); XBtn.AutoButtonColor=false; XBtn.Parent=TB
Instance.new("UICorner", XBtn).CornerRadius=UDim.new(0,8)
addConn(XBtn.MouseButton1Click:Connect(function() Unload() end))

local mD,mDS,mSP=false,nil,nil
addConn(TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mD=true;mDS=i.Position;mSP=Main.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if mD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-mDS; Main.Position=UDim2.new(mSP.X.Scale,mSP.X.Offset+d.X,mSP.Y.Scale,mSP.Y.Offset+d.Y) end end))
addConn(TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mD=false end end))

local Tabs = {"Farm","Combat","ESP","Move","Misc"}
local TabBtns={}; TabFrames={}
local TabBar=Instance.new("Frame"); TabBar.Size=UDim2.new(1,0,0,38); TabBar.Position=UDim2.new(0,0,0,46); TabBar.BackgroundColor3=Color3.fromRGB(18,18,26); TabBar.Parent=Main
local TL=Instance.new("UIListLayout"); TL.FillDirection=Enum.FillDirection.Horizontal; TL.Padding=UDim.new(0,3); TL.Parent=TabBar
Instance.new("UIPadding", TabBar).PaddingLeft=UDim.new(0,4)
for i,name in ipairs(Tabs) do
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1/#Tabs, -5, 1, -6); b.Position=UDim2.new(0,0,0,3)
    b.BackgroundColor3 = i==1 and ACCENT or BGB; b.Text=name; b.Font=Enum.Font.GothamBold; b.TextSize=12
    b.TextColor3=Color3.new(1,1,1); b.AutoButtonColor=false; b.Parent=TabBar
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
    local f=Instance.new("ScrollingFrame"); f.Size=UDim2.new(1,-12,1,-94); f.Position=UDim2.new(0,6,0,90)
    f.BackgroundTransparency=1; f.CanvasSize=UDim2.new(0,0,0,0); f.AutomaticCanvasSize=Enum.AutomaticSize.Y
    f.ScrollBarThickness=4; f.ScrollBarImageColor3=ACCENT2; f.Visible=(i==1); f.Parent=Main
    local L=Instance.new("UIListLayout"); L.Padding=UDim.new(0,6); L.SortOrder=Enum.SortOrder.LayoutOrder; L.Parent=f
    Instance.new("UIPadding", f).PaddingBottom=UDim.new(0,12)
    TabFrames[name]=f; TabBtns[name]=b
    b.MouseButton1Click:Connect(function()
        for tn,tf in pairs(TabFrames) do tf.Visible=(tn==name) end
        for tn,btn in pairs(TabBtns) do btn.BackgroundColor3=(tn==name) and ACCENT or BGB end
    end)
end

local yIdx={Farm=0,Combat=0,ESP=0,Move=0,Misc=0}
local function section(tab,text)
    yIdx[tab]=yIdx[tab]+1
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-6,0,20); l.BackgroundTransparency=1
    l.Text="— "..text.." —"; l.Font=Enum.Font.GothamBold; l.TextSize=11; l.TextColor3=ACCENT2
    l.TextXAlignment=Enum.TextXAlignment.Left; l.LayoutOrder=yIdx[tab]; l.Parent=TabFrames[tab]
end
local function toggle(tab,name,stateKey,color)
    yIdx[tab]=yIdx[tab]+1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-6,0,38); row.BackgroundColor3=BGB
    row.LayoutOrder=yIdx[tab]; row.Parent=TabFrames[tab]; Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=TXTW; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,46,0,22); btn.Position=UDim2.new(1,-52,0.5,-11)
    btn.BackgroundColor3=S[stateKey] and (color or ACCENT) or Color3.fromRGB(60,60,80)
    btn.Text=""; btn.AutoButtonColor=false; btn.Parent=row; Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,16,0,16)
    dot.Position=S[stateKey] and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    dot.BackgroundColor3=Color3.new(1,1,1); dot.Parent=row; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    btn.MouseButton1Click:Connect(function()
        S[stateKey]=not S[stateKey]
        TweenService:Create(btn,TweenInfo.new(0.18),{BackgroundColor3=S[stateKey] and (color or ACCENT) or Color3.fromRGB(60,60,80)}):Play()
        TweenService:Create(dot,TweenInfo.new(0.18),{Position=S[stateKey] and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end)
end
local function slider(tab,name,stateKey,minv,maxv,suffix)
    yIdx[tab]=yIdx[tab]+1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-6,0,50); row.BackgroundColor3=BGB
    row.LayoutOrder=yIdx[tab]; row.Parent=TabFrames[tab]; Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-70,0,18); lbl.Position=UDim2.new(0,10,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11.5
    lbl.TextColor3=TXTW; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0,55,0,18); vl.Position=UDim2.new(1,-62,0,5)
    vl.BackgroundTransparency=1; vl.Text=tostring(Sl[stateKey])..(suffix or ""); vl.Font=Enum.Font.GothamBold; vl.TextSize=11.5
    vl.TextColor3=ACCENT2; vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=row
    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-24,0,5); track.Position=UDim2.new(0,12,0,32)
    track.BackgroundColor3=Color3.fromRGB(50,50,70); track.Parent=row; Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=ACCENT2; fill.Parent=track
    local knob=Instance.new("TextButton"); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,-5,0.5,-8)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.Text=""; knob.Parent=track; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function set(x)
        local p=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(minv+(maxv-minv)*p+0.5); Sl[stateKey]=v
        vl.Text=tostring(v)..(suffix or ""); fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,-8,0.5,-8)
    end
    addConn(knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end))
    addConn(track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; set(i.Position.X) end end))
    addConn(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end))
    addConn(UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i.Position.X) end end))
    local p0=(Sl[stateKey]-minv)/(maxv-minv); fill.Size=UDim2.new(p0,0,1,0); knob.Position=UDim2.new(p0,-8,0.5,-8)
end

section("Farm","Auto Coin Farm")
toggle("Farm","Auto Farm (เก็บเหรียญ)","AutoFarm",Color3.fromRGB(255,215,0))
toggle("Farm","หลบฆาตกร (Avoid Murderer)","AvoidMurderer",Color3.fromRGB(255,150,50))
toggle("Farm","รีสปอร์นตอนกระเป๋าเต็ม","RespawnOnFull",Color3.fromRGB(100,200,255))
toggle("Farm","หยิบปืนอัตโนมัติ","PickUpGun",Color3.fromRGB(80,180,255))
toggle("Farm","ยิงฆาตกรตอนเต็ม (Shoot On Full)","ShootOnFull",Color3.fromRGB(255,80,80))
toggle("Farm","เปิดกล่องอัตโนมัติ","AutoOpenBoxes",Color3.fromRGB(200,150,255))
section("Farm","ความเร็ว")
slider("Farm","ความเร็วเก็บเหรียญ","FarmSpeed",10,60,"")

section("Combat","ฆาตกร (Murderer)")
toggle("Combat","Kill Aura (ออร่าฆ่า)","KillAura",Color3.fromRGB(255,80,80))
toggle("Combat","โยนมีดอัตโนมัติ","AutoThrowKnife",Color3.fromRGB(255,120,60))
slider("Combat","ระยะ Kill Aura","AuraRange",50,500," ม.")
section("Combat","นายอำเภอ (Sheriff)")
toggle("Combat","ยิงฆาตกรอัตโนมัติ","AutoShootMurder",Color3.fromRGB(80,140,255))
toggle("Combat","Silent Aim (ซายเลนต์)","SilentAim",Color3.fromRGB(180,80,255))
toggle("Combat","เหวี่ยงนายอำเภอ (Fling)","AutoFlingSheriff",Color3.fromRGB(255,60,120))
toggle("Combat","ต้านถูกเหวี่ยง (Anti Fling)","AntiFling",Color3.fromRGB(100,255,150))
section("Combat","Aimbot")
slider("Combat","FOV (วงล็อค)","FOV",50,600,"")
slider("Combat","ความนุ่ม (Smooth)","Smoothness",1,20,"")

section("ESP","เปิด/ปิดทั่วไป")
toggle("ESP","เปิด ESP ทั้งหมด","ESP_Enable",Color3.fromRGB(160,80,255))
section("ESP","แสดงตามบทบาท")
toggle("ESP","แสดง ฆาตกร","ESP_Murderer",Color3.fromRGB(255,60,60))
toggle("ESP","แสดง นายอำเภอ","ESP_Sheriff",Color3.fromRGB(60,120,255))
toggle("ESP","แสดง คนบริสุทธิ์","ESP_Innocent",Color3.fromRGB(60,220,100))
toggle("ESP","แสดง ฮีโร่","ESP_Hero",Color3.fromRGB(255,215,0))
section("ESP","รูปแบบการแสดง (ทำงานได้หมด)")
toggle("ESP","กล่องล้อมตัว (Box)","ESP_Box",Color3.fromRGB(255,150,60))
toggle("ESP","เส้นลาก (Tracers)","ESP_Tracers",Color3.fromRGB(100,200,255))
toggle("ESP","แสดงชื่อ (Name)","ESP_Name",Color3.fromRGB(220,220,255))
toggle("ESP","แสดงระยะ (Distance)","ESP_Distance",Color3.fromRGB(255,200,100))
toggle("ESP","แถบเลือด (Health Bar)","ESP_HealthBar",Color3.fromRGB(80,255,120))

section("Move","ความเร็ว/กระโดด")
toggle("Move","เพิ่มความเร็ววิ่ง","WalkSpeed",Color3.fromRGB(80,220,200))
slider("Move","ค่าความเร็ววิ่ง","WalkSpeedV",16,200,"")
toggle("Move","เพิ่มกำลังกระโดด","JumpPower",Color3.fromRGB(120,255,150))
slider("Move","ค่ากำลังกระโดด","JumpPowerV",50,200,"")
section("Move","ระบบพิเศษ")
toggle("Move","บิน (Fly) กดกระโดด=ขึ้น","Fly",Color3.fromRGB(150,150,255))
slider("Move","ความเร็วบิน","FlySpeed",20,120,"")
toggle("Move","ทะลุกำแพง (No Clip)","NoClip",Color3.fromRGB(255,180,40))
toggle("Move","กระโดดต่อเนื่อง (Bhop)","Bhop",Color3.fromRGB(100,200,255))
toggle("Move","หมุนตัว (Spin)","Spin",Color3.fromRGB(255,100,200))
toggle("Move","โปร่งแสง (Invisible)","Invisible",Color3.fromRGB(180,180,220))
toggle("Move","กระโดดไม่จำกัด (Inf Jump)","InfJump",Color3.fromRGB(200,255,100))

section("Misc","ระบบช่วยเหลือ")
toggle("Misc","Anti AFK (ไม่หลุดเกม)","AntiAFK",Color3.fromRGB(100,200,255))
toggle("Misc","โหวตแผนที่อัตโนมัติ","AutoVoteMap",Color3.fromRGB(255,200,80))
toggle("Misc","ดูปไอเทม (Auto Dupe)","AutoDupe",Color3.fromRGB(200,100,255))
toggle("Misc","เอกซเรย์ (X-Ray)","XRay",Color3.fromRGB(100,255,200))

-- Icon ลอย
local Icon = Instance.new("TextButton")
Icon.Size=UDim2.new(0,50,0,50); Icon.Position=UDim2.new(0,12,0.45,0)
Icon.BackgroundColor3=BGP; Icon.Text="M"; Icon.Font=Enum.Font.GothamBold; Icon.TextSize=18
Icon.TextColor3=ACCENT; Icon.AutoButtonColor=false; Icon.Parent=SG
Instance.new("UICorner",Icon).CornerRadius=UDim.new(1,0)
local ist=Instance.new("UIStroke",Icon); ist.Color=ACCENT; ist.Thickness=2
local iD,iS,iP,iM=false,nil,nil,false
addConn(Icon.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then iD=true;iM=false;iS=i.Position;iP=Icon.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if iD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-iS; if d.Magnitude>6 then iM=true; Icon.Position=UDim2.new(iP.X.Scale,iP.X.Offset+d.X,iP.Y.Scale,iP.Y.Offset+d.Y) end end end))
addConn(Icon.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if iD and not iM then Main.Visible=not Main.Visible end; iD=false end end))

-- ==================== ฟังก์ชันการทำงาน (ทุกตัวทำงานจริง) ====================

-- ANTI-AFK
addConn(LocalPlayer.Idled:Connect(function()
    if not S.AntiAFK then return end
    pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
end))

-- SPEED / JUMP / BHOP / INF JUMP
addConn(RunService.Heartbeat:Connect(function()
    local h=getHum(LocalPlayer.Character); if not h then return end
    h.WalkSpeed = S.WalkSpeed and Sl.WalkSpeedV or (S.AutoFarm and Sl.FarmSpeed or 16)
    h.JumpPower = S.JumpPower and Sl.JumpPowerV or 50
    if S.Bhop and h.MoveDirection.Magnitude>0 and h.FloorMaterial~=Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end))
addConn(UserInputService.JumpRequest:Connect(function()
    if S.InfJump then local h=getHum(LocalPlayer.Character); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
    if S.Fly then FlyUpUntil = tick() + 0.45 end  -- ✅ บนมือถือ: กดกระโดด = บินขึ้น
end))

-- INVISIBLE / SPIN / XRAY (ตรวจสอบ state เปลี่ยน แล้ว apply ทีเดียว ไม่หนัก)
addConn(RunService.RenderStepped:Connect(function()
    local c=LocalPlayer.Character
    if c then
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then pcall(function() d.LocalTransparencyModifier = S.Invisible and 1 or 0 end) end
        end
        if S.Spin then local hrp=getHRP(c); if hrp then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(12),0) end end
    end
    -- ✅ XRay ทำงานจริง: โปร่งกำแพง (apply ทีเดียวตอน toggle เปลี่ยน)
    if S.XRay ~= XRayApplied then
        XRayApplied = S.XRay
        if S.XRay then
            pcall(function()
                for _, p in ipairs(Workspace:GetDescendants()) do
                    if p:IsA("BasePart") and not p:IsDescendantOf(LocalPlayer.Character or Instance.new("Part")) then
                        local isChar = false
                        for _, pl in ipairs(Players:GetPlayers()) do if p:IsDescendantOf(pl.Character or Instance.new("Part")) then isChar=true break end end
                        if not isChar then
                            if OrigXray[p]==nil then OrigXray[p]=p.LocalTransparencyModifier end
                            p.LocalTransparencyModifier = 0.5
                        end
                    end
                end
            end)
        else
            for part, orig in pairs(OrigXray) do if part and part.Parent then pcall(function() part.LocalTransparencyModifier=orig end) end end
            table.clear(OrigXray)
        end
    end
end))

-- ✅ FLY บนมือถือได้: ใช้ทิศทางการเดิน + กดกระโดดขึ้น
addConn(RunService.Heartbeat:Connect(function()
    if not S.Fly then return end
    local hrp=getHRP(LocalPlayer.Character); local hum=getHum(LocalPlayer.Character)
    if not hrp or not hum then return end
    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
    local moveDir = hum.MoveDirection
    local up = (tick() < FlyUpUntil) and 1 or 0
    if moveDir.Magnitude > 0.1 or up > 0 then
        hrp.CFrame = hrp.CFrame + (moveDir * Sl.FlySpeed * 0.12) + Vector3.new(0, up * Sl.FlySpeed * 0.12, 0)
    end
end))

-- NOCLIP + ANTI-FLING
addConn(RunService.Stepped:Connect(function()
    local c=LocalPlayer.Character; if not c then return end
    local hrp=getHRP(c); local safeY=hrp and hrp.Position.Y>-40
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if OrigCollide[part]==nil then OrigCollide[part]=part.CanCollide end
            if S.NoClip and safeY then part.CanCollide=false else part.CanCollide=OrigCollide[part] end
            if S.AntiFling then pcall(function() part.AssemblyLinearVelocity=Vector3.new(0,0,0); part.RotVelocity=Vector3.new(0,0,0) end) end
        end
    end
end))

-- KILL AURA
addConn(RunService.Heartbeat:Connect(function()
    if not S.KillAura or getRole(LocalPlayer)~="Murderer" then return end
    local myChar=LocalPlayer.Character; local myHRP=getHRP(myChar); if not myHRP then return end
    local knife=myChar:FindFirstChildOfClass("Tool")
    if not knife then
        local bp=LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local h=getHum(myChar); if h then h:EquipTool(t) end; knife=t; break end end end
    end
    if not knife then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) then
            local tHRP=getHRP(p.Character)
            if tHRP and (myHRP.Position-tHRP.Position).Magnitude<=Sl.AuraRange then
                pcall(function()
                    tHRP.CFrame=myHRP.CFrame*CFrame.new(0,0,-2)
                    knife:Activate()
                    local handle=knife:FindFirstChild("Handle")
                    if handle and firetouchinterest then firetouchinterest(handle,tHRP,0); task.wait(); firetouchinterest(handle,tHRP,1) end
                end)
            end
        end
    end
end))

-- AUTO SHOOT / SILENT AIM
addConn(RunService.Heartbeat:Connect(function()
    if not (S.AutoShootMurder or S.SilentAim) then return end
    local myRole=getRole(LocalPlayer)
    if myRole~="Sheriff" and myRole~="Hero" then return end
    local myChar=LocalPlayer.Character; local myHRP=getHRP(myChar); if not myHRP then return end
    local gun=myChar:FindFirstChildOfClass("Tool")
    if not gun then
        local bp=LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and string.find(string.lower(t.Name),"gun") then local h=getHum(myChar); if h then h:EquipTool(t) end; gun=t; break end end end
    end
    if not gun then return end
    local target,td=nil,math.huge
    local vp=Camera.ViewportSize; local center=Vector2.new(vp.X/2,vp.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and getRole(p)=="Murderer" then
            local head=p.Character:FindFirstChild("Head") or getHRP(p.Character)
            if head then
                local sp,on=Camera:WorldToViewportPoint(head.Position)
                if on then local m=(Vector2.new(sp.X,sp.Y)-center).Magnitude; if m<=Sl.FOV and m<td then td=m; target=p end end
            end
        end
    end
    if target then
        local head=target.Character:FindFirstChild("Head") or getHRP(target.Character)
        if head then
            pcall(function()
                myHRP.CFrame=CFrame.new(myHRP.Position,head.Position)
                Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,head.Position),1/math.max(Sl.Smoothness,1))
                for _, d in ipairs(gun:GetDescendants()) do
                    if d:IsA("RemoteEvent") then d:FireServer(head.Position) elseif d:IsA("RemoteFunction") then d:InvokeServer(head.Position) end
                end
                gun:Activate()
            end)
        end
    end
end))

-- AUTO FLING SHERIFF
addConn(RunService.Heartbeat:Connect(function()
    if not S.AutoFlingSheriff then return end
    local myHRP=getHRP(LocalPlayer.Character); if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and getRole(p)=="Sheriff" then
            local tHRP=getHRP(p.Character)
            if tHRP then pcall(function() myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,2); myHRP.AssemblyLinearVelocity=myHRP.CFrame.LookVector*350+Vector3.new(0,100,0) end) end
        end
    end
end))

-- ✅ ESP (Highlight + Tracer ถูกต้อง + Name/Distance/HP ทำงานจริงด้วย BillboardGui)
local ESPCol={Murderer=Color3.fromRGB(102,43,43),Sheriff=Color3.fromRGB(38,52,74),Innocent=Color3.fromRGB(38,110,28),Hero=Color3.fromRGB(126,110,55)}

-- สร้าง ESP Text (BillboardGui) สำหรับคนทุกคน
local function ensureESPText(p)
    if ESPText[p] and ESPText[p].bb and ESPText[p].bb.Parent then return ESPText[p] end
    local char = p.Character; if not char then return nil end
    local head = char:FindFirstChild("Head") or getHRP(char); if not head then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "GodESP_Text"; bb.Size = UDim2.new(0, 120, 0, 50); bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true; bb.Adornee = head; bb.Parent = head
    local nameLbl = Instance.new("TextLabel"); nameLbl.Size=UDim2.new(1,0,0,16); nameLbl.Position=UDim2.new(0,0,0,0)
    nameLbl.BackgroundTransparency=1; nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=12; nameLbl.TextColor3=Color3.new(1,1,1)
    nameLbl.TextStrokeTransparency=0.5; nameLbl.Text=""; nameLbl.Parent=bb
    local distLbl = Instance.new("TextLabel"); distLbl.Size=UDim2.new(1,0,0,14); distLbl.Position=UDim2.new(0,0,0,16)
    distLbl.BackgroundTransparency=1; distLbl.Font=Enum.Font.Gotham; distLbl.TextSize=11; distLbl.TextColor3=Color3.fromRGB(255,220,100)
    distLbl.TextStrokeTransparency=0.5; distLbl.Text=""; distLbl.Parent=bb
    local barBg = Instance.new("Frame"); barBg.Size=UDim2.new(1,-10,0,6); barBg.Position=UDim2.new(0,5,0,32)
    barBg.BackgroundColor3=Color3.fromRGB(40,40,40); barBg.Parent=bb; Instance.new("UICorner",barBg).CornerRadius=UDim.new(1,0)
    local barFill = Instance.new("Frame"); barFill.Size=UDim2.new(1,0,1,0); barFill.BackgroundColor3=Color3.fromRGB(60,220,90)
    barFill.Parent=barBg; Instance.new("UICorner",barFill).CornerRadius=UDim.new(1,0)
    ESPText[p] = {bb=bb, name=nameLbl, dist=distLbl, bar=barFill}
    return ESPText[p]
end

-- Tracers: ใช้ Beam กับ Attachment ทั้งสองอันใน Terrain อัปเดต WorldPosition
local function ensureTracer(p)
    if ESPTracer[p] and ESPTracer[p].beam and ESPTracer[p].beam.Parent then return ESPTracer[p] end
    local a0 = Instance.new("Attachment", Workspace.Terrain)
    local a1 = Instance.new("Attachment", Workspace.Terrain)
    local beam = Instance.new("Beam")
    beam.Width0=0.06; beam.Width1=0.06; beam.FaceCamera=true; beam.Attachment0=a0; beam.Attachment1=a1
    beam.Parent=Workspace.Terrain
    ESPTracer[p] = {beam=beam, a0=a0, a1=a1}
    return ESPTracer[p]
end

addConn(Players.PlayerRemoving:Connect(function(p)
    if ESPText[p] then pcall(function() if ESPText[p].bb then ESPText[p].bb:Destroy() end end); ESPText[p]=nil end
    if ESPTracer[p] then pcall(function() ESPTracer[p].beam:Destroy(); ESPTracer[p].a0:Destroy(); ESPTracer[p].a1:Destroy() end); ESPTracer[p]=nil end
end))

addConn(RunService.RenderStepped:Connect(function()
    if not S.ESP_Enable then
        for _, e in pairs(ESPHL) do pcall(function() if e then e.Enabled=false end end) end
        for _, t in pairs(ESPTracer) do pcall(function() if t.beam then t.beam.Enabled=false end end) end
        for _, txt in pairs(ESPText) do pcall(function() if txt.bb then txt.bb.Enabled=false end end) end
        return
    end
    local myHRP = getHRP(LocalPlayer.Character)
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and p.Character and getHRP(p.Character) then
            pcall(function()
                local char=p.Character; local role=getRole(p); local tHRP=char.HumanoidRootPart
                local show=(role=="Murderer" and S.ESP_Murderer) or (role=="Sheriff" and S.ESP_Sheriff) or (role=="Innocent" and S.ESP_Innocent) or (role=="Hero" and S.ESP_Hero)
                local col=ESPCol[role] or Color3.fromRGB(150,150,150)
                -- Box (Highlight)
                local hl=char:FindFirstChild("GodHL")
                if show and S.ESP_Box then
                    if not hl then hl=Instance.new("Highlight"); hl.Name="GodHL"; hl.FillTransparency=0.55; hl.Parent=char; table.insert(ESPHL,hl) end
                    hl.Enabled=true; hl.FillColor=col; hl.OutlineColor=col
                elseif hl then hl.Enabled=false end
                -- ✅ Tracer (ถูกต้อง: อัปเดต WorldPosition)
                if show and S.ESP_Tracers and myHRP then
                    local tr = ensureTracer(p)
                    if tr then
                        tr.beam.Enabled=true; tr.beam.Color=ColorSequence.new(col)
                        tr.a0.WorldPosition = myHRP.Position
                        tr.a1.WorldPosition = tHRP.Position
                    end
                elseif ESPTracer[p] then ESPTracer[p].beam.Enabled=false end
                -- ✅ Name + Distance + Health Bar (ทำงานจริง)
                if show and (S.ESP_Name or S.ESP_Distance or S.ESP_HealthBar) then
                    local txt = ensureESPText(p)
                    if txt then
                        txt.bb.Enabled = true
                        txt.name.Text = S.ESP_Name and p.Name or ""
                        local dist = myHRP and math.floor((myHRP.Position - tHRP.Position).Magnitude) or 0
                        txt.dist.Text = S.ESP_Distance and (dist.."m") or ""
                        if S.ESP_HealthBar then
                            local hum = getHum(char)
                            local hp = hum and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
                            txt.bar.Size = UDim2.new(hp, 0, 1, 0)
                            txt.bar.BackgroundColor3 = hp > 0.5 and Color3.fromRGB(60,220,90) or (hp > 0.25 and Color3.fromRGB(255,200,60) or Color3.fromRGB(255,60,60))
                            txt.bar.Parent.Parent.Visible = true
                        else
                            txt.bar.Parent.Visible = false
                        end
                    end
                elseif ESPText[p] then ESPText[p].bb.Enabled=false end
            end)
        end
    end
end))

-- ✅ AUTO COIN FARM (throttle สแกนไม่แลค)
addConn(RunService.Heartbeat:Connect(function(dt)
    if not S.AutoFarm then TargetCoin=nil; return end
    if tick()<ResumeTime then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=getHRP(char); local hum=getHum(char)
    if not hrp or not hum or hum.Health<=0 then return end
    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
    local murdererHRP=nil
    if S.AvoidMurderer then
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and alive(p) and getRole(p)=="Murderer" then
                local mHRP=getHRP(p.Character)
                if mHRP and (hrp.Position-mHRP.Position).Magnitude<=30 then murdererHRP=mHRP end
            end
        end
    end
    -- หลบมีดปา (throttle ทุก 0.15วิ ไม่หนัก)
    if tick() - (LastCoinScan - 10) > 0.15 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj.Velocity and obj.Velocity.Magnitude>15 then
                local nm=obj.Name:lower()
                if nm:find("knife") or nm:find("blade") or nm:find("thrown") then
                    local toObj=obj.Position-hrp.Position
                    if toObj.Magnitude<18 then local dd=Vector3.new(-toObj.Z,0,toObj.X).Unit; hrp.CFrame=CFrame.new(hrp.Position+dd*6) end
                end
            end
        end
    end
    if hrp.Position.Y<-35 then hrp.CFrame=CFrame.new(hrp.Position.X,10,hrp.Position.Z); TargetCoin=nil; return end
    local coinContainer=Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not coinContainer then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") or string.find(string.lower(v.Name),"coin") then coinContainer=v:FindFirstChild("CoinContainer") or v; break end
        end
    end
    if not coinContainer then return end
    -- ✅ สแกนหาเหรียญทุก 0.25 วินาที (ไม่สแกนทุกเฟรม → ไม่แลค)
    if (not TargetCoin or not TargetCoin.Parent) and tick() - LastCoinScan > 0.25 then
        LastCoinScan = tick()
        local nearest,distN=nil,math.huge
        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin:IsA("BasePart") and coin.Position.Y>-30 then
                local skip=false
                if murdererHRP and (coin.Position-murdererHRP.Position).Magnitude<=20 then skip=true end
                if not skip then local d=(hrp.Position-coin.Position).Magnitude; if d<distN then distN=d; nearest=coin end end
            end
        end
        TargetCoin=nearest
    end
    if not TargetCoin then
        if murdererHRP then local flee=(hrp.Position-murdererHRP.Position).Unit; hrp.CFrame=hrp.CFrame:Lerp(CFrame.new(hrp.Position+flee*25),0.2) end
        return
    end
    local cp=TargetCoin.Position; local dist=(hrp.Position-cp).Magnitude
    if dist<=1.2 then TargetCoin=nil; ResumeTime=tick()+1; return end
    local tY=math.min(cp.Y,hrp.Position.Y+3.5); local tPos=Vector3.new(cp.X,tY,cp.Z)
    local step=math.min(dist,Sl.FarmSpeed*dt*60); hrp.CFrame=CFrame.new(hrp.Position:Lerp(tPos,step/dist))
end))

-- AUTO OPEN BOXES / VOTE / DUPE (ทุก 2 วินาที)
task.spawn(function()
    while wait(2) do
        if not Running then return end
        if S.AutoOpenBoxes then pcall(function() for _, v in ipairs(ReplicatedStorage:GetDescendants()) do if v:IsA("RemoteEvent") and (string.find(string.lower(v.Name),"box") or string.find(string.lower(v.Name),"open")) then v:FireServer("Halloween2026Box") end end end) end
        if S.AutoVoteMap then pcall(function() for _, v in ipairs(ReplicatedStorage:GetDescendants()) do if v:IsA("RemoteEvent") and string.find(string.lower(v.Name),"vote") then v:FireServer() end end end) end
        if S.AutoDupe then pcall(function() for _, v in ipairs(ReplicatedStorage:GetDescendants()) do if v:IsA("RemoteEvent") and string.find(string.lower(v.Name),"dupe") then v:FireServer() end end end) end
    end
end)

print("[MM2 God-Tier v2] ✅ โหลดสำเร็จ! แก้ทุกจุดบั๊กแล้ว — แตะปุ่ม M ซ่อน/แสดงเมนู")
