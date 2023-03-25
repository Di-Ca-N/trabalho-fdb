-- Checklist:
-- [x] 1 visão
-- [x] 1 trigger
-- [x] 2 com subconsulta
-- [x] 1 consulta group by
-- [X] 2 consultas com visão
-- [X] 1 consulta group by + having
-- [ ] 10 consultas com pelo menos 3 tabelas
-- [x] 1 consulta NOT EXISTS obrigratório (query TODOS/NENHUM)

DROP VIEW IF EXISTS pokemon_capturados_completos;
CREATE VIEW pokemon_capturados_completos AS
SELECT 
	PokemonCapturados.*,
	Especies.ataque_base, Especies.vida_base, Especies.defesa_base,
	Especies.doce_id
FROM PokemonCapturados
	JOIN Formas ON Formas.id=PokemonCapturados.forma_id
	JOIN Especies ON Especies.id=Formas.especie_id;


-- Inventário do 'Jogador 1', incluindo itens e quantidades
SELECT Itens.nome, Itens.classe, Inventarios.quantidade
FROM Itens 
	JOIN Inventarios ON Inventarios.item_id=Itens.id 
	JOIN Jogadores ON Inventarios.jogador_id=Jogadores.id
WHERE Jogadores.nome='Jogador 1';

-- Todos os ids dos Pokémon capturados pelo 'Jogador 1' que podem evoluir
SELECT PokemonCapturados.id, PokemonCapturados.nome, forma_pokemon.nome, Especies.nome, evolucao.custo_evolucao
FROM PokemonCapturados 
	JOIN Jogadores ON PokemonCapturados.treinador_id=Jogadores.id
	JOIN Inventarios ON Inventarios.jogador_id=Jogadores.id
	JOIN Itens ON Inventarios.item_id=Itens.id
	JOIN Formas forma_pokemon ON PokemonCapturados.forma_id=forma_pokemon.id
	JOIN Especies ON forma_pokemon.especie_id=Especies.id
	LEFT JOIN Formas evolucao ON evolucao.evolui_de=forma_pokemon.id
WHERE Jogadores.nome='Jogador 1' AND itens.id=especies.doce_id AND inventarios.quantidade>=evolucao.custo_evolucao;

-- nome do tipo, id da espécie, nome da espécie, id da forma e nome da forma que possui o maior ataque básico para 
-- cada tipo de pokémon
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

-- Para cada ginásio que possui pelo menos dois defensores do tipo fogo, qual é a menor 
-- motivação entre esses defensores
SELECT Ginasios.local_id, MIN(defensor_motivacao)
FROM Ginasios
	JOIN pokemon_capturados_completos PC ON Ginasios.local_id=defensor_ginasio_id
	JOIN TipoForma ON PC.forma_id=TipoForma.forma_id
	JOIN Tipos ON TipoForma.tipo_id=Tipos.id
WHERE Tipos.nome='Fogo'
GROUP BY (Ginasios.local_id)
HAVING COUNT(*) >= 2;

-- Quais são os tipos de ataques que nenhum Pokémon do jogador 1 conhece
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

-- Quantos Pokémon capturados de cada espécie o jogador 1 tem
SELECT E.nome, COUNT(*)
FROM Jogadores J
	JOIN PokemonCapturados P ON J.id=P.treinador_id
	JOIN Formas F ON P.forma_id=F.id
	JOIN Especies E ON F.especie_id=E.id
WHERE J.nome='Jogador 1'
GROUP BY (E.nome)
ORDER BY (E.nome);

-- Quantos ginásios são defendidos por cada time
SELECT time, COUNT(DISTINCT local_id)
FROM Jogadores
	JOIN PokemonCapturados ON PokemonCapturados.treinador_id=Jogadores.id
	JOIN Ginasios ON Ginasios.local_id=PokemonCapturados.defensor_ginasio_id
GROUP BY time;


-- Quais são os ids, nomes e proabilidades dos itens obtíveis no local de id 1
SELECT I.id, nome, probabilidade
FROM Locais L
	JOIN ConjuntosDeItens CI ON L.conjunto_id=CI.id
	JOIN Composicoes CO ON CI.id=CO.conjunto_id
	JOIN Itens I ON I.id=item_id
WHERE L.id=1;


-- Todos os jogadores que possuem Pokémon de todas as espécies que o Jogador 1 possui, e somente essas
SELECT nome
FROM Jogadores J1
WHERE
	nome<>'Jogador 1'
	AND NOT EXISTS (  -- Id do Jogador 1, caso tenha capturado alguma espécie que o outro jogador não capturou
		SELECT J2.id
		FROM Jogadores J2
			JOIN PokemonCapturados P2 ON J2.id=P2.treinador_id
			JOIN Formas F2 ON P2.forma_id=F2.id
		WHERE
			J2.nome='Jogador 1'
			AND F2.especie_id NOT IN (	 -- Espécies que um jogador capturou
				SELECT DISTINCT F3.especie_id
				FROM Jogadores J3
					JOIN PokemonCapturados P3 ON J3.id=P3.treinador_id
					JOIN Formas F3 ON P3.forma_id=F3.id
				WHERE J3.id=J1.id
			)
	)
	AND NOT EXISTS (  -- Id dos jogadores que capturaram espécies que o Jogador 1 não capturou 
		SELECT DISTINCT J2.id
		FROM Jogadores J2
			JOIN PokemonCapturados P2 ON J2.id=P2.treinador_id
			JOIN Formas F2 ON P2.forma_id=F2.id
		WHERE
			J2.id=J1.id
			AND F2.especie_id NOT IN (	 -- Espécies que o Jogador 1 capturou
				SELECT DISTINCT F3.especie_id
				FROM Jogadores J3
					JOIN PokemonCapturados P3 ON J3.id=P3.treinador_id
					JOIN Formas F3 ON P3.forma_id=F3.id
				WHERE J3.nome='Jogador 1'
			)
	)
;

-- Qual é o time que 
-- Se a motivação do Pokemon capturado chegar a zero, desvincula do ginásio e zera vida atual
CREATE OR REPLACE FUNCTION expulsa_pokemon() RETURNS trigger AS $$
BEGIN
	IF (NEW.defensor_motivacao=0) THEN
		UPDATE PokemonCapturados
		SET defensor_ginasio_id = NULL, defensor_motivacao = NULL, vida_atual = 0
		WHERE id=NEW.id;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Monitora atualizações na tabela PokemonCapturados
CREATE OR REPLACE TRIGGER monitora_motivacao
AFTER INSERT OR UPDATE ON PokemonCapturados
	FOR EACH ROW EXECUTE FUNCTION expulsa_pokemon();
