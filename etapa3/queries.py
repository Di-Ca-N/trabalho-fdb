from dataclasses import dataclass, field
from db_utils import run_sql_query


@dataclass
class Query:
    """Represent an arbitrary SQL query.
    
    Attributes:
        description (str): Text that describes what the query does. Will
            be displayed to the user.
        sql (str): SQL query to execute. The query may have parameters,
            marked by the string substitution placeholder '%s'.
        parameters (dict[str, type]): Parameters dictionary, indicating 
            the parameters the query expects. The key is the verbose 
            name of the parameter, and the value is its type. The number 
            of items must equal the number of query parameters. 
    """
    description: str
    sql: str
    parameters: dict[str, type] = field(default_factory=dict)

    def get_parameters(self):
        """Get the query parameters
        
        Use the 'parameters' attribute to ask the used for the required
        query parameters
        """
        parameter_values = []

        # Get the parameter values
        for text, _type in self.parameters.items():
            valid = False

            while not valid:
                try:
                    value = _type(input(text))
                except ValueError:
                    print("Opção inválida")
                else:
                    valid = True
            parameter_values.append(value)
    
        return parameter_values

    def run(self, conn):
        parameters = self.get_parameters()
        return run_sql_query(conn, self.sql, parameters)

queries = [
    Query(
        description="Inventário de um jogador",
        sql="""
            SELECT Itens.nome, Itens.classe, Inventarios.quantidade
            FROM Itens 
                JOIN Inventarios ON Inventarios.item_id=Itens.id 
                JOIN Jogadores ON Inventarios.jogador_id=Jogadores.id
            WHERE Jogadores.nome=%s;
        """,
        parameters={'Nome do jogador: ': str}
    ),
    Query(
        description="Pokémon do Jogador 1 que podem evoluir",
        sql="""
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
    Query(
        description="Forma com maior ataque básico, por cada tipo de Pokémon",
        sql="""
            SELECT Tipos.nome, Especies.id, Especies.nome, Formas.id, Formas.nome, Especies.ataque_base
            FROM Especies
                JOIN Formas ON Formas.especie_id=Especies.id
                JOIN TipoForma TipoEXT ON Formas.id=TipoEXT.forma_id
                JOIN Tipos ON TipoEXT.tipo_id=Tipos.id
            WHERE especies.ataque_base=(
                SELECT MAX(ataque_base)
                FROM Especies
                    JOIN Formas ON Formas.especie_id=Especies.id
                    JOIN TipoForma ON Formas.id=TipoForma.forma_id
                WHERE tipo_id=TipoEXT.tipo_id
            );
        """
    ),
    Query(
        description="Para cada ginásio que possui pelo menos dois defensores do tipo fogo, qual é a menor motivação entre esses defensores",
        sql="""
            SELECT Ginasios.local_id, MIN(defensor_motivacao)
            FROM Ginasios
                JOIN pokemon_capturados_completos PC ON Ginasios.local_id=defensor_ginasio_id
                JOIN TipoForma ON PC.forma_id=TipoForma.forma_id
                JOIN Tipos ON TipoForma.tipo_id=Tipos.id
            WHERE Tipos.nome='Fogo'
            GROUP BY (Ginasios.local_id)
            HAVING COUNT(*) >= 2;
        """
    ),
    Query(
        description="Quais são os tipos de ataques que nenhum Pokémon do jogador 1 conhece",
        sql="""
            SELECT *
            FROM Tipos
            WHERE id NOT IN (
                SELECT DISTINCT tipo_id
                FROM pokemon_capturados_completos
                    JOIN AtaquesConhecidos ON pokemon_id=id
                    JOIN Ataques ON ataque_id=Ataques.id
                    JOIN Jogadores ON treinador_id=Jogadores.id
                WHERE Jogadores.nome='Jogador 1'
            );
        """
    ),
    Query(
        description="Quantos Pokémon capturados de cada espécie um jogador tem",
        sql="""
            SELECT E.nome, COUNT(*)
            FROM Jogadores J
                JOIN PokemonCapturados P ON J.id=P.treinador_id
                JOIN Formas F ON P.forma_id=F.id
                JOIN Especies E ON F.especie_id=E.id
            WHERE J.nome=%s
            GROUP BY (E.nome)
            ORDER BY (E.nome);
        """,
        parameters={"Nome do jogador: ": str}
    ),
    Query(
        description="Número de ginásios defendidos por cada time",
        sql="""
            SELECT time, COUNT(DISTINCT local_id)
            FROM Jogadores
                JOIN PokemonCapturados ON PokemonCapturados.treinador_id=Jogadores.id
                JOIN Ginasios ON Ginasios.local_id=PokemonCapturados.defensor_ginasio_id
            GROUP BY time;
        """
    ),
    Query(
        description="Quais são os ids, nomes e probabilidades dos itens obtíveis em um local",
        sql="""
            SELECT I.id, nome, probabilidade
            FROM Locais L
                JOIN ConjuntosDeItens CI ON L.conjunto_id=CI.id
                JOIN Composicoes CO ON CI.id=CO.conjunto_id
                JOIN Itens I ON I.id=item_id
            WHERE L.id=%s;
        """,
        parameters={"ID do local: ": int}
    ),
    Query(
        description="id e nome dos jogadores que não possuem nenhum pokémon das espécies que o Jogador 1 possui",
        sql="""
            SELECT id, nome
            FROM Jogadores JEXT
            WHERE nome<>'Jogador 1' AND NOT EXISTS (
                SELECT especie_id
                FROM PokemonCapturados
                    JOIN Formas ON Formas.id=forma_id
                WHERE treinador_id = JEXT.id

                INTERSECT

                SELECT especie_id
                FROM PokemonCapturados
                    JOIN Jogadores ON Jogadores.id=treinador_id
                    JOIN Formas ON Formas.id=forma_id
                WHERE Jogadores.nome='Jogador 1'
            );
        """
    ),
    Query(
        description="id, latitude e longitude dos Pokémon Selvagens com os quais o Jogador 2 já encerrou uma tentativa de captura",
        sql="""
            SELECT PS.id, latitude, longitude
            FROM PokemonSelvagens PS
                JOIN TentativasDeCaptura T ON T.pokemon_id=PS.id
                JOIN Jogadores J ON J.id=T.jogador_id
            WHERE finalizado=true AND nome='Jogador 2';
        """
    ),
    Query(
        description="id, latitude e longitude das Pokéstops com isca válida que o Jogador 1 já interagiu alguma vez",
        sql="""
            SELECT Locais.id, latitude, longitude
            FROM Locais
                JOIN Fotodiscos F ON F.local_id=Locais.id
                JOIN Pokestops P ON P.local_id=Locais.id
            WHERE jogador_id=1 AND isca_validade > NOW();
        """
    )
]


def ask_user_for_query():
    print("Selecione a consulta desejada:")

    # Display all registered queries
    for idx, query in enumerate(queries, start=1):
        print(f"{idx}) {query.description}")

    # Get a valid selection
    valid = False
    while not valid:
        try:
            option = int(input("> ")) - 1
 
            if option < 0 or option >= len(queries):
                print("Opcao invalida")
            else:
                valid = True
 
        except ValueError:
            print("Opção inválida")

    return queries[option]


def display_records(title, records):
    """Print to the terminal the records
    
    Arguments:
        title (str): Title of the list
        records (list[Any]): List of records to be printed
    """
    top_ruler = f"----------- {title} -----------"
    bottom_ruler = "-" * len(top_ruler)

    print()
    print(top_ruler)
    if not records:
        print("Nenhum registro encontrado")

    for idx, record in enumerate(records, start=1):
        record_str = " - ".join(str(x) for x in record)
        print(f"{idx}) {record_str}")

    print(bottom_ruler)
