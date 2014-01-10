desc 'Make necessary file switches for production mode'
task :jekyll_production do
  Dir.chdir("config/jekyll") do
  	system('rm _config.yml')
  	system('cp _config.production.yml _config.yml')
  	system('sh watch.sh')
    system('jekyll build')
    system('git add .')
	system('git commit -a -m "Production Changes"')
	system('git push')
	system('cap deploy')
	system('rm _config.yml')
	system('cp _config.development.yml _config.yml')    
  end
end