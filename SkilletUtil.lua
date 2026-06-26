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

-- Extracts the crafted item/enchant id from a squished Stitch cache string.
function SkilletUtil.GetRecipeResultIdFromCacheString(cached_string)
    if not cached_string then
        return nil
    end

    local squished_link = cached_string:match("^[^;]*;([^;]+);")
    if not squished_link or squished_link == "" then
        return nil
    end

    local full_link = SkilletUtil.UnsquishLink(squished_link)
    return SkilletUtil.GetItemIDFromLink(full_link)
end

-- True when cached recipe data does not match the live tradeskill result link at this index.
function SkilletUtil.IsCachedRecipeStringStale(cached_string, live_item_link)
    if not cached_string then
        return true
    end
    if not live_item_link then
        return false
    end

    local cached_id = SkilletUtil.GetRecipeResultIdFromCacheString(cached_string)
    local live_id = SkilletUtil.GetItemIDFromLink(live_item_link)
    if not cached_id or not live_id then
        return cached_id ~= live_id
    end

    return cached_id ~= live_id
end

local function is_recipe_index_stale(i, cached, live_item_links_at)
    if not cached or not cached[i] then
        return true
    end
    if live_item_links_at and SkilletUtil.IsCachedRecipeStringStale(cached[i], live_item_links_at[i]) then
        return true
    end
    return false
end

-- Returns the first non-header Blizzard index missing or mismatched cached data, or nil if complete.
local function find_first_stale_recipe_index(blizz_count, is_header_at, cached, live_item_links_at)
    if not blizz_count or blizz_count <= 0 then
        return nil
    end
    if not cached then
        for i = 1, blizz_count, 1 do
            if not is_header_at[i] then
                return i
            end
        end
        return nil
    end

    for i = 1, blizz_count, 1 do
        if not is_header_at[i] and is_recipe_index_stale(i, cached, live_item_links_at) then
            return i
        end
    end

    return nil
end

-- Returns true when any non-header Blizzard recipe index lacks cached data
-- or cached data does not match the live result link at that index.
-- blizz_count includes header rows; cached is indexed by recipe position only.
-- live_item_links_at[i] is optional; when provided, result item ids are compared.
function SkilletUtil.IsRecipeIndexCacheStale(blizz_count, is_header_at, cached, live_item_links_at)
    if not blizz_count or blizz_count <= 0 then
        return false
    end
    if not cached then
        return true
    end

    return find_first_stale_recipe_index(blizz_count, is_header_at, cached, live_item_links_at) ~= nil
end

function SkilletUtil.FindFirstStaleRecipeIndex(blizz_count, is_header_at, cached, live_item_links_at)
    return find_first_stale_recipe_index(blizz_count, is_header_at, cached, live_item_links_at)
end

-- Counts non-header recipe rows in the live Blizzard tradeskill list.
function SkilletUtil.CountNonHeaderRecipes(blizz_count, is_header_at)
    if not blizz_count or blizz_count <= 0 then
        return 0
    end

    local count = 0
    for i = 1, blizz_count, 1 do
        if not is_header_at[i] then
            count = count + 1
        end
    end

    return count
end

-- Counts non-header recipe rows with cached data; require_fresh excludes stale links.
local function count_cached_recipe_rows(blizz_count, is_header_at, cached, live_item_links_at, require_fresh)
    if not blizz_count or blizz_count <= 0 or not cached then
        return 0
    end

    local count = 0
    for i = 1, blizz_count, 1 do
        if not is_header_at[i] and cached[i]
            and (not require_fresh or not is_recipe_index_stale(i, cached, live_item_links_at)) then
            count = count + 1
        end
    end

    return count
end

-- Counts non-header recipe rows that already have cached data.
function SkilletUtil.CountCachedRecipes(blizz_count, is_header_at, cached)
    return count_cached_recipe_rows(blizz_count, is_header_at, cached, nil, false)
end

-- Counts non-header recipe rows with cached data that matches live result links.
function SkilletUtil.CountFreshCachedRecipes(blizz_count, is_header_at, cached, live_item_links_at)
    return count_cached_recipe_rows(blizz_count, is_header_at, cached, live_item_links_at, true)
end

-- Counts non-header recipe rows from Blizzard index 1 through through_index (inclusive).
function SkilletUtil.CountNonHeaderRecipesUpTo(blizz_count, is_header_at, through_index)
    if not blizz_count or blizz_count <= 0 or not through_index or through_index <= 0 then
        return 0
    end

    local count = 0
    local limit = through_index
    if limit > blizz_count then
        limit = blizz_count
    end
    for i = 1, limit, 1 do
        if not is_header_at[i] then
            count = count + 1
        end
    end

    return count
end

function SkilletUtil.ComputeScanPercent(done, total)
    if not total or total <= 0 then
        return 0
    end

    local pct = math.floor(done / total * 100)
    if pct > 100 then
        return 100
    end
    return pct
end

-- Recomputes recipe_done, recipe_done_display, and recipe_total on an active scan session.
-- Done count uses max(cached recipes, scan position); display never decreases mid-session.
function SkilletUtil.SyncScanSessionProgress(session, cached, progress_through_index)
    if not session or not session.is_header then
        return
    end

    session.recipe_total = SkilletUtil.CountNonHeaderRecipes(session.blizz_count, session.is_header)

    local cache_done = SkilletUtil.CountFreshCachedRecipes(
        session.blizz_count, session.is_header, cached, session.live_links)

    local through = progress_through_index
    if through == nil then
        through = session.next_index - 1
    end
    local position_done = SkilletUtil.CountNonHeaderRecipesUpTo(
        session.blizz_count, session.is_header, through)

    local candidate = cache_done
    if position_done > candidate then
        candidate = position_done
    end
    session.recipe_done = candidate

    local display = session.recipe_done_display or 0
    if candidate > display then
        display = candidate
    end
    session.recipe_done_display = display
end

-- True when a scan session should show progress in the window title.
function SkilletUtil.IsScanSessionUIActive(session)
    if not session or session.pending then
        return false
    end
    return true
end

-- True when the scan driver may process another chunk (not pending or waiting on shred retry).
function SkilletUtil.IsScanSessionRunnable(session)
    if not SkilletUtil.IsScanSessionUIActive(session) then
        return false
    end
    if session.waiting_retry then
        return false
    end
    return true
end

-- Refreshes header maps and recipe_total on a scan session when Blizzard row count changes.
function SkilletUtil.SyncScanSessionBlizzCount(session, blizz_count)
    session.blizz_count = blizz_count
    session.is_header, session.live_links = SkilletUtil.BuildTradeSkillHeaderMaps(blizz_count)
    session.recipe_total = SkilletUtil.CountNonHeaderRecipes(blizz_count, session.is_header)
end

-- When the live tradeskill list changes mid-scan (e.g. learning a recipe), refresh maps
-- and rewind next_index to the first stale row before the current cursor.
function SkilletUtil.ResyncScanSessionAfterRecipeListChange(session, blizz_count, cached)
    if not session or not blizz_count or blizz_count <= 0 then
        return false
    end

    local changed = false
    if blizz_count ~= session.blizz_count then
        SkilletUtil.SyncScanSessionBlizzCount(session, blizz_count)
        changed = true
    end

    local stale = SkilletUtil.FindFirstStaleRecipeIndex(
        blizz_count, session.is_header, cached, session.live_links)
    local cursor = session.next_index or 1
    if stale and stale < cursor then
        session.next_index = stale
        changed = true
    end

    return changed
end

-- Human-readable scan progress for tests and fallback display.
function SkilletUtil.FormatScanProgress(profession, done, total)
    local pct = SkilletUtil.ComputeScanPercent(done, total)
    return profession .. " — " .. done .. "/" .. total .. " (" .. pct .. "%)"
end

function SkilletUtil.FindRecipeIndexByDataString(recipes_by_index, target, decode_recipe)
    if not recipes_by_index or not target then
        return nil
    end

    for index, recipe_string in pairs(recipes_by_index) do
        if type(index) == "number" and recipe_string == target then
            return index
        end
    end

    if decode_recipe then
        local decoded = decode_recipe(target)
        if decoded and decoded.link then
            for index, recipe_string in pairs(recipes_by_index) do
                if type(index) == "number" and recipe_string then
                    local candidate = decode_recipe(recipe_string)
                    if candidate and candidate.link == decoded.link then
                        return index
                    end
                end
            end
        end
    end

    return nil
end

-- Builds header flags and live result links for Blizzard tradeskill indices.
function SkilletUtil.BuildTradeSkillHeaderMaps(blizz_count)
    local is_header = {}
    local live_links = {}

    if not blizz_count or blizz_count <= 0 then
        return is_header, live_links
    end

    for i = 1, blizz_count, 1 do
        local _, skillType = GetTradeSkillInfo(i)
        is_header[i] = (skillType == "header")
        if not is_header[i] then
            live_links[i] = GetTradeSkillItemLink(i)
        end
    end

    return is_header, live_links
end

-- Finds the Blizzard tradeskill index for an item id after indices shift.
function SkilletUtil.FindRecipeIndexByItemId(recipe_ids_by_index, target_id)
    if not recipe_ids_by_index or not target_id then
        return nil
    end

    for index, item_id in pairs(recipe_ids_by_index) do
        if type(index) == "number" and item_id == target_id then
            return index
        end
    end

    return nil
end

-- Adds reagent links from a decoded recipe into a set keyed by link string.
function SkilletUtil.AddReagentLinksFromRecipe(links_set, recipe, maxReagents)
    maxReagents = maxReagents or 8
    if not links_set or not recipe then
        return links_set
    end

    for i = 1, maxReagents, 1 do
        if recipe[i] and recipe[i].link then
            links_set[recipe[i].link] = true
        end
    end

    return links_set
end

-- Computes craftable counts from pre-resolved reagent quantities (testable).
function SkilletUtil.ComputeCraftableCounts(reagents, nummade, prefer_non_vendor)
    nummade = nummade or 1
    if not reagents or #reagents == 0 then
        return 0, 0, nil
    end

    local function min_craftable(use_bank, use_alts)
        local num = 1000
        local found = false
        for _, v in ipairs(reagents) do
            if not prefer_non_vendor or v.vendor == false then
                local have = v.num or 0
                if use_bank then
                    have = v.numwbank or 0
                end
                if use_alts and v.numwalts ~= nil then
                    have = v.numwalts or 0
                end
                if v.needed and v.needed > 0 then
                    found = true
                    local max = math.floor(have / v.needed) * nummade
                    if max < num then
                        num = max
                    end
                end
            end
        end
        if not found or num == 1000 then
            num = 0
            for _, v in ipairs(reagents) do
                if v.needed and v.needed > 0 then
                    local have = v.num or 0
                    if use_bank then
                        have = v.numwbank or 0
                    end
                    if use_alts and v.numwalts ~= nil then
                        have = v.numwalts or 0
                    end
                    local max = math.floor(have / v.needed) * nummade
                    if max < num or num == 0 then
                        num = max
                    end
                end
            end
        end
        return num
    end

    local num = min_craftable(false, false)
    local numwbank = min_craftable(true, false)
    local numwalts = nil
    if reagents[1] and reagents[1].numwalts ~= nil then
        numwalts = min_craftable(false, true)
    end

    return num, numwbank, numwalts
end

function SkilletUtil.IsRecipeIdFavorited(favorites_by_trade, trade, recipe_id)
    if not favorites_by_trade or not trade or not recipe_id then
        return false
    end

    local trade_favorites = favorites_by_trade[trade]
    if trade_favorites and trade_favorites[recipe_id] then
        return true
    end

    return false
end
