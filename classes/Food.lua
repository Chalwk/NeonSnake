-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_random = math.random
local math_sin = math.sin
local math_pi = math.pi
local table_insert = table.insert
local table_remove = table.remove

local lg = love.graphics

local Food = {}
Food.__index = Food

function Food.new(gridSize)
    local instance = setmetatable({}, Food)

    instance.gridSize = gridSize
    instance.items = {}
    instance.powerUps = {}
    instance.animationTime = 0
    instance.powerUpTimer = 0
    instance.powerUpSpawnInterval = 10

    -- Food types with glow colors
    instance.foodTypes = {
        {
            name = "apple",
            color = {0.9, 0.2, 0.2},
            glowColor = {1.0, 0.3, 0.3},
            value = 10,
            growAmount = 1,
            rarity = 1,
            pulseSpeed = 5
        },
        {
            name = "berry",
            color = {0.8, 0.3, 0.8},
            glowColor = {0.9, 0.4, 0.9},
            value = 20,
            growAmount = 1,
            rarity = 2,
            pulseSpeed = 6
        },
        {
            name = "golden",
            color = {1.0, 0.8, 0.2},
            glowColor = {1.0, 0.9, 0.3},
            value = 50,
            growAmount = 2,
            rarity = 3,
            pulseSpeed = 7
        },
        {
            name = "rainbow",
            color = {0.3, 0.8, 0.9},
            glowColor = {0.4, 0.9, 1.0},
            value = 100,
            growAmount = 3,
            rarity = 5,
            pulseSpeed = 8
        }
    }

    -- Power-up types
    instance.powerUpTypes = {
        {
            name = "speed",
            color = {0.2, 0.7, 1.0},
            glowColor = {0.3, 0.8, 1.0},
            duration = 5,
            effect = "speed_boost",
            rarity = 4,
            pulseSpeed = 8,
            symbol = "⚡"
        },
        {
            name = "shield",
            color = {0.9, 0.9, 0.2},
            glowColor = {1.0, 1.0, 0.3},
            duration = 8,
            effect = "invincible",
            rarity = 6,
            pulseSpeed = 6,
            symbol = "🛡️"
        },
        {
            name = "magnet",
            color = {1.0, 0.3, 0.3},
            glowColor = {1.0, 0.4, 0.4},
            duration = 10,
            effect = "attract_food",
            rarity = 5,
            pulseSpeed = 7,
            symbol = "🧲"
        }
    }

    return instance
end

function Food:update(dt)
    self.animationTime = self.animationTime + dt
    self.powerUpTimer = self.powerUpTimer + dt

    -- Update power-ups
    for i = #self.powerUps, 1, -1 do
        local powerUp = self.powerUps[i]
        if powerUp.duration then
            powerUp.duration = powerUp.duration - dt
            if powerUp.duration <= 0 then
                table_remove(self.powerUps, i)
            end
        else
            table_remove(self.powerUps, i)
        end
    end
end

function Food:spawnFood(gridWidth, gridHeight, snakeBody)
    local x = math_random(0, gridWidth - 1) * self.gridSize
    local y = math_random(0, gridHeight - 1) * self.gridSize

    -- Check if position is occupied by snake
    for _, segment in ipairs(snakeBody) do
        if segment.x == x and segment.y == y then
            return self:spawnFood(gridWidth, gridHeight, snakeBody)
        end
    end

    -- Choose food type based on rarity
    local totalRarity = 0
    for _, foodType in ipairs(self.foodTypes) do
        totalRarity = totalRarity + foodType.rarity
    end

    local roll = math_random(totalRarity)
    local current = 0
    local selectedType

    for _, foodType in ipairs(self.foodTypes) do
        current = current + foodType.rarity
        if roll <= current then
            selectedType = foodType
            break
        end
    end

    table_insert(self.items, {
        x = x,
        y = y,
        type = selectedType,
        spawnTime = self.animationTime,
        rotation = math_random() * math_pi * 2,
        rotationSpeed = math_random(-2, 2)
    })

    return selectedType
end

function Food:spawnPowerUp(gridWidth, gridHeight, snakeBody)
    if self.powerUpTimer >= self.powerUpSpawnInterval and math_random(10) > 7 then
        self.powerUpTimer = 0

        local x = math_random(0, gridWidth - 1) * self.gridSize
        local y = math_random(0, gridHeight - 1) * self.gridSize

        for _, segment in ipairs(snakeBody) do
            if segment.x == x and segment.y == y then
                return
            end
        end

        local totalRarity = 0
        for _, powerUpType in ipairs(self.powerUpTypes) do
            totalRarity = totalRarity + powerUpType.rarity
        end

        local roll = math_random(totalRarity)
        local current = 0
        local selectedType

        for _, powerUpType in ipairs(self.powerUpTypes) do
            current = current + powerUpType.rarity
            if roll <= current then
                selectedType = powerUpType
                break
            end
        end

        table_insert(self.powerUps, {
            x = x,
            y = y,
            type = selectedType,
            spawnTime = self.animationTime,
            duration = selectedType.duration,
            rotation = math_random() * math_pi * 2,
            rotationSpeed = math_random(-3, 3)
        })
    end
end

function Food:draw(offsetX, offsetY)
    -- Draw food items
    for _, food in ipairs(self.items) do
        local timeAlive = self.animationTime - food.spawnTime
        local pulse = (math_sin(timeAlive * food.type.pulseSpeed) + 1) * 0.3
        local hover = math_sin(timeAlive * 3) * 2
        local size = self.gridSize - 6
        food.rotation = food.rotation + food.rotationSpeed * 0.02

        -- Food glow
        lg.setColor(
            food.type.glowColor[1],
            food.type.glowColor[2],
            food.type.glowColor[3],
            0.4 + pulse * 0.3
        )
        lg.rectangle("fill",
            food.x + offsetX + 3 - 4,
            food.y + offsetY + 3 - 4 + hover,
            size + 8, size + 8, 6, 6
        )

        -- Main food body
        lg.setColor(
            food.type.color[1] + pulse * 0.2,
            food.type.color[2] + pulse * 0.2,
            food.type.color[3] + pulse * 0.2
        )

        lg.push()
        lg.translate(food.x + offsetX + self.gridSize / 2,
                               food.y + offsetY + self.gridSize / 2 + hover)
        lg.rotate(food.rotation)

        if food.type.name == "apple" then
            lg.rectangle("fill", -size/2, -size/2, size, size, 4, 4)
            -- Stem
            lg.setColor(0.4, 0.3, 0.1)
            lg.rectangle("fill", -2, -size/2 - 3, 4, 6)
        elseif food.type.name == "berry" then
            lg.circle("fill", 0, 0, size/2)
        elseif food.type.name == "golden" then
            lg.polygon("fill",
                0, -size/2,
                size/2, 0,
                0, size/2,
                -size/2, 0
            )
        else -- rainbow
            lg.circle("fill", 0, 0, size/2)
            lg.setColor(1, 1, 1, 0.8)
            lg.circle("line", 0, 0, size/2)
        end

        lg.pop()

        -- Inner shine
        lg.setColor(1, 1, 1, 0.6)
        lg.rectangle("line",
            food.x + offsetX + 5,
            food.y + offsetY + 5 + hover,
            size - 4, size - 4, 3, 3
        )
    end

    -- Draw power-ups
    for _, powerUp in ipairs(self.powerUps) do
        local timeAlive = self.animationTime - powerUp.spawnTime
        local pulse = (math_sin(timeAlive * powerUp.type.pulseSpeed) + 1) * 0.4
        local hover = math_sin(timeAlive * 4) * 3
        local size = self.gridSize - 8
        powerUp.rotation = powerUp.rotation + powerUp.rotationSpeed * 0.02

        -- Power-up outer glow
        lg.setColor(
            powerUp.type.glowColor[1],
            powerUp.type.glowColor[2],
            powerUp.type.glowColor[3],
            0.5 + pulse * 0.3
        )
        lg.circle("fill",
            powerUp.x + offsetX + self.gridSize / 2,
            powerUp.y + offsetY + self.gridSize / 2 + hover,
            size/2 + 4
        )

        -- Power-up main body
        lg.setColor(
            powerUp.type.color[1] + pulse * 0.2,
            powerUp.type.color[2] + pulse * 0.2,
            powerUp.type.color[3] + pulse * 0.2
        )

        lg.push()
        lg.translate(powerUp.x + offsetX + self.gridSize / 2,
                               powerUp.y + offsetY + self.gridSize / 2 + hover)
        lg.rotate(powerUp.rotation)

        -- Draw different shapes for different power-ups
        if powerUp.type.name == "speed" then
            -- Lightning bolt shape
            lg.polygon("fill",
                -size/4, -size/2,
                size/4, 0,
                -size/4, 0,
                size/4, size/2,
                -size/4, size/2,
                size/4, 0
            )
        elseif powerUp.type.name == "shield" then
            -- Shield shape
            lg.arc("fill", 0, 0, size/2, math_pi, 0)
            lg.rectangle("fill", -size/2, -2, size, 4)
        else -- magnet
            -- Magnet shape (two circles with gap)
            lg.circle("fill", -size/4, 0, size/3)
            lg.circle("fill", size/4, 0, size/3)
            lg.rectangle("fill", -size/4 - size/3, -size/6, size/1.5, size/3)
        end

        lg.pop()

        -- Pulsing outline
        lg.setColor(1, 1, 1, 0.8 + pulse * 0.2)
        lg.circle("line",
            powerUp.x + offsetX + self.gridSize / 2,
            powerUp.y + offsetY + self.gridSize / 2 + hover,
            size/2
        )
    end
end

function Food:checkCollision(x, y)
    -- Check food collision
    for i, food in ipairs(self.items) do
        if food.x == x and food.y == y then
            local foodType = food.type
            table_remove(self.items, i)
            return "food", foodType
        end
    end

    -- Check power-up collision
    for i, powerUp in ipairs(self.powerUps) do
        if powerUp.x == x and powerUp.y == y then
            local powerUpType = powerUp.type
            table_remove(self.powerUps, i)
            return "powerup", powerUpType
        end
    end

    return nil
end

function Food:clear()
    self.items = {}
    self.powerUps = {}
end

return Food