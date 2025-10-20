local math_random = math.random
local math_sin = math.sin
local table_insert = table.insert

local Food = {}
Food.__index = Food

function Food.new(gridSize)
    local instance = setmetatable({}, Food)

    instance.gridSize = gridSize
    instance.items = {}
    instance.powerUps = {}
    instance.animationTime = 0
    instance.powerUpTimer = 0          -- Add a timer to control spawn frequency
    instance.powerUpSpawnInterval = 10 -- Spawn attempt every 10 seconds

    -- Food types with different values and effects
    instance.foodTypes = {
        {
            name = "apple",
            color = { 0.9, 0.2, 0.2 },
            value = 10,
            growAmount = 1,
            rarity = 1
        },
        {
            name = "berry",
            color = { 0.8, 0.3, 0.8 },
            value = 20,
            growAmount = 1,
            rarity = 2
        },
        {
            name = "golden",
            color = { 1.0, 0.8, 0.2 },
            value = 50,
            growAmount = 2,
            rarity = 3
        },
        {
            name = "rainbow",
            color = { 0.3, 0.8, 0.9 },
            value = 100,
            growAmount = 3,
            rarity = 5
        }
    }

    -- Power-up types
    instance.powerUpTypes = {
        {
            name = "speed",
            color = { 0.2, 0.7, 1.0 },
            duration = 5,
            effect = "speed_boost",
            rarity = 4
        },
        {
            name = "shield",
            color = { 0.9, 0.9, 0.2 },
            duration = 8,
            effect = "invincible",
            rarity = 6
        },
        {
            name = "magnet",
            color = { 1.0, 0.3, 0.3 },
            duration = 10,
            effect = "attract_food",
            rarity = 5
        }
    }

    return instance
end

function Food:update(dt)
    self.animationTime = self.animationTime + dt
    self.powerUpTimer = self.powerUpTimer + dt -- Update the timer

    -- Update power-ups
    for i = #self.powerUps, 1, -1 do
        local powerUp = self.powerUps[i]
        if powerUp.duration then
            powerUp.duration = powerUp.duration - dt
            if powerUp.duration <= 0 then
                table.remove(self.powerUps, i)
            end
        else
            -- Remove power-ups without duration
            table.remove(self.powerUps, i)
        end
    end
end

function Food:spawnFood(gridWidth, gridHeight, snakeBody)
    local x = math_random(0, gridWidth - 1) * self.gridSize
    local y = math_random(0, gridHeight - 1) * self.gridSize

    -- Check if position is occupied by snake
    for _, segment in ipairs(snakeBody) do
        if segment.x == x and segment.y == y then
            return self:spawnFood(gridWidth, gridHeight, snakeBody) -- Try again
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
        spawnTime = self.animationTime
    })

    return selectedType
end

function Food:spawnPowerUp(gridWidth, gridHeight, snakeBody)
    -- Only attempt to spawn if timer has reached the interval
    -- AND there's a successful chance roll
    if self.powerUpTimer >= self.powerUpSpawnInterval and math_random(10) > 7 then -- 30% chance when timer is ready
        self.powerUpTimer = 0                                                      -- Reset timer

        local x = math_random(0, gridWidth - 1) * self.gridSize
        local y = math_random(0, gridHeight - 1) * self.gridSize

        -- Check if position is occupied by snake
        for _, segment in ipairs(snakeBody) do
            if segment.x == x and segment.y == y then
                return -- Don't try again, wait for next interval
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
            duration = selectedType.duration
        })
    end
end

function Food:draw(offsetX, offsetY)
    -- Draw food items
    for _, food in ipairs(self.items) do
        local pulse = (math_sin((self.animationTime - food.spawnTime) * 5) + 1) * 0.2
        local size = self.gridSize - 4

        love.graphics.setColor(
            food.type.color[1] + pulse,
            food.type.color[2] + pulse,
            food.type.color[3] + pulse
        )

        love.graphics.rectangle("fill",
            food.x + offsetX + 2,
            food.y + offsetY + 2,
            size, size, 4, 4
        )

        -- Inner glow
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line",
            food.x + offsetX + 3,
            food.y + offsetY + 3,
            size - 2, size - 2, 3, 3
        )
    end

    -- Draw power-ups
    for _, powerUp in ipairs(self.powerUps) do
        local pulse = (math_sin((self.animationTime - powerUp.spawnTime) * 8) + 1) * 0.3
        local size = self.gridSize - 6

        love.graphics.setColor(
            powerUp.type.color[1] + pulse,
            powerUp.type.color[2] + pulse,
            powerUp.type.color[3] + pulse
        )

        love.graphics.circle("fill",
            powerUp.x + offsetX + self.gridSize / 2,
            powerUp.y + offsetY + self.gridSize / 2,
            size / 2
        )

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line",
            powerUp.x + offsetX + self.gridSize / 2,
            powerUp.y + offsetY + self.gridSize / 2,
            size / 2
        )
    end
end

function Food:checkCollision(x, y)
    -- Check food collision
    for i, food in ipairs(self.items) do
        if food.x == x and food.y == y then
            local foodType = food.type
            table.remove(self.items, i)
            return "food", foodType
        end
    end

    -- Check power-up collision
    for i, powerUp in ipairs(self.powerUps) do
        if powerUp.x == x and powerUp.y == y then
            local powerUpType = powerUp.type
            table.remove(self.powerUps, i)
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
