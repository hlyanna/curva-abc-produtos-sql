-- 03_curva_abc.sql
-- Classifica os produtos em A, B e C pelo faturamento total (VTEX + Mercado Livre)
-- e calcula o ROAS no Google Shopping e a margem depois dos anúncios.
--
-- Regra da curva:
--   A = produtos que somam até 80% do faturamento
--   B = os próximos, até 95%
--   C = os 5% finais

USE CurvaABC;
GO

CREATE OR ALTER VIEW vw_curva_abc AS
WITH vendas AS (
    -- 1) Consolida as vendas das duas plataformas por produto
    SELECT
        p.sku,
        p.nome_produto,
        p.categoria,
        SUM(v.quantidade_vendida)                    AS quantidade,
        SUM(v.faturamento)                           AS faturamento,
        SUM(v.quantidade_vendida * p.custo_unitario) AS custo_produto,
        (p.preco_venda - p.custo_unitario) / p.preco_venda AS margem_bruta
    FROM vendas_semanais AS v
    INNER JOIN produtos AS p ON p.sku = v.sku
    GROUP BY p.sku, p.nome_produto, p.categoria, p.preco_venda, p.custo_unitario
),
anuncios AS (
    -- 2) Soma o investimento e o valor de conversão do Shopping por produto
    SELECT sku, SUM(investimento) AS investimento, SUM(valor_conversao) AS valor_conversao
    FROM google_shopping_semanal
    GROUP BY sku
),
acumulado AS (
    -- 3) Participação no faturamento e percentual acumulado (do maior para o menor)
    SELECT
        v.*,
        COALESCE(a.investimento, 0)    AS investimento,
        COALESCE(a.valor_conversao, 0) AS valor_conversao,
        CAST(v.faturamento / SUM(v.faturamento) OVER () AS DECIMAL(10,4)) AS perc_faturamento,
        CAST(SUM(v.faturamento) OVER (ORDER BY v.faturamento DESC
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(v.faturamento) OVER () AS DECIMAL(10,4))                AS perc_acumulado
    FROM vendas AS v
    LEFT JOIN anuncios AS a ON a.sku = v.sku
)
-- 4) Classe ABC, ROAS e retorno financeiro
--    lucro_anuncios = quanto sobra das vendas geradas pelo Shopping depois de pagar
--    o custo do produto e o próprio anúncio (valor_conversao x margem bruta - investimento)
SELECT
    sku,
    nome_produto,
    categoria,
    quantidade,
    faturamento,
    perc_faturamento,
    perc_acumulado,
    CASE
        WHEN perc_acumulado <= 0.80 THEN 'A'
        WHEN perc_acumulado <= 0.95 THEN 'B'
        ELSE 'C'
    END                                                                  AS classe_abc,
    investimento,
    valor_conversao,
    CAST(valor_conversao / NULLIF(investimento, 0) AS DECIMAL(10,2))     AS roas_shopping,
    CAST(margem_bruta AS DECIMAL(10,4))                                  AS margem_bruta,
    CAST(valor_conversao * margem_bruta - investimento AS DECIMAL(12,2)) AS lucro_anuncios,
    CAST(faturamento - custo_produto - investimento AS DECIMAL(12,2))    AS margem_contribuicao,
    CAST((faturamento - custo_produto - investimento)
         / NULLIF(faturamento, 0) AS DECIMAL(10,4))                      AS perc_margem
FROM acumulado;
GO

SELECT *
FROM vw_curva_abc
ORDER BY faturamento DESC;
