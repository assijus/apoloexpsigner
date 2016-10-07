DECLARE 
    -- parametros de entrada 
    i_codsecao           NUMBER(2, 0); 
    i_coddoc             NUMBER(10, 0); 
    i_pdfcomprimido      BLOB; 
    i_envelopecomprimido BLOB; 
    i_pdfnumpaginas      NUMBER; 
    i_nomeassinante      VARCHAR2(100); 
    i_cpf                VARCHAR2(14); 
    i_dthrassinatura     DATE; 
    i_dthrultatu         DATE; 
    -- parametros de saida 
    o_status             VARCHAR2(32767) := NULL; 
    o_error              VARCHAR2(32767) := NULL; 
    -- demais variaveis 
    v_dthrultatu         DATE := NULL; 
    v_pdfnumpaginas      NUMBER := NULL; 
    v_pdfcomprimido      BLOB := NULL; 
    v_descr              VARCHAR2(250); 
    v_tipassin           NUMBER(2, 0); 
    v_count              NUMBER; 
    v_seq                NUMBER(4, 0) := NULL; 
    v_seqassin           NUMBER(4, 0) := NULL; 
    v_dthrincl           DATE := NULL; 
    v_login              VARCHAR2(200) := NULL; 
BEGIN 
    i_codsecao := ?; 

    i_coddoc := ?; 

    i_pdfcomprimido := ?; 

    i_envelopecomprimido := ?; 

    i_pdfnumpaginas := ?; 

    i_nomeassinante := ?; 

    i_cpf := ?; 

    i_dthrassinatura := ?; 

    i_dthrultatu := ?; 

    -- identifica o usuario perante o sistema de auditoria 
    SELECT login 
    INTO   v_login 
    FROM   usuario 
    WHERE  numcpf = i_cpf 
           AND indativo = 'S'; 

    Dbms_session_set_context(v_login); 

    -- verifica se o documento ja esta assinado 
    SELECT Count(*) 
    INTO   v_count 
    FROM   documentoarquivo da 
    WHERE  da.codsecao = i_codsecao 
           AND da.coddoc = i_coddoc 
           AND da.numtipmovarq IS NULL; 

    IF ( v_count > 0 ) THEN 
      o_status := 'Erro'; 

      o_error := 'Documento já estava assinado!'; 
    ELSE 
      -- verifica se o pdf e demais dados estao disponiveis na tabela do servico de conversao automatica
      BEGIN 
          SELECT dthrultatu, 
                 txtpdfcompr, 
                 numpagespdf 
          INTO   v_dthrultatu, v_pdfcomprimido, v_pdfnumpaginas 
          FROM   expedientepdf mtp 
          WHERE  mtp.codsecao = i_codsecao 
                 AND mtp.coddoc = i_coddoc 
                 AND mtp.status = 'convertidoempdf'; 

          --select count(*) from MovimentoTextoPdf mtp where mtp.Status='convertidoempdf'; 
          i_pdfcomprimido := v_pdfcomprimido; 

          i_pdfnumpaginas := v_pdfnumpaginas; 
      EXCEPTION 
          WHEN no_data_found THEN 
            -- quando nao estiverem la, nao faz nada 
            o_status := o_status; 
      END; 
    -- se recebido um parametro com a data da ultima atualizacao, entao vamos apresentar um erro se nao foi possivel recuperar os dados do servico de conversao automatica
    IF (i_dthrultatu IS NOT NULL AND i_dthrultatu <> v_dthrultatu) THEN o_status 
    := 
    'Erro'; o_error := 'Documento sofreu alteração!'|| i_dthrultatu|| ' - '|| 
    v_dthrultatu; ELSE 
    -- obtem a descricao 
    SELECT Formata_exp(num)|| ' - '|| (SELECT c.descr FROM tipoexpediente c 
    WHERE 
    c.codsecao = m.codsecao AND c.codtipexp = m.codtipexp) INTO v_descr FROM 
    t_expediente m 
    WHERE m.codsecao = i_codsecao AND m.coddoc = i_coddoc; 
    -- obtem o tipo da assinatura 
    v_tipassin := Nval_const('$$TipAssin'); 
    -- grava nas tabelas 
    Documentoarquivo_i(i_codsecao, i_coddoc, v_seq, NULL, NULL, i_pdfcomprimido, 
    NULL, NULL, v_descr, i_envelopecomprimido, v_dthrincl, NULL, i_pdfnumpaginas 
    , 
    'N', NULL, NULL, NULL, NULL, NULL, NULL); Documentoarquivodadosassin_i( 
    v_seqassin, i_codsecao, i_coddoc, v_seq, i_nomeassinante, i_dthrassinatura, 
    v_tipassin); 
    -- marca o status da tabela movimentotextopdf com 'assinado'. Precisei arredondar a dthrultatu fazendo um to_char pois estava dando diferente.
    UPDATE expedientepdf SET status='assinado' WHERE codsecao = i_codsecao AND 
    coddoc = i_coddoc AND To_char(dthrultatu, 'dd/mm/yyyy hh24:mi') = To_char( 
    v_dthrultatu, 'dd/mm/yyyy hh24:mi'); o_status := 'OK'; END IF; 
    END IF; 

    ? := o_status; 

    ? := o_error; 
END; 