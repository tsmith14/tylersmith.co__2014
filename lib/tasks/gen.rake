desc 'Run Jekyll in config/jekyll directory without having to cd there'''
task :generate do
  Dir.chdir("config/jekyll") do
  	Dir.chdir("internship") do
  		system('sh watch.sh')
  	end
    system('jekyll')
  end
end

desc 'Run Jekyll in config/jekyll/home directory without having to cd there'''
task :generate_home do
  Dir.chdir("config/jekyll/home") do
    system('jekyll --no-auto')
  end
  Rake::Task["generate_internship"].invoke
end

desc 'Run Jekyll in config/jekyll/internship directory without having to cd there'''
task :generate_internship do
  Dir.chdir("config/jekyll/internship") do
  	system('sh watch.sh')
    system('jekyll --no-auto')
  end
end
	

