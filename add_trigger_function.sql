-- Function to automatically add audit triger to the tables created in the schema
CREATE OR REPLACE FUNCTION add_trigger_func()
RETURNS event_trigger
LANGUAGE plpgsql volatile as
$$
DECLARE
    obj record;
    identity text[];
begin
    FOR obj in SELECT * FROM pg_event_trigger_ddl_commands() WHERE object_type = 'table'
    LOOP
        -- if create table and table name begins with "user_", automatically create user_id column
        IF obj.command_tag = 'CREATE TABLE' THEN
            EXECUTE FORMAT('SELECT audit.audit_table(%L)', obj.object_identity);
        END IF;
    END LOOP;
END
$$;

-- Create an event trigger with the function
--
-- The table name is unfortunately available only AFTER the DDL command
-- has executed for PSQL functions. However, it is available on ddl_command_start
-- if writing a C extention
CREATE EVENT TRIGGER add_trigger
ON ddl_command_end
WHEN TAG in('CREATE TABLE')
EXECUTE PROCEDURE add_trigger_func();
