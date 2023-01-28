if(not owner)then
	getfenv(1).owner = script.Parent:IsA("PlayerGui") and script.Parent.Parent or game:GetService('Players'):GetPlayerFromCharacter(script.Parent)
end
if(not NLS)then
	getfenv(1).NLS = function() end
end
local plr : Player = owner
local chr : Model = owner.Character
local hum : Humanoid = chr:FindFirstChildOfClass("Humanoid")
local animate = chr:FindFirstChild("Animate")
local tweening = true
function getData(name : string)
	local data = game:GetService('HttpService'):GetAsync("https://raw.githubusercontent.com/TheFakeFew/R6Emotes/main/"..(name or "")..".lua")
	local DATA = loadstring(data or "")()
	return DATA or nil
end
NLS([[
	local chr = owner.Character
	local hum = chr:FindFirstChildOfClass("Humanoid")
	for i,v in next, hum.Animator:GetPlayingAnimationTracks() do
		v:Stop()
	end
]],chr)
task.wait(.3)
local anims = {}
local welds = {}
local tweens = {}
for i,v in next, chr:GetDescendants() do
	if(v:IsA("JointInstance") and not v:FindFirstAncestorOfClass("Accessory"))then
		welds[v.Part1.Name or ""] = v
	end
end

local origc0s = {}
for i,v in next, welds do
	origc0s[i] = v.C0
end

function stopAnims()
	coroutine.wrap(function()
		NLS([[
	    local chr = owner.Character
	    local hum = chr:FindFirstChildOfClass("Humanoid")
	    for i,v in next, hum.Animator:GetPlayingAnimationTracks() do
	    	v:Stop()
	    end
    ]],chr)
	end)()
	for i,v in next, anims do
		pcall(function()
			task.cancel(v)
		end)
	end
	task.wait()
	anims = {}
	for i,v in next, tweens do
		pcall(function()
			v:Stop()
		end)
	end
	tweens = {}
	for i,v in next, origc0s do
		welds[i].C0 = v
	end
	if(animate)then
		animate.Disabled = false
	end
end

function setC0s(tbl : {},time,easestyle)
	local anims = tbl["HumanoidRootPart"]
	local function recurse(v)
		for i,v in next, v do
			if(welds[i])then
				if(tweening)then
					pcall(function()
						local tw = game:GetService('TweenService'):Create(welds[i],TweenInfo.new((welds[i].C0.Position - v.CFrame.Position).Magnitude,easestyle),{
							C0 = origc0s[i]*v.CFrame
						})
						tw:Play()
						table.insert(tweens,tw)
					end)
				else
					pcall(function()
						welds[i].C0 = origc0s[i]*v.CFrame
					end)
				end
				recurse(v)
			end
		end
	end
	for i,v in next, anims do
		if(welds[i])then
			if(tweening)then
				pcall(function()
					local tw = game:GetService('TweenService'):Create(welds[i],TweenInfo.new((welds[i].C0.Position - v.CFrame.Position).Magnitude,easestyle),{
						C0 = origc0s[i]*v.CFrame
					})
					tw:Play()
					table.insert(tweens,tw)
				end)
			else
				pcall(function()
					welds[i].C0 = origc0s[i]*v.CFrame
				end)
			end
			recurse(v)
		end
	end
end

function getSongData(songname)
	local json = game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/TheFakeFew/R6Emotes/main/MidiSongs/"..songname..".json")
	if(not json)then
		return nil
	end
	return game:GetService("HttpService"):JSONDecode(json)
end

function getInstruments()
	local data = game:GetService('HttpService'):GetAsync("https://raw.githubusercontent.com/OrangeCash090/MIDI-Player-Roblox/main/Instruments.lua")
	local DATA = loadstring(data or "")()
	return DATA or nil
end

local instrumentsfallback = {
	{"rbxassetid://31173820", "standard kit", settings = {["Gain"] = 0.1}},
	{"rbxassetid://5924276201", "acoustic grand piano", settings = {["Gain"] = 0, ["Offset"] = -7}}
}

local instruments = getInstruments()
if(not instruments or instruments == {})then
	instruments = instrumentsfallback
end

local families = {}

for i,v in next, instruments do
	families[v[2]] = {v[1], settings = v.settings or {}, pitches = v.pitches or {}}
end

function notetopitch(note, offset)
	return (440 / 32) * math.pow(2, ((note + offset) / 12)) / 440
end

local rootpart = chr:WaitForChild("HumanoidRootPart")
local songs = {}
local volmult = 1.5
local looping = true
function playSong(songname)
	coroutine.wrap(function()
		for i,v in next, songs do
			task.cancel(v)
		end
		local data = getSongData(songname)
		if(not data)then
			return
		end
		local tracks = data.tracks
		local function play()
			local notenum = 0
			local numofnotes = 0
			for i,v in next, tracks do
				numofnotes = numofnotes + #v.notes
			end
			for i,v in next, tracks do
				local id = {}
				if(families[v.instrument.name])then
					id = families[v.instrument.name]
				else
					id = families["acoustic grand piano"]
				end
				for i,v in next, v.notes do
					local thread
					thread = task.delay(v.time,function()
						notenum = notenum + 1
						local settings = id.settings
						local snd = Instance.new("Sound",rootpart)
						snd.Volume = v.velocity*volmult
						if(settings and settings["Gain"])then
							snd.Volume += settings["Gain"]
						end
						snd.SoundId = id[1]
						if(id.pitches and id.pitches[v.midi])then
							snd.SoundId = id.pitches[v.midi]
						end
						if(settings and settings["Loop"])then
							snd.Looped = settings["Loop"]
						end
						if(settings and settings["Offset"])then
							snd.Pitch = notetopitch(v.midi,settings["Offset"]) --2^((v.midi-69)/12)
						else
							snd.Pitch = notetopitch(v.midi,0)
						end
						snd.Name = v.name
						snd:Play()
						task.delay(v.duration,function()
							local tw = game:GetService("TweenService"):Create(snd,TweenInfo.new(.1),{
								Volume = 0
							})
							tw:Play()
							tw.Completed:Wait()
							snd:Destroy()
						end)
					end)
					table.insert(songs,thread)
				end
			end
			local function onend()
				if(looping)then play()end
			end
			local endofsongtime = 0
			for i,v in next, tracks do
				for i,v in next, v.notes do
					if((v.time+v.duration) > endofsongtime)then
						endofsongtime = v.time+v.duration
					end
				end
			end
			print(endofsongtime)
			local thread = task.delay(endofsongtime,onend)
			table.insert(songs,thread)
		end
		play()
	end)()
end

function playAnim(name : string)
	stopAnims()
	for i,v in next, songs do
		task.cancel(v)
	end
	local data = getData(name)
	if(not data)then
		return print("Doesnt Exist.")
	end
	if(animate)then
		animate.Disabled = true
	end
	local keyframes = data.Keyframes
	local looping = data.Properties.Looping or false
	local lastt = 0
	local easestyle = Enum.EasingStyle.Linear
	if(data.Properties.Song)then
		playSong(data.Properties.Song)
	end
	local function onend()
		if(looping)then
			anims = {}
			tweens = {}
			local lastkeyframe = 0
			for i,v in next, keyframes do
				if(i>lastkeyframe)then
					lastkeyframe = i
				end
			end
			local thread = task.delay(lastkeyframe,onend)
			table.insert(anims,thread)
			for i,v in next, keyframes do
				local thread
				thread = task.delay(i,function()
					local time = i-lastt
					setC0s(v,i-lastt,easestyle)
					lastt = i
				end)
				table.insert(anims,thread)
			end
		else
			stopAnims()
		end
	end
	local lastkeyframe = 0
	for i,v in next, keyframes do
		if(i>lastkeyframe)then
			lastkeyframe = i
		end
	end
	print(lastkeyframe)
	local thread = task.delay(lastkeyframe,onend)
	table.insert(anims,thread)
	for i,v in next, keyframes do
		local thread 
		thread = task.delay(i,function()
			local time = i-lastt
			setC0s(v,i-lastt,easestyle)
			lastt = i
		end)
		table.insert(anims,thread)
	end
end

owner.Chatted:Connect(function(message)
	if(string.lower(message):sub(1,5)=="anim!")then
		stopAnims()
		playAnim(string.split(message,"!")[2])
	elseif(string.lower(message):sub(1,8)=="tweened!")then
		local t = string.split(message,"!")[2]
		if(t=="false")then
			tweening = false
		else
			tweening = true
		end
		print(tweening)
	end
end)