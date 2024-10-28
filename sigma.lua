local Camera = workspace.CurrentCamera
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local Client = {}
do
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
        for _, hitbox in next, {"Head", "Torso", "LeftArm", "RightArm"} do
            local player_hitbox = Client:GetPlayerHitbox(target, hitbox)
            if player_hitbox then
                return player_hitbox
            end
        end
        return nil
    end
end

local botEnabled = true
local espEnabled = true
local espObjects = {}

local function sendNotification(title, text, duration)
    local bindableFunction = Instance.new("BindableFunction")
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
        callback = bindableFunction,
    })
end

sendNotification("Sigma", "🎉 Sigma loaded! Enjoy! Press T to toggle aimbot, P to toggle ESP.", 8)
print("[SIGMA]: Sigma.Aim v0.1.3 loaded! Yeeeeeeee")

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

local function createOrUpdateESP(player)
    if espEnabled and player.PlayerModel then
        if not espObjects[player] then
            local highlight = Instance.new("Highlight")
            highlight.Parent = player.PlayerModel.Model
            highlight.FillColor = Color3.new(1, 0, 0)
            highlight.FillTransparency = 0.3
            highlight.OutlineColor = Color3.new(0.5, 0, 0)
            highlight.OutlineTransparency = 0

            espObjects[player] = {highlight = highlight}

            highlight.FillTransparency = 1
            local tweenInfoIn = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tweenIn = TweenService:Create(highlight, tweenInfoIn, {FillTransparency = 0.3})
            tweenIn:Play()
        end
    end
end

local function cleanupESP(player)
    if espObjects[player] then
        local highlight = espObjects[player].highlight

        local tweenInfoOut = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tweenOut = TweenService:Create(highlight, tweenInfoOut, {FillTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Wait()

        highlight:Destroy()
        espObjects[player] = nil
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1)
        createOrUpdateESP(player)
    end)
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if espEnabled then
        for _, player in next, Client.Players do
            if player.PlayerModel and not player.Dead then
                createOrUpdateESP(player)
            else
                cleanupESP(player)
            end
        end
    end
end)

Fire = hookfunction(Client.Bullet.Fire, function(self, ...)
    local args = {...}

    if botEnabled then
        local target = Client:GetClosestPlayerFromCursor()
        local targetHitbox = target and Client:GetTargetHitbox(target)

        if targetHitbox then
            args[2] = CFrame.new(Camera.CFrame.Position, targetHitbox.CFrame.Position).LookVector
        end
    end

    return Fire(self, unpack(args))
end)
