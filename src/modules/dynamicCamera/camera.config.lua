-- Динамическая интеграция конфигурации камеры
-- Расширяет окно конфигурации DialogUI элементами управления камерой
-- Совместимо с WoW 3.3.5
-- ИСПРАВЛЕНО: Добавлен параметр offsetY для позиционирования
-- ИСПРАВЛЕНО: Исправлена ошибка с индексацией self

-- Глобальная переменная для управления дебаг-сообщениями
-- Установите в false, чтобы отключить все дебаг-сообщения
DialogUI_DebugEnabled = false;

-- Вспомогательная функция для вывода дебаг-сообщений
function DialogUI_DebugMessage(message)
    if DialogUI_DebugEnabled and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    end
end

-- Отладочное сообщение для подтверждения загрузки файла
DialogUI_DebugMessage("DialogUI: camera.config.lua загружается...");

-- Добавить элементы управления камерой в окно конфигурации
-- ИСПРАВЛЕНО: Добавлен параметр offsetY для позиционирования
function DynamicCamera:AddConfigControls(offsetY)
    DialogUI_DebugMessage("DialogUI: Попытка добавить элементы управления камерой...");

    -- ИСПРАВЛЕНО: Используем self для доступа к методам объекта
    local self = DynamicCamera; -- Гарантируем, что self определен

    -- ИСПРАВЛЕНО: Используем getglobal для безопасного получения фреймов
    local parent = getglobal("DConfigScrollChild") or getglobal("DConfigFrame");
    if not parent then
        DialogUI_DebugMessage("DialogUI: ОШИБКА - Не найден DConfigScrollChild или DConfigFrame");
        return;
    end

    DialogUI_DebugMessage("DialogUI: Родительский элемент найден: " .. (parent:GetName() or "неизвестно"));

    -- Проверяем существование DConfigFontSelectLabel
    local fontSelectLabel = getglobal("DConfigFontSelectLabel");
    if not fontSelectLabel then
        DialogUI_DebugMessage("DialogUI: ОШИБКА - DConfigFontSelectLabel не существует");
        return;
    end

    DialogUI_DebugMessage("DialogUI: DConfigFontSelectLabel найден, создаем раздел камеры...");

    -- Проверяем, существует ли уже раздел камеры (избегаем дубликатов)
    if getglobal("DCameraSectionTitle") then
        self:UpdateConfigControls();
        return;
    end

    -- ИСПРАВЛЕНО: Используем offsetY для позиционирования, если он передан
    local yOffset = offsetY or 40; -- По умолчанию 40, если параметр не передан

    -- Создаем заголовок раздела камеры
    local cameraTitle = parent:CreateFontString("DCameraSectionTitle", "OVERLAY", "DQuestButtonTitleGossip");
    cameraTitle:SetPoint("TOPLEFT", fontSelectLabel, "BOTTOMLEFT", 0, -yOffset);
    cameraTitle:SetText("Настройки Камеры");
    cameraTitle:SetJustifyH("LEFT");
    if SetFontColor then
        SetFontColor(cameraTitle, "DarkBrown");
    end

    -- Флажок включения камеры
	local cameraEnabledCheckbox = CreateFrame("CheckButton", "DCameraEnabledCheckbox", parent, "UICheckButtonTemplate");
	cameraEnabledCheckbox:SetPoint("TOPLEFT", cameraTitle, "BOTTOMLEFT", 0, -15);
	cameraEnabledCheckbox:SetScale(0.8);
	cameraEnabledCheckbox:SetChecked(DynamicCamera.config.enabled);

	local cameraEnabledLabel = parent:CreateFontString("DCameraEnabledLabel", "OVERLAY", "DQuestButtonTitleGossip");
	cameraEnabledLabel:SetPoint("LEFT", cameraEnabledCheckbox, "RIGHT", 5, 0);
	cameraEnabledLabel:SetText("Включить Динамическую Камеру");
	if SetFontColor then
		SetFontColor(cameraEnabledLabel, "DarkBrown");
	end

	cameraEnabledCheckbox:SetScript("OnClick", function()
		local newState = cameraEnabledCheckbox:GetChecked();
		DynamicCamera:SetEnabled(newState);
		
		-- Обновляем отображение в UI
		if DynamicCamera.UpdateConfigControls then
			DynamicCamera:UpdateConfigControls();
		end
	end);

    -- Флажок Face View
    local faceViewCheckbox = CreateFrame("CheckButton", "DCameraFaceViewCheckbox", parent, "UICheckButtonTemplate");
    faceViewCheckbox:SetPoint("TOPLEFT", cameraEnabledCheckbox, "BOTTOMLEFT", 0, -5);
    faceViewCheckbox:SetScale(0.8);
    faceViewCheckbox:SetChecked(self.config.useFaceView);

    local faceViewLabel = parent:CreateFontString("DCameraFaceViewLabel", "OVERLAY", "DQuestButtonTitleGossip");
    faceViewLabel:SetPoint("LEFT", faceViewCheckbox, "RIGHT", 5, 0);
    faceViewLabel:SetText("Режим Face View (лицом к NPC)");
    if SetFontColor then
        SetFontColor(faceViewLabel, "DarkBrown");
    end

    faceViewCheckbox:SetScript("OnClick", function()
        DynamicCamera.config.useFaceView = faceViewCheckbox:GetChecked();
        DynamicCamera:SaveConfig();

        local status = DynamicCamera.config.useFaceView and "включен" or "отключен";
        DialogUI_DebugMessage("DialogUI: Face View " .. status);
    end);

    -- Отображение настроек
    local settingsRow = parent:CreateFontString("DCameraSettingsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    settingsRow:SetPoint("TOPLEFT", faceViewCheckbox, "BOTTOMLEFT", 0, -25);
    settingsRow:SetText("Дистанция: " .. string.format("%.1f", self.config.faceViewDistance) .. 
                       " | Режим: " .. (self.config.useFaceView and "Лицом" or "Обычный"));
    if SetFontColor then
        SetFontColor(settingsRow, "DarkBrown");
    end

    -- Сохраняем ссылку для обновлений
    self.settingsLabel = settingsRow;

    -- Типы взаимодействий
    local typesLabel = parent:CreateFontString("DInteractionTypesLabel", "OVERLAY", "DQuestButtonTitleGossip");
    typesLabel:SetPoint("TOPLEFT", settingsRow, "BOTTOMLEFT", 0, -25);
    typesLabel:SetText("Включить для: ");
    if SetFontColor then
        SetFontColor(typesLabel, "DarkBrown");
    end

    -- ЕДИНСТВЕННЫЙ ПРАВИЛЬНЫЙ ЦИКЛ для чекбоксов
    local checkboxData = {
        {name = "Разговоры", config = "enableForGossip"},
        {name = "Торговцы", config = "enableForVendors"},
        {name = "Тренеры", config = "enableForTrainers"},
        {name = "Квесты", config = "enableForQuests"}
    };

    -- Создаем чекбоксы вертикально
    for i, data in ipairs(checkboxData) do
        local checkbox = CreateFrame("CheckButton", "DCamera" .. data.name .. "Checkbox", parent, "UICheckButtonTemplate");
        
        -- Вертикальное расположение (каждый ниже предыдущего)
        checkbox:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", 0, -15 - ((i-1) * 25));
        checkbox:SetScale(0.7);
        checkbox:SetChecked(self.config[data.config]);
        
        local label = parent:CreateFontString("DCamera" .. data.name .. "Label", "OVERLAY", "DQuestButtonTitleGossip");
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
        label:SetText(data.name);
        if SetFontColor then
            SetFontColor(label, "DarkBrown");
        end
        
        checkbox:SetScript("OnClick", function()
            DynamicCamera.config[data.config] = checkbox:GetChecked();
            DynamicCamera:SaveConfig();
        end);
    end

    -- Раздел быстрых пресетов
    local presetsLabel = parent:CreateFontString("DCameraPresetsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    presetsLabel:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", 0, -140);
    presetsLabel:SetText("Быстрая настройка (Face View):");
    if SetFontColor then
        SetFontColor(presetsLabel, "DarkBrown");
    end

    -- Кнопка сохранения текущего пресета камеры
	local savePresetBtn = CreateFrame("Button", "DSavePresetButton", parent, "DUIPanelButtonTemplate");
	savePresetBtn:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -10);
	savePresetBtn:SetWidth(150);
	savePresetBtn:SetHeight(25);
	savePresetBtn:SetText("Сохранить Текущий Вид");
	savePresetBtn:SetScript("OnClick", function()
		if DynamicCamera.SaveCameraPreset then
			DynamicCamera:SaveCameraPreset();
			DialogUI_DebugMessage("DialogUI: Текущий вид сохранен как пользовательский пресет");
		else
			DialogUI_DebugMessage("DialogUI: ОШИБКА - Метод SaveCameraPreset не найден");
		end
	end);

    -- Информация о пресете
    local presetInfo = parent:CreateFontString("DCameraPresetInfo", "OVERLAY", "DQuestButtonTitleGossip");
    presetInfo:SetPoint("TOPLEFT", savePresetBtn, "BOTTOMLEFT", 0, -10);
    presetInfo:SetWidth(300);
    presetInfo:SetJustifyH("LEFT");
    presetInfo:SetText("Настройте камеру так, как вы хотите, чтобы она выглядела после разговора с NPC, затем сохраните вид.");
    if SetFontColor then
        SetFontColor(presetInfo, "LightBrown");
    end

    -- Кнопки пресетов
	local presets = {"Cinematic", "Close", "Normal", "Wide"};
	local presetNames = {"Кинематогр.", "Близко", "Обычный", "Широкий"};
	for i, presetName in ipairs(presets) do
		local button = CreateFrame("Button", "DCamera" .. presetName .. "Button", parent, "DUIPanelButtonTemplate");
		button:SetText(presetNames[i]);
		button:SetWidth(80);
		button:SetHeight(22);

		-- Располагаем кнопки в ряд
		button:SetPoint("TOPLEFT", presetInfo, "BOTTOMLEFT", (i-1) * 85, -15);
		button:SetScript("OnClick", function()
			if DynamicCamera.ApplyPreset then
				DynamicCamera:ApplyPreset(string.lower(presetName));
				DialogUI_DebugMessage("DialogUI: Вид '" .. presetNames[i] .. "' применен");
				-- Обновляем отображение
				if DynamicCamera.settingsLabel then
					DynamicCamera.settingsLabel:SetText("Дистанция: " .. string.format("%.1f", DynamicCamera.config.faceViewDistance) .. 
													   " | Режим: " .. (DynamicCamera.config.useFaceView and "Лицом" or "Обычный"));
				end
			else
				DialogUI_DebugMessage("DialogUI: ОШИБКА - Метод ApplyPreset не найден");
			end
		end);
	end

    -- Отладка: Подтверждаем создание раздела камеры
    DialogUI_DebugMessage("DialogUI: Раздел камеры создан с " .. #presets .. " кнопками пресетов");
end

function DynamicCamera:UpdateConfigControls()
    local self = DynamicCamera;
    
    -- Проверяем существование фреймов перед обновлением
    local checkbox = getglobal("DCameraEnabledCheckbox");
    if checkbox and checkbox.SetChecked then
        checkbox:SetChecked(self.config.enabled);
    end

    local faceViewCheckbox = getglobal("DCameraFaceViewCheckbox");
    if faceViewCheckbox and faceViewCheckbox.SetChecked then
        faceViewCheckbox:SetChecked(self.config.useFaceView);
    end

    if self.settingsLabel then
        self.settingsLabel:SetText("Дистанция: " .. string.format("%.1f", self.config.faceViewDistance) .. 
                                   " | Режим: " .. (self.config.useFaceView and "Лицом" or "Обычный"));
    end

    -- Обновляем значения чекбоксов
    local checkboxData = {
        {name = "Разговоры", config = "enableForGossip"},
        {name = "Торговцы", config = "enableForVendors"},
        {name = "Тренеры", config = "enableForTrainers"},
        {name = "Квесты", config = "enableForQuests"}
    };

    for i, data in ipairs(checkboxData) do
        local checkbox = getglobal("DCamera" .. data.name .. "Checkbox");
        if checkbox and checkbox.SetChecked then
            checkbox:SetChecked(self.config[data.config]);
        end
    end
end

-- Тестовые пресеты камеры
function DynamicCamera:ApplyPreset(presetName)
    local self = DynamicCamera; -- Гарантируем, что self определен
    
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

    self:SaveConfig();
    DialogUI_DebugMessage("DialogUI: Вид камеры '" .. presetName .. "' применен");
end

-- Команды пресетов
SlashCmdList["CAMERA_PRESET"] = function(msg)
    local preset = string.lower(msg or "");
    if preset == "cinematic" or preset == "close" or preset == "normal" or preset == "wide" then
        DynamicCamera:ApplyPreset(preset);
    else
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Доступные виды: cinematic, close, normal, wide");
            DEFAULT_CHAT_FRAME:AddMessage("Использование: /camerapreset [название_вида]");
        end
    end
end;
SLASH_CAMERA_PRESET1 = "/camerapreset";

-- Подтверждаем, что функция определена
DialogUI_DebugMessage("DialogUI: Функция AddConfigControls успешно определена");