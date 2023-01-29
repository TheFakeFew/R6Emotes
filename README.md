animation player for roblox
```lua
local raw = game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/TheFakeFew/R6Emotes/main/RobloxScript.lua")
if(not raw)then
    print('Failed to get raw')
end
print('Loading raw')
local load,err = loadstring(raw)
if(not load)then print("Failed to load: ",err) else load() end
```
