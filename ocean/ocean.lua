-- todo
-- ====
-- check dates on deps
-- alternatives
-- patterns
-- pass variables to recipe functions

local spawn = require 'coro-spawn'
local split = require 'coro-split'
local fs = require 'coro-fs'
local pretty = require 'pretty-print'.prettyPrint

local function coro(f)
  coroutine.wrap(f)()
end

local rules = {}

local function rule(targets, deps, builder)
  if type(targets) == 'string' then
    targets = { targets }
  end
  if type(deps) == 'string' then
    deps = { deps }
  end
  if type(builder) == 'string' then
    local command = builder
    builder = function() exec(command) end
  end

  for _, target in ipairs(targets) do
    local rule = {
      target = '^' .. target:gsub('*', '(%%S+)') .. '$',
      deps = deps,
      builder = builder,
      subscribers = subscribers
    }

    -- Prioritize non-pattern rules
    if target:match('*') then
      table.insert(rules, rule)
    else
      table.insert(rules, 1, rule)
    end
  end
end

local function exists(target)
  return fs.stat(target) ~= nil
end

local function get_tree(target)
  for _, rule in ipairs(rules) do
    local match = target:match(rule.target)

    if match ~= nil then
      local found_all_deps = true
      local tree = {
        builder = rule.builder,
        target = target,
        deps = {},
        match = match
      }

      for _, dep in ipairs(rule.deps) do
        local dep = dep:gsub('*', match)
        if not exists(dep) then
          local sub_tree = get_tree(dep)
          if not sub_tree then
            found_all_deps = false
            break
          end
          table.insert(tree.deps, sub_tree)
        end
      end

      if found_all_deps then
        return tree
      end
    end
  end
end

local function build_tree(tree)

end

local function run(target)
  coro(function()
    local tree = get_tree(target)
    pretty(tree)
    build_tree(tree)
  end)
end

--

rule('build', {}, function()
  fs.mkdirp('build')
end)

rule('build/*.o', { 'src/*.c', 'build' }, function(target, match)
  exec('touch ' .. target)
end)

rule('build/a.o', { 'src/a.c', 'build' }, 'touch build/a.o')

rule('build/app.lib', { 'build/a.o', 'build/b.o', 'build/c.o', 'build' }, 'touch build/app.lib')

run('build/app.lib')
