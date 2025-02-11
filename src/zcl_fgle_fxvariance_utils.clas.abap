class ZCL_FGLE_FXVARIANCE_UTILS definition
  public
  final
  create public .

public section.

  interfaces IF_SADL_EXIT .
  interfaces IF_SADL_EXIT_CALC_ELEMENT_READ .
  PROTECTED SECTION.
    TYPES: BEGIN OF ty_currency_shift,
             currency TYPE waers,
             shift    TYPE i,
           END OF ty_currency_shift.
    TYPES: BEGIN OF ty_document_type,
             doctype  TYPE T003-blart,
             xkursx   TYPE T003-xkursx,
           END OF TY_document_type.
    TYPES tt_waers TYPE STANDARD TABLE OF waers.

    DATA m_currshift TYPE HASHED TABLE OF ty_currency_shift WITH UNIQUE KEY currency.
    DATA m_doctypes  TYPE HASHED TABLE OF ty_document_type WITH UNIQUE KEY doctype.
    METHODS read_classical_fxrate IMPORTING iv_kurst         TYPE kurst
                                            iv_date          TYPE dats
                                            iv_from_curr     TYPE waers
                                            iv_to_curr       TYPE waers
                                  RETURNING VALUE(rv_fxrate) TYPE kursf.

    METHODS read_extended_fxrate IMPORTING iv_kurst         TYPE kurst
                                           iv_date          TYPE dats
                                           iv_from_curr     TYPE waers
                                           iv_to_curr       TYPE waers
                                 RETURNING VALUE(rv_fxrate) TYPE gle_fxr_dte_ratex28.

    METHODS read_exchange_rate IMPORTING iv_xkursx        TYPE x_fxr_ratex
                                         iv_kurst         TYPE kurst
                                         iv_date          TYPE dats
                                         iv_from_curr     TYPE waers
                                         iv_to_curr       TYPE waers
                               RETURNING VALUE(rv_fxrate) TYPE gle_fxr_dte_ratex28.

    METHODS read_document_type IMPORTING iv_blart TYPE t003-blart.
    METHODS calculate_currency_shift IMPORTING it_currencies TYPE tt_waers.
ENDCLASS.



CLASS ZCL_FGLE_FXVARIANCE_UTILS IMPLEMENTATION.

  METHOD READ_DOCUMENT_TYPE.

  " Check if the input document type is provided
  CHECK iv_blart IS NOT INITIAL.

  " Check if the document type data already exists in the cache
  IF line_exists( m_doctypes[ doctype = iv_blart ] ).
    RETURN. " Exit if data is already cached
  ENDIF.

  " Select the XKURSX field from T003 table
  SELECT SINGLE xkursx
    INTO @DATA(lv_xkursx)
    FROM t003
    WHERE blart = @iv_blart.
  IF sy-subrc = 0.
    INSERT VALUE #( doctype = iv_blart
                    xkursx  = lv_xkursx ) INTO TABLE m_doctypes.
  ENDIF.

  ENDMETHOD.
  METHOD CALCULATE_CURRENCY_SHIFT.
    DATA lt_missed_currencies TYPE TABLE OF waers.
    DATA lt_tcurx             TYPE HASHED TABLE OF tcurx WITH UNIQUE KEY currkey.

    LOOP AT it_currencies ASSIGNING FIELD-SYMBOL(<fs_currency>).
      IF NOT line_exists( m_currshift[ currency = <fs_currency> ] ).
        " If not present, add to the list of missed currencies
        APPEND <fs_currency> TO lt_missed_currencies.
      ENDIF.
    ENDLOOP.

    " Fetch data from TCURX only for the currencies that are missing
    IF lt_missed_currencies IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM tcurx
      FIELDS *
      FOR ALL ENTRIES IN @lt_missed_currencies
      WHERE currkey = @lt_missed_currencies-table_line
      INTO TABLE @lt_tcurx[].

    LOOP AT lt_missed_currencies ASSIGNING <fs_currency>.
      ASSIGN lt_tcurx[ currkey = <fs_currency> ] TO FIELD-SYMBOL(<fs_tcurx>).
      DATA(lv_shift) = 0. " Default shift for currencies with two decimals
      IF sy-subrc = 0 AND <fs_tcurx> IS ASSIGNED. " Currency has a number of decimals not equal two
        lv_shift = 2 - <fs_tcurx>-currdec.
      ENDIF.
      INSERT VALUE #( currency = <fs_currency>
                      shift    = lv_shift ) INTO TABLE m_currshift.
    ENDLOOP.
  ENDMETHOD.


  METHOD IF_SADL_EXIT_CALC_ELEMENT_READ~CALCULATE.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zc_exchratevariance WITH DEFAULT KEY.
    DATA lv_xkursx          TYPE t003-xkursx.
    DATA lv_eod_fxrate      TYPE gle_fxr_dte_ratex28.
    DATA lv_journal_fxrate  TYPE gle_fxr_dte_ratex28.
    DATA lv_fcur_amt_calc   TYPE fins_vhcur12.
    DATA lv_tcurramount_ext TYPE fins_vwcur12.
    DATA lv_cccuramount_ext TYPE fins_vhcur12.
    DATA lv_shift           TYPE int1.

    CHECK it_original_data IS NOT INITIAL.
    MOVE-CORRESPONDING it_original_data TO lt_calculated_data.

    LOOP AT lt_calculated_data[] ASSIGNING FIELD-SYMBOL(<fs_calculated_data>)
         GROUP BY ( blart        = <fs_calculated_data>-AccountingDocumentType
                    fxrate_type  = <fs_calculated_data>-ExchangeRateType
                    from_curr    = <fs_calculated_data>-TransactionCurrency
                    to_curr      = <fs_calculated_data>-CompanyCodeCurrency
                    posting_date = <fs_calculated_data>-PostingDate
                    fxrate_date  = <fs_calculated_data>-ExchangeRateDate )
         ASSIGNING FIELD-SYMBOL(<fs_key>).

      " Get details for document type
      read_document_type( iv_blart = <fs_key>-blart  ).

      " Calculate currency shifts
      calculate_currency_shift( it_currencies = VALUE #( ( <fs_key>-from_curr ) ( <fs_key>-to_curr ) ) ).

      CLEAR: lv_xkursx,
             lv_eod_fxrate.
      lv_xkursx     = VALUE #( m_doctypes[ doctype = <fs_key>-blart ]-xkursx OPTIONAL ).
      lv_eod_fxrate = read_exchange_rate(
                          iv_xkursx    = lv_xkursx
                          iv_kurst     = <fs_key>-fxrate_type
                          iv_date      = COND dats( WHEN <fs_key>-fxrate_date IS INITIAL
                                                    THEN <fs_key>-posting_date
                                                    ELSE <fs_key>-fxrate_date )
                          iv_from_curr = <fs_key>-from_curr
                          iv_to_curr   = <fs_key>-to_curr ).

      LOOP AT GROUP <fs_key> ASSIGNING FIELD-SYMBOL(<fs_member>).
        CLEAR: lv_journal_fxrate,
               lv_fcur_amt_calc,
               lv_shift,
               lv_tcurramount_ext,
               lv_cccuramount_ext,
               <fs_member>-journalexchrate,
               <fs_member>-eodexchrate,
               <fs_member>-ExchangeRateVariance,
               <fs_member>-varianceamount,
               <fs_member>-VarianceCriticality.
        " Check on amount in transaction currency
        IF <fs_member>-amountintransactioncurrency = 0.
          CONTINUE. " No relation possible for variance
        ENDIF.

        lv_shift = VALUE #( m_currshift[ currency = <fs_member>-TransactionCurrency ]-shift OPTIONAL ).
        lv_tcurramount_ext = <fs_member>-amountintransactioncurrency * ( 10 ** lv_shift ).

        lv_shift = VALUE #( m_currshift[ currency = <fs_member>-CompanyCodeCurrency ]-shift OPTIONAL ).
        lv_cccuramount_ext = <fs_member>-AmountInCompanyCodeCurrency * ( 10 ** lv_shift ).

        " Determine Journal FX rate
        lv_journal_fxrate = lv_cccuramount_ext / lv_tcurramount_ext.

        " Calculate Functional Currency Amount
        lv_fcur_amt_calc = lv_tcurramount_ext * lv_eod_fxrate.

        " Results Mapping
        <fs_member>-JournalExchRate = round( val = lv_journal_fxrate
                                             dec = 5 ).
        <fs_member>-EODExchRate     = round( val = lv_eod_fxrate
                                             dec = 5 ).
        <fs_member>-VarianceAmount  = lv_fcur_amt_calc - lv_cccuramount_ext.
        IF lv_eod_fxrate IS NOT INITIAL.
          <fs_member>-ExchangeRateVariance = abs( lv_journal_fxrate / lv_eod_fxrate - 1 ) * 100.
          <fs_member>-VarianceCriticality  = COND #( WHEN <fs_member>-ExchangeRateVariance > '2.50' THEN 1
                                                    ELSE 3 ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    MOVE-CORRESPONDING lt_calculated_data[] TO ct_calculated_data[].
  ENDMETHOD.


  METHOD IF_SADL_EXIT_CALC_ELEMENT_READ~GET_CALCULATION_INFO.
    et_requested_orig_elements = VALUE #( BASE et_requested_orig_elements
                                          ( CONV #( 'ACCOUNTINGDOCUMENTTYPE' ) )
                                          ( CONV #( 'POSTINGDATE' ) )
                                          ( CONV #( 'EXCHANGERATEDATE' ) )
                                          ( CONV #( 'EXCHANGERATETYPE' ) )
                                          ( CONV #( 'TRANSACTIONCURRENCY' ) )
                                          ( CONV #( 'COMPANYCODECURRENCY' ) ) ).
  ENDMETHOD.


  METHOD READ_CLASSICAL_FXRATE.
    DATA lv_kurst TYPE kurst.

    CLEAR rv_fxrate.

    IF iv_kurst IS INITIAL.
      lv_kurst = 'M'.
    ELSE.
      lv_kurst = iv_kurst.
    ENDIF.

    " In case of Tri-angulation, FM: 'READ_EXCHANGE_RATE' requires
    " the maintenance of Translation ratio between Foreign(from) and Local(to) Currency
    CALL FUNCTION 'READ_EXCHANGE_RATE'
      EXPORTING  date             = iv_date
                 foreign_currency = iv_from_curr
                 local_currency   = iv_to_curr
                 type_of_rate     = lv_kurst
      IMPORTING  exchange_rate    = rv_fxrate
      EXCEPTIONS no_rate_found    = 1.

    IF sy-subrc IS NOT INITIAL.
      CLEAR rv_fxrate.
    ENDIF.

    " Convert Result into Direct Quotation Form
    IF rv_fxrate < 0.
      rv_fxrate = ( 1 / rv_fxrate ) * ( -1 ).
    ENDIF.
  ENDMETHOD.


  METHOD READ_EXCHANGE_RATE.
    DATA lv_xeodrate TYPE gle_fxr_dte_ratex28.
    DATA lv_eodrate  TYPE kursf.

    IF iv_from_curr = iv_to_curr.
      rv_fxrate = 1.
      RETURN.
    ENDIF.
    IF iv_xkursx = abap_true.
      lv_xeodrate = read_extended_fxrate( iv_kurst     = iv_kurst
                                          iv_date      = iv_date
                                          iv_from_curr = iv_from_curr
                                          iv_to_curr   = iv_to_curr ).
      IF lv_xeodrate IS NOT INITIAL.
        rv_fxrate = lv_xeodrate.
      ENDIF.
    ELSE.
      lv_eodrate = read_classical_fxrate( iv_kurst     = iv_kurst
                                          iv_date      = iv_date
                                          iv_from_curr = iv_from_curr
                                          iv_to_curr   = iv_to_curr ).
      IF lv_eodrate IS NOT INITIAL.
        rv_fxrate = CONV #( lv_eodrate ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD READ_EXTENDED_FXRATE.
    DATA lv_kurst TYPE kurst.

    CLEAR rv_fxrate.
    IF iv_kurst IS INITIAL.
      lv_kurst = 'M'.
    ELSE.
      lv_kurst = iv_kurst.
    ENDIF.

    CALL FUNCTION 'GLE_AL_FXR_CONVERT_CURRENCY'
      EXPORTING  date           = iv_date
                 from_amount    = 1
                 from_currency  = iv_from_curr
                 to_currency    = iv_to_curr
                 type_of_rate   = lv_kurst
      IMPORTING  exchange_ratex = rv_fxrate
      EXCEPTIONS failed         = 1
                 OTHERS         = 2.
    IF sy-subrc IS NOT INITIAL.
      CLEAR rv_fxrate.
    ENDIF.

    " Convert Result into Direct Quotation Form
    IF rv_fxrate < 0.
      rv_fxrate = ( 1 / rv_fxrate ) * ( -1 ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
