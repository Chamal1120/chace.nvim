local assert = require("luassert")
local describe = describe
local it = it

-- Load the module
local M = require("chace")

-- Reset the config to its defaults for each test
local function reset_config()
	M.config = {
		debug = false,
		show_notifications = true,
		model = "groq",
		keymap = "<leader>c",
	}
end

-- --- Tests ---

describe("Chace Configuration Tests", function()
	-- Reset state before each test to ensure isolation
	before_each(function()
		reset_config()
		-- clear user command and keymap to prevent leakage between tests
		vim.cmd("delcommand Chace")
		pcall(vim.keymap.del, "n", M.config.keymap)
	end)

	it("should correctly merge user options over defaults", function()
		local user_opts = {
			debug = true,
			model = "openai-gpt-4",
			show_notifications = false,
		}

		M.setup(user_opts)

		assert.is_true(M.config.debug, "Debug should be set to true")
		assert.is_false(M.config.show_notifications, "Notifications should be set to false")
		assert.are.equal("openai-gpt-4", M.config.model, "Model should be the user-provided value")
		assert.are.equal("<leader>c", M.config.keymap, "Keymap should retain the default value")
	end)

	it("should handle calling M.setup without any options", function()
		M.setup(nil)

		assert.is_false(M.config.debug, "Debug should be default false")
		assert.are.equal("groq", M.config.model, "Model should be default groq")
	end)
end)
