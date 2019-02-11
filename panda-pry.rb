require 'canvas-api'
require 'pry'
require 'csv'
require 'pp'
#require 'quality_extensions'

puts "                                                    ,,,         ,,,      "
puts '                                                  ;"   ^;     ;^   ",    '
puts '                                                 ;     s$$$$$$$s     ;   '
puts "             P  A  N  D  A                        ,  ss$$$$$$$$$$s  ,'   "
puts "                                                  ;s$$$$$$$$$$$$$$$      "
puts "             P  R  Y                              $$$$$$$$$$$$$$$$$$     "
puts '                                                 $$$$P""Y$$$Y""W$$$$$    '
puts '                                                 $$$$  p"$$$"q  $$$$$    '
puts "                           ______                $$$$  .$$$$$.  $$$$     "
puts "        |\_______________ (_____\\______________    $$$$$$$$$$$$$$$$$    "
puts 'HH======#H###############H#######################   "Y$$$"*"$$$Y"        '
puts '        ` ~""""""""""""""`##(_))#H\"""""Y########      "$b.$$"           '
puts '                          ))    \#H\       `"Y###                        '
puts '                          "      }#H)                              v0.1  '
puts ""

# initiate canvas-api
$domain = "https://pony.instructure.com"
$api_token = ""
$canvas = Canvas::API.new(:host => "#{$domain}", :token => "#{$api_token}")

$counter = 0

$buffers = {}

def create_buffer(input)
	buffer_name = "buffer_#{$counter}"
	$buffers.merge!(buffer_name => input)
	puts "buffer_#{$counter}"
	$counter += 1
end

def startup()
	binding.pry
end

Commands = Pry::CommandSet.new do

	# set token command
	# feature idea: add a -s flag to save the token locally
	create_command "token" do
		description "Sets the token for the session: token [api_token]."
		def process
			# not sure if this is the *best* way to handle this, but it works for here at least
			# history lesson: anything entered after the command name is stored in an array titled args
			$api_token = args[0]
    		output.puts "token set"
		end
	end

	# set instance
	create_command "inst" do
		description "Sets the instance for the session: instance [instance_name]."
		banner <<-BANNER
			Usage: instance [instance_name]

			Sets the instance for the session.
			Can accept just instance name: [instance_name].instructure.com
			Or full URL: cheeky.aussies.edu.au | https://cheeky.aussies.edu.au
		BANNER
		def process
			if args[0].include? "."
				if args[0].include? "https://"
					$domain = args[0]
					output.puts "instance set"
				else
					$domain = "https://#{args[0]}"
					output.puts "instance set"
				end
			else
				$domain = "https://#{args[0]}.instructure.com"
				output.puts "instance set"
			end
		end
	end

	create_command "GET" do
		description "stores JSON from endpoint in an array."
		banner <<-BANNER
			Usage: GET [-p <integer> | -a ] /api/v1/<endpoint> 

			Stores JSON data returned from endpoint in an array, outputs array's name.
		BANNER
		def options(opt)
			opt.on :p, :pages, "Set the number of pages to retrieve, e.g. -p 5"
			opt.on :a, :allthethings, "retrieve all data on the provided endpoint"
			# note :all is apparently reserved namespace and breaks things if you use it
		end
		def process
    		raise Pry::CommandError, "-a and -p cannot be passed together" if opts.allthethings? && opts.pages?			
    		output = []

			if opts.pages? == true
				total_pages = args[0].to_i
				get_data = $canvas.get("#{args[1]}")
				get_data.each {|x| output.push(x)}
				page_count = 1

				if page_count < total_pages
					loop do
						get_data.next_page!.each {|x| output.push(x)}
						page_count += 1
						break if page_count == total_pages
					end
				end

			elsif opts.allthethings? == true
				puts 
				get_data = $canvas.get("#{args[0]}")
				get_data.each {|x| output.push(x)}	

				if get_data.more?
					loop do
						get_data.next_page!.each {|x| output.push(x)}
						break if get_data.more? == false
					end
				end
			else
				get_data = $canvas.get("#{args[0]}")
				get_data.each {|x| output.push(x)}
			end
			create_buffer(output)	
		end
	end

	create_command "!" do
		description "Pretty prints buffer: ! <buffer name>."
		def process
			#!TODO probs find a better way to handle pretty print.
			pp $buffers.fetch(args[0])
		end
		# this opens up an opportunity/problem for some neat interpolating stuffs
	end


	create_command "CSV" do
		description "Writes a CSV file of given buffer"
		banner <<-BANNER
			Usage: CSV <buffer_name>

			Writes the JSON data stored in a buffer to a CSV file. 
			Defaults do your downloads directory
		BANNER
		def process
			CSV.open("Downloads/#{args[0]}.csv", "wb") do |csv|
  				csv << $buffers.fetch(args[0]).first.keys # adds the attributes name on the first line
  				$buffers.fetch(args[0]).each do |hash|
    				csv << hash.values
  				end
			end
  		end
	end


 # this end belongs to `Commands = Pry::CommandSet.new do`
end


Pry.commands.import Commands

# initiate pry
startup()
