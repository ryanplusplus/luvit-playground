local spawn = require 'coro-spawn'
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

local tree_cache = {}

local function generate_tree(target)
  if tree_cache[target] then return tree_cache[target] end

  local target_exists = exists(target)
  local target_mtime = mtime(target)

  for _, rule in ipairs(rules) do
    local match = target:match(rule.target)
    local out_of_date = false

    if match ~= nil then
      local satisfied_all_deps = true
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
          local sub_tree = generate_tree(dep)
          if not sub_tree then
            satisfied_all_deps = false
            break
          end
          table.insert(tree.deps, sub_tree)
        elseif not target_exists or is_before(target_mtime, mtime(dep)) then
          out_of_date = true
        end
      end

      if satisfied_all_deps then
        if target_exists and not out_of_date then
          tree.complete = true
        end
        tree_cache[target] = tree
        return tree
      end
    end
  end
end

local function execute(tree)
  coro(function()
    tree.rule.builder(tree.target, tree.match)
    tree.complete = true
    for _, subscriber in ipairs(tree.rule.subscribers[tree.target] or {}) do
      subscriber()
    end
  end)
end

local function build_tree(tree)
  if tree.scheduled or tree.complete then return end

  tree.scheduled = true

  local todo_dep_count = 0
  local function dep_completed()
    todo_dep_count = todo_dep_count - 1
    if todo_dep_count == 0 then
      execute(tree)
    end
  end

  for _, dep in ipairs(tree.deps) do
    if not dep.complete then
      todo_dep_count = todo_dep_count + 1
      dep.rule.subscribers[dep.target] = dep.rule.subscribers[dep.target] or {}
      table.insert(dep.rule.subscribers[dep.target], dep_completed)
      build_tree(dep)
    end
  end

  if todo_dep_count == 0 then
    execute(tree)
  end
end

local function run(target)
  coro(function()
    local tree = generate_tree(target)

    if not tree then
      print('error: no recipe for building target "' .. target .. '"')
      return
    end

    if tree.complete then
      print('nothing to be done for target "' .. target .. '"')
    end

    -- pretty(tree)

    build_tree(tree)
  end)
end

--

rule('build', {}, function()
  print('Creating build directory...')
  fs.mkdirp('build')
end)

rule('build/*.o', { 'src/*.c', 'build' }, function(target, match)
  print('Compiling ' .. target .. '...')
  exec('touch ' .. target)
end)

rule('build/a.o', { 'src/a.c', 'build' }, function(target)
  print('Compiling ' .. target .. '...')
  exec('touch build/a.o')
end)

rule('build/app.lib', { 'build/a.o', 'build/b.o', 'build/c.o', 'build' }, function(target)
  print('Linking ' .. target .. '...')
  exec('touch build/app.lib')
end)

run('build/app.lib')
