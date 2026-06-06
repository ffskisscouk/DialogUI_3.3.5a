-- Dynamic Camera module for DialogUI
-- Compatible with WoW 3.3.5

-- Camera module initialization
DynamicCamera = {};
DynamicCamera.isActive = false;
DynamicCamera.originalDistance = nil;
DynamicCamera.originalPitch = nil;
DynamicCamera.originalYaw = nil;
DynamicCamera.originalView = nil;
DynamicCamera.transitionActive = false;
DynamicCamera.initialized = false;
DynamicCamera.savedMaxDistance = nil;

-- Use GLOBAL variable (automatically saved in WTF folder)
if not _G.DialogUI_CameraSaved then
    _G.DialogUI_CameraSaved = {};
end
DialogUI_CameraSaved = _G.DialogUI_CameraSaved;

-- Default camera settings
DynamicCamera.config = {
    enabled = true,
    interactionDistance = 3,
    interactionPitch = -0.1,
    transitionSpeed = 2.0,
    enableForGossip = true,
    enableForVendors = true,
    enableForTrainers = true,
    enableForQuests = true,
    usePresetRestore = false,
    presetView = 2,
    savedCameraYaw = nil,
    savedCameraPitch = nil,
    savedCameraDistance = nil,
    useFaceView = true,
    faceViewDistance = 2.5,
    useFirstPersonView = true,
};

-- Force load from global saved data
function DynamicCamera:ForceLoadConfig()
    if DialogUI_CameraSaved then
        if DialogUI_CameraSaved.enabled ~= nil then
            self.config.enabled = DialogUI_CameraSaved.enabled;
        else
            -- If no saved value, set default and save
            self.config.enabled = false;  -- DEFAULT CHANGED TO OFF
            self:ForceSaveConfig();
        end
        
        if DialogUI_CameraSaved.interactionDistance then
            self.config.interactionDistance = DialogUI_CameraSaved.interactionDistance;
        end
        if DialogUI_CameraSaved.interactionPitch then
            self.config.interactionPitch = DialogUI_CameraSaved.interactionPitch;
        end
        if DialogUI_CameraSaved.transitionSpeed then
            self.config.transitionSpeed = DialogUI_CameraSaved.transitionSpeed;
        end
        if DialogUI_CameraSaved.enableForGossip ~= nil then
            self.config.enableForGossip = DialogUI_CameraSaved.enableForGossip;
        end
        if DialogUI_CameraSaved.enableForVendors ~= nil then
            self.config.enableForVendors = DialogUI_CameraSaved.enableForVendors;
        end
        if DialogUI_CameraSaved.enableForTrainers ~= nil then
            self.config.enableForTrainers = DialogUI_CameraSaved.enableForTrainers;
        end
        if DialogUI_CameraSaved.enableForQuests ~= nil then
            self.config.enableForQuests = DialogUI_CameraSaved.enableForQuests;
        end
        if DialogUI_CameraSaved.usePresetRestore ~= nil then
            self.config.usePresetRestore = DialogUI_CameraSaved.usePresetRestore;
        end
        if DialogUI_CameraSaved.presetView then
            self.config.presetView = DialogUI_CameraSaved.presetView;
        end
        if DialogUI_CameraSaved.useFaceView ~= nil then
            self.config.useFaceView = DialogUI_CameraSaved.useFaceView;
        end
        if DialogUI_CameraSaved.faceViewDistance then
            self.config.faceViewDistance = DialogUI_CameraSaved.faceViewDistance;
        end
        if DialogUI_CameraSaved.useFirstPersonView ~= nil then
            self.config.useFirstPersonView = DialogUI_CameraSaved.useFirstPersonView;
        end
    else
        -- No saved data — camera disabled by default
        self.config.enabled = false;
        self:ForceSaveConfig();
    end
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camera configuration loaded (enabled: " .. (self.config.enabled and "YES" or "NO") .. ")");
    end
end

-- Force save to global storage
function DynamicCamera:ForceSaveConfig()
    DialogUI_CameraSaved = {
        enabled = self.config.enabled,
        interactionDistance = self.config.interactionDistance,
        interactionPitch = self.config.interactionPitch,
        transitionSpeed = self.config.transitionSpeed,
        enableForGossip = self.config.enableForGossip,
        enableForVendors = self.config.enableForVendors,
        enableForTrainers = self.config.enableForTrainers,
        enableForQuests = self.config.enableForQuests,
        usePresetRestore = self.config.usePresetRestore,
        presetView = self.config.presetView,
        savedCameraYaw = self.config.savedCameraYaw,
        savedCameraPitch = self.config.savedCameraPitch,
        savedCameraDistance = self.config.savedCameraDistance,
        useFaceView = self.config.useFaceView,
        faceViewDistance = self.config.faceViewDistance,
        useFirstPersonView = self.config.useFirstPersonView,
    };
    
    -- Update global reference
    _G.DialogUI_CameraSaved = DialogUI_CameraSaved;
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camera configuration saved (enabled: " .. (self.config.enabled and "YES" or "NO") .. ")");
    end
end

-- Immediately save enabled state
function DynamicCamera:SetEnabled(state)
    self.config.enabled = state;
    self:ForceSaveConfig();
    
    if state == false and self.isActive then
        self:RestoreOriginalPosition();
        self.isActive = false;
    end
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Dynamic camera " .. (state and "enabled" or "disabled"));
    end
end

-- Save original camera position
function DynamicCamera:SaveOriginalPosition()
    if not self.isActive then
        if GetCVar then
            self.originalDistance = tonumber(GetCVar("cameraDistanceMax")) or 15;
            self.originalView = tonumber(GetCVar("cameraView")) or 2;
            self.originalDistanceFactor = tonumber(GetCVar("cameraDistanceMaxFactor")) or 1.0;
        end

        if self.config.savedCameraPitch then
            self.originalPitch = self.config.savedCameraPitch;
        end
        if self.config.savedCameraYaw then
            self.originalYaw = self.config.savedCameraYaw;
        end
    end
end

-- Apply camera position for interaction
function DynamicCamera:ApplyInteractionPosition()
    if not self.config.enabled then return; end
    if self.isActive then return; end

    self:SaveOriginalPosition();

    if self.config.useFaceView then
        self:ApplyFaceView();
    else
        self:ApplyImmediateCamera(self.config.interactionDistance, self.config.interactionPitch, self.originalYaw);
    end

    self.isActive = true;
end

-- Apply "face NPC" view
function DynamicCamera:ApplyFaceView()
    if not self.config.useFaceView then return; end

    self.savedMaxDistance = tonumber(GetCVar("cameraDistanceMax")) or 15;
    
    if self.config.useFirstPersonView and SetView then
        SetView(1);
        
        if SetCVar then
            SetCVar("cameraDistanceMax", tostring(self.config.faceViewDistance));
            SetCVar("cameraDistanceMaxFactor", "1.0");
        end
        
        if CameraZoomIn then
            for i = 1, 5 do
                CameraZoomIn(1.0);
            end
        end
    else
        if SetCVar then
            SetCVar("cameraDistanceMax", tostring(self.config.faceViewDistance));
        end
        
        if CameraZoomIn then
            for i = 1, 10 do
                CameraZoomIn(1.0);
            end
        end
    end
end

-- Restore original camera position
function DynamicCamera:RestoreOriginalPosition()
    if not self.originalDistance then return; end

    if SetView then
        if self.originalView and self.originalView ~= 1 then
            SetView(self.originalView);
        else
            SetView(2);
        end
    end

    if SetCVar and self.originalDistance then
        SetCVar("cameraDistanceMax", tostring(self.originalDistance));
        if self.originalDistanceFactor then
            SetCVar("cameraDistanceMaxFactor", tostring(self.originalDistanceFactor));
        end
    end

    local currentDist = tonumber(GetCVar("cameraDistanceMax")) or 15;
    local targetDist = self.originalDistance or 15;
    
    if math.abs(currentDist - targetDist) > 0.5 then
        if currentDist < targetDist then
            local steps = math.min(math.ceil((targetDist - currentDist) / 2), 8);
            for i = 1, steps do
                CameraZoomOut(1.0);
            end
        elseif currentDist > targetDist then
            local steps = math.min(math.ceil((currentDist - targetDist) / 2), 8);
            for i = 1, steps do
                CameraZoomIn(1.0);
            end
        end
    end

    self.isActive = false;
    self.originalDistance = nil;
    self.originalPitch = nil;
    self.originalYaw = nil;
    self.originalView = nil;
    self.savedMaxDistance = nil;
end

-- Force restore camera
function DynamicCamera:ForceRestore()
    if SetView then
        SetView(2);
    end
    
    if SetCVar and self.originalDistance then
        SetCVar("cameraDistanceMax", tostring(self.originalDistance));
    elseif SetCVar then
        SetCVar("cameraDistanceMax", "15");
    end
    
    self.isActive = false;
end

-- Apply camera settings immediately
function DynamicCamera:ApplyImmediateCamera(distance, pitch, yaw)
    if SetCVar and distance then
        SetCVar("cameraDistanceMax", tostring(distance));
        SetCVar("cameraDistanceMaxFactor", "1.0");
    end
    
    if CameraZoomIn and distance then
        local currentDist = tonumber(GetCVar("cameraDistanceMax")) or 15;
        if currentDist > distance then
            for i = 1, 3 do
                CameraZoomIn(1.0);
            end
        end
    end
end

-- Event handlers
function DynamicCamera:OnGossipShow()
    if not self.config.enabled then return; end
    if self.config.enableForGossip then self:ApplyInteractionPosition(); end
end

function DynamicCamera:OnGossipClosed()
    if not self.config.enabled then return; end
    if self.config.enableForGossip and self.isActive then self:RestoreOriginalPosition(); end
end

function DynamicCamera:OnMerchantShow()
    if not self.config.enabled then return; end
    if self.config.enableForVendors then self:ApplyInteractionPosition(); end
end

function DynamicCamera:OnMerchantClosed()
    if not self.config.enabled then return; end
    if self.config.enableForVendors and self.isActive then self:RestoreOriginalPosition(); end
end

function DynamicCamera:OnTrainerShow()
    if not self.config.enabled then return; end
    if self.config.enableForTrainers then self:ApplyInteractionPosition(); end
end

function DynamicCamera:OnTrainerClosed()
    if not self.config.enabled then return; end
    if self.config.enableForTrainers and self.isActive then self:RestoreOriginalPosition(); end
end

function DynamicCamera:OnQuestDetail()
    if not self.config.enabled then return; end
    if self.config.enableForQuests then
        if not self.isActive then self:ApplyInteractionPosition(); end
    end
end

function DynamicCamera:OnQuestFinished()
    if not self.config.enabled then return; end
    if self.config.enableForQuests and self.isActive then self:RestoreOriginalPosition(); end
end

-- Load config
function DynamicCamera:LoadConfig()
    self:ForceLoadConfig();
end

-- Save config
function DynamicCamera:SaveConfig()
    self:ForceSaveConfig();
end

-- Apply preset
function DynamicCamera:ApplyPreset(presetName)
    if presetName == "cinematic" then
        self.config.faceViewDistance = 2.0;
        self.config.useFaceView = true;
    elseif presetName == "close" then
        self.config.faceViewDistance = 1.5;
        self.config.useFaceView = true;
    elseif presetName == "normal" then
        self.config.faceViewDistance = 2.5;
        self.config.useFaceView = true;
    elseif presetName == "wide" then
        self.config.useFaceView = false;
        self.config.interactionDistance = 8;
    end

    self:ForceSaveConfig();
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camera preset '" .. presetName .. "' applied");
    end
end

-- Save current camera view
function DynamicCamera:SaveCameraPreset()
    local currentDistance = tonumber(GetCVar("cameraDistanceMax")) or self.config.faceViewDistance;
    local currentPitch = nil;
    local currentYaw = nil;
    
    if GetCameraPosition then
        currentYaw, currentPitch = GetCameraPosition();
    end
    
    self.config.savedCameraDistance = currentDistance;
    self.config.savedCameraPitch = currentPitch;
    self.config.savedCameraYaw = currentYaw;
    self.config.usePresetRestore = true;
    
    self:ForceSaveConfig();
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Current camera view saved (distance: " .. string.format("%.1f", currentDistance) .. ")");
    end
end

-- Update controls
function DynamicCamera:UpdateConfigControls()
    local checkbox = getglobal("DCameraEnabledCheckbox");
    if checkbox and checkbox.SetChecked then
        checkbox:SetChecked(self.config.enabled);
    end
end

-- Add controls to config
function DynamicCamera:AddConfigControls(offsetY)
    local parent = getglobal("DConfigScrollChild") or getglobal("DConfigFrame");
    if not parent then return; end

    local fontSelectLabel = getglobal("DConfigFontSelectLabel");
    if not fontSelectLabel then return; end

    if getglobal("DCameraSectionTitle") then
        self:UpdateConfigControls();
        return;
    end

    local yOffset = offsetY or 40;

    local cameraTitle = parent:CreateFontString("DCameraSectionTitle", "OVERLAY", "DQuestButtonTitleGossip");
    cameraTitle:SetPoint("TOPLEFT", fontSelectLabel, "BOTTOMLEFT", 0, -yOffset);
    cameraTitle:SetText("Camera Settings");
    cameraTitle:SetJustifyH("LEFT");
    if SetFontColor then SetFontColor(cameraTitle, "DarkBrown"); end

    local cameraEnabledCheckbox = CreateFrame("CheckButton", "DCameraEnabledCheckbox", parent, "UICheckButtonTemplate");
    cameraEnabledCheckbox:SetPoint("TOPLEFT", cameraTitle, "BOTTOMLEFT", 0, -15);
    cameraEnabledCheckbox:SetScale(0.8);
    cameraEnabledCheckbox:SetChecked(self.config.enabled);

    local cameraEnabledLabel = parent:CreateFontString("DCameraEnabledLabel", "OVERLAY", "DQuestButtonTitleGossip");
    cameraEnabledLabel:SetPoint("LEFT", cameraEnabledCheckbox, "RIGHT", 5, 0);
    cameraEnabledLabel:SetText("Enable Dynamic Camera");
    if SetFontColor then SetFontColor(cameraEnabledLabel, "DarkBrown"); end

    cameraEnabledCheckbox:SetScript("OnClick", function()
        DynamicCamera:SetEnabled(cameraEnabledCheckbox:GetChecked());
    end);
end

-- Initialization
function DynamicCamera:Initialize()
    if self.initialized then return; end

    self:ForceLoadConfig();

    local eventFrame = CreateFrame("Frame", "DynamicCameraEventFrame");
    eventFrame:RegisterEvent("GOSSIP_SHOW");
    eventFrame:RegisterEvent("GOSSIP_CLOSED");
    eventFrame:RegisterEvent("MERCHANT_SHOW");
    eventFrame:RegisterEvent("MERCHANT_CLOSED");
    eventFrame:RegisterEvent("TRAINER_SHOW");
    eventFrame:RegisterEvent("TRAINER_CLOSED");
    eventFrame:RegisterEvent("QUEST_DETAIL");
    eventFrame:RegisterEvent("QUEST_FINISHED");
    eventFrame:RegisterEvent("QUEST_COMPLETE");

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "GOSSIP_SHOW" then DynamicCamera:OnGossipShow();
        elseif event == "GOSSIP_CLOSED" then DynamicCamera:OnGossipClosed();
        elseif event == "MERCHANT_SHOW" then DynamicCamera:OnMerchantShow();
        elseif event == "MERCHANT_CLOSED" then DynamicCamera:OnMerchantClosed();
        elseif event == "TRAINER_SHOW" then DynamicCamera:OnTrainerShow();
        elseif event == "TRAINER_CLOSED" then DynamicCamera:OnTrainerClosed();
        elseif event == "QUEST_DETAIL" then DynamicCamera:OnQuestDetail();
        elseif event == "QUEST_FINISHED" or event == "QUEST_COMPLETE" then DynamicCamera:OnQuestFinished();
        end
    end);

    self.initialized = true;

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Dynamic camera initialized (enabled: " .. (self.config.enabled and "YES" or "NO") .. ")");
    end
end

-- Slash commands
SlashCmdList["DYNAMICCAMERA_TOGGLE"] = function()
    DynamicCamera:SetEnabled(not DynamicCamera.config.enabled);
end;
SLASH_DYNAMICCAMERA_TOGGLE1 = "/togglecamera";
SLASH_DYNAMICCAMERA_TOGGLE2 = "/dcamera";

SlashCmdList["DYNAMICCAMERA_TEST"] = function()
    if DynamicCamera.isActive then DynamicCamera:RestoreOriginalPosition();
    else DynamicCamera:ApplyInteractionPosition(); end
end;
SLASH_DYNAMICCAMERA_TEST1 = "/testcamera";

SlashCmdList["CAMERA_PRESET"] = function(msg)
    local preset = string.lower(msg or "");
    if preset == "cinematic" or preset == "close" or preset == "normal" or preset == "wide" then
        DynamicCamera:ApplyPreset(preset);
    else
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Available presets: cinematic, close, normal, wide");
        end
    end
end;
SLASH_CAMERA_PRESET1 = "/camerapreset";

-- Auto‑initialize
DynamicCamera:Initialize();
