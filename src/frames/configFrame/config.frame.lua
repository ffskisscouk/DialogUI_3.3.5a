---@diagnostic disable: undefined-global

-- DialogUI configuration system
DialogUI_Config = {
    scale = 1.0,        -- Frame scale (0.5 - 2.0)
    alpha = 1.0,        -- Frame transparency (0.1 - 1.0)
    fontSize = 1.0,     -- Font size multiplier (0.5 - 2.0)
    fontFile = "frizqt___cyr.ttf"  -- Default font
};

-- Available fonts
local AVAILABLE_FONTS = {
    { name = "Magistral", file = "frizqt___cyr.ttf" },
    { name = "PTNarrow", file = "frizqt__.ttf" },
    { name = "Arial", file = "ARIALN.ttf" },
    { name = "Expressway", file = "Expressway.ttf" }
};

local COLORS = {
    DarkBrown = {0.19, 0.17, 0.13},
    LightBrown = {0.50, 0.36, 0.24},
    Ivory = {0.87, 0.86, 0.75}
};

function SetFontColor(fontObject, key)
    local color = COLORS[key];
    if color and fontObject and fontObject.SetTextColor then
        fontObject:SetTextColor(color[1], color[2], color[3]);
    end
end

-- Main configuration window functions
function DConfigFrame_OnLoad()
    -- Disable moving since the window is always centered
    this:SetMovable(false);
    this:EnableMouse(true);

    -- Info text describing available commands
    local infoText = "Configure DialogUI interface parameters.\n\n" ..
                    "• Scale: Change the size of dialog windows (0.5 to 2.0)\n" ..
                    "• Transparency: Adjust background transparency (10% to 100%)\n" ..
                    "• Font size: Change the text size in dialogs (0.5 to 2.0)\n" ..
                    "• Font: Choose the font for dialog text\n" ..
                    "• Dynamic camera: Automatically adjust the camera when talking to an NPC\n\n" ..
                    "Available commands:\n" ..
                    "▪ /dialogui or /dialogui config - open settings window\n" ..
                    "▪ /dialogui reset - reset all settings\n" ..
                    "▪ /togglecamera or /dcamera - toggle dynamic camera on/off\n" ..
                    "▪ /testcamera - test camera positioning\n" ..
                    "▪ /camerapreset [preset] - apply a camera preset (cinematic, close, normal, wide)\n\n" ..
                    "Values can be changed directly in the input fields.\n" ..
                    "All changes are applied and saved automatically.";

    local infoTextObj = getglobal("DConfigInfoText");
    if infoTextObj then
        infoTextObj:SetText(infoText);
        SetFontColor(infoTextObj, "DarkBrown");
    end
end

function DConfigFrame_OnShow()
    PlaySound("igQuestListOpen");

    -- Always keep the settings window at scale 1.0 and centered
    DConfigFrame:SetScale(1.0);
    DConfigFrame:ClearAllPoints();
    DConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    -- Initialize the scroll area
    local scrollFrame = getglobal("DConfigScrollFrame");
    local scrollChild = getglobal("DConfigScrollChild");
    if scrollFrame and scrollChild then
        scrollFrame:SetScrollChild(scrollChild);
        scrollFrame:SetHorizontalScroll(0);
        scrollFrame:SetVerticalScroll(0);
    end

    -- Set colors for labels
    local scaleLabel = getglobal("DConfigScaleLabel");
    if scaleLabel then
        SetFontColor(scaleLabel, "DarkBrown");
        scaleLabel:SetText("Scale:");
    end

    local alphaLabel = getglobal("DConfigAlphaLabel");
    if alphaLabel then
        SetFontColor(alphaLabel, "DarkBrown");
        alphaLabel:SetText("Transparency:");
    end

    local fontLabel = getglobal("DConfigFontLabel");
    if fontLabel then
        SetFontColor(fontLabel, "DarkBrown");
        fontLabel:SetText("Font size:");
    end

    local fontSelectLabel = getglobal("DConfigFontSelectLabel");
    if fontSelectLabel then
        SetFontColor(fontSelectLabel, "DarkBrown");
        fontSelectLabel:SetText("Font:");
    end

    -- Update values in input fields
    local scaleEditBox = getglobal("DConfigScaleEditBox");
    if scaleEditBox then
        scaleEditBox:SetText(string.format("%.1f", DialogUI_Config.scale));
    end

    local alphaEditBox = getglobal("DConfigAlphaEditBox");
    if alphaEditBox then
        alphaEditBox:SetText(tostring(math.floor(DialogUI_Config.alpha * 100)));
    end

    local fontEditBox = getglobal("DConfigFontEditBox");
    if fontEditBox then
        fontEditBox:SetText(string.format("%.1f", DialogUI_Config.fontSize));
    end

    -- Update font selection buttons
    DConfigFrame_UpdateFontButtons();

    -- Apply current transparency to the settings window background
    DialogUI_ApplyConfigAlpha();

    -- Add camera controls AFTER font buttons
    if DynamicCamera and DynamicCamera.AddConfigControls then
        -- Check whether camera controls have already been created
        if not getglobal("DCameraSectionTitle") then
            -- Create controls (they will be created with default anchoring)
            DynamicCamera:AddConfigControls();
        end
        
        -- Move existing camera controls, anchoring to the FIRST font button
        DialogUI_PositionCameraControls();
    end
end

function DConfigFrame_OnHide()
    PlaySound("igQuestListClose");
end

-- Function for correctly positioning camera elements after font buttons
function DialogUI_PositionCameraControls()
    if not DynamicCamera then return; end
    
    local cameraSection = getglobal("DCameraSectionTitle");
    if not cameraSection then return; end
    
    -- Anchor the camera section to the FIRST font button (DConfigFontButton1)
    cameraSection:ClearAllPoints();
    cameraSection:SetPoint("TOP", "DConfigFontButton1", "BOTTOM", 0, -70);
    -- Offset -70 means: 10px after the second row + 10px padding + 50px extra
    
    -- Move the remaining camera elements (they are usually anchored to the title)
    local cameraEnableCheck = getglobal("DCameraEnableCheck");
    if cameraEnableCheck then
        cameraEnableCheck:ClearAllPoints();
        cameraEnableCheck:SetPoint("TOP", cameraSection, "BOTTOM", 0, -10);
    end
    
    local cameraPresetLabel = getglobal("DCameraPresetLabel");
    if cameraPresetLabel then
        cameraPresetLabel:ClearAllPoints();
        cameraPresetLabel:SetPoint("TOP", cameraEnableCheck, "BOTTOM", 0, -15);
    end
    
    -- Anchor presets to the first font button for correct alignment
    local cinematicButton = getglobal("DCameraCinematicButton");
    if cinematicButton then
        cinematicButton:ClearAllPoints();
        cinematicButton:SetPoint("TOPLEFT", "DConfigFontButton1", "BOTTOMLEFT", 0, -140);
    end
    
    local closeButton = getglobal("DCameraCloseButton");
    if closeButton then
        closeButton:ClearAllPoints();
        closeButton:SetPoint("LEFT", cinematicButton, "RIGHT", 10, 0);
    end
    
    local normalButton = getglobal("DCameraNormalButton");
    if normalButton then
        normalButton:ClearAllPoints();
        normalButton:SetPoint("LEFT", closeButton, "RIGHT", 10, 0);
    end
    
    local wideButton = getglobal("DCameraWideButton");
    if wideButton then
        wideButton:ClearAllPoints();
        wideButton:SetPoint("LEFT", normalButton, "RIGHT", 10, 0);
    end
    
    -- Update if an update function exists
    if DynamicCamera.UpdateConfigControls then
        DynamicCamera.UpdateConfigControls();
    end
    
    -- Adjust the scroll container height to fit all elements
    local scrollChild = getglobal("DConfigScrollChild");
    if scrollChild then
        -- Get the bottom boundary of the last camera element
        local lastCameraControl = getglobal("DCameraWideButton") or getglobal("DCameraEnableCheck");
        if lastCameraControl then
            local bottom = lastCameraControl:GetBottom();
            local childTop = scrollChild:GetTop();
            if bottom and childTop then
                local requiredHeight = childTop - bottom + 50; -- +50 for padding
                scrollChild:SetHeight(math.max(requiredHeight, 900));
            end
        end
    end
end

-- Input field functions
function DConfigScaleEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigScaleEditBox");
    if not editBox then return; end

    local text = editBox:GetText();
    -- Replace comma with period to support decimal numbers
    text = string.gsub(text, ",", ".");
    local value = tonumber(text);

    if value and value >= 0.5 and value <= 2.0 then
        DialogUI_Config.scale = value;
        editBox:SetText(string.format("%.1f", value));
        DialogUI_ApplyScale();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Scale set to " .. string.format("%.1f", value));
        end
    else
        editBox:SetText(string.format("%.1f", DialogUI_Config.scale));
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Scale must be between 0.5 and 2.0 (example: 1.5)");
        end
    end
end

function DConfigAlphaEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigAlphaEditBox");
    if not editBox then return; end

    local value = tonumber(editBox:GetText());
    if value and value >= 10 and value <= 100 then
        local alpha = value / 100;
        DialogUI_Config.alpha = alpha;
        editBox:SetText(tostring(value));
        DialogUI_ApplyAlpha();
        DialogUI_ApplyConfigAlpha();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Transparency set to " .. value .. "%");
        end
    else
        editBox:SetText(tostring(math.floor(DialogUI_Config.alpha * 100)));
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Transparency must be between 10 and 100 (whole numbers only)");
        end
    end
end

function DConfigFontEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigFontEditBox");
    if not editBox then return; end

    local text = editBox:GetText();
    -- Replace comma with period to support decimal numbers
    text = string.gsub(text, ",", ".");
    local value = tonumber(text);

    if value and value >= 0.5 and value <= 2.0 then
        DialogUI_Config.fontSize = value;
        editBox:SetText(string.format("%.1f", value));
        DialogUI_ApplyFontSize();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Font size set to " .. string.format("%.1f", value));
        end
    else
        editBox:SetText(string.format("%.1f", DialogUI_Config.fontSize));
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Font size must be between 0.5 and 2.0 (example: 1.2)");
        end
    end
end

-- Button functions
function DConfigResetButton_OnClick()
    -- Reset to default values
    DialogUI_Config.scale = 1.0;
    DialogUI_Config.alpha = 1.0;
    DialogUI_Config.fontSize = 1.0;
    DialogUI_Config.fontFile = "frizqt___cyr.ttf";

    -- Update input fields
    local scaleEditBox = getglobal("DConfigScaleEditBox");
    if scaleEditBox then
        scaleEditBox:SetText("1.0");
    end

    local alphaEditBox = getglobal("DConfigAlphaEditBox");
    if alphaEditBox then
        alphaEditBox:SetText("100");
    end

    local fontEditBox = getglobal("DConfigFontEditBox");
    if fontEditBox then
        fontEditBox:SetText("1.0");
    end

    -- Update font buttons
    DConfigFrame_UpdateFontButtons();

    -- Apply changes
    DialogUI_ApplyAllSettings();
    DialogUI_SaveConfig();

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Settings reset to default values");
    end
    PlaySound("igQuestListComplete");
end

function DConfigCloseButton_OnClick()
    HideUIPanel(DConfigFrame);
end

-- Configuration apply functions
function DialogUI_ApplyScale()
    local scale = DialogUI_Config.scale;

    -- Apply scale only to dialog windows, NOT to the config window
    if DQuestFrame then
        DQuestFrame:SetScale(scale);
    end
    if DGossipFrame then
        DGossipFrame:SetScale(scale);
    end
    -- The config window keeps a fixed scale of 1.0
end

function DialogUI_ApplyAlpha()
    local alpha = DialogUI_Config.alpha;

    -- Apply transparency to the quest window and its panels
    if DQuestFrame then
        DialogUI_ApplyAlphaToPanel(DQuestFrame, alpha);

        local rewardPanel = getglobal("DQuestFrameRewardPanel");
        if rewardPanel then
            DialogUI_ApplyAlphaToPanel(rewardPanel, alpha);
        end

        local progressPanel = getglobal("DQuestFrameProgressPanel");
        if progressPanel then
            DialogUI_ApplyAlphaToPanel(progressPanel, alpha);
        end

        local greetingPanel = getglobal("DQuestFrameGreetingPanel");
        if greetingPanel then
            DialogUI_ApplyAlphaToPanel(greetingPanel, alpha);
        end

        local detailPanel = getglobal("DQuestFrameDetailPanel");
        if detailPanel then
            DialogUI_ApplyAlphaToPanel(detailPanel, alpha);
        end
    end

    -- Apply transparency to the gossip window
    if DGossipFrame then
        DialogUI_ApplyAlphaToPanel(DGossipFrame, alpha);

        local gossipGreetingPanel = getglobal("DGossipFrameGreetingPanel");
        if gossipGreetingPanel then
            DialogUI_ApplyAlphaToPanel(gossipGreetingPanel, alpha);
        end
    end

    -- Apply transparency to any money frames that may exist
    local moneyFrame = getglobal("DQuestProgressRequiredMoneyFrame");
    if moneyFrame then
        DialogUI_ApplyAlphaToPanel(moneyFrame, alpha);
    end

    -- Config window transparency is handled separately by DialogUI_ApplyConfigAlpha()
end

-- Helper function to apply transparency to a panel's background texture
function DialogUI_ApplyAlphaToPanel(panel, alpha)
    if not panel then return; end
    local regions = {panel:GetRegions()};
    for i = 1, table.getn(regions) do
        local region = regions[i];
        if region and region:GetObjectType() == "Texture" then
            local texturePath = region:GetTexture();
            if texturePath and string.find(texturePath, "Parchment") then
                region:SetAlpha(alpha);
                break;
            end
        end
    end
end

-- Simple version without saving original sizes
function DialogUI_ApplyFontSize()
    local fontSize = DialogUI_Config.fontSize;
    
    -- Iterate over all frames and apply scale
    -- WoW automatically uses the base font size from the template
    
    if DQuestFrame then
        -- First "reset" by iterating all regions and applying scale
        -- Since the base size comes from the template, multiplying by 1.0 gives the original size
        DialogUI_ScaleFonts(DQuestFrame, 1.0);  -- Reset to base
        DialogUI_ScaleFonts(DQuestFrame, fontSize);  -- Apply new scale
    end
    
    if DGossipFrame then
        DialogUI_ScaleFonts(DGossipFrame, 1.0);  -- Reset to base
        DialogUI_ScaleFonts(DGossipFrame, fontSize);  -- Apply new scale
    end
end

function DialogUI_ScaleFonts(frame, scale)
    if not frame then return; end
    
    local regions = {frame:GetRegions()};
    for i = 1, #regions do
        local region = regions[i];
        if region and region:GetObjectType() == "FontString" then
            local fontName, fontSize, fontFlags = region:GetFont();
            if fontName and fontSize then
                -- For reset, use scale=1.0 which returns to the template size
                region:SetFont(fontName, fontSize * scale, fontFlags);
            end
        end
    end
    
    local children = {frame:GetChildren()};
    for i = 1, table.getn(children) do
        local child = children[i];
        if child then
            DialogUI_ScaleFonts(child, scale);
        end
    end
end

function DialogUI_ApplyAllSettings()
    DialogUI_ApplyScale();
    DialogUI_ApplyAlpha();
    DialogUI_ApplyFontSize();
    DialogUI_ApplyFont();
end

-- Save / Load configuration
function DialogUI_SaveConfig()
    if not DialogUI_SavedConfig then
        DialogUI_SavedConfig = {};
    end

    DialogUI_SavedConfig.scale = DialogUI_Config.scale;
    DialogUI_SavedConfig.alpha = DialogUI_Config.alpha;
    DialogUI_SavedConfig.fontSize = DialogUI_Config.fontSize;
    DialogUI_SavedConfig.fontFile = DialogUI_Config.fontFile;
end

function DialogUI_LoadConfig()
    if DialogUI_SavedConfig then
        DialogUI_Config.scale = DialogUI_SavedConfig.scale or 1.0;
        DialogUI_Config.alpha = DialogUI_SavedConfig.alpha or 1.0;
        DialogUI_Config.fontSize = DialogUI_SavedConfig.fontSize or 1.0;
        DialogUI_Config.fontFile = DialogUI_SavedConfig.fontFile or "frizqt___cyr.ttf";

        DialogUI_ApplyAllSettings();
    end
end

-- Config window show/hide functions
function DialogUI_ShowConfig()
    if DConfigFrame then
        ShowUIPanel(DConfigFrame);
    end
end

function DialogUI_HideConfig()
    if DConfigFrame then
        HideUIPanel(DConfigFrame);
    end
end

function DialogUI_ToggleConfig()
    if DConfigFrame and DConfigFrame:IsVisible() then
        DialogUI_HideConfig();
    else
        DialogUI_ShowConfig();
    end
end

-- Special transparency function for the config window
function DialogUI_ApplyConfigAlpha()
    local alpha = DialogUI_Config.alpha;

    if DConfigFrame then
        local layers = {DConfigFrame:GetRegions()};
        for i = 1, table.getn(layers) do
            if layers[i]:GetObjectType() == "Texture" then
                layers[i]:SetAlpha(alpha);
                break;
            end
        end
    end
end

-- ==========================================
-- Font selection functions
-- ==========================================

function DConfigFrame_UpdateFontButtons()
    local currentFont = DialogUI_Config.fontFile or "frizqt___cyr.ttf";
    
    for i, fontData in ipairs(AVAILABLE_FONTS) do
        local button = getglobal("DConfigFontButton" .. i);
        local check = getglobal("DConfigFontButton" .. i .. "Check");
        
        if button and check then
            if fontData.file == currentFont then
                -- Selected font
                check:Show();
                button:SetNormalTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\ButtonHighlight-Gossip");
            else
                -- Unselected font
                check:Hide();
                button:SetNormalTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\OptionBackground-common");
            end
            
            -- Set button text
            local text = getglobal(button:GetName() .. "Text");
            if text then
                text:SetText(fontData.name);
            end
        end
    end
end

function DConfigFontButton_OnClick(index)
    if not index or index < 1 or index > #AVAILABLE_FONTS then return; end
    
    local fontData = AVAILABLE_FONTS[index];
    if not fontData then return; end
    
    DialogUI_Config.fontFile = fontData.file;
    
    -- Update the visual state of buttons
    DConfigFrame_UpdateFontButtons();
    
    -- Apply the font
    DialogUI_ApplyFont();
    
    -- Save
    DialogUI_SaveConfig();
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Font changed to " .. fontData.name);
    end
    
    PlaySound("igMainMenuOptionCheckBoxOn");
end

function DialogUI_ApplyFont()
    local fontFile = DialogUI_Config.fontFile or "frizqt___cyr.ttf";
    local fontPath = "Interface\\AddOns\\DialogUI\\src\\assets\\font\\" .. fontFile;
    
    -- Apply font to all text elements in DQuestFrame
    if DQuestFrame then
        DialogUI_SetFontForFrame(DQuestFrame, fontPath);
    end
    
    -- Apply font to all text elements in DGossipFrame
    if DGossipFrame then
        DialogUI_SetFontForFrame(DGossipFrame, fontPath);
    end
    
    -- Apply font to the config window
    if DConfigFrame then
        DialogUI_SetFontForFrame(DConfigFrame, fontPath);
    end
end

function DialogUI_SetFontForFrame(frame, fontPath)
    if not frame then return; end
    
    local regions = {frame:GetRegions()};
    for i = 1, #regions do
        local region = regions[i];
        if region and region:GetObjectType() == "FontString" then
            local _, fontSize, fontFlags = region:GetFont();
            if fontSize then
                region:SetFont(fontPath, fontSize, fontFlags);
            end
        end
    end
    
    -- Recursively process child frames
    local children = {frame:GetChildren()};
    for i = 1, table.getn(children) do
        local child = children[i];
        if child then
            DialogUI_SetFontForFrame(child, fontPath);
        end
    end
end

function DialogUI_GetFontPath()
    local fontFile = DialogUI_Config.fontFile or "frizqt___cyr.ttf";
    return "Interface\\AddOns\\DialogUI\\src\\assets\\font\\" .. fontFile;
end
