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
