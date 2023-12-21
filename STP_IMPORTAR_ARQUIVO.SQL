CREATE OR REPLACE PROCEDURE "STP_ARQUIVO_CONTAGEM_HDN"(P_CODUSU    NUMBER, -- Codigo do usuario logado
                                                       P_IDSESSAO  VARCHAR2, -- Identificador da execuc?o. Serve para buscar informac?es dos parametros/campos da execuc?o.
                                                       P_QTDLINHAS NUMBER, -- Informa a quantidade de registros selecionados no momento da execuc?o.
                                                       P_MENSAGEM  OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela sera exibida como uma informac?o ao usuario.
                                                       ) AS

  FIELD_ID NUMBER;

  V_ARQUIVO     CLOB;
  V_LINE        VARCHAR2(200);
  V_LINE_NUMBER INT := 0;
  V_SEQ         NUMBER;
  V_CODPROD     VARCHAR2(50) := NULL;
  V_QTDCONTADA  NUMBER;

  V_DTCONTAGEM DATE;
  V_CODEMP     NUMBER;

BEGIN

  FOR I IN 1 .. P_QTDLINHAS LOOP
  
    FIELD_ID := ACT_INT_FIELD(P_IDSESSAO, I, 'ID');
  
    --busca o arquivo
    SELECT GETBLOB(ARQUIVO)
      INTO V_ARQUIVO
      FROM AD_CTGINT
     WHERE ID = FIELD_ID;
  
    -- Busca dados empresa e data contagem
    SELECT IT.DTCONTAGEM, IT.CODEMP
      INTO V_DTCONTAGEM, V_CODEMP
      FROM AD_CTGINT IT
     WHERE IT.id = FIELD_ID;
  
    -- Dividir o CLOB em linhas
    FOR I IN 1 .. DBMS_LOB.GETLENGTH(V_ARQUIVO) LOOP
    
      V_LINE := V_LINE || DBMS_LOB.SUBSTR(V_ARQUIVO, 1, I);
    
      IF DBMS_LOB.SUBSTR(V_ARQUIVO, 1, I) = CHR(10) THEN
      
        V_LINE_NUMBER := V_LINE_NUMBER + 1;
      
        -- Ignorar a primeira linha
        IF V_LINE_NUMBER = 1 THEN
        
          V_LINE := NULL;
        
        ELSE
        
          -- Processar as linhas subsequentes
          V_LINE       := TRIM(BOTH CHR(10) FROM V_LINE);
          V_CODPROD    := REGEXP_SUBSTR(V_LINE, '^[^;]+');
          V_QTDCONTADA := TO_NUMBER(RTRIM(RTRIM(SUBSTR(V_LINE,
                                                       INSTR(V_LINE, ';') + 1),
                                                CHR(10)),
                                          CHR(13)));
        
          -- Inserir na tabela AD_PRECIFICITE
          INSERT INTO AD_ITEARQ
            (ID, CODPROD, QTDCONTADA)
          VALUES
            (FIELD_ID, V_CODPROD, V_QTDCONTADA);
          /*
          FOR A IN (SELECT CODPROD
                      FROM TGFCTE
                    INNER JOIN   
                     WHERE CODEMP = V_CODEMP
                       AND DTCONTAGEM = V_DTCONTAGEM
                       AND SEQUENCIA = 1
                       AND 
                       ) LOOP
            INSERT INTO tgfcte
              (DTCONTAGEM,
               CODPROD,
               CODLOCAL,
               CODPARC,
               CODEMP,
               SEQUENCIA,
               TIPO,
               CONTROLE,
               CODVOL,
               QTDEST)
            VALUES
              (V_DTCONTAGEM,
               A.CODPROD,
               '100000000',
               0,
               V_CODEMP,
               2,
               'P',
               ' ',
               'PC',
               V_QTDCONTADA);
          END LOOP;*/
        
          -- Limpar a linha
          V_LINE := NULL;
        
        END IF;
      
      END IF;
    
    END LOOP;
  
  END LOOP;

END;

/