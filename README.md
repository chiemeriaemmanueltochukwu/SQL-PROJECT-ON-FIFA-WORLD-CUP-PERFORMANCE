# FIFA World Cup 2026 Player Performance Data Warehouse

A PostgreSQL data warehouse project built from a FIFA World Cup 2026 player-performance dataset.

## Project goals

- Load and validate raw player-match data
- Transform the raw dataset into a star schema
- Separate dimensions from facts
- Model opponent teams using a role-playing dimension
- Build tournament-level player facts
- Implement role-based access control
- Create a separate workspace for data-science/ML work
- Produce analytical SQL queries

## Warehouse architecture

```text
                         dim_player
                             |
dim_team ---- fact_player_match ---- dim_match
                             |
                        dim_stadium

dim_player ---- fact_player_tournament
```

The warehouse schema is `fifa_dw`.

The Data Scientist workspace is `fifa_ml`.

## Validated project scale

| Object | Rows |
|---|---:|
| `dim_player` | 1,248 |
| `dim_team` | 48 |
| `dim_match` | 1,050 |
| `dim_stadium` | 16 |
| `fact_player_match` | 54,600 |
| `fact_player_tournament` | 1,248 |

## Roles

| Role | Purpose |
|---|---|
| `postgres` | Database superuser |
| `fifa_admin` | Warehouse administration |
| `fifa_analyst` | Read-only analytics |
| `fifa_data_scientist` | Read warehouse + create ML/analysis objects in `fifa_ml` |

## Repository structure

```text
sql/
├── 01_setup/
├── 02_dimensions/
├── 03_facts/
├── 04_relationships/
├── 05_security/
├── 06_validation/
└── 07_analytics/
docs/
```

## Data security

The original CSV is intentionally not included. Do not commit passwords, connection strings, `.env` files, or other credentials.

## Suggested execution order

1. Create/load the raw table
2. Create and populate dimensions
3. Create and populate facts
4. Verify relationships
5. Configure security roles
6. Run validation checks
7. Run analytics

## Portfolio visuals

This repository now includes visual documentation in `docs/`:
- `schema_diagram.svg` — FIFA star-schema architecture, including the role-playing `DIM_TEAM` relationship for `opponent_team_key`.
- `security_model.svg` — PostgreSQL role and privilege model.
- `analyst_questions.md` — portfolio-ready analyst questions.

The `sql/07_analytics/` folder contains the SQL used to answer the analyst questions. Because the actual CSV was not packaged with this repository, player-level chart values are not fabricated; run the queries against the warehouse and export the results for visualization.
