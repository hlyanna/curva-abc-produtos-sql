-- 04_resumo_por_classe.sql
-- Compara as classes A, B e C: volume, faturamento, ROAS e margem.

USE CurvaABC;
GO

SELECT
    classe_abc,
    COUNT(*)                                                                      AS qtd_produtos,
    SUM(quantidade)                                                               AS unidades_vendidas,
    CAST(SUM(quantidade) * 1.0 / SUM(SUM(quantidade)) OVER () AS DECIMAL(10,4))   AS perc_unidades,
    SUM(faturamento)                                                              AS faturamento,
    CAST(SUM(faturamento) / SUM(SUM(faturamento)) OVER () AS DECIMAL(10,4))       AS perc_faturamento,
    SUM(investimento)                                                             AS investimento_shopping,
    CAST(SUM(valor_conversao) / NULLIF(SUM(investimento), 0) AS DECIMAL(10,2))    AS roas_shopping,
    SUM(lucro_anuncios)                                                           AS lucro_anuncios,
    CAST(SUM(margem_contribuicao) / NULLIF(SUM(faturamento), 0) AS DECIMAL(10,4)) AS perc_margem
FROM vw_curva_abc
GROUP BY classe_abc
ORDER BY classe_abc;
