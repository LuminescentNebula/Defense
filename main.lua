local ui = require("ui")

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
    baseWidth = 1
    baseHeight = 1

    flags={resizable = true}
    -- window size
    love.window.setTitle("Tower Defense")
    width = cellSize*10+cellSize
    height = cellSize*10
    love.window.setMode( width, height, flags )
    -- Initialize the grid
    initializeGrid(gridSize)

    tokens = {
        base = love.graphics.newImage("res/base.png"),
        spawner = love.graphics.newImage("res/spawner.png"),
        turret = love.graphics.newImage("res/turret.png"),
        cursor = love.graphics.newImage("res/cursor.png"),
        cursor2 = love.graphics.newImage("res/cursor2.png"),
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

    -- Timer enemy spawning
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
        function(x, y, r, g, b, a) return r, 1, b, a end,
        function(x, y, r, g, b, a) return r, g, 1, a end,
        function(x, y, r, g, b, a) return 1, 1, b, a end,
        function(x, y, r, g, b, a) return r, 1, 1, a end
    }
    cursors ={}
    for i = 1, #imagedatas do
        cursorData = love.image.newImageData("res/cursor.png")
        image = love.graphics.newImage(cursorData)
        cursorData:mapPixel(imagedatas[i])
        image:replacePixels(cursorData)
        table.insert(cursors,image)
    end

    keys = {
        {"w","s","a","d","q"},
        {"u","j","h","k","y"},
        {"up","down","left","right","/"},
        {"kp8","kp5","kp4","kp6","kp7"}
    }
    players = {}
    --createPlayers(3)

    count =0
end

function resizeCanvas()
    if #players <=3 then
        return love.graphics.newCanvas(math.floor(width/#players), math.floor(height))
    else 
        return love.graphics.newCanvas(math.floor(width/2), math.floor(height/2))
    end
end

function createPlayers(n)
    for i=1,n do
        table.insert(players,
        {n = i,
        finish = false,
        nextUnit = "turret",
        units = {},
        bases = baseHeight*baseWidth,
        attacks = {},
        gold = 100,
        keys = keys[i],
        stats = {
          kills = 0,
          time = 0  
        },
        canvas = nil})
        local x = (i>2 and gridSize-5 or 5) 
        local y = (math.mod(i,2)==1 and gridSize-5 or 5) 
        placeBaseAndCursor(players[i], x, y )
    end
    remain = #players
    love.resize(width,height)
end

-- Initialize the grid with empty cells
function initializeGrid(gridSize)
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
       players[i].canvas = resizeCanvas()
    end
end

function placeBaseAndCursor(player, row, col)
    for r = row, row + baseHeight - 1 do
        for c = col, col + baseWidth - 1 do
            local unit = {n = player.n, type="base", row = r, col = c, hp = 50, maxHP = 50, 
                            upgraded = false, cooldown = 0, maxCooldown = 1, radius = 7, power = 1, attackable = true, one=true}
            grid[r][c].type = unit
            table.insert(player.units, unit)
        end
    end   
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
            table.insert(enemies, {row = spawner.row, col = spawner.col, moveTimer = 0, moveCooldown = (1/increaser)*2.5,
                        hp=math.floor(5*(increaser-2)), maxHP = math.floor(5*(increaser-2)), 
                        power=math.floor(1*increaser-2), award = math.floor(5*(increaser-2))})
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
        unit = {n=n, type = "bomb", row = x, col = y, radius = 2, power=10, hp=1, maxHP=1, upgraded = false, attackable = false, one = false}
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
        spawnEnemy()
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
            increaser=increaser+0.3
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
                                        players[k].stats.kills = players[k].stats.kills + 1
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
    --FIx radius
    for j = 1, #enemies do
        local enemy = enemies[j]

        local distance = math.abs(enemy.row - bomb.row) +
                        math.abs(enemy.col - bomb.col)

        if distance <= bomb.radius then
            enemies[j].hp = enemies[j].hp-bomb.power
            if enemies[j].hp <= 0 then
                if removable[tostring(j)] == nil then
                    players[bomb.n].gold = players[bomb.n].gold + enemies[j].award
                    players[bomb.n].stats.kills = players[bomb.n].stats.kills + 1

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
                --print(players[j].units[i].type.." removed")
                if players[j].units[i].type == "base" then
                    players[j].bases = players[j].bases-1
                    if players[j].bases == 0 then
                        players[j].finish = true
                        remain = remain - 1
                        if remain == 1 then
                            ui.visible = true
                            ui.menu = false
                            for g = #players,1,-1 do
                                if players[g].finish == false then
                                    ui.winner = colors[g]
                                    break
                                end
                            end
                            break
                        end
                    end
                end
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
    if not ui.visible then
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

        for i = #players, 1, -1 do
            if not players[i].finish then
                players[i].stats.time = players[i].stats.time + dt
            end
        end

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
        --TODO: не давать upgrade если все апгрейднуто
    oldUnit = player.nextUnit
    while oldUnit == player.nextUnit do
        player.nextUnit=unitsVariants[math.random(#unitsVariants)]
    end
end

function useCursor(player,cursor,key)
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
                elseif player.nextUnit == "bomb" then
                    grid[row][col].type.power = grid[row][col].type.power*2
                    grid[row][col].type.radius = math.floor(grid[row][col].type.radius*1.5)
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

function love.keypressed(key)
    print(key)
    ui:handleInput(key)
    
    for i=1,#players do 
        moveCursor(players[i], players[i].cursor, key)
        useCursor(players[i], players[i].cursor, key)
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
                    if grid[row][col].type.type == "base" then
                        love.graphics.push()
                        love.graphics.setColor(0,0,0,0.7)
                        love.graphics.print(players[grid[row][col].type.n].gold,x,y)
                        love.graphics.pop()
                    end
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
    love.graphics.draw(cursors[player.n], x, y, 0, 1, 1)
    love.graphics.draw(tokens.cursor2, x, y, 0, 1, 1)

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.draw(tokens[player.nextUnit], x, y)
end

function drawlayout()
    love.graphics.setBlendMode("alpha", "premultiplied")
    if #players <=3 then
        for i = 1, #players do
            love.graphics.setColor(1,1,1, 1)
            love.graphics.draw(players[i].canvas, width*(i-1)/#players, 0)

            love.graphics.setColor(0,0,0,1)
            love.graphics.setLineWidth( 5 )
            love.graphics.line(width*(i-1)/#players,0,width*(i-1)/#players,height)
        end
    else 
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, #players do
            if i > 2 then
                love.graphics.draw(players[i].canvas, 
                (width/2),
                (height/2)*math.mod((i+1),2))
            else 
                love.graphics.draw(players[i].canvas, 
                0,
                (height/2)*math.mod((i+1),2))
            end
        end
        love.graphics.setColor(0,0,0,1)
        love.graphics.setLineWidth( 5 )
        love.graphics.line(0,height/2,width,height/2)
        love.graphics.line(width/2,0,width/2,height)
    end
    love.graphics.setBlendMode("alpha")

end

function love.draw()
    if not ui.visible then
        for i = 1, #players do
            love.graphics.setCanvas(players[i].canvas)
            love.graphics.clear(0, 0, 0, 0)
            love.graphics.push()
            if #players <=3 then
                love.graphics.translate(
                    -math.floor(players[i].cursor.col*cellSize-width/(2*#players)), 
                    -math.floor(players[i].cursor.row*cellSize-height/2)
                )
            else 
                love.graphics.translate(
                    -math.floor(players[i].cursor.col*cellSize-width/4), 
                    -math.floor(players[i].cursor.row*cellSize-height/4)
            )
            end

            if (players[i].finish == true) then 
                love.graphics.setColor(1,1,1,1)
                love.graphics.print("Kills: "..players[i].stats.kills.."\nTime: "..players[i].stats.time,
                    players[i].cursor.col*cellSize,players[i].cursor.row*cellSize,0,1,1,
                    0.5,0.5)
            else 
                drawGrid()

                for j = 1, #players,1 do
                    drawCursors(players[j])
                    drawHP(players[j])
                    drawAttacks(players[j])
                end
            end
            love.graphics.pop()
        end
        love.graphics.setCanvas()

        drawlayout()
    else 
        ui:draw()
    end
end