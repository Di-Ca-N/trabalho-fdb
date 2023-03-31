from db_utils import run_sql_query, run_sql_script, get_connection
from queries import ask_user_for_query, display_records


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
        run_sql_script(conn, "./sql/instancias.sql")
        run_sql_script(conn, "./sql/view_and_trigger.sql")
    print("Pronto!")


def handle_queries():
    query = ask_user_for_query()

    with get_connection() as conn:
        records = run_sql_query(conn, query.sql)

    display_records(query.description, records)


def handle_trigger():
    """Display the effect of the trigger on the database

    This function shows the state of the database before the trigger is executed,
    it executes an update to run the trigger, and then shows the state after the trigger
    is executed"""

    # TODO

    raise NotImplementedError


if __name__ == "__main__":
    main()
