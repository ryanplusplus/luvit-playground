-- todo
-- ====
-- multiple targets
-- check dates on deps
-- alternatives
-- patterns
-- pass variables to recipe functions

local spawn = require 'coro-spawn'
local split = require 'coro-split'
local fs = require 'coro-fs'

local recipes = {}

local function coro(f)
  coroutine.wrap(f)()
end

local function exists(target)
  return fs.stat(target) ~= nil
end

local function exec(command)
  local cmd, rest = command:match('(%S+)%s(.+)')
  local args = {}
  for arg in rest:gmatch('%S+') do
    table.insert(args, arg)
  end
  print(cmd, args[1], args[2])
  spawn(cmd, { args = args }).waitExit()
end

local function execute(recipe)
  coro(function()
    print('building: ' .. recipe.target)
    recipe.f()
    print('finished: ' .. recipe.target)
    split(table.unpack(recipe.subscribers))
  end)
end

local function rule(target, deps, f)
  if type(f) == 'string' then
    local command = f
    f = function() exec(command) end
  end
  recipes[target] = { target = target, deps = deps, f = f, subscribers = {} }
end

local function _run(target)
  print('running ' .. target)

  local recipe = recipes[target]

  if exists(target) then return end

  recipe.scheduled = true

  local deps
  if type(recipe.deps) == 'table' then
    deps = recipe.deps
  else
    deps = { recipe.deps }
  end

  local missing_deps = false
  for _, dep in ipairs(deps) do
    if not exists(dep) then
      assert(recipes[dep], 'no recipe to make ' .. dep)
      missing_deps = true
      table.insert(recipes[dep].subscribers, function()
        _run(target)
      end)
      if not recipes[dep].scheduled then
        _run(dep)
      end
    end
  end

  if not missing_deps and not recipe.started then
    recipe.started = true
    execute(recipe)
  end
end

local function run(target)
  coro(function()
    _run(target)
  end)
end

--

rule('build', {}, function()
  fs.mkdirp('build')
end)

rule('build/a.o', { 'src/a.c', 'build' }, 'touch build/a.o')
rule('build/b.o', { 'src/b.c', 'build' }, 'touch build/b.o')
rule('build/c.o', { 'src/c.c', 'build' }, 'touch build/c.o')

rule('build/app.lib', { 'build/a.o', 'build/b.o', 'build/c.o', 'build' }, 'touch build/app.lib')

run('build/app.lib')
