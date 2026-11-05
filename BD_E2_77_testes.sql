-- =====================================================================
-- Bases de Dados 2026/27 - Projeto BANDyApp - Etapa 2 (E2)
-- Grupo 77
-- Testes das restrições de integridade
--
-- Executar DEPOIS de BD_E2_77.sql, na mesma base de dados.
-- Cada comando tenta violar uma restrição e DEVE ser rejeitado com o erro
-- indicado no comentário "Erro esperado" (código SQLSTATE e restrição).
-- Nenhum comando altera os dados (todos falham).
-- Para continuar após cada erro: psql -f BD_E2_77_testes.sql (sem ON_ERROR_STOP).
-- =====================================================================

-- Teste 1: Chave primária duplicada em festival
-- Erro esperado: [23505] unique_violation - restrição "pk_festival"
INSERT INTO festival (nome, ano_criacao) VALUES ('Lisboa Sounds', 2020);

-- Teste 2: ano_criacao é obrigatório
-- Erro esperado: [23502] not_null_violation - coluna "ano_criacao"
INSERT INTO festival (nome, ano_criacao) VALUES ('Festival Novo', NULL);

-- Teste 3: Chave primária duplicada em recinto
-- Erro esperado: [23505] unique_violation - restrição "pk_recinto"
INSERT INTO recinto VALUES ('Parque Tejo Norte', 'Rua A', '1000-001', 'Lisboa', 'Lisboa', 1000);

-- Teste 4: Código postal com formato inválido
-- Erro esperado: [23514] check_violation - restrição "ck_recinto_codigo_postal"
INSERT INTO recinto VALUES ('Recinto Teste', 'Rua A', 'ABC', 'Lisboa', 'Lisboa', 1000);

-- Teste 5 (RIA-12): Capacidade máxima igual a zero
-- Erro esperado: [23514] check_violation - restrição "ck_recinto_capacidade_max"
INSERT INTO recinto VALUES ('Recinto Teste', 'Rua A', '1000-001', 'Lisboa', 'Lisboa', 0);

-- Teste 6 (RIA-12): Capacidade máxima negativa
-- Erro esperado: [23514] check_violation - restrição "ck_recinto_capacidade_max"
INSERT INTO recinto VALUES ('Recinto Teste', 'Rua A', '1000-001', 'Lisboa', 'Lisboa', -500);

-- Teste 7: Rua é obrigatória
-- Erro esperado: [23502] not_null_violation - coluna "rua"
INSERT INTO recinto VALUES ('Recinto Teste', NULL, '1000-001', 'Lisboa', 'Lisboa', 1000);

-- Teste 8: Chave primária duplicada em edicao
-- Erro esperado: [23505] unique_violation - restrição "pk_edicao"
INSERT INTO edicao VALUES ('Lisboa Sounds', 2026, 150.00, 'Parque Tejo Norte');

-- Teste 9: Edição de um festival inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_edicao_festival"
INSERT INTO edicao VALUES ('Festival Fantasma', 2026, 150.00, 'Parque Tejo Norte');

-- Teste 10: Edição num recinto inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_edicao_recinto"
INSERT INTO edicao VALUES ('Lisboa Sounds', 2030, 150.00, 'Recinto Fantasma');

-- Teste 11 (RIA-12): preco_passe igual a zero
-- Erro esperado: [23514] check_violation - restrição "ck_edicao_preco_passe"
INSERT INTO edicao VALUES ('Lisboa Sounds', 2030, 0, 'Parque Tejo Norte');

-- Teste 12: Edição sem recinto (participação total em decorre_em)
-- Erro esperado: [23502] not_null_violation - coluna "recinto_nome"
INSERT INTO edicao VALUES ('Lisboa Sounds', 2030, 150.00, NULL);

-- Teste 13: Edição sem preco_passe
-- Erro esperado: [23502] not_null_violation - coluna "preco_passe"
INSERT INTO edicao VALUES ('Lisboa Sounds', 2030, NULL, 'Parque Tejo Norte');

-- Teste 14: Apagar recinto que tem edições (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_edicao_recinto"
DELETE FROM recinto WHERE nome = 'Parque Tejo Norte';

-- Teste 15: Chave primária duplicada em dia
-- Erro esperado: [23505] unique_violation - restrição "pk_dia"
INSERT INTO dia VALUES ('Lisboa Sounds', 2026, '2026-07-08', 60.00);

-- Teste 16: Dia de uma edição inexistente (entidade fraca)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_dia_edicao"
INSERT INTO dia VALUES ('Lisboa Sounds', 2030, '2030-07-01', 60.00);

-- Teste 17 (RIA-1): Data do dia fora do ano da edição
-- Erro esperado: [23514] check_violation - restrição "ck_dia_data_no_ano_da_edicao"
INSERT INTO dia VALUES ('Lisboa Sounds', 2026, '2025-07-11', 60.00);

-- Teste 18 (RIA-12): preco_diario negativo
-- Erro esperado: [23514] check_violation - restrição "ck_dia_preco_diario"
INSERT INTO dia VALUES ('Lisboa Sounds', 2026, '2026-07-11', -5.00);

-- Teste 19: Dia sem preco_diario
-- Erro esperado: [23502] not_null_violation - coluna "preco_diario"
INSERT INTO dia VALUES ('Lisboa Sounds', 2026, '2026-07-11', NULL);

-- Teste 20: Chave primária duplicada em artista
-- Erro esperado: [23505] unique_violation - restrição "pk_artista"
INSERT INTO artista VALUES ('Kaelo', 'Pop', 'artista');

-- Teste 21 (RIA-3): Tipo de artista fora de {artista, grupo}
-- Erro esperado: [23514] check_violation - restrição "ck_artista_tipo"
INSERT INTO artista VALUES ('Duo Teste', 'Pop', 'duo');

-- Teste 22: Artista sem género musical
-- Erro esperado: [23502] not_null_violation - coluna "genero_musical"
INSERT INTO artista VALUES ('Artista Teste', NULL, 'artista');

-- Teste 23: Chave primária duplicada em concerto
-- Erro esperado: [23505] unique_violation - restrição "pk_concerto"
INSERT INTO concerto VALUES (1, '10:00', '11:00', 'Lisboa Sounds', 2026, '2026-07-08', 'Kaelo');

-- Teste 24 (RIA-2): hora_inicio igual a hora_fim
-- Erro esperado: [23514] check_violation - restrição "ck_concerto_horas"
INSERT INTO concerto VALUES (100, '21:00', '21:00', 'Lisboa Sounds', 2026, '2026-07-08', 'Kaelo');

-- Teste 25 (RIA-2): hora_inicio posterior a hora_fim
-- Erro esperado: [23514] check_violation - restrição "ck_concerto_horas"
INSERT INTO concerto VALUES (100, '23:00', '21:00', 'Lisboa Sounds', 2026, '2026-07-08', 'Kaelo');

-- Teste 26: Concerto num dia inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_concerto_dia"
INSERT INTO concerto VALUES (100, '20:00', '21:00', 'Lisboa Sounds', 2026, '2026-07-20', 'Kaelo');

-- Teste 27: Concerto de um artista inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_concerto_artista"
INSERT INTO concerto VALUES (100, '20:00', '21:00', 'Lisboa Sounds', 2026, '2026-07-08', 'Artista Fantasma');

-- Teste 28: Concerto sem artista (participação total em atua)
-- Erro esperado: [23502] not_null_violation - coluna "artista_nome"
INSERT INTO concerto VALUES (100, '20:00', '21:00', 'Lisboa Sounds', 2026, '2026-07-08', NULL);

-- Teste 29: Concerto sem dia (participação total em realizado)
-- Erro esperado: [23502] not_null_violation - coluna "data"
INSERT INTO concerto VALUES (100, '20:00', '21:00', 'Lisboa Sounds', 2026, NULL, 'Kaelo');

-- Teste 30: Apagar artista que tem concertos (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_concerto_artista"
DELETE FROM artista WHERE nome = 'Kaelo';

-- Teste 31: Apagar dia que tem concertos (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_concerto_dia"
DELETE FROM dia WHERE festival_nome = 'Lisboa Sounds' AND ano = 2026 AND data = '2026-07-08';

-- Teste 32: Chave primária duplicada em utilizador
-- Erro esperado: [23505] unique_violation - restrição "pk_utilizador"
INSERT INTO utilizador VALUES ('ana.ferreira@exemplo.pt', 'Outra Ana', '1990-01-01', NULL, NULL);

-- Teste 33: Email com formato inválido
-- Erro esperado: [23514] check_violation - restrição "ck_utilizador_email"
INSERT INTO utilizador VALUES ('email-sem-arroba', 'Teste', '1990-01-01', NULL, NULL);

-- Teste 34: Grupo sanguíneo inválido
-- Erro esperado: [23514] check_violation - restrição "ck_utilizador_grupo_sanguineo"
INSERT INTO utilizador VALUES ('teste@exemplo.pt', 'Teste', '1990-01-01', 'C+', NULL);

-- Teste 35: Utilizador sem nome
-- Erro esperado: [23502] not_null_violation - coluna "nome"
INSERT INTO utilizador VALUES ('teste@exemplo.pt', NULL, '1990-01-01', NULL, NULL);

-- Teste 36: Utilizador sem data de nascimento
-- Erro esperado: [23502] not_null_violation - coluna "data_nascimento"
INSERT INTO utilizador VALUES ('teste@exemplo.pt', 'Teste', NULL, NULL, NULL);

-- Teste 37: Alergia repetida para o mesmo utilizador
-- Erro esperado: [23505] unique_violation - restrição "pk_utilizador_alergia"
INSERT INTO utilizador_alergia VALUES ('ana.ferreira@exemplo.pt', 'Amendoim');

-- Teste 38: Alergia de um utilizador inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_utilizador_alergia_utilizador"
INSERT INTO utilizador_alergia VALUES ('fantasma@exemplo.pt', 'Pólen');

-- Teste 39: Chave primária duplicada em dispositivo
-- Erro esperado: [23505] unique_violation - restrição "pk_dispositivo"
INSERT INTO dispositivo VALUES ('BD-0001', 10, 'bloqueado', 'carla.mendes@exemplo.pt');

-- Teste 40 (RIA-7): Estado do dispositivo fora de {ativo, bloqueado, extraviado}
-- Erro esperado: [23514] check_violation - restrição "ck_dispositivo_estado"
INSERT INTO dispositivo VALUES ('BD-0100', 10, 'perdido', 'carla.mendes@exemplo.pt');

-- Teste 41 (RIA-7): Saldo negativo
-- Erro esperado: [23514] check_violation - restrição "ck_dispositivo_saldo"
INSERT INTO dispositivo VALUES ('BD-0100', -1, 'bloqueado', 'carla.mendes@exemplo.pt');

-- Teste 42 (RIA-7): Saldo que fica negativo ao atualizar
-- Erro esperado: [23514] check_violation - restrição "ck_dispositivo_saldo"
UPDATE dispositivo SET saldo = saldo - 1000 WHERE num_serie = 'BD-0007';

-- Teste 43: Dispositivo de um titular inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_dispositivo_titular"
INSERT INTO dispositivo VALUES ('BD-0100', 10, 'bloqueado', 'fantasma@exemplo.pt');

-- Teste 44: Dispositivo sem titular (participação total em pertence)
-- Erro esperado: [23502] not_null_violation - coluna "titular_email"
INSERT INTO dispositivo VALUES ('BD-0100', 10, 'bloqueado', NULL);

-- Teste 45 (RIA-8): Segundo dispositivo ativo para o mesmo utilizador (INSERT)
-- Erro esperado: [23505] unique_violation - restrição "uq_dispositivo_um_ativo_por_titular"
INSERT INTO dispositivo VALUES ('BD-0100', 0, 'ativo', 'ana.ferreira@exemplo.pt');

-- Teste 46 (RIA-8): Reativar um dispositivo extraviado quando já existe um ativo (UPDATE)
-- Erro esperado: [23505] unique_violation - restrição "uq_dispositivo_um_ativo_por_titular"
UPDATE dispositivo SET estado = 'ativo' WHERE num_serie = 'BD-0010';

-- Teste 47: Apagar utilizador que tem dispositivos (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_dispositivo_titular"
DELETE FROM utilizador WHERE email = 'ana.ferreira@exemplo.pt';

-- Teste 48 (RIA-11): Utilizador a seguir-se a si próprio
-- Erro esperado: [23514] check_violation - restrição "ck_segue_nao_a_si_proprio"
INSERT INTO segue VALUES ('ana.ferreira@exemplo.pt', 'ana.ferreira@exemplo.pt');

-- Teste 49: Relação segue repetida
-- Erro esperado: [23505] unique_violation - restrição "pk_segue"
INSERT INTO segue VALUES ('ana.ferreira@exemplo.pt', 'bruno.costa@exemplo.pt');

-- Teste 50: Seguidor inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_segue_seguidor"
INSERT INTO segue VALUES ('fantasma@exemplo.pt', 'ana.ferreira@exemplo.pt');

-- Teste 51: Seguido inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_segue_seguido"
INSERT INTO segue VALUES ('ana.ferreira@exemplo.pt', 'fantasma@exemplo.pt');

-- Teste 52: Chave primária duplicada em bilhete
-- Erro esperado: [23505] unique_violation - restrição "pk_bilhete"
INSERT INTO bilhete VALUES (1, '2026-01-01', 'P', 'ana.ferreira@exemplo.pt', NULL);

-- Teste 53: Tipo de bilhete fora de {P, D}
-- Erro esperado: [23514] check_violation - restrição "ck_bilhete_tipo"
INSERT INTO bilhete VALUES (100, '2026-01-01', 'X', 'ana.ferreira@exemplo.pt', NULL);

-- Teste 54: Bilhete de um comprador inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_comprador"
INSERT INTO bilhete VALUES (100, '2026-01-01', 'P', 'fantasma@exemplo.pt', NULL);

-- Teste 55: Bilhete associado a um dispositivo inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_dispositivo"
INSERT INTO bilhete VALUES (100, '2026-01-01', 'P', 'ana.ferreira@exemplo.pt', 'BD-9999');

-- Teste 56: Bilhete sem comprador (participação total em compra)
-- Erro esperado: [23502] not_null_violation - coluna "comprador_email"
INSERT INTO bilhete VALUES (100, '2026-01-01', 'P', NULL, NULL);

-- Teste 57: Bilhete sem data de compra
-- Erro esperado: [23502] not_null_violation - coluna "data_compra"
INSERT INTO bilhete VALUES (100, NULL, 'P', 'ana.ferreira@exemplo.pt', NULL);

-- Teste 58: Passe geral duplicado para o mesmo bilhete
-- Erro esperado: [23505] unique_violation - restrição "pk_passe_geral"
INSERT INTO passe_geral VALUES (1, 'P', 'Lisboa Sounds', 2026);

-- Teste 59: Passe geral sem o bilhete correspondente (superclasse)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_passe_geral_bilhete"
INSERT INTO passe_geral VALUES (100, 'P', 'Lisboa Sounds', 2026);

-- Teste 60: Disjunção: bilhete diário (id 9) também registado como passe geral
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_passe_geral_bilhete"
INSERT INTO passe_geral VALUES (9, 'P', 'Lisboa Sounds', 2026);

-- Teste 61: Discriminador do passe geral diferente de 'P'
-- Erro esperado: [23514] check_violation - restrição "ck_passe_geral_tipo"
INSERT INTO passe_geral VALUES (100, 'D', 'Lisboa Sounds', 2026);

-- Teste 62: Passe geral de uma edição inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_passe_geral_edicao"
UPDATE passe_geral SET ano = 2030 WHERE id_bilhete = 1;

-- Teste 63: Mudar o tipo de um passe geral para 'D' na superclasse
-- Erro esperado: [23514] check_violation - restrição "ck_passe_geral_tipo"
UPDATE bilhete SET tipo = 'D' WHERE id_bilhete = 1;

-- Teste 64: Apagar edição com passes gerais vendidos (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_passe_geral_edicao"
DELETE FROM edicao WHERE festival_nome = 'Lisboa Sounds' AND ano = 2027;

-- Teste 65: Bilhete diário duplicado para o mesmo bilhete
-- Erro esperado: [23505] unique_violation - restrição "pk_bilhete_diario"
INSERT INTO bilhete_diario VALUES (9, 'D', 'Verão em Sintra', 2025, '2025-08-15');

-- Teste 66: Bilhete diário sem o bilhete correspondente (superclasse)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_diario_bilhete"
INSERT INTO bilhete_diario VALUES (100, 'D', 'Verão em Sintra', 2025, '2025-08-15');

-- Teste 67: Disjunção: passe geral (id 1) também registado como bilhete diário
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_diario_bilhete"
INSERT INTO bilhete_diario VALUES (1, 'D', 'Verão em Sintra', 2025, '2025-08-15');

-- Teste 68: Discriminador do bilhete diário diferente de 'D'
-- Erro esperado: [23514] check_violation - restrição "ck_bilhete_diario_tipo"
INSERT INTO bilhete_diario VALUES (100, 'P', 'Verão em Sintra', 2025, '2025-08-15');

-- Teste 69: Bilhete diário de um dia inexistente
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_diario_dia"
UPDATE bilhete_diario SET data = '2025-08-20' WHERE id_bilhete = 9;

-- Teste 70: Apagar dia com bilhetes diários vendidos (ON DELETE RESTRICT)
-- Erro esperado: [23503] foreign_key_violation - restrição "fk_bilhete_diario_dia"
DELETE FROM dia WHERE festival_nome = 'Verão em Sintra' AND ano = 2025 AND data = '2025-08-16';
