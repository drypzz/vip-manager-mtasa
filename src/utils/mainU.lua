--[[
██████╗ ██████╗ ██╗   ██╗██████╗ ███████╗███████╗    ██████╗ ███████╗██╗   ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗╚══███╔╝╚══███╔╝    ██╔══██╗██╔════╝██║   ██║
██║  ██║██████╔╝ ╚████╔╝ ██████╔╝  ███╔╝   ███╔╝     ██║  ██║█████╗  ██║   ██║
██║  ██║██╔══██╗  ╚██╔╝  ██╔═══╝  ███╔╝   ███╔╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝
██████╔╝██║  ██║   ██║   ██║     ███████╗███████╗    ██████╔╝███████╗ ╚████╔╝ 
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝
--]]

--> utils



removeHex = function(s)
    if type (s) == "string" then
        while (s ~= s:gsub ("#%x%x%x%x%x%x", "")) do
            s = s:gsub ("#%x%x%x%x%x%x", "")
        end
    end
    return s or false
end;

formatNumber = function(number)
	assert(type(tonumber(number)) == "number", "Bad argument @\"formatNumber\" [Expected number at argument 1 got "..type(number).."]")
	for i = 1, (tostring(number):len() / 3) do
		number = string.gsub(number, "^(-?%d+)(%d%d%d)", "%1.%2")
	end
    
	return number
end

formatTimeRemaining = function(timestamp)
    local currentTime = getRealTime().timestamp
    local targetTime = nil

    if type(timestamp) == "string" then
        targetTime = os.time({
            year = tonumber(timestamp:sub(1, 4)),
            month = tonumber(timestamp:sub(6, 7)),
            day = tonumber(timestamp:sub(9, 10)),
            hour = tonumber(timestamp:sub(12, 13)),
            min = tonumber(timestamp:sub(15, 16)),
            sec = tonumber(timestamp:sub(18, 19)),
        })
    else
        targetTime = tonumber(timestamp)
    end
    
    if targetTime then
        local timeLeft = targetTime - currentTime

        if timeLeft > 0 then
            local daysLeft = math.floor(timeLeft / 86400)
            local hoursLeft = math.floor((timeLeft % 86400) / 3600)
            local minutesLeft = math.floor((timeLeft % 3600) / 60)
            return daysLeft .. " Dias e " .. hoursLeft .. " Horas" .. " - " .. minutesLeft .. " Min"
        else
            return "---"
        end
    else
        return "Data inválida"
    end
end

convertToDateLimitFormat = function(days)
    local year, month, day = days:match("(%d+)-(%d+)-(%d+)")
    if year and month and day then
        return string.format("%02d/%02d/%04d", day, month, year)
    else
        return "Data inválida"
    end
end

calculateDaysDifference = function(dateStr)
    local year, month, day, hour, min, sec = dateStr:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local targetDate = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})

    local currentDate = os.time()

    local diffInSeconds = currentDate - targetDate

    local diffInDays = math.abs(math.floor(diffInSeconds / (60 * 60 * 24)))

    return diffInDays
end

hasPermission = function(player, aclGroups)
    local accountName = getAccountName(getPlayerAccount(player))
    if not accountName then
        return false
    end

    for _, group in ipairs(aclGroups) do
        if isObjectInACLGroup("user." .. accountName, aclGetGroup(tostring(group))) then
            return true
        end
    end
    return false
end

local activeMessage = nil
local music = nil
local currentTimer = nil

function createDynamicMessage(message, options)
    local screenWidth, screenHeight = guiGetScreenSize()
    local textX = screenWidth / 2
    local textY = screenHeight / 10

    local isRainbow = options and options.isRainbow or false
    local color1 = options and options.color1 or 255
    local color2 = options and options.color2 or 255
    local color3 = options and options.color3 or 255

    local sounds = config.infoDx.sounds
    local baseTextSize = 3
    local currentTextSize = baseTextSize
    local targetTextSize = baseTextSize

    if activeMessage then
        if currentTimer and isTimer(currentTimer) then
            killTimer(currentTimer)
        end
        removeEventHandler("onClientRender", root, activeMessage.drawFunction)
        if isElement(music) then
            stopSound(music)
        end
    end

    if isRainbow then
        local soundFile = sounds[math.random(1, #sounds)]
        music = playSound("assets/sfx/" .. soundFile)
        setSoundVolume(music, 0.4)
    end

    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local function drawMessage()
        local tick = getTickCount()
        local alpha = 255

        if isRainbow then
            alpha = math.abs(math.sin(tick / 600) * 255)
            color1 = math.abs(math.sin(tick / 300) * 255)
            color2 = math.abs(math.sin(tick / 600) * 255)
            color3 = math.abs(math.sin(tick / 900) * 255)

            if isElement(music) then
                local fftData = getSoundFFTData(music, 1024)
                if fftData then
                    local intensity = math.max(fftData[2] or 0, fftData[3] or 0, fftData[4] or 0)
                    targetTextSize = baseTextSize + intensity * 2
                end
            end

            currentTextSize = lerp(currentTextSize, targetTextSize, 0.1)
        end

        dxDrawText(message, textX + 1, textY + 1, textX + 1, textY + 1, tocolor(0, 0, 0, alpha), currentTextSize, "sans", "center", "center", false, false, false, true, false)
        dxDrawText(message, textX + 2, textY + 2, textX + 2, textY + 2, tocolor(0, 0, 0, alpha), currentTextSize, "sans", "center", "center", false, false, false, true, false)
        dxDrawText(message, textX, textY, textX, textY, tocolor(color1, color2, color3, alpha), currentTextSize, "sans", "center", "center", false, false, false, true, false)
    end

    addEventHandler("onClientRender", root, drawMessage)

    if isRainbow then
        currentTimer = setTimer(function()
            if drawMessage then
                removeEventHandler("onClientRender", root, drawMessage)
            end
            if isElement(music) then
                stopSound(music)
            end
            activeMessage = nil
        end, tonumber(config.infoDx.timer_activation) * 1000, 1)
    end

    activeMessage = { text = message, options = options, isRainbow = isRainbow, drawFunction = drawMessage }
end

function sendDynamicMessageToAll(message, options)
    triggerClientEvent(root, "createDynamicMessage", root, message, options)
end