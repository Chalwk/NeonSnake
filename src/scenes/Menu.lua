-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local math_pi = math.pi
local math_max = math.max
local table_insert = table.insert
local table_remove = table.remove
local ipairs = ipairs

local lg = love.graphics

local helpText = {
    "Control the snake using arrow keys or WASD!",
    "",
    "Features:",
    "• Multiple food types with different values",
    "• Power-ups: Speed boost, Shield, Magnet",
    "• Progressive difficulty - snake speeds up",
    "• Wrap-around screen edges",
    "• Beautiful neon visuals and particle effects",
    "",
    "Food Types:",
    "• Red Apple: 10 points, +1 length",
    "• Purple Berry: 20 points, +1 length",
    "• Golden Fruit: 50 points, +2 length",
    "• Rainbow Food: 100 points, +3 length",
    "",
    "Power-ups:",
    "• Blue: Speed boost (5 seconds)",
    "• Yellow: Invincibility (8 seconds)",
    "• Red: Food magnet (10 seconds)",
    "",
    "Controls:",
    "• Arrow Keys or WASD: Move snake",
    "• P: Pause game",
    "• R: Restart game",
    "• ESC: Return to menu",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)
    instance.difficulty = "easy"
    instance.title = {
        text = "NEON SNAKE",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2,
        glow = 0,
        glowDirection = 1
    }
    instance.showHelp = false
    instance.buttonHover = nil
    instance.time = 0
    instance.menuParticles = {}

    instance:createMenuButtons()
    instance:createOptionsButtons()
    instance:initMenuParticles()

    return instance
end

function Menu:initMenuParticles()
    self.menuParticles = {}
    for _ = 1, 30 do
        table_insert(self.menuParticles, {
            x = math_random(0, screenWidth),
            y = math_random(0, screenHeight),
            size = math_random(2, 8),
            speed = math_random(10, 30),
            angle = math_random() * math_pi * 2,
            life = math_random(3, 8),
            maxLife = math_random(3, 8),
            color = {
                math_random(0.1, 0.4),
                math_random(0.6, 1.0),
                math_random(0.1, 0.4)
            }
        })
    end
end

function Menu:setFonts(fonts)
    self.smallFont = fonts.small
    self.mediumFont = fonts.medium
    self.largeFont = fonts.large
    self.sectionFont = fonts.section
    self.titleFont = fonts.title
end

function Menu:setScreenSize(width, height)
    self:updateButtonPositions()
    self:updateOptionsButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 280,
            height = 60,
            x = 0,
            y = 0,
            hover = false,
            pulse = 0
        },
        {
            text = "Options",
            action = "options",
            width = 280,
            height = 60,
            x = 0,
            y = 0,
            hover = false,
            pulse = 0
        },
        {
            text = "How to Play",
            action = "help",
            width = 280,
            height = 60,
            x = 0,
            y = 0,
            hover = false,
            pulse = 0
        },
        {
            text = "Quit Game",
            action = "quit",
            width = 280,
            height = 60,
            x = 0,
            y = 0,
            hover = false,
            pulse = 0
        }
    }

    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        -- Difficulty Section
        {
            text = "Easy",
            action = "diff easy",
            width = 200,
            height = 50,
            x = 0,
            y = 0,
            section = "difficulty",
            hover = false,
            pulse = 0
        },
        {
            text = "Medium",
            action = "diff medium",
            width = 200,
            height = 50,
            x = 0,
            y = 0,
            section = "difficulty",
            hover = false,
            pulse = 0
        },
        {
            text = "Hard",
            action = "diff hard",
            width = 200,
            height = 50,
            x = 0,
            y = 0,
            section = "difficulty",
            hover = false,
            pulse = 0
        },

        -- Navigation
        {
            text = "Back to Menu",
            action = "back",
            width = 200,
            height = 55,
            x = 0,
            y = 0,
            section = "navigation",
            hover = false,
            pulse = 0
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = screenHeight / 2 - 30
    for i, button in ipairs(self.menuButtons) do
        button.x = (screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 80
    end
end

function Menu:updateOptionsButtonPositions()
    local centerX = screenWidth / 2
    local totalSectionsHeight = 220
    local startY = (screenHeight - totalSectionsHeight) / 2

    -- Difficulty buttons
    local diffButtonW, diffButtonH, diffSpacing = 200, 50, 20
    local diffTotalW = 3 * diffButtonW + 2 * diffSpacing
    local diffStartX = centerX - diffTotalW / 2
    local diffY = startY + 50

    -- Navigation
    local navY = startY + 140

    local diffIndex = 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = diffStartX + diffIndex * (diffButtonW + diffSpacing)
            button.y = diffY
            diffIndex = diffIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY
        end
    end
end

function Menu:update(dt)
    self.time = self.time + dt

    self:updateButtonPositions()
    self:updateOptionsButtonPositions()

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    self.title.glow = self.title.glow + self.title.glowDirection * 0.8 * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    if self.title.glow > 1 then
        self.title.glow = 1
        self.title.glowDirection = -1
    elseif self.title.glow < 0.3 then
        self.title.glow = 0.3
        self.title.glowDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt

    -- Update button hover states
    local mouseX, mouseY = love.mouse.getX(), love.mouse.getY()
    local currentButtons = self.showHelp and {} or (self.screenState == "options" and self.optionsButtons or self.menuButtons)

    local newHover = nil
    for i, button in ipairs(currentButtons) do
        local wasHover = button.hover
        button.hover = mouseX >= button.x and mouseX <= button.x + button.width and
                      mouseY >= button.y and mouseY <= button.y + button.height

        if button.hover then
            newHover = i
            if not wasHover then
                -- Button just got hovered
                button.pulse = 0
            end
        end

        if button.hover then
            button.pulse = button.pulse + dt * 8
        else
            button.pulse = math_max(0, button.pulse - dt * 4)
        end
    end

    self.buttonHover = newHover

    -- Update menu particles
    for i = #self.menuParticles, 1, -1 do
        local particle = self.menuParticles[i]
        particle.life = particle.life - dt

        if particle.life <= 0 then
            table_remove(self.menuParticles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

            -- Wrap around
            if particle.x < -50 then particle.x = screenWidth + 50 end
            if particle.x > screenWidth + 50 then particle.x = -50 end
            if particle.y < -50 then particle.y = screenHeight + 50 end
            if particle.y > screenHeight + 50 then particle.y = -50 end
        end
    end

    while #self.menuParticles < 30 do
        table_insert(self.menuParticles, {
            x = math_random(-50, screenWidth + 50),
            y = math_random(-50, screenHeight + 50),
            size = math_random(2, 8),
            speed = math_random(10, 30),
            angle = math_random() * math_pi * 2,
            life = math_random(3, 8),
            maxLife = math_random(3, 8),
            color = {
                math_random(0.1, 0.4),
                math_random(0.6, 1.0),
                math_random(0.1, 0.4)
            }
        })
    end
end

function Menu:draw(state)
    self.screenState = state

    -- Draw menu particles
    for _, particle in ipairs(self.menuParticles) do
        local alpha = (particle.life / particle.maxLife) * 0.3
        lg.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        lg.circle("fill", particle.x, particle.y, particle.size)
    end

    -- Draw animated title with glow effect
    lg.setFont(self.titleFont)

    -- Glow effect
    for i = 1, 3 do
        local glowSize = i * 2
        lg.setColor(0.1, 0.8, 0.3, self.title.glow * 0.2 / i)
        lg.printf(self.title.text, -glowSize, -glowSize, screenWidth, "center")
        lg.printf(self.title.text, glowSize, glowSize, screenWidth, "center")
    end

    -- Main title
    lg.setColor(0.2, 1.0, 0.4, 0.9 + self.title.glow * 0.3)
    lg.push()
    lg.translate(screenWidth / 2, screenHeight / 4)
    lg.rotate(math_sin(self.title.rotation) * 0.05)
    lg.scale(self.title.scale, self.title.scale)
    lg.printf(self.title.text, -screenWidth / 2, -self.titleFont:getHeight() / 2, screenWidth, "center")
    lg.pop()

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay()
        else
            self:drawMenuButtons()
            -- Draw animated tagline
            lg.setColor(0.6, 1.0, 0.8, 0.7 + math_sin(self.time * 3) * 0.3)
            lg.setFont(self.mediumFont)
            lg.printf("A Cybernetic Evolution of a Classic",
                0, screenHeight / 3 + 5, screenWidth, "center")
        end
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Draw animated copyright
    lg.setColor(1, 1, 1, 0.4 + math_sin(self.time * 2) * 0.2)
    lg.setFont(self.smallFont)
    lg.printf("© 2025 Jericho Crosby – Neon Snake Evolution",
        10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpOverlay()
    -- Animated overlay
    local pulse = math_sin(self.time * 4) * 0.1 + 0.9
    lg.setColor(0, 0, 0, 0.85 * pulse)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Help box with animation
    local boxWidth = 750
    local boxHeight = 700
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Animated box background
    lg.setColor(0.05, 0.1, 0.15, 0.95)
    lg.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 15)

    -- Pulsing box border
    lg.setColor(0.2, 0.8, 0.3, 0.6 + math_sin(self.time * 5) * 0.4)
    lg.setLineWidth(4)
    lg.rectangle("line", boxX, boxY, boxWidth, boxHeight, 15)

    -- Title with glow
    lg.setColor(0.3, 1.0, 0.5, 1.0)
    lg.setFont(self.largeFont)
    lg.printf("How to Play", boxX, boxY + 25, boxWidth, "center")

    -- Help text with fade-in effect
    lg.setColor(0.8, 1.0, 0.9, 0.9)
    lg.setFont(self.smallFont)

    local lineHeight = 22
    for i, line in ipairs(helpText) do
        local y = boxY + 90 + (i - 1) * lineHeight
        lg.printf(line, boxX + 40, y, boxWidth - 80, "left")
    end

    lg.setLineWidth(1)
end

function Menu:drawOptionsInterface()
    local totalSectionsHeight = 220
    local startY = (screenHeight - totalSectionsHeight) / 2

    -- Draw section headers with animation
    lg.setFont(self.sectionFont)
    lg.setColor(0.6, 1.0, 0.8, 0.8 + math_sin(self.time * 3) * 0.2)
    lg.printf("Difficulty", 0, startY + 20, screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            self:drawButton(button)

            -- Draw animated selection highlight
            if button.action:sub(1, 4) == "diff" then
                local difficulty = button.action:sub(6)
                if difficulty == self.difficulty then
                    local pulse = math_sin(self.time * 6) * 0.2 + 0.8
                    lg.setColor(0.2, 0.8, 0.2, 0.3 * pulse)
                    lg.rectangle("fill", button.x - 5, button.y - 5,
                                          button.width + 10, button.height + 10, 8)
                end
            end
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    local hoverFactor = button.pulse
    local pulse = math_sin(self.time * 5 + hoverFactor) * 0.1

    -- Button background with hover effect
    if button.hover then
        lg.setColor(0.3, 0.4, 0.6, 0.9 + hoverFactor * 0.3)
    else
        lg.setColor(0.2, 0.25, 0.4, 0.8)
    end

    lg.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    -- Animated border
    local borderPulse = button.hover and (0.8 + pulse) or 0.6
    lg.setColor(0.2, 0.8, 0.3, borderPulse)
    lg.setLineWidth(2 + hoverFactor)
    lg.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)

    -- Button text with glow effect
    if button.hover then
        lg.setColor(1, 1, 1, 1)
        -- Text glow
        lg.setColor(0.8, 1.0, 0.8, 0.5)
        --lg.printf(button.text, button.x - 2, button.y - 2, button.width, "center")
    end

    lg.setColor(1, 1, 1, 0.9 + hoverFactor * 0.3)
    lg.setFont(self.mediumFont)
    lg.printf(button.text, button.x, button.y + (button.height - self.mediumFont:getHeight()) / 2,
                        button.width, "center")

    lg.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    -- If help is showing, any click closes it
    if state == "menu" and self.showHelp then
        self.showHelp = false
        return "help_close"
    end

    return nil
end

function Menu:setDifficulty(difficulty) self.difficulty = difficulty end

function Menu:getDifficulty() return self.difficulty end

return Menu