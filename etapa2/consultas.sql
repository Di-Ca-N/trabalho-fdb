-- Grupo: Diego Nunes e Felipe Gallois

-- ==============================================
-- ================== VISÃO =====================
-- ==============================================

DROP VIEW IF EXISTS pokemon_capturados_completos;
CREATE VIEW pokemon_capturados_completos AS
SELECT 
	PokemonCapturados.*,
	Especies.ataque_base, Especies.vida_base, Especies.defesa_base,
	Especies.doce_id
FROM PokemonCapturados
	JOIN Formas ON Formas.id=PokemonCapturados.forma_id
	JOIN Especies ON Especies.id=Formas.especie_id;


-- ==============================================
-- ================= CONSULTAS ==================
-- ==============================================

-- 1) nome, classe e quantidade dos itens que estão no inventário do 'Jogador 1'
SELECT Itens.nome, Itens.classe, Inventarios.quantidade
FROM Itens 
	JOIN Inventarios ON Inventarios.item_id=Itens.id 
	JOIN Jogadores ON Inventarios.jogador_id=Jogadores.id
WHERE Jogadores.nome='Jogador 1';

-- 2) ids, nome, nome da espécie, nome da forma e custo de evolução dos Pokémon 
-- capturados pelo 'Jogador 1' que podem evoluir
SELECT PokemonCapturados.id, PokemonCapturados.nome, forma_pokemon.nome, Especies.nome, evolucao.custo_evolucao
FROM PokemonCapturados
	JOIN Jogadores ON PokemonCapturados.treinador_id=Jogadores.id
	JOIN Inventarios ON Inventarios.jogador_id=Jogadores.id
	JOIN Itens ON Inventarios.item_id=Itens.id
	JOIN Formas forma_pokemon ON PokemonCapturados.forma_id=forma_pokemon.id
	JOIN Especies ON forma_pokemon.especie_id=Especies.id
	LEFT JOIN Formas evolucao ON evolucao.evolui_de=forma_pokemon.id
WHERE Jogadores.nome='Jogador 1' AND itens.id=especies.doce_id AND inventarios.quantidade>=evolucao.custo_evolucao;

-- 3) nome do tipo, id da espécie, nome da espécie, id da forma e nome da forma 
-- que possui o maior ataque básico para cada tipo de pokémon
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

-- 4) Para cada ginásio que possui pelo menos dois defensores do tipo fogo, qual é a menor 
-- motivação entre esses defensores
SELECT Ginasios.local_id, MIN(defensor_motivacao)
FROM Ginasios
	JOIN pokemon_capturados_completos PC ON Ginasios.local_id=defensor_ginasio_id
	JOIN TipoForma ON PC.forma_id=TipoForma.forma_id
	JOIN Tipos ON TipoForma.tipo_id=Tipos.id
WHERE Tipos.nome='Fogo'
GROUP BY (Ginasios.local_id)
HAVING COUNT(*) >= 2;

-- 5) Quais são os tipos de ataques que nenhum Pokémon do jogador 1 conhece
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

-- 6) Quantos Pokémon capturados de cada espécie o jogador 1 tem
SELECT E.nome, COUNT(*)
FROM Jogadores J
	JOIN PokemonCapturados P ON J.id=P.treinador_id
	JOIN Formas F ON P.forma_id=F.id
	JOIN Especies E ON F.especie_id=E.id
WHERE J.nome='Jogador 1'
GROUP BY (E.nome)
ORDER BY (E.nome);

-- 7) Quantos ginásios são defendidos por cada time
SELECT time, COUNT(DISTINCT local_id)
FROM Jogadores
	JOIN PokemonCapturados ON PokemonCapturados.treinador_id=Jogadores.id
	JOIN Ginasios ON Ginasios.local_id=PokemonCapturados.defensor_ginasio_id
GROUP BY time;

-- 8) Quais são os ids, nomes e probabilidades dos itens obtíveis no local de id 1
SELECT I.id, nome, probabilidade
FROM Locais L
	JOIN ConjuntosDeItens CI ON L.conjunto_id=CI.id
	JOIN Composicoes CO ON CI.id=CO.conjunto_id
	JOIN Itens I ON I.id=item_id
WHERE L.id=1;

-- 9) id e nome dos jogadores que não possuem nenhum pokémon das espécies que o 
-- Jogador 1 possui
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

-- 10) id, latitude e longitude dos Pokémon Selvagens com os quais o Jogador 2 já encerrou 
-- uma tentativa de captura
SELECT PS.id, latitude, longitude
FROM PokemonSelvagens PS
	JOIN TentativasDeCaptura T ON T.pokemon_id=PS.id
	JOIN Jogadores J ON J.id=T.jogador_id
WHERE finalizado=true AND nome='Jogador 2';

-- 11) id, latitude e longitude das Pokéstops com isca válida que o jogador 1 já interagiu alguma vez
SELECT Locais.id, latitude, longitude
FROM Locais
	JOIN Fotodiscos F ON F.local_id=Locais.id
	JOIN Pokestops P ON P.local_id=Locais.id
WHERE jogador_id=1 AND isca_validade > NOW();


-- ==============================================
-- ============ PROCEDURE E TRIGGER =============
-- ==============================================

-- Desvincula um Pokémon defensor de um ginásio e zera vida atual
-- OBS: Apesar de a função abaixo não retornar valor, não se pode usar 
-- um procedure. No Postgres só é possível criar gatilhos que chamem 
-- funções, e essas funções devem ter retorno do tipo 'trigger'
CREATE OR REPLACE FUNCTION expulsa_pokemon() RETURNS trigger AS $$
BEGIN
	UPDATE PokemonCapturados
	SET defensor_ginasio_id = NULL, defensor_motivacao = NULL, vida_atual = 0
	WHERE id=NEW.id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Monitora atualizações na tabela PokemonCapturados, expulsando o
-- Pokémon do ginásio quando sua motivação chega a 0
CREATE OR REPLACE TRIGGER monitora_motivacao
AFTER INSERT OR UPDATE OF defensor_motivacao ON PokemonCapturados
FOR EACH ROW 
WHEN (NEW.defensor_motivacao = 0)
EXECUTE FUNCTION expulsa_pokemon();