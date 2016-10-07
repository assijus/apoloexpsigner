DECLARE 
    i_codsecao        NUMBER(2, 0); 
    i_coddoc          NUMBER(10, 0); 
    i_cpf             VARCHAR2(14); 
    i_pdf_recuperar   NUMBER(1, 0); 
    o_pdf_sha1        VARCHAR2(64) := NULL; 
    o_pdf_sha256      VARCHAR2(64) := NULL; 
    o_pdf_num_paginas NUMBER := NULL; 
    o_dthrultatu      DATE := NULL; 
    o_status          VARCHAR2(32767) := NULL; 
    o_error           VARCHAR2(32767) := NULL; 
    o_pdf             BLOB := NULL; 
    v_login           VARCHAR2(200) := NULL; 
BEGIN 
    i_codsecao := ?; 

    i_coddoc := ?; 

    i_cpf := ?; 

    i_pdf_recuperar := ?; 

    SELECT login 
    INTO   v_login 
    FROM   usuario 
    WHERE  numcpf = i_cpf 
           AND indativo = 'S'; 

    Dbms_session_set_context(v_login); 

    SELECT pdfsha1, 
           pdfsha256, 
           numpagespdf, 
           dthrultatu, 
           txtpdf 
    INTO   o_pdf_sha1, o_pdf_sha256, o_pdf_num_paginas, o_dthrultatu, o_pdf 
    FROM   expedientepdf mtp 
    WHERE  mtp.codsecao = i_codsecao 
           AND mtp.coddoc = i_coddoc 
           AND ( mtp.status = 'convertidoempdf' 
                  OR mtp.status = 'assinado' ); 

    IF ( o_pdf_sha256 = NULL ) THEN 
      o_status := 'Erro'; 

      o_error := 'PDF não foi gerado!'; 
    ELSE 
      o_status := 'OK'; 
    END IF; 

    IF ( i_pdf_recuperar = 0 ) THEN 
      o_pdf := NULL; 
    END IF; 

    ? := o_pdf_sha1; 

    ? := o_pdf_sha256; 

    ? := o_pdf_num_paginas; 

    ? := o_dthrultatu; 

    ? := o_pdf; 

    ? := o_status; 

    ? := o_error; 
END; 