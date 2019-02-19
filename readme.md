# setup
## populate the databases
- run `oltp_create.sql`
- run `olap_create.sql`
- run `olap_etl.sql`

## update apps mysql password for DB access
- change contents in `password` file to match mysql password

## run the httpserver (choose one)
- `python3 httpserver.py`
`python3 -m http.server --bind localhost --cgi 8000`

## visit page from server
http://localhost:8000/app.html

# other tips
## run .py standalone in interpreter
`python3 -i cgi-bin/simple.py`