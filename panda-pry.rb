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
$domain = "https://pony.instructure.com"
$api_token = ""
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

def output_helper(response, output)
  if response.class == Hash
    output.push(response)
  else 
    response.each {|r| output.push(r)}
  end
end

def flatten_hash(hash, results = {}, parent_key = '')
  hash.each_with_object({}) do |(k, v), h|
    if v.is_a? Hash
      flatten_hash(v).map do |h_k, h_v|
        h["#{k}.#{h_k}"] = h_v
      end
    else 
      h[k] = v
    end
 end
end

def spinner(fps=10)
  chars = %w[| / - \\]
  delay = 1.0/fps
  iter = 0
  spinner = Thread.new do
	while iter do  # Keep spinning until told otherwise
	  print chars[(iter+=1) % chars.length]
	  sleep delay
	  print "\b"
	end
  end
  yield.tap{       # After yielding to the block, save the return value
	iter = false   # Tell the thread to exit, cleaning up after itself…
	spinner.join   # …and wait for it to do so.
  }                # Use the block's return value as the method's
end


def startup()
  puts "enter 'plshelp' at anytime for a complete list of commands"
  binding.pry
end

Commands = Pry::CommandSet.new do

  create_command "token" do
    description "Sets the token for the session: token [api_token]."
    def process
      # history lesson: anything entered after the command name is stored in an array titled args
      $api_token = args[0]
      $canvas = Canvas::API.new(:host => "#{$domain}", :token => "#{$api_token}")
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
      $canvas = Canvas::API.new(:host => "#{$domain}", :token => "#{$api_token}")
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
      spinner {
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
        output_helper(get_data, output)
      end
      }
      create_buffer(output)	
    end
  end

  create_command "!" do
    description "Pretty prints buffer: ! <buffer name>."
    def process
      puts JSON.pretty_generate($buffers.fetch(args[0]))
    end
  end

  create_command "flatten" do
    description "Flattens all nested JSON in a buffer."
    banner <<-BANNER
      Usage: flaten <buffer_name>
      
      Creates a new buffer with the same information as the provided buffer. All JSON objects in the new buffer will be flattened. 
      example: all fields nested inside of a 'user' field will be written to the CSV with a header of 'user.<field_name>'
    BANNER

    def process
      input = $buffers.fetch(args[0])
      output = []
      input.each { |x| output.push(flatten_hash(x)) }
      create_buffer(output)
    end
  end


  create_command "plshelp" do
    description "List all avalilbe commands."
    def process
      puts <<-plshelp
        You may enter '<command_name> -h' at anytime for a complete description of the command
        ======================================================================================

        inst: sets the canvas instance for the session
        
        token: sets a token for the session
        
        GET: makes a GET request to the provided endpoint. Outputs a buffer name that stores the JSON response of the call.
        
        flatten: flattens all nested JSON in a buffer. 

        select: creates an array containing all values of a given key in a buffer. Can conditionally select values.
        
        !: pretty prings a buffer or selection.
        
        CSV: generates a csv file for a given buffer

        open: ingests a CSV file, converting data into a new buffer. Outputs buffer name.
        
        YEET: accepts a selection, http method, & endpoint. iterates over the provided selection.

      plshelp
    end
  end


  create_command "CSV" do
    description "Writes a CSV file of given buffer"
    banner <<-BANNER
      Usage: CSV <buffer_name>

      Writes the JSON data stored in a buffer to a CSV file. 
      Outputed file will be save in the directory panda-pry was initiated in.
      Note: Nested JSON objects will be flattened. ex) all fields nested inside of a 'user'
      field will be written to the CSV with a header of 'user.<field_name>'
    BANNER
    def process
      CSV.open("#{args[0]}-#{Time.now.to_i}.csv", "wb") do |csv|
          input = $buffers.fetch(args[0])
          csv << flatten_hash(input.first).keys # adds the attributes name on the first line
          input.each do |hash|
            output = flatten_hash(hash)
            csv << output.values
          end
      end
    end
  end

    create_command "open" do
      description "Ingests a CSV, creates buffer of CSV data"
      banner <<-BANNER
        Usage: open </path/to/file.csv>
        Ingests a CSV file, converting data into a new buffer. Outputs buffer name.
        Note: command assumes provided CSV contains headers.
      BANNER
      def process
        input = CSV.open(args[0], headers: :first_row).map(&:to_h)
        output = []
        output_helper(input, output)
        create_buffer(output)
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

      Note: in order to select a nested JSON feild, you will first need to flatten the buffer. See 'flatten -h'
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
        allowed_operators = ["=","!=",">","<","contains","!contains"]
        args[4] = '' if args[4] == 'nil' || args[4] == 'null'
        filter_value = args[4]

        if allowed_operators.include? operator == false
          raise Pry::CommandError, "Error: invalid operator. Allowed operators: = , != , > , < , contains , !contains"  
        end
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
          if filter_value.to_i.to_s != filter_value 
            raise Pry::CommandError, "Error: filter-value must be an integer when using the '>' '<' operators.operators" 
          end
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            if x.fetch(filter_key).to_i > filter_value.to_i
              selection_output.push(value)
            end
          end

        when "<"
          if filter_value.to_i.to_s != filter_value 
            raise Pry::CommandError, "Error: filter-value must be an integer when using the '>' '<' operators.operators" 
          end
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            if x.fetch(filter_key).to_i < filter_value.to_i
              selection_output.push(value)
            end
          end
      
        when "contains"
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            if x.fetch(filter_key).include? filter_value
              selection_output.push(value)
            end
          end

        when "!contains"
          $buffers.fetch(args[0]).each do |x|
            value = x.fetch(key)
            unless x.fetch(filter_key).include? filter_value
              selection_output.push(value)
            end
          end
        end

        create_selection(selection_output)
      else
        $buffers.fetch(args[0]).each do |x|
          selection_output.push(x.to_s.fetch(args[1]))
        end
        
        create_selection(selection_output)

      end

    end
  end

  create_command "YEET" do
    description "Executes an API call, replacing 'yeet' with the provided selection value(s)"
    banner <<-BANNER
      Usage: YEET <selection_name> <http_method> /api/v1/endpoint/yeet/
      
      Iterates over a provided selection buffer, replace 'yeet' in the provided call with
      the values of the selection buffer. Outputs a buffer containing the response bodies
      of each call that was made.
      "dis bish empty! YEET!"
    BANNER
    def process
      method = args[1].upcase
      call = args[2]
      output = []
      $buffers.fetch(args[0]).each do |x|
        puts method + " " + call.gsub('yeet', x.to_s) + " ✓"
        case method
        when "GET"
          response = $canvas.get(call.gsub('yeet', x.to_s))
          ouput_helper(response, output)
        when "PUT"
          response = $canvas.put(call.gsub('yeet', x.to_s))
          ouput_helper(response, output)
        when "DELETE"
          response = $canvas.delete(call.gsub('yeet', x.to_s))
          ouput_helper(response, output)
        when "POST"
          response = $canvas.delete(call.gsub('yeet', x.to_s))
          ouput_helper(response, output)
        else
          puts "HTTP Method not reconized, allowed methods: GET, PUT, POST, DELETE"
        end
      end
      create_buffer(output)
    end
  end


 # this end belongs to `Commands = Pry::CommandSet.new do`
end

Pry.commands.import Commands

# initiate pry
startup()

