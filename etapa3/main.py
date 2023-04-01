from os import path
from db_utils import run_sql_query, run_sql_script, get_connection, run_query_and_commit
from queries import (
    ask_user_for_query,
    display_records,
    display_db_state,
    trigger_update,
)
import psycopg


def main():
    print("========================================")
    print("============ POKEMON GO ================")
    print("========================================")

    run = True

    while run:
        print()
        print("1. Popular o banco de dados")
        print("2. Executar query")
        print("3. Testar gatilho")
        print("0. Sair")
        option = input("> ")

        print()

        if option == "1":
            populate_db()
        elif option == "2":
            handle_queries()
        elif option == "3":
            handle_trigger()
        elif option == "0":
            run = False
        else:
            print("Opção inválida")


def populate_db():
    """Configure the schema, views, triggers and insert instances into the database"""
    print("Adicionando instâncias, views e triggers ao banco de dados...")
    with get_connection() as conn:
        absolute_path = path.dirname(__file__)
        run_sql_script(conn, path.join(absolute_path, "./sql/instancias.sql"))
        run_sql_script(conn, path.join(absolute_path, "./sql/view_and_trigger.sql"))
    print("Pronto!")


def handle_queries():
    query = ask_user_for_query()

    with get_connection() as conn:
        records = query.run(conn)

    display_records(query.description, records)


def handle_trigger():
    """Display the effect of the trigger on the database

    This function shows the state of the database before the trigger is executed,
    it executes an update to run the trigger, and then shows the state after the trigger
    is executed"""

    with get_connection() as conn:
        print("Estado do banco de dados antes do gatilho:")
        records = run_sql_query(conn, display_db_state)
        display_records(
            "ID, nome, vida, motivação e ginásio do Pokémon com id=1", records
        )

        print(
            "Executando atualização: definindo a motivação do Pokémon com id=1 para 0"
        )
        try:
            run_query_and_commit(conn, trigger_update)
        except psycopg.errors.CheckViolation:
            print(
                ">>> O Pokémon com id 1 não está defendendo nenhum ginásio.\n"
                ">>> Por favor, redefina os registros da base da dados"
            )
            return

        print("Estado do banco de dados depois do gatilho:")
        records = run_sql_query(conn, display_db_state)
        display_records(
            "ID, nome, vida, motivação e ginásio do Pokémon com id=1", records
        )


if __name__ == "__main__":
    main()
