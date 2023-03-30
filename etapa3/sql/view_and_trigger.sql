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