require 'canvas-api'
require 'pry'
require 'csv'
require 'pp'

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
#!TODO don't forget about your hardcoded values for testing
$domain = "https://pony.instructure.com"
$api_token = ""
#!TODO fucntion-ify this — this needs to be re0iniitated everytime a new instance is set
$canvas = Canvas::API.new(:host => "#{$domain}", :token => "#{$api_token}")

$counter = 0
$selection_counter = 0

$buffers = {}

def create_buffer(input)
  buffer_name = "buffer_#{$counter}"
  $buffers.merge!(buffer_name => input)
  puts "buffer_#{$counter}"
  $counter += 1
end

def create_selection(input)
  selection_name = "selection_#{$selection_counter}"
  $buffers.merge!(selection_name => input)
  puts "selection_#{$selection_counter}"
  $selection_counter += 1
end

def startup()
  binding.pry
end

Commands = Pry::CommandSet.new do

  create_command "token" do
    description "Sets the token for the session: token [api_token]."
    def process
      # not sure if this is the *best* way to handle this, but it works for here at least
      # history lesson: anything entered after the command name is stored in an array titled args
      $api_token = args[0]
        output.puts "token set"
    end
  end

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
    description "Stores JSON from endpoint in an array."
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
      # apparently this breaks when the script is in the root directory, but works when in Downloads
      CSV.open("Downloads/#{args[0]}.csv", "wb") do |csv|
          csv << $buffers.fetch(args[0]).first.keys # adds the attributes name on the first line
          $buffers.fetch(args[0]).each do |hash|
            csv << hash.values
          end
      end
      end
  end

  create_command "select" do
    description "Creates an array contain all values of given key in a buffer."
    banner <<-BANNER
      Usage: select <buffer name> <key> [-w / --where] <key> (operator) <value>
      
      Creates a flat array containing all values for the provided <key> in the provided buffer
      -w --where : Optional — filters which values will be added to the array
      
      Example: select buffer_0 user_id --where sis_import_id = 1234
      => will create a array containg all user_id values in buffer_0 that have a sis_import_id of 1234

      Allowed operators: = , != , > , < , contains , !contains
    BANNER

    def options(opt)
      opt.on :w, :where, "allows user to pass a conditional statement to filter which values are added to the selection."
    end

    def process
      #!TODO do some error handling here to ensure format is valid
      selection_output = []

      # select <buffer> <key> -w <key> <operator> <value>
      #        args[0] args[1]  args[2] args[3]    args[4]
    
      if opts.where?	
        key = args[1]
        filter_key = args[2]
        operator = args[3].to_s
        allowed_operators = ["=","!=","equals","!equals",">","<","contains","!contains"]
        filter_value = args[4]
        #!TODO first things first, do some error handling to ensure -w arguments are valid
        # after, probs use a case statement to handle what to do fo' each operator
        if allowed_operators.include? operator == false
          raise Pry::CommandError, "Error: invalid operator. Allowed operators: = , != , > , < , contains , !contains"  
        end
        # literally none of this works :D
        case operator
        when "="
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            if x.fetch(filter_key).to_s == filter_value
              selection_output.push(value) 
            end
          end
        when "!="# | "!equals"
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            if x.fetch(filter_key).to_s != filter_value
              selection_output.push(value) 
            end
          end
        when ">"
          # these operators will need:
          # 1. to turn everything into a integer, not a string like everything else
          # 2. error messaging if non integer value is passed
        when "<"

        end

        create_selection(selection_output)
      else
        $buffers.fetch(args[0]).each do |x|
          selection_output.push(x.fetch(args[1]))
        end
        
        create_selection(selection_output)

      end

    end
  end

 # this end belongs to `Commands = Pry::CommandSet.new do`
end

Pry.commands.import Commands

# initiate pry
startup()

