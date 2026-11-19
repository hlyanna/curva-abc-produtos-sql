-- 06_revisao_selecao_produtos.sql
-- Revisão da seleção de produtos: olha as últimas 4 semanas de cada produto
-- e sugere manter, mudar de grupo ou pausar.

USE CurvaABC;
GO

WITH parametros AS (
    SELECT CAST(4.50 AS DECIMAL(10,2)) AS roas_meta      -- ajuste a meta de ROAS aqui
),
ultimas_semanas AS (
    SELECT DISTINCT TOP 4 semana
    FROM google_shopping_semanal
    ORDER BY semana DESC
),
grupo_atual AS (
    -- grupo do produto na semana mais recente (NULL = fora da campanha)
    SELECT sku, grupo_anuncios
    FROM google_shopping_semanal
    WHERE semana = (SELECT MAX(semana) FROM google_shopping_semanal)
),
recente AS (
    SELECT
        g.sku,
        SUM(g.investimento)                                                         AS investimento_4s,
        CAST(SUM(g.valor_conversao) / NULLIF(SUM(g.investimento), 0) AS DECIMAL(10,2)) AS roas_4s,
        CAST(SUM(g.valor_conversao) * MAX(c.margem_bruta) - SUM(g.investimento) AS DECIMAL(12,2)) AS lucro_anuncios_4s
    FROM google_shopping_semanal AS g
    INNER JOIN vw_curva_abc AS c ON c.sku = g.sku
    WHERE g.semana IN (SELECT semana FROM ultimas_semanas)
    GROUP BY g.sku
)
SELECT
    c.sku,
    c.nome_produto,
    c.classe_abc,
    COALESCE(ga.grupo_anuncios, 'Pausado') AS grupo_atual,
    r.roas_4s,
    r.lucro_anuncios_4s,
    CASE
        WHEN ga.sku IS NULL
            THEN 'Fora da campanha: reavaliar se o lucro com anúncios puder ficar positivo'
        WHEN r.lucro_anuncios_4s < 0
            THEN 'Reduzir lance: o anúncio custa mais do que a venda deixa'
        WHEN ga.grupo_anuncios = 'Curva C' AND c.classe_abc IN ('A', 'B')
            THEN 'Subir para o grupo B: já vende no volume de um produto B'
        WHEN r.roas_4s >= p.roas_meta
            THEN 'Manter no grupo e considerar mais verba: retorno acima da meta'
        ELSE 'Manter e acompanhar: retorno abaixo da meta'
    END AS acao_sugerida
FROM vw_curva_abc AS c
LEFT JOIN grupo_atual AS ga ON ga.sku = c.sku
LEFT JOIN recente     AS r  ON r.sku  = c.sku
CROSS JOIN parametros AS p
ORDER BY grupo_atual, r.roas_4s DESC;
