#!/usr/bin/env ruby

require 'colorize'
require 'json'

class SqlPal

	def initialize
		@cmd = %q||
		@choice = %q||
		@json = {}
	end
	
	def go 
		# json menu
		n = 0
		menu_json = Dir.glob(%q|*.json|)
		
		unless menu_json.length > 0 then
			system %q|perl ./json-generator.pl|
			menu_json = Dir.glob(%q|*.json|)
		end
		
		loop do 
			# printf %Q|\033[2J|
			printf %Q|%s %s %s\n|, %q|~|*13, %q|DB TOOLS|, %q|~|*13
			menu_json.each_with_index do |v,k|
				printf %Q|%-2d ~ %s\n|, k, v.blue 
			end
			printf %Q|%s\n|, %q|~|*36
			printf %Q|%s: |, %q|choice|.yellow
			@choice = gets.chomp!
			
			next if @choice.match(%r~[[:alpha:]]~i)
			next unless menu_json[@choice.to_i]
			
			break
		end
		
		json_raw = File.read(menu_json[@choice.to_i])
		
		loop do 
			# printf %Q|\033[2J|
			printf %Q|%s %s %s\n|, %q|~|*13, %q|LOAD INFO|, %q|~|*12
			
			json_which = JSON.parse(json_raw)
			
			json_which.each do |k,v|
				if k.match(%r~^\d+$~) then
					printf %Q|%d ~ %s\n|, k.to_i, v.to_s.blue
				end
			end
			printf %Q|%s\n|, %q|~|*36
			printf %Q|%s: |, %q|choice|.yellow
			@choice = gets.chomp!
			next unless json_which[@choice]
			
			@json = json_which[@choice]
			@json['linuxuser'] = json_which['linuxuser']
			@json['sqlpass']   = json_which['sqlpass']
			
			break
		end
		
		loop do
			print %q|> | + %q|(b)ackup / (s)ql backup  / (r)estore mysql / (u)ntar / q(uit)|.downcase.yellow + %q|: |
			choice = gets.chomp!
			
			next unless choice.match(%r~^(?:b(?:ackup)?|(s(?:ql)?|r(?:estore)?)|u(?:ntar)?|q(?:uit)?)$~i)

			if (choice.match(%r~^b(?:ackup)?$~i)) then
			
				# todo: eventual use ruby internals for this
				@cmd = (<<~'CMD').gsub(%r~^$|\ {2,}|((?:\ )?\n(?:\ )?)~) { $1 ? %q| | : %q|| }
				
					mkdir -vp TIME_DATABASE 
					&& 
					cp -vr DIR TIME_DATABASE/ 
					&& 
					sudo mysqldump --user='root' --password='PASS' DATABASE > TIME_DATABASE/TIME_DATABASE.sql 
					&& 
					tar -cvzf TIME_DATABASE.tar.gz TIME_DATABASE 
					&& 
					rm -vr TIME_DATABASE
					
				CMD
				
				@cmd.strip!
				
			elsif choice.match(%r~^s(?:ql)?$~i)  
			
				@cmd = %q|sudo mysqldump --user='root' --password='PASS' DATABASE > TIME_DATABASE.sql|
				
			elsif choice.match(%r~^r(?:estore)?$~i) 
			
				menu_sql = Dir.glob(%q|*.sql|)
			
				unless menu_sql.length > 0 then
					printf %Q|> %s\n|, %q|no .sql so quitting|.red
					exit 69
				end
			
				loop do 

					# printf %Q|\033[2J|
					printf %Q|%s %s %s\n|, %q|~|*13, %q|SQL FILES|, %q|~|*13
					menu_sql.each_with_index do |v,k|
						printf %Q|%-2d ~ %s\n|, k, v.blue 
					end
					printf %Q|%s\n|, %q|~|*36
					printf %Q|%s: |, %q|choice|.yellow
					@choice = gets.chomp!
					
					next if @choice.match(%r~[[:alpha:]]~i)
					next unless menu_sql[@choice.to_i]
					
					break
				end
			
				@cmd = %q|sudo mysql -u'root' -p'PASS' 'DATABASE' < 'DBFILE'|
				@cmd.sub!(%r~DBFILE~,menu_sql[@choice.to_i])
				
			elsif choice.match(%r~^u(?:ntar)?$~i)
			
				menu_tar = Dir.glob(%q|*.tar.gz|)
				
				unless menu_tar.length > 0 then
					printf %Q|> %s\n|, %q|no .tar.gz so quitting|.red
					exit 69
				end
				
				loop do 
				
					printf %Q|\033[2J|
					printf %Q|%s %s %s\n|, %q|~|*13, %q|SQL FILES|, %q|~|*13
					menu_tar.each_with_index do |v,k|
						printf %Q|%-2d ~ %s\n|, k, v.blue 
					end
					printf %Q|%s\n|, %q|~|*36
					printf %Q|%s: |, %q|choice|.yellow
					@choice = gets.chomp!
					
					next if @choice.match(%r~[[:alpha:]]~i)
					next unless menu_tar[@choice.to_i]
					
					break
				end
						
				@cmd = %q|tar -xvzf TARBALL -C /var/www/|
				@cmd.sub!(%r~TARBALL~,menu_tar[@choice.to_i])
				
			elsif choice.match(%r~^q(?:uit)?$~i)
			
				puts %q|> | + %q|bye!|.red
				exit 69
			
			end
			
			@cmd.chomp!
			
			@cmd.gsub!(%r~USER|PASS|TIME|DATABASE|DIR|DATABASE~) do |m|
			
				if m.match(%r~^TIME$~) then 
				
					Time.now.to_i
					
				elsif m.match(%r~^DIR$~) then 
				
					%Q|/var/www/#{@json['webfolder']}|
					
				elsif m.match(%r~^DATABASE$~) then 
				
					@json['dbname']
					
				elsif m.match(%r~^USER$~) then 
				
					@json['dbuser']
					
				elsif m.match(%r~^PASS$~) then 
				
					@json['sqlpass']
					
				end
				
			end
		
			printf %Q|> %s\n|, @cmd.green
			
			printf %q|> %s: |, %q|do you want to proceed? [y/n]|.yellow
			doit = gets.chomp! 
			doit.match(%r~^y$~i) ? () : next
			system @cmd
		end
		
	end

end

go = SqlPal.new
go.go

__END__
