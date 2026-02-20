-- [[ ZONHUB - MANAGER MODULE (INJECTED) ]] --
local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "Manager v1.1" 

-- ========================================= --
getgenv().DropDelay = 2     
getgenv().StepDelay = 0.1   
getgenv().GridSize = 4.5 
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser") 

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

getgenv().AutoCollect = false; getgenv().AutoDrop = false; getgenv().DropAmount = 50; getgenv().TargetPosX = 0; getgenv().TargetPosY = 0

local function ManageUIState(Mode)
    local PG = LP:FindFirstChild("PlayerGui")
    if not PG then return end
    if Mode == "Normal" then
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = true end end end end
        local RestoredUI = {"GemsUI", "TopbarCentered", "TopbarCenteredClipped", "TopbarStandard", "TopbarStandardClipped", "ExperienceChat"}
        for _, name in pairs(RestoredUI) do local ui = PG:FindFirstChild(name); if ui and ui:IsA("ScreenGui") then ui.Enabled = true end end
    elseif Mode == "Dropping" then
        if PlayerMovement then PlayerMovement.InputActive = true end
        if PG:FindFirstChild("TouchGui") then PG.TouchGui.Enabled = true end
        if PG:FindFirstChild("InventoryUI") then PG.InventoryUI.Enabled = true end
        if PG:FindFirstChild("ExperienceChat") then PG.ExperienceChat.Enabled = true end
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end end end
    end
end

local function FindInventoryModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindInventoryModule()

local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

function CreateToggle(Parent, Text, Var, OnToggle) local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false; local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Btn; local T = Instance.new("TextLabel"); T.Parent = Btn; T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame"); IndBg.Parent = Btn; IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(1,0); IC.Parent = IndBg; local Dot = Instance.new("Frame"); Dot.Parent = IndBg; Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(1,0); DC.Parent = Dot; Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end if OnToggle then OnToggle(getgenv()[Var]) end end) end
function CreateSlider(Parent, Text, Min, Max, Default, Var) local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 45); local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Frame; local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text .. ": " .. Default; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 20); Label.Position = UDim2.new(0, 10, 0, 2); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local SliderBg = Instance.new("TextButton"); SliderBg.Parent = Frame; SliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SliderBg.Position = UDim2.new(0, 10, 0, 28); SliderBg.Size = UDim2.new(1, -20, 0, 6); SliderBg.Text = ""; SliderBg.AutoButtonColor = false; local SC = Instance.new("UICorner"); SC.CornerRadius = UDim.new(1,0); SC.Parent = SliderBg; local Fill = Instance.new("Frame"); Fill.Parent = SliderBg; Fill.BackgroundColor3 = Theme.Purple; Fill.Size = UDim2.new(0.5, 0, 1, 0); local FC = Instance.new("UICorner"); FC.CornerRadius = UDim.new(1,0); FC.Parent = Fill; local Dragging = false; local function Update(input) local SizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1); local Val = math.floor(Min + ((Max - Min) * SizeX)); Fill.Size = UDim2.new(SizeX, 0, 1, 0); Label.Text = Text .. ": " .. Val; getgenv()[Var] = Val end; SliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = true; Update(i) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = false end end); UIS.InputChanged:Connect(function(i) if Dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Update(i) end end) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Frame; local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox"); InputBox.Parent = Frame; InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 4); IC.Parent = InputBox; InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Btn; Btn.MouseButton1Click:Connect(Callback) end

-- Inject elemen ke TargetPage dari Index
CreateToggle(TargetPage, "Enable Auto Collect", "AutoCollect")
local BoxX = CreateTextBox(TargetPage, "Target Grid X", 0, "TargetPosX")
local BoxY = CreateTextBox(TargetPage, "Target Grid Y", 0, "TargetPosY")
CreateButton(TargetPage, "Save Pos (Current Loc)", function()
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local RefPart = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if RefPart then
        local currX = math.floor(RefPart.Position.X / getgenv().GridSize + 0.5)
        local currY = math.floor(RefPart.Position.Y / getgenv().GridSize + 0.5)
        getgenv().TargetPosX = currX; getgenv().TargetPosY = currY
        BoxX.Text = tostring(currX); BoxY.Text = tostring(currY)
    end
end)

CreateToggle(TargetPage, "Auto Drop", "AutoDrop", function(state) if not state then ManageUIState("Normal") end end)
CreateSlider(TargetPage, "Drop Amount", 1, 200, 50, "DropAmount")

-- Logic Mesin (Sama seperti sebelumnya)
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 

RunService.RenderStepped:Connect(function() if getgenv().AutoDrop then ManageUIState("Dropping") end end)

task.spawn(function() while true do if getgenv().AutoDrop then local Amt = getgenv().DropAmount; pcall(function() if getgenv().GameInventoryModule then local _, slot; if getgenv().GameInventoryModule.GetSelectedHotbarItem then _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() elseif getgenv().GameInventoryModule.GetSelectedItem then _, slot = getgenv().GameInventoryModule.GetSelectedItem() end; if slot then RemoteDropSafe:FireServer(slot, Amt) end end end); pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(Amt) } }})) end) end; task.wait(getgenv().DropDelay) end end)
task.spawn(function() while true do if getgenv().AutoCollect then local HitboxFolder = workspace:FindFirstChild("Hitbox"); local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name); if MyHitbox then local startZ = MyHitbox.Position.Z; local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5); local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5); local homeX = currentX; local homeY = currentY; local targetX = getgenv().TargetPosX; local targetY = getgenv().TargetPosY; if currentX ~= targetX or currentY ~= targetY then local function WalkGrid(tX, tY) while (currentX ~= tX or currentY ~= tY) and getgenv().AutoCollect do if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1) elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end; local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ); MyHitbox.CFrame = CFrame.new(newWorldPos); if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end; task.wait(getgenv().StepDelay) end end; WalkGrid(targetX, targetY); task.wait(0.6); WalkGrid(homeX, homeY) end end end; task.wait(2) end end)
