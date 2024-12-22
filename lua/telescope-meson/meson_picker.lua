local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local M = {}


M.config = {
  builddir_name = '/builddir', -- Default builddir name
  meson_build_name = '/meson.build', -- Default meson.build file name
  meson_commands_with_builddir = {
    "meson compile -C ${builddir}",
    "meson test -C ${builddir}",
    "meson install -C ${builddir}",
    "meson configure -C ${builddir}",
    "meson clean -C ${builddir}",
  }, -- Commands with builddir
  meson_commands_without_builddir = {
    "meson compile",
    "meson test",
    "meson install",
    "meson configure",
    "meson clean",
  }, -- Commands without builddir
  meson_build_template = [[
project('%s', 'c', 'cpp',
  default_options : ['buildtype=release', 'warning_level=2'])

executable('%s', %s)
]], -- Default meson.build template
}


M.meson = function(opts)
  opts = opts or {}

  -- Get the current working directory
  local cwd = vim.fn.getcwd()
  -- Check if meson.build exists in the current directory
  local meson_build_path = cwd .. M.config.meson_build_name
  local builddir = cwd .. M.config.builddir_name

  local project_name = vim.fn.fnamemodify(cwd, ":t")

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

    -- Exclude files within builddir from the search
    -- -- Delete the builddir directory recursively
    vim.fn.delete(builddir, 'rf')

    local source_files = vim.fn.glob(cwd .. '/**/*.{c,cpp,cc}', true, true)
    source_files = vim.tbl_filter(function(file)
      return not string.find(file, builddir)
    end, source_files)

    if #source_files > 0 then
      local src_list = "['" .. table.concat(source_files, "', '") .. "']"
      local meson_build_template = M.config.meson_build_template or [[
project('%s', 'c', 'cpp',
  default_options : ['buildtype=release', 'warning_level=2'])

executable('%s', %s)
]]

      local generated_meson_build = string.format(meson_build_template, project_name, project_name, src_list)
      -- Write the generated template to meson.build
      local file = io.open(meson_build_path, "w")
      if file then
        file:write(generated_meson_build)
        file:close()
        print("meson.build created with discovered source files!")
      else
        print("Failed to create meson.build.")
      end
      meson_commands = {
        "meson setup " .. builddir,
        "meson compile -C " .. builddir,
        "meson test -C " .. builddir,
        "meson install -C " .. builddir,
        "meson configure -C " .. builddir,
        "meson clean -C " .. builddir
      }
    else
     -- No source files found, fallback to meson init
      print("no source files found anywhere, falling back to meson init.")
      meson_commands = {
        "meson init"
      }
    end  
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
