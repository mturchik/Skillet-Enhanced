--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

SkilletUtil = {}

function SkilletUtil.SquishLink(link)
    local color, id, name = link:match("^|cff(......)|Hitem:(%d+):[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+|h%[([^%]]+)%]|h|r$")
    if id then
        return color.."|"..id.."|"..name
    else
        id, name = link:match("^|cffffd000|Henchant:(%d+)|h%[([^%]]+)%]|h|r$")
        return "|-"..id.."|"..name
    end
end

function SkilletUtil.UnsquishLink(link)
    local color, id, name = link:match("^([^|].....)|(%d+)|(.+)$")
    if id then
        return "|cff"..color.."|Hitem:"..id..":0:0:0:0:0:0:0:0|h["..name.."]|h|r", false
    else
        id, name = link:match("^|%-(%d+)|(.+)$")
        if id then
            return "|cffffd000|Henchant:"..id.."|h["..name.."]|h|r", true
        else
            return link
        end
    end
end

function SkilletUtil.GetItemIDFromLink(link)
    local id
    if link then
        _, _, id = string.find(link, "|Hitem:(%d+):")
    end

    if link and not id then
        _, _, id = string.find(link, "|Henchant:(%d+)|")
    end

    if id then id = tonumber(id) end

    return id
end

function SkilletUtil.UpdateQueuedList(list, player, name, link, needed)
    for i = 1, #list, 1 do
        if list[i]["name"] == name then
            list[i]["count"] = list[i]["count"] + needed
            if list[i].player and not string.find(list[i].player, player) then
                list[i].player = list[i].player .. ", " .. player
            end
            return
        end
    end

    table.insert(list, {
        ["name"]  = name,
        ["link"]  = link,
        ["count"] = needed,
        ["player"] = player,
    })
end

function SkilletUtil.RecipeMatchesFilter(recipe, filtertext, maxReagents)
    maxReagents = maxReagents or 8
    if not filtertext or filtertext == "" then
        return true
    end

    local filter = string.lower(filtertext)
    local name = string.lower(recipe.name)
    if string.find(name, filter, 1, true) ~= nil then
        return true
    end

    for i = 1, maxReagents, 1 do
        if recipe[i] then
            name = string.lower(recipe[i].name)
            if string.find(name, filter, 1, true) ~= nil then
                return true
            end
        end
    end

    return false
end

function SkilletUtil.CompareRecipeByName(left_r, right_r)
    if not left_r and right_r then
        return false
    elseif not right_r and left_r then
        return true
    elseif not left_r and not right_r then
        return true
    end

    return left_r.name < right_r.name
end

function SkilletUtil.MapSortedRecipeIndex(index, sorted_recipes, sort_desc)
    if not sorted_recipes or #sorted_recipes == 0 then
        return index
    end

    local lookup = index
    if not sort_desc then
        lookup = #sorted_recipes + 1 - index
    end

    return sorted_recipes[lookup]
end
