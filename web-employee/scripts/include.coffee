util = require('util')
fs = require('fs')
_ = require('underscore')
coffee = require('coffee-script')

concatenate = (sourceFile, includeDirectories) ->
  fileDirectiveRegex = /#=\s*include (.*)/g
  output = fs.readFileSync(sourceFile).toString()
  mfile = '\n' + output
  while (result = fileDirectiveRegex.exec(mfile)) != null
    file = null
    for dir in includeDirectories
      files = require('findit').sync("#{dir}/#{result[1]}")
      file = files[0]
      contents = ""
      if ".js" in result[1]
        contents += fs.readFileSync(file).toString()
      else
        contents += coffee.compile fs.readFileSync(file).toString(), bare:true
      output = output.replace result[0], contents
  util.puts output

args = process.argv[2..]
unless args.length > 0
  console.log('Usage: coffee coffeescript-include.coffee [-I .] a.coffee')
  process.exit(1)

includeDirectories = []
sourceFiles = []

readingIncludes = true
i = 0
while readingIncludes and i < args.length
	if args[i] == '-I' or args[i] == '--include-dir'
		i++
		dir = args[i++]
		unless dir[dir.length-1] == ('/')
			dir += '/'
		includeDirectories.push(dir)
	else
		readingIncludes = false
while i < args.length
  concatenate(args[i++], includeDirectories)
