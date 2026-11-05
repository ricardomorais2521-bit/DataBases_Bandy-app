-- =====================================================================
-- Bases de Dados 2026/27 - Projeto BANDyApp - Etapa 2 (E2)
-- Grupo 77
-- Script de criação (DDL) e população (DML) - PostgreSQL
--
-- Traduz o modelo Entidade-Associação de referência (enunciado E2).
-- Regras de passagem EA -> relacional aplicadas:
--  * Entidades fortes -> tabela com a sua chave primária.
--  * Entidades fracas (Edicao, Dia) -> chave primária = chave da entidade
--    identificadora + discriminador (FK com ON DELETE CASCADE).
--  * Associações N:1 (com ou sem participação total) -> chave estrangeira
--    na tabela do lado "N"; NOT NULL quando a participação é total.
--  * Associação N:N (segue) -> tabela própria com PK composta.
--  * Atributo multivalor {alergia} -> tabela utilizador_alergia.
--  * Atributos compostos (morada, emergência) -> colunas simples.
--  * Especialização total e disjunta de Bilhete -> uma tabela por entidade
--    (bilhete, passe_geral, bilhete_diario) + discriminador "tipo" com FK
--    composta (id_bilhete, tipo), que garante a disjunção.
--  * Atributo derivado preco_pago() -> vista v_bilhete (não é armazenado).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Remoção dos objetos existentes (permite executar repetidamente)
-- ---------------------------------------------------------------------
DROP VIEW  IF EXISTS v_bilhete CASCADE;
DROP TABLE IF EXISTS segue              CASCADE;
DROP TABLE IF EXISTS bilhete_diario     CASCADE;
DROP TABLE IF EXISTS passe_geral        CASCADE;
DROP TABLE IF EXISTS bilhete            CASCADE;
DROP TABLE IF EXISTS dispositivo        CASCADE;
DROP TABLE IF EXISTS utilizador_alergia CASCADE;
DROP TABLE IF EXISTS utilizador         CASCADE;
DROP TABLE IF EXISTS concerto           CASCADE;
DROP TABLE IF EXISTS artista            CASCADE;
DROP TABLE IF EXISTS dia                CASCADE;
DROP TABLE IF EXISTS edicao             CASCADE;
DROP TABLE IF EXISTS recinto            CASCADE;
DROP TABLE IF EXISTS festival           CASCADE;

-- ---------------------------------------------------------------------
-- 1. Festivais, recintos, edições e dias
-- ---------------------------------------------------------------------
CREATE TABLE festival (
    nome         VARCHAR(80) NOT NULL,
    ano_criacao  SMALLINT    NOT NULL,
    CONSTRAINT pk_festival PRIMARY KEY (nome)
);

CREATE TABLE recinto (
    nome            VARCHAR(80)  NOT NULL,
    -- atributo composto "morada" (rua, código postal, localidade)
    rua             VARCHAR(120) NOT NULL,
    codigo_postal   VARCHAR(8)   NOT NULL,
    localidade      VARCHAR(60)  NOT NULL,
    cidade          VARCHAR(60)  NOT NULL,
    capacidade_max  INTEGER      NOT NULL,
    CONSTRAINT pk_recinto PRIMARY KEY (nome),
    CONSTRAINT ck_recinto_codigo_postal
        CHECK (codigo_postal ~ '^[0-9]{4}-[0-9]{3}$'),
    CONSTRAINT ck_recinto_capacidade_max          -- RIA-12
        CHECK (capacidade_max > 0)
);

-- Entidade fraca de Festival (tem_edicao); decorre_em -> Recinto (total).
CREATE TABLE edicao (
    festival_nome  VARCHAR(80)   NOT NULL,
    ano            SMALLINT      NOT NULL,
    preco_passe    NUMERIC(8,2)  NOT NULL,
    recinto_nome   VARCHAR(80)   NOT NULL,        -- decorre_em (total)
    CONSTRAINT pk_edicao PRIMARY KEY (festival_nome, ano),
    CONSTRAINT fk_edicao_festival FOREIGN KEY (festival_nome)
        REFERENCES festival (nome) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_edicao_recinto FOREIGN KEY (recinto_nome)
        REFERENCES recinto (nome) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_edicao_preco_passe              -- RIA-12
        CHECK (preco_passe > 0)
);

-- Entidade fraca de Edicao (tem_dia).
CREATE TABLE dia (
    festival_nome  VARCHAR(80)   NOT NULL,
    ano            SMALLINT      NOT NULL,
    data           DATE          NOT NULL,
    preco_diario   NUMERIC(8,2)  NOT NULL,
    CONSTRAINT pk_dia PRIMARY KEY (festival_nome, ano, data),
    CONSTRAINT fk_dia_edicao FOREIGN KEY (festival_nome, ano)
        REFERENCES edicao (festival_nome, ano) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_dia_data_no_ano_da_edicao       -- RIA-1
        CHECK (EXTRACT(YEAR FROM data) = ano),
    CONSTRAINT ck_dia_preco_diario                -- RIA-12
        CHECK (preco_diario > 0)
);

-- ---------------------------------------------------------------------
-- 2. Artistas e concertos
-- ---------------------------------------------------------------------
CREATE TABLE artista (
    nome            VARCHAR(80) NOT NULL,
    genero_musical  VARCHAR(40) NOT NULL,
    tipo            VARCHAR(10) NOT NULL,
    CONSTRAINT pk_artista PRIMARY KEY (nome),
    CONSTRAINT ck_artista_tipo                    -- RIA-3
        CHECK (tipo IN ('artista', 'grupo'))
);

CREATE TABLE concerto (
    id_concerto    INTEGER      NOT NULL,
    hora_inicio    TIME         NOT NULL,
    hora_fim       TIME         NOT NULL,
    -- realizado (total): chave do Dia
    festival_nome  VARCHAR(80)  NOT NULL,
    ano            SMALLINT     NOT NULL,
    data           DATE         NOT NULL,
    -- atua (total): Artista
    artista_nome   VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_concerto PRIMARY KEY (id_concerto),
    CONSTRAINT fk_concerto_dia FOREIGN KEY (festival_nome, ano, data)
        REFERENCES dia (festival_nome, ano, data) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_concerto_artista FOREIGN KEY (artista_nome)
        REFERENCES artista (nome) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_concerto_horas                  -- RIA-2
        CHECK (hora_inicio < hora_fim)
);

-- ---------------------------------------------------------------------
-- 3. Utilizadores, dispositivos e seguidores
-- ---------------------------------------------------------------------
CREATE TABLE utilizador (
    email                VARCHAR(120) NOT NULL,
    nome                 VARCHAR(100) NOT NULL,
    data_nascimento      DATE         NOT NULL,
    -- atributo composto "emergência" (opcional)
    grupo_sanguineo      VARCHAR(3),
    contacto_emergencia  VARCHAR(20),
    CONSTRAINT pk_utilizador PRIMARY KEY (email),
    CONSTRAINT ck_utilizador_email
        CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    CONSTRAINT ck_utilizador_grupo_sanguineo
        CHECK (grupo_sanguineo IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);

-- Atributo multivalor {alergia}
CREATE TABLE utilizador_alergia (
    email    VARCHAR(120) NOT NULL,
    alergia  VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_utilizador_alergia PRIMARY KEY (email, alergia),
    CONSTRAINT fk_utilizador_alergia_utilizador FOREIGN KEY (email)
        REFERENCES utilizador (email) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE dispositivo (
    num_serie     VARCHAR(20)   NOT NULL,
    saldo         NUMERIC(10,2) NOT NULL DEFAULT 0,
    estado        VARCHAR(10)   NOT NULL,
    titular_email VARCHAR(120)  NOT NULL,         -- pertence (total)
    CONSTRAINT pk_dispositivo PRIMARY KEY (num_serie),
    CONSTRAINT fk_dispositivo_titular FOREIGN KEY (titular_email)
        REFERENCES utilizador (email) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_dispositivo_estado              -- RIA-7
        CHECK (estado IN ('ativo', 'bloqueado', 'extraviado')),
    CONSTRAINT ck_dispositivo_saldo               -- RIA-7
        CHECK (saldo >= 0)
);

-- RIA-8: no máximo um dispositivo "ativo" por utilizador
-- (UNIQUE parcial, só sobre as linhas com estado = 'ativo').
CREATE UNIQUE INDEX uq_dispositivo_um_ativo_por_titular
    ON dispositivo (titular_email) WHERE estado = 'ativo';

-- Associação N:N reflexiva "segue" (seguidor -> seguido)
CREATE TABLE segue (
    seguidor_email  VARCHAR(120) NOT NULL,
    seguido_email   VARCHAR(120) NOT NULL,
    CONSTRAINT pk_segue PRIMARY KEY (seguidor_email, seguido_email),
    CONSTRAINT fk_segue_seguidor FOREIGN KEY (seguidor_email)
        REFERENCES utilizador (email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_segue_seguido FOREIGN KEY (seguido_email)
        REFERENCES utilizador (email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_segue_nao_a_si_proprio          -- RIA-11
        CHECK (seguidor_email <> seguido_email)
);

-- ---------------------------------------------------------------------
-- 4. Bilhetes (especialização total e disjunta: PasseGeral | BilheteDiario)
-- ---------------------------------------------------------------------
CREATE TABLE bilhete (
    id_bilhete        INTEGER      NOT NULL,
    data_compra       DATE         NOT NULL,
    tipo              CHAR(1)      NOT NULL,      -- discriminador: P | D
    comprador_email   VARCHAR(120) NOT NULL,      -- compra (total)
    num_serie         VARCHAR(20),                -- usa (parcial: pode estar por associar)
    CONSTRAINT pk_bilhete PRIMARY KEY (id_bilhete),
    CONSTRAINT uq_bilhete_id_tipo UNIQUE (id_bilhete, tipo),  -- alvo das FKs das subclasses
    CONSTRAINT fk_bilhete_comprador FOREIGN KEY (comprador_email)
        REFERENCES utilizador (email) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bilhete_dispositivo FOREIGN KEY (num_serie)
        REFERENCES dispositivo (num_serie) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT ck_bilhete_tipo
        CHECK (tipo IN ('P', 'D'))
);

CREATE TABLE passe_geral (
    id_bilhete     INTEGER      NOT NULL,
    tipo           CHAR(1)      NOT NULL DEFAULT 'P',
    festival_nome  VARCHAR(80)  NOT NULL,         -- passe_de (total)
    ano            SMALLINT     NOT NULL,
    CONSTRAINT pk_passe_geral PRIMARY KEY (id_bilhete),
    CONSTRAINT ck_passe_geral_tipo CHECK (tipo = 'P'),
    CONSTRAINT fk_passe_geral_bilhete FOREIGN KEY (id_bilhete, tipo)
        REFERENCES bilhete (id_bilhete, tipo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_passe_geral_edicao FOREIGN KEY (festival_nome, ano)
        REFERENCES edicao (festival_nome, ano) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE bilhete_diario (
    id_bilhete     INTEGER      NOT NULL,
    tipo           CHAR(1)      NOT NULL DEFAULT 'D',
    festival_nome  VARCHAR(80)  NOT NULL,         -- dá_acesso (total)
    ano            SMALLINT     NOT NULL,
    data           DATE         NOT NULL,
    CONSTRAINT pk_bilhete_diario PRIMARY KEY (id_bilhete),
    CONSTRAINT ck_bilhete_diario_tipo CHECK (tipo = 'D'),
    CONSTRAINT fk_bilhete_diario_bilhete FOREIGN KEY (id_bilhete, tipo)
        REFERENCES bilhete (id_bilhete, tipo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bilhete_diario_dia FOREIGN KEY (festival_nome, ano, data)
        REFERENCES dia (festival_nome, ano, data) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RIA-6: preco_pago() é derivado; não se armazena, calcula-se nesta vista.
--   passe geral  -> preco_passe da Edição
--   bilhete diário -> preco_diario do Dia
CREATE VIEW v_bilhete AS
SELECT b.id_bilhete,
       b.data_compra,
       b.tipo,
       b.comprador_email,
       b.num_serie,
       COALESCE(e.preco_passe, d.preco_diario) AS preco_pago
FROM bilhete b
LEFT JOIN passe_geral    pg ON pg.id_bilhete = b.id_bilhete
LEFT JOIN edicao         e  ON e.festival_nome = pg.festival_nome AND e.ano = pg.ano
LEFT JOIN bilhete_diario bd ON bd.id_bilhete = b.id_bilhete
LEFT JOIN dia            d  ON d.festival_nome = bd.festival_nome
                           AND d.ano = bd.ano AND d.data = bd.data;

-- =====================================================================
-- POPULAÇÃO DE DADOS
-- =====================================================================

-- Festivais (3)
INSERT INTO festival (nome, ano_criacao) VALUES
  ('Lisboa Sounds',   2012),
  ('Verão em Sintra', 2018),
  ('Algarve Beats',   2021);

-- Recintos (4)
INSERT INTO recinto (nome, rua, codigo_postal, localidade, cidade, capacidade_max) VALUES
  ('Passeio Marítimo de Algés', 'Passeio Marítimo de Algés', '1495-165', 'Algés',    'Oeiras',  55000),
  ('Parque Tejo Norte',         'Avenida Dom João II',       '1990-094', 'Lisboa',   'Lisboa',  40000),
  ('Arena de Sintra',           'Estrada da Lagoa Azul',     '2710-297', 'Sintra',   'Sintra',  15000),
  ('Arena Portimão Beach',      'Avenida Tomás Cabreira',    '8500-802', 'Portimão', 'Portimão',20000);

-- Edições (6)
-- CASO LIMITE: "Lisboa Sounds" mudou de recinto entre 2025 (Algés) e 2026 (Parque Tejo Norte).
INSERT INTO edicao (festival_nome, ano, preco_passe, recinto_nome) VALUES
  ('Lisboa Sounds',   2025, 189.90, 'Passeio Marítimo de Algés'),   -- 5 dias
  ('Lisboa Sounds',   2026, 199.90, 'Parque Tejo Norte'),           -- 3 dias (mudou de recinto)
  ('Lisboa Sounds',   2027, 209.90, 'Parque Tejo Norte'),           -- 3 dias (bilhetes à venda)
  ('Verão em Sintra', 2025,  79.00, 'Arena de Sintra'),             -- 2 dias
  ('Verão em Sintra', 2026,  89.00, 'Arena de Sintra'),             -- 2 dias
  ('Algarve Beats',   2026, 129.00, 'Arena Portimão Beach');        -- 3 dias

-- Dias (18)
-- CASO LIMITE: edições com 2 dias (Verão em Sintra) e com 5 dias (Lisboa Sounds 2025).
INSERT INTO dia (festival_nome, ano, data, preco_diario) VALUES
  ('Lisboa Sounds',   2025, '2025-07-09', 55.00),
  ('Lisboa Sounds',   2025, '2025-07-10', 65.00),
  ('Lisboa Sounds',   2025, '2025-07-11', 75.00),
  ('Lisboa Sounds',   2025, '2025-07-12', 75.00),
  ('Lisboa Sounds',   2025, '2025-07-13', 85.00),
  ('Lisboa Sounds',   2026, '2026-07-08', 69.00),
  ('Lisboa Sounds',   2026, '2026-07-09', 79.00),
  ('Lisboa Sounds',   2026, '2026-07-10', 89.00),
  ('Lisboa Sounds',   2027, '2027-07-07', 75.00),
  ('Lisboa Sounds',   2027, '2027-07-08', 85.00),
  ('Lisboa Sounds',   2027, '2027-07-09', 95.00),
  ('Verão em Sintra', 2025, '2025-08-15', 45.00),
  ('Verão em Sintra', 2025, '2025-08-16', 50.00),
  ('Verão em Sintra', 2026, '2026-08-14', 49.00),
  ('Verão em Sintra', 2026, '2026-08-15', 55.00),
  ('Algarve Beats',   2026, '2026-08-27', 40.00),
  ('Algarve Beats',   2026, '2026-08-28', 50.00),
  ('Algarve Beats',   2026, '2026-08-29', 60.00);

-- Artistas (8)
-- CASO LIMITE: artistas a solo (tipo 'artista') e grupos (tipo 'grupo').
INSERT INTO artista (nome, genero_musical, tipo) VALUES
  ('Marisa Alvim',    'Fado',       'artista'),
  ('Os Maré Viva',    'Rock',       'grupo'),
  ('Kaelo',           'Eletrónica', 'artista'),
  ('Banda Horizonte', 'Pop',        'grupo'),
  ('Inês Valadares',  'Pop',        'artista'),
  ('Trio Sal e Mar',  'Folk',       'grupo'),
  ('Duarte Pinheiro', 'Hip-Hop',    'artista'),
  ('Luz Nocturna',    'Indie',      'grupo');

-- Concertos (16): todos em dias das respetivas edições
INSERT INTO concerto (id_concerto, hora_inicio, hora_fim, festival_nome, ano, data, artista_nome) VALUES
  ( 1, '20:00', '21:30', 'Lisboa Sounds',   2025, '2025-07-09', 'Os Maré Viva'),
  ( 2, '22:00', '23:45', 'Lisboa Sounds',   2025, '2025-07-09', 'Kaelo'),
  ( 3, '21:00', '22:30', 'Lisboa Sounds',   2025, '2025-07-10', 'Marisa Alvim'),
  ( 4, '21:30', '23:00', 'Lisboa Sounds',   2025, '2025-07-11', 'Banda Horizonte'),
  ( 5, '20:30', '22:00', 'Lisboa Sounds',   2025, '2025-07-12', 'Inês Valadares'),
  ( 6, '22:30', '23:50', 'Lisboa Sounds',   2025, '2025-07-13', 'Duarte Pinheiro'),
  ( 7, '19:00', '20:15', 'Lisboa Sounds',   2026, '2026-07-08', 'Luz Nocturna'),
  ( 8, '21:30', '23:00', 'Lisboa Sounds',   2026, '2026-07-09', 'Os Maré Viva'),
  ( 9, '21:00', '22:30', 'Lisboa Sounds',   2026, '2026-07-10', 'Banda Horizonte'),
  (10, '18:30', '19:45', 'Verão em Sintra', 2026, '2026-08-14', 'Trio Sal e Mar'),
  (11, '21:00', '22:45', 'Verão em Sintra', 2026, '2026-08-15', 'Marisa Alvim'),
  (12, '20:00', '21:30', 'Algarve Beats',   2026, '2026-08-28', 'Kaelo'),
  (13, '22:00', '23:30', 'Algarve Beats',   2026, '2026-08-29', 'Inês Valadares'),
  (14, '19:30', '20:30', 'Verão em Sintra', 2025, '2025-08-15', 'Trio Sal e Mar'),
  (15, '21:00', '22:30', 'Lisboa Sounds',   2027, '2027-07-08', 'Os Maré Viva'),
  (16, '20:00', '21:00', 'Algarve Beats',   2026, '2026-08-27', 'Luz Nocturna');

-- Utilizadores (8)
-- CASO LIMITE: Diogo não tem dados de emergência (atributos opcionais a NULL).
INSERT INTO utilizador (email, nome, data_nascimento, grupo_sanguineo, contacto_emergencia) VALUES
  ('ana.ferreira@exemplo.pt',   'Ana Ferreira',   '1998-03-14', 'A+',  '912345678'),
  ('bruno.costa@exemplo.pt',    'Bruno Costa',    '1995-11-02', 'O-',  '913456789'),
  ('carla.mendes@exemplo.pt',   'Carla Mendes',   '2001-07-21', 'B+',  '914567890'),
  ('diogo.pereira@exemplo.pt',  'Diogo Pereira',  '1989-01-30', NULL,  NULL),
  ('elisa.santos@exemplo.pt',   'Elisa Santos',   '2003-05-09', 'AB+', '916789012'),
  ('filipe.rocha@exemplo.pt',   'Filipe Rocha',   '1999-09-18', 'O+',  '917890123'),
  ('gabriela.lopes@exemplo.pt', 'Gabriela Lopes', '1992-12-05', 'A-',  '918901234'),
  ('hugo.martins@exemplo.pt',   'Hugo Martins',   '2000-04-27', 'B-',  '919012345');

-- Alergias (6): Ana tem duas; vários utilizadores não têm nenhuma
INSERT INTO utilizador_alergia (email, alergia) VALUES
  ('ana.ferreira@exemplo.pt', 'Amendoim'),
  ('ana.ferreira@exemplo.pt', 'Pólen'),
  ('bruno.costa@exemplo.pt',  'Glúten'),
  ('carla.mendes@exemplo.pt', 'Lactose'),
  ('elisa.santos@exemplo.pt', 'Marisco'),
  ('hugo.martins@exemplo.pt', 'Penicilina');

-- Dispositivos (10)
-- CASOS LIMITE:
--  * Ana: BD-0010 extraviado + BD-0001 ativo (novo dispositivo).
--  * Bruno: BD-0002 extraviado + BD-0003 ativo (novo dispositivo).
--  * Diogo: BD-0005 bloqueado + BD-0006 ativo (novo dispositivo).
--  * Elisa: dispositivo ativo com saldo 0.
--  * Hugo: ainda não levantou nenhum BANDy.
INSERT INTO dispositivo (num_serie, saldo, estado, titular_email) VALUES
  ('BD-0001',  45.50, 'ativo',      'ana.ferreira@exemplo.pt'),
  ('BD-0002',  12.00, 'extraviado', 'bruno.costa@exemplo.pt'),
  ('BD-0003',  80.00, 'ativo',      'bruno.costa@exemplo.pt'),
  ('BD-0004',  20.00, 'ativo',      'carla.mendes@exemplo.pt'),
  ('BD-0005',   5.00, 'bloqueado',  'diogo.pereira@exemplo.pt'),
  ('BD-0006', 150.00, 'ativo',      'diogo.pereira@exemplo.pt'),
  ('BD-0007',   0.00, 'ativo',      'elisa.santos@exemplo.pt'),
  ('BD-0008',  62.75, 'ativo',      'filipe.rocha@exemplo.pt'),
  ('BD-0009',  33.00, 'ativo',      'gabriela.lopes@exemplo.pt'),
  ('BD-0010',   0.00, 'extraviado', 'ana.ferreira@exemplo.pt');

-- Seguidores (8)
-- CASO LIMITE: amizades não recíprocas (só Ana <-> Bruno é recíproca).
INSERT INTO segue (seguidor_email, seguido_email) VALUES
  ('ana.ferreira@exemplo.pt',   'bruno.costa@exemplo.pt'),
  ('bruno.costa@exemplo.pt',    'ana.ferreira@exemplo.pt'),
  ('carla.mendes@exemplo.pt',   'ana.ferreira@exemplo.pt'),
  ('diogo.pereira@exemplo.pt',  'elisa.santos@exemplo.pt'),
  ('elisa.santos@exemplo.pt',   'ana.ferreira@exemplo.pt'),
  ('filipe.rocha@exemplo.pt',   'gabriela.lopes@exemplo.pt'),
  ('hugo.martins@exemplo.pt',   'gabriela.lopes@exemplo.pt'),
  ('gabriela.lopes@exemplo.pt', 'carla.mendes@exemplo.pt');

-- Bilhetes (18): superclasse
-- CASOS LIMITE:
--  * Bilhetes comprados para terceiros: 5 (Diogo compra para a Elisa, titular do BD-0007)
--    e 8 (Gabriela compra para o Hugo).
--  * Bilhetes ainda por associar a dispositivo (num_serie NULL): 7, 8 e 14, todos da
--    edição futura Lisboa Sounds 2027.
--  * Compra no próprio dia do espetáculo: 18.
INSERT INTO bilhete (id_bilhete, data_compra, tipo, comprador_email, num_serie) VALUES
  ( 1, '2025-03-10', 'P', 'ana.ferreira@exemplo.pt',   'BD-0010'),
  ( 2, '2025-03-12', 'P', 'bruno.costa@exemplo.pt',    'BD-0002'),
  ( 3, '2026-03-01', 'P', 'ana.ferreira@exemplo.pt',   'BD-0001'),
  ( 4, '2026-02-20', 'P', 'carla.mendes@exemplo.pt',   'BD-0004'),
  ( 5, '2026-04-02', 'P', 'diogo.pereira@exemplo.pt',  'BD-0007'),
  ( 6, '2026-06-15', 'P', 'filipe.rocha@exemplo.pt',   'BD-0008'),
  ( 7, '2026-10-20', 'P', 'bruno.costa@exemplo.pt',    NULL),
  ( 8, '2026-10-22', 'P', 'gabriela.lopes@exemplo.pt', NULL),
  ( 9, '2025-06-01', 'D', 'carla.mendes@exemplo.pt',   'BD-0004'),
  (10, '2026-05-10', 'D', 'filipe.rocha@exemplo.pt',   'BD-0008'),
  (11, '2026-05-11', 'D', 'gabriela.lopes@exemplo.pt', 'BD-0009'),
  (12, '2026-07-20', 'D', 'diogo.pereira@exemplo.pt',  'BD-0006'),
  (13, '2026-07-25', 'D', 'elisa.santos@exemplo.pt',   'BD-0007'),
  (14, '2026-10-25', 'D', 'carla.mendes@exemplo.pt',   NULL),
  (15, '2025-05-05', 'D', 'ana.ferreira@exemplo.pt',   'BD-0010'),
  (16, '2026-06-01', 'D', 'bruno.costa@exemplo.pt',    'BD-0003'),
  (17, '2025-05-20', 'D', 'diogo.pereira@exemplo.pt',  'BD-0005'),
  (18, '2026-08-29', 'D', 'gabriela.lopes@exemplo.pt', 'BD-0009');

-- Passes gerais (8): bilhetes 1 a 8
INSERT INTO passe_geral (id_bilhete, festival_nome, ano) VALUES
  (1, 'Lisboa Sounds', 2025),
  (2, 'Lisboa Sounds', 2025),
  (3, 'Lisboa Sounds', 2026),
  (4, 'Lisboa Sounds', 2026),
  (5, 'Lisboa Sounds', 2026),
  (6, 'Algarve Beats', 2026),
  (7, 'Lisboa Sounds', 2027),
  (8, 'Lisboa Sounds', 2027);

-- Bilhetes diários (10): bilhetes 9 a 18
INSERT INTO bilhete_diario (id_bilhete, festival_nome, ano, data) VALUES
  ( 9, 'Verão em Sintra', 2025, '2025-08-15'),
  (10, 'Verão em Sintra', 2026, '2026-08-14'),
  (11, 'Verão em Sintra', 2026, '2026-08-15'),
  (12, 'Algarve Beats',   2026, '2026-08-29'),
  (13, 'Algarve Beats',   2026, '2026-08-28'),
  (14, 'Lisboa Sounds',   2027, '2027-07-09'),
  (15, 'Verão em Sintra', 2025, '2025-08-16'),
  (16, 'Algarve Beats',   2026, '2026-08-27'),
  (17, 'Verão em Sintra', 2025, '2025-08-15'),
  (18, 'Algarve Beats',   2026, '2026-08-29');

-- =====================================================================
-- VERIFICAÇÕES DOS DADOS vs. RESTRIÇÕES NÃO IMPLEMENTADAS NO SQL
-- (todas as consultas devem devolver 0 linhas; ver relatório)
-- =====================================================================

-- Datas de acesso de cada bilhete (passe geral = todos os dias da edição)
-- RIA-4: ocupação por dia acima da capacidade do recinto
SELECT d.festival_nome, d.ano, d.data
FROM dia d
JOIN edicao e  ON e.festival_nome = d.festival_nome AND e.ano = d.ano
JOIN recinto r ON r.nome = e.recinto_nome
WHERE (SELECT COUNT(*) FROM passe_geral pg
        WHERE pg.festival_nome = d.festival_nome AND pg.ano = d.ano)
    + (SELECT COUNT(*) FROM bilhete_diario bd
        WHERE bd.festival_nome = d.festival_nome AND bd.ano = d.ano AND bd.data = d.data)
      > r.capacidade_max;

-- RIA-5: data_compra posterior ao primeiro dia de acesso
SELECT b.id_bilhete
FROM bilhete b
LEFT JOIN passe_geral pg ON pg.id_bilhete = b.id_bilhete
LEFT JOIN bilhete_diario bd ON bd.id_bilhete = b.id_bilhete
WHERE b.data_compra > COALESCE(
        (SELECT MIN(d.data) FROM dia d
          WHERE d.festival_nome = pg.festival_nome AND d.ano = pg.ano),
        bd.data);

-- RIA-9 (parte verificável): bilhetes cujo primeiro dia já passou sem dispositivo associado
SELECT b.id_bilhete
FROM bilhete b
LEFT JOIN passe_geral pg ON pg.id_bilhete = b.id_bilhete
LEFT JOIN bilhete_diario bd ON bd.id_bilhete = b.id_bilhete
WHERE b.num_serie IS NULL
  AND COALESCE(
        (SELECT MIN(d.data) FROM dia d
          WHERE d.festival_nome = pg.festival_nome AND d.ano = pg.ano),
        bd.data) < CURRENT_DATE;

-- RIA-10: dispositivo associado a dois bilhetes com acesso à mesma data
SELECT acesso.num_serie, acesso.data
FROM (
    SELECT b.num_serie, b.id_bilhete, d.data
    FROM bilhete b
    JOIN passe_geral pg ON pg.id_bilhete = b.id_bilhete
    JOIN dia d ON d.festival_nome = pg.festival_nome AND d.ano = pg.ano
    WHERE b.num_serie IS NOT NULL
  UNION ALL
    SELECT b.num_serie, b.id_bilhete, bd.data
    FROM bilhete b
    JOIN bilhete_diario bd ON bd.id_bilhete = b.id_bilhete
    WHERE b.num_serie IS NOT NULL
) acesso
GROUP BY acesso.num_serie, acesso.data
HAVING COUNT(*) > 1;

-- Totalidade da especialização de Bilhete: bilhete sem linha na subclasse
SELECT b.id_bilhete
FROM bilhete b
WHERE (b.tipo = 'P' AND NOT EXISTS (SELECT 1 FROM passe_geral pg WHERE pg.id_bilhete = b.id_bilhete))
   OR (b.tipo = 'D' AND NOT EXISTS (SELECT 1 FROM bilhete_diario bd WHERE bd.id_bilhete = b.id_bilhete));

-- Cardinalidade 2..5 de tem_dia: edições com menos de 2 ou mais de 5 dias
SELECT e.festival_nome, e.ano, COUNT(d.data) AS n_dias
FROM edicao e
LEFT JOIN dia d ON d.festival_nome = e.festival_nome AND d.ano = e.ano
GROUP BY e.festival_nome, e.ano
HAVING COUNT(d.data) NOT BETWEEN 2 AND 5;
