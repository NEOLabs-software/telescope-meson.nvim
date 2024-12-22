local telescope = require("telescope")

return telescope.register_extension({
  exports = {
    meson = require("telescope-meson.meson_picker").meson,
  },
})

