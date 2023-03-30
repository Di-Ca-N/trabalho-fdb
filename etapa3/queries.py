from dataclasses import dataclass


@dataclass
class Query:
    description: str
    sql: str


simple_queries = [
    Query(
        "Número de ginásios defendidos por cada time",
        """
            SELECT time, COUNT(DISTINCT local_id)
            FROM Jogadores
                JOIN PokemonCapturados ON PokemonCapturados.treinador_id=Jogadores.id
                JOIN Ginasios ON Ginasios.local_id=PokemonCapturados.defensor_ginasio_id
            GROUP BY time;
        """
    ),
    Query(
        "Inventário do Jogador 1",
        """
        SELECT Itens.nome, Itens.classe, Inventarios.quantidade
        FROM Itens 
            JOIN Inventarios ON Inventarios.item_id=Itens.id 
            JOIN Jogadores ON Inventarios.jogador_id=Jogadores.id
        WHERE Jogadores.nome='Jogador 1';
        """
    ),
    Query(
        "Pokémon do Jogador 1 que podem evoluir",
        """
        SELECT PokemonCapturados.id, PokemonCapturados.nome, forma_pokemon.nome, Especies.nome, evolucao.custo_evolucao
        FROM PokemonCapturados
            JOIN Jogadores ON PokemonCapturados.treinador_id=Jogadores.id
            JOIN Inventarios ON Inventarios.jogador_id=Jogadores.id
            JOIN Itens ON Inventarios.item_id=Itens.id
            JOIN Formas forma_pokemon ON PokemonCapturados.forma_id=forma_pokemon.id
            JOIN Especies ON forma_pokemon.especie_id=Especies.id
            LEFT JOIN Formas evolucao ON evolucao.evolui_de=forma_pokemon.id
        WHERE Jogadores.nome='Jogador 1' AND itens.id=especies.doce_id AND inventarios.quantidade>=evolucao.custo_evolucao;
        """
    ),
]


def ask_user_for_query():
    print("Selecione a consulta desejada:")

    # Display all registered queries
    for idx, query in enumerate(simple_queries, start=1):
        print(f"{idx}) {query.description}")

    # Get a valid selection
    valid = False
    while not valid:
        try:
            option = int(input()) - 1
            if option < 0 or option >= len(simple_queries):
                print("Opcao invalida")
            else:
                valid = True
        except ValueError:
            print("Opcao invalida")

    return simple_queries[option]


def display_records(title, records):
    """Print to the terminal the records
    
    Arguments:
        title (str): Title of the list
        records (list[Any]): List of records to be printed
    """
    top_ruler = f"----------- {title} -----------"
    bottom_ruler = "-" * len(top_ruler)

    print(top_ruler)
    for idx, record in enumerate(records, start=1):
        record_str = " - ".join(str(x) for x in record)
        print(f"{idx}) {record_str}")
    print(bottom_ruler)
