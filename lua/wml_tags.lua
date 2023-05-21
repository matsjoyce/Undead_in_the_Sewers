function wesnoth.wml_actions.store_shroud(args)
    local team_num = args.side or wml.error("[store_shroud] expects a side= attribute")
    local storage = args.variable or wml.error("[store_shroud] expects a variable= attribute")
    local team = wesnoth.sides[team_num]
    local current_shroud = team.__cfg.shroud_data
    wesnoth.set_variable(storage,current_shroud)
end

function wesnoth.wml_actions.set_shroud(args)
    local team_num = args.side or wml.error("[set_shroud] expects a side= attribute")
    local shroud = args.shroud_data or wml.error("[set_shroud] expects a shroud_data= attribute")
    if shroud == nil then
        wml.error("[set_shroud] was passed a nil shroud string")
    elseif string.sub(shroud,1,1)~="|" then
        wml.error("[set_shroud] was passed an invalid shroud string")
    else
        local w,h,b=wesnoth.get_map_size()
        local shroud_x= (1-b)
        for r in string.gmatch(shroud,"|(%d*)") do
            local shroud_y=(1-b)
            for c in string.gmatch(r,"%d") do
                if c == "1" then
                    wml.fire("remove_shroud",{side=team_num,x=shroud_x,y=shroud_y})
                end
                shroud_y=shroud_y+1
            end
            shroud_x=shroud_x+1
        end
    end
end

function reflect(overlay, dir)
    if overlay == "Zmr-" then -- Facing south
        if dir == "n" then return "s"
        elseif dir == "nw" then return "sw"
        elseif dir == "ne" then return "se"
        end
    elseif overlay == "ZmR-" then -- Facing north
        if dir == "s" then return "n"
        elseif dir == "sw" then return "nw"
        elseif dir == "se" then return "ne"
        end
    elseif overlay == "Zmr/" then -- Facing south-east
        if dir == "nw" then return "s"
        elseif dir == "n" then return "se"
        end
    elseif overlay == "Zmr\\" then -- Facing south-west
        if dir == "ne" then return "s"
        elseif dir == "n" then return "sw"
        end
    elseif overlay == "ZmR/" then -- Facing north-west
        if dir == "s" then return "nw"
        elseif dir == "se" then return "n"
        end
    elseif overlay == "ZmR\\" then -- Facing north-east
        if dir == "s" then return "ne"
        elseif dir == "sw" then return "n"
        end
    end
    return dir
end

function opposite_direction(dir)
    if dir == "n" then return "s"
    elseif dir == "ne" then return "sw"
    elseif dir == "se" then return "nw"
    elseif dir == "s" then return "n"
    elseif dir == "sw" then return "ne"
    elseif dir == "nw" then return "se"
    end
    return dir
end

function raytrace(loc, dir, opacity, start_x, start_y, start_dir, do_damage)
    local loc, dir = {start_x, start_y}, start_dir

    repeat
        loc = wesnoth.map.get_direction(loc, dir)
        if not wesnoth.current.map:on_board(loc, true) then
            break
        end
        wesnoth.interface.remove_hex_overlay(loc, {redraw=false})
        wesnoth.interface.add_hex_overlay(loc, {image="scenery/ray-" .. opposite_direction(dir) .. ".png~O(" .. tostring(opacity) .. "%)", redraw=false})
        local hex = wesnoth.map.get(loc)
        dir = reflect(hex.overlay_terrain, dir)
        wesnoth.interface.add_hex_overlay(loc, {image="scenery/ray-" .. dir .. ".png~O(" .. tostring(opacity) .. "%)", redraw=false})
        if do_damage then
            wesnoth.wml_actions.harm_unit{{"filter", {x=loc[1], y=loc[2]}}, amount=40, fire_event=true, animate=true, damage_type="fire"}
        end
    until( loc[1] == start_x and loc[2] == start_y and dir == start_dir )
end

function wesnoth.wml_actions.raytrace(args)
    local start_x = args.start_x or wml.error("[raytrace] expects a start_x= attribute")
    local start_y = args.start_y or wml.error("[raytrace] expects a start_y= attribute")
    local start_dir = args.start_dir or wml.error("[raytrace] expects a start_dir= attribute")

    wesnoth.wml_actions.sound{name="laser-beam.wav"}

    raytrace({start_x, start_y}, start_dir, 100, start_x, start_y, start_dir, true)
    wesnoth.wml_actions.redraw{}
    wesnoth.wml_actions.delay{time=200}

    for op=100,0,-10 do
        raytrace({start_x, start_y}, start_dir, op, start_x, start_y, start_dir, false)
        wesnoth.wml_actions.redraw{}
        wesnoth.wml_actions.delay{time=100}
    end
end
