local ui = {
    visible = true,
    selected = 1,
    options = {"1 Player", "2 Players", "3 Players", "4 Players"}
}

function ui:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", 0,0,width,height)
    love.graphics.setColor(0, 0, 0)
    for i, option in ipairs(ui.options) do
        if i == ui.selected then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.print(option, width / 2 - 50, height / 2 - 25 + (i - 1) * 25)
    end
end

function ui:handleInput(key)
    if key == "up" then
        ui.selected = math.max(1, ui.selected - 1)
    elseif key == "down" then
        ui.selected = math.min(#ui.options, ui.selected + 1)
    elseif key == "return" then
        -- Set the number of players based on the selected option
        players = {}
        createPlayers(ui.selected)
        ui.visible = false
    end
end

return ui