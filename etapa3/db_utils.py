import pathlib
import psycopg
import os
from contextlib import contextmanager


@contextmanager
def get_connection():
    """Connect to the database and return the connection."""

    # Get the credentials from environment variables. If missing, use the defaults instead
    user = os.environ.get("DB_USER", "pokemon")
    dbname = os.environ.get("DB_NAME", "pokemon")
    host = os.environ.get("DB_HOST", "127.0.0.1")
    password = os.environ.get("DB_PASSWORD", "pokemon")

    # This function uses the context manager interface and yield
    # to ensure the connection is always closed after it is used.
    # Another alternative would be to return the connection and
    # call 'close' explicitly.
    with psycopg.connect(
        user=user, dbname=dbname, host=host, password=password
    ) as conn:
        yield conn


def run_sql_script(conn, script_path):
    """Execute an SQL script using the provided connection

    Arguments:
        conn (psycopg.Connection): Connection to the database
        script_path (str): Path to the script to be executed
    """

    script_file = pathlib.Path(script_path)
    with conn.cursor() as cur:
        script = script_file.read_text(encoding="utf-8")
        cur.execute(script)

    # Persist the changes
    conn.commit()


def run_sql_query(conn, query, parameters=None):
    """Run an SQL query using the provided connection

    Arguments:
        conn (psycopg.Connection): Connection to the database
        query (str): Query to be executed
        parameters (Optional[Iterable]): parameters to the query

    Returns: List of records (Any)
    """

    parameters = parameters or []

    with conn.cursor() as cur:
        cur.execute(query, parameters)
        return list(cur)
