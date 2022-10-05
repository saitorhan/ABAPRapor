*&---------------------------------------------------------------------*
*& Report  ZMalzemeKarakteristik
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZMalzemeKarakteristik.
TYPE-POOLS: SLIS.
TABLES: MARA, MAKT, CABNT, CABN, T006A, AUSP.

DATA: BEGIN OF GT_METADATAS OCCURS 0,
  MATNR LIKE MARA-MATNR, " Malzeme no
  MAKTX LIKE MAKT-MAKTX, " Malzeme tan�m�
  atinn LIKE AUSP-ATINN, " karakteristik
  ATBEZ LIKE CABNT-ATBEZ, " Karakteristik tan�m�
  MSEHI LIKE CABN-MSEHI, "�l�� Birimi
  ATWRT LIKE AUSP-ATWRT, " Karakter karakteristik de�eri
  ATFLV LIKE AUSP-ATFLV, " Say�sal Alt de�er
  ATFLB LIKE AUSP-ATFLB, " Say�sal �st de�er
  MSEH6 LIKE T006A-MSEH6, " �l�� birimi teknik tan�m�
  SPRAS LIKE T006A-SPRAS, " dil
  ATFOR LIKE CABN-ATFOR, " veri tipi
  ANZST LIKE CABN-ANZST, " Karakter uzunlu�u
  ANZDZ LIKE CABN-ANZDZ, " ondal�k karakter say�s�
  DEGER1 TYPE C LENGTH 10, " numerik de�er alt
  DEGER2 TYPE C LENGTH 10, " numarik de�er �st
  END OF GT_METADATAS.

DATA: FCAT TYPE SLIS_T_FIELDCAT_ALV.
DATA: LAYOUT TYPE SLIS_LAYOUT_ALV.
DATA: VARYANT TYPE DISVARIANT.
VARYANT-REPORT = SY-REPID.
VARYANT-USERNAME = SY-UNAME.


SELECTION-SCREEN BEGIN OF BLOCK PARAMETERS WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS:
P_MATNR FOR MARA-MATNR,
  P_MATKL FOR MARA-MATKL.
SELECTION-SCREEN END OF BLOCK PARAMETERS.

START-OF-SELECTION.
  IF P_MATNR[] IS INITIAL AND P_MATKL[] IS INITIAL.
    MESSAGE 'Malzeme numaras� veya Mal Grubundan biri girilmeli'
    TYPE 'S' DISPLAY LIKE 'E'.
    CHECK 1 EQ 2.
  ENDIF.

  PERFORM GETDATA.
  PERFORM SHOWDATA.



*&---------------------------------------------------------------------*
*&      Form  GETDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GETDATA .
  SELECT
    MR~MATNR
    MT~MAKTX
    AP~ATWRT
    AP~ATFLV
    AP~ATFLB
    AP~ATINN
    CN~ATFOR
    CN~ANZST
    CN~ANZDZ
    CN~MSEHI
    CT~ATBEZ
    TA~MSEH6
    TA~SPRAS
    FROM MARA AS MR
    JOIN MAKT AS MT ON MR~MATNR EQ MT~MATNR
    JOIN AUSP AS AP ON MR~MATNR EQ AP~OBJEK
  JOIN CABN AS CN ON AP~ATINN EQ CN~ATINN
    JOIN CABNT AS CT ON CN~ATINN EQ CT~ATINN
  LEFT JOIN T006A AS TA ON CN~MSEHI EQ TA~MSEHI
  INTO CORRESPONDING FIELDS OF TABLE GT_METADATAS
  WHERE AP~OBJEK IN P_MATNR
  AND MR~MATKL IN P_MATKL.

  DELETE GT_METADATAS WHERE SPRAS IS NOT INITIAL AND SPRAS NE SY-LANGU.

  LOOP AT GT_METADATAS WHERE ATFOR EQ 'NUM'.

    CALL FUNCTION 'FLTP_CHAR_CONVERSION'
      EXPORTING
      DECIM = GT_METADATAS-ANZDZ
        EXPON = 0
        INPUT = GT_METADATAS-ATFLV
        IVALU = 'X'
*       MASKN = ' '
      IMPORTING
        FLSTR = GT_METADATAS-DEGER1.

    " De�erleri tek kolonda g�rmek i�in atama yap�ld�
    GT_METADATAS-ATWRT = GT_METADATAS-DEGER1.

    CALL FUNCTION 'FLTP_CHAR_CONVERSION'
      EXPORTING
        DECIM = GT_METADATAS-ANZDZ
        EXPON = 0
        INPUT = GT_METADATAS-ATFLB
        IVALU = 'X'
*       MASKN = ' '
      IMPORTING
        FLSTR = GT_METADATAS-DEGER2.

    MODIFY GT_METADATAS.

  ENDLOOP.

ENDFORM.                    " GETDATA


*&---------------------------------------------------------------------*
*&      Form  SHOWDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM SHOWDATA .
  DATA: I_SORT TYPE SLIS_SORTINFO_ALV,
        IT_SORT TYPE  SLIS_T_SORTINFO_ALV.
  I_SORT-SPOS  = 1.
  I_SORT-FIELDNAME = 'MATNR'.
  APPEND I_SORT TO IT_SORT.

  I_SORT-SPOS  = 2.
  I_SORT-FIELDNAME = 'MAKTX'.
  APPEND I_SORT TO IT_SORT.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      I_PROGRAM_NAME     = SY-REPID
      I_INTERNAL_TABNAME = 'GT_METADATAS'
      I_INCLNAME         = SY-REPID
    CHANGING
      CT_FIELDCAT        = FCAT[].

  PERFORM SET_FCAT.

  LAYOUT-COLWIDTH_OPTIMIZE = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM = SY-REPID
      IS_LAYOUT          = LAYOUT
      IT_FIELDCAT        = FCAT[]
      I_SAVE             = 'A'
      IS_VARIANT         = VARYANT
      IT_SORT            = IT_SORT
    TABLES
      T_OUTTAB           = GT_METADATAS.

ENDFORM.                    " SHOWDATA


*&---------------------------------------------------------------------*
*&      Form  SET_FCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM SET_FCAT .
  DATA: FCATROW LIKE LINE OF FCAT.

  LOOP AT FCAT INTO FCATROW.
    CASE FCATROW-FIELDNAME.
      WHEN 'MSEHI'.
        FCATROW-TECH = 'X'.
      WHEN 'SPRAS'.
        FCATROW-TECH = 'X'.
      WHEN 'ATFOR'.
        FCATROW-TECH = 'X'.
      WHEN 'ANZST'.
        FCATROW-TECH = 'X'.
      WHEN 'ANZDZ'.
        FCATROW-TECH = 'X'.
      WHEN 'ATFLB'.
        FCATROW-TECH = 'X'.
      WHEN 'ATFLV'.
        FCATROW-TECH = 'X'.
      WHEN 'DEGER1'.
        FCATROW-SELTEXT_S = 'Alt De�er'.
        FCATROW-SELTEXT_M = 'Alt De�er'.
        FCATROW-SELTEXT_L = 'Alt De�er'.
        FCATROW-REPTEXT_DDIC = 'Alt De�er'.
        FCATROW-TECH = 'X'.

      WHEN 'DEGER2'.
        FCATROW-SELTEXT_S = '�st De�er'.
        FCATROW-SELTEXT_M = '�st De�er'.
        FCATROW-SELTEXT_L = '�st De�er'.
        FCATROW-REPTEXT_DDIC = '�st De�er'.
        FCATROW-TECH = 'X'.
    ENDCASE.

    MODIFY FCAT FROM FCATROW.

  ENDLOOP.

ENDFORM.                    " SET_FCAT

