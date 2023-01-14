if(not owner)then
	getfenv(1).owner = script.Parent:IsA("PlayerGui") and script.Parent.Parent or game:GetService('Players'):GetPlayerFromCharacter(script.Parent)
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
wait()
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
    NLS([[
	    local chr = owner.Character
	    local hum = chr:FindFirstChildOfClass("Humanoid")
	    for i,v in next, hum.Animator:GetPlayingAnimationTracks() do
	    	v:Stop()
	    end
    ]],chr)
	for i,v in next, anims do
		pcall(function()
			task.cancel(v)
		end)
	end
    for i,v in next, tweens do
        pcall(function()
            v:Stop()
        end)
    end
    for i,v in next, origc0s do
        welds[i].C0 = v
    end
end

function setC0s(tbl : {},time,easestyle)
	local anims = tbl["HumanoidRootPart"]
	for i,v in next, anims do
		if(welds[i])then
			if(tweening)then
				local tw = game:GetService('TweenService'):Create(welds[i],TweenInfo.new(time,easestyle),{
					C0 = origc0s[i]*v.CFrame
				})
                tw:Play()
                table.insert(tweens,tw)
			else
				welds[i].C0 = origc0s[i]*v.CFrame
			end
		end
		for i,v in next, v do
			if(welds[i])then
				if(tweening)then
					local tw = game:GetService('TweenService'):Create(welds[i],TweenInfo.new(time,easestyle),{
                        C0 = origc0s[i]*v.CFrame
                    })
                    tw:Play()
                    table.insert(tweens,tw)
				else
					welds[i].C0 = origc0s[i]*v.CFrame
				end
			end
		end
	end
end

function playAnim(name : string)
	stopAnims()
	if(animate)then
		animate.Disabled = false
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
	local function onend()
		if(looping)then
			local lastkeyframe = 0
			for i,v in next, keyframes do
				if(i>lastkeyframe)then
					lastkeyframe = i
				end
			end
			local thread = task.delay(lastkeyframe,onend)
			table.insert(anims,thread)
			for i,v in next, keyframes do
				local thread = task.delay(i,function()
					local time = i-lastt
					setC0s(v,i-lastt,easestyle)
					lastt = i
				end)
				table.insert(anims,thread)
			end
		else
			stopAnims()
			if(animate)then
				animate.Disabled = false
			end
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
		local thread = task.delay(i,function()
			local time = i-lastt
			setC0s(v,i-lastt,easestyle)
			lastt = i
		end)
		table.insert(anims,thread)
	end
end

playAnim("Kazotsky")

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