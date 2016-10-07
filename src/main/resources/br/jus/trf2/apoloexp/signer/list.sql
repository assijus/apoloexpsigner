SELECT e.coddoc, 
       e.codsecao, 
       formata_exp(e.num) AS Num, 
       (SELECT c.descr 
        FROM   tipoexpediente c 
        WHERE  c.codtipexp = e.codtipexp 
               AND c.codsecao = e.codsecao) AS DESCR, 
       (SELECT u.codusu 
        FROM   usuario u 
        WHERE  u.codsecao = e.codsecao 
               AND u.numcpf = ?)            AS CodUsu 
FROM   t_expediente e 
WHERE  e.codsecao = Nval_const('$$SecaoAtual') 
       AND e.coddoc IN(--Busca todos os documentos da mesa de trabalho padrao 
                      SELECT lvd.coddoc 
                       FROM   localvirtualdocumento lvd, 
                              ( 
                              --Busca o local virtual(mesa de trabalho) padrao do usuario para a sua lotacao principal 
                              SELECT * 
                               FROM   localvirtualusuario lvu 
                               WHERE  lvu.codsecao = Nval_const('$$SecaoAtual')
                                      AND lvu.codusu = ( 
                                                       --Busca o usuario pelo CPF 
                                                       SELECT u.codusu 
                                                        FROM   usuario u 
                                                        WHERE 
                                          u.codsecao = lvu.codsecao 
                                          AND u.numcpf = ?) 
                                      AND lvu.codlocfis = ( 
                                                          --Busca a lotacao principal do usuario 
                                                          SELECT ul.codlocfis 
                                                           FROM 
                                          usuariolotacao ul 
                                                           WHERE 
                                          ul.codsecao = lvu.codsecao 
                                          AND ul.codusu = ( 
                                                          --Busca o usuario pelo CPF 
                                                          SELECT u.codusu 
                                                           FROM   usuario u 
                                                           WHERE 
                                              u.codsecao = ul.codsecao 
                                              AND u.numcpf = ?) 
                                          AND ul.codtiplot = 
                                              Nval_const('$$TipLotPrincUsu')) 
                                      AND lvu.codtiplocalvirt = 
                                          Nval_const('$$TipLocalVirtPadrao')) 
                              mesa 
                       WHERE  lvd.codsecao = e.codsecao 
                              AND lvd.codsecao = mesa.codsecao 
                              AND lvd.codlocfis = mesa.codlocfis 
                              AND lvd.codlocalvirt = mesa.codlocalvirt) 
       --Verifica as fases que se deve assinar 
       AND NOT EXISTS (SELECT 1 
                       FROM   documentoarquivo da 
                       WHERE  da.codsecao = e.codsecao 
                              AND da.coddoc = e.coddoc 
                              AND da.numtipmovarq IS NULL) 