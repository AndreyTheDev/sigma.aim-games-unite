local Camera = workspace.CurrentCamera
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

if game.gameID == 2746687316 then
    print("[SIGMA]: SigmaLoader V1: SIgma.Aim")
else
    error("[SIGMA]: wrong placee")
end

local Client = {}
for _, v in next, getgc(true) do
    if (type(v) == 'table') then
        if (rawget(v, 'Fire') and type(rawget(v, 'Fire')) == 'function' and not Client.Bullet) then
            Client.Bullet = v
        elseif (rawget(v, 'HiddenUpdate')) then
            Client.Players = debug.getupvalue(rawget(v, 'new'), 9)
        end
    end
end

function Client:GetPlayerHitbox(player, hitbox)
    for _, player_hitbox in next, player.Hitboxes do
        if (player_hitbox._name == hitbox) then
            return player_hitbox
        end
    end
end

function Client:GetClosestPlayerFromCursor()
    local nearest_player, min_magnitude = nil, math.huge
    for _, player in next, Client.Players do
        if player.PlayerModel and player.PlayerModel.Model.Head.Transparency ~= 1 then
            local screen_pos, is_visible = Camera:WorldToViewportPoint(player.Position)
            if is_visible then
                local magnitude = (UserInputService:GetMouseLocation() - Vector2.new(screen_pos.X, screen_pos.Y)).Magnitude
                if magnitude < min_magnitude then
                    min_magnitude = magnitude
                    nearest_player = player
                end
            end
        end
    end
    return nearest_player
end

function Client:GetTargetHitbox(target)
    for _, hitbox in next, {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"} do
        local player_hitbox = Client:GetPlayerHitbox(target, hitbox)
        if player_hitbox then
            return player_hitbox
        end
    end
    return nil
end

local botEnabled = true
local espEnabled = true
local espObjects = {}
local currentTarget = nil

local function sendNotification(title, text, duration)
    local bindableFunction = Instance.new("BindableFunction")
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
        callback = bindableFunction,
    })
end

sendNotification("Sigma", "🎉 SigmaAIM loaded! Press T to toggle aimbot, P to toggle ESP.", 8)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.T then
            botEnabled = not botEnabled
            sendNotification("Sigma", botEnabled and "Aimbot enabled 💎" or "Aimbot disabled 🛑", 5)
        elseif input.KeyCode == Enum.KeyCode.P then
            espEnabled = not espEnabled
            sendNotification("Sigma", espEnabled and "ESP enabled 👁️" or "ESP disabled 🛑", 5)
            if not espEnabled then
                for _, esp in pairs(espObjects) do
                    if esp then
                        esp.highlight:Destroy()
                    end
                end
                espObjects = {}
            end
        end
    end
end)

local function createESP(player)
    if espEnabled and player.PlayerModel then
        local highlight = Instance.new("Highlight")
        highlight.Parent = player.PlayerModel.Model
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.FillTransparency = 0.3
        highlight.OutlineColor = Color3.new(0.5, 0, 0)
        highlight.OutlineTransparency = 0

        espObjects[player] = {highlight = highlight}

        local tweenInfoIn = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tweenIn = TweenService:Create(highlight, tweenInfoIn, {FillTransparency = 0.3})
        tweenIn:Play()

        local colorTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
        local colorTween = TweenService:Create(highlight, colorTweenInfo, {OutlineColor = Color3.new(1, 0, 0)})
        colorTween:Play()
    end
end

local function cleanupESP(player)
    if espObjects[player] then
        local highlight = espObjects[player].highlight
        highlight:Destroy()
        espObjects[player] = nil
    end
end

local function updateESP()
    for _, player in next, Client.Players do
        if player.PlayerModel and not player.Dead and not espObjects[player] then
            createESP(player)
        elseif not player.PlayerModel or player.Dead then
            cleanupESP(player)
        end
    end
end

local function updateTargetHighlight(target)
    for player, data in pairs(espObjects) do
        local highlight = data.highlight
        if player == target then
            highlight.OutlineColor = Color3.new(1, 1, 0)
        else
            highlight.OutlineColor = Color3.new(0.5, 0, 0)
        end
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        wait(1)
        createESP(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end
end)

Fire = hookfunction(Client.Bullet.Fire, function(self, ...)
    local args = {...}

    if botEnabled then
        local target = Client:GetClosestPlayerFromCursor()
        local targetHitbox = target and Client:GetTargetHitbox(target)

        if targetHitbox then
            args[2] = (CFrame.new(Camera.CFrame.Position, targetHitbox.CFrame.Position)).LookVector
            currentTarget = target
            updateTargetHighlight(target)
        else
            currentTarget = nil
            updateTargetHighlight(nil)
            return
        end
    else
        return
    end

    return Fire(self, unpack(args))
end)
