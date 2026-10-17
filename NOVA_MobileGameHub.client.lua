-- NOVA Mobile Game Hub
-- Place this LocalScript in StarterPlayerScripts.
-- Designed for your own Roblox experience / UI testing.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GUI_NAME = "MobileGameHub"

-- Remove an earlier copy so the UI never stacks.
local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
    existing:Destroy()
end

local COLORS = {
    background = Color3.fromRGB(18, 20, 27),
    surface = Color3.fromRGB(25, 28, 37),
    card = Color3.fromRGB(31, 35, 46),
    button = Color3.fromRGB(42, 47, 61),
    accent = Color3.fromRGB(112, 130, 255),
    text = Color3.fromRGB(242, 243, 248),
    muted = Color3.fromRGB(155, 162, 180),
    border = Color3.fromRGB(51, 57, 73),
    success = Color3.fromRGB(98, 210, 154),
}

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    }, object)
end

local function addStroke(object, color)
    make("UIStroke", {
        Color = color or COLORS.border,
        Thickness = 1,
    }, object)
end

local function addLabel(parent, text, size, position, textSize, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Position = position or UDim2.new(),
        Size = size,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or COLORS.text,
        TextSize = textSize or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local gui = make("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 20,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local window = make("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(760, 500),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
addCorner(window, 16)
addStroke(window, COLORS.border)

-- Header
local topBar = make("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
}, window)
addCorner(topBar, 16)

-- A surface-colored strip keeps the header's lower edge visually clean.
make("Frame", {
    Name = "HeaderBottomEdge",
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
}, topBar)

local dragHandle = make("TextButton", {
    Name = "DragHandle",
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -112, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    Active = true,
}, topBar)

addLabel(dragHandle, "NOVA", UDim2.new(0, 78, 1, 0), nil, 19, COLORS.text, true)
local hubSubtitle = addLabel(
    dragHandle, "GAME HUB", UDim2.new(0, 100, 1, 0),
    UDim2.fromOffset(82, 0), 11, COLORS.accent, true
)

local localTag = addLabel(
    topBar, "LOCAL UI", UDim2.new(0, 70, 1, 0),
    UDim2.new(1, -130, 0, 0), 10, COLORS.muted, true
)

local minimizeButton = make("TextButton", {
    Name = "MinimizeButton",
    Position = UDim2.new(1, -88, 0, 13),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = COLORS.button,
    Text = "—",
    TextColor3 = COLORS.text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, topBar)
addCorner(minimizeButton, 8)

local hideButton = make("TextButton", {
    Name = "HideButton",
    Position = UDim2.new(1, -48, 0, 13),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = COLORS.button,
    Text = "×",
    TextColor3 = COLORS.text,
    TextSize = 21,
    Font = Enum.Font.Gotham,
    AutoButtonColor = true,
}, topBar)
addCorner(hideButton, 8)

-- Main layout
local body = make("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
}, window)

local sidebar = make("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 176, 1, 0),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
}, body)

local sidebarPadding = make("UIPadding", {
    PaddingTop = UDim.new(0, 16),
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
}, sidebar)

make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local sidebarHeader = addLabel(
    sidebar, "WORKSPACE", UDim2.new(1, 0, 0, 24),
    nil, 10, COLORS.muted, true
)
sidebarHeader.LayoutOrder = 1

local content = make("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 176, 0, 0),
    Size = UDim2.new(1, -176, 1, 0),
    BackgroundTransparency = 1,
}, body)

local pages = {}
local tabButtons = {}
local tabIcons = {}
local activePage
local minimized = false
local updateLayout -- Forward declaration for the minimize button callback.

local function createPage(name)
    local page = make("ScrollingFrame", {
        Name = name .. "Page",
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 1, -28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, content)

    make("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    make("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 6),
    }, page)

    local heading = addLabel(
        page, name, UDim2.new(1, 0, 0, 34),
        nil, 22, COLORS.text, true
    )
    heading.LayoutOrder = 1
    pages[name] = page
    return page
end

local function showPage(name)
    if not pages[name] then
        return
    end
    activePage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for tabName, button in pairs(tabButtons) do
        local selected = tabName == name
        button.BackgroundColor3 = selected and COLORS.accent or COLORS.card
        button.TextColor3 = selected and COLORS.text or COLORS.muted
    end
end

local function createTab(name, icon, order)
    local button = make("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.card,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Text = "   " .. icon .. "    " .. name,
        TextColor3 = COLORS.muted,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = true,
        LayoutOrder = order,
    }, sidebar)
    addCorner(button, 9)

    tabButtons[name] = button
    tabIcons[name] = icon
    button.Activated:Connect(function()
        showPage(name)
    end)
end

local function createCard(parent, title, description, height)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 100),
        BackgroundColor3 = COLORS.card,
        BorderSizePixel = 0,
    }, parent)
    addCorner(card, 12)
    addStroke(card)

    addLabel(
        card, title, UDim2.new(1, -28, 0, 24),
        UDim2.fromOffset(14, 9), 14, COLORS.text, true
    )
    addLabel(
        card, description, UDim2.new(1, -28, 0, 36),
        UDim2.fromOffset(14, 34), 12, COLORS.muted, false
    )
    return card
end

local function notify(message)
    local camera = workspace.CurrentCamera
    local screenWidth = camera and camera.ViewportSize.X or 400
    local notificationWidth = math.min(280, math.max(190, screenWidth - 32))

    local notification = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, notificationWidth + 16, 0, 16),
        Size = UDim2.fromOffset(notificationWidth, 62),
        BackgroundColor3 = COLORS.card,
        BorderSizePixel = 0,
    }, gui)
    addCorner(notification, 10)
    addStroke(notification, COLORS.accent)

    addLabel(
        notification, "NOTICE", UDim2.new(1, -24, 0, 18),
        UDim2.fromOffset(12, 6), 10, COLORS.accent, true
    )
    addLabel(
        notification, message, UDim2.new(1, -24, 0, 28),
        UDim2.fromOffset(12, 27), 12, COLORS.text, false
    )

    TweenService:Create(notification, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Position = UDim2.new(1, -12, 0, 16),
    }):Play()

    task.delay(2.5, function()
        if not notification.Parent then
            return
        end
        local tween = TweenService:Create(notification, TweenInfo.new(0.2), {
            Position = UDim2.new(1, notificationWidth + 16, 0, 16),
        })
        tween:Play()
        tween.Completed:Wait()
        if notification.Parent then
            notification:Destroy()
        end
    end)
end

-- Pages and tabs
local homePage = createPage("Home")
local toolsPage = createPage("Tools")
local settingsPage = createPage("Settings")

createTab("Home", "⌂", 2)
createTab("Tools", "✦", 3)
createTab("Settings", "⚙", 4)

-- Home
local hero = make("Frame", {
    Size = UDim2.new(1, 0, 0, 130),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    LayoutOrder = 2,
}, homePage)
addCorner(hero, 14)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(94, 111, 235)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(145, 99, 235)),
    }),
    Rotation = 15,
}, hero)

addLabel(
    hero, "Welcome back", UDim2.new(1, -28, 0, 30),
    UDim2.fromOffset(16, 14), 20, COLORS.text, true
)
addLabel(
    hero, "Your game hub is ready.", UDim2.new(1, -28, 0, 24),
    UDim2.fromOffset(16, 46), 13, COLORS.text, false
)

local exploreButton = make("TextButton", {
    Position = UDim2.fromOffset(16, 84),
    Size = UDim2.fromOffset(128, 30),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "Explore tools",
    TextColor3 = Color3.fromRGB(38, 42, 65),
    TextSize = 12,
    AutoButtonColor = true,
}, hero)
addCorner(exploreButton, 8)
exploreButton.Activated:Connect(function()
    showPage("Tools")
end)

local homeCard = createCard(
    homePage, "Built for your experience",
    "Connect these buttons to features in your own Roblox game.", 88
)
homeCard.LayoutOrder = 3

local statusBadge = addLabel(
    homeCard, "●  UI ONLINE", UDim2.new(0, 110, 0, 18),
    UDim2.new(1, -122, 0, 10), 10, COLORS.success, true
)

-- Tools
local searchBox = make("TextBox", {
    Name = "SearchBox",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = COLORS.card,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Search tools...",
    PlaceholderColor3 = COLORS.muted,
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 13,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 2,
}, toolsPage)
addCorner(searchBox, 9)
addStroke(searchBox)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
}, searchBox)

local toolEntries = {}
local emptyState = addLabel(
    toolsPage, "No tools found. Try another search.",
    UDim2.new(1, 0, 0, 48), nil, 13, COLORS.muted, false
)
emptyState.TextXAlignment = Enum.TextXAlignment.Center
emptyState.Visible = false
emptyState.LayoutOrder = 99

local function addTool(title, description, callback)
    local card = createCard(toolsPage, title, description, 112)
    card.LayoutOrder = #toolEntries + 3

    local actionButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -10),
        Size = UDim2.fromOffset(92, 30),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Text = "Run",
        TextColor3 = COLORS.text,
        TextSize = 12,
        AutoButtonColor = true,
    }, card)
    addCorner(actionButton, 7)
    actionButton.Activated:Connect(callback)

    table.insert(toolEntries, {
        card = card,
        searchText = (title .. " " .. description):lower(),
    })
end

addTool("Welcome message", "Show a notification from the hub.", function()
    notify("Welcome to your game hub!")
end)
addTool("Open settings", "Jump to the settings page.", function()
    showPage("Settings")
end)
addTool("Reset search", "Clear the tool search field.", function()
    searchBox.Text = ""
end)

local function refreshToolSearch()
    local query = searchBox.Text:lower()
    local visibleCount = 0

    for _, entry in ipairs(toolEntries) do
        local matches = query == "" or entry.searchText:find(query, 1, true) ~= nil
        entry.card.Visible = matches
        if matches then
            visibleCount += 1
        end
    end

    emptyState.Visible = visibleCount == 0
    emptyState.LayoutOrder = #toolEntries + 3
end
searchBox:GetPropertyChangedSignal("Text"):Connect(refreshToolSearch)

-- Settings
local settingCard = createCard(
    settingsPage, "Interface settings",
    "Toggle this example setting.", 112
)
settingCard.LayoutOrder = 2

local settingEnabled = true
local toggleButton = make("TextButton", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -12, 1, -10),
    Size = UDim2.fromOffset(88, 30),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "ON",
    TextColor3 = COLORS.text,
    TextSize = 12,
    AutoButtonColor = true,
}, settingCard)
addCorner(toggleButton, 8)

toggleButton.Activated:Connect(function()
    settingEnabled = not settingEnabled
    toggleButton.Text = settingEnabled and "ON" or "OFF"
    toggleButton.BackgroundColor3 = settingEnabled and COLORS.accent or COLORS.button
    notify("Setting " .. (settingEnabled and "enabled." or "disabled."))
end)

local shortcutCard = createCard(
    settingsPage, "Keyboard shortcut",
    "Press RightShift to show or hide the hub on keyboard.", 82
)
shortcutCard.LayoutOrder = 3

-- Floating reopen button
local reopenButton = make("TextButton", {
    Name = "ReopenButton",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -24),
    Size = UDim2.fromOffset(50, 50),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "N",
    TextColor3 = COLORS.text,
    TextSize = 18,
    Visible = false,
    AutoButtonColor = true,
}, gui)
addCorner(reopenButton, 18)

-- Smooth open/close transitions. Original transparency values are restored on reopen.
local windowScale = make("UIScale", { Scale = 1 }, window)
local transitionId = 0
local activeTweens = {}
local originalVisuals = {}

local function captureVisuals()
    originalVisuals = {}
    local objects = { window }
    for _, descendant in ipairs(window:GetDescendants()) do
        table.insert(objects, descendant)
    end
    for _, object in ipairs(objects) do
        local saved = {}
        if object:IsA("GuiObject") then
            saved.BackgroundTransparency = object.BackgroundTransparency
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                saved.TextTransparency = object.TextTransparency
            end
            if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                saved.ImageTransparency = object.ImageTransparency
            end
        elseif object:IsA("UIStroke") then
            saved.Transparency = object.Transparency
        end
        if next(saved) then
            originalVisuals[object] = saved
        end
    end
end

captureVisuals()

local function cancelVisualTweens()
    for _, tween in ipairs(activeTweens) do
        tween:Cancel()
    end
    table.clear(activeTweens)
end

local function tweenVisuals(closing)
    for object, properties in pairs(originalVisuals) do
        if object.Parent then
            local goals = {}
            for property, original in pairs(properties) do
                if closing then
                    goals[property] = 1
                else
                    goals[property] = original
                end
            end
            local tween = TweenService:Create(
                object,
                TweenInfo.new(0.20, Enum.EasingStyle.Quad, closing and Enum.EasingDirection.In or Enum.EasingDirection.Out),
                goals
            )
            table.insert(activeTweens, tween)
            tween:Play()
        end
    end
end

local function setHubVisible(isVisible)
    transitionId += 1
    local thisTransition = transitionId
    cancelVisualTweens()

    if isVisible then
        reopenButton.Visible = false
        window.Visible = true
        windowScale.Scale = 0.94
        tweenVisuals(false)

        local scaleTween = TweenService:Create(
            windowScale,
            TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }
        )
        table.insert(activeTweens, scaleTween)
        scaleTween:Play()
    else
        tweenVisuals(true)
        local scaleTween = TweenService:Create(
            windowScale,
            TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Scale = 0.94 }
        )
        table.insert(activeTweens, scaleTween)
        scaleTween:Play()

        scaleTween.Completed:Once(function(playbackState)
            if thisTransition ~= transitionId or playbackState ~= Enum.PlaybackState.Completed then
                return
            end
            window.Visible = false
            windowScale.Scale = 1
            reopenButton.Visible = true
            reopenButton.BackgroundTransparency = 1
            reopenButton.TextTransparency = 1
            local buttonTween = TweenService:Create(
                reopenButton,
                TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = 0, TextTransparency = 0 }
            )
            buttonTween:Play()
        end)
    end
end

reopenButton.Activated:Connect(function()
    setHubVisible(true)
end)

hideButton.Activated:Connect(function()
    setHubVisible(false)
end)

minimizeButton.Activated:Connect(function()
    minimized = not minimized
    minimizeButton.Text = minimized and "□" or "—"

    if minimized then
        local tween = TweenService:Create(
            window,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.fromOffset(window.Size.X.Offset, 58) }
        )
        tween:Play()
        tween.Completed:Once(function()
            if minimized then body.Visible = false end
        end)
    else
        body.Visible = true
        updateLayout()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize
        local height = viewport and math.max(180, math.min(500, viewport.Y - 40)) or 500
        TweenService:Create(
            window,
            TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.fromOffset(window.Size.X.Offset, height) }
        ):Play()
    end
end)

-- Responsive layout. Defined before button callbacks can call it.
updateLayout = function()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local compact = viewport.X < 600
    local width = math.max(200, math.min(760, viewport.X - 20))
    local height = math.max(180, math.min(500, viewport.Y - 40))
    local sidebarWidth = compact and 52 or 176
    sidebarWidth = math.min(sidebarWidth, width * 0.34)

    window.Size = UDim2.fromOffset(width, minimized and 58 or height)
    sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
    content.Position = UDim2.new(0, sidebarWidth, 0, 0)
    content.Size = UDim2.new(1, -sidebarWidth, 1, 0)

    sidebarPadding.PaddingLeft = UDim.new(0, compact and 5 or 12)
    sidebarPadding.PaddingRight = UDim.new(0, compact and 5 or 12)
    sidebarHeader.Visible = not compact
    hubSubtitle.Visible = not compact
    localTag.Visible = not compact
    statusBadge.Visible = not compact

    for name, button in pairs(tabButtons) do
        if compact then
            button.Text = tabIcons[name]
            button.TextXAlignment = Enum.TextXAlignment.Center
            button.TextSize = 18
        else
            button.Text = "   " .. tabIcons[name] .. "    " .. name
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.TextSize = 14
        end
    end

    -- Keep the centered window inside the visible viewport.
    local maxX = math.max(0, (viewport.X - width) / 2)
    local maxY = math.max(0, (viewport.Y - window.Size.Y.Offset) / 2)
    window.Position = UDim2.new(
        0.5, math.clamp(window.Position.X.Offset, -maxX, maxX),
        0.5, math.clamp(window.Position.Y.Offset, -maxY, maxY)
    )

    reopenButton.Position = UDim2.new(1, -18, 1, -24)
end

-- Drag with mouse or touch. Touch movement is tracked via the global input stream.
local dragging = false
local dragStart
local windowStart
local activeTouch

dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        activeTouch = nil
    elseif input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        activeTouch = input
    else
        return
    end

    dragStart = input.Position
    windowStart = window.Position
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not windowStart then
        return
    end

    local mouseMove = input.UserInputType == Enum.UserInputType.MouseMovement and activeTouch == nil
    local touchMove = activeTouch ~= nil and input == activeTouch

    if mouseMove or touchMove then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or (activeTouch ~= nil and input == activeTouch) then
        dragging = false
        activeTouch = nil
        dragStart = nil
        windowStart = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setHubVisible(not window.Visible)
    end
end)

local cameraConnection
local function bindCamera(camera)
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)
    end
    updateLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindCamera(workspace.CurrentCamera)
end)

bindCamera(workspace.CurrentCamera)
showPage("Home")
