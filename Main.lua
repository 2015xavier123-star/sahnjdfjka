print("[Aether] starting...")
local v4 = Vector3.new(math.huge, math.huge, math.huge)
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local generalChannel = nil
pcall(function()
	local channels = TextChatService:FindFirstChild("TextChannels") or TextChatService:WaitForChild("TextChannels", 3)
	if channels then
		generalChannel = channels:FindFirstChild("RBXGeneral") or channels:WaitForChild("RBXGeneral", 2)
	end
end)
local function autoSendChat(messageText)
	pcall(function()
		if generalChannel then generalChannel:SendAsync(tostring(messageText)) end
	end)
end

local OrionLib
do
	local ok, res = pcall(function()
		return loadstring(game:HttpGet("https://codeberg.org/Tr4c3rz/abyssalhubFTAP/raw/branch/main/orionX"))()
	end)
	if not ok or type(res) ~= "table" then
		warn("[Aether] Orion failed:", res)
		return
	end
	OrionLib = res
end
autoSendChat("Aether 4.5 by AI_simp")

print("[Aether] Orion loaded")

local function GetOwner(t)
    if not t then return 0 end

    local targetModel = t:IsA("Model") and t or t:FindFirstAncestorOfClass("Model")

    if not targetModel and t:IsA("BasePart") then
        targetModel = t.Parent
    end

    if targetModel then
        local partOwner = targetModel:FindFirstChild("PartOwner", true)
        if partOwner and partOwner:IsA("StringValue") then
            return partOwner.Value
        end
    end

    return 0
end

local function attemptowner_move(m, targpos, targvelo, targavelo, targ)
    local grab = game.ReplicatedStorage.GrabEvents.SetNetworkOwner
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    local t = false
    if hrp and targ and (hrp.Position - targ:GetPivot().Position).Magnitude >= 20 then
        t = true
    end

    if GetOwner(targ) ~= lp.Name then
        local origp
        if t then
            origp = hrp.CFrame
            hrp.CFrame = targ:GetPivot()
            task.wait(0.1)
        end

        local targetModel = targ:IsA("Model") and targ or targ:FindFirstAncestorOfClass("Model")
        local partOwner = targetModel and targetModel:FindFirstChild("PartOwner", true)
        local safetyCounter = 0

        repeat
            grab:FireServer(targ, targ:GetPivot())

            if t and hrp and hrp.Parent and safetyCounter % 2 == 0 then
                hrp.CFrame = origp
            end

            task.wait(0.03)
            safetyCounter = safetyCounter + 1

            if safetyCounter > 40 or not targ or not targ.Parent then break end
        until (partOwner and partOwner.Value == lp.Name) or GetOwner(targ) == lp.Name

        if t and hrp and hrp.Parent and origp then
            hrp.CFrame = origp
        end
    end


-- Anti-Kick System State Definitions (Ported from XOCU Engine)
local AntiKickItemActive = false
local MyPCLD = nil
local pcldConn = nil
local SelectedToy = "InstrumentGuitarViolin" -- Fallback replication toy configuration

local function FWD(parent, part, timeOffset)
    return parent:FindFirstChild(part) or parent:WaitForChild(part, timeOffset or 1)
end

local function CheckNetworkOwnerOnPart(Part) 
    local po = Part:FindFirstChild("PartOwner")
    return po and po.Value == Players.LocalPlayer.Name
end

local function sno(part)
    pcall(function()
        local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
        local setNetOwner = grabEvents and grabEvents:FindFirstChild("SetNetworkOwner")
        if setNetOwner then
            setNetOwner:FireServer(part, part.CFrame)
        end
    end)
end

local function CheckForHome()
    local plotItems = workspace:FindFirstChild("PlotItems")
    local plots = workspace:FindFirstChild("Plots")
    if plots and plotItems then
        for i = 1, 5 do 
            local Plot = plots:FindFirstChild("Plot"..i)
            if Plot then
                local sign = Plot:FindFirstChild("PlotSign")
                local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                if owners then
                    for _,v in pairs(owners:GetChildren()) do 
                        if v.Value == Players.LocalPlayer.Name then 
                            return plotItems:FindFirstChild("Plot"..i)
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function SpawnToy(ToyName)
    local InPlot = Players.LocalPlayer:FindFirstChild("InPlot")
    local InOwnedPlot = Players.LocalPlayer:FindFirstChild("InOwnedPlot")
    local CanSpawnToy = Players.LocalPlayer:FindFirstChild("CanSpawnToy")
    local inv = workspace:FindFirstChild(Players.LocalPlayer.Name.."SpawnedInToys")

    if InPlot and InPlot.Value and InOwnedPlot and not InOwnedPlot.Value then 
        InPlot:GetPropertyChangedSignal("Value"):Wait()
    end 
    if CanSpawnToy and not CanSpawnToy.Value then 
        CanSpawnToy:GetPropertyChangedSignal("Value"):Wait()
    end

    local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local SpawnCF = (MyPCLD or hrp).CFrame * CFrame.new(0, 14, 20)
    local Container = (InOwnedPlot and InOwnedPlot.Value) and CheckForHome() or inv
    if not Container then return nil end

    local spawnedObject = nil
    local connection
    connection = Container.ChildAdded:Connect(function(child)
        if child.Name == ToyName then
            spawnedObject = child
        end
    end)

    task.spawn(function()
        pcall(function()
            local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
            local spawnRemote = menuToys and menuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote then
                spawnRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
            end
        end)
    end)

    local start = tick()
    repeat task.wait() until spawnedObject or (tick() - start) > 2.5

    if connection then connection:Disconnect() end
    return spawnedObject
end

local function FindPCLD(hrp)
    if pcldConn then pcldConn:Disconnect() end
    MyPCLD = nil
    pcldConn = RunService.Heartbeat:Connect(function()
        if MyPCLD or not hrp or not hrp.Parent then 
            if pcldConn then pcldConn:Disconnect() pcldConn = nil end
            return
        end
        for _, v in pairs(workspace:GetChildren()) do 
            if v.Name == "PlayerCharacterLocationDetector" and v:IsA("BasePart") then
                if (v.Position - hrp.Position).Magnitude <= 2 then 
                    MyPCLD = v
                    break
                end
            end
        end
    end)
end

-- Respawn watchdog listeners for alignment persistence
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    if AntiKickItemActive then
        MyPCLD = nil
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then FindPCLD(hrp) end
    end
end)


      
    if m and targ and targ.Parent then
        if GetOwner(targ) == lp.Name then
            targ:PivotTo(targpos)
            targ.AssemblyLinearVelocity = targvelo
            targ.AssemblyAngularVelocity = targavelo
        end
    end
end

local function attemptdestroypart(v1)
    local v = Vector3.new(math.huge, math.huge, math.huge)
    attemptowner_move(true, CFrame.new(0, -140, 0), v, v, v1)
end

OrionLib.Themes["AetherGalaxy"] = {
    Main = Color3.fromRGB(15, 12, 28),
    Second = Color3.fromRGB(24, 20, 43),
    Stroke = Color3.fromRGB(142, 68, 173),
    Divider = Color3.fromRGB(0, 210, 255),
    Text = Color3.fromRGB(240, 240, 255),
    TextDark = Color3.fromRGB(130, 120, 150)
}
OrionLib.SelectedTheme = "AetherGalaxy"

local function AetherPart1()

local variants = {
	"BlackHoleKick", "BlackHoleDetected", "BlackHole", "Black_Hole", "Blackhole",
	"Black-Hole", "BHole", "BH", "VoidHole", "Void", "VoidSphere", "DarkHole",
	"DarkSphere", "DarkOrb", "GravityHole", "GravityOrb", "SpaceHole", "SpaceOrb",
	"Singularity", "SingularityOrb", "EventHorizon", "BlackSphere", "Anomaly",
	"AnomalyHole", "SupermassiveHole", "QuantumHole",
}

OrionLib:MakeNotification({
    Name = "Kick Detector",
    Content = "Detector is now active and monitoring.",
    Image = "rbxassetid://4483345998",
    Time = 3
})

local variantSet = {}
for _, n in ipairs(variants) do
	variantSet[n] = true
end

local function playKickSound()

end

local function notifyKick(displayName, username)
	print("[KickDetect]", displayName .. " (" .. username .. ") has been kicked")
	OrionLib:MakeNotification({
		Name = "Player Kicked!",
		Content = displayName .. " (@" .. username .. ") was detected getting kicked.",
		Image = "rbxassetid://4483345998",
		Time = 5
	})
end

local function getClosestPlayer(pos)
	local closestPlr = nil
	local closestDist = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - pos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlr = plr
				end
			end
		end
	end
	return closestPlr
end

local function onKickObject(obj)
	task.wait(0.05)
	local pos
	if obj:IsA("BasePart") then
		pos = obj.Position
	elseif obj:IsA("Model") and obj.PrimaryPart then
		pos = obj.PrimaryPart.Position
	else
		local p = obj:FindFirstChildWhichIsA("BasePart", true)
		if p then pos = p.Position end
	end
	if not pos then return end
	local plr = getClosestPlayer(pos)
	if not plr then return end
	playKickSound()
	notifyKick(plr.DisplayName, plr.Name)
end

Workspace.ChildAdded:Connect(function(obj)
	if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" or variantSet[obj.Name] then
		onKickObject(obj)
	end
end)

print("kicking loaded")

local Settings = {
	BlobmanBeta = {
		ignores = false,
		kickMethod = "Kick Double Hands",
		currentSide = "Left",
		selectedTarget = nil,
		unsafeBlobman = false,
		FloatAmount = 16,
		KickDelay = 0.18,
		driftKickActive = false,
		kickAllV2Active = false,
		destroyGucciActive = false,
		ignoreHeights = {526.377685546875, 5.2832231521606445},
		currentGucciType = "CreatureBlobman", -- <--- ADD THIS LINE TO PREVENT THE NIL INDEX
	},
	Loop = {
		Whitelists = false,
	},
	Protects = false,
	KickAllV1 = false,
	AntiExplosion = false,
	AntiKillHamburger = false,
	AntiBlobmanKill = false,
	BarrierNoclip = false,
	FloatAmount = 16,
	currentSide = "Left",
}


local State = {
	allPCLDParts = nil,
	pcldWatcherConn = nil,
	driftKickConn = nil,
	driftKickLoopId = nil,
	kickAllV2Conn = nil,
}

local grabEventsFolder = ReplicatedStorage:WaitForChild("GrabEvents")
local setNetworkOwnerEvent = grabEventsFolder:WaitForChild("SetNetworkOwner")
local destroyGrabLineEvent = grabEventsFolder:WaitForChild("DestroyGrabLine")
local menuToysFolder = ReplicatedStorage:WaitForChild("MenuToys")
local SpawnToyRF = menuToysFolder:WaitForChild("SpawnToyRemoteFunction")
local DeleteToyRE = menuToysFolder:WaitForChild("DestroyToy")

local function isProtectedPlayer(name)
	return false
end

local BlobmanBetaFeature = {}

function BlobmanBetaFeature.getLocalHum()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function BlobmanBetaFeature.getLocalRoot()
	local char = LocalPlayer.Character
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

function BlobmanBetaFeature.getInv()
	return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

function BlobmanBetaFeature.SetNetworkOwner(part)
	pcall(function() setNetworkOwnerEvent:FireServer(part, BlobmanBetaFeature.getLocalRoot().CFrame) end)
end

function BlobmanBetaFeature.ungrab(part)
	pcall(function() destroyGrabLineEvent:FireServer(part) end)
end

function BlobmanBetaFeature.getBlobman()
	local hum = BlobmanBetaFeature.getLocalHum()
	if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
		if hum.SeatPart.Parent.Name == "CreatureBlobman" then
			return hum.SeatPart.Parent
		end
	end
	local inv = BlobmanBetaFeature.getInv()
	if inv then
		local v = inv:FindFirstChild("CreatureBlobman")
		if v and v.ClassName == "Model" and v:FindFirstChild("VehicleSeat") then return v end
	end
	return nil
end

function BlobmanBetaFeature.findAnyBlobman()
	if not Settings.BlobmanBeta.unsafeBlobman then return nil end
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	local closest, closestDist = nil, math.huge
	local function checkFolder(folder)
		if not folder then return end
		for _, obj in ipairs(folder:GetChildren()) do
			if obj.Name == "CreatureBlobman" and obj:IsA("Model") then
				local seat = obj:FindFirstChild("VehicleSeat")
				if seat then
					local dist = myRoot and (obj:GetPivot().Position - myRoot.Position).Magnitude or 0
					if dist < closestDist then
						closestDist = dist
						closest = obj
					end
				end
			end
		end
	end
	checkFolder(BlobmanBetaFeature.getInv())
	if not closest then
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == "CreatureBlobman" and obj:IsA("Model") then
				local seat = obj:FindFirstChild("VehicleSeat")
				if seat then
					local dist = myRoot and (obj:GetPivot().Position - myRoot.Position).Magnitude or 0
					if dist < 100000 and dist < closestDist then
						closestDist = dist
						closest = obj
					end
				end
			end
		end
	end
	return closest
end

function BlobmanBetaFeature.spawnBlobman()
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	if not myRoot then return nil end
	local existing = BlobmanBetaFeature.getBlobman()
	if existing then return existing end
	local anyBlob = BlobmanBetaFeature.findAnyBlobman()
	if anyBlob and anyBlob:FindFirstChild("VehicleSeat") then return anyBlob end

	local inv = BlobmanBetaFeature.getInv()
	local SpawnedToy = nil
	if inv then
		local conn
		conn = inv.ChildAdded:Connect(function(toy)
			if toy.Name == "CreatureBlobman" and toy:IsA("Model") then
				SpawnedToy = toy
				conn:Disconnect()
			end
		end)
		task.spawn(function()
			pcall(function()
				SpawnToyRF:InvokeServer("CreatureBlobman", myRoot.CFrame * CFrame.new(3, 0, 0), Vector3.zero)
			end)
		end)
		local t = tick()
		while not SpawnedToy do
			if tick() - t > 2 then conn:Disconnect() break end
			task.wait(0.01)
		end
	end
	if SpawnedToy then
		SpawnedToy:WaitForChild("VehicleSeat", 2)
		return SpawnedToy
	end
	return BlobmanBetaFeature.getBlobman()
end

function BlobmanBetaFeature.ensureBlob()
	local blob = BlobmanBetaFeature.getBlobman() or BlobmanBetaFeature.findAnyBlobman() or BlobmanBetaFeature.spawnBlobman()
	if not blob or not blob:FindFirstChild("VehicleSeat") then return nil end
	local hum = BlobmanBetaFeature.getLocalHum()
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	if hum and myRoot and not hum.Sit then
		myRoot.CFrame = blob.VehicleSeat.CFrame + Vector3.new(0, 2, 0)
		blob.VehicleSeat:Sit(hum)
	end
	return blob
end

function BlobmanBetaFeature.blobGrab(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	local weld = detector and detector:FindFirstChild(side .. "Weld")
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	local remote = script and script:FindFirstChild("CreatureGrab")
	if remote then pcall(function() remote:FireServer(detector, target, weld) end) end
end

_G.Window = nil

do
	local ok, err = pcall(function()
		_G.Window = OrionLib:MakeWindow({
			Name = "Aether 4.2",
			HidePremium = false,
			SaveConfig = true,
			ConfigFolder = "OrionTest"
		})
	end)
	if not ok then warn("[Aether] MakeWindow:", err) end
end
if not _G.Window then
	warn("[Aether] Window nil")
	return
end
print("[Aether] Window OK")
local Kicks = _G.Window:MakeTab({Name = "Blobman", Icon = "", PremiumOnly = false})
local ConfigTab = _G.Window:MakeTab({Name = "Settings", Icon = "", PremiumOnly = false})

function BlobmanBetaFeature.blobDrop(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	local remote = script and script:FindFirstChild("CreatureDrop")
	if remote then pcall(function() remote:FireServer(detector, target) end) end
end

function BlobmanBetaFeature.blobKick(blob, target, side)
	if not blob or not target then return end
	BlobmanBetaFeature.blobGrab(blob, BlobmanBetaFeature.getLocalRoot(), side)
	task.wait(0.02)
	BlobmanBetaFeature.SetNetworkOwner(target)
	task.wait(0.02)
	target.CFrame = target.CFrame + Vector3.new(0, Settings.BlobmanBeta.FloatAmount, 0)
	task.wait(0.02)
	BlobmanBetaFeature.ungrab(target)
	task.wait(0.02)
	BlobmanBetaFeature.blobGrab(blob, target, side)
	task.wait(0.02)
	BlobmanBetaFeature.blobDrop(blob, target, side)
	task.wait(0.02)
	BlobmanBetaFeature.ungrab(target)
end

function BlobmanBetaFeature.GetPlayerList()
	local list = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not isProtectedPlayer(plr.Name) then
			table.insert(list, plr.DisplayName .. " @" .. plr.Name)
		end
	end
	return list
end

function BlobmanBetaFeature.checkTarget()
	if not Settings.BlobmanBeta.selectedTarget then return nil end
	local target = Players:FindFirstChild(Settings.BlobmanBeta.selectedTarget)
	if not target or isProtectedPlayer(Settings.BlobmanBeta.selectedTarget) then return nil end
	return target
end

local driftAngle = 0
function BlobmanBetaFeature.startDriftKick(targetName)
	driftAngle = 0
	Settings.BlobmanBeta.driftKickActive = true
	local myLoopId = tick()
	State.driftKickLoopId = myLoopId
	local driftSkipCounter = 0

	if State.driftKickConn then task.cancel(State.driftKickConn) end
	State.driftKickConn = task.spawn(function()
		local target = Players:FindFirstChild(targetName)
		if not target or target == LocalPlayer then Settings.BlobmanBeta.driftKickActive = false return end
		local blob = BlobmanBetaFeature.ensureBlob()
		if not blob then Settings.BlobmanBeta.driftKickActive = false return end

		local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript") or blob:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
		local grabRemote = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
		local dropRemote = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
		local Det = blob:FindFirstChild("RightDetector") or blob:FindFirstChild("LeftDetector")
		local Weld = Det and (Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld"))
		local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
		local blobRoot = blob.PrimaryPart or blob:FindFirstChild("HumanoidRootPart")

		if not GE or not grabRemote or not dropRemote or not Det or not Weld or not blobRoot then
			Settings.BlobmanBeta.driftKickActive = false return
		end

		while Settings.BlobmanBeta.driftKickActive do
			if myLoopId ~= State.driftKickLoopId then break end
			local tChar = target.Character
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

			if tChar and tRoot and tHum and tHum.Health > 0 then
				local bringStart = tick()
				while tick() - bringStart < 0.35 do
					if myLoopId ~= State.driftKickLoopId or not Settings.BlobmanBeta.driftKickActive then break end
					blobRoot.CFrame = tRoot.CFrame
					pcall(function()
						grabRemote:FireServer(Det, tRoot, Weld)
						if driftSkipCounter % 3 == 0 then
							GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
						end
					end)
					driftSkipCounter = (driftSkipCounter + 1) % 3
					RunService.Heartbeat:Wait()
				end
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

function BlobmanBetaFeature.stopDriftKick()
	Settings.BlobmanBeta.driftKickActive = false
	if State.driftKickConn then task.cancel(State.driftKickConn) State.driftKickConn = nil end
end

function BlobmanBetaFeature.startKickAllV2()
	Settings.BlobmanBeta.kickAllV2Active = true
	task.spawn(function()
		local allPlayers2 = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and not isProtectedPlayer(p.Name) then
				if Settings.BlobmanBeta.ignores then
					local is = false
					pcall(function() is = LocalPlayer:IssWith(p.UserId) end)
					if is then continue end
				end
				local tChar = p.Character
				local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
				local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
				if tRoot and tHum and tHum.Health > 0 then
					table.insert(allPlayers2, p)
				end
			end
		end

		if #allPlayers2 == 0 then Settings.BlobmanBeta.kickAllV2Active = false return end
		local blob = BlobmanBetaFeature.ensureBlob()
		if not blob then Settings.BlobmanBeta.kickAllV2Active = false return end

		local MyBlob = blob
		local scr = MyBlob:FindFirstChild("BlobmanSeatAndOwnerScript") or MyBlob:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
		local CreatureGrab = scr and scr:FindFirstChild("CreatureGrab")
		local CreatureRelease = scr and scr:FindFirstChild("CreatureRelease")
		local myHRP = BlobmanBetaFeature.getLocalRoot()

		for _, targetPlayer in ipairs(allPlayers2) do
			local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot and myHRP then
				myHRP.CFrame = targetRoot.CFrame
				task.wait(0.02)
				for i = 1, 3 do
					pcall(function()
						CreatureGrab:FireServer(MyBlob.LeftDetector, targetRoot, MyBlob.LeftDetector.LeftWeld)
						CreatureRelease:FireServer(MyBlob.LeftDetector.LeftWeld)
					end)
					if i < 3 then task.wait(0.08) end
				end
			end
		end
		Settings.BlobmanBeta.kickAllV2Active = false
	end)
end

function BlobmanBetaFeature.destroyPlayerGucci(targetPlayer)
	if not targetPlayer or targetPlayer == LocalPlayer then return false end
	local folderName = targetPlayer.Name .. "SpawnedInToys"
	local toysFolder = Workspace:FindFirstChild(folderName)
	if not toysFolder then return false end
	local myChar = LocalPlayer.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHum or not myRoot then return false end
	for _, obj in ipairs(toysFolder:GetChildren()) do
		if obj.Name == "CreatureBlobman" or obj.Name == "TractorGreen" then
			local seat = obj:FindFirstChild("VehicleSeat") or obj:FindFirstChildWhichIsA("VehicleSeat", true)
			if seat then
				local safeSpot = myRoot.CFrame
				myRoot.CFrame = seat.CFrame
				myRoot.Velocity = Vector3.zero
				seat:Sit(myHum)
				task.wait(0.3)
				if myHum.SeatPart == seat then
					myHum.Sit = false
					task.wait(0.1)
					myRoot.CFrame = safeSpot
					task.wait(1)
					obj:Destroy()
					return true
				else
					myRoot.CFrame = safeSpot
				end
			end
		end
	end
	return false
end

function BlobmanBetaFeature.StartDestroyGucciLoop()
	while Settings.BlobmanBeta.destroyGucciActive do
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isProtectedPlayer(player.Name) and player.Character then
				BlobmanBetaFeature.destroyPlayerGucci(player)
			end
		end
		task.wait(2)
	end
end

local function parsePlayerName(displayStr)
	local atPos = string.find(displayStr, " @")
	return atPos and string.sub(displayStr, atPos + 2) or displayStr
end

Kicks:AddSection({Name = "Target Selection"})

local targetDropdown = Kicks:AddDropdown({
	Name = "Select Target",
	Default = "",
	Options = BlobmanBetaFeature.GetPlayerList(),
	Callback = function(Value)
		Settings.BlobmanBeta.selectedTarget = Value ~= "" and parsePlayerName(Value) or nil
	end
})

local function refreshDropdown()
	pcall(function()
		targetDropdown:Refresh(BlobmanBetaFeature.GetPlayerList(), true)
	end)
end
Players.PlayerAdded:Connect(refreshDropdown)
Players.PlayerRemoving:Connect(refreshDropdown)

Kicks:AddSection({Name = "Kick Operations"})

Kicks:AddDropdown({
	Name = "Kick Method",
	Default = "Kick Double Hands",
	Options = {"Kick Double Hands", "Kick Left", "Kick Right"},
	Callback = function(Value)
		Settings.BlobmanBeta.kickMethod = Value
		Settings.BlobmanBeta.currentSide = (Value == "Kick Right") and "Right" or "Left"
	end
})

Kicks:AddButton({
	Name = "Kick Target",
	Callback = function()
		local target = BlobmanBetaFeature.checkTarget()
		local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		local blob = BlobmanBetaFeature.ensureBlob()
		if not root or not blob then return end

		task.spawn(function()
			if Settings.BlobmanBeta.kickMethod == "Kick Double Hands" then
				BlobmanBetaFeature.blobKick(blob, root, "Left")
				task.wait(0.05)
				BlobmanBetaFeature.blobKick(blob, root, "Right")
			else
				BlobmanBetaFeature.blobKick(blob, root, Settings.BlobmanBeta.currentSide)
			end
		end)
	end
})

Kicks:AddToggle({
	Name = "Drift Kick",
	Default = false,
	Callback = function(Value)
		if Value then
			local target = BlobmanBetaFeature.checkTarget()
			if target then BlobmanBetaFeature.startDriftKick(target.Name) end
		else
			BlobmanBetaFeature.stopDriftKick()
		end
	end
})




Kicks:AddButton({
	Name = "Decimate Server",
	Callback = function()
		local lp = game:GetService("Players").LocalPlayer
		local char = lp.Character or lp.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart")
		local hum = char:WaitForChild("Humanoid")

		-- Retrieve map spawn anchor point defaults
		local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
		local spawnPosition = spawnLocation and spawnLocation.Position or Vector3.new(0, 0, 0)

		local originalPos = hrp.CFrame
		local validTargets = {}
		
		for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
			if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(validTargets, p)
			end
		end

		local targetCount = #validTargets
		if targetCount == 0 then return end

		-- 1. Acquisition Sequence: Teleport & Force Network Ownership (No attemptowner_move)
		local setNetOwner = game.ReplicatedStorage.GrabEvents.SetNetworkOwner
		for _, targetPlayer in ipairs(validTargets) do
			local tChar = targetPlayer.Character
			local target_hrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
			
			if target_hrp then
				-- Teleport directly onto the player
				hrp.CFrame = target_hrp.CFrame
				task.wait(0.1)

				-- Spam Network Ownership 300 times or until successfully acquired
				local ownershipCount = 0
				repeat
					setNetOwner:FireServer(target_hrp, target_hrp.CFrame)
					task.wait(0.01)
					ownershipCount = ownershipCount + 1
					if ownershipCount > 300 then break end
				until GetOwner(target_hrp) == lp.Name
			end
		end

		-- 2. Teleport All to Sky Circle Configuration
		local radius = 25
		local verticalHeight = 40
		local targetSkyNodes = {}

		for idx, targetPlayer in ipairs(validTargets) do
			local tChar = targetPlayer.Character
			local target_hrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
			
			if target_hrp and GetOwner(target_hrp) == lp.Name then
				local angle = (idx / targetCount) * (math.pi * 2)
				local circleOffset = Vector3.new(math.cos(angle) * radius, verticalHeight, math.sin(angle) * radius)
				local targetSkyCFrame = CFrame.new(spawnPosition + circleOffset)

				-- Lock player position in sky setup
				target_hrp.CFrame = targetSkyCFrame
				target_hrp.AssemblyLinearVelocity = Vector3.zero
				target_hrp.AssemblyAngularVelocity = Vector3.zero
				table.insert(targetSkyNodes, {part = target_hrp, cf = targetSkyCFrame, locked = true})
			end
		end

		-- Persistent Sky Position Engine Lock
		local skyLockConn
		skyLockConn = game:GetService("RunService").Heartbeat:Connect(function()
			for _, node in ipairs(targetSkyNodes) do
				if node.locked and node.part and node.part.Parent then
					node.part.CFrame = node.cf
					node.part.AssemblyLinearVelocity = Vector3.zero
					node.part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end)

		-- 3. Spawn and Mount Mountable Asset
		local blob = BlobmanBetaFeature.ensureBlob()
		task.wait(0.2)

		-- 4. Centralize User Setup and Lock to Circle Midpoint
		local centerSkyCFrame = CFrame.new(spawnPosition + Vector3.new(0, verticalHeight, 0))
		local userLockConn
		userLockConn = game:GetService("RunService").Heartbeat:Connect(function()
			if blob and blob.PrimaryPart then
				blob:PivotTo(centerSkyCFrame)
				blob.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
				blob.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
			end
			if hrp and hum.Sit and hum.SeatPart then
				hrp.CFrame = centerSkyCFrame
			end
		end)

		task.wait(0.5) -- Stability alignment step

		-- 5. Alternating Hand Execution Engine Sequence with Selective Unlocking
		for idx, node in ipairs(targetSkyNodes) do
			if node.part and node.part.Parent then
				-- UNLOCK TARGET: Disable the heartbeat freeze lock right before the hand grasp triggers
				node.locked = false 
				task.wait(0.02)

				-- Alternates execution hands based on sequence index (Odd = Left, Even = Right)
				local assignedSide = (idx % 2 == 1) and "Left" or "Right"
				
				pcall(function()
					BlobmanBetaFeature.blobKick(blob, node.part, assignedSide)
				end)
				task.wait(Settings.BlobmanBeta.KickDelay or 0.18)
			end
		end

		-- Cleanup pipeline layers
		if skyLockConn then skyLockConn:Disconnect() end
		if userLockConn then userLockConn:Disconnect() end

		OrionLib:MakeNotification({
			Name = "Decimation Complete",
			Content = "Server cleared using synchronized alternating hand components.",
			Image = "rbxassetid://4483345998",
			Time = 3
		})
	end
})





Kicks:AddButton({
	Name = "This is broke",
	Callback = function()
		local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

-- Fetch the raw pixel coordinate array over the internet
local url = "https://githubusercontent.com"
local success, response = pcall(function()
    return HttpService:GetAsync(url)
end)

if success then
    local badAppleVideoData = HttpService:JSONDecode(response)
    
    -- Playback execution loop (assuming ~30 FPS or standard step intervals)
    task.spawn(function()
        for frameIndex, frameMatrix in ipairs(badAppleVideoData) do
            -- frameMatrix is a dynamic array of coordinates matching your structure { {x, y, z}, {x, y, z} }
            RenderFrameEngine(frameMatrix)
            
            -- Keep track of your framerate delay 
            task.wait(1 / 30) 
        end
    end)
else
    warn("[Aether Engine Error] Failed to stream video frame data: " .. tostring(response))
end

	end
})













Kicks:AddToggle({
	Name = "Destroy Gucci",
	Default = false,
	Callback = function(Value)
		Settings.BlobmanBeta.destroyGucciActive = Value
		if Value then
			task.spawn(function()
				BlobmanBetaFeature.StartDestroyGucciLoop()
			end)
		end
	end
})

ConfigTab:AddToggle({
	Name = "Ignore s",
	Default = false,
	Callback = function(Value) Settings.BlobmanBeta.ignores = Value end
})

ConfigTab:AddToggle({
	Name = "Unsafe Blobman",
	Default = false,
	Callback = function(Value) Settings.BlobmanBeta.unsafeBlobman = Value end
})

ConfigTab:AddSlider({
	Name = "Float Amount",
	Min = 1, Max = 50, Default = 16, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "studs",
	Callback = function(Value) Settings.BlobmanBeta.FloatAmount = Value end
})

ConfigTab:AddSlider({
	Name = "Kick Delay",
	Min = 0.01, Max = 1, Default = 0.18, Color = Color3.fromRGB(255,255,255), Increment = 0.01, ValueName = "s",
	Callback = function(Value) Settings.BlobmanBeta.KickDelay = Value end
})

local TpWalkSpeed = 16

_G.SETTINGS_ANTI_GRAB = false
local GHOST_SPEED = 16
local SYNC_TIMEOUT = 0.8
local CLEANUP_DELAY = 0.5

local characterEventsFolder = ReplicatedStorage:WaitForChild("CharacterEvents", 30)
local setNetworkOwnerEvent = grabEventsFolder:WaitForChild("SetNetworkOwner", 5)
local destroyGrabLineEvent = grabEventsFolder:WaitForChild("DestroyGrabLine", 5)
local ragdollRemoteEvent = characterEventsFolder:WaitForChild("RagdollRemote", 5)
local struggleEvent = characterEventsFolder:WaitForChild("Struggle", 5)
local isHeldValue = LocalPlayer:WaitForChild("IsHeld", 30)

local currentVisualClone = nil
local renderConnection = nil
local escapeConnection = nil
local teleportSpamConnection = nil
local jumpConnection = nil
local cleanupThread = nil

local MasterControl = nil
pcall(function()
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
	MasterControl = PlayerModule:GetControls()
end)

local function stripPartVisibilityAndQuery(part)
	if part:IsA("BasePart") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
		part.CanQuery = false
		part.CastShadow = false
	elseif part:IsA("Decal") or part:IsA("Texture") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
	end
end

local function applyPermanentStealth(character)
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		stripPartVisibilityAndQuery(desc)
	end
	character.DescendantAdded:Connect(stripPartVisibilityAndQuery)
end

RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if character then
		for _, desc in ipairs(character:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then

				if _G.SETTINGS_ANTI_GRAB then
					desc.LocalTransparencyModifier = 1
					if desc:IsA("BasePart") then desc.CanQuery = false end
				else
					desc.LocalTransparencyModifier = 0
					if desc:IsA("BasePart") then desc.CanQuery = true end
				end
			end
		end
	end
	if currentVisualClone then
		for _, desc in ipairs(currentVisualClone:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				desc.LocalTransparencyModifier = 1
				if desc:IsA("BasePart") then desc.CanQuery = false end
			end
		end
	end
end)

local function setMobileJumpButtonEnabled(enabled)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if touchGui then
		local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
		if touchControlFrame then
			local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
			if jumpButton then
				jumpButton.Visible = enabled
				jumpButton.Active = enabled
			end
		end
	end
end

local function cleanupClone()
	if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
	if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
	if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end

	if currentVisualClone then
		currentVisualClone:Destroy()
		currentVisualClone = nil
	end

	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and camera then camera.CameraSubject = humanoid end
end

local function verifyAndSyncPosition(realHrp, targetCFrame, timeout)
	local startTime = os.clock()
	while (os.clock() - startTime) < timeout do
		if not realHrp or not realHrp.Parent then break end
		realHrp.Velocity = Vector3.zero
		realHrp.RotVelocity = Vector3.zero
		realHrp.CFrame = targetCFrame
		if (realHrp.Position - targetCFrame.Position).Magnitude < 0.5 then return true end
		task.wait()
	end
	return false
end

local function handleTerminationAndCleanup()
	if cleanupThread then task.cancel(cleanupThread) cleanupThread = nil end
	local character = LocalPlayer.Character
	local realHrp = character and character:FindFirstChild("HumanoidRootPart")

	if realHrp and currentVisualClone then
		local cloneHrp = currentVisualClone:FindFirstChild("HumanoidRootPart")
		if cloneHrp then
			if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
			if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
			verifyAndSyncPosition(realHrp, cloneHrp.CFrame, SYNC_TIMEOUT)
		end
	end

	cleanupThread = task.spawn(function()
		task.wait(CLEANUP_DELAY)
		cleanupClone()
		cleanupThread = nil
	end)
end

local function AttemptNetworkShip(part)
	if not part or not part.Parent then return false end
	local partOwner = part:FindFirstChild("PartOwner")
	if partOwner and partOwner.Value == LocalPlayer.Name then return true end
	for _ = 1, 5 do
		task.wait()
		local po = part:FindFirstChild("PartOwner")
		if po and po.Value == LocalPlayer.Name then return true end
	end
	return false
end

local function bindEscapeHooks(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	if not escapeConnection then
		escapeConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			hrp.AssemblyLinearVelocity = Vector3.zero
			if struggleEvent then pcall(function() struggleEvent:FireServer(LocalPlayer) end) end
			if ragdollRemoteEvent then pcall(function() ragdollRemoteEvent:FireServer(hrp, 0) end) end
		end)
	end

	if not teleportSpamConnection then
		teleportSpamConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			if currentVisualClone then
				local cloneHrpPart = currentVisualClone:FindFirstChild("HumanoidRootPart")
				if cloneHrpPart then
					hrp.Anchored = false
					if (hrp.Position - cloneHrpPart.Position).Magnitude > 0.02 then
						hrp.CFrame = cloneHrpPart.CFrame
					end
				end
			end
		end)
	end
end

local function createVisualClone(character)
	if cleanupThread and currentVisualClone then
		task.cancel(cleanupThread)
		cleanupThread = nil
		bindEscapeHooks(character)
		return
	end

	if currentVisualClone then cleanupClone() end
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false

	local cloneHrp = clone:FindFirstChild("HumanoidRootPart")
	local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	local realHrp = character:FindFirstChild("HumanoidRootPart")

	if cloneHrp and realHrp then
		cloneHrp.CFrame = realHrp.CFrame
		cloneHrp.AssemblyLinearVelocity = Vector3.zero
		cloneHrp.AssemblyAngularVelocity = Vector3.zero
	end

	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("Sound") then
			desc:Destroy()
		else
			stripPartVisibilityAndQuery(desc)
			if desc:IsA("BasePart") then
				desc.CanTouch = false
				desc.CanQuery = false
				desc.CanCollide = (desc == cloneHrp)
			end
		end
	end

	for _, realPart in ipairs(character:GetDescendants()) do
		if realPart:IsA("BasePart") then
			for _, ghostPart in ipairs(clone:GetDescendants()) do
				if ghostPart:IsA("BasePart") then
					local noCollide = Instance.new("NoCollisionConstraint")
					noCollide.Part0 = realPart
					noCollide.Part1 = ghostPart
					noCollide.Parent = ghostPart
				end
			end
		end
	end

	if cloneHumanoid then

		cloneHumanoid.WalkSpeed = TpWalkSpeed
		cloneHumanoid.AutoRotate = true
		cloneHumanoid.PlatformStand = false
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		cloneHumanoid:ChangeState(Enum.HumanoidStateType.Running)
	end

	clone.Parent = workspace
	currentVisualClone = clone

	local camera = workspace.CurrentCamera
	if cloneHumanoid and camera then camera.CameraSubject = cloneHumanoid end

	setMobileJumpButtonEnabled(true)

	jumpConnection = UserInputService.JumpRequest:Connect(function()
		if cloneHumanoid and cloneHumanoid.Health > 0 then
			cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	renderConnection = RunService.RenderStepped:Connect(function()
		if not cloneHrp or not cloneHumanoid then return end

		cloneHumanoid.WalkSpeed = TpWalkSpeed

		local rawMoveVector = Vector3.zero
		if MasterControl and MasterControl.GetMoveVector then rawMoveVector = MasterControl:GetMoveVector() end

		if MasterControl and MasterControl.GetActiveController then
			local activeCtrl = MasterControl:GetActiveController()
			if activeCtrl and (activeCtrl.IsJumping or (activeCtrl.GetIsJumping and activeCtrl:GetIsJumping())) then
				cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end

		if rawMoveVector.Magnitude > 0 then
			local cameraCFrame = camera.CFrame
			local forward = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
			local right = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit
			local worldMoveVector = (forward * -rawMoveVector.Z) + (right * rawMoveVector.X)
			if worldMoveVector.Magnitude > 0 then cloneHumanoid:Move(worldMoveVector.Unit, false) else cloneHumanoid:Move(Vector3.zero, false) end
		else
			cloneHumanoid:Move(Vector3.zero, false)
		end
	end)

	bindEscapeHooks(character)
end

local function setupPartOwnerListener(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	character.DescendantAdded:Connect(function(child)
		if not _G.SETTINGS_ANTI_GRAB then return end
		if not (child:IsA("StringValue") and child.Name == "PartOwner" and child.Value) then return end
		if child.Value == LocalPlayer.Name then return end

		local grabbedPart = child.Parent
		if not grabbedPart or not grabbedPart:IsA("BasePart") then return end

		AttemptNetworkShip(hrp)
		if destroyGrabLineEvent then pcall(function() destroyGrabLineEvent:FireServer(grabbedPart) end) end
	end)
end

local function onCharacterAdded(character)
	applyPermanentStealth(character)
	setupPartOwnerListener(character)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

isHeldValue.Changed:Connect(function(isBeingHeld)
	if isBeingHeld and _G.SETTINGS_ANTI_GRAB then
		local character = LocalPlayer.Character
		if character then createVisualClone(character) end
	else
		handleTerminationAndCleanup()
	end
end)

local camera = Workspace.CurrentCamera
local isCustomCameraEnabled = false
local renderConnectionCam = nil
local inputConnection = nil
local touchConnection = nil

local MIN_ZOOM = 0
local MAX_ZOOM = 100
local currentZoom = 20
local pitch = -15
local yaw = 0
local heightOffset = Vector3.new(0, 2, 0)

local function updateCamera()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end

	local targetPosition = humanoidRootPart.Position + heightOffset
	local cameraRotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
	local cameraPosition = targetPosition + cameraRotation * Vector3.new(0, 0, currentZoom)
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
end

local function setupMobileDragging()
	return UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isCustomCameraEnabled then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			local activeTouchId = input.Identifier
			local moveConnection
			local endedConnection
			local lastPosition = input.Position

			moveConnection = UserInputService.InputChanged:Connect(function(moveInput, moveProcessed)
				if not isCustomCameraEnabled then moveConnection:Disconnect() return end
				if moveInput.Identifier == activeTouchId and moveInput.UserInputType == Enum.UserInputType.Touch and moveInput.Position then
					local delta = moveInput.Position - lastPosition
					lastPosition = moveInput.Position
					yaw = yaw - (delta.X * 0.4)
					pitch = math.clamp(pitch - (delta.Y * 0.4), -75, 75)
				end
			end)

			endedConnection = UserInputService.InputEnded:Connect(function(endInput)
				if endInput.Identifier == activeTouchId then
					if moveConnection then moveConnection:Disconnect() end
					if endedConnection then endedConnection:Disconnect() end
				end
			end)
		end
	end)
end

local function setupZoomHandling()
	return UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed or not isCustomCameraEnabled then return end
		if input.UserInputType == Enum.UserInputType.Gesture then
			if input.Delta.Z ~= 0 then currentZoom = math.clamp(currentZoom - (input.Delta.Z * 5), MIN_ZOOM, MAX_ZOOM) end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			currentZoom = math.clamp(currentZoom - (input.Delta.Y * 2), MIN_ZOOM, MAX_ZOOM)
		end
	end)
end

local function toggleCustomCamera(enable)
	if enable == nil then enable = not isCustomCameraEnabled end
	isCustomCameraEnabled = enable

	if isCustomCameraEnabled then
		camera.CameraType = Enum.CameraType.Scriptable
		renderConnectionCam = RunService.RenderStepped:Connect(updateCamera)
		touchConnection = setupMobileDragging()
		inputConnection = setupZoomHandling()
		print("Custom camera system: ENABLED")
	else
		if renderConnectionCam then renderConnectionCam:Disconnect() end
		if touchConnection then touchConnection:Disconnect() end
		if inputConnection then inputConnection:Disconnect() end
		camera.CameraType = Enum.CameraType.Custom
    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		print("Custom camera system: DISABLED")
	end
end

LocalPlayer.Chatted:Connect(function(message)
	if message:lower() == "/toggle" then toggleCustomCamera() end
end)

local highlightEnabled = false
local function updateHighlights()
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:FindFirstChild("OwnershipHighlight") then part.OwnershipHighlight:Destroy() end
	end
	if not highlightEnabled then return end
	local Character = LocalPlayer.Character
	if not Character then return end

	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Character) then
			if part.ReceiveAge == 0 or (part:GetRootPart() and part:GetRootPart().ReceiveAge == 0) then
				local isPlayer = false
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character and part:IsDescendantOf(p.Character) then isPlayer = true break end
				end
				local highlight = Instance.new("SelectionBox")
				highlight.Name = "OwnershipHighlight"
				highlight.Adornee = part
				highlight.Color3 = isPlayer and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
				highlight.LineThickness = 0.05
				highlight.Parent = part
			end
		end
	end
end

_G.SetOwnershipHighlight = function(state)
	highlightEnabled = state
	updateHighlights()
end

task.spawn(function()
	while task.wait(0.5) do if highlightEnabled then updateHighlights() end end
end)

local scriptObj = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("CharacterAndBeamMove")
local function setAntiLag(on) if scriptObj then scriptObj.Disabled = on end end
setAntiLag(false)

LocalPlayer.CharacterAdded:Connect(function()
	task.defer(function()
		scriptObj = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("CharacterAndBeamMove")
		if scriptObj then scriptObj.Disabled = true end
	end)
end)

_G.Cam = _G.Cam or {}
_G.Cam.ThirdP = { Enabled = false, MinZoom = 0, MaxZoom = 100, Offset = Vector3.new(0, 2, 8) }

RunService.RenderStepped:Connect(function(deltaTime)
	local config = _G.Cam.ThirdP
	if not config or not config.Enabled then return end
	LocalPlayer.CameraMinZoomDistance = config.MinZoom
	LocalPlayer.CameraMaxZoomDistance = config.MaxZoom

	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		camera.CameraType = Enum.CameraType.Scriptable
		local zoomOffset = config.Offset
		local targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(camera.CFrame.Rotation.Y), 0) * CFrame.new(zoomOffset.X, zoomOffset.Y, zoomOffset.Z)
		camera.CFrame = CFrame.lookAt(targetCFrame.Position, rootPart.Position + Vector3.new(0, 2, 0))
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end)

local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
local CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
shared.LagSettings = { MonsterLagEnabled = false }
local maxRange = 9e9
local distanceModifier = 1.0

local function getSpawnLocation() return Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) end
local function getRandomOffset()
	local currentMax = maxRange * distanceModifier
	return ((math.random() * 2) - 1) * currentMax, ((math.random() * 2) - 1) * currentMax
end

task.spawn(function()
	while CreateLine do
		if shared.LagSettings.MonsterLagEnabled then
			local spawnLocation = getSpawnLocation()
			if spawnLocation then
				local offsetX, offsetZ = getRandomOffset()
				CreateLine:FireServer(spawnLocation, CFrame.new(offsetX, 0, offsetZ))
			end
		end
		task.wait()
	end
end)

local AntiGrabEnabled = false
local antiExplosionConnection = nil
local antiExplosionCharConn = nil

local function setupAntiExplosion(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not hrp then return end
	if antiExplosionConnection then antiExplosionConnection:Disconnect() end

	antiExplosionConnection = Workspace.ChildAdded:Connect(function(model)
		if not Settings.AntiExplosion then return end
		local char = LocalPlayer.Character
		local h = char and char:FindFirstChild("Humanoid")
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not h or not r then return end
		if model:IsA("BasePart") and (model.Position - r.Position).Magnitude <= 20 then
			if h.SeatPart ~= nil then
				r.Anchored = true task.wait(0.03) r.AssemblyLinearVelocity = Vector3.zero r.Anchored = false
			else
				r.Anchored = true task.wait() h:ChangeState(Enum.HumanoidStateType.Running) r.Anchored = false h.AutoRotate = true
			end
		end
	end)
end

local antiKillConnection = nil
local function enableAntiKill()
	if antiKillConnection then antiKillConnection:Disconnect() end
	local toggle = false
	local lastSpawnAttempt = 0
	antiKillConnection = RunService.Heartbeat:Connect(function()
		if not Settings.AntiKillHamburger then return end
		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return end
		local spawnedFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
		local hamburger = spawnedFolder and spawnedFolder:FindFirstChild("InstrumentGuitarViolin")
		if not hamburger or not hamburger:FindFirstChild("HoldPart") then
			if tick() - lastSpawnAttempt > 1 then
				lastSpawnAttempt = tick()
				pcall(function() SpawnToyRF:InvokeServer("InstrumentGuitarViolin", CFrame.new(0, 300, 0), Vector3.zero) end)
			end
			toggle = false return
		end
		toggle = not toggle
		if toggle then pcall(function() hamburger.HoldPart.HoldItemRemoteFunction:InvokeServer(hamburger, character) end) else pcall(function() hamburger.HoldPart.DropItemRemoteFunction:InvokeServer(hamburger, CFrame.new(0, 300, 0), Vector3.zero) end) end
	end)
end

local function disableAntiKill()
	if antiKillConnection then antiKillConnection:Disconnect() antiKillConnection = nil end
	local spawnedFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
	if spawnedFolder then
		for _, hb in ipairs(spawnedFolder:GetChildren()) do
			if hb.Name == "InstrumentGuitarViolin" and hb:FindFirstChild("HoldPart") then pcall(function() hb.HoldPart.DropItemRemoteFunction:InvokeServer(hb, CFrame.new(0, 300, 0), Vector3.zero) end) end
		end
		task.wait(0.1)
		for _, hb in ipairs(spawnedFolder:GetChildren()) do if hb.Name == "InstrumentGuitarViolin" then pcall(function() DeleteToyRE:FireServer(hb) end) end end
	end
end

local antiBlobmanKillConnection = nil
local function enableAntiBlobmanKill()
	if antiBlobmanKillConnection then antiBlobmanKillConnection:Disconnect() end
	local lastUpdate = 0
	antiBlobmanKillConnection = RunService.Heartbeat:Connect(function()
		if not Settings.AntiBlobmanKill then return end
		if tick() - lastUpdate < 0.033 then return end
		lastUpdate = tick()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then return end
		hum.Sit = true
		hum:ChangeState(Enum.HumanoidStateType.Running)
		if camera then
			local lookVec = camera.CFrame.LookVector
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
		end
	end)
end

local kickAllV1Thread = nil
local function startKickAllV1()
	if kickAllV1Thread then task.cancel(kickAllV1Thread) end
	kickAllV1Thread = task.spawn(function()
		local blob = BlobmanBetaFeature.getBlobman() or BlobmanBetaFeature.findAnyBlobman() or BlobmanBetaFeature.spawnBlobman()
		if not blob or not blob:FindFirstChild("VehicleSeat") then Settings.KickAllV1 = false return end
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not myHRP or not myHum then Settings.KickAllV1 = false return end

		while Settings.KickAllV1 do
			local targets = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then table.insert(targets, {plr = plr, root = plr.Character.HumanoidRootPart}) end
			end
			for _, t in ipairs(targets) do
				if not Settings.KickAllV1 then break end
				if myHRP and t.root then
					myHRP.CFrame = t.root.CFrame task.wait(0.03)
					BlobmanBetaFeature.blobKick(blob, t.root, Settings.currentSide) task.wait(0.03)
					BlobmanBetaFeature.ungrab(myHRP) task.wait(0.03)
				end
			end
			task.wait(0.05)
		end
	end)
end

local function setBarrierNoclip()
	local Plots = Workspace:FindFirstChild("Plots")
	if not Plots then return end
	for i = 1, 5 do
		local plot = Plots:FindFirstChild("Plot" .. i)
		if plot and plot:FindFirstChild("Barrier") then
			for _, b in ipairs(plot.Barrier:GetChildren()) do if b:IsA("BasePart") then b.CanCollide = false end end
		end
	end
end

local function UnlockBarrier()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local orig = LocalPlayer.Character.HumanoidRootPart.CFrame
	pcall(function() SpawnToyRF:InvokeServer("InstrumentWoodwindOcarina", CFrame.new(184.14, -5.54, 498.13), Vector3.new(0, 34, 0)) end)
	task.wait(0.3)
	local ocarina = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys"):FindFirstChild("InstrumentWoodwindOcarina")
	if ocarina and ocarina:FindFirstChild("HoldPart") then ocarina.HoldPart.HoldItemRemoteFunction:InvokeServer(ocarina, Workspace[LocalPlayer.Name]) end
	task.wait(0.3)
	LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(304.06, 25.77, 488.54) task.wait(0.15)
	if ocarina then pcall(function() DeleteToyRE:FireServer(ocarina) end) end task.wait(0.15)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = orig end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local setNetworkOwnerEvent = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")

local function claimPlotAndLoadHouse()

    task.wait()

    task.spawn(UnlockBarrier)
    task.wait(4)

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local targetPlot = nil

    for i = 1, 5 do
        local plotName = "Plot" .. i
        local plot = Workspace:WaitForChild("Plots"):WaitForChild(plotName)
        local ownersFolder = plot:WaitForChild("PlotSign"):WaitForChild("ThisPlotsOwners")

        if #ownersFolder:GetChildren() == 0 then
            targetPlot = plot
            break
        end
    end

    if not targetPlot then
        warn("All 5 plots checked, but all are owned. Giving up.")
        return
    end

    rootPart.CFrame = targetPlot:GetPivot()
    task.wait(1)

    local plotSign = targetPlot:WaitForChild("PlotSign")
    local children = plotSign:GetChildren()
    local targetChild = children[8]

    if targetChild and targetChild:FindFirstChild("Plus") then
        local plusPart = targetChild.Plus
        rootPart.CFrame = plusPart.CFrame

        setNetworkOwnerEvent:FireServer(plusPart, plusPart.CFrame)
    else
        warn("Could not find the Plus part at index 8 of PlotSign.")
        return
    end

    task.wait(1)

    local houseLoadButton = targetPlot:WaitForChild("PlotSign")
        :WaitForChild("PlotOptionsSign")
        :WaitForChild("HouseLoadModel")
        :WaitForChild("HouseLoadButton")

    setNetworkOwnerEvent:FireServer(houseLoadButton)

    print("Finished")
end

local function Disconnecthrp()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then for _, obj in ipairs(hrp:GetChildren()) do if obj:IsA("Motor6D") or obj:IsA("Weld") then obj:Destroy() end end end
end

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "OrionToggleDot"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ToggleGui.Parent = game:GetService("CoreGui") end)
if not ToggleGui.Parent then ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local BlackDot = Instance.new("TextButton")
BlackDot.Name = "OpenButton"
BlackDot.Size = UDim2.new(0, 42, 0, 42)
BlackDot.Position = UDim2.new(0, 20, 0, 140)
BlackDot.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BlackDot.Text = "Open"
BlackDot.TextColor3 = Color3.fromRGB(255, 255, 255)
BlackDot.Font = Enum.Font.SourceSansBold
BlackDot.TextSize = 14
BlackDot.Parent = ToggleGui
BlackDot.Draggable = true
BlackDot.Visible = false

BlackDot.MouseButton1Click:Connect(function()
    if OrionLib then
        OrionLib:ToggleUi()
        _G.Window.Visible = true
    end
end)

local infoTab = _G.Window:MakeTab({ Name = "Infoℹ️", Icon = "", PremiumOnly = false })
infoTab:AddLabel("Made by ai simp")
infoTab:AddLabel("HUGE thanks to TSBH_Adrenaline for making the attacks")

local PlayerTab = _G.Window:MakeTab({
	Name = "Player🚹",
	Icon = "",
	PremiumOnly = false
})

local PlayerSection = PlayerTab:AddSection({
	Name = "Movement & Physics Toggles"
})

_G.UseCustomWalkspeed = false
_G.UseCustomJump = false

PlayerSection:AddToggle({
	Name = "Toggle Custom Walkspeed",
	Default = false,
	Callback = function(Value)
		_G.UseCustomWalkspeed = Value

		if not Value then
			pcall(function()
				game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
			end)
		end
	end
})

PlayerSection:AddToggle({
	Name = "Toggle Custom Jump",
	Default = false,
	Callback = function(Value)
		_G.UseCustomJump = Value

		if not Value then
			pcall(function()
				game.Players.LocalPlayer.Character.Humanoid.JumpPower = 50
			end)
		end
	end
})

local SliderSection = PlayerTab:AddSection({
	Name = "Movement & Physics Modifiers"
})

-- Paste this directly into your existing Orion script where your buttons/toggles go
do
    local leftLegConnection
    local rightLegConnection

    PlayerTab:AddToggle({
        Name = "Auto Remove Left Leg",
        Default = false,
        Callback = function(Value)
            _G.RemoveLeftLegActive = Value
            
            if Value then
                leftLegConnection = task.spawn(function()
                    while _G.RemoveLeftLegActive do
                        if workspace:FindFirstChild('GrabParts') and workspace.GrabParts:FindFirstChild('GrabPart') then
                            local target = workspace.GrabParts.GrabPart.WeldConstraint.Part1 and workspace.GrabParts.GrabPart.WeldConstraint.Part1.Parent
                            if target and target:FindFirstChild('Left Leg') and target:FindFirstChild('Humanoid') and target.Humanoid:FindFirstChild('Ragdolled') then
                                if target.Humanoid.Ragdolled.Value then
                                    local pos = target.Torso.CFrame
                                    workspace.FallenPartsDestroyHeight = -100
                                    target['Left Leg'].CFrame = CFrame.new(0, -1E3, 0)
                                    task.wait(0.1)
                                    target.Torso.CFrame = CFrame.new(0, -950, 0)
                                    task.wait(0)
                                    target.Torso.CFrame = pos
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            else
                if leftLegConnection then 
                    task.cancel(leftLegConnection) 
                end
            end
        end    
    })

    PlayerTab:AddToggle({
        Name = "Auto Remove Right Leg",
        Default = false,
        Callback = function(Value)
            _G.RemoveRightLegActive = Value
            
            if Value then
                rightLegConnection = task.spawn(function()
                    while _G.RemoveRightLegActive do
                        if workspace:FindFirstChild('GrabParts') and workspace.GrabParts:FindFirstChild('GrabPart') then
                            local target = workspace.GrabParts.GrabPart.WeldConstraint.Part1 and workspace.GrabParts.GrabPart.WeldConstraint.Part1.Parent
                            if target and target:FindFirstChild('Right Leg') and target:FindFirstChild('Humanoid') and target.Humanoid:FindFirstChild('Ragdolled') then
                                if target.Humanoid.Ragdolled.Value then
                                    local pos = target.Torso.CFrame
                                    workspace.FallenPartsDestroyHeight = -100
                                    target['Right Leg'].CFrame = CFrame.new(0, -1E3, 0)
                                    task.wait(0.1)
                                    target.Torso.CFrame = CFrame.new(0, -950, 0)
                                    task.wait(0)
                                    target.Torso.CFrame = pos
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            else
                if rightLegConnection then 
                    task.cancel(rightLegConnection) 
                end
            end
        end    
    })
end





local RunService = game:GetService("RunService")

local TpWalkConnection = nil

SliderSection:AddSlider({
	Name = "Walkspeed",
	Min = 16,
	Max = 500,
	Default = 16,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	Callback = function(Value)
		TpWalkSpeed = Value

		pcall(function()
			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
		end)

		if not TpWalkConnection then
			TpWalkConnection = RunService.Heartbeat:Connect(function(deltaTime)
				pcall(function()

					if _G.UseCustomWalkspeed then
						local character = game.Players.LocalPlayer.Character
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						local rootPart = character:FindFirstChild("HumanoidRootPart")

						if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then

							local targetVelocity = humanoid.MoveDirection * (TpWalkSpeed - 16)
							rootPart.CFrame = rootPart.CFrame + (targetVelocity * deltaTime)
						end
					end
				end)
			end)
		end
	end
})

local targetJumpHeight = 50
local currentHumanoidConn = nil

local function applyJumpHeight(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid and _G.UseCustomJump then
        humanoid.JumpPower = targetJumpHeight
    end
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)

    task.wait(0.1)
    applyJumpHeight(newCharacter)
end)

local targetJumpHeight = 50
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function()

    if _G.UseCustomJump then
        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then

            if humanoid.JumpPower ~= targetJumpHeight then
                humanoid.JumpPower = targetJumpHeight
            end
        end
    end
end)

SliderSection:AddSlider({
    Name = "Jump Height",
    Min = 50,
    Max = 500,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    Callback = function(Value)
        targetJumpHeight = Value
    end
})

SliderSection:AddSlider({
	Name = "Gravity",
	Min = 0,
	Max = 196.2,
	Default = 196.2,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	Callback = function(Value)
		game.Workspace.Gravity = Value
	end
})

SliderSection:AddToggle({
	Name = "Infinite Jump",
	Default = false,
	Callback = function(Value)
		_G.InfJump = Value
		game:GetService("UserInputService").JumpRequest:Connect(function()
			if _G.InfJump then
				game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState("Jumping")
			end
		end)
	end
})

local ProtectionSection = PlayerTab:AddSection({
	Name = "Client Protection"
})

local PlayersService = game:GetService("Players")
local oldHook

ProtectionSection:AddToggle({
	Name = "Anti-Local Kick",
	Default = false,
	Callback = function(Value)
		_G.AntiKick = Value

		if not oldHook then
			if type(hookmetamethod) ~= "function" then warn("[Aether] no hookmetamethod") return end
			oldHook = hookmetamethod(game, "__namecall", function(self, ...)
				local method = (getnamecallmethod and getnamecallmethod()) or ""

				if _G.AntiKick and self == PlayersService.LocalPlayer and (method == "Kick" or method == "kick") then
					return nil
				end

				return oldHook(self, ...)
			end)
		end
	end
})

local ServerTab = _G.Window:MakeTab({
	Name = "Servers💾",
	Icon = "",
	PremiumOnly = false
})

local ServerSection = ServerTab:AddSection({
	Name = "Server Management"
})

ServerSection:AddButton({
	Name = "Rejoin Server",
	Callback = function()
		local ts = game:GetService("TeleportService")
		local p = game.Players.LocalPlayer
		ts:Teleport(game.PlaceId, p)
	end
})

ServerSection:AddButton({
	Name = "Server Hop",
	Callback = function()
		local HttpService = game:GetService("HttpService")
		local TeleportService = game:GetService("TeleportService")

		local targetUrl = "https://roblox.com" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(targetUrl))
		end)

		if success and result and result.data then

			for i = #result.data, 1, -1 do
				local server = result.data[i]
				if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then

					if (server.maxPlayers - server.playing) >= 2 then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, game.Players.LocalPlayer)
						break
					end
				end
			end
		end
	end
})

ServerSection:AddToggle({
	Name = "Mobile Anti-AFK",
	Default = false,
	Callback = function(Value)
		_G.AntiAFK = Value
		if Value then
			task.spawn(function()
				local localPlayer = game:GetService("Players").LocalPlayer
				localPlayer.Idled:Connect(function()
					if _G.AntiAFK then
						local camera = workspace.CurrentCamera
						if camera then
							camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(1), 0)
							task.wait(0.1)
							camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(-1), 0)
						end
					end
				end)
			end)
		end
	end
})

local AntisTab = _G.Window:MakeTab({ Name = "Antis🛡", Icon = "", PremiumOnly = false })
local BarrierTab = _G.Window:MakeTab({ Name = "Barrier❌️", Icon = "", PremiumOnly = false })
_G.ScriptStuff = _G.Window:MakeTab({ Name = "Script helpers", Icon = "", PremiumOnly = false })
local ScriptStuff = _G.ScriptStuff
local CustomProtectTab = _G.Window:MakeTab({ Name = "Givers👑", Icon = "", PremiumOnly = false })
ScriptStuff:AddButton({Name = "Ocean Shape Force", Callback = function() local lp = game:GetService("Players").LocalPlayer local validPlayers = {} for _, p in ipairs(game:GetService("Players"):GetPlayers()) do if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(validPlayers, p) end end if #validPlayers == 0 then return end local oceanParts = {} for _, desc in ipairs(game.Workspace:GetDescendants()) do if desc:IsA("BasePart") and (desc.Name:lower():find("ocean") or desc.Name:lower():find("water")) then table.insert(oceanParts, desc) end end if #oceanParts == 0 then return end task.spawn(function() local radius = 25 local heightAboveHead = 35 for idx, part in ipairs(oceanParts) do local targetPlayer = validPlayers[math.random(1, #validPlayers)] local tChar = targetPlayer and targetPlayer.Character local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart") if tRoot then local angle = (idx / #oceanParts) * (math.pi * 2) local shapeOffset = Vector3.new(math.cos(angle) * radius, heightAboveHead + (math.sin(idx) * 5), math.sin(angle) * radius) local projectCF = CFrame.new(tRoot.Position + shapeOffset) * CFrame.Angles(math.sin(idx), math.cos(idx), 0) pcall(function() part.Anchored = false local grabEvents = game:GetService("ReplicatedStorage"):FindFirstChild("GrabEvents") local setNetOwner = grabEvents and grabEvents:FindFirstChild("SetNetworkOwner") if setNetOwner then setNetOwner:FireServer(part, part.CFrame) end part.CFrame = projectCF part.AssemblyLinearVelocity = Vector3.zero part.AssemblyAngularVelocity = Vector3.zero end) end if idx % 5 == 0 then task.wait() end end end) end})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local selectedPlayer = nil
local targetQueue = {}
local manualTargets = {}

local GRAB_EVENTS = ReplicatedStorage:WaitForChild("GrabEvents")
local SET_NETWORK_OWNER = GRAB_EVENTS:WaitForChild("SetNetworkOwner")
local DESTROY_GRAB_LINE = GRAB_EVENTS:WaitForChild("DestroyGrabLine")
local LocalPlayer = Players.LocalPlayer

local ActiveProtectDropdown = nil

local function updateDropdown()
    local options = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            table.insert(options, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    if ActiveProtectDropdown then
        ActiveProtectDropdown:Refresh(options, true)
    end
end

Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(updateDropdown)

ActiveProtectDropdown = CustomProtectTab:AddDropdown({
    Name = "Select Targeted Player",
    Options = {},
    CurrentOption = "None",
    MultipleOptions = false,
    Callback = function(option)
        if option and option ~= "None" and option ~= "" then
            local username = option:match("%(@([^)]+)%)")
            selectedPlayer = Players:FindFirstChild(username)
        else
            selectedPlayer = nil
        end
    end
})
updateDropdown()

CustomProtectTab:AddButton({
    Name = "Add Selected to Queue",
    Callback = function()
        if selectedPlayer then
            if not table.find(targetQueue, selectedPlayer) then
                table.insert(targetQueue, selectedPlayer)
            end
            if not table.find(manualTargets, selectedPlayer) then
                table.insert(manualTargets, selectedPlayer)
            end
            OrionLib:MakeNotification({
                Name = "Queue Updated",
                Content = selectedPlayer.DisplayName .. " is now being tracked.",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        else
            OrionLib:MakeNotification({
                Name = "Selection Error",
                Content = "Please pick a valid player from the dropdown menu first.",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

CustomProtectTab:AddButton({
    Name = "Clear Queue",
    Callback = function()
        targetQueue = {}
        manualTargets = {}
        OrionLib:MakeNotification({
            Name = "Queue Cleared",
            Content = "All target entries cleared from protect tracker memory profiles.",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

local function executeRescueSequence(targetPlayer)
    local myCharacter = LocalPlayer.Character
    local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local targetCharacter = targetPlayer.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

    if not myRootPart or not targetRoot or not targetRoot.Parent then return end

    local partOwner = targetCharacter:FindFirstChild("PartOwner")
    if partOwner and partOwner:IsA("StringValue") and partOwner.Value == LocalPlayer.Name then
        DESTROY_GRAB_LINE:FireServer(targetRoot)
        return
    end

    local savedTargetCFrame = targetRoot.CFrame
    local originalPlayerCFrame = myRootPart.CFrame

    local camera = Workspace.CurrentCamera
    local originalCameraType = camera.CameraType
    local originalCameraCFrame = camera.CFrame
    camera.CameraType = Enum.CameraType.Scriptable

    myRootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.1)

    for i = 1, 10 do
        attemptowner_move(true, savedTargetCFrame, Vector3.zero, Vector3.zero, targetRoot)
    end

    targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    targetCharacter:SetPrimaryPartCFrame(savedTargetCFrame)
    DESTROY_GRAB_LINE:FireServer(targetRoot)

    myRootPart.CFrame = originalPlayerCFrame
    camera.CFrame = originalCameraCFrame

    camera.CameraType = Enum.CameraType.Fixed
    RunService.RenderStepped:Wait()

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = myCharacter:FindFirstChildOfClass("Humanoid")

    myRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    myRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    local humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

task.spawn(function()
    while true do
        for _, targetPlayer in ipairs(manualTargets) do
            if targetPlayer and targetPlayer.Parent == Players then
                local isHeldVal = targetPlayer:FindFirstChild("IsHeld")
                if isHeldVal and (isHeldVal:IsA("BoolValue") or isHeldVal:IsA("ValueBase")) and isHeldVal.Value == true then
                    pcall(function()
                        executeRescueSequence(targetPlayer)
                    end)
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
	while true do
		for _, targetPlayer in ipairs(manualTargets) do
			if targetPlayer and targetPlayer.Parent == Players then

				local isHeldVal = targetPlayer:FindFirstChild("IsHeld")
				if isHeldVal and (isHeldVal:IsA("BoolValue") or isHeldVal:IsA("ValueBase")) and isHeldVal.Value == true then

					pcall(function()
						executeRescueSequence(targetPlayer)
					end)

					task.wait(0.1)
				end
			end
		end
		task.wait()
	end
end)

local Lighting = game:GetService("Lighting")

local VisualsTab = _G.Window:MakeTab({
	Name = "Shaders🌃",
	Icon = "",
	PremiumOnly = false
})

local function getOrCreateEffect(className, name)
	local effect = Lighting:FindFirstChild(name)
	if not effect then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect
end

local colorCorrection = getOrCreateEffect("ColorCorrectionEffect", "CustomColorCorrection")
local bloom = getOrCreateEffect("BloomEffect", "CustomBloom")
local sunRays = getOrCreateEffect("SunRaysEffect", "CustomSunRays")

colorCorrection.Enabled = false
colorCorrection.Brightness = 0.1
colorCorrection.Contrast = 0.15
colorCorrection.Saturation = 0.2

bloom.Enabled = false
bloom.Intensity = 1
bloom.Size = 24
bloom.Threshold = 0.9

sunRays.Enabled = false
sunRays.Intensity = 0.1
sunRays.Spread = 1

local skyboxPresets = {
	["Default"] = {
		SkyboxBk = "rbxassetid://164344078", SkyboxDn = "rbxassetid://164344053", SkyboxFt = "rbxassetid://164344026",
		SkyboxLf = "rbxassetid://164344007", SkyboxRt = "rbxassetid://164343940", SkyboxUp = "rbxassetid://164344093"
	},
	["Cyberpunk Neon"] = {
		SkyboxBk = "rbxassetid://2312683072", SkyboxDn = "rbxassetid://2312683226", SkyboxFt = "rbxassetid://2312683397",
		SkyboxLf = "rbxassetid://2312683574", SkyboxRt = "rbxassetid://2312683713", SkyboxUp = "rbxassetid://2312683884"
	},
	["Deep Space"] = {
		SkyboxBk = "rbxassetid://154449886", SkyboxDn = "rbxassetid://154449911", SkyboxFt = "rbxassetid://154449931",
		SkyboxLf = "rbxassetid://154449955", SkyboxRt = "rbxassetid://154449975", SkyboxUp = "rbxassetid://154449993"
	},
	["Aesthetic Purple Pastel"] = {
		SkyboxBk = "rbxassetid://5854483733", SkyboxDn = "rbxassetid://5854483569", SkyboxFt = "rbxassetid://5854483321",
		SkyboxLf = "rbxassetid://5854483103", SkyboxRt = "rbxassetid://5854482811", SkyboxUp = "rbxassetid://5854482559"
	},
	["Realistic Sunset"] = {
		SkyboxBk = "rbxassetid://265320577", SkyboxDn = "rbxassetid://265321345", SkyboxFt = "rbxassetid://265321528",
		SkyboxLf = "rbxassetid://265321856", SkyboxRt = "rbxassetid://265322129", SkyboxUp = "rbxassetid://265322409"
	}
}

local function applySkybox(presetName)
	local assets = skyboxPresets[presetName]
	if not assets then return end

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	local newSky = Instance.new("Sky")
	newSky.Name = "CustomSkyboxEffect"
	newSky.SkyboxBk = assets.SkyboxBk
	newSky.SkyboxDn = assets.SkyboxDn
	newSky.SkyboxFt = assets.SkyboxFt
	newSky.SkyboxLf = assets.SkyboxLf
	newSky.SkyboxRt = assets.SkyboxRt
	newSky.SkyboxUp = assets.SkyboxUp

	if presetName == "Deep Space" then
		Lighting.TimeOfDay = "00:00:00"
		Lighting.Ambient = Color3.fromRGB(10, 10, 20)
	elseif presetName == "Realistic Sunset" then
		Lighting.TimeOfDay = "17:30:00"
		Lighting.Ambient = Color3.fromRGB(130, 90, 60)
	else
		Lighting.TimeOfDay = "14:00:00"
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	end

	newSky.Parent = Lighting
end

VisualsTab:AddSection({
	Name = "Post-Processing Shaders"
})

VisualsTab:AddToggle({
	Name = "Vibrant Color Correction",
	Default = false,
	Callback = function(Value)
		colorCorrection.Enabled = Value
	end
})

VisualsTab:AddToggle({
	Name = "High Bloom Contrast (Glow)",
	Default = false,
	Callback = function(Value)
		bloom.Enabled = Value
	end
})

VisualsTab:AddToggle({
	Name = "Volumetric Sun Rays",
	Default = false,
	Callback = function(Value)
		sunRays.Enabled = Value
	end
})

VisualsTab:AddSection({
	Name = "Atmospheric Skyboxes"
})

local dropdownOptions = {}
for name, _ in pairs(skyboxPresets) do
	table.insert(dropdownOptions, name)
end
table.sort(dropdownOptions)

VisualsTab:AddDropdown({
	Name = "Change Atmosphere/Skybox",
	Default = "Default",
	Options = dropdownOptions,
	Callback = function(Value)
		pcall(function()
			applySkybox(Value)
		end)
	end
})
-- ==========================================
-- REWRITTEN GUCCI ANTI-GRAB LAYER FOR PART1
-- ==========================================
AntisTab:AddSection({ Name = "GUCCI Anti-Grab Layer" })

AntisTab:AddDropdown({
    Name = "GUCCI Vehicle Type",
    Default = "CreatureBlobman",
    Options = {"CreatureBlobman", "TractorGreen", "Train", "SantaSleigh"},
    Callback = function(Value) 
        Settings.BlobmanBeta.currentGucciType = Value 
    end
})

AntisTab:AddToggle({
    Name = "GUCCI Anti-Grab",
    Default = false,
    Callback = function(Value)
        if Value then
            task.spawn(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not myRoot or not myHum or myHum.Health <= 0 then return end

                local chosenToy = Settings.BlobmanBeta.currentGucciType or "CreatureBlobman"
                local targetVehicle = SpawnToy(chosenToy)
                
                -- CRITICAL SAFEGUARD: Drop out immediately if vehicle fails to spawn
                if not targetVehicle or not targetVehicle.Parent then 
                    warn("[Aether] Failed to spawn vehicle tool asset type: " .. tostring(chosenToy))
                    return 
                end
                
                targetVehicle.Name = "GucciRSC"
                local seat = targetVehicle:WaitForChild("VehicleSeat", 2) or targetVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
                local mainPart = targetVehicle:FindFirstChild("Main") or targetVehicle:FindFirstChild("Hitbox") or targetVehicle:FindFirstChildWhichIsA("BasePart")
                
                if not seat or not mainPart then 
                    pcall(function() DeleteToyRE:FireServer(targetVehicle) end) 
                    return 
                end

                local function makeGhost(p)
                    if p:IsA("BasePart") then 
                        p.Transparency = 1 
                        p.CanCollide = false 
                        p.CanTouch = false 
                        p.CanQuery = false
                    elseif p:IsA("Decal") or p:IsA("Texture") then 
                        p.Transparency = 1 
                    end
                end
                for _, desc in ipairs(targetVehicle:GetDescendants()) do makeGhost(desc) end
                targetVehicle.DescendantAdded:Connect(makeGhost)

                myHum.Sit = false
                local weldConn = seat.ChildAdded:Connect(function(child) 
                    if child.Name == "SeatWeld" then 
                        child.Enabled = false 
                        child:Destroy() 
                    end 
                end)
                local scriptConn = myChar.ChildAdded:Connect(function(child) 
                    if child:IsA("LocalScript") and child.Name:lower():find("control") then 
                        child.Enabled = false 
                        child:Destroy() 
                    end 
                end)

                local originalCF = myRoot.CFrame
                local forceHeartbeat; forceHeartbeat = RunService.Heartbeat:Connect(function()
                    local c = LocalPlayer.Character 
                    local r = c and c:FindFirstChild("HumanoidRootPart") 
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if not (targetVehicle and targetVehicle.Parent and r and h and h.Health > 0) then
                        if forceHeartbeat then forceHeartbeat:Disconnect() end
                        if weldConn then weldConn:Disconnect() end
                        if scriptConn then scriptConn:Disconnect() end
                    else
                        -- CRITICAL FIX: Safe check for RagdollRemote event folder existence before invocation
                        local characterEvents = ReplicatedStorage:FindFirstChild("CharacterEvents")
                        local ragdollRemote = characterEvents and characterEvents:FindFirstChild("RagdollRemote")
                        if ragdollRemote then
                            pcall(function() ragdollRemote:FireServer(r, 0) end)
                        end
                    end
                end)

                task.wait()
                seat:Sit(myHum)

                local successClaim = false 
                local startTick = tick()
                while (tick() - startTick) < 0.75 do
                    sno(mainPart)
                    local po = mainPart:FindFirstChild("PartOwner") or (mainPart.Parent and mainPart.Parent:FindFirstChild("PartOwner", true))
                    if po and po.Value == LocalPlayer.Name then 
                        successClaim = true 
                        break 
                    end
                    RunService.Heartbeat:Wait()
                end

                if not successClaim then
                    if forceHeartbeat then forceHeartbeat:Disconnect() end
                    if weldConn then weldConn:Disconnect() end
                    if scriptConn then scriptConn:Disconnect() end
                    pcall(function() DeleteToyRE:FireServer(targetVehicle) end) 
                    return
                end

                local bp = Instance.new("BodyPosition")
                bp.Name = "GucciBP" 
                bp.D = 200 
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.Position = Vector3.new(math.random(-100000, 100000), 100000, math.random(-100000, 100000))
                bp.Parent = mainPart

                myRoot.CFrame = originalCF
                myHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                
                _G.ActiveGucciVehicle = targetVehicle
                _G.ActiveGucciHeartbeat = forceHeartbeat
                _G.ActiveGucciWeld = weldConn
                _G.ActiveGucciScript = scriptConn
            end)
        else
            if _G.ActiveGucciHeartbeat then _G.ActiveGucciHeartbeat:Disconnect() _G.ActiveGucciHeartbeat = nil end
            if _G.ActiveGucciWeld then _G.ActiveGucciWeld:Disconnect() _G.ActiveGucciWeld = nil end
            if _G.ActiveGucciScript then _G.ActiveGucciScript:Disconnect() _G.ActiveGucciScript = nil end
            if _G.ActiveGucciVehicle then pcall(function() DeleteToyRE:FireServer(_G.ActiveGucciVehicle) end) _G.ActiveGucciVehicle = nil end
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Sit = false h:ChangeState(Enum.HumanoidStateType.Running) end
        end
    end
})



AntisTab:AddButton({
    Name = "destroy gucci",
    Callback = function()
        if _G.ActiveGucciHeartbeat then _G.ActiveGucciHeartbeat:Disconnect() _G.ActiveGucciHeartbeat = nil end
        if _G.ActiveGucciWeld then _G.ActiveGucciWeld:Disconnect() _G.ActiveGucciWeld = nil end
        if _G.ActiveGucciScript then _G.ActiveGucciScript:Disconnect() _G.ActiveGucciScript = nil end
        local inv = workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        if inv then
            for _, child in ipairs(inv:GetChildren()) do
                if child.Name == "GucciRSC" or child.Name == "CreatureBlobman" or child.Name == "TractorGreen" or child.Name == "SantaSleigh" then
                    pcall(function() DeleteToyRE:FireServer(child) end)
                end
            end
        end
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Sit = false h:ChangeState(Enum.HumanoidStateType.Running) end
    end
})

AntisTab:AddToggle({ Name = "Iso anti V5", Default = false, Callback = function(Value) _G.SETTINGS_ANTI_GRAB = Value end })
AntisTab:AddToggle({ Name = "Antigrab by TSBH", Default = false, Callback = function(Value) AntiGrabEnabled = Value end })
AntisTab:AddToggle({ Name = "Anti Explosion", Default = false, Callback = function(Value) Settings.AntiExplosion = Value setupAntiExplosion(LocalPlayer.Character) end })
AntisTab:AddToggle({ Name = "Anti Kill (Hamburger)", Default = false, Callback = function(Value) Settings.AntiKillHamburger = Value if Value then enableAntiKill() else disableAntiKill() end end })
AntisTab:AddToggle({ Name = "Anti Lag", Default = false, Callback = function(Value) setAntiLag(Value) end })
AntisTab:AddToggle({ Name = "Anti Blobman Kill", Default = false, Callback = function(Value) Settings.AntiBlobmanKill = Value enableAntiBlobmanKill() end })
AntisTab:AddToggle({
	Name = "Anti-Kick (PCLD LOCK)",
	Default = false,
	Callback = function(Val)
		AntiKickItemActive = Val 
		
		if Val then
			task.spawn(function()
				local Item, SoundPart
				while AntiKickItemActive and task.wait() do 
					local char = Players.LocalPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChild("Humanoid")
					local inPlot = Players.LocalPlayer:FindFirstChild("InPlot")
					local inv = workspace:FindFirstChild(Players.LocalPlayer.Name.."SpawnedInToys")
					local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
					
					if not hrp or not hum or hum.Health <= 0 or not inv then continue end  
					if inPlot and inPlot.Value then continue end 
					
					if not MyPCLD and not pcldConn then
						FindPCLD(hrp)
					end

					Item = inv:FindFirstChild("AntiKickItem") 
					SoundPart = Item and Item:FindFirstChild("Hitbox")
					
					if not Item or not SoundPart then
						for _,v in pairs(inv:GetChildren()) do 
							if v.Name == "AntiKickItem" then 
								pcall(function() destroyToy:FireServer(v) end)
							end
						end
						
						Item = SpawnToy(SelectedToy)
						if not Item then continue end 
						
						SoundPart = Item and FWD(Item, "Hitbox", 0.5)
						if SoundPart then sno(SoundPart) end
						
						for _,v in pairs(Item:GetChildren()) do 
							if v:IsA("BasePart") then 
								v.CanCollide = false 
								v.Transparency = 0.8
								v.Color = Color3.fromRGB(0, 255, 255) -- Graphical cyan tracing highlight
							end
						end
						Item.Name = "AntiKickItem"
					end
					
					if SoundPart and not CheckNetworkOwnerOnPart(SoundPart) then 
						sno(SoundPart)
					end
					
					local targetPart = MyPCLD or hrp:FindFirstChild("FirePlayerPart") or hrp
					if SoundPart and targetPart then
						SoundPart.CFrame = targetPart.CFrame
						SoundPart.AssemblyLinearVelocity = Vector3.zero
						SoundPart.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
		else
			if pcldConn then pcldConn:Disconnect() pcldConn = nil end
			MyPCLD = nil
			
			task.spawn(function()
				local inv = workspace:FindFirstChild(Players.LocalPlayer.Name.."SpawnedInToys")
				local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
				if inv and destroyToy then
					for _,v in pairs(inv:GetChildren()) do 
						if v.Name == "AntiKickItem" then 
							pcall(function() destroyToy:FireServer(v) end)
						end
					end
				end
			end)
		end
	end
})


BarrierTab:AddButton({ Name = "Unlock Barrier (V1)", Callback = function() task.spawn(UnlockBarrier) end })
BarrierTab:AddToggle({ Name = "Barrier Noclip", Default = false, Callback = function(Value) Settings.BarrierNoclip = Value setBarrierNoclip() end })

ScriptStuff:AddToggle({ Name = "Enable void", Default = true, Callback = function(Value) Workspace.FallHeightEnabled = Value end })
ScriptStuff:AddButton({ Name = "Tsunami", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/tsunami.lua"))() end })
ScriptStuff:AddButton({ Name = "Disconnect hrp", Callback = function() task.spawn(Disconnecthrp) end })

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local state = {
    plotName = "Plot3",
    autoTP = false,
    ownerOnly = true,
    hasTriggered = false,
    lastCFrame = nil,
    timeValue = nil,
}

local function OrionNotify(title, msg)
    OrionLib:MakeNotification({
        Name = title,
        Content = msg,
        Image = "rbxassetid://4483362458",
        Time = 3
    })
end

local function CheckPlotOwner(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false, "Plots missing" end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false, plotName .. " missing" end
    local ownerName = ""
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local ownersFolder = plotSign:FindFirstChild("ThisPlotsOwners")
        if ownersFolder then
            for _, child in ipairs(ownersFolder:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("ObjectValue") then
                    local v = tostring(child.Value)
                    if v ~= "" then ownerName = v break end
                end
                if child.Name == "Value" then
                    ownerName = tostring(child.Value)
                    break
                end
            end
            local valObj = ownersFolder:FindFirstChild("Value")
            if valObj then ownerName = tostring(valObj.Value) end
        end
    end
    if ownerName == "" then
        for _, desc in ipairs(plot:GetDescendants()) do
            if (desc.Name == "Value" or desc.Name == "Owner") and (desc:IsA("StringValue") or desc:IsA("ObjectValue")) then
                ownerName = tostring(desc.Value)
                if ownerName ~= "" then break end
            end
        end
    end
    if ownerName == LocalPlayer.Name or ownerName == "VyzenAlt" or ownerName == "VYZEN_NN" then
        return true, ownerName
    end
    return false, ownerName ~= "" and ownerName or "None"
end

local function FindTimeRemaining(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        local plot = plots:FindFirstChild(plotName or "Plot3")
        if plot then
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc.Name == "TimeRemainingNum" and (desc:IsA("IntValue") or desc:IsA("NumberValue")) then
                    return desc
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "TimeRemainingNum" and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end
    return nil
end

local function TeleportToPlotHouse(plotName)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild(plotName or "Plot3")
    if not plot then
        OrionNotify("Teleport Error", (plotName or "Plot3") .. " not found")
        return
    end
    local house = plot:FindFirstChild("House", true)
    if not house then
        OrionNotify("Teleport Error", "House not found")
        return
    end
    local targets = {"BigFatTree", "BigSkinTree", "FireLog", "Deck", "Chimney", "Chimney2", "BottomTrim"}
    local targetPart = nil
    for _, name in ipairs(targets) do
        local obj = house:FindFirstChild(name, true)
        if obj then
            if obj:IsA("BasePart") then targetPart = obj break end
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPart = part break end
        end
    end
    if not targetPart then
        targetPart = house:FindFirstChildWhichIsA("BasePart", true)
    end
    if targetPart then
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 8, 0)
        OrionNotify("Teleported", "Landed on " .. targetPart.Name)
    else
        hrp.CFrame = house:GetPivot() + Vector3.new(0, 10, 0)
        OrionNotify("Teleported", "Used House pivot")
    end
    task.delay(2, function()
        if state.lastCFrame and character and character.Parent and hrp and hrp.Parent then
            hrp.CFrame = state.lastCFrame
            OrionNotify("Returned", "Returned to original position")
        end
    end)
end

local function CheckAndTeleport()
    if not state.timeValue or not state.timeValue.Parent then
        state.timeValue = FindTimeRemaining(state.plotName)
    end
    local isOwner = CheckPlotOwner(state.plotName)
    if state.timeValue then
        local val = state.timeValue.Value
        if val > 9 then
            state.hasTriggered = false
        end
        if val == 8 and not state.hasTriggered then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then state.lastCFrame = hrp.CFrame end
        end
        if val <= 6 and not state.hasTriggered then
            if (not state.ownerOnly) or isOwner then
                state.hasTriggered = true
                OrionNotify("Auto TP Triggered", "Timer: " .. tostring(val) .. "s - TPing to house")
                TeleportToPlotHouse(state.plotName)
                return true
            end
        end
    end
    return false
end

local StatusLabel = ScriptStuff:AddLabel(state.plotName .. " | Timer: N/A | Owner: ...")

ScriptStuff:AddDropdown({
    Name = "Select Plot Target",
    Default = state.plotName,
    Options = {"Plot1", "Plot2", "Plot3", "Plot4", "Plot5"},
    Callback = function(Option)
        state.plotName = Option
        state.timeValue = nil
        state.hasTriggered = false
        OrionNotify("Plot Changed", "Selected " .. Option)
    end,
})

ScriptStuff:AddToggle({
    Name = "Auto TP (Timer <= 6s)",
    Default = state.autoTP,
    Callback = function(Value)
        state.autoTP = Value
        state.hasTriggered = false
        state.timeValue = FindTimeRemaining(state.plotName)
        OrionNotify("Auto TP", Value and ("Watching " .. state.plotName) or "Auto TP Disabled")
    end,
})

ScriptStuff:AddToggle({
    Name = "Only When I Own Plot",
    Default = state.ownerOnly,
    Callback = function(Value)
        state.ownerOnly = Value
    end,
})

ScriptStuff:AddButton({
    Name = "Force TP To House Now",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then state.lastCFrame = hrp.CFrame end
        TeleportToPlotHouse(state.plotName)
    end,
})

task.spawn(function()
    local lastStatusUpdate = 0
    while true do
        if state.autoTP then
            CheckAndTeleport()
        else
            if not state.timeValue or not state.timeValue.Parent then
                state.timeValue = FindTimeRemaining(state.plotName)
            end
        end
        local now = tick()
        if now - lastStatusUpdate > 0.5 then
            lastStatusUpdate = now
            local isOwner, ownerInfo = CheckPlotOwner(state.plotName)
            local val = (state.timeValue and state.timeValue.Parent) and state.timeValue.Value or "N/A"

            StatusLabel:Set(state.plotName .. " | Timer: " .. tostring(val) .. "s | Owner: " .. tostring(ownerInfo))
        end
        task.wait(0.15)
    end
end)

ServerTab:AddToggle({ Name = "Lag server", Default = false, Callback = function(Value) shared.LagSettings.MonsterLagEnabled = Value end })

PlayerTab:AddButton({ Name = "Multicolor&FurtherReach", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Multicolor-and-FurtherReach-224379"))()
 end })
ScriptStuff:AddButton({ Name = "Inf Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
 end })
ScriptStuff:AddButton({ Name = "Dex++", Callback = function() loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-Dex-PlusPlus-Decompiler-Fix-206651"))()
 end })
ScriptStuff:AddButton({ Name = "Cobalt", Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Wortexios/CobaltSpy/refs/heads/main/Cobalt"))()
 end })

end
local function AetherPart2()
	local ScriptStuff = _G.ScriptStuff
	if not ScriptStuff then
		warn("[Aether] no ScriptStuff")
		return
	end

local ToyMod = _G.Window:MakeTab({ Name = "Toy mod🎩", Icon = "", PremiumOnly = false })

local hsection = ToyMod:AddSection({
    Name = "House plots"
})
ToyMod:AddButton({
	Name = "Setup ToyMod",
	Callback = function()
		task.spawn(claimPlotAndLoadHouse)
	end
})
local msection = ToyMod:AddSection({
    Name = "Midi"
})

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local displayText = "HELLO 123"
local isEnabled = false
local currentSpeedSetting = 10
local ON_HEAD = true
local HEAD_HEIGHT = 8
local MAKER_SPACING = 7.5
local ROTATION_STEP = -09

local frameDuration = 0.35 - currentSpeedSetting * 0.03
local scrollOffset, lastUpdate = 0, 0
local GrabEvents, SetNetworkOwner, ToyFolder
local MidiMakers = {}
local rows = {"A","B","C","D","E","F","G","H"}
local grid, canvas = {}, {}

local rawFont = {
A="00111100/01100110/01100110/01111110/01100110/01100110/01100110/00000000",
B="01111100/01100110/01100110/01111100/01100110/01100110/01111100/00000000",
C="00111100/01100110/01100000/01100000/01100000/01100110/00111100/00000000",
D="01111000/01101100/01100110/01100110/01100110/01101100/01111000/00000000",
E="01111110/01100000/01100000/01111100/01100000/01100000/01111110/00000000",
F="01111110/01100000/01100000/01111100/01100000/01100000/01100000/00000000",
G="00111100/01100110/01100000/01101110/01100110/01100110/00111100/00000000",
H="01100110/01100110/01100110/01111110/01100110/01100110/01100110/00000000",
I="00111000/00010000/00010000/00010000/00010000/00010000/00111000/00000000",
J="00001110/00000110/00000110/00000110/00000110/01100110/00111100/00000000",
K="01100110/01101100/01111000/01110000/01111000/01101100/01100110/00000000",
L="01100000/01100000/01100000/01100000/01100000/01100000/01111110/00000000",
M="01100011/01110111/01111111/01101011/01100011/01100011/01100011/00000000",
N="01100110/01110110/01111110/01101110/01100110/01100110/01100110/00000000",
O="00111100/01100110/01100110/01100110/01100110/01100110/00111100/00000000",
P="01111100/01100110/01100110/01111100/01100000/01100000/01100000/00000000",
Q="00111100/01100110/01100110/01100110/01101110/01100110/00111111/00000011",
R="01111100/01100110/01100110/01111100/01111000/01101100/01100110/00000000",
S="00111100/01100110/00110000/00011100/00011000/01100110/00111100/00000000",
T="01111110/00011000/00011000/00011000/00011000/00011000/00011000/00000000",
U="01100110/01100110/01100110/01100110/01100110/01100110/00111100/00000000",
V="01100110/01100110/01100110/01100110/00111100/00111100/00011000/00000000",
W="01100011/01100011/01100011/01101011/01111111/00110110/00110110/00000000",
X="01100110/01100110/00111100/00011000/00111100/01100110/01100110/00000000",
Y="01100110/01100110/01100110/00111100/00011000/00011000/00011000/00000000",
Z="01111110/00000110/00001100/00011000/00110000/01100000/01111110/00000000",
["0"]="00111100/01100110/01101110/01111110/01110110/01100110/00111100/00000000",
["1"]="00011000/00111000/01011000/00011000/00011000/00011000/01111110/00000000",
["2"]="00111000/01100110/00000110/00011100/00110000/01100000/01111110/00000000",
["3"]="00111100/01100110/00000110/00111100/00000110/01100110/00111100/00000000",
["4"]="00001100/00011100/00110100/01100100/01111110/00000100/00000100/00000000",
["5"]="01111110/01100000/01111100/00000110/00000110/01100110/00111100/00000000",
["6"]="00111100/01100000/01100000/01111100/01100110/01100110/00111100/00000000",
["7"]="01111110/00000110/00001100/00011000/00110000/00110000/00110000/00000000",
["8"]="00111100/01100110/01100110/00111100/01100110/01100110/00111100/00000000",
["9"]="00111100/01100110/01100110/00111110/00000110/00000110/00111100/00000000",
["!"]="00011000/00011000/00011000/00011000/00000000/00011000/00011000/00000000",
["?"]="00111100/01100110/00000110/00001100/00011000/00000000/00011000/00000000",
["_"]="00000000/00000000/00000000/00000000/00000000/00000000/01111110/00000000",
["%"]="01100110/01100100/00001100/00011000/00110000/01001110/01001100/00000000",
["^"]="00011000/00111100/01100110/00000000/00000000/00000000/00000000/00000000",
["#"]="00101000/00101000/01111100/00101000/01111100/00101000/00101000/00000000",
["@"]="00111100/01100110/01111110/01101110/01101110/01100000/00111110/00000000"
}

local font = {}
for ch, encoded in pairs(rawFont) do
    font[ch] = {}
    for line in encoded:gmatch("[^/]+") do
        local row = {}
        for i = 1, #line do
            row[i] = tonumber(line:sub(i, i))
        end
        table.insert(font[ch], row)
    end
end

local blank = {}
for r = 1, 8 do
    blank[r] = {0,0,0,0,0,0,0,0}
end

local function refreshObjects()
    GrabEvents = RS:FindFirstChild("GrabEvents")
    SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
    ToyFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")

    local found = {}
    if ToyFolder then
        for _, obj in ipairs(ToyFolder:GetChildren()) do
            if obj.Name == "MidiMaker" then
                table.insert(found, obj)
            end
        end
    end

    MidiMakers = found
    return SetNetworkOwner ~= nil and #MidiMakers > 0
end

local function rebuildGrid()
    grid = {}
    for i, _ in ipairs(MidiMakers) do
        grid[i] = {}
        for _, r in ipairs(rows) do
            grid[i][r] = {0,0,0,0,0,0,0,0}
        end
    end
end

local function layoutMakers()
    if not ON_HEAD then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local count = #MidiMakers
    if count == 0 then return end

    local dynamicSpacing = tonumber(MAKER_SPACES) or 8
    local firstMaker = MidiMakers[1]
    if firstMaker then
        if firstMaker:IsA("Model") then
            dynamicSpacing = firstMaker:GetExtentsSize().X
        elseif firstMaker:IsA("BasePart") then
            dynamicSpacing = firstMaker.Size.X
        end
    end

    local hrpCFrame = hrp.CFrame
    local flatLook = Vector3.new(hrpCFrame.LookVector.X, 0, hrpCFrame.LookVector.Z).Unit
    local flatRight = Vector3.new(hrpCFrame.RightVector.X, 0, hrpCFrame.RightVector.Z).Unit
    local flatCFrame = CFrame.fromMatrix(hrpCFrame.Position, flatRight, Vector3.new(0, 1, 0), -flatLook)

    for i, maker in ipairs(MidiMakers) do
        if maker and maker.Parent then
            local offsetMultiplier = (i - (count + 1) / 2)
            local relativeOffset = Vector3.new(offsetMultiplier * dynamicSpacing, HEAD_HEIGHT, 0)
            local cf = flatCFrame * CFrame.new(relativeOffset) * CFrame.Angles(math.rad(-90), 0, 0)

            if maker:IsA("Model") then
                maker:PivotTo(cf)
            elseif maker:IsA("BasePart") then
                maker.CFrame = cf
            end
        end
    end
end

local function buildCanvas(text)
    local result = {}
    for r = 1, 8 do
        result[r] = {}
        for _ = 1, 8 do
            table.insert(result[r], 0)
        end
    end

    for i = 1, #text do
        local ch = text:sub(i, i)
        local glyph = font[ch] or blank

        for r = 1, 8 do
            for c = 1, 8 do
                table.insert(result[r], glyph[r][c] or 0)
            end
        end

        local gap = ch == " " and 2 or 1
        if ch == "!" or ch == "?" or ch == "_" or ch == "%" or ch == "^" or ch == "#" or ch == "@" then
            gap = 0
        end
        for r = 1, 8 do
            for _ = 1, gap do
                table.insert(result[r], 0)
            end
        end
    end

    for r = 1, 8 do
        for _ = 1, 8 do
            table.insert(result[r], 0)
        end
    end

    canvas = result
    scrollOffset = 0
end

local function getFrame(offset)
    local frame = {}
    local width = #MidiMakers * 8
    local total = #canvas[1]
    if total == 0 then return frame end

    for r = 1, 8 do
        frame[r] = {}
        for c = 1, width do
            local index = ((offset + c - 1) % total) + 1
            frame[r][c] = canvas[r][index] or 0
        end
    end
    return frame
end

local function drawFrame(frame)
    if not SetNetworkOwner or not SetNetworkOwner.Parent then
        return false
    end

    if #grid ~= #MidiMakers then
        rebuildGrid()
    end

    local totalMakers = #MidiMakers

    for i, maker in ipairs(MidiMakers) do
        if not maker or not maker.Parent then return false end

        local displayOrderIndex = (totalMakers - i)

        for r, rowName in ipairs(rows) do
            for c = 1, 8 do
                local pixel = frame[r] and frame[r][(displayOrderIndex * 8) + c] or 0
                local old = grid[i][rowName][c]

                if pixel ~= old then
                    local part = maker:FindFirstChild(rowName .. c)
                    if part and part:IsA("BasePart") then

                        part.LocalTransparencyModifier = (pixel == 1) and 0 or 1

                        SetNetworkOwner:FireServer(part, part.CFrame)
                        grid[i][rowName][c] = pixel
                    end
                end
            end
        end
    end

    return true
end

buildCanvas(displayText:upper())
refreshObjects()
rebuildGrid()

RunService.Heartbeat:Connect(function()
    if ON_HEAD then
        layoutMakers()
    end

    if not isEnabled then return end

    local calculatedDuration = 0.35 - (math.clamp(tonumber(currentSpeedSetting) or 8, 1, 11) * 0.03)
    if os.clock() - lastUpdate < calculatedDuration then return end
    lastUpdate = os.clock()

    local oldCount = #MidiMakers
    refreshObjects()
    if oldCount ~= #MidiMakers then rebuildGrid() end
    if #MidiMakers == 0 then return end

    drawFrame(getFrame(scrollOffset))
    scrollOffset = (scrollOffset + 1) % #canvas[1]
end)

msection:AddToggle({
    Name = "Enable Drawer",
    Default = false,
    Callback = function(Value)
        isEnabled = Value
    end
})

msection:AddToggle({
    Name = "Ontop head",
    Default = false,
    Callback = function(Value)
        ON_HEAD = Value
    end
})

msection:AddTextbox({
    Name = "Input",
    Default = "Hello123",
    TextDisappear = false,
    Callback = function(Value)
        displayText =Value
    end
})

msection:AddTextbox({
    Name = "Scrollspeed",
    Default = "8",
    TextDisappear = false,
    Callback = function(Value)
        currentSpeedSetting =Value
    end
})

msection:AddTextbox({
    Name = "Spaces",
    Default = "8",
    TextDisappear = false,
    Callback = function(Value)
        MAKER_SPACES = Value
    end
})

local osection = ToyMod:AddSection({
    Name = "Object"
})
local DEADZONE = 5
local MAX_RANGE = 20
local currentTarget = nil

local function getNearestObject(hrp)
    local nearest = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(game.Players.LocalPlayer.Character) and not obj.Anchored then
            local target = obj:FindFirstAncestorOfClass("Model") or obj

            if target ~= currentTarget then
                local distance = (hrp.Position - target:GetPivot().Position).Magnitude

                if distance >= DEADZONE and distance <= MAX_RANGE then
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearest = target
                    end
                end
            end
        end
    end
    return nearest
end

local RunService = game:GetService("RunService")

local DEADZONE = 5
local MAX_RANGE = 20
local currentTarget = nil

local function getNearestObject(hrp)
    local nearest = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(game.Players.LocalPlayer.Character) and not obj.Anchored then
            local target = obj:FindFirstAncestorOfClass("Model") or obj

            if target ~= currentTarget then
                local distance = (hrp.Position - target:GetPivot().Position).Magnitude

                if distance >= DEADZONE and distance <= MAX_RANGE then
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearest = target
                    end
                end
            end
        end
    end
    return nearest
end
_G.headtoggle = false

RunService.Heartbeat:Connect(function()
    if _G.headtoggle then
        local lp = game.Players.LocalPlayer
        local char = lp and lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if hrp and head then
            if not currentTarget then
                currentTarget = getNearestObject(hrp)
            end

            if currentTarget and currentTarget:GetPivot() then
                local sizeY = (currentTarget:IsA("Model") and currentTarget:GetExtentsSize().Y or currentTarget.Size.Y) + 5
                local targetPos = head.CFrame * CFrame.new(0, (sizeY / 2) + 15, 0)
                local targetVelo = head.AssemblyLinearVelocity
                local targetAVelo = v4

                attemptowner_move(true, targetPos, targetVelo, targetAVelo, currentTarget)
            end
        end
    else
        currentTarget = nil
    end
end)

osection:AddToggle({
   Name = "obj on head (can fling)",
   Default = false,
   Callback = function(Value)
       _G.headtoggle = Value
   end,
})

local rsection = ToyMod:AddSection({
    Name = "Miscallenious"
})

local currentLuauCode = ""
local isSpamming = false

pcall(function()
	local fn = ScriptStuff.AddTextbox or ScriptStuff.AddTextBox
	if fn then
		fn(ScriptStuff, {
			Name = "Enter Luau Code",
			Default = "",
			TextDisappear = false,
			Callback = function(Value)
				currentLuauCode = Value
			end
		})
	end
end)

ScriptStuff:AddToggle({
	Name = "Spam Script (No Delay / Safe)",
	Default = false,
	Callback = function(Value)
		isSpamming = Value
		if isSpamming then
			task.spawn(function()
				while isSpamming do
					if currentLuauCode ~= "" then
						pcall(function()
							local func, err = loadstring(currentLuauCode)
							if func then
								func()
							else
								warn("Luau Compile Error: " .. tostring(err))
							end
						end)
					end
					task.wait()
				end
			end)
		end
	end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_EVENTS_PER_SECOND = 25
local VOLATILITY_THRESHOLD = 50000
local BLOCK_DURATION = 30
local PING_SPIKE_THRESHOLD = 0.150

local eventTracker = {}
local LocalPlayer = Players.LocalPlayer

local initialPing = LocalPlayer and LocalPlayer:GetNetworkPing() or 0.05

local function getMagnitude(param)
    if typeof(param) == "Vector3" then
        return param.Magnitude
    elseif typeof(param) == "CFrame" then
        return param.Position.Magnitude
    elseif type(param) == "number" then
        return math.abs(param)
    end
    return 0
end

task.spawn(function()
    while true do
        if LocalPlayer then

            local currentPing = LocalPlayer:GetNetworkPing()
            if currentPing > (initialPing + PING_SPIKE_THRESHOLD) then
                if OrionLib then
                    OrionLib:MakeNotification({
                        Name = "⚠️ Packet Network Lag!",
                        Content = string.format("Current Client Latency: %.1f ms\nNetwork pipeline stalling.", currentPing * 1000),
                        Image = "rbxassetid://4483345998",
                        Time = 3
                    })
                end
            end
        end
        task.wait(2)
    end
end)

local function shouldBlockEvent(senderPlayer, ...)
    local senderName = senderPlayer and senderPlayer.Name or "Unknown"
    local currentTime = os.clock()

    if not eventTracker[senderName] then
        eventTracker[senderName] = { timestamps = {}, lastMagnitude = nil, blockedUntil = 0 }
    end

    local tracker = eventTracker[senderName]

    if currentTime < tracker.blockedUntil then
        return true
    end

    table.insert(tracker.timestamps, currentTime)

    while #tracker.timestamps > 0 and (currentTime - tracker.timestamps[1]) > 1 do
        table.remove(tracker.timestamps, 1)
    end

    local args = {...}
    local currentMagnitude = getMagnitude(args[1])
    local volatile = false
    local delta = 0

    if tracker.lastMagnitude and currentMagnitude > 0 then
        delta = math.abs(currentMagnitude - tracker.lastMagnitude)
        if delta > VOLATILITY_THRESHOLD then
            volatile = true
        end
    end

    tracker.lastMagnitude = currentMagnitude

    if #tracker.timestamps > MAX_EVENTS_PER_SECOND and volatile then
        tracker.blockedUntil = currentTime + BLOCK_DURATION
        table.clear(tracker.timestamps)

        if OrionLib then
            OrionLib:MakeNotification({
                Name = "🛡️ Network Block Active",
                Content = string.format("Dropped [%s] incoming events for %ds.\nDelta Shift: %.1f", senderName, BLOCK_DURATION, delta),
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
        return true
    end

    return false
end

local GrabLineEvent = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("CreateGrabLine")

if GrabLineEvent and GrabLineEvent:IsA("RemoteEvent") then
    GrabLineEvent.OnClientEvent:Connect(function(sender, ...)

        local playerInstance = nil
        if typeof(sender) == "Instance" and sender:IsA("Player") then
            playerInstance = sender
        elseif typeof(sender) == "string" then
            playerInstance = Players:FindFirstChild(sender)
        end

        if playerInstance then
            if shouldBlockEvent(playerInstance, ...) then
                return
            end
        end
    end)
    print("[Shield Ready] Network filters and layout modules initialized.")
else
    warn("[Path Error] Could not find the CreateGrabLine remote event path.")
end


-- Assumed pre-defined variables from your environment:
-- local OrionLib = ...
-- local Tab = OrionLib:MakeTab({Name = "ScriptStuff", Icon = "rbxassetid://4483345998"})

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local activeHighlights = {}
local scanConnection = nil
local heartbeatConnection = nil
local isHighlightEnabled = false

-- Dynamic cleanup function
local function clearHighlights()
	for i = #activeHighlights, 1, -1 do
		local box = activeHighlights[i]
		if box then
			box:Destroy()
		end
		table.remove(activeHighlights, i)
	end
end

-- Logic to apply a bounding box to a target instance
local function applyHighlight(desc)
	if not isHighlightEnabled then return end
	if desc.Name == "PlayerCharacterLocationDetector" or desc.Name == "PCLD" then
		if not desc:FindFirstChild("PermanentAetherBox") then
			local box = Instance.new("SelectionBox")
			box.Name = "PermanentAetherBox"
			box.Adornee = desc
			box.LineThickness = 0.08
			box.Parent = desc
			table.insert(activeHighlights, box)
		end
	end
end

ScriptStuff:AddToggle({
	Name = "Rainbow PCLD Box",
	Default = false,
	Callback = function(Value)
		isHighlightEnabled = Value

		if isHighlightEnabled then
			-- 1. Scan everything currently in the workspace
			for _, desc in ipairs(Workspace:GetDescendants()) do
				applyHighlight(desc)
			end

			-- 2. Hook listener for future runtime additions
			scanConnection = Workspace.DescendantAdded:Connect(applyHighlight)

			-- 3. Run the rainbow color updates
			heartbeatConnection = RunService.Heartbeat:Connect(function()
				local hue = (os.clock() % 4) / 4
				local rainbowColor = Color3.fromHSV(hue, 1, 1)
				
				for i = #activeHighlights, 1, -1 do
					local box = activeHighlights[i]
					if box and box.Parent then
						box.Color3 = rainbowColor
					else
						table.remove(activeHighlights, i)
					end
				end
			end)
		else
			-- Disconnect listeners immediately to save processing power
			if scanConnection then
				scanConnection:Disconnect()
				scanConnection = nil
			end
			if heartbeatConnection then
				heartbeatConnection:Disconnect()
				heartbeatConnection = nil
			end
			
			-- Wipe out all existing selection boxes cleanly
			clearHighlights()
		end
	end    
})

-- Shuriken Anti-Kick Detection and Tracking Engine
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local trackedShurikens = {}

-- Optional: Play an alert sound when a player is caught exploiting
local function playDetectionSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://79150789336480" -- Delta Bell Alert
	s.Volume = 4
	s.PlayOnRemove = true
	s.Parent = SoundService
	s:Destroy()
end

-- Generates a persistent notification through your existing Orion Engine
local function notifyShurikenUser(displayName, username)
	pcall(function()
		OrionLib:MakeNotification({
			Name = "⚠️ Shuriken Anti-Kick Detected!",
			Content = displayName .. " (@" .. username .. ") is using Shuriken Anti-Kick protection.",
			Image = "rbxassetid://4483345998",
			Time = 6
		})
	end)
end

-- Determines who the hidden shuriken is glued to by analyzing its Weld structure
-- Shuriken Anti-Kick Detection and Tracking Engine (Orion Native)
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local trackedShurikens = {}

-- Optional: Play a bell alert sound when a player is caught exploiting
local function playDetectionSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://79150789336480" -- Delta Bell Alert
	s.Volume = 4
	s.PlayOnRemove = true
	s.Parent = SoundService
	s:Destroy()
end

-- Generates a persistent notification through the Orion Engine UI
local function notifyShurikenUser(displayName, username)
	pcall(function()
		OrionLib:MakeNotification({
			Name = "Antikick detected",
			Content = displayName .. " (@" .. username .. ") is using Shuriken Anti-Kick.",
			Image = "rbxassetid://4483345998",
			Time = 6
		})
	end)
end

-- Determines who the hidden shuriken is glued to by analyzing its Weld structure
local function getShurikenOwner(shuriken)
	local stickyPart = shuriken:FindFirstChild("StickyPart")
	if stickyPart then
		local weld = stickyPart:FindFirstChild("StickyWeld") or stickyPart:FindFirstChildWhichIsA("Weld") or stickyPart:FindFirstChildWhichIsA("WeldConstraint")
		if weld and weld.Part1 then
			local possibleChar = weld.Part1.Parent
			if possibleChar and possibleChar:FindFirstChildOfClass("Humanoid") then
				return Players:GetPlayerFromCharacter(possibleChar)
			end
		end
	end
	return nil
end

-- Applies visual tracing highlights and tracks the shuriken object
local function handleNewShuriken(obj)
	if obj.Name == "NinjaShuriken" or obj.Name == "AntiKick" or obj.Name == "Noclipped" then
		task.wait(0.2) -- Brief pause to allow the exploiter's script to finish welding it
		
		if trackedShurikens[obj] then return end
		trackedShurikens[obj] = true
		
		-- Identify the exploiter
		local targetPlayer = getShurikenOwner(obj)
		if targetPlayer and targetPlayer ~= Players.LocalPlayer then
			playDetectionSound()
			notifyShurikenUser(targetPlayer.DisplayName, targetPlayer.Name)
			print("[Anti-Cheat] Detected Shuriken Anti-Kick on: " .. targetPlayer.Name)
		end

		-- Apply the visual ESP highlighting
		for _, part in ipairs(obj:GetChildren()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				
				-- Break the script's local invisibility desync to reveal it to you
				part.Transparency = 0.4 
				
				-- Apply permanent visual tracking box container
				if not part:FindFirstChild("ShurikenTrackerBox") then
					local box = Instance.new("SelectionBox")
					box.Name = "ShurikenTrackerBox"
					box.Adornee = part
					box.LineThickness = 0.08
					box.Parent = part
				end
			end
		end
	end
end

-- Connect real-time listeners for instant runtime additions
workspace.ChildAdded:Connect(handleNewShuriken)
workspace.DescendantAdded:Connect(handleNewShuriken)

-- Check everything currently loaded in the workspace upon script execution
for _, desc in ipairs(workspace:GetDescendants()) do
	handleNewShuriken(desc)
end

    
pcall(function() OrionLib:Init() end)
print("[Aether] Init done")
end
local ok1, e1 = pcall(AetherPart1)
if not ok1 then warn("[Aether] Part1:", e1) end
local ok2, e2 = pcall(AetherPart2)
if not ok2 then warn("[Aether] Part2:", e2) end