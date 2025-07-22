

local players = cloneref(game:GetService("Players"))
local client = players.LocalPlayer
local camera = workspace.CurrentCamera

getgenv().global = getgenv()

function global.declare(self, index, value, check)
	if self[index] == nil then self[index] = value elseif check then local methods = { "remove", "Disconnect" }; for _, method in methods do pcall(function() value[method](value) end) end end; return self[index]
end

declare(global, "services", {})
function global.get(service) return services[service] end
declare(declare(services, "loop", {}), "cache", {})

get("loop").new = function(self, index, func, disabled)
	if disabled == nil and (func == nil or typeof(func) == "boolean") then disabled = func func = index end
	self.cache[index] = { ["enabled"] = (not disabled), ["func"] = func, ["toggle"] = function(self, boolean) if boolean == nil then self.enabled = not self.enabled else self.enabled = boolean end end, ["remove"] = function() self.cache[index] = nil end }; return self.cache[index]
end

declare(get("loop"), "connection", cloneref(game:GetService("RunService")).RenderStepped:Connect(function(delta)
	for _, loop in get("loop").cache do if loop.enabled then local success, result = pcall(function() loop.func(delta) end); if not success then warn(result) end end end
end), true)

declare(services, "new", {})
get("new").drawing = function(class, properties)
	local drawing = Drawing.new(class); for property, value in properties do pcall(function() drawing[property] = value end) end; return drawing
end

declare(declare(services, "player", {}), "cache", {})
get("player").find = function(self, player) for character, data in self.cache do if data.player == player then return character end end end
get("player").check = function(self, player)
	local success, check = pcall(function() local character = player:IsA("Player") and player.Character or player; local children = { character.Humanoid, character.HumanoidRootPart }; return children and character.Parent ~= nil end); return success and check
end

get("player").new = function(self, player)
	local function cache(character)
		self.cache[character] = { ["player"] = player, ["drawings"] = { ["name"] = get("new").drawing("Text", { Visible = false, Center = true, Font = Drawing.Fonts.Plex }) } }
	end
	local function check(character) if self:check(character) then cache(character) else local listener; listener = character.ChildAdded:Connect(function() if self:check(character) then cache(character) listener:Disconnect() end end) end end
	if player.Character then check(player.Character) end; player.CharacterAdded:Connect(check)
end

get("player").remove = function(self, player)
	if player:IsA("Player") then local character = self:find(player); if character then self:remove(character) end
	else local drawings = self.cache[player].drawings; self.cache[player] = nil; for _, drawing in drawings do drawing:Remove() end end
end

get("player").update = function(self, character, data)
	if not self:check(character) then self:remove(character) end
	local player = data.player; local root = character.HumanoidRootPart; local drawings = data.drawings
	if self:check(client) then data.distance = (client.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude end

	task.spawn(function()
		local position, visible = camera:WorldToViewportPoint(root.CFrame.Position)
		local visuals = features.visuals
		local function check() local team; if visuals.teamCheck then team = player.Team ~= client.Team else team = true end; return visuals.enabled and data.distance and data.distance <= visuals.renderDistance and team end
		local function color(color) if visuals.teamColor then color = player.TeamColor.Color end; return color end

		if visible and check() then
			local scale = 1 / (position.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
			local height = math.floor(6 * scale); local y = math.floor(position.Y); local x = math.floor(position.X)
			local yPostion = math.floor((y - height * 0.5) + (0.5 * scale))

			drawings.name.Text = `[ {player.Name} ]`
			drawings.name.Size = math.max(math.min(math.abs(12.5 * scale), 12.5), 10)
			drawings.name.Position = Vector2.new(x, (yPostion - drawings.name.TextBounds.Y) - 2)
			drawings.name.Color = color(visuals.names.color)
			drawings.name.Outline = visuals.names.outline.enabled
			drawings.name.OutlineColor = visuals.names.outline.color
		end
		drawings.name.Visible = (check() and visible and visuals.names.enabled)
	end)
end

declare(get("player"), "loop", get("loop"):new(function () for character, data in get("player").cache do get("player"):update(character, data) end end, true)) -- Starts disabled
declare(global, "features", {})

features.toggle = function(self, feature, boolean)
	if self[feature] then
		local enabled = if boolean == nil then not self[feature].enabled else boolean
		self[feature].enabled = enabled
		get("player").loop:toggle(enabled)

		--// [FIX] If disabling, iterate through all drawings and hide them.
		if not enabled then
			for _, data in get("player").cache do
				for _, drawing in data.drawings do
					drawing.Visible = false
				end
			end
		end
	end
end

declare(features, "visuals", {
	["enabled"] = false, ["teamCheck"] = false, ["teamColor"] = true, ["renderDistance"] = 2000,
	["names"] = { ["enabled"] = true, ["color"] = Color3.fromRGB(255, 255, 255), ["outline"] = { ["enabled"] = true, ["color"] = Color3.fromRGB(0, 0, 0) } }
})

for _, player in players:GetPlayers() do if player ~= client and not get("player"):find(player) then get("player"):new(player) end end
declare(get("player"), "added", players.PlayerAdded:Connect(function(player) get("player"):new(player) end), true)
declare(get("player"), "removing", players.PlayerRemoving:Connect(function(player) get("player"):remove(player) end), true)

return features
