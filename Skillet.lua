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

local MAJOR_VERSION = "1.14"
local MINOR_VERSION = ("$Revision: 153 $"):match("%d+") or 1
local DATE = string.gsub("$Date: 2008-10-26 19:38:21 +0000 (Sun, 26 Oct 2008) $", "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

Skillet = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "AceHook-2.1")
Skillet.title   = "Skillet-Enhanced"
Skillet.version = MAJOR_VERSION .. "-" .. MINOR_VERSION
Skillet.date    = DATE

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet

-- Is a copy of LibPossessions is avaialable, use it for alt
-- character inventory checks
Skillet.inventoryCheck = LibStub and LibStub:GetLibrary('LibPossessions')

-- Register to have the AceDB class handle data and option persistence for us
Skillet:RegisterDB("SkilletDB", "SkilletDBPC")

-- Global ( across all alts ) options
Skillet:RegisterDefaults('profile', {
    -- user configurable options
    vendor_buy_button = true,
    vendor_auto_buy   = false,
    show_item_notes_tooltip = false,
    show_crafters_tooltip = true,
    show_detailed_recipe_tooltip = true,
    link_craftable_reagents = true,
    queue_craftable_reagents = true,
    display_required_level = false,
    display_shopping_list_at_bank = false,
    display_shopping_list_at_auction = false,
    transparency = 1.0,
    scale = 1.0,
} )

-- Options specific to a single character
Skillet:RegisterDefaults('server', {
    -- we tell Stitch to keep the "recipes" table up to data for us.
    recipes = {},

    -- and any queued up recipes
    queues = {},

    -- notes added to items crafted or used in crafting.
    notes = {},
} )

-- Options specific to a single character
Skillet:RegisterDefaults('char', {
    -- options specific to a current tradeskill
    tradeskill_options = {},

    -- recipe favorites keyed by profession name then result item/enchant id
    favorite_recipes = {},

    -- Display alt's items in shopping list
    include_alts = true,
} )

-- Localization
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Events
local AceEvent = AceLibrary("AceEvent-2.0")

-- All the options that we allow the user to control.
local Skillet = Skillet
Skillet.options =
{
    handler = Skillet,
    type = 'group',
    args = {
        features = {
            type = 'group',
            name = L["Features"],
            desc = L["FEATURESDESC"],
            order = 11,
            args = {
                vendor_buy_button = {
                    type = "toggle",
                    name = L["VENDORBUYBUTTONNAME"],
                    desc = L["VENDORBUYBUTTONDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_buy_button;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_buy_button = value;
                    end,
                    order = 12
                },
                vendor_auto_buy = {
                    type = "toggle",
                    name = L["VENDORAUTOBUYNAME"],
                    desc = L["VENDORAUTOBUYDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_auto_buy;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_auto_buy = value;
                    end,
                    order = 12
                },
                show_item_notes_tooltip = {
                    type = "toggle",
                    name = L["SHOWITEMNOTESTOOLTIPNAME"],
                    desc = L["SHOWITEMNOTESTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_item_notes_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_item_notes_tooltip = value;
                    end,
                    order = 13
                },
                show_crafters_tooltip = {
                    type = "toggle",
                    name = L["SHOWCRAFTERSTOOLTIPNAME"],
                    desc = L["SHOWCRAFTERSTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_crafters_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_crafters_tooltip = value;
                    end,
                    order = 14
                },
                show_detailed_recipe_tooltip = {
                    type = "toggle",
                    name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
                    desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_detailed_recipe_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_detailed_recipe_tooltip = value;
                    end,
                    order = 15
                },
                link_craftable_reagents = {
                    type = "toggle",
                    name = L["LINKCRAFTABLEREAGENTSNAME"],
                    desc = L["LINKCRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.link_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.link_craftable_reagents = value;
                    end,
                    order = 16
                },
                queue_craftable_reagents = {
                    type = "toggle",
                    name = L["QUEUECRAFTABLEREAGENTSNAME"],
                    desc = L["QUEUECRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.queue_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.queue_craftable_reagents = value;
                    end,
                    order = 17
                },
                display_shopping_list_at_bank = {
                    type = "toggle",
                    name = L["DISPLAYSHOPPINGLISTATBANKNAME"],
                    desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_bank;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_bank = value;
                    end,
                    order = 18
                },
                display_shopping_list_at_auction = {
                    type = "toggle",
                    name = L["DISPLAYSGOPPINGLISTATAUCTIONNAME"],
                    desc = L["DISPLAYSGOPPINGLISTATAUCTIONDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_auction;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_auction = value;
                    end,
                    order = 19
                },
                show_craft_counts = {
                    type = "toggle",
                    name = L["SHOWCRAFTCOUNTSNAME"],
                    desc = L["SHOWCRAFTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_craft_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_craft_counts = value
                        Skillet:internal_RefreshRecipeList(true)
                    end,
                    order = 20,
                },
            }
        },
        appearance = {
            type = 'group',
            name = L["Appearance"],
            desc = L["APPEARANCEDESC"],
            order = 12,
            args = {
                display_required_level = {
                    type = "toggle",
                    name = L["DISPLAYREQUIREDLEVELNAME"],
                    desc = L["DISPLAYREQUIREDLEVELDESC"],
                    get = function()
                        return Skillet.db.profile.display_required_level
                    end,
                    set = function(value)
                        Skillet.db.profile.display_required_level = value
                        Skillet:internal_RefreshRecipeList(true)
                    end,
                    order = 1
                },
                transparency = {
                    type = "range",
                    name = L["Transparency"],
                    desc = L["TRANSPARAENCYDESC"],
                    min = 0.1, max = 1, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.transparency
                    end,
                    set = function(t)
                        Skillet.db.profile.transparency = t
                        Skillet:internal_RefreshWindowChrome()
                    end,
                    order = 2,
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    desc = L["SCALEDESC"],
                    min = 0.1, max = 1.25, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.scale
                    end,
                    set = function(t)
                        Skillet.db.profile.scale = t
                        Skillet:internal_RefreshWindowChrome()
                    end,
                    order = 3,
                },
                enhanced_recipe_display = {
                    type = "toggle",
                    name = L["ENHANCHEDRECIPEDISPLAYNAME"],
                    desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
                    get = function()
                        return Skillet.db.profile.enhanced_recipe_display
                    end,
                    set = function(value)
                        Skillet.db.profile.enhanced_recipe_display = value
                        Skillet:internal_RefreshRecipeList(true)
                    end,
                    order = 2,
                },
            },
        },
        inventory = {
            type = "group",
            name = L["Inventory"],
            desc = L["INVENTORYDESC"],
            order = 13,
            args = {
                addons = {
                    type = 'execute',
                    name = L["Supported Addons"],
                    desc = L["SUPPORTEDADDONSDESC"],
                    func = function()
                        Skillet:ShowInventoryInfoPopup()
                    end,
                    order = 1,
                },
                show_bank_alt_counts = {
                    type = "toggle",
                    name = L["SHOWBANKALTCOUNTSNAME"],
                    desc = L["SHOWBANKALTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_bank_alt_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_bank_alt_counts = value
                        Skillet:internal_RefreshInventoryCounts()
                    end,
                    order = 2,
                },
            },
        },

        about = {
            type = 'execute',
            name = L["About"],
            desc = L["ABOUTDESC"],
            func = function()
                Skillet:PrintAddonInfo()
            end,
            order = 50
        },
        config = {
            type = 'execute',
            name = L["Config"],
            desc = L["CONFIGDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    Skillet:ShowOptions()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            guiHidden = true,
            order = 51
        },
        shoppinglist = {
            type = 'execute',
            name = L["Shopping List"],
            desc = L["SHOPPINGLISTDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    Skillet:DisplayShoppingList(false)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            order = 52
        },
    }
}

-- Called when the addon is loaded
function Skillet:OnInitialize()

    -- hook default tooltips
    local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
    for _, tooltip in pairs(tooltipsToHook) do
        if tooltip and tooltip:HasScript("OnTooltipSetItem") then
            if tooltip:GetScript("OnTooltipSetItem") then
                local oldOnTooltipSetItem = tooltip:GetScript("OnTooltipSetItem")
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    oldOnTooltipSetItem(tooltip)
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            else
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            end
        end
    end

    -- no need to be spammy about the fact that we are here, they'll find out soon enough
    -- self:Print("Skillet v" .. self.version .. " loaded");

    -- Track trade skill creation
    self.stitch = AceLibrary("SkilletStitch-1.1")

    -- Make sure this is done in initialize, not enable as we want the chat
    -- commands to be available even when the mod is disabled. Otherwise,
    -- how would the mod be enabled again?
    self:RegisterChatCommand({"/skillet"}, self.options, "SKILLET")

end

-- Returns the number of items across all characters, including the
-- current one.
local function alt_item_lookup(link)
    local item = Skillet:GetItemIDFromLink(link)
    return Skillet.inventoryCheck:GetItemCount(item)
end

local function register_skillet_options_window()
    local waterfall = AceLibrary("Waterfall-1.0")
    if waterfall:IsRegistered("Skillet") then
        return
    end
    waterfall:Register("Skillet",
                   "aceOptions", Skillet.options,
                   "title",      L["Skillet Trade Skills"],
                   "colorR",     0,
                   "colorG",     0.7,
                   "colorB",     0
                   )
end

-- Called when the addon is enabled
function Skillet:OnEnable()

    -- Hook into the events that we care about

    -- Trade skill window changes
    self:RegisterEvent("TRADE_SKILL_CLOSE")
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("TRADE_SKILL_UPDATE")

    -- Learning or unlearning a tradeskill
    self:RegisterEvent('SKILL_LINES_CHANGED')

    -- Tracks when the bumber of items on hand changes
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("TRADE_CLOSED")

    -- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_UPDATE")
    self:RegisterEvent("MERCHANT_CLOSED")

    -- May need to show a shopping list when at the bank/auction house
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")

    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Messages from the Stitch libary
    -- These need to update the tradeskill window, not just the queue
    -- as we need to redisplay the number of items that can be crafted
    -- as we consume reagents.
    self:RegisterEvent("SkilletStitch_Queue_Continue", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Complete", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Add",      "QueueChanged")

    self:RegisterEvent("SkilletStitch_Scan_Complete",  "ScanCompleted")

    self.hideUncraftableRecipes = false
    self.hideTrivialRecipes = false
    self.currentTrade = nil
    self.selectedSkill = nil

    -- run the upgrade code to convert any old settings
    self:UpgradeDataAndOptions()

    if self.stitch.SetAltCharacterItemLookupFunction and self.inventoryCheck and self.inventoryCheck:IsAvailable() then
        -- Older version of the Stitch-1.1 library may not have this
        -- routine. If they don't then we just don't included item
        -- counts from alt characters.
        self.stitch:SetAltCharacterItemLookupFunction(alt_item_lookup)
    end

    -- hook up our copy of stitch to the data for this character
    if self.db.server.recipes[UnitName("player")] then
        self.stitch.data = self.db.server.recipes[UnitName("player")]
    end
    self.db.server.recipes[UnitName("player")] = self.stitch.data

    self.stitch:EnableDataGathering("Skillet")
    self.stitch:EnableQueue("Skillet")

    register_skillet_options_window()
    AceLibrary("Waterfall-1.0"):Open("Skillet")

end

-- Called when the addon is disabled
function Skillet:OnDisable()
    self.stitch:DisableDataGathering("Skillet")
    self.stitch:DisableQueue("Skillet");

    self:UnregisterAllEvents()

    AceLibrary("Waterfall-1.0"):Close("Skillet")
    AceLibrary("Waterfall-1.0"):UnRegister("Skillet")
end

local function is_known_trade_skill(name)
    -- Check to see if we actually know this skill or if the user is
    -- opening a tradeskill that was linked to them. We can't just check
    -- the cached list of skills as this might also be a tradeskill that
    -- the user has just learned.
    local numSkills = GetNumSkillLines()
    for skillIndex=1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil and skillName == name then
            return true
        end
    end

    -- must not be a trade skill we know about.
    return false
end

-- Checks to see if the current trade is one that we support.
local function is_supported_trade(parent)
    local name = parent:GetTradeSkillLine()

    -- EnchantingSell does not play well with the Skillet window, so
    -- if it is enabled, and it was the craft frame hidden, do not
    -- show Skillet for enchanting.
    --
    -- EnchantingSell does some odd things to the enchanting toggle,
    -- so expect some odd bug reports about this.
    if ESeller and ESeller:IsActive() and ESeller.db.char.DisableDefaultCraftFrame then
         return false
    end

    return is_known_trade_skill(name) and not IsTradeSkillLinked()

end

local scan_session = nil
local need_inventory_refresh_on_open = false
local pending_selected_recipe = nil
local scan_just_completed_prof = nil
local scan_notify_trade = nil
local SCAN_CHUNK_SIZE = 30
local SCAN_TITLE_UPDATE_INTERVAL = 0.25
local scan_title_last_pct = nil
local scan_title_last_done = nil
local scan_title_last_time = nil

local function reset_scan_title_throttle()
    scan_title_last_pct = nil
    scan_title_last_done = nil
    scan_title_last_time = nil
end

local function cancel_scheduled_event(name)
    if AceEvent:IsEventScheduled(name) then
        AceEvent:CancelScheduledEvent(name)
    end
end

local function cancel_scan_retry_events()
    cancel_scheduled_event("Skillet_ScanRetry")
    cancel_scheduled_event("SkilletStitch_AutoRescan")
end

local function cancel_all_scan_events()
    cancel_scheduled_event("Skillet_DeferredScanStart")
    cancel_scan_retry_events()
end

local function schedule_event_once(name, func, delay)
    if not AceEvent:IsEventScheduled(name) then
        AceEvent:ScheduleEvent(name, func, delay)
    end
end

local scan_driver = CreateFrame("Frame", nil, UIParent)
scan_driver:Hide()
scan_driver.elapsed = 0
scan_driver:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0

    if not SkilletUtil.IsScanSessionRunnable(scan_session) then
        self:Hide()
        return
    end

    Skillet:ProcessScanChunk()
    if not scan_session then
        self:Hide()
    end
end)

local function Skillet_start_scan_driver()
    scan_driver.elapsed = 0
    scan_driver:Show()
end

local function Skillet_stop_scan_driver()
    scan_driver:Hide()
    scan_driver.elapsed = 0
end

local function Skillet_clear_scan_flag()
    scan_just_completed_prof = nil
end

local function capture_selected_recipe(self)
    pending_selected_recipe = nil
    if self.selectedSkill and self.currentTrade then
        local data = self.stitch.data[self.currentTrade]
        if data then
            pending_selected_recipe = data[self.selectedSkill]
        end
    end
end

local function restore_selected_recipe(self)
    if pending_selected_recipe and self.currentTrade then
        local data = self.stitch.data[self.currentTrade]
        if data then
            local new_index = SkilletUtil.FindRecipeIndexByDataString(data, pending_selected_recipe)
            if new_index then
                self.selectedSkill = new_index
            end
        end
    end
    pending_selected_recipe = nil
end

function Skillet:GetScanSession()
    return scan_session
end

function Skillet:CancelScanSession()
    Skillet_stop_scan_driver()
    cancel_all_scan_events()
    scan_session = nil
    scan_notify_trade = nil
    reset_scan_title_throttle()
    self:UpdateWindowTitle()
    self:RefreshScanInteractionState()
end

function Skillet:UpdateScanProgressUI(trade, progress_through_index)
    if not self:IsScanInProgress(trade) then
        return
    end

    SkilletUtil.SyncScanSessionProgress(
        scan_session,
        self.stitch.data[trade],
        progress_through_index
    )

    local done = scan_session.recipe_done_display or scan_session.recipe_done
    local pct = SkilletUtil.ComputeScanPercent(done, scan_session.recipe_total)
    local now = GetTime()
    if scan_title_last_done == nil or scan_title_last_done ~= done
        or scan_title_last_pct == nil or scan_title_last_pct ~= pct
        or not scan_title_last_time or (now - scan_title_last_time) >= SCAN_TITLE_UPDATE_INTERVAL then
        scan_title_last_done = done
        scan_title_last_pct = pct
        scan_title_last_time = now
        self:UpdateWindowTitle()
    end
end

local function Skillet_deferred_scan_start()
    local session = scan_session
    if not session or not session.pending then
        return
    end

    if InCombatLockdown() then
        schedule_deferred_scan_after_combat()
        return
    end

    local trade = session.profession
    local opts = { force = session.force, notify = session.notify }

    if GetNumTradeSkills() <= 0 then
        schedule_deferred_scan_start()
        return
    end

    scan_session = nil
    Skillet:BeginScanSession(trade, opts)
end

local function schedule_deferred_scan_start()
    schedule_event_once("Skillet_DeferredScanStart", Skillet_deferred_scan_start, 0.1)
end

local function Skillet_deferred_scan_after_combat()
    if InCombatLockdown() then
        AceEvent:ScheduleLeaveCombatAction(Skillet_deferred_scan_after_combat)
        return
    end
    Skillet_deferred_scan_start()
end

local function schedule_deferred_scan_after_combat()
    AceEvent:ScheduleLeaveCombatAction(Skillet_deferred_scan_after_combat)
end

local function Skillet_resume_scan_after_list_change(trade)
    if not scan_session or scan_session.profession ~= trade then
        return
    end

    local blizz_count = GetNumTradeSkills()
    if blizz_count <= 0 then
        return
    end

    local cached = Skillet.stitch.data[trade]
    SkilletUtil.ResyncScanSessionAfterRecipeListChange(scan_session, blizz_count, cached)

    if scan_session.waiting_retry then
        scan_session.waiting_retry = false
        cancel_scheduled_event("Skillet_ScanRetry")
    end

    if SkilletUtil.IsScanSessionRunnable(scan_session) then
        Skillet_start_scan_driver()
    end
end

local function Skillet_scan_retry()
    if not scan_session or not scan_session.waiting_retry then
        return
    end

    scan_session.waiting_retry = false
    Skillet:UpdateWindowTitle()
    Skillet_start_scan_driver()
end

function Skillet:FinishScanSession(trade)
    Skillet_stop_scan_driver()
    local notify = scan_session and scan_session.notify
    if scan_session then
        SkilletUtil.SyncScanSessionProgress(
            scan_session,
            self.stitch.data[trade],
            nil
        )
    end
    scan_session = nil
    scan_notify_trade = nil
    reset_scan_title_throttle()
    self:UpdateWindowTitle()
    if notify then
        self:Print(L["Scan completed"] .. ": " .. trade)
    end
    AceEvent:TriggerEvent("SkilletStitch_Scan_Complete", trade)
    self:RefreshScanInteractionState()
end

function Skillet:HandleScanShredded(trade)
    Skillet_stop_scan_driver()
    if not scan_session or scan_session.profession ~= trade then
        return
    end

    scan_session.waiting_retry = true
    self:UpdateWindowTitle()
    schedule_event_once("Skillet_ScanRetry", Skillet_scan_retry, 0.5)
end

function Skillet:ProcessScanChunk()
    if not SkilletUtil.IsScanSessionRunnable(scan_session) then
        return
    end

    local trade = scan_session.profession
    local live_trade = self:GetTradeSkillLine()
    if live_trade ~= trade then
        if not live_trade or live_trade == "" or live_trade == "UNKNOWN" then
            Skillet_start_scan_driver()
            return
        end
        self:CancelScanSession()
        return
    end

    local blizz_count = GetNumTradeSkills()
    if blizz_count <= 0 then
        Skillet_start_scan_driver()
        return
    end

    if blizz_count ~= scan_session.blizz_count then
        SkilletUtil.SyncScanSessionBlizzCount(scan_session, blizz_count)
    end

    local start_index = scan_session.next_index
    if start_index > blizz_count then
        if scan_session.forced then
            self:FinishScanSession(trade)
            return
        elseif self:IsRecipeCacheStale(trade) then
            scan_session.is_header, scan_session.live_links = SkilletUtil.BuildTradeSkillHeaderMaps(blizz_count)
            start_index = SkilletUtil.FindFirstStaleRecipeIndex(
                blizz_count, scan_session.is_header, self.stitch.data[trade], scan_session.live_links) or 1
            scan_session.next_index = start_index
        else
            self:FinishScanSession(trade)
            return
        end
    end

    local end_index = math.min(start_index + SCAN_CHUNK_SIZE - 1, blizz_count)
    local shred, scanned, shred_index = self.stitch:ScanIndexRange(trade, start_index, end_index)

    if shred then
        local progress_through = nil
        if shred_index then
            progress_through = shred_index - 1
        end
        self:UpdateScanProgressUI(trade, progress_through)
        self:HandleScanShredded(trade)
        return
    end

    scan_session.next_index = end_index + 1
    self:UpdateScanProgressUI(trade)

    if scan_session.forced then
        if scan_session.next_index > blizz_count then
            self:FinishScanSession(trade)
        else
            Skillet_start_scan_driver()
        end
    elseif not self:IsRecipeCacheStale(trade) then
        self:FinishScanSession(trade)
    else
        Skillet_start_scan_driver()
    end
end

function Skillet:BeginScanSession(trade, opts)
    opts = opts or {}
    if InCombatLockdown() then
        return false
    end
    local forced = opts.force and true or false
    local notify = opts.notify and true or false

    local blizz_count = GetNumTradeSkills()
    if blizz_count <= 0 then
        return false
    end

    local is_header, live_links = SkilletUtil.BuildTradeSkillHeaderMaps(blizz_count)
    if not self.stitch.data[trade] then
        self.stitch.data[trade] = {}
    end
    local cached = self.stitch.data[trade]

    local next_index = 1
    if not forced then
        local stale_index = SkilletUtil.FindFirstStaleRecipeIndex(blizz_count, is_header, cached, live_links)
        if not stale_index then
            return false
        end
        next_index = stale_index
    end

    local fresh_done = forced and 0 or SkilletUtil.CountFreshCachedRecipes(blizz_count, is_header, cached, live_links)

    scan_session = {
        profession = trade,
        next_index = next_index,
        blizz_count = blizz_count,
        is_header = is_header,
        live_links = live_links,
        recipe_total = SkilletUtil.CountNonHeaderRecipes(blizz_count, is_header),
        recipe_done = fresh_done,
        recipe_done_display = fresh_done,
        forced = forced,
        notify = notify,
        pending = false,
        waiting_retry = false,
    }

    if notify and scan_notify_trade ~= trade then
        self:Print(L["Scanning tradeskill"] .. ": " .. trade)
        scan_notify_trade = trade
    end

    reset_scan_title_throttle()
    self:UpdateScanProgressUI(trade, scan_session.forced and 0 or nil)
    self:RefreshScanInteractionState()
    self:ProcessScanChunk()
    return true
end

function Skillet:RequestRecipeScan(trade, opts)
    opts = opts or {}
    trade = trade or self:GetTradeSkillLine()

    if not trade or trade == "" or trade == "UNKNOWN" then
        return false
    end
    if not is_known_trade_skill(trade) or IsTradeSkillLinked() then
        return false
    end

    if scan_session and scan_session.pending and scan_session.profession == trade then
        if InCombatLockdown() then
            schedule_deferred_scan_after_combat()
        elseif GetNumTradeSkills() > 0 then
            Skillet_deferred_scan_start()
        else
            schedule_deferred_scan_start()
        end
        return true
    end

    if self:IsScanInProgress(trade) then
        Skillet_resume_scan_after_list_change(trade)
        return true
    end

    if not opts.force and not self:IsRecipeCacheStale(trade) then
        return false
    end

    if self:IsScanInProgress() then
        self:CancelScanSession()
    end

    cancel_scan_retry_events()

    if InCombatLockdown() then
        scan_session = {
            profession = trade,
            pending = true,
            notify = opts.notify and true or false,
            force = opts.force and true or false,
        }
        schedule_deferred_scan_after_combat()
        return true
    end

    local blizz_count = GetNumTradeSkills()
    if blizz_count <= 0 then
        scan_session = {
            profession = trade,
            pending = true,
            notify = opts.notify and true or false,
            force = opts.force and true or false,
        }
        schedule_deferred_scan_start()
        return true
    end

    return self:BeginScanSession(trade, opts)
end

function Skillet:ScanCompleted(prof)
    prof = prof or self:GetTradeSkillLine()

    if prof and prof ~= "UNKNOWN" and prof == self.currentTrade then
        self:RemapQueueAfterRescan(prof)
        restore_selected_recipe(self)
        if self.selectedSkill and not self.stitch:GetItemDataByIndex(prof, self.selectedSkill) then
            self.selectedSkill = nil
        end

        if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
            self:ResortRecipes(true)
            self:UpdateTradeSkillWindow()
        end
        if self.selectedSkill and self.selectedSkill > 0 then
            SelectTradeSkill(self.selectedSkill)
            self:UpdateDetailsWindow(self.selectedSkill)
        end
    end

    self:RefreshScanInteractionState()

    scan_just_completed_prof = prof
    if not AceEvent:IsEventScheduled("Skillet_clear_scan_flag") then
        AceEvent:ScheduleEvent("Skillet_clear_scan_flag", Skillet_clear_scan_flag, 0.1)
    end
end

function Skillet:IsScanInProgress(trade)
    if not SkilletUtil.IsScanSessionUIActive(scan_session) then
        return false
    end
    if trade then
        return scan_session.profession == trade
    end
    return true
end

-- True when queue/filter/sort/craft handlers should no-op for the given trade.
function Skillet:BlocksScanActions(trade)
    return self:IsScanInProgress(trade or self.currentTrade)
end

-- Safe to call before MainFrame loads; UpdateScanInteractionState is defined in UI/MainFrame.lua.
function Skillet:RefreshScanInteractionState()
    if self.UpdateScanInteractionState then
        self:UpdateScanInteractionState()
    end
end

-- Backward-compatible alias used by Stitch.
function Skillet:StartScanSession(trade, forced, notify)
    return self:RequestRecipeScan(trade, { force = forced, notify = notify })
end

function Skillet:IsScanJustCompleted(trade)
    if not scan_just_completed_prof then
        return false
    end
    if trade then
        return scan_just_completed_prof == trade
    end
    return true
end

-- Checks to see if the list of recipes has been cached
-- before and if not, scans them. This only works on the
-- currently selected tradeskill
local function cache_recipes_if_needed(self, force, notify)
    local trade = self:GetTradeSkillLine()
    if not trade or trade == "UNKNOWN" then
        return false
    end
    return self:RequestRecipeScan(trade, {
        force = force and true or false,
        notify = notify and true or false,
    })
end

local function Skillet_rescan_skills()
    local numSkills = GetNumSkillLines()
    local skills = {}
    for skillIndex=1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil then
            skills[skillName] = skillName
        end
    end

    local player = UnitName("player")

    local changed = false
    for profession, _ in pairs(Skillet.db.server.recipes[player]) do
        if not skills[profession] then
            changed = true
            if profession ~= "UNKNOWN" then
                -- where the hell does this come from?
                Skillet:Print("No longer know: " .. profession)
            end
            Skillet.db.server.recipes[player][profession] = nil
        end
    end

    if changed == true then
        Skillet:HideAllWindows()
        if Skillet.db.server.recipes[player] then
            Skillet.stitch.data = Skillet.db.server.recipes[player]
        end
        Skillet.db.server.recipes[player] = Skillet.stitch.data
        Skillet:internal_ResetCharacterCache()
    end
end

-- Called when the list of trade skills know by the player has changed
function Skillet:SKILL_LINES_CHANGED()
    if not AceEvent:IsEventScheduled("Skillet_rescan_skills") and not IsTradeSkillLinked() then
        AceEvent:ScheduleEvent("Skillet_rescan_skills", Skillet_rescan_skills, 10.0)
    end
end

-- Called when the trade skill window is opened
-- or when the window is open and the user selects another tradeskill
function Skillet:TRADE_SKILL_SHOW()
    if is_supported_trade(self) then
        self:UpdateTradeSkill()
        self:ShowTradeSkillWindow()
        local trade = self:GetTradeSkillLine()
        if trade and trade ~= "UNKNOWN" and self:IsRecipeCacheStale(trade) then
            self:ResetTradeSkillFilters(trade)
        end
        if not cache_recipes_if_needed(self, false, true) then
            self:UpdateWindowTitle()
        end
        self.stitch:TRADE_SKILL_SHOW()
    else
        self:HideAllWindows()
    end
end

function Skillet:TRADE_SKILL_UPDATE()
    if IsTradeSkillLinked() then
        return
    end
    self:UpdateTradeSkill()
    if scan_session and scan_session.pending then
        if InCombatLockdown() then
            schedule_deferred_scan_after_combat()
            return
        end
        Skillet_deferred_scan_start()
        return
    end
    if self:IsScanInProgress(self.currentTrade) then
        Skillet_resume_scan_after_list_change(self.currentTrade)
        self:UpdateScanProgressUI(self.currentTrade)
        self:RefreshScanInteractionState()
        return
    end
    if self:IsRecipeCacheStale() and not self:BlocksScanActions() then
        capture_selected_recipe(self)
        if cache_recipes_if_needed(self, false, false) then
            return
        end
    end
    self:ResetTradeSkillWindow()
    self:UpdateTradeSkillWindow()
    self:RefreshScanInteractionState()
end

function Skillet:PLAYER_REGEN_ENABLED()
    self:RefreshScanInteractionState()
    if scan_session and scan_session.pending then
        if GetNumTradeSkills() > 0 then
            Skillet_deferred_scan_start()
        else
            schedule_deferred_scan_start()
        end
        return
    end
    if scan_session and SkilletUtil.IsScanSessionRunnable(scan_session) then
        self:ProcessScanChunk()
    end
end

-- Called when the trade skill window is closed
function Skillet:TRADE_SKILL_CLOSE()
    self:CancelScanSession()
    self:HideAllWindows()
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill
-- window is open and a trade selected.
local function Skillet_rescan_bags()
    Skillet:internal_RefreshInventoryCounts()
    Skillet:UpdateShoppingListWindow()
end

local function Skillet_refresh_inventory_counts()
    Skillet:internal_RefreshInventoryCounts()
end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE()
    local showing = false
    if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
        showing = true
    end
    if self.shoppingList and self.shoppingList:IsVisible() then
        showing = true
    end

    if showing then
        -- bag updates can happen fairly frequently and we don't want to
        -- be scanning all the time so ... buffer updates to a single event
        -- that fires after a 1/4 second.
        if not AceEvent:IsEventScheduled("Skillet_rescan_bags") then
            AceEvent:ScheduleEvent("Skillet_rescan_bags", Skillet_rescan_bags, 0.25)
        end
    else
       -- Window closed; refresh inventory counts on next open, not recipe cache.
       need_inventory_refresh_on_open = true
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        -- may need to update the button on the merchant frame window ...
        self:UpdateMerchantFrame()
    end
end

-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
function Skillet:TRADE_CLOSED()
    self:BAG_UPDATE()
end

-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
    local trade_changed = false
    local new_trade = self:GetTradeSkillLine()

    if not self.currentTrade and new_trade then
        trade_changed = true
    elseif self.currentTrade ~= new_trade then
        trade_changed = true
    end

    if trade_changed then
        if self:IsScanInProgress() and not self:IsScanInProgress(new_trade) then
            self:CancelScanSession()
        end

        self:HideNotesWindow();

        self:SyncTradeSkillFilterWidgets(new_trade, true)

        -- And start the update sequence through the rest of the mod
        self:SetSelectedTrade(new_trade)

        -- Load up any saved queued items for this profession
        self:LoadQueue(self.db.server.queues, new_trade)

    end
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
    local frame = self.tradeSkillFrame
    if not frame then
        frame = self:CreateTradeSkillWindow()
        self:UpdateTradeSkillWindow()
        self.tradeSkillFrame = frame
    end

    self:ResetTradeSkillWindow()

    if not frame:IsVisible() then
        ShowUIPanel(frame)
    end

    if need_inventory_refresh_on_open then
        need_inventory_refresh_on_open = false
        self:internal_RefreshInventoryCounts()
    end

    self:UpdateWindowTitle()
    self:RefreshScanInteractionState()
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:internal_HideTradeSkillWindow()

    local closed -- was anything closed by us?
    local frame = self.tradeSkillFrame

    if frame and frame:IsVisible() then
        self.stitch:StopCast()
        HideUIPanel(frame)
        closed = true
    end

    return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:internal_HideAllWindows()
    local closed -- was anything closed?

    -- Cancel anything currently being created
    self.stitch:CancelCast()
    self:CancelScanSession()

    if self:HideTradeSkillWindow() then
        closed = true
    end

    if self:HideNotesWindow() then
        closed = true
    end

    if self:HideShoppingList() then
        closed = true
    end

    self.currentTrade = nil
    self.selectedSkill = nil

    return closed
end

-- Show the options window
function Skillet:ShowOptions()
    register_skillet_options_window()
    AceLibrary("Waterfall-1.0"):Open("Skillet")
end

-- Triggers a rescan of the currently selected tradeskill
function Skillet:RescanTrade(forced)
    if self:BlocksScanActions() then
        return
    end
    local trade = self:GetTradeSkillLine()
    if trade and trade ~= "UNKNOWN" and is_known_trade_skill(trade) and not IsTradeSkillLinked() then
        capture_selected_recipe(self)
        self:RequestRecipeScan(trade, {
            force = forced and true or false,
            notify = forced and true or false,
        })
    end
end

-- Notes when a new trade has been selected
function Skillet:SetSelectedTrade(new_trade)
    self.currentTrade = new_trade;
    self:SetSelectedSkill(nil, false);
    self.headerCollapsedState = {};

    self:UpdateTradeSkillWindow()

    -- Stop the stitch queue and nuke anything in it.
    -- would be nice to allow queuing items from different
    -- trades, but the Blizzard design does not allow that
    self.stitch:CancelCast();
    self.stitch:StopCast();
    self.stitch:ClearQueue();
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skill_index, was_clicked)
    if not skill_index then
        -- no skill selected
        self:HideNotesWindow()
    elseif self.selectedSkill and self.selectedSkill ~= skill_index then
        -- new skill selected
        self:HideNotesWindow() -- XXX: should this be an update?
    end

    self.selectedSkill = skill_index
    if self:IsScanInProgress(self.currentTrade) then
        pending_selected_recipe = nil
        if skill_index and skill_index > 0 then
            self:UpdateDetailsWindow(skill_index)
        end
        return
    end
    if skill_index and skill_index > 0 then
        SelectTradeSkill(skill_index)
    end
    self:UpdateDetailsWindow(skill_index)
end

-- Applies saved filter options to the filter box and recipe filter checkboxes.
-- syncFilterBox: when true, also updates SkilletFilterBox (triggers OnTextChanged).
function Skillet:SyncTradeSkillFilterWidgets(trade, syncFilterBox)
    trade = trade or self.currentTrade
    if not trade or trade == "UNKNOWN" then
        return
    end

    if syncFilterBox then
        local filterbox = getglobal("SkilletFilterBox")
        if filterbox then
            filterbox:SetText(self:GetTradeSkillOption(trade, "filtertext") or "")
        end
    end
    if SkilletShowCraftableRecipes then
        SkilletShowCraftableRecipes:SetChecked(self:GetTradeSkillOption(trade, "showcraftable"))
    end
    if SkilletShowRelevantRecipes then
        SkilletShowRelevantRecipes:SetChecked(self:GetTradeSkillOption(trade, "showrelevant"))
    end
    if SkilletShowFavoriteRecipes then
        SkilletShowFavoriteRecipes:SetChecked(self:GetTradeSkillOption(trade, "showfavorites"))
    end
end

-- Clears saved and on-screen search / recipe filters for a profession.
function Skillet:ResetTradeSkillFilters(trade)
    trade = trade or self.currentTrade
    if not trade or trade == "UNKNOWN" then
        return
    end

    self:SetTradeSkillOption(trade, "filtertext", "")
    self:SetTradeSkillOption(trade, "showcraftable", false)
    self:SetTradeSkillOption(trade, "showrelevant", false)
    self:SetTradeSkillOption(trade, "showfavorites", false)
    self:SyncTradeSkillFilterWidgets(trade, true)

    FauxScrollFrame_SetOffset(SkilletSkillList, 0)
end

-- Toggles a recipe filter checkbox and refreshes the appropriate list tier.
function Skillet:ToggleRecipeFilterOption(option, checkbox)
    if self:BlocksScanActions() then
        return
    end
    if checkbox and checkbox:GetChecked() then
        PlaySound("igMainMenuOptionCheckBoxOn")
    end

    local before = self:GetTradeSkillOption(self.currentTrade, option)
    self:SetTradeSkillOption(self.currentTrade, option, not before)

    if option == "showcraftable" then
        self:internal_RefreshInventoryCounts()
    else
        self:internal_RefreshRecipeList(true)
    end
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
    if self:BlocksScanActions() then
        return
    end
    self:SetTradeSkillOption(self.currentTrade, "filtertext", text)
    FauxScrollFrame_SetOffset(SkilletSkillList, 0)
    self:internal_RefreshRecipeList(true)
end

-- Called when the queue has changed in some way
function Skillet:QueueChanged()
    -- Hey! What's all this then? Well, we may get the request to update the
    -- windows while the queue is being processed and the reagent and item
    -- counts may not have been updated yet. So, the "0.5" puts in a 1/2
    -- second delay before the real update window method is called. That
    -- give the rest of the UI (and the API methods called by Stitch) time
    -- to record any used reagents.
    if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateWindows") then
            AceEvent:ScheduleEvent("Skillet_UpdateWindows", Skillet_refresh_inventory_counts, 0.5, self)
        end
    end

    if SkilletShoppingList and SkilletShoppingList:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateShoppingList") then
            AceEvent:ScheduleEvent("Skillet_UpdateShoppingList", Skillet.UpdateShoppingListWindow, 0.25, self)
        end
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateMerchantFrame") then
            AceEvent:ScheduleEvent("Skillet_UpdateMerchantFrame", Skillet.UpdateMerchantFrame, 0.25, self)
        end
    end
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(link)
    local result

    if not self.db.server.notes[UnitName("player")] then
        return
    end

    local id = self:GetItemIDFromLink(link)
    if id and self.db.server.notes[UnitName("player")] then
        result = self.db.server.notes[UnitName("player")][id]
    else
        self:Print("Error: Skillet:GetItemNote() could not determine item ID for " .. link);
    end

    if result and result == "" then
        result = nil
        self.db.server.notes[UnitName("player")][id] = nil
    end

    return result
end

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(link, note)
    local id = self:GetItemIDFromLink(link);

    if not self.db.server.notes[UnitName("player")] then
        self.db.server.notes[UnitName("player")] = {}
    end

    if id then
        self.db.server.notes[UnitName("player")][id] = note
    else
        self:Print("Error: Skillet:SetItemNote() could not determine item ID for " .. link);
    end

end

-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
function Skillet:AddItemNotesToTooltip(tooltip)
    if IsControlKeyDown() then
        return
    end

    local notes_enabled = self.db.profile.show_item_notes_tooltip or false
    local crafters_enabled = self.db.profile.show_crafters_tooltip or false

    -- nothing to be added to the tooltip
    if not notes_enabled and not crafters_enabled then
        return
    end

    -- get item name
    local name,link = tooltip:GetItem();
    if not link then return; end

    local id = self:GetItemIDFromLink(link);
    if not id then return end;

    if notes_enabled then
        local header_added = false
        for player,notes_table in pairs(self.db.server.notes) do
            local note = notes_table[id]
            if note then
                if not header_added then
                    tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
                    header_added = true
                end
                if player ~= UnitName("player") then
                    note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
                end
                tooltip:AddLine(" " .. note, 1, 1, 1, 1) -- r,g,b, wrap
            end
        end
    end

    if crafters_enabled then
        local crafters = self:GetCraftersForItem(id);
        if crafters then
            header_added = true
            local title_added = false

            for i,name in ipairs(crafters) do
                if not title_added then
                    title_added = true
                    tooltip:AddDoubleLine(L["Crafted By"], name)
                else
                    tooltip:AddDoubleLine(" ", name)
                end
            end
        end
    end

    return header_added
end

-- Returns the stable result id for a recipe at the given Blizzard index, or nil.
function Skillet:GetRecipeFavoriteId(trade, skill_index)
    if not trade or not skill_index or skill_index < 1 then
        return nil
    end

    local s = self.stitch:GetItemDataByIndex(trade, skill_index)
    if s and s.link then
        return self:GetItemIDFromLink(s.link)
    end
end

-- True when the recipe is marked as a favorite for this character.
function Skillet:IsRecipeFavorite(trade, skill_index)
    trade = trade or self.currentTrade
    local id = self:GetRecipeFavoriteId(trade, skill_index)
    if not id then
        return false
    end

    return SkilletUtil.IsRecipeIdFavorited(self.db.char.favorite_recipes, trade, id)
end

-- Toggles favorite state for a recipe and refreshes the recipe list.
function Skillet:ToggleRecipeFavorite(trade, skill_index)
    if self:BlocksScanActions() then
        return
    end

    trade = trade or self.currentTrade
    skill_index = skill_index or self.selectedSkill
    if not trade or not skill_index or skill_index < 1 then
        return
    end

    local id = self:GetRecipeFavoriteId(trade, skill_index)
    if not id then
        return
    end

    local favorites = self.db.char.favorite_recipes
    if not favorites[trade] then
        favorites[trade] = {}
    end

    if favorites[trade][id] then
        favorites[trade][id] = nil
        if not next(favorites[trade]) then
            favorites[trade] = nil
        end
    else
        favorites[trade][id] = true
    end

    self:SyncRecipeFavoriteButton(trade, skill_index)
    self:internal_RefreshRecipeList(true)
end

-- Updates the Favorite button label for the selected recipe.
function Skillet:SyncRecipeFavoriteButton(trade, skill_index)
    if not SkilletRecipeFavoriteButton then
        return
    end

    trade = trade or self.currentTrade
    skill_index = skill_index or self.selectedSkill
    if not skill_index or skill_index < 1 then
        SkilletRecipeFavoriteButton:Hide()
        return
    end

    if self:IsRecipeFavorite(trade, skill_index) then
        SkilletRecipeFavoriteButton:SetText(L["Unfavorite"])
    else
        SkilletRecipeFavoriteButton:SetText(L["Favorite"])
    end
    SkilletRecipeFavoriteButton:Show()
end

-- Returns the state of a craft specific option
function Skillet:GetTradeSkillOption(trade, option)
    local options = self.db.char.tradeskill_options;

    if not options or not options[trade] then
        return false
    end

    return options[trade][option]
end

-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(trade, option, value)
    local options = self.db.char.tradeskill_options;

    if not options[trade] then
        options[trade] = {}
    end

    options[trade][option] = value
end
