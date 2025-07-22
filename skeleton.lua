-- Skeleton ESP Library by Blissful#4992

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

local BONES = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" }
}

get("player").new = function(self, player)
	local function cache(character)
		local drawings = {}
		for i, v in ipairs(BONES) do
			drawings["bone" .. i] = get("new").drawing("Line", { Visible = false, Thickness = 2 })
		end
		self.cache[character] = { ["player"] = player, ["drawings"] = drawings }
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
	local player = data.player; local drawings = data.drawings
	if self:check(client) then data.distance = (client.Character.HumanoidRootPart.CFrame.Position - character.HumanoidRootPart.CFrame.Position).Magnitude end

	task.spawn(function()
		local visuals = features.visuals
		local function check() local team; if visuals.teamCheck then team = player.Team ~= client.Team else team = true end; return visuals.enabled and data.distance and data.distance <= visuals.renderDistance and team end
		local function color(color) if visuals.teamColor then color = player.TeamColor.Color end; return color end

		local allVisible = true
		local partPositions = {}

		for _, v in ipairs(BONES) do
			for _, partName in ipairs(v) do
				if not partPositions[partName] then
					local part = character:FindFirstChild(partName)
					if part then
						local pos, onScreen = camera:WorldToViewportPoint(part.Position)
						if onScreen then partPositions[partName] = Vector2.new(pos.X, pos.Y)
						else allVisible = false; break end
					else allVisible = false; break end
				end
			end
			if not allVisible then break end
		end

		if allVisible and check() then
			for i, v in ipairs(BONES) do
				local line = drawings["bone" .. i]
				line.From = partPositions[v[1]]
				line.To = partPositions[v[2]]
				line.Color = color(visuals.skeleton.color)
				line.Visible = true
			end
		else
			for _, line in pairs(drawings) do line.Visible = false end
		end
	end)
end

declare(get("player"), "loop", get("loop"):new(function () for character, data in get("player").cache do get("player"):update(character, data) end end, true)) -- Starts disabled
declare(global, "features", {})

features.toggle = function(self, feature, boolean)
	if self[feature] then
		local enabled = if boolean == nil then not self[feature].enabled else boolean
		self[feature].enabled = enabled
		get("player").loop:toggle(enabled)

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
	["skeleton"] = { ["enabled"] = true, ["color"] = Color3.fromRGB(0, 255, 0) }
})

for _, player in players:GetPlayers() do if player ~= client and not get("player"):find(player) then get("player"):new(player) end end
declare(get("player"), "added", players.PlayerAdded:Connect(function(player) get("player"):new(player) end), true)
declare(get("player"), "removing", players.PlayerRemoving:Connect(function(player) get("player"):remove(player) end), true)

return features
