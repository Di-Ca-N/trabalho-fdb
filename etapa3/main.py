from db_utils import run_sql_query, run_sql_script


def main():
    print("========================================")
    print("============ POKEMON GO ================")
    print("========================================")

    run = True

    while run:
        print()
        print("1. Popular o banco de dados")
        print("2. Executar query sem parametro")
        print("3. Executar query com parametro")
        print("4. Testar gatilho")
        print("0. Sair")
        option = input()

        print()

        if option == "1":
            populate_db()
        elif option == "2":
            simple_queries()
        elif option == "3":
            parametrized_queries()
        elif option == "4":
            trigger()
        elif option == "0":
            run = False
        else:
            print("Opcao invalida")


def populate_db():
    """Apply the schema and instances to the database

    Arguments:
        conn (psycopg.Connection): connection to the database
    """
    print("Adicionando instancias ao banco de dados...")
    run_sql_script("../etapa2/instancias.sql")
    print("Pronto!")


def simple_queries():
    print("Selecione a consulta desejada:")
    print("1. Número de ginásios defendidos por cada time")

    # TODO


def parametrized_queries():
    print("Selecione a consulta desejada:")
    print("1. Verificar inventário de um jogador")

    # TODO

    option = input()

    print()

    if option == "1":
        inventory_query()
    else:
        print("Opcao invalida")


def inventory_query():
    print("------ Verificar inventário de um jogador ------")

    player_name = input("Nome do jogador: ")
    query = """
        SELECT Itens.nome, Itens.classe, Inventarios.quantidade
        FROM Itens 
            JOIN Inventarios ON Inventarios.item_id=Itens.id 
            JOIN Jogadores ON Inventarios.jogador_id=Jogadores.id
        WHERE Jogadores.nome=%s;
    """

    inventory = run_sql_query(query, [player_name])

    print(f"Inventário de '{player_name}':")
    for idx, (item, item_class, quantity) in enumerate(inventory, start=1):
        print(f"{idx}) {item} - {item_class} - {quantity}")

    print("------------------------------------------------")


def trigger():
    """Display the effect of the trigger on the database

    This function shows the state of the database before the trigger is executed,
    it executes an update to run the trigger, and then shows the state after the trigger
    is executed"""

    # TODO

    raise NotImplementedError


if __name__ == "__main__":
    main()
