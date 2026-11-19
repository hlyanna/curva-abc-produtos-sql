-- 01_criar_tabelas.sql
-- Cria o banco e as tabelas do projeto (SQL Server).

IF DB_ID('CurvaABC') IS NULL
    CREATE DATABASE CurvaABC;
GO

USE CurvaABC;
GO

IF OBJECT_ID('google_shopping_semanal') IS NOT NULL DROP TABLE google_shopping_semanal;
IF OBJECT_ID('vendas_semanais') IS NOT NULL DROP TABLE vendas_semanais;
IF OBJECT_ID('produtos') IS NOT NULL DROP TABLE produtos;
GO

-- Cadastro de produtos: preço de venda e custo unitário
CREATE TABLE produtos (
    sku             VARCHAR(10)    NOT NULL PRIMARY KEY,
    nome_produto    NVARCHAR(100)  NOT NULL,
    categoria       NVARCHAR(50)   NOT NULL,
    preco_venda     DECIMAL(10,2)  NOT NULL,
    custo_unitario  DECIMAL(10,2)  NOT NULL
);

-- Vendas por semana, produto e plataforma (VTEX = loja própria, Mercado Livre)
CREATE TABLE vendas_semanais (
    semana              DATE           NOT NULL,
    sku                 VARCHAR(10)    NOT NULL REFERENCES produtos(sku),
    plataforma          VARCHAR(20)    NOT NULL,
    quantidade_vendida  INT            NOT NULL,
    faturamento         DECIMAL(12,2)  NOT NULL
);

-- Campanha de Google Shopping: investimento e valor de conversão por semana e produto.
-- grupo_anuncios = grupo em que o produto estava naquela semana (Curva A, B ou C).
-- Produto sem linha na semana = produto fora da campanha (pausado).
CREATE TABLE google_shopping_semanal (
    semana           DATE           NOT NULL,
    sku              VARCHAR(10)    NOT NULL REFERENCES produtos(sku),
    grupo_anuncios   VARCHAR(10)    NOT NULL,
    investimento     DECIMAL(12,2)  NOT NULL,
    valor_conversao  DECIMAL(12,2)  NOT NULL
);
GO
