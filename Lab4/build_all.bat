@echo off
set PGPASSWORD=secret
set PSQL="C:\Program Files\PostgreSQL\18\bin\psql.exe"

%PSQL% -h localhost -p 5432 -U postgres -d Lab4 -f sql\drop_sqema.sql

%PSQL% -h localhost -p 5432 -U postgres -d Lab4 -f sql\create_schema.sql

%PSQL% -h localhost -p 5432 -U postgres -d Lab4 -f sql\seed_data.sql

%PSQL% -h localhost -p 5432 -U postgres -d Lab4 -f sql\data_test.sql

pause