target('all', 'test/build/app.lib')

include('./test.compile.lk.lua')

rule('test/build', {}, function()
  print('Creating build directory...')
  fs.mkdirp('test/build')
end)

rule('test/build/a.o', { 'test/src/a.c', 'test/build' }, function(target)
  print('Compiling ' .. target .. '...')
  exec('touch ' .. target)
end)

rule('test/build/app.lib', { 'test/build/a.o', 'test/build/b.o', 'test/build/c.o', 'test/build' }, function(target)
  print('Linking ' .. target .. '...')
  exec('touch ' .. target)
end)
