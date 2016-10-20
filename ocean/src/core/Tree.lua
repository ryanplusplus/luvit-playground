local fs = require 'coro-fs'

local function exists(target)
  return fs.stat(target) ~= nil
end

local function mtime(target)
  local stat = fs.stat(target)
  if stat then return stat.mtime end
end

local function is_before(mtime1, mtime2)
  if mtime1.sec == mtime2.sec then
    return mtime1.nsec < mtime2.nsec
  else
    return mtime1.sec < mtime2.sec
  end
end

return function(target, rules)
  local tree_cache = {}

  local function make_tree(target)
    if tree_cache[target] then return tree_cache[target] end

    local target_exists = exists(target)
    local target_mtime = mtime(target)

    for _, rule in ipairs(rules) do
      local match = target:match('^' .. rule.target:gsub('*', '(%%S+)') .. '$')
      local out_of_date = false

      if match ~= nil then
        local satisfied_all_deps = true
        local all_deps_complete = true
        local tree = {
          rule = rule,
          target = target,
          deps = {},
          match = match
        }

        for _, dep in ipairs(rule.deps) do
          local dep = dep:gsub('*', match)
          if not exists(dep) then
            out_of_date = true
            local sub_tree = make_tree(dep)
            if not sub_tree then
              satisfied_all_deps = false
              break
            end
            all_deps_complete = all_deps_complete and sub_tree.complete
            table.insert(tree.deps, sub_tree)
          elseif not target_exists or is_before(target_mtime, mtime(dep)) then
            out_of_date = true
          end
        end

        if satisfied_all_deps then
          if (all_deps_complete and rule.phony) or (target_exists and not out_of_date) then
            tree.complete = true
          end
          tree_cache[target] = tree
          return tree
        end
      end
    end
  end

  return make_tree(target)
end
