local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local M = {}

M.meson = function(opts)
  opts = opts or {}

  -- Get the current working directory
  local cwd = vim.fn.getcwd()
  
  -- Check if meson.build exists in the current directory
  local meson_build_path = cwd .. '/meson.build'
  
  -- Set up the build directory path
  local builddir = cwd .. '/builddir'

  local meson_commands = {}

  -- Check if meson.build exists
  if vim.fn.filereadable(meson_build_path) == 1 then
    -- If meson.build exists, show commands that require an existing build directory
    if vim.fn.isdirectory(builddir) == 1 then
      meson_commands = {
        "meson compile -C " .. builddir,
        "meson test -C " .. builddir,
        "meson install -C " .. builddir,
        "meson configure -C " .. builddir,
        "meson clean -C " .. builddir
      }
    else
      meson_commands = {
        "meson setup " .. builddir,
        "meson compile -C " .. builddir,
        "meson test -C " .. builddir,
        "meson install -C " .. builddir,
        "meson configure -C " .. builddir,
        "meson clean -C " .. builddir
      }
    end
  else
    -- If meson.build doesn't exist, show meson init command
    meson_commands = {
      "meson init"
    }
  end

  -- Open Telescope picker with the meson commands
  pickers.new(opts, {
    prompt_title = "Meson Commands",
    finder = finders.new_table({
      results = meson_commands,
    }),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      -- On selection, run the selected command
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("!" .. selection.value)
        end
      end)
      return true
    end,
  }):find()
end

return M

