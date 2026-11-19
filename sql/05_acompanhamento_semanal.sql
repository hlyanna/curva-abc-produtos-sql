-- 05_acompanhamento_semanal.sql
-- Rotina semanal: como cada grupo da campanha de Shopping está performando
-- e qual fatia da verba recebeu. É a base para redistribuir o investimento.

USE CurvaABC;
GO

-- 1) ROAS e % da verba por grupo, semana a semana
SELECT
    semana,
    grupo_anuncios,
    COUNT(*)                                                                         AS produtos_no_grupo,
    SUM(investimento)                                                                AS investimento,
    CAST(SUM(investimento) / SUM(SUM(investimento)) OVER (PARTITION BY semana)
         AS DECIMAL(10,4))                                                           AS perc_verba,
    SUM(valor_conversao)                                                             AS valor_conversao,
    CAST(SUM(valor_conversao) / NULLIF(SUM(investimento), 0) AS DECIMAL(10,2))       AS roas
FROM google_shopping_semanal
GROUP BY semana, grupo_anuncios
ORDER BY semana, grupo_anuncios;

-- 2) ROAS da campanha inteira por semana, com a variação em relação à semana anterior
WITH campanha AS (
    SELECT
        semana,
        SUM(investimento)                                                         AS investimento,
        CAST(SUM(valor_conversao) / NULLIF(SUM(investimento), 0) AS DECIMAL(10,2)) AS roas
    FROM google_shopping_semanal
    GROUP BY semana
)
SELECT
    semana,
    investimento,
    roas,
    roas - LAG(roas) OVER (ORDER BY semana) AS variacao_vs_semana_anterior
FROM campanha
ORDER BY semana;
