-- Bootstrap for Skillet off-client unit tests.
-- Run from addon root: lua tests/run.lua

local function addon_root()
    local script = arg and arg[0]
    if script then
        local root = script:match("^(.*)[/\\]tests[/\\]run%.lua$")
        if root and root ~= "" then
            return root .. "/"
        end
    end
    return "./"
end

local root = addon_root()
package.path = root .. "?.lua;"
    .. root .. "tests/?.lua;"
    .. root .. "tests/fixtures/?.lua;"
    .. package.path

dofile(root .. "SkilletUtil.lua")
dofile(root .. "tests/wow_mock.lua")

local lu = require("luaunit")

require("test_links")
require("test_queue")
require("test_sort")
require("test_filter")
require("test_cache")
require("test_inventory")
require("test_lua_scope")

os.exit(lu.LuaUnit.run())
