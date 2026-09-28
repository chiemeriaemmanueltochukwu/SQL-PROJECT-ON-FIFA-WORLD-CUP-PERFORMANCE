-- ============================================================
-- FIFA WORLD CUP 2026
-- PLAYER PERFORMANCE DATA WAREHOUSE
-- PostgreSQL
-- ============================================================
--
-- PROJECT STRUCTURE
--
-- 01. Database Roles
-- 02. Source / Raw Data Table
-- 03. Data Quality Checks
-- 04. Data Warehouse Schema
-- 05. Dimension: Player
-- 06. Dimension: Team
-- 07. Dimension: Stadium
-- 08. Dimension: Match
-- 09. Fact: Player Match
-- 10. Opponent Team Enrichment
-- 11. Match Context Enrichment
-- 12. Fact: Player Tournament
-- 13. Star Schema Validation
-- 14. Foreign Key Validation
-- 15. Data Analyst Privilege Testing
-- 16. Data Scientist / ML Schema
--
-- ============================================================



-- ============================================================
-- 01. DATABASE ROLES
-- ============================================================
--
-- Roles:
-- fifa_admin
-- fifa_analyst
-- fifa_data_scientist
--
-- NOTE:
-- The CREATE ROLE statements below are commented because
-- these roles may already exist in the database.
--
-- ============================================================

BEGIN;

-- Run these ONLY if the roles do not already exist.

-- CREATE ROLE fifa_admin
-- LOGIN
-- PASSWORD 'YOUR_ADMIN_PASSWORD';

-- CREATE ROLE fifa_analyst
-- LOGIN
-- PASSWORD 'YOUR_ANALYST_PASSWORD';

-- CREATE ROLE fifa_data_scientist
-- LOGIN
-- PASSWORD 'YOUR_DATA_SCIENTIST_PASSWORD';


-- ------------------------------------------------------------
-- Admin privileges
-- ------------------------------------------------------------

GRANT CONNECT
ON DATABASE postgres
TO fifa_admin;

GRANT USAGE
ON SCHEMA fifa_dw
TO fifa_admin;

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA fifa_dw
TO fifa_admin;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA fifa_dw
TO fifa_admin;


-- ------------------------------------------------------------
-- Analyst privileges
-- ------------------------------------------------------------

GRANT CONNECT
ON DATABASE postgres
TO fifa_analyst;

GRANT USAGE
ON SCHEMA fifa_dw
TO fifa_analyst;

GRANT SELECT
ON ALL TABLES IN SCHEMA fifa_dw
TO fifa_analyst;

GRANT USAGE
ON SCHEMA public
TO fifa_analyst;

GRANT SELECT
ON public.fifa_player_performance
TO fifa_analyst;


-- ------------------------------------------------------------
-- Data Scientist privileges
-- ------------------------------------------------------------

GRANT CONNECT
ON DATABASE postgres
TO fifa_data_scientist;


COMMIT;



-- ============================================================
-- 02. VERIFY DATABASE ROLES
-- ============================================================

SELECT
    rolname,
    rolcanlogin,
    rolsuper
FROM pg_roles
WHERE rolname IN
(
    'fifa_admin',
    'fifa_analyst',
    'fifa_data_scientist',
    'postgres'
);



-- ============================================================
-- 03. SOURCE / RAW DATA TABLE
-- ============================================================
--
-- This table stores the original FIFA player-performance data.
--
-- Important:
-- player_id and match_id are VARCHAR because values such as
-- P00055 and M00001 are identifiers, not integers.
--
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.fifa_player_performance
(
    player_id VARCHAR(20),
    player_name VARCHAR(100),
    age INTEGER,
    nationality VARCHAR(100),
    team VARCHAR(100),
    jersey_number INTEGER,
    position VARCHAR(50),
    height_cm INTEGER,
    weight_kg DECIMAL(6,2),
    preferred_foot VARCHAR(20),
    club_name VARCHAR(150),
    market_value_eur DECIMAL(15,2),

    match_id VARCHAR(20),
    match_date DATE,
    stadium VARCHAR(150),
    city VARCHAR(100),
    opponent_team VARCHAR(100),
    tournament_stage VARCHAR(50),
    match_result VARCHAR(20),

    goals_team INTEGER,
    goals_opponent INTEGER,
    minutes_played INTEGER,

    goals INTEGER,
    assists INTEGER,
    shots INTEGER,
    shots_on_target INTEGER,
    expected_goals_xg DECIMAL(8,3),
    expected_assists_xa DECIMAL(8,3),
    key_passes INTEGER,
    successful_passes INTEGER,
    total_passes INTEGER,
    pass_accuracy DECIMAL(6,2),

    dribbles_attempted INTEGER,
    successful_dribbles INTEGER,
    crosses INTEGER,
    successful_crosses INTEGER,

    tackles INTEGER,
    interceptions INTEGER,
    clearances INTEGER,
    blocks INTEGER,
    aerial_duels_won INTEGER,
    aerial_duels_lost INTEGER,
    recoveries INTEGER,
    defensive_actions INTEGER,

    fouls_committed INTEGER,
    fouls_suffered INTEGER,
    yellow_cards INTEGER,
    red_cards INTEGER,
    offsides INTEGER,

    saves INTEGER,
    save_percentage DECIMAL(6,2),
    punches INTEGER,
    clean_sheet BOOLEAN,
    goals_conceded INTEGER,
    penalty_saves INTEGER,

    distance_covered_km DECIMAL(8,2),
    sprint_distance_km DECIMAL(8,2),
    top_speed_kmh DECIMAL(8,2),
    accelerations INTEGER,
    decelerations INTEGER,
    stamina_score DECIMAL(6,2),

    player_rating DECIMAL(6,2),
    performance_score DECIMAL(6,2),
    offensive_contribution DECIMAL(6,2),
    defensive_contribution DECIMAL(6,2),
    possession_impact DECIMAL(6,2),
    pressure_resistance DECIMAL(6,2),
    creativity_score DECIMAL(6,2),
    consistency_score DECIMAL(6,2),
    clutch_performance_score DECIMAL(6,2),

    total_goals_tournament INTEGER,
    total_assists_tournament INTEGER,
    total_minutes_tournament INTEGER,
    player_of_match_awards INTEGER,
    tournament_rating DECIMAL(6,2)
);

COMMIT;



-- ============================================================
-- 04. LOAD CSV DATA
-- ============================================================
--
-- Update the path if the CSV is stored somewhere else.
--
-- COPY must be executed by a PostgreSQL server that can access
-- the specified file path.
--
-- ============================================================

COPY public.fifa_player_performance
FROM 'C:\Users\user\Downloads\FIFA WORLD CUP 2026 player performance Dataset\fifa_world_cup_2026_player_performance.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);



-- ============================================================
-- 05. SOURCE DATA VALIDATION
-- ============================================================

-- Total number of records

SELECT
    COUNT(*) AS total_rows
FROM public.fifa_player_performance;


-- ------------------------------------------------------------
-- Check duplicate player-match combinations
-- ------------------------------------------------------------

SELECT
    player_id,
    match_id,
    COUNT(*) AS record_count
FROM public.fifa_player_performance
GROUP BY
    player_id,
    match_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Inspect loaded records
-- ------------------------------------------------------------

SELECT
    player_id,
    player_name,
    match_id,
    match_date
FROM public.fifa_player_performance
LIMIT 20;


-- ------------------------------------------------------------
-- Check important NULL values
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(player_id) AS player_id_filled,
    COUNT(player_name) AS player_name_filled,
    COUNT(age) AS age_filled,
    COUNT(team) AS team_filled,
    COUNT(position) AS position_filled,
    COUNT(match_id) AS match_id_filled,
    COUNT(match_date) AS match_date_filled,
    COUNT(player_rating) AS player_rating_filled,
    COUNT(tournament_rating) AS tournament_rating_filled
FROM public.fifa_player_performance;



-- ============================================================
-- 06. CREATE DATA WAREHOUSE SCHEMA
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS fifa_dw;

COMMIT;



-- ============================================================
-- 07. DIMENSION: PLAYER
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.dim_player
(
    player_key SERIAL PRIMARY KEY,

    player_id VARCHAR(20) UNIQUE NOT NULL,

    player_name VARCHAR(100),
    age INTEGER,
    nationality VARCHAR(100),
    position VARCHAR(50),
    height_cm INTEGER,
    weight_kg DECIMAL(6,2),
    preferred_foot VARCHAR(20),
    club_name VARCHAR(150),
    market_value_eur DECIMAL(15,2)
);


INSERT INTO fifa_dw.dim_player
(
    player_id,
    player_name,
    age,
    nationality,
    position,
    height_cm,
    weight_kg,
    preferred_foot,
    club_name,
    market_value_eur
)
SELECT DISTINCT
    player_id,
    player_name,
    age,
    nationality,
    position,
    height_cm,
    weight_kg,
    preferred_foot,
    club_name,
    market_value_eur
FROM public.fifa_player_performance
WHERE player_id IS NOT NULL
ON CONFLICT (player_id) DO NOTHING;


COMMIT;



-- ============================================================
-- 08. DIMENSION: TEAM
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.dim_team
(
    team_key SERIAL PRIMARY KEY,
    team_name VARCHAR(100) UNIQUE NOT NULL
);


INSERT INTO fifa_dw.dim_team
(
    team_name
)
SELECT DISTINCT
    team
FROM public.fifa_player_performance
WHERE team IS NOT NULL
ON CONFLICT (team_name) DO NOTHING;


COMMIT;



-- ============================================================
-- 09. DIMENSION: STADIUM
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.dim_stadium
(
    stadium_key SERIAL PRIMARY KEY,
    stadium_name VARCHAR(150) NOT NULL,
    city VARCHAR(100)
);


INSERT INTO fifa_dw.dim_stadium
(
    stadium_name,
    city
)
SELECT DISTINCT
    stadium,
    city
FROM public.fifa_player_performance
WHERE stadium IS NOT NULL;


COMMIT;



-- ============================================================
-- 10. DIMENSION: MATCH
-- ============================================================
--
-- One record per match.
--
-- The source table contains multiple player records for the same
-- match, so aggregation using GROUP BY match_id is required.
--
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.dim_match
(
    match_key SERIAL PRIMARY KEY,
    match_id VARCHAR(20) UNIQUE NOT NULL,
    match_date DATE,
    tournament_stage VARCHAR(50)
);


INSERT INTO fifa_dw.dim_match
(
    match_id,
    match_date,
    tournament_stage
)
SELECT
    match_id,
    MAX(match_date) AS match_date,
    MAX(tournament_stage) AS tournament_stage
FROM public.fifa_player_performance
WHERE match_id IS NOT NULL
GROUP BY match_id
ON CONFLICT (match_id) DO NOTHING;


COMMIT;



-- ============================================================
-- 11. VERIFY DIMENSIONS
-- ============================================================

SELECT
    'dim_player' AS table_name,
    COUNT(*) AS row_count
FROM fifa_dw.dim_player

UNION ALL

SELECT
    'dim_team',
    COUNT(*)
FROM fifa_dw.dim_team

UNION ALL

SELECT
    'dim_match',
    COUNT(*)
FROM fifa_dw.dim_match

UNION ALL

SELECT
    'dim_stadium',
    COUNT(*)
FROM fifa_dw.dim_stadium;



-- ============================================================
-- 12. FACT TABLE: PLAYER MATCH
-- ============================================================
--
-- Grain:
-- One row = one player participating in one match.
--
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.fact_player_match
(
    player_key INTEGER NOT NULL,
    team_key INTEGER NOT NULL,
    match_key INTEGER NOT NULL,
    stadium_key INTEGER,

    minutes_played INTEGER,
    goals INTEGER,
    assists INTEGER,
    shots INTEGER,
    shots_on_target INTEGER,

    expected_goals_xg DECIMAL(8,3),
    expected_assists_xa DECIMAL(8,3),
    key_passes INTEGER,

    successful_passes INTEGER,
    total_passes INTEGER,
    pass_accuracy DECIMAL(6,2),

    dribbles_attempted INTEGER,
    successful_dribbles INTEGER,
    crosses INTEGER,
    successful_crosses INTEGER,

    tackles INTEGER,
    interceptions INTEGER,
    clearances INTEGER,
    blocks INTEGER,

    aerial_duels_won INTEGER,
    aerial_duels_lost INTEGER,
    recoveries INTEGER,
    defensive_actions INTEGER,

    fouls_committed INTEGER,
    fouls_suffered INTEGER,
    yellow_cards INTEGER,
    red_cards INTEGER,
    offsides INTEGER,

    saves INTEGER,
    save_percentage DECIMAL(6,2),
    punches INTEGER,
    clean_sheet BOOLEAN,
    goals_conceded INTEGER,
    penalty_saves INTEGER,

    distance_covered_km DECIMAL(8,2),
    sprint_distance_km DECIMAL(8,2),
    top_speed_kmh DECIMAL(8,2),
    accelerations INTEGER,
    decelerations INTEGER,
    stamina_score DECIMAL(6,2),

    player_rating DECIMAL(6,2),
    performance_score DECIMAL(6,2),
    offensive_contribution DECIMAL(6,2),
    defensive_contribution DECIMAL(6,2),
    possession_impact DECIMAL(6,2),
    pressure_resistance DECIMAL(6,2),
    creativity_score DECIMAL(6,2),
    consistency_score DECIMAL(6,2),
    clutch_performance_score DECIMAL(6,2),

    CONSTRAINT fk_player
        FOREIGN KEY (player_key)
        REFERENCES fifa_dw.dim_player(player_key),

    CONSTRAINT fk_team
        FOREIGN KEY (team_key)
        REFERENCES fifa_dw.dim_team(team_key),

    CONSTRAINT fk_match
        FOREIGN KEY (match_key)
        REFERENCES fifa_dw.dim_match(match_key),

    CONSTRAINT fk_stadium
        FOREIGN KEY (stadium_key)
        REFERENCES fifa_dw.dim_stadium(stadium_key),

    CONSTRAINT pk_fact_player_match
        PRIMARY KEY (player_key, match_key)
);


INSERT INTO fifa_dw.fact_player_match
(
    player_key,
    team_key,
    match_key,
    stadium_key,

    minutes_played,
    goals,
    assists,
    shots,
    shots_on_target,
    expected_goals_xg,
    expected_assists_xa,
    key_passes,

    successful_passes,
    total_passes,
    pass_accuracy,

    dribbles_attempted,
    successful_dribbles,
    crosses,
    successful_crosses,

    tackles,
    interceptions,
    clearances,
    blocks,

    aerial_duels_won,
    aerial_duels_lost,
    recoveries,
    defensive_actions,

    fouls_committed,
    fouls_suffered,
    yellow_cards,
    red_cards,
    offsides,

    saves,
    save_percentage,
    punches,
    clean_sheet,
    goals_conceded,
    penalty_saves,

    distance_covered_km,
    sprint_distance_km,
    top_speed_kmh,
    accelerations,
    decelerations,
    stamina_score,

    player_rating,
    performance_score,
    offensive_contribution,
    defensive_contribution,
    possession_impact,
    pressure_resistance,
    creativity_score,
    consistency_score,
    clutch_performance_score
)
SELECT
    p.player_key,
    t.team_key,
    m.match_key,
    s.stadium_key,

    f.minutes_played,
    f.goals,
    f.assists,
    f.shots,
    f.shots_on_target,
    f.expected_goals_xg,
    f.expected_assists_xa,
    f.key_passes,

    f.successful_passes,
    f.total_passes,
    f.pass_accuracy,

    f.dribbles_attempted,
    f.successful_dribbles,
    f.crosses,
    f.successful_crosses,

    f.tackles,
    f.interceptions,
    f.clearances,
    f.blocks,

    f.aerial_duels_won,
    f.aerial_duels_lost,
    f.recoveries,
    f.defensive_actions,

    f.fouls_committed,
    f.fouls_suffered,
    f.yellow_cards,
    f.red_cards,
    f.offsides,

    f.saves,
    f.save_percentage,
    f.punches,
    f.clean_sheet,
    f.goals_conceded,
    f.penalty_saves,

    f.distance_covered_km,
    f.sprint_distance_km,
    f.top_speed_kmh,
    f.accelerations,
    f.decelerations,
    f.stamina_score,

    f.player_rating,
    f.performance_score,
    f.offensive_contribution,
    f.defensive_contribution,
    f.possession_impact,
    f.pressure_resistance,
    f.creativity_score,
    f.consistency_score,
    f.clutch_performance_score

FROM public.fifa_player_performance f

JOIN fifa_dw.dim_player p
    ON f.player_id = p.player_id

JOIN fifa_dw.dim_team t
    ON f.team = t.team_name

JOIN fifa_dw.dim_match m
    ON f.match_id = m.match_id

LEFT JOIN fifa_dw.dim_stadium s
    ON f.stadium = s.stadium_name
   AND f.city = s.city

ON CONFLICT (player_key, match_key) DO NOTHING;


COMMIT;



-- ============================================================
-- 13. VERIFY THE STAR SCHEMA
-- ============================================================

SELECT
    p.player_name,
    t.team_name,
    m.match_date,
    m.tournament_stage,
    f.goals,
    f.assists,
    f.shots,
    f.player_rating
FROM fifa_dw.fact_player_match f

JOIN fifa_dw.dim_player p
    ON f.player_key = p.player_key

JOIN fifa_dw.dim_team t
    ON f.team_key = t.team_key

JOIN fifa_dw.dim_match m
    ON f.match_key = m.match_key

LIMIT 20;



-- ============================================================
-- 14. OPPONENT TEAM
-- ============================================================
--
-- The same dim_team table is used twice:
--
-- team_key          = player's team
-- opponent_team_key = opponent
--
-- This is a role-playing dimension.
--
-- ============================================================

BEGIN;

ALTER TABLE fifa_dw.fact_player_match
ADD COLUMN IF NOT EXISTS opponent_team_key INTEGER;


DO $$
BEGIN

    IF NOT EXISTS
    (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_opponent_team'
    )
    THEN

        ALTER TABLE fifa_dw.fact_player_match
        ADD CONSTRAINT fk_opponent_team
        FOREIGN KEY (opponent_team_key)
        REFERENCES fifa_dw.dim_team(team_key);

    END IF;

END $$;


UPDATE fifa_dw.fact_player_match f

SET opponent_team_key = t.team_key

FROM public.fifa_player_performance r

JOIN fifa_dw.dim_team t
    ON r.opponent_team = t.team_name

JOIN fifa_dw.dim_player p
    ON r.player_id = p.player_id

JOIN fifa_dw.dim_match m
    ON r.match_id = m.match_id

WHERE f.player_key = p.player_key
  AND f.match_key = m.match_key;


COMMIT;



-- ============================================================
-- 15. VALIDATE OPPONENT TEAM
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(opponent_team_key) AS rows_with_opponent,
    COUNT(*) - COUNT(opponent_team_key) AS rows_without_opponent
FROM fifa_dw.fact_player_match;



-- ============================================================
-- 16. OPPONENT TEAM TEST
-- ============================================================

SELECT
    p.player_name,
    team.team_name AS player's_team,
    opponent.team_name AS opponent,
    f.goals,
    f.player_rating

FROM fifa_dw.fact_player_match f

JOIN fifa_dw.dim_player p
    ON f.player_key = p.player_key

JOIN fifa_dw.dim_team team
    ON f.team_key = team.team_key

JOIN fifa_dw.dim_team opponent
    ON f.opponent_team_key = opponent.team_key

LIMIT 20;



-- ============================================================
-- 17. BRAZIL VS FRANCE ANALYSIS
-- ============================================================

SELECT
    team.team_name AS player's_team,
    opponent.team_name AS opponent,

    SUM(f.goals) AS goals,

    AVG(f.player_rating) AS average_rating

FROM fifa_dw.fact_player_match f

JOIN fifa_dw.dim_team team
    ON f.team_key = team.team_key

JOIN fifa_dw.dim_team opponent
    ON f.opponent_team_key = opponent.team_key

WHERE team.team_name = 'Brazil'
  AND opponent.team_name = 'France'

GROUP BY
    team.team_name,
    opponent.team_name;



-- ============================================================
-- 18. MATCH CONTEXT ENRICHMENT
-- ============================================================
--
-- Add match result and team/opponent goals to the fact table.
--
-- ============================================================

BEGIN;

ALTER TABLE fifa_dw.fact_player_match

ADD COLUMN IF NOT EXISTS match_result VARCHAR(20),

ADD COLUMN IF NOT EXISTS goals_team INTEGER,

ADD COLUMN IF NOT EXISTS goals_opponent INTEGER;


UPDATE fifa_dw.fact_player_match f

SET
    match_result = r.match_result,
    goals_team = r.goals_team,
    goals_opponent = r.goals_opponent

FROM public.fifa_player_performance r

JOIN fifa_dw.dim_player p
    ON r.player_id = p.player_id

JOIN fifa_dw.dim_match m
    ON r.match_id = m.match_id

WHERE f.player_key = p.player_key
  AND f.match_key = m.match_key;


COMMIT;



-- ============================================================
-- 19. VALIDATE MATCH CONTEXT
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(match_result) AS rows_with_result,

    COUNT(goals_team) AS rows_with_team_goals,

    COUNT(goals_opponent) AS rows_with_opponent_goals

FROM fifa_dw.fact_player_match;



-- ============================================================
-- 20. DIM_MATCH STRUCTURE CHECK
-- ============================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'fifa_dw'
  AND table_name = 'dim_match'
ORDER BY ordinal_position;



-- ============================================================
-- 21. TOURNAMENT FACT TABLE
-- ============================================================
--
-- Grain:
-- One row = one player for the tournament.
--
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS fifa_dw.fact_player_tournament
(
    player_key INTEGER NOT NULL,

    total_goals_tournament INTEGER,
    total_assists_tournament INTEGER,
    total_minutes_tournament INTEGER,
    player_of_match_awards INTEGER,
    tournament_rating DECIMAL(6,2),

    CONSTRAINT fk_tournament_player
        FOREIGN KEY (player_key)
        REFERENCES fifa_dw.dim_player(player_key),

    CONSTRAINT pk_fact_player_tournament
        PRIMARY KEY (player_key)
);


INSERT INTO fifa_dw.fact_player_tournament
(
    player_key,
    total_goals_tournament,
    total_assists_tournament,
    total_minutes_tournament,
    player_of_match_awards,
    tournament_rating
)

SELECT
    p.player_key,

    MAX(r.total_goals_tournament),

    MAX(r.total_assists_tournament),

    MAX(r.total_minutes_tournament),

    MAX(r.player_of_match_awards),

    MAX(r.tournament_rating)

FROM public.fifa_player_performance r

JOIN fifa_dw.dim_player p
    ON r.player_id = p.player_id

GROUP BY
    p.player_key

ON CONFLICT (player_key) DO NOTHING;


COMMIT;



-- ============================================================
-- 22. VALIDATE TOURNAMENT FACT
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT player_key) AS unique_players
FROM fifa_dw.fact_player_tournament;



-- ============================================================
-- 23. COMPLETE STAR SCHEMA ROW COUNT
-- ============================================================

SELECT
    'dim_player' AS table_name,
    COUNT(*) AS row_count
FROM fifa_dw.dim_player

UNION ALL

SELECT
    'dim_team',
    COUNT(*)
FROM fifa_dw.dim_team

UNION ALL

SELECT
    'dim_match',
    COUNT(*)
FROM fifa_dw.dim_match

UNION ALL

SELECT
    'dim_stadium',
    COUNT(*)
FROM fifa_dw.dim_stadium

UNION ALL

SELECT
    'fact_player_match',
    COUNT(*)
FROM fifa_dw.fact_player_match

UNION ALL

SELECT
    'fact_player_tournament',
    COUNT(*)
FROM fifa_dw.fact_player_tournament;



-- ============================================================
-- 24. FOREIGN KEY VALIDATION
-- ============================================================
--
-- Expected result:
-- 0 orphan records for every check.
--
-- ============================================================

-- Player integrity

SELECT
    COUNT(*) AS orphan_players

FROM fifa_dw.fact_player_match f

LEFT JOIN fifa_dw.dim_player p
    ON f.player_key = p.player_key

WHERE p.player_key IS NULL;



-- Team integrity

SELECT
    COUNT(*) AS orphan_teams

FROM fifa_dw.fact_player_match f

LEFT JOIN fifa_dw.dim_team t
    ON f.team_key = t.team_key

WHERE t.team_key IS NULL;



-- Opponent integrity

SELECT
    COUNT(*) AS orphan_opponents

FROM fifa_dw.fact_player_match f

LEFT JOIN fifa_dw.dim_team t
    ON f.opponent_team_key = t.team_key

WHERE t.team_key IS NULL;



-- Match integrity

SELECT
    COUNT(*) AS orphan_matches

FROM fifa_dw.fact_player_match f

LEFT JOIN fifa_dw.dim_match m
    ON f.match_key = m.match_key

WHERE m.match_key IS NULL;



-- ============================================================
-- 25. PLAYER-MATCH UNIQUENESS CHECK
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(
        DISTINCT player_key || '-' || match_key
    ) AS unique_player_matches

FROM fifa_dw.fact_player_match;



-- ============================================================
-- 26. ANALYST PRIVILEGE TEST
-- ============================================================
--
-- Run this while connected as fifa_analyst.
--
-- The analyst should be able to SELECT but should NOT be able
-- to UPDATE warehouse tables.
--
-- ============================================================

SELECT
    current_user,

    has_table_privilege(
        current_user,
        'fifa_dw.dim_player',
        'SELECT'
    ) AS can_select,

    has_table_privilege(
        current_user,
        'fifa_dw.dim_player',
        'UPDATE'
    ) AS can_update;



-- ============================================================
-- 27. DATA SCIENTIST / MACHINE LEARNING SCHEMA
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS fifa_ml;

GRANT USAGE, CREATE
ON SCHEMA fifa_ml
TO fifa_data_scientist;


COMMIT;



-- ============================================================
-- 28. DATA SCIENTIST PRIVILEGE TEST
-- ============================================================

SELECT
    has_schema_privilege(
        'fifa_data_scientist',
        'fifa_ml',
        'USAGE'
    ) AS can_use_schema,

    has_schema_privilege(
        'fifa_data_scientist',
        'fifa_ml',
        'CREATE'
    ) AS can_create;



-- ============================================================
-- 29. FINAL DATA WAREHOUSE VALIDATION
-- ============================================================
--
-- Expected project results from your completed dataset:
--
-- dim_player              → 1,248
-- dim_team                → 48
-- dim_match               → 1,050
-- dim_stadium             → 16
-- fact_player_match       → 54,600
-- fact_player_tournament  → 1,248
--
-- Integrity checks should return 0.
--
-- ============================================================

SELECT
    'Players' AS metric,
    COUNT(*) AS value
FROM fifa_dw.dim_player

UNION ALL

SELECT
    'Teams',
    COUNT(*)
FROM fifa_dw.dim_team

UNION ALL

SELECT
    'Matches',
    COUNT(*)
FROM fifa_dw.dim_match

UNION ALL

SELECT
    'Stadiums',
    COUNT(*)
FROM fifa_dw.dim_stadium

UNION ALL

SELECT
    'Player-Match Facts',
    COUNT(*)
FROM fifa_dw.fact_player_match

UNION ALL

SELECT
    'Player-Tournament Facts',
    COUNT(*)
FROM fifa_dw.fact_player_tournament;
