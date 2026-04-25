$ErrorActionPreference = "Stop"

$env:PGHOST = "localhost"
$env:PGPORT = "5432"
$env:PGDATABASE = "Lab4"
$env:PGUSER = "postgres"
$env:PGPASSWORD = 

$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"

& $psql -f sql\drop_sqema.sql
& $psql -f sql\create_schema.sql
& $psql -f sql\seed_data.sql
& $psql -f sql\trigger1.sql
& $psql -f sql\trigger2.sql
& $psql -f sql\procedure1.sql
& $psql -f sql\procedure2.sql
py sql\fill_data.py
