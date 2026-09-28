-- 1. Top 10 tournament goal scorers
SELECT p.player_name, p.nationality, t.total_goals_tournament
FROM fifa_dw.fact_player_tournament t
JOIN fifa_dw.dim_player p ON t.player_key = p.player_key
ORDER BY t.total_goals_tournament DESC
LIMIT 10;

-- 2. Top 10 assist providers
SELECT p.player_name, p.nationality, t.total_assists_tournament
FROM fifa_dw.fact_player_tournament t
JOIN fifa_dw.dim_player p ON t.player_key = p.player_key
ORDER BY t.total_assists_tournament DESC
LIMIT 10;

-- 3. Highest tournament ratings
SELECT p.player_name, p.nationality, t.tournament_rating
FROM fifa_dw.fact_player_tournament t
JOIN fifa_dw.dim_player p ON t.player_key = p.player_key
ORDER BY t.tournament_rating DESC
LIMIT 10;

-- 4. Team goals
SELECT t.team_name, SUM(f.goals) AS total_goals
FROM fifa_dw.fact_player_match f
JOIN fifa_dw.dim_team t ON f.team_key = t.team_key
GROUP BY t.team_name
ORDER BY total_goals DESC;

-- 5. Player minutes
SELECT p.player_name, p.nationality, SUM(f.minutes_played) AS total_minutes
FROM fifa_dw.fact_player_match f
JOIN fifa_dw.dim_player p ON f.player_key = p.player_key
GROUP BY p.player_name, p.nationality
ORDER BY total_minutes DESC
LIMIT 10;

-- 6. Team goals conceded (deduplicated at match/team perspective)
SELECT team.team_name, SUM(m.goals_opponent) AS goals_conceded
FROM (
    SELECT DISTINCT match_key, team_key, goals_opponent
    FROM fifa_dw.fact_player_match
) m
JOIN fifa_dw.dim_team team ON m.team_key = team.team_key
GROUP BY team.team_name
ORDER BY goals_conceded DESC;

-- 7. Player goals vs assists
SELECT p.player_name,
       SUM(f.goals) AS goals,
       SUM(f.assists) AS assists
FROM fifa_dw.fact_player_match f
JOIN fifa_dw.dim_player p ON f.player_key = p.player_key
GROUP BY p.player_name
ORDER BY goals DESC, assists DESC;

-- 8. Average player rating by position
SELECT p.position,
       ROUND(AVG(f.player_rating), 2) AS avg_rating
FROM fifa_dw.fact_player_match f
JOIN fifa_dw.dim_player p ON f.player_key = p.player_key
GROUP BY p.position
ORDER BY avg_rating DESC;
