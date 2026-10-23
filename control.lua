local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.border"),
  require("scripts.freeze"),
  require("scripts.runtime"),
  require("scripts.selection"),
})
