local lu = require("luaunit")

-- Documents Lua 5.1 local visibility rules that affect UI/MainFrame.lua.
-- Locals are not visible above their declaration line; helper calls must use
-- forward declarations or be defined earlier in the file.
TestLuaScope = {}

function TestLuaScope:test_localDeclaredAfterFunctionBodyResolvesAsNil()
    local function caller()
        return helper_value
    end
    local helper_value = "ok"
    lu.assertNil(caller())
end

function TestLuaScope:test_forwardDeclaredLocalIsVisibleToEarlierFunction()
    local helper_value
    local function caller()
        return helper_value
    end
    helper_value = "ok"
    lu.assertEquals("ok", caller())
end
