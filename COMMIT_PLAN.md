# Recommended Git Commit Plan

Use these commits to tell the story of the project.

1. `Initialize FIFA World Cup data warehouse project`
   - README
   - .gitignore
   - folder structure

2. `Create and document raw FIFA performance table`
   - sql/01_setup/

3. `Build FIFA warehouse dimensions`
   - sql/02_dimensions/

4. `Build player match fact table`
   - sql/03_facts/01_create_fact_player_match.sql
   - sql/03_facts/02_load_fact_player_match.sql

5. `Build tournament player fact table`
   - sql/03_facts/03_fact_player_tournament.sql

6. `Model opponent team as role-playing dimension`
   - included in fact table creation/load and relationship verification

7. `Add warehouse integrity and data quality checks`
   - sql/06_validation/

8. `Implement FIFA role-based access control`
   - sql/05_security/

9. `Add data scientist ML workspace`
   - fifa_ml grants in sql/05_security/

10. `Add FIFA analytical queries`
   - sql/07_analytics/

11. `Document star schema and project architecture`
   - docs/data_model.md
