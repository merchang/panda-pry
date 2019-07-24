# panda-pry
A simple and hacky tool for interacting with the Canvas API, built using Pry's [custom command system](https://github.com/pry/pry/wiki/Custom-commands)

### Available Commands
- **inst:** sets the canvas instance for the session. Accepts both full URLS, and subdomains.
-- ex: `inst pony` , `inst pony.instructure.com` & `https://pony.instructure.com`  are all acceptable ways for setting the domain 'pony.instructure.com' 
- **token:** sets a Canvas API  token for the session.
- **GET:** makes a GET request to the provided endpoint. Outputs a buffer name that stores the JSON response data from the call.
    - Accepts two arguments: `-a` : paginates through all pages of the endpoint. `-p <integer>` paginates over the endpoint x times.
    - ex: `GET /api/v1/courses/123/enrollments -a`
- **flatten:** flattens all nested JSON in a buffer, outputs a new buffer.
- **select:** creates an array containing all values of a given key in a buffer. Can conditionally select values.
    - `select <buffer_name> <key to collect> [-w / --where] <key to filter by> <operator> <value>`
    - ex: `select buffer_2 sis_user_id --where email !contains @pony.gov` => will output an array titled 'selection_0' containing the sis_user_id of all JSON objects in 'buffer_2' whose 'email' value does not contain the '@pony.gov' substring. 
    - allowed operators: `=` , `!=` , `>` , `<` , `contains` , `!contains`
- **!:** pretty prints a buffer or selection in the console.
- **CSV:** generates a CSV file for a given buffer
- **open:** ingests a CSV file, converting data into a new buffer. Outputs buffer name.
 	- ex: `open /path/to/file.csv`
- **YEET:** accepts a selection, http method, & endpoint. Iterates over the provided selection, substituting 'yeet' passed in the endpoint with values in the selection.
	- ex: `YEET selection_0 DELETE /api/v1/users/sis_user_id:yeet` will delete all users collected in 'selection_0'
