if(not owner)then
	getfenv(1).owner = script.Parent:IsA("PlayerGui") and script.Parent.Parent or game:GetService('Players'):GetPlayerFromCharacter(script.Parent)
end
local plr : Player = owner
local chr : Model = owner.Character
local hum : Humanoid = chr:FindFirstChildOfClass("Humanoid")
local animate = chr.Animate
local tweening = true
function getData(name : string)
	local data = game:GetService('HttpService'):GetAsync("https://raw.githubusercontent.com/TheFakeFew/R6Emotes/main/"..name or ""..".lua")
	local DATA = loadstring(data or "")()
	return DATA or nil
end
local anims = {}
local welds = {}
for i,v in next, chr:GetDescendants() do
	if(v:IsA("JointInstance"))then
		welds[v.Part1.Name or ""] = v
	end
end
local origc0s = {}
for i,v in next, welds do
	origc0s[i] = v.C0
end

function setC0s(tbl : {},time)
	local anims = tbl["HumanoidRootPart"]
	for i,v in next, anims do
		if(welds[i])then
			if(tweening)then
				game:GetService('TweenService'):Create(welds[i],TweenInfo.new(time),{
					C0 = origc0s[i]*v.CFrame
				}):Play()
			else
				welds[i].C0 = origc0s[i]*v.CFrame
			end
		end
		for i,v in next, v do
			if(welds[i])then
				if(tweening)then
					game:GetService('TweenService'):Create(welds[i],TweenInfo.new(time),{
						C0 = origc0s[i]*v.CFrame
					}):Play()
				else
					welds[i].C0 = origc0s[i]*v.CFrame
				end
			end
		end
	end
end

function stopAnims()
	for i,v in next, anims do
		task.cancel(v)
	end
end

function playAnim(name : string)
	stopAnims()
	local data = getData(name)
	if(not data)then
		return print("Doesnt Exist.")
	end
	animate.Disabled = true
	local keyframes = data.Keyframes
	local looping = data.Properties.Looping or false
	local lastt = 0
	function onend()
		if(looping)then
			local lastkeyframe = 0
			for i,v in next, keyframes do
				lastkeyframe = i
			end
			local thread = task.delay(lastkeyframe,onend)
			table.insert(anims,thread)
			for i,v in next, keyframes do
				local thread = task.delay(i,function()
					local time = i-lastt
					setC0s(v,i-lastt)
					lastt = i
				end)
				table.insert(anims,thread)
			end
		else
			stopAnims()
			animate.Disabled = false
		end
	end
	local lastkeyframe = 0
	for i,v in next, keyframes do
		lastkeyframe = i
	end
	local thread = task.delay(lastkeyframe,onend)
	table.insert(anims,thread)
	for i,v in next, keyframes do
		local thread = task.delay(i,function()
			local time = i-lastt
			setC0s(v,i-lastt)
			lastt = i
		end)
		table.insert(anims,thread)
	end
end

playAnim("Kazotsky")

owner.Chatted:Connect(function(message)
	if(string.lower(message):sub(1,5)=="anim!")then
		playAnim(string.split(message,"!")[2])
	end
end)