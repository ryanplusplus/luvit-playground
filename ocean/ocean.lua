return function(args)
  local RuleSet = require './src/core/RuleSet'
  local Tree = require './src/core/Tree'
  local build_tree = require './src/core/build_tree'

  local rule_set = RuleSet()

  if not args[1] then
    print('usage: ocean <lakefile> [<target>]')
    return
  end

  local function run(target)
    coroutine.wrap(function()
      local tree = Tree(target, rule_set.rules)

      if not tree then
        print('error: no recipe for building target "' .. target .. '"')
        return
      end

      if tree.complete then
        print('nothing to be done for target "' .. target .. '"')
      end

      build_tree(tree)
    end)()
  end

  setfenv(loadfile(args[1]), setmetatable({
    rule = rule_set.add_rule,
    target = rule_set.add_phony,
    fs = require 'coro-fs',
    exec = require './src/util/exec',
    include = require './src/util/include'
  }, {
    __index = _G
  }))()

  run(args[2] or 'all')
end
