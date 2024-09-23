function love.load()
    -- Grid size and cell dimensions
    gridSize = 20
    
    defaultCellSize = 50
    cellSize = 50
    
    defaultSpawnInterval = 5 -- Spawn enemies every 5 seconds
    spawnInterval = 5
    increaser = 3
    increaserInterval = 5
    goldInterval = 2
    -- Base dimensions (2 cells wide)
    baseWidth = 2
    baseHeight = 2

    flags={resizable = true}
    -- window size
    love.window.setTitle("Tower Defense")
    width = cellSize*10+cellSize
    height = cellSize*10
    love.window.setMode( width, height, flags )
    -- Initialize the grid
    initializeGrid()

    tokens = {
        base = love.graphics.newImage("res/base.png"),
        spawner = love.graphics.newImage("res/spawner.png"),
        turret = love.graphics.newImage("res/turret.png"),
        cursor = love.graphics.newImage("res/cursor.png"),
        boss = love.graphics.newImage("res/boss.png"),
        enemy = love.graphics.newImage("res/enemy.png"),
        bomb = love.graphics.newImage("res/bomb.png"),
        wall = love.graphics.newImage("res/wall.png"),
        tesla = love.graphics.newImage("res/tesla.png"),
        upgrade = love.graphics.newImage("res/upgrade.png"),
        heal = love.graphics.newImage("res/heal.png")
    }
    love.window.setIcon(love.image.newImageData("res/base.png"))

    unitsVariants = {"turret","bomb","wall","upgrade","tesla","heal"}
    math.randomseed(os.time())
    -- Enemy list
    enemies = {}

    -- Timer for enemy spawning
    spawnTimer = 0
    goldTimer = 0
    increaserTimer = 0

    spawners = {}
    placeSpawner(gridSize, 1)
    placeSpawner(1,gridSize)
    placeSpawner(1, 1)
    placeSpawner(gridSize,gridSize)

    colors = {
        {0,1,0},
        {0,0,1},
        {1,1,0},
        {0,1,1}
    }
    imagedatas = {
        mapPixel(function(x, y, r, g, b, a) return r, 1, b, a end),
        mapPixel(function(x, y, r, g, b, a) return r, g, 1, a end),
        mapPixel(function(x, y, r, g, b, a) return 1, 1, b, a end),
        mapPixel(function(x, y, r, g, b, a) return r, 1, 1, a end)
    }
    keys = {
        {"up","down","left","right","/"},
        {"kp8","kp5","kp4","kp6","kp7"}
    }
    players = {}
    createPlayers(2)

    count =0
end

function createPlayers(n)
    for i=1,n do
        table.insert(players,
        {n = i,
        nextUnit = "turret",
        units = {},
        attacks = {},
        gold = 100,
        keys = keys[i],
        canvas = love.graphics.newCanvas(math.floor(width/n), math.floor(height/n))})
        placeBase(i,math.floor((gridSize/2)/n), math.floor((gridSize/2)/n))
        placeCursor(players[i], math.floor((gridSize/2)/n), math.floor((gridSize/2)/n))
    end
end

-- Initialize the grid with empty cells
function initializeGrid()
    grid = {}
    for row = 1, gridSize do
        grid[row] = {}
        for col = 1, gridSize do
            grid[row][col] = {
                type = nil,
             enemy = nil,
            cursor = false}
        end
    end
end

function love.resize(x,y)
    width = x
    height = y
    for i = 1, #players do
       players[i].canvas = love.graphics.newCanvas(math.floor(width/#players), math.floor(height/#players))
    end
end

function placeBase(n, row, col)
    for r = row, row + baseHeight - 1 do
        for c = col, col + baseWidth - 1 do
            print(r.." "..c)
            local unit = {n = n, type="base", row = r, col = c, hp = 50, maxHP = 50, 
                            upgraded = false, cooldown = 0, maxCooldown = 1, radius = 7, power = 1, attackable = true, one=true}
            grid[r][c].type = unit
            table.insert(players[n].units, unit)
        end
    end    
end

function placeCursor(player, row,col)
    player.cursor = {n=n,row = row, col = col}
    grid[row][col].cursor=true
end

-- Place the spawner in the grid
function placeSpawner(row, col)
    local spawner = {type= "spawner", row = row, col = col}
    grid[row][col].type = spawner
    table.insert(spawners,spawner)

end

-- Spawn an enemy at the spawner location
function spawnEnemy()
    for i = #spawners, 1, -1 do
        local spawner = spawners[i] 
        if grid[spawner.row][spawner.col].enemy == nil then
            table.insert(enemies, {row = spawner.row, col = spawner.col, moveTimer = 0, moveCooldown = 1/(increaser/2.5),
                        hp=math.floor(5*(increaser-2)), maxHP = math.floor(5*(increaser-2)), power=1*increaser-2, award = math.floor(5*(increaser-3))})
            
            count = count + 1
            print("Enemies: "..count.." Alive: "..#enemies)
            grid[spawner.row][spawner.col].enemy = true
        end
    end
end

function removeEnemy(index)
    grid[enemies[index].row][enemies[index].col].enemy = nil
    table.remove(enemies, index)
end

function spawnUnit(n,x,y)
    local unit = nil
    if players[n].nextUnit == "turret" then
        unit = {n=n, type = "turret", row = x, col = y, cooldown = 0, maxCooldown = 1, power=1, hp=10, maxHP=10, upgraded = false, radius = 5, attackable = true, one = true}
    elseif players[n].nextUnit == "bomb" then
        unit = {n=n, type = "bomb", row = x, col = y, radius = 5, power=10, hp=1, maxHP=1, upgraded = false, attackable = false, one = false}
    elseif players[n].nextUnit == "wall" then
        unit = {n=n, type = "wall", row = x, col = y, hp=30, maxHP=30, upgraded = false, attackable = false,}
    elseif players[n].nextUnit == "tesla" then
        unit = {n=n, type = "tesla", row = x, col = y,cooldown = 0, maxCooldown = 3, power=2, hp=10, maxHP=10, upgraded = false, radius = 5, attackable = true, one=false}
    end
    if unit ~= nil then
        table.insert(players[n].units, unit)
        grid[x][y].type = unit
    end
    return unit
end

function updateTimers(dt)
    -- Update the spawn timer
    spawnTimer = spawnTimer + dt

    -- Spawn an enemy every 5 seconds
    if spawnTimer >= spawnInterval then
        --spawnEnemy()
        spawnTimer = 0
    end

    goldTimer = goldTimer + dt

    if goldTimer >= goldInterval then
        for i=1,#players do
            players[i].gold = players[i].gold +1
        end
        goldTimer = 0
    end

    increaserTimer = increaserTimer + dt
    if increaserTimer >= increaserInterval then
        increaserTimer = 0
        if increaser < 10  then
            increaser=increaser+0.1
            spawnInterval = defaultSpawnInterval/increaser
            --print(increaser)
        end
    end
end

function moveCursor(player,cursor,key)
    local row = cursor.row
    local col = cursor.col
    if key == player.keys[1] and cursor.row > 1 then
        row = cursor.row - 1
    elseif key == player.keys[2] and cursor.row < gridSize then
        row = cursor.row + 1
    elseif key == player.keys[3] and cursor.col > 1 then
        col = cursor.col - 1
    elseif key == player.keys[4] and cursor.col < gridSize then
        col = cursor.col + 1
    end
    if grid[row][col].cursor == false then
        grid[cursor.row][cursor.col].cursor=false
        cursor.row=row
        cursor.col=col
        grid[row][col].cursor=true
    end
end

function attack(dt)
    for k = 1, #players do
        local attacks = players[k].attacks 
        for i = #players[k].units, 1, -1 do
            if players[k].units[i].attackable==true then
                local unit = players[k].units[i]
                if unit.cooldown <= 0 then
                    unit.cooldown = unit.maxCooldown
                -- Loop through enemies
                    for j = 1, #enemies do
                        local enemy = enemies[j]
                
                        -- Calculate Manhattan distance between unit and enemy
                        local distance = math.abs(unit.row - enemy.row) +
                                        math.abs(unit.col - enemy.col)
                
                        -- Check if the enemy is within the attack radius
                        if distance <= unit.radius then
                            if enemy.hp > 0 then
                                enemy.hp = enemy.hp-unit.power
                                if enemy.hp <= 0 then
                                    if removable[tostring(j)] == nil then
                                        players[k].gold = players[k].gold + enemy.award
                                        removable[tostring(j)]=j
                                    end
                                end
                                table.insert(attacks, {type=unit.type,
                                    startX = (unit.col - 1) * cellSize + cellSize / 2,
                                    startY = (unit.row - 1) * cellSize + cellSize / 2,
                                    endX = (enemy.col - 1) * cellSize + cellSize / 2,
                                    endY = (enemy.row - 1) * cellSize + cellSize / 2
                                })
                                if unit.one then
                                    break
                                end
                            end
                        end
                    end
                else
                    unit.cooldown = unit.cooldown-dt
                end
            end
        end
    end
end

function attackBomb(bomb) --TODO add damage to structures
    for j = 1, #enemies do
        local enemy = enemies[j]

        local distance = math.abs(bomb.row - bomb.row) +
                        math.abs(bomb.col - bomb.col)

        if distance <= bomb.radius then
            enemies[j].hp = enemies[j].hp-bomb.power
            if enemies[j].hp <= 0 then
                if removable[tostring(j)] == nil then
                    players[bomb.n].gold = players[bomb.n].gold + enemies[j].award
                    removable[tostring(j)] = j
                end
            end
            table.insert(players[bomb.n].attacks, {type="bomb",
                startX = (bomb.col - 1) * cellSize + cellSize / 2,
                startY = (bomb.row - 1) * cellSize + cellSize / 2,
                endX = (enemy.col - 1) * cellSize + cellSize / 2,
                endY = (enemy.row - 1) * cellSize + cellSize / 2
            })
        end
    end
end

function removeUnit(row,col)
    for j = #players,1,-1 do
        for i = #players[j].units, 1, -1 do
            if row == players[j].units[i].row and col == players[j].units[i].col then
                print(players[j].units[i].type.." removed")
                table.remove(players[j].units, i)
                grid[row][col].type = nil
                break
            end
        end
    end
end

function removeEnemiesOnUnits(enemy)
    -- Remove enemy if it reaches the base
    if grid[enemy.row][enemy.col].type ~= nil and grid[enemy.row][enemy.col].type.type ~= "spawner" then
        local unit = grid[enemy.row][enemy.col].type
        if grid[enemy.row][enemy.col].type.type =='bomb' then
            unit.hp = unit.hp-enemy.power
            if unit.hp <= 0 then 
                attackBomb(unit)
                removeUnit(enemy.row,enemy.col)
            end
        else
            unit.hp = unit.hp-enemy.power
            if unit.hp <= 0 then 
                removeUnit(enemy.row,enemy.col)
            end
        end
        return true
    end
    return false
end

function love.update(dt)
    updateTimers(dt)
    removable = {}

    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        updateEnemyMovement(enemy, dt)
        
        if removeEnemiesOnUnits(enemy) then
            removable[tostring(i)]=i
        end
    end

    attack(dt)
    ordered = {}
    for k, v in pairs(removable) do
        table.insert(ordered,v)
    end
    table.sort(ordered)
    for i = #ordered,1,-1 do 
        removeEnemy(ordered[i])
    end
end


function findClosestUnit(enemy)
    minDist = gridSize*2
    minUnit = nil
    for j = #players,1,-1 do
        local units = players[j].units 
        for i = #units, 1, -1 do
            local unit = units[i]
            if unit.type ~= "bomb" then
                local distance = math.abs(unit.row - enemy.row) +
                                math.abs(unit.col - enemy.col)

                if distance<minDist then 
                    minDist = distance
                    minUnit = unit
                end
            end
        end
    end
    return minUnit
end


function moveUpDown(rowDiff,enemy)
    if rowDiff > 0 then
        return enemy.row + 1 -- Move down
    elseif rowDiff < 0 then
        return enemy.row - 1 -- Move up
    end
end

function moveLeftRight(colDiff,enemy)
    if colDiff > 0 then
        return enemy.col + 1 -- Move right
    elseif colDiff < 0 then
        return enemy.col - 1 -- Move left
    end
end

-- Function to update enemy movement towards the base, moving cell by cell
function updateEnemyMovement(enemy, dt)
    enemy.moveTimer = enemy.moveTimer + dt

    -- Check if enough time has passed to move one cell
    if enemy.moveTimer >= enemy.moveCooldown then
        enemy.moveTimer = 0 -- Reset the move timer

        local base = findClosestUnit(enemy)
        if base ~= nil then
            -- Determine direction to move (towards the base)
            local rowDiff = base.row - enemy.row
            local colDiff = base.col - enemy.col

            local row = enemy.row
            local col = enemy.col

            if rowDiff ~= 0 and colDiff ~=0 then
                if math.random(2) == 1 then
                    row = moveUpDown(rowDiff,enemy)
                else 
                    col = moveLeftRight(colDiff,enemy)
                end
            elseif rowDiff~=0 then
                row = moveUpDown(rowDiff,enemy)
            elseif colDiff~=0 then
                col = moveLeftRight(colDiff,enemy)
            end

            if grid[row][col].enemy == nil then
                grid[enemy.row][enemy.col].enemy = nil -- Clear the old cell
                enemy.row = row
                enemy.col = col
                grid[enemy.row][enemy.col].enemy = true -- Mark the new cell with an enemy
            end
        end
    end
end

function selectNextUnit(player)
    oldUnit = player.nextUnit
    while oldUnit == player.nextUnit do
        player.nextUnit=unitsVariants[math.random(#unitsVariants)]
    end
end

function love.keypressed(key)
    for i=1,#players do 
        local player = players[i]
        local cursor = player.cursor

        moveCursor(player, cursor, key)
        --TODO: не давать upgrade если все апгрейднуто, не давать 2 одиаковых
        if key == player.keys[5] and grid[cursor.row][cursor.col].enemy == nil then 
            local row = cursor.row
            local col = cursor.col
            if player.nextUnit ~= "upgrade" and player.nextUnit ~= "heal" then
                if  grid[row][col].type == nil then
                    if  player.nextUnit == "bomb" or --Bomb can be placed anywhere
                        (grid[row+1] ~= nil and grid[row+1][col] ~= nil and grid[row+1][col].type ~= nil and grid[row+1][col].type.n == player.n) or --Has unit on one of the sides
                        (grid[row-1] ~= nil and grid[row-1][col] ~= nil and grid[row-1][col].type ~= nil and grid[row-1][col].type.n == player.n) or
                        (grid[row][col+1] ~= nil and grid[row][col+1].type ~= nil and grid[row][col+1].type.n == player.n) or
                        (grid[row][col-1] ~= nil and grid[row][col-1].type ~= nil and grid[row][col-1].type.n == player.n) then
                        if player.gold >= 20 then
                            if spawnUnit(player.n,row,col) ~= nil then
                                player.gold = player.gold - 20
                                selectNextUnit(player)
                            end
                        end
                    end
                end
            elseif grid[row][col].type ~= nil and grid[row][col].type.n == player.n then
                if  player.nextUnit == "upgrade" and grid[row][col].type.upgraded == false then
                    if grid[row][col].type.type == "wall"  or grid[row][col].type.type == "base"  then
                        grid[row][col].type.hp = grid[row][col].type.maxHP*2
                        grid[row][col].type.maxHP = grid[row][col].type.maxHP*2
                    else
                        grid[row][col].type.power = grid[row][col].type.power*2
                    end
                    grid[row][col].type.upgraded = true
                    selectNextUnit(player)
                elseif player.nextUnit == "heal" then
                    grid[row][col].type.hp = grid[row][col].type.maxHP
                    selectNextUnit(player)
                end
            end
        end
    end
end


function drawHP(player)
    local units = player.units
    for i = 1, #units,1 do
        local unit = units[i]
        if unit ~= nil then
            if unit.hp <= 0 then
                removeUnit(unit.row,unit.col)
            end     
            if unit.hp ~= unit.maxHP then
                love.graphics.setColor(0, 0, 0) 
                love.graphics.rectangle("fill",
                    (unit.col-1)*cellSize+cellSize*0.1-1.5,
                    unit.row*cellSize-cellSize*0.2-1.6,
                    cellSize*0.8+3,
                    cellSize*0.1+3)
                love.graphics.setColor(1, 0, 0) 
                love.graphics.rectangle("fill",
                    (unit.col-1)*cellSize+cellSize*0.1,
                    unit.row*cellSize-cellSize*0.2,
                    cellSize*(unit.hp/unit.maxHP)*0.8,
                    cellSize*0.1)
            end
        end
    end
end

function drawAttacks(player)
    for i = 1, #player.attacks do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setLineWidth( 5 )
        love.graphics.line(player.attacks[i].startX, player.attacks[i].startY, player.attacks[i].endX, player.attacks[i].endY)
    end
    player.attacks={}
end

function drawGrid()
    for row = 1, gridSize do
        for col = 1, gridSize do
            local x = (col - 1) * cellSize
            local y = (row - 1) * cellSize
            love.graphics.setLineWidth( 1 )

            -- Draw the grid cell
            love.graphics.setColor(1, 1, 1) -- White for the cell
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)

            -- Draw the cell border
            love.graphics.setColor(0, 0, 0) -- Black border
            love.graphics.rectangle("line", x, y, cellSize, cellSize)
            if grid[row][col].type ~= nil then
                -- Draw the spawner if the cell contains the spawner
                if grid[row][col].type.type == 'spawner' then
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.rectangle("fill", x, y, cellSize, cellSize)
                    love.graphics.draw(tokens.spawner, x, y)
                else 
                    love.graphics.setColor(colors[grid[row][col].type.n])
                    love.graphics.rectangle("fill", x, y, cellSize, cellSize)
                    love.graphics.draw(tokens[grid[row][col].type.type], x, y)
                    if grid[row][col].type.upgraded == true then
                        love.graphics.draw(tokens.upgrade, x, y, 0, 0.2,0.2)
                    end
                end
            end

            -- Draw an enemy if the cell contains an enemy
            if grid[row][col].enemy then
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle("fill", x + cellSize / 2, y + cellSize / 2, 25)
                love.graphics.draw(tokens.enemy, x, y)
            end
        end
    end
end

function drawCursors(player)
    local x = (player.cursor.col - 1) * cellSize
    local y = (player.cursor.row - 1) * cellSize

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(tokens.cursor, x, y, 0,1, 1)
    love.graphics.setColor(colors[player.n])
    love.graphics.draw(tokens.cursor, x+5, y+5,0, 0.9, 0.9)

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.draw(tokens[player.nextUnit], x, y)
end

function drawUI()
    --love.graphics.setColor(1, 1, 1) -- White for the text
    --love.graphics.print(tostring(gold), gridSize*cellSize+2,25)
end

function love.draw()
    for i = 1, #players do
        love.graphics.setCanvas(players[i].canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.push()
        love.graphics.translate(--TODO
            -math.floor(players[i].cursor.col*cellSize-width/2), 
            -math.floor(players[i].cursor.row*cellSize-height/2))

        drawGrid()

        for j = 1, #players,1 do
            drawCursors(players[j])
            drawHP(players[j])
            drawAttacks(players[j])
        end

        love.graphics.pop()
    end
    love.graphics.setCanvas()

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1,1,1, 1)
    for i = 1, #players do
        love.graphics.draw(players[i].canvas, width*(i-1)/#players, 0)
    end
    love.graphics.setBlendMode("alpha")

end
