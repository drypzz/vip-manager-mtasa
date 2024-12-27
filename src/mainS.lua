--[[
██████╗ ██████╗ ██╗   ██╗██████╗ ███████╗███████╗    ██████╗ ███████╗██╗   ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗╚══███╔╝╚══███╔╝    ██╔══██╗██╔════╝██║   ██║
██║  ██║██████╔╝ ╚████╔╝ ██████╔╝  ███╔╝   ███╔╝     ██║  ██║█████╗  ██║   ██║
██║  ██║██╔══██╗  ╚██╔╝  ██╔═══╝  ███╔╝   ███╔╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝
██████╔╝██║  ██║   ██║   ██║     ███████╗███████╗    ██████╔╝███████╗ ╚████╔╝ 
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝
--]]

--> server-side



local action = false;


--> database

local db = dbConnect("sqlite", "src/db/database.db")
local resourceName = "dgs"

addEventHandler("onResourceStart", resourceRoot, function()

    local resource = getResourceFromName(resourceName)
    if not resource or getResourceState(resource) ~= "running" then
        print("[GERENCIADOR VIP] - Execute o recurso 'dgs' antes de iniciar!")
        cancelEvent()
        return
    end

    for i, data in pairs(config.manager.vips) do
        local groupName = tostring(i)
        if not aclGetGroup(groupName) then
            if config.debuggingEnabled then
                print(string.format("[GERENCIADOR VIP] - ACL [%s] não existe. Será criada!", groupName))
            end
            aclCreateGroup(groupName)
        end
    end

    if not db then
        if config.debuggingEnabled then
            print("[GERENCIADOR VIP] - Failed to connect to the database!")
        end
        cancelEvent()
        return
    else
        dbExec(db, [[
            CREATE TABLE IF NOT EXISTS "vip" (
                "id" INTEGER PRIMARY KEY, 
                "name" TEXT NOT NULL, 
                "days" DATETIME NOT NULL, 
                "active" INTEGER NOT NULL, 
                "type" TEXT NOT NULL, 
                "account" TEXT NOT NULL, 
                "staff" TEXT,
                "dateLimit" TEXT,
                "date" TEXT
            )
        ]])

        if config.debuggingEnabled then
            print("[GERENCIADOR VIP] - Conexão bem sucedida com o banco de dados!")
        end
    end
end)



--> functions relacionadas a tempo e lista

fetchVipList = function()
    local query = dbQuery(db, "SELECT * FROM vip")
    if not query then
        print("[GERENCIADOR VIP] - Erro ao executar consulta para buscar VIPs!")
        return
    end

    local result = dbPoll(query, -1)
    if not result then
        print("[GERENCIADOR VIP] - Erro ao buscar resultados do banco de dados!")
        return
    end

    local vips = {}
    for _, row in ipairs(result) do
        table.insert(vips, {
            id = row.id,
            name = row.name,
            days = row.days,
            active = row.active,
            type = row.type,
            account = row.account,
            staff = row.staff,
            limit = row.dateLimit,
            init = row.date
        })
    end

    if config.debuggingEnabled then
        iprint("listVips", vips)
    end

    triggerClientEvent(root, "updateVipList", root, vips)
end

fetchOnlinePlayers = function()
    local players = {}
    for _, player in ipairs(getElementsByType("player")) do
        
        if getPlayerAccount(player) and not isGuestAccount(getPlayerAccount(player)) then
            local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))), -1)
            
            table.insert(players, { 
                id = (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))),
                name = getPlayerName(player),
                vip = result and #result > 0 and (result[1].active == 1 and "true" or "false")
            })

            if config.debuggingEnabled then
                iprint(
                    "onlinePlayers",
                    {
                        id = (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))),
                        name = getPlayerName(player),
                        vip = result and #result > 0 and (result[1].active == 1 and "true" or "false")
                    }
                )
            end

        end
    end
    triggerClientEvent(root, "updateOnlinePlayers", root, players)
end

validateVipDays = function()
    local query = dbQuery(db, "SELECT * FROM vip")
    if not query then
        print("[GERENCIADOR VIP] - Erro ao executar consulta para validar VIPs!")
        return
    end

    local result = dbPoll(query, -1)
    if not result then
        print("[GERENCIADOR VIP] - Erro ao buscar resultados do banco de dados para VIPs!")
        return
    end

    local currentTime = os.time()

    for _, vip in ipairs(result) do
        local expirationTime = os.time({
            year = tonumber(vip.days:sub(1, 4)),
            month = tonumber(vip.days:sub(6, 7)),
            day = tonumber(vip.days:sub(9, 10)),
            hour = tonumber(vip.days:sub(12, 13)),
            min = tonumber(vip.days:sub(15, 16)),
            sec = tonumber(vip.days:sub(18, 19))
        })

        if not expirationTime then
            print("[GERENCIADOR VIP] - Erro ao converter vip.days para timestamp para o VIP ID " .. vip.id)
            return
        end

        if currentTime >= expirationTime and vip.active == 1 then
            dbExec(db, "UPDATE vip SET active = 0 WHERE id = ?", vip.id)
            
            local aclGroup = aclGetGroup(tostring(vip.type))
            if aclGroup then
                local objects = aclGroupListObjects(aclGroup)
                local isInAcl = false

                for _, object in ipairs(objects) do
                    if object == "user." .. vip.account then
                        isInAcl = true
                        break
                    end
                end

                if isInAcl then
                    aclGroupRemoveObject(aclGroup, "user." .. vip.account)
                else
                    print("[GERENCIADOR VIP] - O jogador " .. removeHex(vip.name) .. " não está na ACL [" .. tostring(vip.type) .. "] portanto, não foi removido.")
                end
            else
                print("[GERENCIADOR VIP] - ACL [" .. tostring(vip.type) .. "] não encontrada.")
            end

            addLog("O VIP [" .. vip.type .. "] de " .. vip.name .. "[" .. vip.id .. "] expirou.")

            local player = getPlayerFromName(vip.name)
            if player then
                outputChatBox("* O seu VIP expirou!", player, 255, 0, 0)
            end
        end
    end

    fetchVipList()
end

setTimer(validateVipDays, 60000, 0)




--> salario vip

local salary = {}

addCommandHandler(tostring(config.manager.cmd_salary), function(player)
    local account = getPlayerAccount(player)
    if isGuestAccount(account) then
        outputChatBox("* Você não está logado!", player, 255, 0, 0)
        return
    end

    local vipID = (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player)))
    local query = dbQuery(db, "SELECT * FROM vip WHERE id = ?", vipID)
    if not query then
        outputChatBox("* Erro ao consultar VIP no banco de dados!", player, 255, 0, 0)
        return
    end

    local result = dbPoll(query, -1)
    if not result or #result == 0 then
        outputChatBox("* Você não possui VIP ativo!", player, 255, 0, 0)
        return
    end

    local vip = result[1]
    if vip.active ~= 1 then
        outputChatBox("* Seu VIP não está ativo!", player, 255, 0, 0)
        return
    end

    if salary[vip.id] == vipID  then
        outputChatBox("* Você já resgatou seu salário recentemente!", player, 255, 0, 0)
        return
    end
    
    local bonus = tonumber(config.manager.vips[vip.type].salary)

    if config.debuggingEnabled then
        iprint(
            "salaryRescued",
            {
                id = vipID,
                name = removeHex(getPlayerName(player)) .. "[" .. (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))) .. "]",
                bonus = bonus,
                type = vip.type
            }
        )
    end

    setPlayerMoney(player, getPlayerMoney(player) + bonus)
    salary[vip.id] = (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player)))
    setTimer(function()
        salary[vip.id] = nil
    end, tonumber(config.manager.hours_salary) * 3600000, 1)

    outputChatBox("* Você resgatou seu salário de $" .. formatNumber(bonus) .. " como " .. vip.type, player, 0, 255, 0)
    addLog("O(A) " .. removeHex(getPlayerName(player)) .. "[" .. (getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))) .. "] resgatou o salário VIP de $" .. formatNumber(bonus) .. " sendo um VIP [" .. vip.type .. "].")

end)



--> abrir painel

hasPanelPermission = function()
    if hasPermission(client, config.manager.acl) then
        triggerClientEvent(client, "showPanel", client)
    end
end



--> adicionar, remover, renovar vip

addVip = function(id, playerName, days, vipType)
    local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", id), -1)
    if result and #result > 0 then
        local active = result[1].active
        if active == 1 then
            outputChatBox("* O jogador selecionado já possui um VIP ativo!", source, 255, 0, 0)
            return
        elseif active == 0 then
            outputChatBox("* O jogador selecionado possui um VIP inativo!", source, 255, 0, 0)
            outputChatBox("* Renove o VIP do mesmo utilizando o botao de Renovar!", source, 255, 0, 0)
            return
        end
    else

        if action then
            outputChatBox("* Aguarde um momento antes de realizar outra ação!", source, 255, 0, 0)
            return
        end

        local futureDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + days * 86400)
        local limit = convertToDateLimitFormat(futureDate)
        local acc = getPlayerAccount(getPlayerFromName(playerName)) and getAccountName(getPlayerAccount(getPlayerFromName(playerName))) or "none"
        
        if config.debuggingEnabled then
            iprint(
                "addedVip",
                {
                    id = id,
                    name = removeHex(playerName),
                    days = days,
                    acc = acc,
                    type = vipType,
                    staff = removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "]"
                }
            )
        end

        dbExec(db, "INSERT INTO vip (id, name, days, active, type, account, staff, dateLimit, date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", id, removeHex(playerName), futureDate, 1, vipType, acc, removeHex(getPlayerName(source)).."[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "]", limit, os.date("%d/%m/%Y"))
        aclGroupAddObject(aclGetGroup(tostring(vipType)), "user."..acc)

        sendDynamicMessageToAll(string.format(config.infoDx.textsToAllPlayers["addedVip"], removeHex(playerName), id, vipType), { isRainbow = true })
        
        action = true
        setTimer(function()
            action = false
        end, (tonumber(config.infoDx.timer_activation) * 1000), 1)

        outputChatBox("* Voce recebeu um bonus pela ativação do " .. vipType .. " !", getPlayerFromName(playerName), 0, 255, 0)
        setPlayerMoney(getPlayerFromName(playerName), getPlayerMoney(getPlayerFromName(playerName)) + config.manager.vips[vipType].bonus)
        
        addLog("O(A) " .. removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "] ativou o [" .. vipType .. "] para " .. removeHex(getPlayerName(getPlayerFromName(playerName))) .. "[" .. (getElementData(getPlayerFromName(playerName), tostring(config.id_elementData)) or getAccountID(getPlayerAccount(getPlayerFromName(playerName)))) .. "] por " .. days .. " dias.")
        triggerEvent("loadLog", root, source)

        
        fetchVipList()
        fetchOnlinePlayers()
    end
end

removeVip = function(id)
    local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", id), -1)

    if not result or #result == 0 then
        outputChatBox("* O VIP de ID " .. id .. " não foi encontrado!", source, 255, 0, 0)
        return
    else

        if action then
            outputChatBox("* Aguarde um momento antes de realizar outra ação!", source, 255, 0, 0)
            return
        end

        local id = result[1].id
        local vipType = result[1].type
        local acc = result[1].account
        local playerName = result[1].name
        local player = getPlayerFromName(playerName)
        
        if config.debuggingEnabled then
            iprint(
                "removedVip",
                {
                    id = id,
                    name = removeHex(playerName),
                    acc = acc,
                    type = vipType,
                    staff = removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "]"
                }
            )
        end

        outputChatBox("* VIP removido com sucesso", source, 0, 255, 0)
        aclGroupRemoveObject(aclGetGroup(tostring(vipType)), "user."..acc)
        addLog("O(A) " .. removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "] removeu o [" .. vipType .. "] de " .. removeHex(playerName) .. "[" .. id .. "]." )
        
        if player then
            outputChatBox("* O seu VIP foi removido!", player, 255, 0, 0)
        end
        
        dbExec(db, "DELETE FROM vip WHERE id=?", id)
        triggerEvent("loadLog", root, source)


        fetchVipList()
    end

end

renewVip = function(id, playerName, days, vipType)
    local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", id), -1)
    if result and #result > 0 then

        if action then
            outputChatBox("* Aguarde um momento antes de realizar outra ação!", source, 255, 0, 0)
            return
        end

        local vip = result[1]

        local expirationDate = vip.days
        
        local year, month, day, hour, minute, second = expirationDate:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            
        if not year or not month or not day then
            outputChatBox("* Erro ao processar a data de expiração!", source, 255, 0, 0)
            return
        end
        
        local expirationTimestamp = os.time({
            year = tonumber(year), 
            month = tonumber(month), 
            day = tonumber(day), 
            hour = tonumber(hour), 
            min = tonumber(minute), 
            sec = tonumber(second)
        })
        
        expirationTimestamp = expirationTimestamp + (days * 86400)
        
        local newExpirationDate = os.date("%Y-%m-%d %H:%M:%S", expirationTimestamp)
        local acc = vip.account
        local limit = convertToDateLimitFormat(newExpirationDate)

        if config.debuggingEnabled then
            iprint(
                "renewedVip",
                {
                    id = id,
                    name = removeHex(playerName),
                    days = days,
                    type = vipType,
                    acc = acc,
                    staff = removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "]"
                }
            )
        end

        dbExec(db, "UPDATE vip SET days=?, type=?, active=1, dateLimit=? WHERE name=?", newExpirationDate, vipType, limit, playerName)
        aclGroupRemoveObject(aclGetGroup(tostring(vip.type)), "user."..acc)
        aclGroupAddObject(aclGetGroup(tostring(vipType)), "user."..acc)

        if vipType == vip.type and (calculateDaysDifference(vip.days) >= 1 or days >= 1) then
            sendDynamicMessageToAll(string.format(config.infoDx.textsToAllPlayers["renewVip"], removeHex(playerName), id), { isRainbow = true })
        end

        action = true
        setTimer(function()
            action = false
        end, (tonumber(config.infoDx.timer_activation) * 1000), 1)
        fetchVipList()

        local player = getPlayerFromName(playerName)

        if player then
            outputChatBox("* Seu VIP foi renovado por " .. days .. " dias!", player, 0, 255, 0)
        end

        outputChatBox("* VIP renovado com sucesso", source, 0, 255, 0)
        
        if vipType == vip.type then
            addLog("O(A) " .. removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "] renovou o [" .. vipType .. "] de " .. removeHex(playerName) .. "[" .. id .. "] por " .. days .. " dias.")
        else
            addLog("O(A) " .. removeHex(getPlayerName(source)) .. "[" .. (getElementData(source, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(source))) .. "] alterou o [" .. vip.type .. "] de " .. removeHex(playerName) .. "[" .. id .. "] para " .. vipType .. " por " .. days .. " dias.")
        end


        triggerEvent("loadLog", root, source)
    else
        outputChatBox("* O jogador selecionado não possui um VIP para renovar!", source, 255, 0, 0)
    end
end



--> abrir painel de renovação

getInfoMember = function(id)
    local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", id), -1)
    if result and #result > 0 then
        local days = calculateDaysDifference(result[1].days)
        return triggerClientEvent(source, "showRenewPanel", source, result[1].id, result[1].name, result[1].type, days)
    else
        return triggerClientEvent(source, "showRenewPanel", source, "047", "drypzz", "dev")
    end
end



--> sorteio vip

local giveaway = {
    event = {},
    players = {},
    enter = false
}

addCommandHandler(tostring(config.giveaway.cmd_create), function(player, cmd, num1, num2, days, ...)
    if hasPermission(player, config.giveaway.acl) then

        if giveaway.enter then
            outputChatBox("* Já existe um sorteio ativo no momento!", player, 255, 0, 0)
            return
        end

        local type = table.concat({...}, " ")

        if not tonumber(num1) or not tonumber(num2) or not tonumber(days) or type == "" then
            outputChatBox("* Digite: /" .. cmd .. " <num1> <num2> <dias de vip> <tipo de vip>", player, 255, 0, 0)
            return
        end

        if tonumber(num1) == tonumber(num2) then
            outputChatBox("* Os números não podem ser iguais!", player, 255, 0, 0)
            return
        end

        if tonumber(num1) <= 0 or tonumber(num2) <= 0 then
            outputChatBox("* Os números devem ser maiores que 0!", player, 255, 0, 0)
            return
        end

        if tonumber(days) <= 0 then
            outputChatBox("* Os dias devem ser maiores que 0!", player, 255, 0, 0)
            return
        end

        if not config.manager.vips[tostring(type)] then
            outputChatBox("* Tipo de VIP inválido!", player, 255, 0, 0)
            return
        end

        giveaway.event = {
            num1 = tonumber(num1),
            num2 = tonumber(num2),
            days = tonumber(days),
            type = type,
            owner = removeHex(getPlayerName(player)),
            ownerID = getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player)),
            event = true
        }

        if config.debuggingEnabled then
            iprint("addedGiveawayEvent", giveaway.event)
        end

        giveaway.players = {}
        giveaway.enter = true

        sendDynamicMessageToAll("* Sorteio VIP *\n* Digite '/" .. tostring(config.giveaway.cmd_join) .. "' para participar *", { color1 = 53, color2 = 153, color3 = 204 })

        playSoundFrontEnd(root, 5)

        action = true

        setTimer(function()
            giveaway.enter = false
            sendDynamicMessageToAll("* Tempo limite para entrar no sorteio atingido *", { color1 = 255, color2 = 0, color3 = 0 })
            playSoundFrontEnd(root, 3)
        end, ((tonumber(config.giveaway.timer_giveaway) - 10) * 1000), 1)

        setTimer(function()
            sendDynamicMessageToAll("* Sorteando VIP em\n5...", { color1 = 255, color2 = 255, color3 = 0 })
            playSoundFrontEnd(root, 5)
        end, ((tonumber(config.giveaway.timer_giveaway) - 5) * 1000), 1)

        setTimer(function()
            sendDynamicMessageToAll("* Sorteando VIP em\n4...", { color1 = 255, color2 = 255, color3 = 0 })
            playSoundFrontEnd(root, 5)
        end, ((tonumber(config.giveaway.timer_giveaway) - 4) * 1000), 1)

        setTimer(function()
            sendDynamicMessageToAll("* Sorteando VIP em\n3...", { color1 = 255, color2 = 255, color3 = 0 })
            playSoundFrontEnd(root, 5)
        end, ((tonumber(config.giveaway.timer_giveaway) - 3) * 1000), 1)

        setTimer(function()
            sendDynamicMessageToAll("* Sorteando VIP em\n2...", { color1 = 255, color2 = 255, color3 = 0 })
            playSoundFrontEnd(root, 5)
        end, ((tonumber(config.giveaway.timer_giveaway) - 2) * 1000), 1)

        setTimer(function()
            sendDynamicMessageToAll("* Sorteando VIP em\n1...", { color1 = 255, color2 = 255, color3 = 0 })
            playSoundFrontEnd(root, 5)
        end, ((tonumber(config.giveaway.timer_giveaway) - 1) * 1000), 1)

        setTimer(function()

            sendDynamicMessageToAll("")

            if #giveaway.players == 0 then
                outputChatBox(" ", root)
                outputChatBox(" ", root)
                outputChatBox("* Sorteio cancelado!", root, 255, 0, 0)
                outputChatBox("* Sem participantes presentes!", root, 255, 0, 0)
                outputChatBox(" ", root)
                outputChatBox(" ", root)
            else
                local randomIndex = math.random(1, #giveaway.players)
                local selectedNumber = giveaway.players[randomIndex].number

                local winner = nil
                for _, participant in ipairs(giveaway.players) do
                    if participant.number == selectedNumber then
                        winner = participant
                        break
                    end
                end

                if not getPlayerAccount(getPlayerFromName(winner.name)) or isGuestAccount(getPlayerAccount(getPlayerFromName(winner.name))) then
                    outputChatBox(" ", root)
                    outputChatBox(" ", root)
                    outputChatBox("* Sorteio cancelado!", root, 255, 0, 0)
                    outputChatBox("* O vencedor do sorteio esta offline!", root, 255, 0, 0)
                    outputChatBox("* n°: " .. selectedNumber .. " - " .. removeHex(winner.name) .. "[" .. winner.id .. "]", root, 255, 0, 0)
                    outputChatBox(" ", root)
                    outputChatBox(" ", root)
                    return;
                end
        
                outputChatBox(" ", root)
                outputChatBox(" ", root)
                outputChatBox("* O número sorteado foi: " .. selectedNumber, root, 53, 153, 204)
                outputChatBox("* O vencedor do sorteio é: " .. removeHex(winner.name) .. "[" .. winner.id .. "]", root, 53, 153, 204)
                outputChatBox(" ", root)
                outputChatBox(" ", root)
                
                giveawayVip(giveaway.event.type, winner.acc, winner.name, winner.id, giveaway.event.days)
                
                if config.debuggingEnabled then
                    iprint("giveawayWinner", winner)
                end
            end

            action = false

            giveaway = { event = {}, players = {}, enter = false }
        end, (tonumber(config.giveaway.timer_giveaway) * 1000), 1)
    end
end)

addCommandHandler(config.giveaway.show_giveaway, function(player)
    if hasPermission(player, config.giveaway.acl) then

        if not giveaway.event.event then
            outputChatBox("* Não há sorteio ativo no momento!", player, 255, 0, 0)
            return
        end

        outputChatBox(" ", player)
        outputChatBox(" ", player)
        outputChatBox("* Jogadores participando do sorteio:", player, 0, 255, 0)
        for _, p in ipairs(giveaway.players) do
            outputChatBox("* n°: " .. p.number .. " - " .. removeHex(p.name) .. "[" .. p.id .. "]", player, 0, 255, 0)
        end
        outputChatBox(" ", player)
        outputChatBox(" ", player)

        if config.debuggingEnabled then
            iprint("lsitGiveawayPlayer", giveaway.players)
        end
    end
end)

addCommandHandler(tostring(config.giveaway.cmd_join), function(player)
    local result = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE id=?", getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player))), -1)

    if isGuestAccount(getPlayerAccount(player)) then
        return
    end
    
    if not giveaway.event.event then
        outputChatBox("* Não há sorteio ativo no momento!", player, 255, 0, 0)
        return
    end

    if result and #result > 0 then
        outputChatBox("* Você já possui um VIP ativo!", player, 255, 0, 0)
        return
    end

    if not giveaway.enter then
        outputChatBox("* Tempo limite para entrar atingido!", player, 255, 0, 0)
        return
    end

    for _, p in ipairs(giveaway.players) do
        if p.id == getElementData(player, tostring(config.id_elementData)) then
            outputChatBox("* Você já está participando do sorteio!", player, 255, 0, 0)
            return
        end
    end

    triggerClientEvent(player, "showGiveawayPanel", player, {
        id = getElementData(player, tostring(config.id_elementData)) or getAccountID(getPlayerAccount(player)),
        name = getPlayerName(player),
        acc = getPlayerAccount(player) and getAccountName(getPlayerAccount(player)) or "none",
        type = giveaway.event.type,
        num1 = giveaway.event.num1,
        num2 = giveaway.event.num2,
        days = giveaway.event.days
    })
end)

getGiveawayNumberPlayer = function(number, acc, name, id)
    
    for _, p in ipairs(giveaway.players) do
        if p.number == number then
            triggerClientEvent(source, "giveawayNumberExists", source, true)
            return
        end
    end
    
    triggerClientEvent(source, "giveawayNumberExists", source, false)
    
    if not giveaway.enter then
        outputChatBox("* Tempo limite para entrar atingido!", source, 255, 0, 0)
        triggerClientEvent(source, "closeGiveawayPanel", source)
        return
    end

    table.insert(giveaway.players, {
        name = name,
        id = id,
        acc = acc,
        number = number
    })

    triggerClientEvent(source, "closeGiveawayPanel", source)

    if config.debuggingEnabled then
        iprint(
            "addedGiveawayPlayer",
            {
                number = number,
                acc = acc,
                name = removeHex(name),
                id = id
            }
        )
    end

    outputChatBox("* Você entrou no sorteio com sucesso! Número escolhido: " .. number, source, 0, 255, 0)
end

giveawayVip = function(type, acc, name, id, days)
    local futureDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + days * 86400)
    local limit = convertToDateLimitFormat(futureDate)
    
    if config.debuggingEnabled then
        iprint(
            "givedVip",
            {
                id = id,
                name = removeHex(name),
                acc = acc,
                type = type,
                days = days,
                staff = "Sorteio VIP"
            }
        )
    end

    dbExec(db, "INSERT INTO vip (id, name, days, active, type, account, staff, dateLimit, date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", id, removeHex(name), futureDate, 1, type, acc, "Sorteio VIP", limit, os.date("%d/%m/%Y"))
    aclGroupAddObject(aclGetGroup(tostring(type)), "user." .. acc)

    sendDynamicMessageToAll(string.format(config.infoDx.textsToAllPlayers["givedVip"], removeHex(name), id, type), { isRainbow = true })

    addLog("O(A) " .. removeHex(getPlayerName(getPlayerFromName(name))) .. "[" .. id .. "] ganhou um VIP [" .. type .. "] no sorteio.")
    
    setPlayerMoney(getPlayerFromName(name), getPlayerMoney(getPlayerFromName(name)) + config.manager.vips[type].bonus)
    outputChatBox("* Você recebeu um bônus pela ativação do " .. type .. "!", getPlayerFromName(name), 0, 255, 0)
        
    action = true
    setTimer(function()
        action = false
    end, (tonumber(config.infoDx.timer_activation) * 1000), 1)

    fetchVipList()
end



--> Logs

addLog = function(txt)
	local file = false

	if not (fileExists("logs.txt")) then
        fileCreate("logs.txt")
    end

	file = fileOpen ("logs.txt")
	fileSetPos(file, fileGetSize(file))

	local tag = string.format("* %02d/%02d/%d - %02d:%02d:%02d: ", getRealTime().monthday, getRealTime().month +1, getRealTime().year +1900, getRealTime().hour, getRealTime().minute, getRealTime().second)
	fileWrite(file, tag..txt.."\r\n")

    if config.debuggingEnabled then
        iprint("addLog", {
            log = "added",
        })
    end

    fileClose(file)
end

loadLog = function(source)
    source = source or client
    local file = fileOpen("logs.txt")
    if (file) then
        local logs = fileRead(file, fileGetSize(file))
        fileClose(file)

        if config.debuggingEnabled then
            iprint("loadLog", {
                logs = "loaded",
            })
        end

        triggerClientEvent(source, "displayLog", root, logs)
    else
        if config.debuggingEnabled then
            iprint("loadLog", {
                logs = "failed",
            })
        end

        triggerClientEvent(source, "displayLog", root, " ")
    end

end



--> funções exportadas

getTimeVip = function(player)
	local acc = getAccountName(getPlayerAccount(player))
    local query = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE account=?", acc), -1)
    if not query or #query == 0 then
        return "---"
    else
        return formatTimeRemaining(query[1].days)
    end
end

getDateLimitVip = function(player)
    local acc = getAccountName(getPlayerAccount(player))
    local query = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE account=?", acc), -1)
    if not query or #query == 0 then
        return "---"
    else
        return query[1].dateLimit
    end
end

getTypeVip = function(acc)
    local query = dbPoll(dbQuery(db, "SELECT * FROM vip WHERE account=?", acc), -1)
    if not query or #query == 0 then
        return "N/A"
    else
        return query[1].type
    end
end



--> events

addEvent("checkPermission", true)
addEventHandler("checkPermission", root, hasPanelPermission)

addEvent("fetchOnlinePlayers", true)
addEventHandler("fetchOnlinePlayers", root, fetchOnlinePlayers)

addEvent("fetchVipList", true)
addEventHandler("fetchVipList", root, fetchVipList)

addEvent("addVip", true)
addEventHandler("addVip", root, addVip)

addEvent("removeVip", true)
addEventHandler("removeVip", root, removeVip)

addEvent("getInfoMember", true)
addEventHandler("getInfoMember", root, getInfoMember)

addEvent("renewVip", true)
addEventHandler("renewVip", root, renewVip)

addEvent("loadLog", true)
addEventHandler("loadLog", root, loadLog)

addEvent("getGiveawayNumberPlayer", true)
addEventHandler("getGiveawayNumberPlayer", root, getGiveawayNumberPlayer)