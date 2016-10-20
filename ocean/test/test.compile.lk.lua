rule('test/build/*.o', { 'test/src/*.c', 'test/build' }, function(target, match)
  print('Compiling ' .. target .. ' with generic rule...')
  exec('touch ' .. target)
end)
