SELECT e.coddoc, 
       e.codsecao, 
       e.codsecao || e.coddoc || To_char(e.dtcad, 'ddmmyyyyhh24miss') || e.coddocvinc as secret,
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
                              SELECT lvu.*
                                   FROM LocalVirtualUsuario lvu, usuario u, UsuarioLotacao ul
                                   WHERE u.NumCpf = ?
                                   AND lvu.CodUsu = u.CodUsu
                                   AND u.CodSecao = lvu.CodSecao
                                   AND lvu.CodTipLocalVirt = nval_const('$$TipLocalVirtPadrao')
                                   AND lvu.CodSecao = Nval_const('$$SecaoAtual')
                                   AND ul.CodSecao = lvu.CodSecao
                                   AND ul.CodUsu = u.CodUsu
                                   AND lvu.CodLocFis = ul.CodLocFis
                                   AND ul.CodTipLot = nval_const('$$TipLotPrincUsu')
                               ) 
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
                              AND da.numtipmovarq IS NULL
                              AND da.inderaanexo = 'N') 