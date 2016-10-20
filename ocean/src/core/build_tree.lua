local function execute(tree)
  if not tree.complete then
    tree.rule.builder(tree.target, tree.match)
    tree.complete = true
    for _, subscriber in ipairs(tree.rule.subscribers[tree.target] or {}) do
      subscriber()
    end
  end
end

local function build_tree(tree)
  if tree.scheduled or tree.complete then return end

  tree.scheduled = true

  local todo_dep_count = 0
  local deps_to_build = {}

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
      table.insert(deps_to_build, dep)
    end
  end

  for _, dep in ipairs(deps_to_build) do
    build_tree(dep)
  end

  if todo_dep_count == 0 then
    execute(tree)
  end
end

return build_tree
