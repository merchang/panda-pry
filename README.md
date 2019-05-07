# panda-pry
A simple and hacky tool for interacting with the Canvas API, built using Pry's [custom command system](https://github.com/pry/pry/wiki/Custom-commands)

### Avalible Commands
- inst: sets the canvas instance for the session. Accepts both full URLS, and subdomains.
-- ex: `inst pony` , `inst pony.instructure.com` & `https://pony.instructure.com`  are all acceptable ways fo setting the domain 'pony.instructure.com' 
- token: sets a Canvas API  token for the session.
- GET: makes a GET request to the provided endpoint. Outputs a buffer name that stores the JSON response data from the call.
-- Accepets two arguments: `-a` : paginates through all pages of the endpoint. `-p <integer>` paginates over the endpoint x times.
-- ex: `GET /api/v1/courses/123/enrollments -a`
- flatten: flattens all nested JSON in a buffer, outputs a new buffer.
- select: creates an array containing all values of a given key in a buffer. Can conditionally select values.
-- select <buffer_name> <key to collect> [-w / --where] <key to filter by> <operator> <value>
-- ex: `select buffer_2 sis_user_id --where email !contains @pony.gov` => will output an array containing the sis_user_ids of all JSON objects in 'buffer_2' whose 'email' value does not contain the '@pony.gov' substring. 
-- allowed operators: `=` , `!=` , `>` , `<` , `contains` , `!contains`
- !: pretty prings a buffer or selection in the console.
- CSV: generates a csv file for a given buffer
- open: ingests a CSV file, converting data into a new buffer. Outputs buffer name.
- YEET: accepts a selection, http method, & endpoint. iterates over the provided selection.
