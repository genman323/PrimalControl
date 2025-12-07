local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game.Workspace
local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

if game.PlaceId ~= 12076775711 then
    LocalPlayer:Kick("Wrong game")
    return
end

if getgenv().script_key ~= "qCqkyJnsIdGuValXkmeYLEcN" or not getgenv().host or getgenv().host == "" then
    LocalPlayer:Kick("Invalid")
    return
end

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local safeConn = nil
local guardConn = nil
local lastSafePos = nil
local isSafe = false
local isGuarding = false
local lastShot = 0
local lastReload = 0
local targetSwitch = 0
local currentTarget = nil
local prefix = "."

local function updateChar()
    character = LocalPlayer.Character
    if character then
        root = character:FindFirstChild("HumanoidRootPart")
        humanoid = character:FindFirstChild("Humanoid")
    end
end

local function stopAll()
    if safeConn then safeConn:Disconnect() safeConn = nil end
    if guardConn then guardConn:Disconnect() guardConn = nil end
    isSafe = false
    isGuarding = false
    if humanoid then humanoid.PlatformStand = false end
    local anim = character and character:FindFirstChild("Animate")
    if anim then anim.Enabled = true end
end

local function goSafe()
    if isSafe then return end
    stopAll()
    lastSafePos = root.Position
    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true
    local sky = Vector3.new(root.Position.X, 500000, root.Position.Z)
    safeConn = RunService.Heartbeat:Connect(function()
        root.CFrame = CFrame.new(sky)
        root.Velocity = Vector3.new()
    end)
    isSafe = true
end

local function goUnsafe()
    if not isSafe or not lastSafePos then return end
    stopAll()
    root.CFrame = CFrame.new(lastSafePos + Vector3.new(0,4,0))
    task.wait(0.1)
    humanoid.PlatformStand = false
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = true end
end

local function getHostChar()
    for _, p in Players:GetPlayers() do
        if p.Name:lower() == getgenv().host:lower() then
            return p.Character
        end
    end
end

local function isDino()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Dinosaurs"
end

local function getVisibleDinos()
    if isDino() then return {} end
    local list = {}
    local head = character:FindFirstChild("Head")
    if not head then return list end
    local hostChar = getHostChar()
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Dinosaurs" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local hrp = p.Character.HumanoidRootPart
            local ray = Workspace:Raycast(head.Position, (hrp.Position - head.Position).Unit * 500, (function()
                local p = RaycastParams.new()
                p.FilterDescendantsInstances = {character, hostChar}
                p.FilterType = Enum.RaycastFilterType.Exclude
                return p
            end)())
            if ray and ray.Instance and ray.Instance:IsDescendantOf(p.Character) then
                table.insert(list, p)
            end
        end
    end
    return list
end

local offset = Vector3.new(math.sin(LocalPlayer.UserId % 100), 0, math.cos(LocalPlayer.UserId % 100)) * 6

local function guardLoop()
    if isDino() then return end
    updateChar()
    if not character or not root or not humanoid or humanoid.Health <= 0 then return end

    local hostChar = getHostChar()
    if not hostChar or not hostChar:FindFirstChild("HumanoidRootPart") or hostChar.Humanoid.Health <= 0 then
        return
    end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end

    local hostRoot = hostChar.HumanoidRootPart
    local myPos = hostRoot.Position + offset + Vector3.new(0, 3, 0)

    local dinos = getVisibleDinos()
    local target = nil
    if #dinos > 0 then
        if #dinos == 1 then
            target = dinos[1]
        else
            local now = tick()
            if now - targetSwitch >= 2 then
                targetSwitch = now
                currentTarget = dinos[math.random(1, #dinos)]
            end
            target = currentTarget
        end
    end

    local lookAt
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        lookAt = target.Character.HumanoidRootPart.Position
        local now = tick()
        if now - lastShot >= 0.3 then
            lastShot = now
            if tool then tool:Activate() end
        end
        if now - lastReload >= 5.5 then
            lastReload = now
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end
    else
        local dir = (myPos - hostRoot.Position).Unit
        lookAt = myPos + dir * 40
    end

    root.CFrame = CFrame.lookAt(myPos, lookAt)
    root.Velocity = Vector3.new()

    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true
end

local function startGuard()
    if isDino() then return end
    stopAll()
    isGuarding = true
    guardConn = RunService.Heartbeat:Connect(guardLoop)
end

local function stopGuard()
    isGuarding = false
    stopAll()
    if humanoid then humanoid.Health = 0 end
end

local function process(msg)
    msg = msg:lower()
    if not msg:startswith(prefix) then return end
    local cmd = msg:sub(#prefix + 1):match("^%s*(.-)%s*$")

    if cmd == "safe" then goSafe()
    elseif cmd == "unsafe" then goUnsafe()
    elseif cmd == "guard" then startGuard()
    elseif cmd == "unguard" then stopGuard()
    end
end

local function onMsg(plr, text)
    if plr and plr.Name:lower() == getgenv().host:lower() then
        pcall(process, text)
    end
end

if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
    TextChatService.TextChannels.RBXGeneral.MessageReceived:Connect(function(m)
        if m.TextSource then
            local p = Players:GetPlayerByUserId(m.TextSource.UserId)
            if p then onMsg(p, m.Text) end
        end
    end)
end

Chat.Chatted:Connect(onMsg)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    updateChar()
    stopAll()
    task.wait(1)
    if isGuarding and not isDino() then
        guardConn = RunService.Heartbeat:Connect(guardLoop)
    end
end)

print("PrimalControl Loaded [Primal Pursuit]")

return {
    Begin = function() end,
    Init = function() end,
    Load = function() end,
    Start = function() end,
    Show = function() end
}
