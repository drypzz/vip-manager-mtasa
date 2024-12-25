--[[
██████╗ ██████╗ ██╗   ██╗██████╗ ███████╗███████╗    ██████╗ ███████╗██╗   ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗╚══███╔╝╚══███╔╝    ██╔══██╗██╔════╝██║   ██║
██║  ██║██████╔╝ ╚████╔╝ ██████╔╝  ███╔╝   ███╔╝     ██║  ██║█████╗  ██║   ██║
██║  ██║██╔══██╗  ╚██╔╝  ██╔═══╝  ███╔╝   ███╔╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝
██████╔╝██║  ██║   ██║   ██║     ███████╗███████╗    ██████╔╝███████╗ ╚████╔╝ 
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝
--]]

--> client-side



local screenW,screenH = guiGetScreenSize()
local resW, resH = 1920, 1080
local x, y =  (screenW/resW), (screenH/resH)

local DGS = exports.dgs

local panel = false
local panelRenew = false
local panelGiveaway = false

local window, addTab, listTab, gridPlayers, gridVips, logTab
local renewPanel, renewTypeSelect, renewDaysInput, renewConfirmBtn, btnRenewVip, logTextArea, givewayNumberInput, givePanel

local posX = (x * 660)
local posY = (y * 333)

local sansFont = DGS:dgsCreateFont("assets/font/sans.ttf", x * 10)



--> painel gerenciador

function createPanel()
    if not panel then

        DGS:dgsSetInputMode("no_binds_when_editing")

        -- Função de ordenação por ID

        local sortID = [[
            local arg = {...}
            local a = arg[1]
            local b = arg[2]
            local column = dgsElementData[self].sortColumn
            local c, d = tonumber(a[column][1]), tonumber(b[column][1])
            return c < d
        ]]
        

        window = DGS:dgsCreateWindow(posX, posY, x * 600, y * 445, "Gerenciador VIP", false)
        DGS:dgsSetProperty(window, "titleColorBlur", tocolor(0, 0, 0))
        DGS:dgsSetProperty(window, "alpha", 0.9)
        DGS:dgsWindowSetSizable(window, false)
        DGS:dgsSetFont(window, sansFont)
        
        -- Tabs

        local tabPanel = DGS:dgsCreateTabPanel(x * 10, y * 30, x * 580, y * 290, false, window)
        DGS:dgsSetProperty(tabPanel, "tabGapSize", {10, false})
        DGS:dgsSetProperty(tabPanel, "tabPadding", {20, false})
        DGS:dgsSetFont(tabPanel, sansFont)

        -- Tab Players

        addTab = DGS:dgsCreateTab("Players", tabPanel)
        DGS:dgsSetProperty(addTab, "bgColor", tocolor(10, 10, 10, 200))
        DGS:dgsSetProperty(addTab, "tabColor", {tocolor(0, 0, 0, 200), tocolor(0, 0, 0, 150), tocolor(0, 0, 0, 250)})
        DGS:dgsSetFont(addTab, sansFont)

        -- Tab VIP's

        listTab = DGS:dgsCreateTab("VIP's", tabPanel)
        DGS:dgsSetProperty(listTab, "bgColor", tocolor(10, 10, 10, 200))
        DGS:dgsSetProperty(listTab, "tabColor", {tocolor(0, 0, 0, 200), tocolor(0, 0, 0, 150), tocolor(0, 0, 0, 250)})
        DGS:dgsSetFont(listTab, sansFont)

        -- Tab Log's

        logTab = DGS:dgsCreateTab("Log's", tabPanel)
        DGS:dgsSetProperty(logTab, "bgColor", tocolor(10, 10, 10, 200))
        DGS:dgsSetProperty(logTab, "tabColor", {tocolor(0, 0, 0, 200), tocolor(0, 0, 0, 150), tocolor(0, 0, 0, 250)})
        DGS:dgsSetFont(logTab, sansFont)

        -- Grid Players

        gridPlayers = DGS:dgsCreateGridList(x * 10, y * 10, x * 558, y * 250, false, addTab)
        DGS:dgsSetProperty(gridPlayers, "columnColor", tocolor(0, 0, 0, 200))
        DGS:dgsGridListSetSortFunction(gridPlayers, sortID)
        DGS:dgsGridListSetSortColumn(gridPlayers, 1)

        DGS:dgsSetProperty(gridPlayers, "columnHeight", "30")
        DGS:dgsSetProperty(gridPlayers, "rowHeight", "30")
        DGS:dgsSetProperty(gridPlayers, "colorCoded", true)
        DGS:dgsSetProperty(gridPlayers, "rowTextSize", {0.9, 0.9})
        DGS:dgsSetFont(gridPlayers, sansFont)

        local idPlayerCol = DGS:dgsGridListAddColumn(gridPlayers, "ID", 0.09)
        local playerCol = DGS:dgsGridListAddColumn(gridPlayers, "Nome", 0.6)
        local statusCol = DGS:dgsGridListAddColumn(gridPlayers, "VIP", 0.30)

        -- Adicionar VIP

        local btnAddVip = DGS:dgsCreateButton(x * 10, y * 280, x * 220, y * 40, "Adicionar", false, addTab)
        DGS:dgsSetProperty(btnAddVip, "textColor", tocolor(0, 0, 0))
        DGS:dgsSetProperty(btnAddVip, "color", {tocolor(0, 230, 0, 200), tocolor(0, 200, 0, 200), tocolor(0, 155, 0, 200)})
        DGS:dgsSetFont(btnAddVip, sansFont)

        local vipDaysInput = DGS:dgsCreateEdit(x * 240, y * 280, x * 150, y * 40, "", false, addTab)
        DGS:dgsSetFont(vipDaysInput, sansFont)
        DGS:dgsSetProperty(vipDaysInput, "placeHolder", "Digite o(s) dia(s)...")
        DGS:dgsSetProperty(vipDaysInput, "placeHolderFont", sansFont)
        DGS:dgsEditSetMaxLength(vipDaysInput, 3)

        local vipTypeSelect = DGS:dgsCreateComboBox(x * 400, y * 280, x * 170, x * 40, "Tipo", false, addTab)
        DGS:dgsSetFont(vipTypeSelect, sansFont)
        DGS:dgsSetProperty(vipTypeSelect, "itemHeight", y * 30)

        local count = 0
        
        for i, data in pairs(config.manager.vips) do
            DGS:dgsComboBoxAddItem(vipTypeSelect, i)
            count = count + 1
        end

        if count >= 3 then
            DGS:dgsComboBoxSetViewCount(vipTypeSelect, 2)
        end

        logTextArea = DGS:dgsCreateMemo(x * 10, y * 10, x * 558, y * 250, "", false, logTab)
        DGS:dgsSetProperty(logTextArea, "font", sansFont)
        DGS:dgsSetProperty(logTextArea, "readOnly", true)
        DGS:dgsSetProperty(logTextArea, "wordBreak", true)

        -- Evento para carregar os logs

        addEventHandler("onDgsTabPanelTabSelect", tabPanel, function(new, old)
            if new == 3 then
                triggerServerEvent("loadLog", resourceRoot)
            end
        end)

        -- Evento para adicionar VIP

        addEventHandler("onDgsMouseClick", btnAddVip, function(button, state)
            if button == "left" and state == "up" then
                local selectedRow = DGS:dgsGridListGetSelectedItem(gridPlayers)
                if selectedRow ~= -1 then
                    local id = DGS:dgsGridListGetItemText(gridPlayers, selectedRow, idPlayerCol)
                    local playerName = DGS:dgsGridListGetItemText(gridPlayers, selectedRow, playerCol)
                    local days = tonumber(DGS:dgsGetText(vipDaysInput))
                    local type = DGS:dgsComboBoxGetSelectedItem(vipTypeSelect)
                    if days and days > 0 and type ~= -1 then
                        local vipType = DGS:dgsComboBoxGetItemText(vipTypeSelect, type)
                        triggerServerEvent("addVip", getLocalPlayer(), id, playerName, days, vipType)
                    else
                        outputChatBox("* Preencha todos os campos!", 255, 0, 0)
                    end
                else
                    outputChatBox("* Selecione um player!", 255, 0, 0)
                end
            end
        end, false)

        -- Grid VIP's

        gridVips = DGS:dgsCreateGridList(x * 10, y * 10, x * 558, y * 250, false, listTab)
        DGS:dgsSetProperty(gridVips, "columnColor", tocolor(0, 0, 0, 200))
        DGS:dgsSetProperty(gridVips, "columnHeight", "30")
        DGS:dgsSetProperty(gridVips, "rowHeight", "30")
        DGS:dgsSetProperty(gridVips, "colorCoded", true)
        DGS:dgsSetProperty(gridVips, "rowTextSize", {0.9, 0.9})
        DGS:dgsSetFont(gridVips, sansFont)
        DGS:dgsGridListSetSortFunction(gridVips, sortID)
        DGS:dgsGridListSetSortColumn(gridVips, 1)

        local vipIdPlayerCol = DGS:dgsGridListAddColumn(gridVips, "ID", 0.09)
        local vipPlayerCol = DGS:dgsGridListAddColumn(gridVips, "Nome", 0.40)
        local vipStaffCol = DGS:dgsGridListAddColumn(gridVips, "Staff", 0.30)
        local vipDaysCol = DGS:dgsGridListAddColumn(gridVips, "Tempo", 0.35)
        local vipInit = DGS:dgsGridListAddColumn(gridVips, "Início", 0.30)
        local vipLimit = DGS:dgsGridListAddColumn(gridVips, "Fim", 0.30)
        local vipStatusCol = DGS:dgsGridListAddColumn(gridVips, "Status", 0.30)
        local vipTypeCol = DGS:dgsGridListAddColumn(gridVips, "Tipo", 0.30)
        local vipAcc = DGS:dgsGridListAddColumn(gridVips, "Conta", 0.30)

        -- Remover VIP

        local btnRemoveVip = DGS:dgsCreateButton(x * 10, y * 280, x * 220, y * 40, "Remover", false, listTab)
        DGS:dgsSetProperty(btnRemoveVip, "textColor", tocolor(255, 255, 255))
        DGS:dgsSetProperty(btnRemoveVip, "color", {tocolor(230, 0, 0, 200), tocolor(200, 0, 0, 200), tocolor(155, 0, 0, 200)})
        DGS:dgsSetFont(btnRemoveVip, sansFont)

        -- Renovar VIP

        btnRenewVip = DGS:dgsCreateButton(x * 340, y * 280, x * 230, y * 40, "Renovar", false, listTab)
        DGS:dgsSetProperty(btnRenewVip, "textColor", tocolor(255, 255, 255))
        DGS:dgsSetProperty(btnRenewVip, "color", {tocolor(53, 153, 204, 200), tocolor(40, 140, 190, 200), tocolor(53, 153, 204, 200)})
        DGS:dgsSetFont(btnRenewVip, sansFont)


        -- Evento para remover VIP

        addEventHandler("onDgsMouseClick", btnRemoveVip, function(button, state)
            if button == "left" and state == "up" then
                local selectedRow = DGS:dgsGridListGetSelectedItem(gridVips)
                if selectedRow ~= -1 then
                    local id = DGS:dgsGridListGetItemText(gridVips, selectedRow, vipIdPlayerCol)
                    triggerServerEvent("removeVip", getLocalPlayer(), id)
                else
                    outputChatBox("* Selecione um player para remover", 255, 0, 0)
                end
            end
        end, false)

        -- Evento para renovar VIP

        addEventHandler("onDgsMouseClick", btnRenewVip, function(button, state)
            if button == "left" and state == "up" then
                local selectedRow = DGS:dgsGridListGetSelectedItem(gridVips)
                if selectedRow ~= -1 then
                    local id = DGS:dgsGridListGetItemText(gridVips, selectedRow, vipIdPlayerCol)
                    triggerServerEvent("getInfoMember", getLocalPlayer(), id)
                else
                    outputChatBox("* Selecione um player para renovar", 255, 0, 0)
                end
            end
        end, false)

        -- Evento para atualizar a lista de players e vips

        triggerServerEvent("fetchOnlinePlayers", getLocalPlayer())
        triggerServerEvent("fetchVipList", getLocalPlayer())


        -- Evento para fechar o painel

        addEventHandler("onDgsWindowClose", window, function()
            closePanel()
        end, false)

        panel = true
        showCursor(true)
    end
end



--> painel de renovação

addEvent("showRenewPanel", true)
addEventHandler("showRenewPanel", getLocalPlayer(), function(id, playername, currentVipType, days)
    showRenewPanel(id, playername, currentVipType, days)
    DGS:dgsSetEnabled(btnRenewVip, false)
end)

function showRenewPanel(id, playername, currentVipType, days)
    if not panelRenew then

        DGS:dgsSetInputMode("no_binds_when_editing")

        renewPanel = DGS:dgsCreateWindow(posX + 100, posY + 100, x * 400, y * 200, "Renovar/ou Alterar VIP - (ID: " .. id .. ")", false)
        DGS:dgsWindowSetSizable(renewPanel, false)
        DGS:dgsSetFont(renewPanel, sansFont)

        local info = DGS:dgsCreateLabel(x * 10, y * 30, x * 380, y * 30, "* VIP atual: #359acc" .. currentVipType .. "#ffffff\n* Dias atuais: #359acc" .. days .. " Dia(s)", false, renewPanel)
        DGS:dgsSetFont(info, sansFont)
        DGS:dgsSetProperty(info, "colorCoded", true)

        renewTypeSelect = DGS:dgsCreateComboBox(x * 10, y * 70, x * 180, y * 30, "Tipo", false, renewPanel)
        DGS:dgsSetFont(renewTypeSelect, sansFont)
        DGS:dgsSetProperty(renewTypeSelect, "itemHeight", y * 30)
        DGS:dgsComboBoxSetViewCount(renewTypeSelect, 2)

        for i, data in pairs(config.manager.vips) do
            if i ~= currentVipType then
                DGS:dgsComboBoxAddItem(renewTypeSelect, i)
            end
        end

        renewDaysInput = DGS:dgsCreateEdit(x * 200, y * 70, x * 189, y * 30, "", false, renewPanel)
        DGS:dgsSetFont(renewDaysInput, sansFont)
        DGS:dgsSetProperty(renewDaysInput, "placeHolder", "Digite o(s) dia(s)...")
        DGS:dgsSetProperty(renewDaysInput, "placeHolderFont", sansFont)
        DGS:dgsEditSetMaxLength(renewDaysInput, 3)

        renewConfirmBtn = DGS:dgsCreateButton(x * 10, y * 120, x * 375, y * 40, "Confirmar", false, renewPanel)
        DGS:dgsSetProperty(renewConfirmBtn,"textColor", tocolor(0, 0, 0))
        DGS:dgsSetProperty(renewConfirmBtn, "color", {tocolor(0, 230, 0, 200), tocolor(0, 200, 0, 200), tocolor(0, 155, 0, 200)})
        DGS:dgsSetFont(renewConfirmBtn, sansFont)

        addEventHandler("onDgsMouseClick", renewConfirmBtn, function(button, state)
            if button == "left" and state == "up" then
                local days = tonumber(DGS:dgsGetText(renewDaysInput))
                local type = DGS:dgsComboBoxGetSelectedItem(renewTypeSelect)
                if days and days > 0 then
                    if (type ~= -1) then
                        local vipType = DGS:dgsComboBoxGetItemText(renewTypeSelect, type)
                        triggerServerEvent("renewVip", getLocalPlayer(), id, playername, days, vipType)
                    else
                        triggerServerEvent("renewVip", getLocalPlayer(), id, playername, days, currentVipType)
                    end

                    DGS:dgsCloseWindow(renewPanel)
                    panelRenew = false
                    DGS:dgsSetEnabled(btnRenewVip, true)
                else
                    outputChatBox("* Preencha todos os campos!", 255, 0, 0)
                end
            end
        end, false)

        addEventHandler("onDgsWindowClose", renewPanel, function()
            if panelRenew then
                panelRenew = false
                DGS:dgsCloseWindow(renewPanel)
                DGS:dgsSetEnabled(btnRenewVip, true)
            end
        end, false)

        panelRenew = true
        showCursor(true)
    end
end



--> painel de sorteio

addEvent("showGiveawayPanel", true)
addEventHandler("showGiveawayPanel", getLocalPlayer(), function(e)
    giveawayPanel(e.id, e.name, e.acc, e.type, e.num1, e.num2, e.days)
end)

addEvent("closeGiveawayPanel", true)
addEventHandler("closeGiveawayPanel", getLocalPlayer(), function()
    if panelGiveaway then
        DGS:dgsCloseWindow(givePanel)
        panelGiveaway = false
        showCursor(false)
    end
end)

function giveawayPanel(id, name, acc, type, num1, num2, days)
    if not panelGiveaway then

        DGS:dgsSetInputMode("no_binds_when_editing")
        
        givePanel = DGS:dgsCreateWindow(posX + 100, posY + 100, x * 400, y * 200, "Sorteio VIP", false)
        DGS:dgsWindowSetSizable(givePanel, false)
        DGS:dgsSetFont(givePanel, sansFont)
        
        local infoGiveaway = DGS:dgsCreateLabel(x * 10, y * 30, x * 380, y * 30, "* Recompensa: #359acc".. type .." - " .. days .. " Dias#ffffff\n* Digite um número entre [" .. num1 .. "] e [" .. num2 .. "]", false, givePanel)
        DGS:dgsSetFont(infoGiveaway, sansFont)
        DGS:dgsSetProperty(infoGiveaway, "colorCoded", true)
        
        givewayNumberInput = DGS:dgsCreateEdit(x * 10, y * 75, x * 380, y * 30, "", false, givePanel)
        DGS:dgsSetFont(givewayNumberInput, sansFont)
        DGS:dgsSetProperty(givewayNumberInput, "placeHolder", "Digite um número...")
        DGS:dgsSetProperty(givewayNumberInput, "placeHolderFont", sansFont)
        
        local confirmGiveawayBtn = DGS:dgsCreateButton(x * 25, y * 120, x * 350, y * 40, "Confirmar", false, givePanel)
        DGS:dgsSetProperty(confirmGiveawayBtn,"textColor", tocolor(0, 0, 0))
        DGS:dgsSetProperty(confirmGiveawayBtn, "color", {tocolor(0, 230, 0, 200), tocolor(0, 200, 0, 200), tocolor(0, 155, 0, 200)})
        DGS:dgsSetFont(confirmGiveawayBtn, sansFont)

        addEventHandler("onDgsMouseClick", confirmGiveawayBtn, function(button, state)
            if button == "left" and state == "up" then
                local number = tonumber(DGS:dgsGetText(givewayNumberInput))
                if number and number >= num1 and number <= num2 then
                    triggerServerEvent("getGiveawayNumberPlayer", getLocalPlayer(), number, acc, name, id)
                else
                    outputChatBox("* Número inválido! Escolha um número entre [" .. num1 .. "] e [" .. num2 .. "].", 255, 0, 0)
                end
            end
        end, false)

        addEventHandler("onDgsWindowClose", givePanel, function()
            if panelGiveaway then
                panelGiveaway = false
                DGS:dgsCloseWindow(givePanel)
                showCursor(false)
            end
        end, false)

        panelGiveaway = true
        showCursor(true)
    end
end



--> funções auxiliares

function closePanel()
    if panel then
        DGS:dgsCloseWindow(window)
        panel = false
        showCursor(false)
    end
    if panelRenew then
        DGS:dgsCloseWindow(renewPanel)
        panelRenew = false
        showCursor(false)
    end
end



--> funções de formatação

addEvent("updateOnlinePlayers", true)
addEventHandler("updateOnlinePlayers", root, function(players)
    if panel then
        DGS:dgsGridListClear(gridPlayers)
        for _, player in ipairs(players) do
            local row = DGS:dgsGridListAddRow(gridPlayers)
            DGS:dgsGridListSetItemText(gridPlayers, row, 1, tostring(player.id), false, false)
            DGS:dgsGridListSetItemText(gridPlayers, row, 2, tostring(player.name), false, false)
            DGS:dgsGridListSetItemText(gridPlayers, row, 3, player.vip == "true" and "Sim" or "Não", false, false)
        end
    else
        players = {}
    end
end)

addEvent("updateVipList", true)
addEventHandler("updateVipList", root, function(vips)
    if panel then
        DGS:dgsGridListClear(gridVips)
        for _, vip in ipairs(vips) do
            local row = DGS:dgsGridListAddRow(gridVips)
            DGS:dgsGridListSetItemText(gridVips, row, 1, tostring(vip.id), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 2, tostring(removeHex(vip.name)), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 3, tostring(vip.staff), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 4, tostring(formatTimeRemaining(vip.days)), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 5, tostring(vip.init), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 6, tostring(vip.limit), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 7, (vip.active == 1 and "#00ff00Ativo" or "#ff0000Expirado"), false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 8, tostring(vip.type) or "off", false, false)
            DGS:dgsGridListSetItemText(gridVips, row, 9, tostring(vip.account), false, false)
        end
    else
        vips = {}
    end
end)



--> função para abrir o painel

if config.manager.open["bind"][2] then
    addEventHandler("onClientKey", root, function(button, press)
        if button == tostring(config.manager.open["bind"][1]) and press then
            if panel then
                closePanel()
            else
                triggerServerEvent("checkPermission", getLocalPlayer())
            end
        end
    end)
end

if config.manager.open["cmd"][2] then
    addCommandHandler(config.manager.open["cmd"][1], function()
        if panel then
            closePanel()
        else
            triggerServerEvent("checkPermission", getLocalPlayer())
        end
    end)
end



--> funções auxiliares

addEvent("giveawayNumberExists", true)
addEventHandler("giveawayNumberExists", root, function(isDuplicate)
    if isDuplicate then
        outputChatBox("* Esse número já foi escolhido! Tente outro.", 255, 0, 0)
    else
        if panelGiveaway then
            DGS:dgsCloseWindow(givePanel)
            panelGiveaway = false
            showCursor(false)
        end
    end
end)

addEvent("displayLog", true)
addEventHandler("displayLog", root, function(logContent)
    DGS:dgsSetText(logTextArea, tostring(logContent))
end)

addEvent("showPanel", true)
addEventHandler("showPanel", root, function()
    createPanel()
end)

addEvent("createDynamicMessage", true)
addEventHandler("createDynamicMessage", root, function(message, options)
    createDynamicMessage(message, options)
end)