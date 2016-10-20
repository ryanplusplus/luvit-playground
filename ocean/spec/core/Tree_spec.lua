describe('core.Tree', function()
  local proxyquire = require 'deps/proxyquire'
  local files
  local fs = {
    stat = function(file)
      return files[file]
    end
  }

  local Tree = proxyquire('core.Tree', {
    ['coro-fs'] = fs
  })

  before_each(function()
    files = {}
  end)

  it('should return nothing when there are no rules', function()
    local tree = Tree('foo', {})

    assert.is_nil(tree)
  end)

  it('should return nothing when there is no rule for the target', function()
    local tree = Tree('foo', {
      { target = 'bar', deps = {} }
    })

    assert.is_nil(tree)
  end)

  it('should return nothing when the target is not buildable because of a missing dependency', function()
    local tree = Tree('foo', {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} }
    })

    assert.is_nil(tree)
  end)

  it('should create a completed tree when the target exists and is up-to-date', function()
    files = {
      foo = { mtime = { sec = 3, nsec = 0 } },
      bar = { mtime = { sec = 2, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      complete = true,
      rule = rules[1],
      deps = {}
    }, tree)
  end)

  it('should create an incomplete tree when the target exists but is not up-to-date', function()
    files = {
      foo = { mtime = { sec = 1, nsec = 0 } },
      bar = { mtime = { sec = 2, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {}
    }, tree)
  end)

  it('should create an incomplete tree when the target exists but is not up-to-date due to nanoseconds', function()
    files = {
      foo = { mtime = { sec = 2, nsec = 0 } },
      bar = { mtime = { sec = 2, nsec = 1 } },
      baz = { mtime = { sec = 2, nsec = 1 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {}
    }, tree)
  end)

  it('should create an incomplete tree when the target does not exist', function()
    files = {
      bar = { mtime = { sec = 2, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {}
    }, tree)
  end)

  it('should create a completed tree when the target does not exist but is phony', function()
    files = {
      bar = { mtime = { sec = 2, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' }, phony = true },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      complete = true,
      rule = rules[1],
      deps = {}
    }, tree)
  end)

  it('should create an incomplete tree when a dependency does not exist', function()
    files = {
      foo = { mtime = { sec = 3, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {
        {
          target = 'bar',
          match = 'bar',
          rule = rules[2],
          deps = {}
        }
      }
    }, tree)
  end)

  it('should create an incomplete tree when a dependency does not exist and the target is phony', function()
    files = {
      foo = { mtime = { sec = 3, nsec = 0 } },
      baz = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' }, phony = true },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {
        {
          target = 'bar',
          match = 'bar',
          rule = rules[2],
          deps = {}
        }
      }
    }, tree)
  end)

  it('should create a incomplete tree when the target and its dependencies do not exist', function()
    files = {}

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = {} }
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {
        {
          target = 'bar',
          match = 'bar',
          rule = rules[2],
          deps = {}
        },
        {
          target = 'baz',
          match = 'baz',
          rule = rules[3],
          deps = {}
        }
      }
    }, tree)
  end)

  it('should create multi-level trees', function()
    files = {
      quux = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = {} },
      { target = 'baz', deps = { 'qux' } },
      { target = 'qux', deps = { 'quux' } },
      { target = 'quux', deps = { } },
    }

    local tree = Tree('foo', rules)

    assert.are_same({
      target = 'foo',
      match = 'foo',
      rule = rules[1],
      deps = {
        {
          target = 'bar',
          match = 'bar',
          rule = rules[2],
          deps = {}
        },
        {
          target = 'baz',
          match = 'baz',
          rule = rules[3],
          deps = {
            {
              target = 'qux',
              match = 'qux',
              rule = rules[4],
              deps = {}
            },
          }
        }
      }
    }, tree)
  end)

  it('should create trees with wildcard rules', function()
    files = {
      ['a.c'] = { mtime = { sec = 2, nsec = 0 } },
      ['b.c'] = { mtime = { sec = 2, nsec = 0 } }
    }

    local rules = {
      { target = 'app.lib', deps = { 'a.o', 'b.o' } },
      { target = '*.o', deps = { '*.c' } }
    }

    local tree = Tree('app.lib', rules)

    assert.are_same({
      target = 'app.lib',
      match = 'app.lib',
      rule = rules[1],
      deps = {
        {
          target = 'a.o',
          match = 'a',
          rule = rules[2],
          deps = {}
        },
        {
          target = 'b.o',
          match = 'b',
          rule = rules[2],
          deps = {}
        }
      }
    }, tree)
  end)

  it('should ensure that identical sub-trees have reference equality', function()
    files = {}

    local rules = {
      { target = 'foo', deps = { 'bar', 'baz' } },
      { target = 'bar', deps = { 'qux' } },
      { target = 'baz', deps = { 'qux' } },
      { target = 'qux', deps = { } },
    }

    local tree = Tree('foo', rules)

    assert.are.equal(tree.deps[1].deps[1], tree.deps[2].deps[1])
  end)
end)
