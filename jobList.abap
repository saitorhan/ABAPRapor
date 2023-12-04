*&---------------------------------------------------------------------*
*& Report  ZIT_RP001
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZIT_RP001.

TABLES: TBTCO, TBTCP, TRDIRT, TSTC.

DATA: GT_FCAT TYPE SLIS_T_FIELDCAT_ALV.
DATA: GT_TCODE TYPE TABLE OF TSTC WITH HEADER LINE.

DATA: BEGIN OF GT_OUT OCCURS 0,
  JOBNAME   LIKE TBTCO-JOBNAME,
  STEPCOUNT LIKE TBTCP-STEPCOUNT,
  PROGNAME  LIKE TBTCP-PROGNAME,
  VARIANT   LIKE TBTCP-VARIANT,
  TEXT      LIKE TRDIRT-TEXT, "Program ad�
  SDLSTRTDT LIKE TBTCO-SDLSTRTDT, "Y�r�tme zaman�,
  SDLSTRTTM LIKE TBTCO-SDLSTRTTM, "Y�r�tme saati
  SDLUNAME like tbtcp-SDLUNAME, "Olu�turan
  AUTHCKNAM like tbtcp-AUTHCKNAM, "Olu�turan
  END OF GT_OUT.

SELECTION-SCREEN BEGIN OF BLOCK BLOK-1
  WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: P_JNAME FOR TBTCO-JOBNAME,
                P_PNAME FOR TBTCP-PROGNAME,
                P_TCODE FOR TSTC-TCODE,
                P_user FOR tbtcp-SDLUNAME,
                P_auth FOR tbtcp-AUTHCKNAM.
SELECTION-SCREEN END OF BLOCK BLOK-1.

IF P_TCODE IS NOT INITIAL.
  SELECT * FROM TSTC
    INTO CORRESPONDING FIELDS OF TABLE GT_TCODE
    WHERE pgmna ne space and TCODE IN P_TCODE.
  IF SY-SUBRC IS INITIAL.
    LOOP AT GT_TCODE.
      P_PNAME-SIGN = 'I'.
      P_PNAME-OPTION = 'EQ'.
      P_PNAME-LOW = GT_TCODE-PGMNA.

      APPEND P_PNAME.
    ENDLOOP.
  ENDIF.
ENDIF.

SELECT
  JH~JOBNAME
  JS~STEPCOUNT
  JS~PROGNAME
  JS~VARIANT
  T~TEXT
  JH~SDLSTRTDT
  JH~SDLSTRTTM
  JS~SDLUNAME
  JS~AUTHCKNAM
  INTO CORRESPONDING FIELDS OF TABLE GT_OUT
  FROM TBTCO AS JH JOIN TBTCP AS JS ON JH~JOBNAME EQ JS~JOBNAME
                                       AND JH~JOBCOUNT EQ JS~JOBCOUNT
  JOIN TRDIRT AS T ON JS~PROGNAME EQ T~NAME
  WHERE JH~JOBNAME IN P_JNAME
  AND JS~PROGNAME IN P_PNAME
  AND JS~SDLUNAME IN P_USER
  AND JS~AUTHCKNAM IN P_AUTH
  AND T~SPRSL EQ SY-LANGU
  AND JH~STATUS EQ 'S'
  ORDER BY JH~JOBNAME JS~STEPCOUNT  JH~SDLSTRTDT.

DATA: LAYOUT TYPE SLIS_LAYOUT_ALV.
LAYOUT-COLWIDTH_OPTIMIZE = 'X'.
LAYOUT-BOX_FIELDNAME = 'SEL'.

CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    I_PROGRAM_NAME         = SY-REPID
    I_INTERNAL_TABNAME     = 'GT_OUT'
    I_INCLNAME             = SY-REPID
  CHANGING
    CT_FIELDCAT            = GT_FCAT
  EXCEPTIONS
    INCONSISTENT_INTERFACE = 1
    PROGRAM_ERROR          = 2
    OTHERS                 = 3.


CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     I_CALLBACK_PROGRAM                = SY-REPID
     IT_FIELDCAT                       = GT_FCAT
    TABLES
      T_OUTTAB                          = GT_OUT
   EXCEPTIONS
     PROGRAM_ERROR                     = 1
     OTHERS                            = 2.

