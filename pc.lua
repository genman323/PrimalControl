local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game.Workspace
local VirtualInputManager = game:GetService("VirtualInputManager")
local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")

local LocalPlayer = Players.LocalPlayer

if game.PlaceId ~= 12076775711 then
    LocalPlayer:Kick("Wrong game")
    return
end

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local prefix = "."

local farmConn = nil
local lastShoot = 0
local lastPos = nil
local farming = false
local cam = Workspace.CurrentCamera

local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

local function updateChar()
    character = LocalPlayer.Character
    if character then
        root = character:FindFirstChild("HumanoidRootPart")
        humanoid = character:FindFirstChild("Humanoid")
    end
end

local function stopFarm()
    farming = false
    if farmConn then
        farmConn:Disconnect()
        farmConn = nil
    end
    if humanoid then
        humanoid.PlatformStand = false
    end
    local anim = character and character:FindFirstChild("Animate")
    if anim then
        anim.Enabled = true
    end
end

local function isDino()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Dinosaurs"
end

local function getAliveDinos()
    local dinos = {}
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Dinosaurs" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(dinos, p)
        end
    end
    return dinos
end

local function getNearestDino(dinos)
    if #dinos == 0 then return nil end
    local nearest = dinos[1]
    local dist = (root.Position - nearest.Character.HumanoidRootPart.Position).Magnitude
    for _, d in dinos do
        local ddist = (root.Position - d.Character.HumanoidRootPart.Position).Magnitude
        if ddist < dist then
            dist = ddist
            nearest = d
        end
    end
    return nearest
end

local function findEscapePrompt()
    for _, v in Workspace:GetDescendants() do
        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("board") or v.ActionText:lower():find("escape") or v.ActionText:lower():find("heli") or v.ActionText:lower():find("enter")) then
            return v
        end
    end
end

local function escape(prompt)
    stopFarm()
    if root and prompt.Parent then
        root.CFrame = prompt.Parent.CFrame * CFrame.new(0, 3, 0)
        task.wait(0.1)
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 1)
        prompt:InputHoldEnd()
    end
end

local function farmUpdate()
    updateChar()
    if not character or not root or not humanoid or humanoid.Health <= 0 then
        stopFarm()
        return
    end
    if isDino() then
        humanoid.Health = 0
        return
    end

    local prompt = findEscapePrompt()
    if prompt then
        escape(prompt)
        return
    end

    local dinos = getAliveDinos()
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        pressKey("One")
        task.wait(0.5)
    end

    local nearest = nil
    if #dinos > 0 then
        nearest = getNearestDino(dinos)
        local dpos = nearest.Character.HumanoidRootPart.Position
        lastPos = dpos
        local mypos = dpos + Vector3.new(math.random(-2,2), 50, math.random(-2,2))
        local lookat = nearest.Character:FindFirstChild("Head") and nearest.Character.Head.Position or nearest.Character.HumanoidRootPart.Position
        root.CFrame = CFrame.lookAt(mypos, lookat)
    elseif lastPos then
        local mypos = lastPos + Vector3.new(0, 5, 0)
        root.CFrame = CFrame.new(mypos)
    end

    root.Velocity = Vector3.new()
    cam.CameraType = Enum.CameraType.Scriptable
    if nearest then
        local lookat = nearest.Character:FindFirstChild("Head") and nearest.Character.Head.Position or nearest.Character.HumanoidRootPart.Position
        cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 2, 0), lookat)
    end

    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true

    local now = tick()
    if nearest and tool and now - lastShoot >= 0.35 then
        tool:Activate()
        lastShoot = now
    end
end

local function startFarm()
    if farming then return end
    farming = true
    farmConn = RunService.Heartbeat:Connect(farmUpdate)
end

local function findJungleButton()
    for _, obj in Workspace:GetDescendants() do
        local name = obj.Name:lower()
        if (name:find("jungle") or (obj.Parent and obj.Parent.Name:lower():find("jungle"))) and obj:IsA("BasePart") and obj:FindFirstChildOfClass("ClickDetector") then
            return obj
        end
    end
end

task.spawn(function()
    while true do
        task.wait(3)
        local button = findJungleButton()
        if button and root then
            local oldCFrame = root.CFrame
            root.CFrame = button.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0)
            task.wait(0.1)
            local cd = button:FindFirstChildOfClass("ClickDetector")
            if cd then
                fireclickdetector(cd)
            end
            task.wait(0.3)
            root.CFrame = oldCFrame
        end
    end
end)

local function hideCam()
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(0, -5000000, 0)
    task.spawn(function()
        while task.wait(120 + math.random(-40, 60)) do
            mousemoverel(2, 0)
            task.wait(0.1)
            mousemoverel(-2, 0)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    updateChar()
    stopFarm()
    task.wait(5)
    pressKey("E")
    task.wait(0.5)
    pressKey("One")
    startFarm()
    hideCam()
end)

hideCam()
print("PrimalAutofarm Loaded [Primal Pursuit]")

return {
    Begin = function() end,
    Init = function() end,
    Load = function() end,
    Start = function() end,
    Show = function() end
}
