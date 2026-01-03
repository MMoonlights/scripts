local url = "https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/UI/LunaUI.lua"
local Interface = loadstring(game:HttpGet(url, true))()

local Window = Interface:CreateWindow({
	Name = "Loader",
	Subtitle = "By https://github.com/MMoonlights",
	LogoID = "77782645018929",
	LoadingEnabled = true,
	LoadingTitle = "MMoonlights",
	LoadingSubtitle = "Loading...",
	ConfigSettings = {
		RootFolder = nil,
		ConfigFolder = "Loader",
	},
	KeySystem = false,
})

local MainTab = Window:CreateTab({
	Name = "Main",
	Icon = "110743239876005",
	ImageSource = "Custom",
	ShowTitle = true,
})

MainTab:CreateButton({
	Name = "Criminality",
	Description = "Criminality",
	Callback = function()
		Window:Destroy()
		wait(0.1)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Criminality/script.lua"))()
	end,
})
