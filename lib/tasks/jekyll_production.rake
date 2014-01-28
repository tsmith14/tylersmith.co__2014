desc 'Make necessary file switches for production mode'
task :jekyll_production do
  Dir.chdir("config/jekyll/home") do
  	system('rm _config.yml')
  	system('cp _config.production.yml _config.yml')
  	system('jekyll')
  end
  Dir.chdir("config/jekyll/internship") do 
  	system('rm _config.yml')
  	system('cp _config.production.yml _config.yml')
  	system('sh watch.sh')
  	system('jekyll')
  end
  Dir.chdir(Rake.application.original_dir) do
  	puts Dir.pwd
  	system('git add .')
  	system('git commit -a -m "Production Changes"')
  	system('git push')
  	system('cap deploy')
  end
  Dir.chdir("config/jekyll/home") do
  	system('rm _config.yml')
  	system('cp _config.development.yml _config.yml')  
  end
  Dir.chdir("config/jekyll/internship") do 
  	system('rm _config.yml')
  	system('cp _config.development.yml _config.yml')  
  end 
  
end