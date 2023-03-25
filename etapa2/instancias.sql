/*****************************************************
 ************  DEFINIÇÃO DAS TABELAS  ****************
 *****************************************************/

DROP TABLE IF EXISTS AtaquesConhecidos;
DROP TABLE IF EXISTS PokemonCapturados CASCADE;
DROP TABLE IF EXISTS TentativasDeCaptura;
DROP TABLE IF EXISTS Ataques;
DROP TABLE IF EXISTS Ginasios;
DROP TABLE IF EXISTS Pokestops;
DROP TABLE IF EXISTS Fotodiscos;
DROP TABLE IF EXISTS TipoForma;
DROP TABLE IF EXISTS Composicoes;
DROP TABLE IF EXISTS Inventarios;
DROP TABLE IF EXISTS Jogadores;
DROP TABLE IF EXISTS Locais;
DROP TABLE IF EXISTS ConjuntosDeItens;
DROP TABLE IF EXISTS PokemonSelvagens;
DROP TABLE IF EXISTS Formas;
DROP TABLE IF EXISTS Especies;
DROP TABLE IF EXISTS Tipos;
DROP TABLE IF EXISTS Itens;
DROP TYPE IF EXISTS tipo_local;
DROP TYPE IF EXISTS time_jogador;
DROP TYPE IF EXISTS classe_item;

-- Tipos de Enumeração usados na modelagem
CREATE TYPE classe_item AS ENUM ('doce', 'isca', 'pokebola', 'poeira', 'reviver', 'pocao');
CREATE TYPE time_jogador AS ENUM ('valor', 'instinct', 'mystic');
CREATE TYPE tipo_local AS ENUM ('P', 'G');

CREATE TABLE IF NOT EXISTS Itens (
	id serial NOT NULL,
	nome varchar(30) NOT NULL,
	classe classe_item NOT NULL,
	
	PRIMARY KEY (id),
	UNIQUE(nome)
);

CREATE TABLE IF NOT EXISTS Tipos (
	id serial NOT NULL,
	nome varchar(16) NOT NULL,
	
	PRIMARY KEY (id),
	UNIQUE (nome)
);

CREATE TABLE IF NOT EXISTS Especies (
	id serial NOT NULL,
	nome varchar(32) NOT NULL,
	vida_base smallint NOT NULL,
	ataque_base smallint NOT NULL,
	defesa_base smallint NOT NULL,
	prob_captura real NOT NULL,
	prob_fuga real NOT NULL,
	
	doce_id integer NOT NULL,
	
	PRIMARY KEY (id),
	UNIQUE (nome),
	FOREIGN KEY (doce_id) REFERENCES Itens,
	CHECK (vida_base > 0),
	CHECK (ataque_base > 0),
	CHECK (defesa_base > 0)
);

CREATE TABLE IF NOT EXISTS Formas (
	id serial NOT NULL,
	especie_id integer NOT NULL,
	nome varchar(24) NOT NULL,
	
	evolui_de integer,
	custo_evolucao integer,

	PRIMARY KEY (id),
	UNIQUE (especie_id, nome),

	FOREIGN KEY (evolui_de) REFERENCES Formas,
	CHECK (evolui_de IS NULL AND custo_evolucao IS NULL OR evolui_de IS NOT NULL AND custo_evolucao >= 0)
);

CREATE TABLE IF NOT EXISTS TipoForma (
	forma_id integer NOT NULL,
	tipo_id integer NOT NULL,
	PRIMARY KEY (forma_id, tipo_id)
);

CREATE TABLE IF NOT EXISTS PokemonSelvagens (
	id serial NOT NULL,
	forma_id integer NOT NULL,
	latitude double precision NOT NULL,
	longitude double precision NOT NULL,
	visivel_ate timestamp NOT NULL,

	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Jogadores (
	id serial NOT NULL,
	nome varchar(32) NOT NULL,
	experiencia integer NOT NULL DEFAULT 0,
	time time_jogador,

	PRIMARY KEY (id),
	UNIQUE (nome)
);

CREATE TABLE IF NOT EXISTS Inventarios (
	jogador_id integer NOT NULL,
	item_id integer NOT NULL,
	quantidade integer NOT NULL DEFAULT 0,
	
	PRIMARY KEY (jogador_id, item_id),
	FOREIGN KEY (jogador_id) REFERENCES Jogadores,
	FOREIGN KEY (item_id) REFERENCES Itens
);

CREATE TABLE IF NOT EXISTS ConjuntosDeItens (
	id serial NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Composicoes (
	item_id integer NOT NULL,
	conjunto_id integer NOT NULL,
	probabilidade real NOT NULL,
	
	PRIMARY KEY (item_id, conjunto_id),
	FOREIGN KEY (item_id) REFERENCES Itens,
	FOREIGN KEY (conjunto_id) REFERENCES ConjuntosDeItens,
	CHECK (probabilidade > 0)
);

CREATE TABLE IF NOT EXISTS Locais (
	id serial NOT NULL,
	latitude double precision NOT NULL,
	longitude double precision NOT NULL,
	tipo tipo_local NOT NULL,
	
	conjunto_id integer NOT NULL,
	PRIMARY KEY (id),
    UNIQUE (latitude, longitude),
	FOREIGN KEY (conjunto_id) REFERENCES ConjuntosDeItens
);

CREATE TABLE IF NOT EXISTS Fotodiscos (
	local_id integer NOT NULL,
	jogador_id integer NOT NULL,
	ultimo_giro timestamp NOT NULL,
	
	PRIMARY KEY (local_id, jogador_id),
	FOREIGN KEY (local_id) REFERENCES Locais,
	FOREIGN KEY (jogador_id) REFERENCES Jogadores
);

CREATE TABLE IF NOT EXISTS Pokestops (
	local_id integer NOT NULL,

	isca_jogador_id integer,
	isca_item_id integer,
	isca_validade timestamp,

	PRIMARY KEY (local_id),
	FOREIGN KEY (local_id) REFERENCES Locais,
	FOREIGN KEY (isca_jogador_id) REFERENCES Jogadores,
	FOREIGN KEY (isca_item_id) REFERENCES Itens
);

CREATE TABLE IF NOT EXISTS Ginasios (
	local_id integer NOT NULL,
	
	PRIMARY KEY (local_id),
	FOREIGN KEY (local_id) REFERENCES Locais
);

CREATE TABLE IF NOT EXISTS Ataques (
	id serial NOT NULL,
	nome varchar(32) NOT NULL,
	dano smallint NOT NULL,
	velocidade smallint NOT NULL,
	tipo_id integer NOT NULL,

	PRIMARY KEY (id),
	UNIQUE (nome),
	FOREIGN KEY (tipo_id) REFERENCES Tipos
);

CREATE TABLE IF NOT EXISTS TentativasDeCaptura (
	pokemon_id integer NOT NULL,
	jogador_id integer NOT NULL,
	finalizado boolean NOT NULL DEFAULT FALSE,
	iv_vida smallint NOT NULL,
	iv_ataque smallint NOT NULL,
	iv_defesa smallint NOT NULL,
	
	PRIMARY KEY (pokemon_id, jogador_id),
	FOREIGN KEY (pokemon_id) REFERENCES PokemonSelvagens
		ON DELETE CASCADE,
	FOREIGN KEY (jogador_id) REFERENCES Jogadores
		ON DELETE CASCADE,
	
	CHECK (
		0 <= iv_vida AND iv_vida <= 15 AND
		0 <= iv_ataque AND iv_ataque <= 15 AND
		0 <= iv_defesa AND iv_defesa <= 15
	)
);

CREATE TABLE IF NOT EXISTS PokemonCapturados (
	id serial NOT NULL,
	forma_id integer NOT NULL,
	
    nome varchar(32) NOT NULL,
	vida_atual smallint NOT NULL,
	iv_vida smallint NOT NULL,
	iv_ataque smallint NOT NULL,
	iv_defesa smallint NOT NULL,
	nivel smallint NOT NULL,

	treinador_id integer NOT NULL,
	favorito boolean NOT NULL DEFAULT FALSE,
	
	defensor_ginasio_id integer,
	defensor_motivacao integer,

	PRIMARY KEY (id),
	FOREIGN KEY (forma_id) REFERENCES Formas,
	FOREIGN KEY (treinador_id) REFERENCES Jogadores,
	FOREIGN KEY (defensor_ginasio_id) REFERENCES Ginasios,

	CHECK (vida_atual >= 0),
	CHECK (nivel >= 1),
	CHECK (
		0 <= iv_vida AND iv_vida <= 15 AND
		0 <= iv_ataque AND iv_ataque <= 15 AND
		0 <= iv_defesa AND iv_defesa <= 15
	),
	CHECK (
		defensor_ginasio_id IS NOT NULL AND defensor_motivacao >= 0 
		OR 
		defensor_ginasio_id IS NULL AND defensor_motivacao IS NULL
	)
);

CREATE TABLE IF NOT EXISTS AtaquesConhecidos (
	pokemon_id integer NOT NULL,
	ataque_id integer NOT NULL,
	PRIMARY KEY (pokemon_id, ataque_id),
	FOREIGN KEY (pokemon_id) REFERENCES PokemonCapturados,
	FOREIGN KEY (ataque_id) REFERENCES Ataques
);

/*****************************************************
 ************  INSERÇÃO DE REGISTROS  ****************
 *****************************************************/
 
INSERT INTO Itens(id, nome, classe) VALUES 
	(1, 'Pokebola', 'pokebola'),
	(2, 'Poeira Estelar', 'poeira'),
	(3, 'Isca', 'isca'),
	(4, 'Doce Charmander', 'doce'),
	(5, 'Doce Squirtle', 'doce'),
	(6, 'Doce Bulbasaur', 'doce'),
	(7, 'Doce Vulpix', 'doce'),
	(8, 'Poção', 'pocao'),
	(9, 'SuperPoção', 'pocao'),
	(10, 'HiperPoção', 'pocao'),
	(11, 'Greatball', 'pokebola'),
	(12, 'Ultraball', 'pokebola'),
	(13, 'Isca gelada', 'isca'),
	(14, 'Isca musgosa', 'isca'),
	(15, 'Isca magnética', 'isca');

INSERT INTO Jogadores(id, nome, experiencia, time) VALUES 
	(1, 'Jogador 1', 10000, 'instinct'), 
	(2, 'Jogador 2', 1000000, 'valor'), 
	(3, 'Jogador 3', 1000, NULL),
	(4, 'Jogador 4', 15000, 'instinct'),
	(5, 'Jogador 5', 5000, NULL),
	(6, 'Jogador 6', 153200, 'instinct'),
	(7, 'Jogador 7', 123450, 'valor');

INSERT INTO Inventarios(jogador_id, item_id, quantidade) VALUES
	(1, 1, 10), -- 10 Pokebola
	(1, 2, 10000), -- 10000 Poeira Estelar
	(1, 4, 50), -- 50 Doce Charmander
	(1, 5, 100), -- 100 Doce Squirtle
	(2, 1, 50), -- 50 Pokebola
	(2, 2, 85000), -- 85000 Poeira Estelar
	(2, 3, 2), -- 2 Isca
	(3, 1, 20), -- 20 Pokebola
	(3, 3, 1), --  1 Isca
	(3, 2, 1000), -- 1000 Poeira Estelar
	(1, 7, 52); -- 52 Doce Vulpix

INSERT INTO 
	Especies(id, nome, vida_base, ataque_base, defesa_base, prob_captura, prob_fuga, doce_id) 
VALUES 
	(1, 'Bulbasaur',  128, 118, 111, 0.20, 0.10, 6),
	(2, 'Ivysaur',    155, 151, 143, 0.10, 0.07, 6),
	(3, 'Venusaur',   190, 198, 189, 0.05, 0.05, 6),
	(4, 'Charmander', 118, 116,  93, 0.20, 0.10, 4),
	(5, 'Charmeleon', 151, 158, 126, 0.10, 0.07, 4),
	(6, 'Charizard',  186, 223, 173, 0.05, 0.05, 4),
	(7, 'Squirtle',   127,  94, 121, 0.20, 0.10, 5),
	(37, 'Vulpix',    116,  96, 109, 0.30, 0.10, 7),
	(38, 'Ninetales', 177, 169, 190, 0.10, 0.06, 7);
	
INSERT INTO 
	Formas (id, especie_id, nome, evolui_de, custo_evolucao) 
VALUES 
	(1, 1, 'Padrão', NULL, NULL), -- Bulbasaur Padrão
	(2, 2, 'Padrão', 1, 25),      -- Ivysaur Padrão
	(3, 3, 'Padrão', 2, 100),     -- Venusaur Padrão
	(4, 4, 'Padrão', NULL, NULL), -- Charmander Padrão
	(5, 5, 'Padrão', 4, 25),      -- Charmeleon Padrão
	(6, 6, 'Padrão', 5, 100),     -- Charizard Padrão	
	(7, 7, 'Padrão', NULL, NULL), -- Squirtle Padrão
	(8, 37, 'Padrão', NULL, NULL),-- Vulpix Padrão
	(9, 37, 'Alola', NULL, NULL), -- Vulpix de Alola
	(10, 38, 'Padrão', 8, 50),    -- Ninetales Padrão
	(11, 38, 'Alola', 9, 50);     -- Ninetales de Alola

INSERT INTO 
	Tipos (id, nome)
VALUES
	(1, 'Planta'), 
	(2, 'Gelo'), 
	(3, 'Pedra'), 
	(4, 'Fantasma'), 
	(5, 'Água'), 
	(6, 'Fogo'), 
	(7, 'Dragão'), 
	(8, 'Voador'), 
	(9, 'Normal'),
	(10, 'Fada'), 
	(11, 'Lutador'), 
	(12, 'Psíquico'),
	(13, 'Sombrio'),
	(14, 'Venenoso'),
	(15, 'Solo'),
	(16, 'Elétrico'),
	(17, 'Aço'),
	(18, 'Inseto');

INSERT INTO
	TipoForma(forma_id, tipo_id)
VALUES
	(1, 1),
	(2, 1),
	(3, 1),
	(4, 6),
	(5, 6),
	(6, 6),
	(6, 8),
	(7, 5),
	(8, 6),
	(9, 2),
	(10, 6),
	(11, 2);

-- Por padrão, apenas 2 conjuntos de itens (para Pokéstops e Ginásios).
-- Em eventos especiais, mais conjuntos podem ser criados
INSERT INTO ConjuntosDeItens (id) VALUES (1), (2);

INSERT INTO 
	Composicoes(conjunto_id, item_id, probabilidade)
VALUES
	(1,  1, 0.40), -- 40% Pokebola
	(1, 11, 0.20), -- 20% Greatball
	(1, 12, 0.10), -- 10% Ultraball
	(1,  8, 0.15), -- 15% Poção
	(1,  9, 0.10), -- 10% SuperPoção
	(1, 10, 0.05), --  5% HiperPoção
	(2,  8, 0.40), -- 40% Poção
	(2,  9, 0.20), -- 20% SuperPoção
	(2, 10, 0.10), -- 10% HiperPoção
	(2,  1, 0.15), -- 15% Pokebola
	(2, 11, 0.10), -- 10% Greatball
	(2, 12, 0.05); --  5% Ultraball

INSERT INTO 
	Locais(id, latitude, longitude, tipo, conjunto_id)
VALUES 
	(1, -30.038000, -51.215365, 'P', 1),
	(2, -30.038761, -51.214877, 'P', 1),
	(3, -30.037614, -51.212919, 'P', 1),
	(4, -30.037261, -51.217645, 'G', 2),
	(5, -30.036453, -51.212543, 'G', 2),
	(6, -30.037540, -51.213257, 'G', 2);

INSERT INTO
	Pokestops(local_id, isca_jogador_id, isca_item_id, isca_validade)
VALUES
	(1, NULL, NULL, NULL),
	(2, 1, 3, NOW()),
	(3, 2, 13, NOW());

INSERT INTO Ginasios(local_id) VALUES (4), (5), (6);

INSERT INTO
	Ataques(id, nome, dano, velocidade, tipo_id)
VALUES
	(1, 'Presa de Fogo',     12,   9, 6),
	(2, 'Incinerar',         29,  23, 6),
	(3, 'Soco de Fogo',      55,  22, 6),
	(4, 'Arranhão',           6,   5, 9),
	(5, 'Impacto Corporal',  50,  19, 9),
	(6, 'Folha Navalha',     13,  10, 1),
	(7, 'Raio Solar',        180, 49, 1);

INSERT INTO
	PokemonSelvagens(id, forma_id, latitude, longitude, visivel_ate)
VALUES
	(1, 1, -30.038181, -51.215505, NOW()),
	(2, 1, -30.037549, -51.215488, NOW()),
	(3, 4, -30.037828, -51.215987, NOW()),
	(4, 7, -30.037930, -51.214244, NOW()),
	(5, 8, -30.038868, -51.215075, NOW());


INSERT INTO
	TentativasDeCaptura(pokemon_id, jogador_id, finalizado, iv_vida, iv_ataque, iv_defesa)
VALUES
	(1, 1, FALSE, 7, 2, 15),
	(3, 2, TRUE, 10, 11, 13),
	(4, 2, TRUE, 14, 11, 10);

INSERT INTO
	PokemonCapturados(
		id, nome, forma_id, vida_atual, iv_vida, iv_ataque, iv_defesa, nivel, 
		treinador_id, favorito, defensor_ginasio_id, defensor_motivacao
	)
VALUES
	(1, 'Charizard', 6, 100, 14, 15, 15, 20, 1, FALSE, NULL, NULL),
	(2, 'Venusaur', 3, 150, 15, 10, 13, 25, 1, TRUE, 4, 1000),
	(3, 'Ninetales', 10, 80,  8,  9, 12, 13, 2, FALSE, NULL, NULL),
	(4, 'Charmeleon', 5,  83,  1,  0,  4, 10, 2, FALSE, 5, 200),
	(5, 'Raposinha', 8,  120,  8,  15, 15, 15, 1, TRUE, NULL, NULL),

	(6, 'Charigarto', 4, 79, 10, 5, 11, 7, 1, FALSE, NULL, NULL),
	(7, 'Charmander', 4, 79, 10, 5, 11, 7, 4, FALSE, 4, 300),
	(8, 'Venusaur', 3, 50, 15, 10, 13, 25, 1, FALSE, NULL, NULL),
	(9, 'Ninetales', 10, 70, 10, 7, 10, 15, 5, FALSE, NULL, NULL),
	(10, 'Squirtle', 7, 50,  14,  13, 10, 9, 2, TRUE, NULL, NULL),
	(11, 'Charizard', 6, 100, 14, 15, 15, 20, 6, FALSE, 4, 2000),
	(12, 'Vulpix', 8, 70, 10, 7, 10, 15, 7, FALSE, 5, 500);


INSERT INTO 
	AtaquesConhecidos(pokemon_id, ataque_id)
VALUES
	(1, 1), -- Charizard 1, Presa de Fogo
	(1, 2), -- Charizard 1, Incinerar
	(1, 3), -- Charizard 1, Soco de Fogo
	(2, 4), -- Venusaur 2, Arranhão
	(2, 7), -- Venusaur 2, Raio Solar
	(3, 1), -- Vulpix 3, Presa de fogo
	(3, 2), -- Vulpix 3, Incinerar
	(4, 4), -- Charmeleon 1, Arranhão
	(4, 2), -- Charmeleon 1, Incinerar
	(5, 4), -- Raposinha, Arranhão
	(5, 7); -- Raposinha, Raio Solar

INSERT INTO
	FotoDiscos(jogador_id, local_id, ultimo_giro)
VALUES
	(1, 1, NOW()),
	(1, 2, NOW()),
	(2, 1, NOW()),
	(2, 2, NOW()),
	(2, 4, NOW()),
	(3, 5, NOW());
