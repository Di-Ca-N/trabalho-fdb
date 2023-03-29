import pathlib
import psycopg
import os
from contextlib import contextmanager


@contextmanager
def get_connection():
    """Connect to the database and return the connection."""

    # Get the credentials from environment variables, using the defaults if missing
    user = os.environ.get("DB_USER", "postgres")
    dbname = os.environ.get("DB_NAME", "pokemon")
    host = os.environ.get("DB_HOST", "127.0.0.1")
    password = os.environ.get("DB_PASSWORD", "postgres")

    # This function uses the context manager interface and yield
    # to ensure the connection is always closed.
    # Another alternative would be to return the connection and
    # call 'close' explicitly.
    with psycopg.connect(
        user=user, dbname=dbname, host=host, password=password
    ) as conn:
        yield conn


def run_sql_script(script_path):
    """Connect to the database and execute an SQL script using the provided connection

    Arguments:
        conn (psycopg.Connection): Connection to the database
        script_path (str): Path to the script to be executed
    """
    with get_connection() as conn:
        script_file = pathlib.Path(script_path)
        with conn.cursor() as cur:
            script = script_file.read_text(encoding="utf-8")
            cur.execute(script)

        # Persist the changes
        conn.commit()


def run_sql_query(conn, query, parameters):
    """Connect to the database, run an SQL query and return the result as a list

    Arguments:
        conn (psycopg.Connection): Connection to the database
        query (str): Query to be executed

    Returns: List of records (Any)
    """

    parameters = parameters or []
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, parameters)
            return list(cur)