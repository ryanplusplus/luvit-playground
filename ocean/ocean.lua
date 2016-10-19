-- todo
-- ====
-- check dates on deps
-- error when no tree exists to build target

local spawn = require 'coro-spawn'
local split = require 'coro-split'
local fs = require 'coro-fs'
local pretty = require 'pretty-print'.prettyPrint

local function coro(f)
  coroutine.wrap(f)()
end

local rules = {}

local function exec(command)
  local cmd, rest = command:match('(%S+)%s(.+)')
  local args = {}
  for arg in rest:gmatch('%S+') do
    table.insert(args, arg)
  end
  spawn(cmd, { args = args }).waitExit()
end

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
      subscribers = {}
    }

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

local function generate_tree(target)
  for _, rule in ipairs(rules) do
    local match = target:match(rule.target)

    if match ~= nil then
      local found_all_deps = true
      local tree = {
        rule = rule,
        target = target,
        deps = {},
        match = match
      }

      for _, dep in ipairs(rule.deps) do
        local dep = dep:gsub('*', match)
        if not exists(dep) then
          local sub_tree = generate_tree(dep)
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

local function execute(tree)
  coro(function()
    print('building: ' .. tree.target .. ' (' .. tree.match .. ')')
    tree.rule.builder(tree.target, tree.match)
    print('finished: ' .. tree.target .. ' (' .. tree.match .. ')')
    if tree.rule.subscribers[tree.target] then
      split(table.unpack(tree.rule.subscribers[tree.target]))
    end
  end)
end

local function build_tree(tree)
  local target = tree.target

  if exists(target) then return end

  tree.scheduled = true

  local missing_deps = false
  for _, dep in ipairs(tree.deps) do
    if not exists(dep.target) then
      missing_deps = true
      dep.rule.subscribers[dep.target] = dep.rule.subscribers[dep.target] or {}
      table.insert(dep.rule.subscribers[dep.target], function()
        build_tree(tree)
      end)
      if not dep.scheduled then
        build_tree(dep)
      end
    end
  end

  if not missing_deps and not tree.started then
    tree.started = true
    execute(tree)
  end
end

local function run(target)
  coro(function()
    local tree = generate_tree(target)
    -- pretty(tree)
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
