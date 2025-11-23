*&---------------------------------------------------------------------*
*& Depolar Arası Parti Transferi ve Loglama
*&---------------------------------------------------------------------*
REPORT ZHCPP_P114.

* --- Tablo ve Veri Tanımlamaları ---
TABLES: ZHCPP_T073.

* Ekran verilerini tutmak için global yapı (ekran 0100'deki alanlar)
DATA: GS_DATA TYPE ZHCPP_T073,
      GV_MEVCUTSTOK TYPE MENGE_D.

* BAPI İçin Gerekli Yapılar
DATA:
  LS_HEADER TYPE BAPI2017_GM_HEAD_01,
  LT_ITEM   TYPE STANDARD TABLE OF BAPI2017_GM_ITEM_CREATE,
  LS_ITEM   TYPE BAPI2017_GM_ITEM_CREATE,
  LT_RETURN TYPE STANDARD TABLE OF BAPIRET2,
  LS_RETURN TYPE BAPIRET2.

DATA:
  LV_MAT_DOC  TYPE MBLNR,  " Oluşturulan Malzeme Belge Numarası
  LV_CTRL     TYPE C.     " Hata Kontrol Değişkeni


* Program başlangıcı - Ekranı Çağırma
CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
* Kullanıcı etkileşimlerini (buton basımı) yönetir
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.

  CASE SY-UCOMM.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM FORM_SAVE.
    WHEN OTHERS.
      PERFORM GET_MATNR.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT


*&---------------------------------------------------------------------*
*&      Form  GET_MATNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_MATNR.
  "Önce Z tablosunda arar
  SELECT SINGLE MATNR INTO GS_DATA-MATNR FROM ZHCPP_T001 WHERE ETKNO EQ GS_DATA-CHARG.

  "Z tablosunda bulunamazsa, standart MCHB tablosunda arar
  IF GS_DATA-MATNR IS INITIAL.
    SELECT SINGLE MATNR INTO GS_DATA-MATNR FROM MCHB
      WHERE CHARG = GS_DATA-CHARG
        AND WERKS = GS_DATA-WERKS.   "Üretim yeri de verilmeli
  ENDIF.

  "Yine bulunamazsa, MCHA (parti yönetimi) tablosunda deneyebilirsiniz
  IF GS_DATA-MATNR IS INITIAL.
    SELECT SINGLE MATNR INTO GS_DATA-MATNR FROM MCHA
      WHERE CHARG = GS_DATA-CHARG
        AND WERKS = GS_DATA-WERKS.
  ENDIF.

  IF GS_DATA-MATNR IS NOT INITIAL.

    SELECT SINGLE MEINS INTO GS_DATA-MEINS FROM MARA
    WHERE MATNR EQ GS_DATA-MATNR.

    IF GS_DATA-MATNR IS NOT INITIAL
        AND GS_DATA-WERKS IS NOT INITIAL
        AND GS_DATA-KLGORT IS NOT INITIAL
        AND GS_DATA-CHARG IS NOT INITIAL.
      SELECT SUM( CLABS ) INTO GV_MEVCUTSTOK FROM MCHB
            WHERE MATNR = GS_DATA-MATNR
            AND WERKS = GS_DATA-WERKS
            AND LGORT = GS_DATA-KLGORT
            AND CHARG = GS_DATA-CHARG.
    ENDIF.



  ENDIF.

ENDFORM.                    "GET_MATNR


*&---------------------------------------------------------------------*
*&      Form  FORM_SAVE
*&---------------------------------------------------------------------*
* Kaydetme ve Transfer İşlemini Yürütür
*----------------------------------------------------------------------*
FORM FORM_SAVE .

  CLEAR LV_CTRL.
  PERFORM FORM_CHECK.
* Eğer kontrol başarısızsa (LV_CTRL = 'X'), kaydetme ve transfer işlemini atla
  CHECK LV_CTRL NE 'X'.

* --- 1. Stok Transferini Gerçekleştirme ---
  PERFORM FORM_CREATE_GOODS_MOVEMENT USING LV_MAT_DOC CHANGING LV_CTRL.

  IF LV_CTRL NE 'X'.
* --- 2. İşlem Başarılıysa Log Tablosuna Kaydetme (ZHCPP_T073) ---
    PERFORM FORM_INSERT_LOG USING LV_MAT_DOC.
    PERFORM CLEAR_FIELDS.
    MESSAGE 'Transfer başarıyla tamamlandı.' TYPE 'S'.
  ELSE.
* --- 3. İşlem Başarısızsa Hata Mesajlarını Gösterme ---
    MESSAGE 'Transfer işlemi sırasında HATA oluştu.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.                   " FORM_SAVE

*&---------------------------------------------------------------------*
*&      Form  FORM_CHECK
*&---------------------------------------------------------------------*
* Zorunlu Alan Kontrolleri
*----------------------------------------------------------------------*
FORM FORM_CHECK .

* MANDT alanı otomatik olarak sistem tarafından doldurulur.
  IF GS_DATA-CHARG IS INITIAL.
    MESSAGE 'Parti Numarası zorunludur.' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-WERKS IS INITIAL.
    MESSAGE 'Üretim Yeri zorunludur.' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-KLGORT IS INITIAL.
    MESSAGE 'Kaynak Depo Yeri zorunludur.' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-HLGORT IS INITIAL.
    MESSAGE 'Hedef Depo zorunludur.' TYPE 'X'. " Hedef depo yoksa hata ver
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-MENGE <= 0.
    MESSAGE 'Miktar sıfırdan büyük olmalıdır.' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-MATNR IS INITIAL.
    MESSAGE 'Malzeme bilgisi alınamadı' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-MEINS IS INITIAL.
    MESSAGE 'Birim bilgisi alınamadı' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

  IF GS_DATA-PERNR IS INITIAL.
    MESSAGE 'Personel Numarası zorunludur.' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ELSE.
    DATA: LV_PERNR TYPE PERNR.
    LV_PERNR = GS_DATA-PERNR.
    SELECT SINGLE PERNR INTO LV_PERNR FROM PA0001 WHERE PERNR = LV_PERNR.
    IF SY-SUBRC <> 0.
      MESSAGE 'Geçersiz Personel Numarası!' TYPE 'S' DISPLAY LIKE 'E'.
      LV_CTRL = 'X'.
      RETURN.
    ENDIF.
  ENDIF.

  " KLgort deposunda menge kadar stok var mı kontrolü
  DATA: LV_LGORT_STOCK TYPE MENGE_D.

  SELECT SUM( CLABS ) INTO LV_LGORT_STOCK FROM MCHB
      WHERE MATNR = GS_DATA-MATNR
      AND WERKS = GS_DATA-WERKS
      AND LGORT = GS_DATA-KLGORT
      AND CHARG = GS_DATA-CHARG.

  IF LV_LGORT_STOCK < GS_DATA-MENGE.
    MESSAGE 'Kaynak depoda yeterli stok yok!' TYPE 'S' DISPLAY LIKE 'E'.
    LV_CTRL = 'X'.
    RETURN.
  ENDIF.

ENDFORM.                   " FORM_CHECK

*&---------------------------------------------------------------------*
*&      Form  FORM_CREATE_GOODS_MOVEMENT
*&---------------------------------------------------------------------*
* Stok Transferini BAPI ile Gerçekleştirme
*----------------------------------------------------------------------*
FORM FORM_CREATE_GOODS_MOVEMENT USING    PV_MAT_DOC TYPE MBLNR
                                CHANGING PV_CTRL    TYPE C.

  CLEAR: LS_HEADER, LS_ITEM, LT_ITEM, LT_RETURN.

* Başlık
  LS_HEADER-PSTNG_DATE = SY-DATUM.
  LS_HEADER-DOC_DATE   = SY-DATUM.
  LS_HEADER-REF_DOC_NO = 'ZHCPP_P114 TRANSFER'.

  DATA: LS_CODE  TYPE BAPI2017_GM_CODE.



  "En son halen boşsa hata verdirilebilir
  IF GS_DATA-MATNR IS INITIAL.
    MESSAGE 'Malzeme numarası bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

* Kalem
  CLEAR LS_ITEM.
  LS_ITEM-MATERIAL   = GS_DATA-MATNR.
  LS_ITEM-PLANT      = GS_DATA-WERKS.
  LS_ITEM-STGE_LOC   = GS_DATA-KLGORT.
  LS_ITEM-BATCH      = GS_DATA-CHARG.
  LS_ITEM-MOVE_TYPE  = '311'.
  LS_ITEM-ENTRY_QNT  = GS_DATA-MENGE.
  LS_ITEM-ENTRY_UOM  = GS_DATA-MEINS.
  LS_ITEM-MOVE_STLOC = GS_DATA-HLGORT.

* ÖNEMLİ: Rezervasyon yoksa bu ikisini de BOŞ bırakın
  CLEAR: LS_ITEM-RESERV_NO, LS_ITEM-RES_ITEM.
* Rezervasyon kullanacaksanız:
*  LS_ITEM-RESERV_NO = '<RESERV_NO>'.
*  LS_ITEM-RES_ITEM  = '<ITEM>'.

  APPEND LS_ITEM TO LT_ITEM.

* BAPI çağrısı
  LS_CODE-GM_CODE = '04'.  " MB1B / Transfer Postingi
  CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
    EXPORTING
      GOODSMVT_HEADER  = LS_HEADER
      GOODSMVT_CODE    = LS_CODE
    IMPORTING
      MATERIALDOCUMENT = PV_MAT_DOC
    TABLES
      GOODSMVT_ITEM    = LT_ITEM
      RETURN           = LT_RETURN.

* Hata kontrolü
  PV_CTRL = SPACE.
  LOOP AT LT_RETURN INTO LS_RETURN WHERE TYPE CA 'EA'.
    PV_CTRL = 'X'.
    EXIT.
  ENDLOOP.

  IF PV_CTRL EQ 'X'.
    PERFORM FORM_SHOW_BAPI_MESSAGES.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
  ENDIF.

ENDFORM.                    "FORM_CREATE_GOODS_MOVEMENT

*&---------------------------------------------------------------------*
*&      Form  FORM_INSERT_LOG
*&---------------------------------------------------------------------*
* Transfer Belgesini ZHCPP_T073 Tablosuna Kaydetme
*----------------------------------------------------------------------*
FORM FORM_INSERT_LOG USING PV_MAT_DOC TYPE MBLNR.

* GS_DATA zaten ekran verilerini içeriyor.
  GS_DATA-PERNR = GS_DATA-PERNR. " Personel No (Ekrandan gelmeli)
  GS_DATA-DATUM = SY-DATUM.    " Tarih
  GS_DATA-UZEIT = SY-UZEIT.    " Saat
  GS_DATA-UNAME = SY-UNAME.    " Kullanıcı Ad
  GS_DATA-MBLNR = PV_MAT_DOC. " Oluşan Malzeme Belge No
* Kayıt Loguna özel alanlar:
* GS_DATA-TRANSP_TABLE = 'MBLNR'. " Belge tipini kaydet

  INSERT ZHCPP_T073 FROM GS_DATA.

  IF SY-SUBRC EQ 0.
    COMMIT WORK.
  ELSE.
    MESSAGE 'Log tablosuna kayıt başarısız oldu!' TYPE 'W'.
  ENDIF.

ENDFORM.                   " FORM_INSERT_LOG

*&---------------------------------------------------------------------*
*&      Form  FORM_SHOW_BAPI_MESSAGES
*&---------------------------------------------------------------------*
* BAPI Hata Mesajlarını Ekranda Gösterme
*----------------------------------------------------------------------*
FORM FORM_SHOW_BAPI_MESSAGES.
  WRITE: / 'BAPI Hata Mesajları:'.
  LOOP AT LT_RETURN INTO LS_RETURN.
    MESSAGE ID LS_RETURN-ID TYPE LS_RETURN-TYPE NUMBER LS_RETURN-NUMBER
            WITH LS_RETURN-MESSAGE_V1 LS_RETURN-MESSAGE_V2
            LS_RETURN-MESSAGE_V3 LS_RETURN-MESSAGE_V4 DISPLAY LIKE 'E'.
  ENDLOOP.
ENDFORM.                   " FORM_SHOW_BAPI_MESSAGES
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.

*  SET PF-STATUS 'xxxxxxxx'.
*  SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_0100  OUTPUT

*&---------------------------------------------------------------------*
*&      Form  clear_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM CLEAR_FIELDS.
  DATA: LV_PERNR LIKE GS_DATA-PERNR.
  LV_PERNR = GS_DATA-PERNR.
  CLEAR GS_DATA.
  CLEAR GV_MEVCUTSTOK.

  GS_DATA-PERNR = LV_PERNR.
ENDFORM.                    "clear_fields