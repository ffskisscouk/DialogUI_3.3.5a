-- DialogueUI Money Frame
-- Fully isolated version for WoW 3.3.5

DUI_MONEY_ICON_WIDTH = 19;
DUI_MONEY_ICON_WIDTH_SMALL = 13;
DUI_MONEY_BUTTON_SPACING = -4;
DUI_MONEY_BUTTON_SPACING_SMALL = -4;
DUI_COPPER_PER_SILVER = 100;
DUI_SILVER_PER_GOLD = 100;
DUI_COPPER_PER_GOLD = DUI_COPPER_PER_SILVER * DUI_SILVER_PER_GOLD;
DUI_COIN_BUTTON_WIDTH = 32;

DUI_MoneyTypeInfo = {};
DUI_MoneyTypeInfo["PLAYER"] = {
    UpdateFunc = function()
        return (GetMoney() - GetCursorMoney() - GetPlayerTradeMoney());
    end,
    PickupFunc = function(amount)
        PickupPlayerMoney(amount);
    end,
    DropFunc = function()
        DropCursorMoney();
    end,
    collapse = 1,
    canPickup = 1,
    showSmallerCoins = "Backpack"
};
DUI_MoneyTypeInfo["STATIC"] = {
    UpdateFunc = function()
        return this.staticMoney;
    end,
    collapse = 1,
};
DUI_MoneyTypeInfo["AUCTION"] = {
    UpdateFunc = function()
        return this.staticMoney;
    end,
    showSmallerCoins = "Backpack",
    fixedWidth = 1,
    collapse = 1,
    truncateSmallCoins = nil,
};
DUI_MoneyTypeInfo["PLAYER_TRADE"] = {
    UpdateFunc = function()
        return GetPlayerTradeMoney();
    end,
    PickupFunc = function(amount)
        PickupTradeMoney(amount);
    end,
    DropFunc = function()
        AddTradeMoney();
    end,
    collapse = 1,
    canPickup = 1,
};
DUI_MoneyTypeInfo["TARGET_TRADE"] = {
    UpdateFunc = function()
        return GetTargetTradeMoney();
    end,
    collapse = 1,
};
DUI_MoneyTypeInfo["SEND_MAIL"] = {
    UpdateFunc = function()
        return GetSendMailMoney();
    end,
    PickupFunc = function(amount)
        PickupSendMailMoney(amount);
    end,
    DropFunc = function()
        AddSendMailMoney();
    end,
    collapse = nil,
    canPickup = 1,
    showSmallerCoins = "Backpack",
};
DUI_MoneyTypeInfo["SEND_MAIL_COD"] = {
    UpdateFunc = function()
        return GetSendMailCOD();
    end,
    PickupFunc = function(amount)
        PickupSendMailCOD(amount);
    end,
    DropFunc = function()
        AddSendMailCOD();
    end,
    collapse = 1,
    canPickup = 1,
};

-- Use this instead of self for compatibility with WoW 3.3.5
function DUI_MoneyFrame_OnLoad()
    local frame = this; -- this points to the frame in OnLoad
    
    frame.moneyType = "PLAYER";
    frame.info = DUI_MoneyTypeInfo["PLAYER"];
    frame.staticMoney = 0;

    frame:RegisterEvent("PLAYER_MONEY");
    frame:RegisterEvent("PLAYER_TRADE_MONEY");
    frame:RegisterEvent("TRADE_MONEY_CHANGED");
    frame:RegisterEvent("SEND_MAIL_MONEY_CHANGED");
    frame:RegisterEvent("SEND_MAIL_COD_CHANGED");
end

function DUI_SmallMoneyFrame_OnLoad()
    local frame = this;
    
    frame.moneyType = "PLAYER";
    frame.info = DUI_MoneyTypeInfo["PLAYER"];
    frame.staticMoney = 0;
    frame.small = 1;

    frame:RegisterEvent("PLAYER_MONEY");
    frame:RegisterEvent("PLAYER_TRADE_MONEY");
    frame:RegisterEvent("TRADE_MONEY_CHANGED");
    frame:RegisterEvent("SEND_MAIL_MONEY_CHANGED");
    frame:RegisterEvent("SEND_MAIL_COD_CHANGED");
end

function DUI_MoneyFrame_SetTypeSafe(moneyType)
    local frame = this;
    
    if not moneyType then
        moneyType = "PLAYER";
    end

    local typeOfArg = type(moneyType)

    if typeOfArg == "string" then
        local info = DUI_MoneyTypeInfo[moneyType];
        if info then
            frame.info = info;
            frame.moneyType = moneyType;
        else
            frame.info = DUI_MoneyTypeInfo["PLAYER"];
            frame.moneyType = "PLAYER";
        end
    elseif typeOfArg == "table" then
        frame.info = moneyType;
        if moneyType.moneyType and type(moneyType.moneyType) == "string" then
            frame.moneyType = moneyType.moneyType;
        else
            frame.moneyType = "PLAYER";
        end

        if not frame.info.UpdateFunc then
            frame.info.UpdateFunc = function() 
                return GetMoney(); 
            end;
        end
        if frame.info.collapse == nil then
            frame.info.collapse = 1;
        end
    else
        frame.info = DUI_MoneyTypeInfo["PLAYER"];
        frame.moneyType = "PLAYER";
    end

    local frameName = frame:GetName();
    if not frameName then return; end

    local info = frame.info;

    local goldButton = getglobal(frameName .. "GoldButton");
    local silverButton = getglobal(frameName .. "SilverButton");
    local copperButton = getglobal(frameName .. "CopperButton");

    if info and info.canPickup then
        if goldButton then goldButton:EnableMouse(true); end
        if silverButton then silverButton:EnableMouse(true); end
        if copperButton then copperButton:EnableMouse(true); end
    else
        if goldButton then goldButton:EnableMouse(false); end
        if silverButton then silverButton:EnableMouse(false); end
        if copperButton then copperButton:EnableMouse(false); end
    end

    DUI_MoneyFrame_UpdateMoney(frame);
end

function DUI_MoneyFrame_SetType(moneyType)
    DUI_MoneyFrame_SetTypeSafe(moneyType);
end

function DUI_MoneyFrame_OnEvent(event)
    local frame = this;
    
    if not frame or not frame.info or not frame:IsVisible() then
        return;
    end

    if (event == "PLAYER_MONEY" and frame.moneyType == "PLAYER") then
        DUI_MoneyFrame_UpdateMoney(frame);
    elseif (event == "PLAYER_TRADE_MONEY" and (frame.moneyType == "PLAYER" or frame.moneyType == "PLAYER_TRADE")) then
        DUI_MoneyFrame_UpdateMoney(frame);
    elseif (event == "TRADE_MONEY_CHANGED" and frame.moneyType == "TARGET_TRADE") then
        DUI_MoneyFrame_UpdateMoney(frame);
    elseif (event == "SEND_MAIL_MONEY_CHANGED" and (frame.moneyType == "PLAYER" or frame.moneyType == "SEND_MAIL")) then
        DUI_MoneyFrame_UpdateMoney(frame);
    elseif (event == "SEND_MAIL_COD_CHANGED" and (frame.moneyType == "PLAYER" or frame.moneyType == "SEND_MAIL_COD")) then
        DUI_MoneyFrame_UpdateMoney(frame);
    end
end

-- Accept frame as a parameter or fall back to this
function DUI_MoneyFrame_UpdateMoney(frame)
    -- If frame is not provided, use this (for calls from XML)
    if not frame then
        frame = this;
    end
    
    if not frame then return; end

    if not frame.info then
        frame.info = DUI_MoneyTypeInfo["PLAYER"];
    end
    if not frame.moneyType then
        frame.moneyType = "PLAYER";
    end

    local money = 0;
    if frame.info and frame.info.UpdateFunc then
        -- Save the current this and set frame as this for UpdateFunc
        local oldThis = this;
        this = frame;
        
        local success, result = pcall(frame.info.UpdateFunc);
        
        this = oldThis;
        
        if success then
            money = result or 0;
        else
            money = frame.staticMoney or GetMoney();
        end
    else
        money = frame.staticMoney or GetMoney();
    end

    DUI_MoneyFrame_UpdateFrame(frame:GetName(), money);

    if frame.hasPickup == 1 then
        UpdateCoinPickupFrame(money);
    end
end

function DUI_MoneyFrame_UpdateFrame(frameName, money)
    if not frameName then return; end

    local frame = getglobal(frameName);
    if not frame then return; end

    if not frame.info then
        frame.info = DUI_MoneyTypeInfo["PLAYER"];
        frame.moneyType = "PLAYER";
    end
    if not frame.moneyType then
        frame.moneyType = "PLAYER";
    end

    local info = frame.info;

    local gold = floor(money / (DUI_COPPER_PER_SILVER * DUI_SILVER_PER_GOLD));
    local silver = floor((money - (gold * DUI_COPPER_PER_SILVER * DUI_SILVER_PER_GOLD)) / DUI_COPPER_PER_SILVER);
    local copper = mod(money, DUI_COPPER_PER_SILVER);

    local goldButton = getglobal(frameName.."GoldButton");
    local silverButton = getglobal(frameName.."SilverButton");
    local copperButton = getglobal(frameName.."CopperButton");

    if not goldButton or not silverButton or not copperButton then
        return;
    end

    local iconWidth = DUI_MONEY_ICON_WIDTH;
    local spacing = DUI_MONEY_BUTTON_SPACING;
    if ( frame.small ) then
        iconWidth = DUI_MONEY_ICON_WIDTH_SMALL;
        spacing = DUI_MONEY_BUTTON_SPACING_SMALL;
    end

    local goldText = getglobal(frameName.."GoldButtonText");
    local silverText = getglobal(frameName.."SilverButtonText");
    local copperText = getglobal(frameName.."CopperButtonText");
    
    if goldText then
        goldText:SetText(gold);
        goldButton:SetWidth(goldText:GetWidth() + iconWidth);
    else
        goldButton:SetText(gold);
        goldButton:SetWidth(goldButton:GetTextWidth() + iconWidth);
    end
    goldButton:Show();
    
    if silverText then
        silverText:SetText(silver);
        silverButton:SetWidth(silverText:GetWidth() + iconWidth);
    else
        silverButton:SetText(silver);
        silverButton:SetWidth(silverButton:GetTextWidth() + iconWidth);
    end
    silverButton:Show();
    
    if copperText then
        copperText:SetText(copper);
        copperButton:SetWidth(copperText:GetWidth() + iconWidth);
    else
        copperButton:SetText(copper);
        copperButton:SetWidth(copperButton:GetTextWidth() + iconWidth);
    end
    copperButton:Show();

    frame.staticMoney = money;

    if ( not info.collapse ) then
        return;
    end

    local width = iconWidth;
    local showLowerDenominations, truncateCopper;
    if ( gold > 0 ) then
        width = width + goldButton:GetWidth();
        if ( info.showSmallerCoins ) then
            showLowerDenominations = 1;
        end
        if ( info.truncateSmallCoins ) then
            truncateCopper = 1;
        end
    else
        goldButton:Hide();
    end

    if ( silver > 0 or showLowerDenominations ) then
        if ( showLowerDenominations and info.fixedWidth ) then
            silverButton:SetWidth(DUI_COIN_BUTTON_WIDTH);
        end

        width = width + silverButton:GetWidth();
        goldButton:SetPoint("RIGHT", frameName.."SilverButton", "LEFT", spacing, 0);
        if ( goldButton:IsVisible() ) then
            width = width - spacing;
        end
        if ( info.showSmallerCoins ) then
            showLowerDenominations = 1;
        end
    else
        silverButton:Hide();
        goldButton:SetPoint("RIGHT", frameName.."SilverButton", "RIGHT", 0, 0);
    end

    if ( (copper > 0 or showLowerDenominations or info.showSmallerCoins == "Backpack") and not truncateCopper) then
        if ( showLowerDenominations and info.fixedWidth ) then
            copperButton:SetWidth(DUI_COIN_BUTTON_WIDTH);
        end

        width = width + copperButton:GetWidth();
        silverButton:SetPoint("RIGHT", frameName.."CopperButton", "LEFT", spacing, 0);
        if ( silverButton:IsVisible() ) then
            width = width - spacing;
        end
    else
        copperButton:Hide();
        silverButton:SetPoint("RIGHT", frameName.."CopperButton", "RIGHT", 0, 0);
    end

    frame:SetWidth(width);
end

function DUI_SetMoneyFrameColor(frameName, r, g, b)
    if not frameName then return; end

    local goldButton = getglobal(frameName.."GoldButton");
    local silverButton = getglobal(frameName.."SilverButton");
    local copperButton = getglobal(frameName.."CopperButton");

    if goldButton and goldButton.SetTextColor then
        goldButton:SetTextColor(r, g, b);
    end

    if silverButton and silverButton.SetTextColor then
        silverButton:SetTextColor(r, g, b);
    end

    if copperButton and copperButton.SetTextColor then
        copperButton:SetTextColor(r, g, b);
    end
end
