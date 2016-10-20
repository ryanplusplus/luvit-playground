return function()
  local rules = {}

  local function add_rule(phony, targets, deps, builder)
    if type(targets) == 'string' then
      targets = { targets }
    end
    if type(deps) == 'string' then
      deps = { deps }
    end
    builder = builder or function() end

    for _, target in ipairs(targets) do
      local rule = {
        target = target,
        deps = deps,
        builder = builder,
        subscribers = {},
        phony = phony
      }

      if target:match('*') then
        table.insert(rules, rule)
      else
        table.insert(rules, 1, rule)
      end
    end
  end

  return {
    rules = rules,
    add_rule = function(...)
      add_rule(false, ...)
    end,
    add_phony = function(...)
      add_rule(true, ...)
    end
  }
end
