local lu = require("luaunit")

-- Documents dot-vs-colon callback registration (see UI/MainFrame.lua scroll handlers).
TestCallbackSelf = {}

function TestCallbackSelf:test_dotRegisteredHandlerMustNotUseColonSelf()
    local addon = { currentTrade = "Engineering" }

    function addon.DotStyleHandler()
        return addon.currentTrade
    end

    function addon:ColonStyleHandler()
        return self.currentTrade
    end

    local fake_scroll_frame = { GetName = function() return "FakeScroll" end }

    lu.assertEquals("Engineering", addon.DotStyleHandler(fake_scroll_frame))

    -- Colon-defined body called with dot syntax: first arg becomes self, not the addon.
    lu.assertNil(addon.ColonStyleHandler(fake_scroll_frame))

    lu.assertEquals("Engineering", addon:ColonStyleHandler())
end
