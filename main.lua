-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")

local game, menu, backgroundManager
local screenWidth, screenHeight
local gameState = "menu"
local nextGameState = "menu"
local fonts = {}
local transition = {
    active = false,
    timer = 0,
    duration = 0.8,
    type = "fade"
}

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

local function startTransition(targetState, transitionType)
    if transition.active then return end

    nextGameState = targetState
    transition.active = true
    transition.timer = 0
    transition.type = transitionType or "fade"
end

local function updateTransition(dt)
    if not transition.active then return end

    transition.timer = transition.timer + dt

    if transition.timer >= transition.duration then
        transition.active = false
        gameState = nextGameState

        -- Special case: when starting a new game
        if gameState == "playing" then
            game:startNewGame(menu:getDifficulty())
        end
    end
end

local function drawTransition()
    if not transition.active then return end

    local progress = transition.timer / transition.duration
    local alpha = 0

    if transition.type == "fade" then
        alpha = progress < 0.5 and progress * 2 or (1 - progress) * 2
        love.graphics.setColor(0, 0, 0, alpha * 0.8)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    elseif transition.type == "slide" then
        local offset = progress < 0.5 and progress * screenWidth * 2 or (1 - progress) * screenWidth * 2
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", offset - screenWidth, 0, screenWidth, screenHeight)
        love.graphics.rectangle("fill", -offset, 0, screenWidth, screenHeight)
    elseif transition.type == "wipe" then
        local height = progress * screenHeight * 1.2
        love.graphics.setColor(0, 0.1, 0.05, 0.9)
        love.graphics.rectangle("fill", 0, screenHeight - height, screenWidth, height)
    end
end

function love.load()
    love.window.setTitle("Neon Snake - Cyber Evolution")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("smooth")

    -- Load fonts
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(22)
    fonts.large = love.graphics.newFont(52)
    fonts.section = love.graphics.newFont(18)
    fonts.title = love.graphics.newFont(64)

    -- Set default font
    love.graphics.setFont(fonts.medium)

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()

    menu:setFonts(fonts)
    game:setFonts(fonts)

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()

    if transition.active then
        updateTransition(dt)
    else
        if gameState == "menu" then
            menu:update(dt, screenWidth, screenHeight)
        elseif gameState == "playing" then
            game:update(dt)
        elseif gameState == "options" then
            menu:update(dt, screenWidth, screenHeight)
        end
    end

    backgroundManager:update(dt)
end

function love.draw()
    backgroundManager:draw(screenWidth, screenHeight, gameState)

    if gameState == "menu" or gameState == "options" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end

    drawTransition()
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        if transition.active then return end

        if gameState == "menu" then
            local action = menu:handleClick(x, y, "menu")
            if action == "start" then
                startTransition("playing", "wipe")
            elseif action == "options" then
                startTransition("options", "slide")
            elseif action == "help" then
                menu.showHelp = not menu.showHelp
            elseif action == "quit" then
                love.event.quit()
            end
        elseif gameState == "options" then
            local action = menu:handleClick(x, y, "options")
            if not action then return end
            if action == "back" then
                startTransition("menu", "slide")
            elseif action:sub(1, 4) == "diff" then
                local difficulty = action:sub(6)
                menu:setDifficulty(difficulty)
            end
        elseif gameState == "playing" then
            if game:isGameOver() then
                startTransition("menu", "fade")
            end
        end
    end
end

function love.keypressed(key)
    if transition.active then return end

    if key == "escape" then
        if gameState == "playing" then
            startTransition("menu", "fade")
        elseif gameState == "options" then
            startTransition("menu", "slide")
        else
            love.event.quit()
        end
    elseif gameState == "playing" then
        game:handleKeypress(key)
    end
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end