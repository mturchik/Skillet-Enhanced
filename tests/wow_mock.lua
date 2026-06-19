-- Minimal WoW API stubs for off-client unit tests.

function GetItemInfo(link)
    local id = SkilletUtil and SkilletUtil.GetItemIDFromLink(link)
    if not id then return end
    return "MockItem", link, 1, 1, 60
end

function GetItemQualityColor(rarity)
    return 1, 1, 1, "ffffff"
end

function GetTradeSkillInfo(index)
    return "Mock Recipe", "optimal", 1, 1
end

function GetTradeSkillItemLink(index)
    return nil
end

function GetItemCount(link, includeBank)
    return 0
end

function UnitName(unit)
    return "TestPlayer"
end

GRAY_FONT_COLOR_CODE = "|cff808080"
FONT_COLOR_CODE_CLOSE = "|r"
