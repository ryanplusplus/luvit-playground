describe('util.include', function()
  local include = require 'util.include'

  bar = spy.new(load'')

  it('should load the specified file in the current environment', function()
    local foo = spy.new(load'')

    include('spec/util/include_helper.lua')
    assert.spy(foo).was_called_with(1, 2, 3)
    assert.spy(bar).was_called_with('a', 'b', 'c')
  end)

  it('should load a relative file in the current environment', function()
    local foo = spy.new(load'')

    include('./include_helper.lua')
    assert.spy(foo).was_called_with(1, 2, 3)
    assert.spy(bar).was_called_with('a', 'b', 'c')
  end)
end)
