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

local RED <const>, GREEN <const>, BLUE <const> = 1, 2, 4

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

function get_rays(trace, x, y)
    return trace[x * 10000 + y]
end

function add_ray(trace, x, y, dir, color)
    if trace[x * 10000 + y] == nil then
        trace[x * 10000 + y] = {n=0, ne=0, nw=0, s=0, se=0, sw=0}
    end
    trace[x * 10000 + y][dir] = trace[x * 10000 + y][dir] + color;
end

function all_hexes_in_trace(trace)
    local key = nil
    return function ()
        local new_key, item = next(trace, key)
        if item == nil then return end
        key = new_key
        y = key % 10000
        x = (key - y) / 10000
        return x, y, item
    end
end

function raytrace(start_x, start_y, start_dir, color)
    local loc, dir = {start_x, start_y}, start_dir
    local trace = {}

    repeat
        loc = wesnoth.map.get_direction(loc, dir)
        if not wesnoth.current.map:on_board(loc, true) then
            break
        end
        add_ray(trace, loc[1], loc[2], opposite_direction(dir), color)
        local hex = wesnoth.map.get(loc)
        dir = reflect(hex.overlay_terrain, dir)
        add_ray(trace, loc[1], loc[2], dir, color)
    until( loc[1] == start_x and loc[2] == start_y and dir == start_dir )

    return trace
end

function draw_raytrace(trace, opacity)
    for x, y, rays in all_hexes_in_trace(trace) do
        wesnoth.interface.remove_hex_overlay({x, y}, {redraw=false})
        for dir, colors in pairs(rays) do
            if colors ~= 0 then
                print(colors)
                wesnoth.interface.add_hex_overlay(
                    {x, y},
                    {
                        image="scenery/ray-"
                        .. dir
                        .. ".png~O("
                        .. tostring(opacity)
                        .. "%)~CS("
                        .. ((colors & RED ~= 0) and "0," or "-255,")
                        .. ((colors & GREEN ~= 0) and "0," or "-255,")
                        .. ((colors & BLUE ~= 0) and "0)" or "-255)"),
                        redraw=false
                    }
                )
            end
        end
    end
    wesnoth.wml_actions.redraw{}
end

function damage_raytrace(trace)
    for x, y, rays in all_hexes_in_trace(trace) do
        wesnoth.wml_actions.harm_unit{{"filter", {x=x, y=y}}, amount=40, fire_event=true, animate=true, damage_type="fire"}
    end
end

function wesnoth.wml_actions.raytrace(args)
    local start_x = args.start_x or wml.error("[raytrace] expects a start_x= attribute")
    local start_y = args.start_y or wml.error("[raytrace] expects a start_y= attribute")
    local start_dir = args.start_dir or wml.error("[raytrace] expects a start_dir= attribute")
    local color_list = args.colors or wml.error("[raytrace] expects a colors= attribute")
    local colors = 0
    for _, color in ipairs(color_list:lower():split()) do
        if color == "red" then colors = colors | RED
        elseif color == "green" then colors = colors | GREEN
        elseif color == "blue" then colors = colors | BLUE
        end
    end

    local trace = raytrace(start_x, start_y, start_dir, colors)

    wesnoth.wml_actions.sound{name="laser-beam.wav"}
    draw_raytrace(trace, 100)
    damage_raytrace(trace)
    wesnoth.wml_actions.delay{time=200}

    for op=100,0,-10 do
        draw_raytrace(trace, op)
        wesnoth.wml_actions.delay{time=100}
    end
end
