describe('util.exec', function()
  local proxyquire = require 'deps/proxyquire'

  local spawn_waitExit = spy.new(load'')
  local spawn = spy.new(function()
    return {
      waitExit = spawn_waitExit
    }
  end)

  local exec = proxyquire('util.exec', {
    ['coro-spawn'] = spawn
  })

  it('should spawn commands with no arguments', function()
    exec('ls')

    assert.spy(spawn).was_called_with('ls', match.is_same({ args = {} }))
    assert.spy(spawn_waitExit).was_called()
  end)

  it('should spawn commands with arguments', function()
    exec('mv abc 123')

    assert.spy(spawn).was_called_with('mv', match.is_same({ args = { 'abc', '123' } }))
    assert.spy(spawn_waitExit).was_called()
  end)
end)
