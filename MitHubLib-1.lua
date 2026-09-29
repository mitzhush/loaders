local MitHubLib = {}
MitHubLib.__index = MitHubLib

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local BG_IMAGE = "rbxassetid://98921381007104"
local FOLDER = "MitHub"
local CONFIG_FOLDER = "MitHub/Configs"
local SETTINGS_FILE = "MitHub/settings.json"
local DEFAULT_W, DEFAULT_H = 460, 440
local MIN_W, MIN_H = 380, 300

local COLORS = {
    THEME = Color3.fromRGB(235, 235, 235),
    THEME_DARK = Color3.fromRGB(40, 40, 40),
    THEME_DARKER = Color3.fromRGB(10, 10, 10),
    THEME_BTN = Color3.fromRGB(22, 22, 22),
    TEXT = Color3.fromRGB(240, 240, 240),
    TEXT_DIM = Color3.fromRGB(150, 150, 150),
    TAB_SELECTED = Color3.fromRGB(232, 232, 232),
    TAB_UNSELECTED = Color3.fromRGB(18, 18, 18),
    TAB_TEXT_SELECTED = Color3.fromRGB(10, 10, 10),
    SWITCH_OFF = Color3.fromRGB(20, 20, 20),
    DOT_OFF = Color3.fromRGB(120, 120, 120),
    DOT_ON = Color3.fromRGB(10, 10, 10),
}

local FS_OK = type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function"
    and type(isfolder) == "function"
    and type(makefolder) == "function"
    and type(listfiles) == "function"
    and type(delfile) == "function"

local function PlayClickSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9101028114"
    sound.Volume = 0.4
    sound.Parent = CoreGui
    sound:Play()
    Debris:AddItem(sound, 1.5)
end

local function Corner(parent, offset, scale)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(scale or 0, offset or 0)
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency
    return s
end

local function ViewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function EnsureFolders()
    if not FS_OK then return end
    pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
end

local function ReadJson(path)
    if not FS_OK then return nil end
    local ok, data = pcall(function()
        if isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
    end)
    if ok then return data end
    return nil
end

local function WriteJson(path, data)
    if not FS_OK then return false end
    local ok = pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
    return ok
end

local function CleanName(name)
    local n = tostring(name or "")
    n = n:gsub("[^%w%s_%-]", "")
    n = n:gsub("^%s+", "")
    n = n:gsub("%s+$", "")
    return n:sub(1, 32)
end

local function BindDrag(handle, onStart, onMove, onEnd)
    local active = false
    local origin
    local touch
    handle.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            active = true
            origin = input.Position
            touch = t == Enum.UserInputType.Touch and input or nil
            onStart()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or (touch and input == touch) then
            local d = input.Position - origin
            onMove(Vector2.new(d.X, d.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if not active then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or (touch and input == touch) then
            active = false
            if onEnd then onEnd() end
        end
    end)
end

function MitHubLib.new(title, colors)
    local self = setmetatable({}, MitHubLib)

    self.COLORS = {}
    for k, v in pairs(COLORS) do self.COLORS[k] = v end
    if colors then
        for k, v in pairs(colors) do self.COLORS[k] = v end
    end
    local C = self.COLORS

    if CoreGui:FindFirstChild("MitHub_V3") then
        CoreGui.MitHub_V3:Destroy()
    end

    EnsureFolders()
    self.Flags = {}
    self.Tabs = {}
    self.TabCount = 0
    self._autoDone = false
    self.Settings = ReadJson(SETTINGS_FILE)
    if type(self.Settings) ~= "table" then self.Settings = {} end

    self.ScreenGui = Instance.new("ScreenGui", CoreGui)
    self.ScreenGui.Name = "MitHub_V3"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame", self.ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.Size = UDim2.new(0, DEFAULT_W, 0, DEFAULT_H)
    MainFrame.ClipsDescendants = true
    Corner(MainFrame, 10)
    self.MainFrame = MainFrame

    local BgImage = Instance.new("ImageLabel", MainFrame)
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.Image = BG_IMAGE
    BgImage.BackgroundTransparency = 1
    BgImage.ImageTransparency = 0.1
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ZIndex = 0

    local BgOverlay = Instance.new("Frame", MainFrame)
    BgOverlay.Size = UDim2.new(1, 0, 1, 0)
    BgOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BgOverlay.BackgroundTransparency = 0.55
    BgOverlay.BorderSizePixel = 0
    BgOverlay.ZIndex = 1

    Stroke(MainFrame, C.THEME, 1.8, 0.35)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = C.THEME_DARKER
    TopBar.BackgroundTransparency = 0.1
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 2
    Stroke(TopBar, C.THEME, 1, 0.6)
    self.TopBar = TopBar

    local TitleIcon = Instance.new("ImageLabel", TopBar)
    TitleIcon.Size = UDim2.new(0, 24, 0, 24)
    TitleIcon.Position = UDim2.new(0, 10, 0.5, -12)
    TitleIcon.Image = BG_IMAGE
    TitleIcon.ScaleType = Enum.ScaleType.Crop
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.ZIndex = 3
    Corner(TitleIcon, 0, 1)

    local TitleLabel = Instance.new("TextLabel", TopBar)
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 42, 0, 0)
    TitleLabel.Text = title or "MITHUB"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextColor3 = C.TEXT
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.ZIndex = 3

    local TitleAccent = Instance.new("Frame", MainFrame)
    TitleAccent.Size = UDim2.new(1, 0, 0, 2)
    TitleAccent.Position = UDim2.new(0, 0, 0, 38)
    TitleAccent.BackgroundColor3 = C.THEME
    TitleAccent.BorderSizePixel = 0
    TitleAccent.ZIndex = 3

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
    CloseBtn.Text = "x"
    CloseBtn.TextColor3 = C.TEXT
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.ZIndex = 4

    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Size = UDim2.new(0, 110, 1, -45)
    Sidebar.Position = UDim2.new(0, 8, 0, 43)
    Sidebar.BackgroundColor3 = C.THEME_DARKER
    Sidebar.BackgroundTransparency = 0.2
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Sidebar.ScrollBarImageColor3 = C.THEME
    Sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.ZIndex = 2
    Corner(Sidebar, 7)
    Stroke(Sidebar, C.THEME, 1, 0.6)
    self.Sidebar = Sidebar

    local SidebarLayout = Instance.new("UIListLayout", Sidebar)
    SidebarLayout.Padding = UDim.new(0, 4)
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local SidebarPad = Instance.new("UIPadding", Sidebar)
    SidebarPad.PaddingTop = UDim.new(0, 6)
    SidebarPad.PaddingBottom = UDim.new(0, 6)

    local Container = Instance.new("Frame", MainFrame)
    Container.Size = UDim2.new(1, -130, 1, -48)
    Container.Position = UDim2.new(0, 124, 0, 45)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 2
    self.Container = Container

    local MinBtn = Instance.new("ImageButton", self.ScreenGui)
    MinBtn.Size = UDim2.new(0, 50, 0, 50)
    MinBtn.Position = UDim2.new(0, 100, 0, 100)
    MinBtn.BackgroundColor3 = C.THEME_DARKER
    MinBtn.Image = BG_IMAGE
    MinBtn.ScaleType = Enum.ScaleType.Crop
    MinBtn.Visible = false
    Corner(MinBtn, 0, 1)
    Stroke(MinBtn, C.THEME, 1.5, 0)
    self.MinBtn = MinBtn

    local minOrigin
    local minMoved = false
    BindDrag(MinBtn,
        function()
            minOrigin = MinBtn.Position
            minMoved = false
        end,
        function(d)
            if math.abs(d.X) + math.abs(d.Y) > 6 then minMoved = true end
            MinBtn.Position = UDim2.new(
                minOrigin.X.Scale, minOrigin.X.Offset + d.X,
                minOrigin.Y.Scale, minOrigin.Y.Offset + d.Y
            )
        end
    )

    local frameOrigin
    BindDrag(TopBar,
        function()
            frameOrigin = MainFrame.Position
        end,
        function(d)
            MainFrame.Position = UDim2.new(
                frameOrigin.X.Scale, frameOrigin.X.Offset + d.X,
                frameOrigin.Y.Scale, frameOrigin.Y.Offset + d.Y
            )
        end
    )

    local Grip = Instance.new("TextButton", MainFrame)
    Grip.Name = "ResizeGrip"
    Grip.Size = UDim2.new(0, 26, 0, 26)
    Grip.AnchorPoint = Vector2.new(1, 1)
    Grip.Position = UDim2.new(1, 0, 1, 0)
    Grip.BackgroundTransparency = 1
    Grip.Text = ""
    Grip.ZIndex = 10
    for i = 1, 3 do
        local c = 3 + i * 4
        local line = Instance.new("Frame", Grip)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Size = UDim2.new(0, i * 8, 0, 1)
        line.Position = UDim2.new(1, -c, 1, -c)
        line.Rotation = -45
        line.BackgroundColor3 = C.TEXT_DIM
        line.BorderSizePixel = 0
        line.ZIndex = 11
    end
    self.Grip = Grip

    local gripOrigin
    BindDrag(Grip,
        function()
            gripOrigin = Vector2.new(MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset)
        end,
        function(d)
            self:SetSize(gripOrigin.X + d.X, gripOrigin.Y + d.Y)
        end,
        function()
            self:SetSize(MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset, true)
        end
    )

    CloseBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        MainFrame.Visible = false
        MinBtn.Visible = true
    end)
    MinBtn.MouseButton1Click:Connect(function()
        if minMoved then return end
        PlayClickSound()
        MainFrame.Visible = true
        MinBtn.Visible = false
    end)

    local w, h = DEFAULT_W, DEFAULT_H
    local saved = self.Settings.size
    if type(saved) == "table" and tonumber(saved[1]) and tonumber(saved[2]) then
        w, h = tonumber(saved[1]), tonumber(saved[2])
    end
    self:SetSize(w, h)
    MainFrame.Position = UDim2.new(
        0.5, -MainFrame.Size.X.Offset / 2,
        0.5, -MainFrame.Size.Y.Offset / 2
    )

    self:_BuildConfigTab()

    task.delay(3, function()
        self:RunAutoExecute()
    end)

    return self
end

function MitHubLib:SetSize(w, h, save)
    local vp = ViewportSize()
    w = math.clamp(math.floor(w), MIN_W, math.max(MIN_W, vp.X - 20))
    h = math.clamp(math.floor(h), MIN_H, math.max(MIN_H, vp.Y - 20))
    self.MainFrame.Size = UDim2.new(0, w, 0, h)
    if save then
        self.Settings.size = { w, h }
        self:SaveSettings()
    end
end

function MitHubLib:GetSize()
    return self.MainFrame.Size.X.Offset, self.MainFrame.Size.Y.Offset
end

function MitHubLib:SaveSettings()
    EnsureFolders()
    return WriteJson(SETTINGS_FILE, self.Settings)
end

function MitHubLib:RegisterFlag(flag, getter, setter)
    self.Flags[flag] = { Get = getter, Set = setter }
end

function MitHubLib:GetConfig()
    local data = {}
    for flag, entry in pairs(self.Flags) do
        local ok, v = pcall(entry.Get)
        if ok and v ~= nil then data[flag] = v end
    end
    return data
end

function MitHubLib:ApplyConfig(data)
    for flag, v in pairs(data) do
        local entry = self.Flags[flag]
        if entry then pcall(entry.Set, v) end
    end
end

function MitHubLib:ListConfigs()
    local names = {}
    if not FS_OK then return names end
    EnsureFolders()
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if ok and type(files) == "table" then
        for _, path in ipairs(files) do
            local n = tostring(path):match("([^/\\]+)%.json$")
            if n then table.insert(names, n) end
        end
    end
    table.sort(names)
    return names
end

function MitHubLib:SaveConfig(name)
    name = CleanName(name)
    if name == "" then return false end
    EnsureFolders()
    local ok = WriteJson(CONFIG_FOLDER .. "/" .. name .. ".json", self:GetConfig())
    return ok, name
end

function MitHubLib:LoadConfig(name)
    name = CleanName(name)
    if name == "" then return false end
    local data = ReadJson(CONFIG_FOLDER .. "/" .. name .. ".json")
    if type(data) ~= "table" then return false end
    self:ApplyConfig(data)
    return true
end

function MitHubLib:DeleteConfig(name)
    name = CleanName(name)
    if name == "" or not FS_OK then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    local ok = pcall(function()
        if isfile(path) then delfile(path) end
    end)
    if ok and self.Settings.autoexecute == name then
        self.Settings.autoexecute = nil
        self:SaveSettings()
    end
    return ok
end

function MitHubLib:RunAutoExecute()
    if self._autoDone then return end
    self._autoDone = true
    local name = self.Settings.autoexecute
    if name then self:LoadConfig(name) end
end

function MitHubLib:_SelectTab(tab)
    local C = self.COLORS
    for _, t in ipairs(self.Tabs) do
        local on = t == tab
        t.Page.Visible = on
        TweenService:Create(t.Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.TAB_SELECTED or C.TAB_UNSELECTED,
            BackgroundTransparency = on and 0 or 0.1,
        }):Play()
        local col = on and C.TAB_TEXT_SELECTED or C.TEXT_DIM
        t.Label.TextColor3 = col
        t.Icon.ImageColor3 = col
        t.Accent.Visible = on
        t.Stroke.Enabled = on
    end
end

function MitHubLib:_MakeTab(name, isDefault, iconId, order)
    local C = self.COLORS
    self.TabCount = self.TabCount + 1

    local Page = Instance.new("ScrollingFrame", self.Container)
    Page.Name = name
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.Visible = false
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = C.THEME
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local PageLayout = Instance.new("UIListLayout", Page)
    PageLayout.Padding = UDim.new(0, 5)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local PagePad = Instance.new("UIPadding", Page)
    PagePad.PaddingTop = UDim.new(0, 4)
    PagePad.PaddingBottom = UDim.new(0, 26)

    local TabBtn = Instance.new("TextButton", self.Sidebar)
    TabBtn.Name = name
    TabBtn.LayoutOrder = order or self.TabCount
    TabBtn.Size = UDim2.new(0, 98, 0, 34)
    TabBtn.BackgroundColor3 = C.TAB_UNSELECTED
    TabBtn.BackgroundTransparency = 0.1
    TabBtn.AutoButtonColor = false
    TabBtn.Text = ""
    Corner(TabBtn, 7)
    local TabStroke = Stroke(TabBtn, C.THEME, 1.2, 0.3)
    TabStroke.Enabled = false

    local Accent = Instance.new("Frame", TabBtn)
    Accent.Name = "Accent"
    Accent.Size = UDim2.new(0, 3, 0, 20)
    Accent.Position = UDim2.new(0, 0, 0.5, -10)
    Accent.BackgroundColor3 = C.TAB_TEXT_SELECTED
    Accent.BorderSizePixel = 0
    Accent.Visible = false
    Corner(Accent, 2)

    local hasIcon = iconId ~= nil and iconId ~= ""
    local TabIcon = Instance.new("ImageLabel", TabBtn)
    TabIcon.Name = "Icon"
    TabIcon.Size = UDim2.new(0, 16, 0, 16)
    TabIcon.Position = UDim2.new(0, 10, 0.5, -8)
    TabIcon.BackgroundTransparency = 1
    TabIcon.Image = hasIcon and iconId or ""
    TabIcon.ImageColor3 = C.TEXT_DIM
    TabIcon.Visible = hasIcon
    TabIcon.ZIndex = 2

    local TabLabel = Instance.new("TextLabel", TabBtn)
    TabLabel.Name = "Label"
    TabLabel.Size = UDim2.new(1, hasIcon and -32 or -14, 1, 0)
    TabLabel.Position = UDim2.new(0, hasIcon and 32 or 12, 0, 0)
    TabLabel.Text = name
    TabLabel.Font = Enum.Font.GothamSemibold
    TabLabel.TextColor3 = C.TEXT_DIM
    TabLabel.TextSize = 11
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TabLabel.BackgroundTransparency = 1
    TabLabel.ZIndex = 2

    local tab = {
        Btn = TabBtn,
        Label = TabLabel,
        Icon = TabIcon,
        Accent = Accent,
        Stroke = TabStroke,
        Page = Page,
    }
    table.insert(self.Tabs, tab)

    TabBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        self:_SelectTab(tab)
    end)

    if isDefault then
        self:_SelectTab(tab)
    end

    return Page
end

function MitHubLib:CreateTab(name, isDefault, iconId)
    return self:_MakeTab(name, isDefault, iconId)
end

function MitHubLib:AddToggle(page, text, callback, iconId, flag)
    local C = self.COLORS
    local TFrame = self:MakeRow(page, 34)

    local labelX = 10
    if iconId and iconId ~= "" then
        local Ico = Instance.new("ImageLabel", TFrame)
        Ico.Size = UDim2.new(0, 15, 0, 15)
        Ico.Position = UDim2.new(0, 10, 0.5, -7)
        Ico.BackgroundTransparency = 1
        Ico.Image = iconId
        Ico.ImageColor3 = C.TEXT_DIM
        labelX = 30
    end

    local Label = Instance.new("TextLabel", TFrame)
    Label.Size = UDim2.new(1, -labelX - 50, 1, 0)
    Label.Position = UDim2.new(0, labelX, 0, 0)
    Label.Text = text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextColor3 = C.TEXT
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.BackgroundTransparency = 1

    local Switch, Dot = self:MakeSwitch(TFrame)
    local state = false

    local function setState(v, fire)
        state = v and true or false
        self:AnimSwitch(Switch, Dot, state)
        TweenService:Create(TFrame, TweenInfo.new(0.15), {
            BackgroundTransparency = state and 0.03 or 0.15,
        }):Play()
        if fire and callback then callback(state) end
    end

    Switch.MouseButton1Click:Connect(function()
        PlayClickSound()
        setState(not state, true)
    end)

    self:RegisterFlag(flag or (page.Name .. ":" .. text),
        function() return state end,
        function(v)
            v = v and true or false
            if v ~= state then setState(v, true) end
        end
    )

    return {
        Frame = TFrame,
        Switch = Switch,
        Dot = Dot,
        Label = Label,
        GetState = function() return state end,
        SetState = function(v, fire) setState(v, fire) end,
    }
end

function MitHubLib:AddButton(page, text, callback)
    local C = self.COLORS

    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, -8, 0, 34)
    Btn.BackgroundColor3 = C.THEME_BTN
    Btn.BackgroundTransparency = 0.2
    Btn.AutoButtonColor = false
    Btn.Text = text
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextColor3 = C.TEXT
    Btn.TextSize = 11
    Corner(Btn, 6)
    Stroke(Btn, C.THEME, 1, 0.5)

    Btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundTransparency = 0 }):Play()
        task.delay(0.15, function()
            TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundTransparency = 0.2 }):Play()
        end)
        if callback then callback() end
    end)

    return Btn
end

function MitHubLib:MakeRow(parent, height)
    local C = self.COLORS
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -8, 0, height or 34)
    f.BackgroundColor3 = C.THEME_DARKER
    f.BackgroundTransparency = 0.15
    Corner(f, 7)
    Stroke(f, C.THEME, 1, 0.6)
    return f
end

function MitHubLib:MakeLabel(parent, text, xOff, w)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(0, w or 130, 1, 0)
    l.Position = UDim2.new(0, xOff or 10, 0, 0)
    l.Text = text
    l.Font = Enum.Font.GothamSemibold
    l.TextColor3 = self.COLORS.TEXT
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.BackgroundTransparency = 1
    return l
end

function MitHubLib:MakeSwitch(parent)
    local C = self.COLORS
    local Switch = Instance.new("TextButton", parent)
    Switch.Size = UDim2.new(0, 34, 0, 18)
    Switch.Position = UDim2.new(1, -44, 0.5, -9)
    Switch.BackgroundColor3 = C.SWITCH_OFF
    Switch.AutoButtonColor = false
    Switch.Text = ""
    Corner(Switch, 0, 1)
    Stroke(Switch, C.THEME, 1, 0.4)

    local Dot = Instance.new("Frame", Switch)
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(0, 2, 0.5, -7)
    Dot.BackgroundColor3 = C.DOT_OFF
    Corner(Dot, 0, 1)

    return Switch, Dot
end

function MitHubLib:AnimSwitch(Switch, Dot, state)
    local C = self.COLORS
    TweenService:Create(Dot, TweenInfo.new(0.2), {
        Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = state and C.DOT_ON or C.DOT_OFF,
    }):Play()
    TweenService:Create(Switch, TweenInfo.new(0.2), {
        BackgroundColor3 = state and C.THEME or C.SWITCH_OFF,
    }):Play()
end

function MitHubLib:MakeTextBox(parent, defaultText, placeholder, xOff, w)
    local C = self.COLORS
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, w or 50, 0, 22)
    box.Position = UDim2.new(1, xOff or -58, 0.5, -11)
    box.BackgroundColor3 = C.THEME_DARK
    box.Text = tostring(defaultText or "")
    box.Font = Enum.Font.GothamSemibold
    box.TextColor3 = C.TEXT
    box.TextSize = 11
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = C.TEXT_DIM
    box.ClearTextOnFocus = false
    Corner(box, 5)
    Stroke(box, C.THEME, 1, 0.4)
    return box
end

function MitHubLib:MakeKeybindBtn(parent, defaultText, xOff)
    local C = self.COLORS
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 34, 0, 20)
    btn.Position = UDim2.new(1, xOff or -82, 0.5, -10)
    btn.BackgroundColor3 = C.THEME_DARK
    btn.BackgroundTransparency = 0.2
    btn.AutoButtonColor = false
    btn.Text = defaultText or "---"
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = C.TEXT
    btn.TextSize = 10
    Corner(btn, 4)
    Stroke(btn, C.THEME, 1, 0.5)
    return btn
end

function MitHubLib:MakeSeparator(parent, text)
    local sep = Instance.new("Frame", parent)
    sep.Size = UDim2.new(1, -8, 0, 20)
    sep.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", sep)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = text or ""
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = self.COLORS.TEXT_DIM
    lbl.TextSize = 10
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.BackgroundTransparency = 1
    return sep, lbl
end

function MitHubLib:MakeColorRow(parent, labelText, defaultColor, flag)
    local C = self.COLORS
    local init = defaultColor or Color3.fromRGB(255, 255, 255)
    local initR = math.round(init.R * 255)
    local initG = math.round(init.G * 255)
    local initB = math.round(init.B * 255)

    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 34)
    row.BackgroundColor3 = C.THEME_DARKER
    row.BackgroundTransparency = 0.2
    Corner(row, 6)
    Stroke(row, C.THEME, 1, 0.7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 85, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.Text = labelText or "Color"
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = C.TEXT
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local preview = Instance.new("Frame", row)
    preview.Size = UDim2.new(0, 14, 0, 14)
    preview.Position = UDim2.new(1, -22, 0.5, -7)
    preview.BackgroundColor3 = init
    Corner(preview, 3)
    Stroke(preview, C.THEME, 1, 0.4)

    local function makeBox(xOff, initVal)
        local b = Instance.new("TextBox", row)
        b.Size = UDim2.new(0, 34, 0, 20)
        b.Position = UDim2.new(0, xOff, 0.5, -10)
        b.BackgroundColor3 = C.THEME_DARK
        b.Text = tostring(initVal)
        b.Font = Enum.Font.GothamSemibold
        b.TextColor3 = C.TEXT
        b.TextSize = 10
        b.ClearTextOnFocus = false
        Corner(b, 4)
        return b
    end

    local rBox = makeBox(90, initR)
    local gBox = makeBox(128, initG)
    local bBox = makeBox(166, initB)

    local currentColor = init
    local function applyColor()
        local r = math.clamp(tonumber(rBox.Text) or initR, 0, 255)
        local g = math.clamp(tonumber(gBox.Text) or initG, 0, 255)
        local b = math.clamp(tonumber(bBox.Text) or initB, 0, 255)
        rBox.Text = tostring(r)
        gBox.Text = tostring(g)
        bBox.Text = tostring(b)
        currentColor = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = currentColor
    end
    rBox.FocusLost:Connect(applyColor)
    gBox.FocusLost:Connect(applyColor)
    bBox.FocusLost:Connect(applyColor)

    local api = {
        Frame = row,
        Preview = preview,
        GetColor = function() return currentColor end,
        SetColor = function(c)
            rBox.Text = tostring(math.round(c.R * 255))
            gBox.Text = tostring(math.round(c.G * 255))
            bBox.Text = tostring(math.round(c.B * 255))
            applyColor()
        end,
    }

    self:RegisterFlag(flag or (parent.Name .. ":" .. (labelText or "Color")),
        function()
            return {
                math.round(currentColor.R * 255),
                math.round(currentColor.G * 255),
                math.round(currentColor.B * 255),
            }
        end,
        function(t)
            if type(t) == "table" then
                api.SetColor(Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255))
            end
        end
    )

    return api
end

function MitHubLib:MakeSlider(parent, labelText, minVal, maxVal, default, decimals, callback, flag)
    local C = self.COLORS
    local dec = decimals or 0

    local row = self:MakeRow(parent, 50)
    self:MakeLabel(row, labelText, 10, 120)

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0, 40, 0, 14)
    valLbl.Position = UDim2.new(1, -48, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = C.TEXT_DIM
    valLbl.TextSize = 10
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local trackBg = Instance.new("Frame", row)
    trackBg.Size = UDim2.new(1, -16, 0, 6)
    trackBg.Position = UDim2.new(0, 8, 1, -14)
    trackBg.BackgroundColor3 = C.THEME_DARK
    trackBg.BorderSizePixel = 0
    Corner(trackBg, 3)
    Stroke(trackBg, C.THEME, 1, 0.6)

    local trackFill = Instance.new("Frame", trackBg)
    trackFill.Size = UDim2.new(0, 0, 1, 0)
    trackFill.BackgroundColor3 = C.THEME
    trackFill.BorderSizePixel = 0
    Corner(trackFill, 3)

    local thumb = Instance.new("Frame", trackBg)
    thumb.Size = UDim2.new(0, 10, 0, 10)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    Corner(thumb, 0, 1)

    local currentValue = default or minVal
    local dragging = false

    local function setValue(v)
        v = math.clamp(tonumber(v) or minVal, minVal, maxVal)
        local pct = (v - minVal) / (maxVal - minVal)
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, 0, 0.5, 0)
        currentValue = v
        valLbl.Text = string.format("%." .. dec .. "f", v)
        if callback then callback(v) end
    end

    setValue(currentValue)

    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local absSize = trackBg.AbsoluteSize.X
            local absPos = trackBg.AbsolutePosition.X
            local pct = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            local raw = minVal + pct * (maxVal - minVal)
            local step = 10 ^ (-dec)
            setValue(math.floor(raw / step + 0.5) * step)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    self:RegisterFlag(flag or (parent.Name .. ":" .. labelText),
        function() return currentValue end,
        setValue
    )

    return {
        Frame = row,
        GetValue = function() return currentValue end,
        SetValue = setValue,
    }
end

function MitHubLib:_BuildConfigTab()
    local C = self.COLORS
    local page = self:_MakeTab("Configs", false, nil, 9999)

    self:MakeSeparator(page, "CONFIGS")

    local nameRow = self:MakeRow(page, 34)
    self:MakeLabel(nameRow, "Name", 10, 50)
    local nameBox = self:MakeTextBox(nameRow, "", "config name", 0, 0)
    nameBox.Size = UDim2.new(1, -74, 0, 22)
    nameBox.Position = UDim2.new(0, 64, 0.5, -11)

    local listRow = self:MakeRow(page, 120)
    local List = Instance.new("ScrollingFrame", listRow)
    List.Size = UDim2.new(1, -12, 1, -12)
    List.Position = UDim2.new(0, 6, 0, 6)
    List.BackgroundTransparency = 1
    List.BorderSizePixel = 0
    List.ScrollBarThickness = 2
    List.ScrollBarImageColor3 = C.THEME
    List.CanvasSize = UDim2.new(0, 0, 0, 0)
    List.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local ListLayout = Instance.new("UIListLayout", List)
    ListLayout.Padding = UDim.new(0, 3)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local _, infoLbl = self:MakeSeparator(page, "")
    local _, statusLbl = self:MakeSeparator(page, FS_OK and "" or "Executor has no file functions")

    local selected

    local function updateInfo()
        infoLbl.Text = "Selected: " .. (selected or "none") .. "  |  Auto Execute: " .. (self.Settings.autoexecute or "none")
    end

    local function status(msg)
        statusLbl.Text = msg
    end

    local refresh
    refresh = function()
        for _, c in ipairs(List:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, name in ipairs(self:ListConfigs()) do
            local isSel = name == selected
            local b = Instance.new("TextButton", List)
            b.Name = name
            b.LayoutOrder = i
            b.Size = UDim2.new(1, -4, 0, 26)
            b.BackgroundColor3 = isSel and C.TAB_SELECTED or C.THEME_DARK
            b.BackgroundTransparency = 0.2
            b.AutoButtonColor = false
            b.Text = name == self.Settings.autoexecute and (name .. "  [AUTO]") or name
            b.Font = Enum.Font.GothamSemibold
            b.TextColor3 = isSel and C.TAB_TEXT_SELECTED or C.TEXT
            b.TextSize = 11
            b.TextTruncate = Enum.TextTruncate.AtEnd
            Corner(b, 5)
            b.MouseButton1Click:Connect(function()
                PlayClickSound()
                selected = name
                nameBox.Text = name
                refresh()
            end)
        end
        updateInfo()
    end

    self:AddButton(page, "Save Config", function()
        if not FS_OK then status("Executor has no file functions") return end
        local raw = nameBox.Text
        if CleanName(raw) == "" then raw = selected or "" end
        if CleanName(raw) == "" then status("Type a name first") return end
        local ok, name = self:SaveConfig(raw)
        if ok then
            selected = name
            nameBox.Text = name
            status("Saved: " .. name)
        else
            status("Failed to save")
        end
        refresh()
    end)

    self:AddButton(page, "Auto Load", function()
        if not selected then status("Select a config first") return end
        if self:LoadConfig(selected) then
            status("Loaded: " .. selected)
        else
            status("Failed to load")
        end
    end)

    self:AddButton(page, "Auto Execute", function()
        if not selected then status("Select a config first") return end
        if self.Settings.autoexecute == selected then
            self.Settings.autoexecute = nil
            status("Auto Execute disabled")
        else
            self.Settings.autoexecute = selected
            status("Auto Execute: " .. selected)
        end
        self:SaveSettings()
        refresh()
    end)

    self:AddButton(page, "Delete Config", function()
        if not selected then status("Select a config first") return end
        local name = selected
        if self:DeleteConfig(name) then
            selected = nil
            nameBox.Text = ""
            status("Deleted: " .. name)
        else
            status("Failed to delete")
        end
        refresh()
    end)

    refresh()
    return page
end

return MitHubLib
