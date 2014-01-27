require 'rubygems'
require 'optparse'
require 'yaml'

#desc "Create new post with given title and category"
task :np do
  OptionParser.new.parse!
  ARGV.shift
  title = ARGV[0]
  category = ARGV[1]

  path = "config/jekyll/home/_posts/#{Date.today}-#{title.downcase.gsub(/[^[:alnum:]]+/, '-')}-#{category.upcase}.markdown"
  
  if File.exist?(path)
    puts "[WARN] File exists - skipping create"
  else
    File.open(path, "w") do |file|
      file.puts YAML.dump({'layout' => 'post', 'published' => false, 'title' => title.titleize , 'category' => "#{category}"})
      file.puts "---"
    end

    begin
      config = {'editor' => 'Espresso'}
      if File.exist?("#{Dir.home}/.bloggyrc")
        config.merge!(YAML.load_file("#{Dir.home}/.bloggyrc"))
      end
    rescue TypeError
      puts "[WARN] Failed to parse editor from .bloggyrc"
    end
    
    begin
    `open -a #{config['editor']} #{path}`
    rescue Exception
      puts "[WARN] Could not find editor #{config['editor']} - please edit #{path} manually"
    end

  end

  exit 1
end

desc "Create New Internship Post"
task :new_internship_post do 
	OptionParser.new.parse!
	ARGV.shift
	title = ARGV.join(' ')
	
	path = "config/jekyll/internship/_posts/#{Date.today}-#{title.downcase.gsub(/[^[:alnum:]]+/, '-')}.markdown"
	
	if File.exist?(path)
	  puts "[WARN] File exists - skipping create"
	else
	  File.open(path, "w") do |file|
	    file.puts YAML.dump({'layout' => 'post', 'published' => false, 'title' => title.titleize, 'category' => "internship"})
	    file.puts "---"
	  end
	
    begin
      config = {'editor' => 'Espresso'}
      if File.exist?("#{Dir.home}/.bloggyrc")
        config.merge!(YAML.load_file("#{Dir.home}/.bloggyrc"))
      end
    rescue TypeError
      puts "[WARN] Failed to parse editor from .bloggyrc"
    end
    
    begin
    `open -a #{config['editor']} #{path}`
    rescue Exception
      puts "[WARN] Could not find editor #{config['editor']} - please edit #{path} manually"
    end

  end

  exit 1
end
	