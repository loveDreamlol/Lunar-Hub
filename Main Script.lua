local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RunConnection = nil

local FriendsList = {}

local AimBotSettings = {
	Smart = false,
	Target = nil,
	DistanceLimit = false,
	MaxDistance = 500
}

Rayfield:Notify({
	Title = "The key is accepted",
	Content = "Access is open",
	Duration = 6.5,
	Image = "rewind",
})

local function DeleteCircle()
	local CircleGui = localPlayer.PlayerGui:FindFirstChild("RedCircleGui")
	if CircleGui then
		CircleGui:Destroy()
	end
end

local function CreateCircle()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RedCircleGui"
	screenGui.Parent = localPlayer.PlayerGui
	screenGui.Enabled = true

-- Фрейм-круг
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1          -- заливка полностью прозрачна
	frame.AnchorPoint = Vector2.new(0.5, 0.5) -- точка привязки в центре
	frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- строго центр экрана
	frame.Size = UDim2.new(0, 200, 0, 200)    -- стартовый диаметр (2 * 100)
	frame.Parent = screenGui

-- Делаем круг (радиус = половина ширины)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 100)    -- 200 / 2
	corner.Parent = frame

-- Красная обводка (контур)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 0, 0)
	stroke.Thickness = 3
	stroke.Parent = frame
end

local function getClosestTarget()
	local closest, minDist = nil, math.huge
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local targetPos = player.Character.HumanoidRootPart.Position
			local toTarget = (targetPos - origin)
			local angle = math.acos(direction:Dot(toTarget.Unit))

			if angle < math.rad(15) then
				local dist = toTarget.Magnitude
				if dist < minDist then
					closest = player.Character:FindFirstChild(AimBotSettings[2])
					minDist = dist
				end
			end
		end
	end

	if closest and closest.Parent:FindFirstChild("Humanoid").Health > 0 then
		print("Locked onto:", closest:GetFullName())
	else
		print("No valid target in view.")
	end

	return closest
end

local function isVisible(targetPosition, targetCharacter)
	local cameraPos = camera.CFrame.Position
	local direction = (targetPosition - cameraPos)
	local distance = direction.Magnitude
	if distance == 0 then
		return true
	end

	local rayOrigin = cameraPos
	local rayDirection = direction.Unit * distance

	local ignoreList = {}
	if localPlayer.Character then
		table.insert(ignoreList, localPlayer.Character)
	end
	if targetCharacter then
		table.insert(ignoreList, targetCharacter)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = ignoreList

	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	return result == nil
end

local function ApplyPlayerEsp(targetPlayer)
	local targetCharacter = targetPlayer.Character
	if not targetCharacter then return end

	local targethum = targetCharacter:FindFirstChild("Humanoid")
	if not targethum then return end

	for _, part in pairs(targetCharacter:GetChildren()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESPBox") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESPBox"
			box.Size = part.Size
			box.Adornee = part
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.5
			box.Parent = part

			if table.find(FriendsList, targetPlayer.Name) then
				box.Color3 = Color3.new(0, 1, 0)
			else
				box.Color3 = Color3.new(1, 0, 0)
			end
		end
	end
end

local function DeleteEsp()
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if not targetPlayer.Character then continue end

		for _, part in pairs(targetPlayer.Character:GetChildren()) do
			if part:IsA("BasePart") then
				local e = part:FindFirstChild("ESPBox")
				if e then
					e:Destroy()
				end
			end
		end
	end
end

local function animateCircleSize(diameter)
	local CircleGui = localPlayer.PlayerGui:FindFirstChild("RedCircleGui")
	if not CircleGui then return end
	
	diameter = math.floor(diameter)

	local tweenInfo = TweenInfo.new(
		0.3,                              -- длительность анимации
		Enum.EasingStyle.Quad,            -- плавное ускорение/замедление
		Enum.EasingDirection.Out
	)

	local goal = {
		Size = UDim2.new(0, diameter, 0, diameter)
	}

	local tween = TweenService:Create(CircleGui.Frame, tweenInfo, goal)

	-- Во время анимации непрерывно обновляем радиус, чтобы круг оставался идеально круглым
	local connection
	connection = CircleGui.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local currentWidth = CircleGui.Frame.AbsoluteSize.X
		CircleGui.Frame.UICorner.CornerRadius = UDim.new(0, currentWidth / 2)
	end)

	-- Когда анимация закончится, отключаем слушатель и на всякий случай фиксируем точный радиус
	tween.Completed:Connect(function()
		connection:Disconnect()
		CircleGui.Frame.UICorner.CornerRadius = UDim.new(0, diameter / 2)
	end)
	
	tween:Play()
end

local Window = Rayfield:CreateWindow({
	Name = "Lunar Hub",
	Icon = 76407560622795, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
	LoadingTitle = "Lunar Hub",
	LoadingSubtitle = "by love_Dream",
	ShowText = "Lunar Hub", -- for mobile users to unhide Rayfield, change if you'd like
	Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

	-- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Lunar", -- Create a custom folder for your hub/game
		FileName = "Lunar Hub"
	},

	Discord = {
		Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
		Invite = "https://discord.gg/2XhkvhK9", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
		RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
	},

	KeySystem = false, -- Set this to true to use our key system
	KeySettings = {
		Title = "Key",
		Subtitle = "Key System",
		Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
		FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
		Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
	}
})

local Main = Window:CreateTab("Main", "rewind")
local Esp = Window:CreateTab("Esp", "rewind")
local Speed = Window:CreateTab("Speed", "rewind")
local Friends = Window:CreateTab("Friends", "rewind")
local Settings = Window:CreateTab("Settings", "rewind")

local AimBot = Main:CreateToggle({
	Name = "AimBot",
	CurrentValue = false,
	Flag = "Toggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		if RunConnection then
			RunConnection:Disconnect()
			RunConnection = nil
		end

		if Value then
			RunConnection = RunService.RenderStepped:Connect(function()
				local target = getClosestTarget()
				if target and target.Parent.Humanoid.Health > 0 and not table.find(FriendsList, Players:GetPlayerFromCharacter(target.Parent).Name) and (not AimBotSettings[1] or isVisible(target.Position, target.Parent)) and (not AimBotSettings[3] or (localPlayer.Character:FindFirstChild("HumanoidRootPart").Position - target.Parent:FindFirstChild("HumanoidRootPart").Position).Magnitude <= AimBotSettings[4]) then	
					camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)

					local trace = Instance.new("Beam")
					local attachment0 = Instance.new("Attachment")
					local attachment1 = Instance.new("Attachment")

					attachment0.WorldPosition = camera.CFrame.Position
					attachment1.WorldPosition = target.Position

					attachment0.Parent = workspace.Terrain
					attachment1.Parent = workspace.Terrain

					trace.Attachment0 = attachment0
					trace.Attachment1 = attachment1
					trace.Color = ColorSequence.new(Color3.new(1, 0, 0))
					trace.Width0 = 0.1
					trace.Width1 = 0.1
					trace.FaceCamera = true
					trace.LightInfluence = 0
					trace.Transparency = NumberSequence.new(1)
					trace.Parent = workspace.Terrain

					task.delay(0.1, function()
						attachment0:Destroy()
						attachment1:Destroy()
						trace:Destroy()
					end)
				end
				task.wait()
			end)
		end
	end,
})

local Circle = Main:CreateToggle({
	Name = "Circle",
	CurrentValue = false,
	Flag = "Toggle6", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		if Value then
			CreateCircle()
		else
			DeleteCircle()
		end
	end,
})

local CircleSize = Main:CreateSlider({
	Name = "Circle Size",
	Range = {1, 10},
	Increment = 0.1,
	Suffix = "Size",
	CurrentValue = 2,
	Flag = "Slider1",
	Callback = function(Value)
		local newDiameter = Value * 100
		animateCircleSize(newDiameter)
	end,
})

local Esp_Players = Esp:CreateToggle({
	Name = "Esp Players",
	CurrentValue = false,
	Flag = "Toggle2", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		if Value then
			Esp = true
			for _, targetPlayer in pairs(Players:GetPlayers()) do
				if targetPlayer.Name == localPlayer.Name or not targetPlayer.Character then continue end
				ApplyPlayerEsp(targetPlayer)
			end
		else
			Esp = false
			DeleteEsp()
		end
	end,
})

local Esp_Health = Esp:CreateToggle({
	Name = "Esp Health",
	CurrentValue = false,
	Flag = "Toggle3", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		if Value then
			for _, targetPlayer in pairs(Players:GetPlayers()) do
				if targetPlayer.Name == localPlayer.Name then continue end

				local targetCharacter = targetPlayer.Character
				if not targetCharacter then continue end

				local targethum = targetCharacter:FindFirstChild("Humanoid")
				if not targethum then continue end

				if not targetCharacter:FindFirstChild("EspHealthLabel") then
					local BillboardGui = Instance.new("BillboardGui", targetCharacter:FindFirstChild("Head"))
					BillboardGui.Name = "EspHealthLabel"
					BillboardGui.Active = true
					BillboardGui.AlwaysOnTop = true
					BillboardGui.ClipsDescendants = true
					BillboardGui.DistanceStep = 0
					BillboardGui.Enabled = true
					BillboardGui.ExtentsOffset = Vector3.new(0, 0, 0)
					BillboardGui.LightInfluence = 0
					BillboardGui.MaxDistance = 500
					BillboardGui.ResetOnSpawn = false
					BillboardGui.Size = UDim2.new(5, 0, 2, 0)
					BillboardGui.SizeOffset = Vector2.new(0, 0)
					BillboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
					BillboardGui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
					BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

					local BillboardGui_TextLabel = Instance.new("TextLabel")
					BillboardGui_TextLabel.Name = "TextLabel"
					BillboardGui_TextLabel.Size = UDim2.new(1, 0, 1, 0)
					BillboardGui_TextLabel.Position = UDim2.new(0, 0, 0, 0)
					BillboardGui_TextLabel.AnchorPoint = Vector2.new(0, 0)
					BillboardGui_TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
					BillboardGui_TextLabel.BackgroundTransparency = 1
					BillboardGui_TextLabel.BorderColor3 = Color3.new(0.10588236153125763, 0.16470588743686676, 0.20784315466880798)
					BillboardGui_TextLabel.BorderSizePixel = 0
					BillboardGui_TextLabel.Visible = true
					BillboardGui_TextLabel.Rotation = 0
					BillboardGui_TextLabel.ZIndex = 1
					BillboardGui_TextLabel.Text = "100"
					BillboardGui_TextLabel.TextColor3 = Color3.new(0.3333333432674408, 1, 0)
					BillboardGui_TextLabel.TextSize = 58
					BillboardGui_TextLabel.Font = Enum.Font.SourceSansSemibold
					BillboardGui_TextLabel.TextTransparency = 0
					BillboardGui_TextLabel.TextWrapped = true
					BillboardGui_TextLabel.TextXAlignment = Enum.TextXAlignment.Center
					BillboardGui_TextLabel.TextYAlignment = Enum.TextYAlignment.Center
					BillboardGui_TextLabel.TextScaled = true
					BillboardGui_TextLabel.RichText = false
					BillboardGui_TextLabel.LineHeight = 1
					BillboardGui_TextLabel.Parent = BillboardGui

					task.spawn(function()
						targethum.Changed:Connect(function()
							BillboardGui_TextLabel.Text = math.floor(targethum.Health)
							if targethum.Health > (targethum.MaxHealth / 2) then
								BillboardGui_TextLabel.TextColor3 = Color3.new(0.333333, 1, 0)
							elseif targethum.Health <= (targethum.MaxHealth / 4) then
								BillboardGui_TextLabel.TextColor3 = Color3.new(1, 0, 0)
							else
								BillboardGui_TextLabel.TextColor3 = Color3.new(1, 1, 0)
							end
						end)
					end)
				end
			end
		else
			for _, targetPlayer in pairs(Players:GetPlayers()) do
				if not targetPlayer.Character then continue end

				local EspHealth = targetPlayer.Character:FindFirstChild("EspHealthLabel")
				if EspHealth then
					EspHealth:Destroy()
				end
			end
		end
	end,
})

local Player_Speed = Speed:CreateSlider({
	Name = "Speed",
	Range = {16, 300},
	Increment = 1,
	Suffix = "Speed",
	CurrentValue = 16,
	Flag = "Slider1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		while localPlayer.Character:FindFirstChild("Humanoid") do
			localPlayer.Character.Humanoid.WalkSpeed = Value
			task.wait()
		end
	end,
})

local Player_Jump = Speed:CreateSlider({
	Name = "Jump",
	Range = {50, 300},
	Increment = 1,
	Suffix = "Jump",
	CurrentValue = 20,
	Flag = "Slider2", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		while localPlayer.Character:FindFirstChild("Humanoid") do
			localPlayer.Character.Humanoid.JumpPower = Value
			task.wait()
		end
	end,
})

local Player_Friends = Friends:CreateDropdown({
	Name = "Friends",
	Options = {},
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Dropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Options)
		for _, Name in pairs(Options) do
			local targetPlayer = Players:FindFirstChild(Name)
			if not targetPlayer then continue end

			if not table.find(FriendsList, Name) then
				table.insert(FriendsList, Name)
			end
		end
	end,
})

local RefreshFriends = Friends:CreateButton({
	Name = "Refresh",
	Callback = function()
		FriendsList = {}
		local PlayersList = {}

		for _, targetPlayer in pairs(Players:GetPlayers()) do
			if targetPlayer.Name == localPlayer.Name or not targetPlayer.Character then continue end

			table.insert(PlayersList, targetPlayer.Name)
		end
		Player_Friends:Refresh(PlayersList)
		Player_Friends:Set({})
	end,
})

local SmartAimBot = Settings:CreateToggle({
	Name = "Smart AimBot (ignores the players who are behind the wall)",
	CurrentValue = false,
	Flag = "Toggle3", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		AimBotSettings[1] = Value
	end,
})

local AimBotTarget = Settings:CreateDropdown({
	Name = "AimBot Target",
	Options = {},
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "Dropdown5", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Options)
		AimBotSettings[2] = Options[1]
	end,
})

local PartsList = {}

for _, part in pairs(localPlayer.Character:GetChildren()) do
	if part:IsA("BasePart") then
		table.insert(PartsList, part.Name)
	end
end

AimBotTarget:Refresh(PartsList)
AimBotTarget:Set({"HumanoidRootPart"})

local AimBotDistanceLimit = Settings:CreateToggle({
	Name = "AimBot Distance Limit",
	CurrentValue = false,
	Flag = "Toggle6", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		if Value then
			AimBotSettings[3] = true
		else
			AimBotSettings[3] = false
		end
	end,
})

local MaxAimBotDistance = Settings:CreateSlider({
	Name = "AimBot Max Distance",
	Range = {10, 1000},
	Increment = 10,
	Suffix = "Distance",
	CurrentValue = 500,
	Flag = "Slider5", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		AimBotSettings[4] = Value
	end,
})
