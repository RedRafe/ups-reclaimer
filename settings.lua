local constants = require("constants")

data:extend({
  {
    -- Seconds of flow each border item is stocked (inputs) or may pile up (outputs) in the hidden chests.
    type = "double-setting",
    name = constants.buffer_setting,
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 2, -- at least two steps, so a step never finds less than its own flow
    maximum_value = 60,
  },
})
