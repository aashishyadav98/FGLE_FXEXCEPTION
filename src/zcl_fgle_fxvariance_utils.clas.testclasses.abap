" Test class for Class: 'ZCL_FGLE_FXVARIANCE_UTILS'
CLASS ltc_test_class DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    " Types
    TYPES tt_elements TYPE SORTED TABLE OF string WITH UNIQUE DEFAULT KEY.
    TYPES ty_scenario TYPE zc_exchratevariance.

    " Class under Test
    CLASS-DATA fxvariance_hdlr         TYPE REF TO zcl_fgle_fxvariance_utils.
    CLASS-DATA requested_calc_elements TYPE SORTED TABLE OF string WITH UNIQUE DEFAULT KEY.

    " Test class setup and tear down
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    CLASS-METHODS assert_equals_generic
      IMPORTING iv_expected TYPE any
                iv_actual   TYPE any
                iv_field    TYPE string
                iv_sno      TYPE i.

    METHODS run_single_test
      IMPORTING iv_sno      TYPE i
                is_scenario TYPE ty_scenario.

    " Test method declaration
    METHODS scenario1          FOR TESTING.
    METHODS test_all_scenarios FOR TESTING.
ENDCLASS.


CLASS ltc_test_class IMPLEMENTATION.
  METHOD class_setup.
    fxvariance_hdlr = NEW zcl_fgle_fxvariance_utils( ).
    requested_calc_elements = VALUE #( ( CONV #( 'ACCOUNTINGDOCUMENTTYPE' ) )
                                       ( CONV #( 'POSTINGDATE' ) )
                                       ( CONV #( 'EXCHANGERATEDATE' ) )
                                       ( CONV #( 'EXCHANGERATETYPE' ) )
                                       ( CONV #( 'TRANSACTIONCURRENCY' ) )
                                       ( CONV #( 'COMPANYCODECURRENCY' ) ) ).
  ENDMETHOD.

  METHOD assert_equals_generic.
    " Unified assertion handling
    cl_abap_unit_assert=>assert_equals(
        exp  = iv_expected
        act  = iv_actual
        msg  = |Scenario: { iv_sno } Computed { iv_field } is incorrect. Expected: { iv_expected }, but got: { iv_actual }.|
        quit = if_abap_unit_constant=>quit-no ).
  ENDMETHOD.

  METHOD scenario1.
    " GIVEN in class setup
    " WHEN
    TRY.
        fxvariance_hdlr->if_sadl_exit_calc_element_read~get_calculation_info(
          EXPORTING it_requested_calc_elements = VALUE tt_elements( ( CONV #( 'EODEXCHRATE' ) )
                                                                    ( CONV #( 'EXCHANGERATEVARIANCE' ) )
                                                                    ( CONV #( 'JOURNALEXCHRATE' ) )
                                                                    ( CONV #( 'VARIANCEAMOUNT' ) )
                                                                    ( CONV #( 'VARIANCECRITICALITY' ) ) )
                    iv_entity                  = 'ZC_EXCHRATEVARIANCE'
          IMPORTING et_requested_orig_elements = DATA(lt_requested_orig_elements) ).
      CATCH cx_sadl_exit INTO DATA(exception). " TODO: variable is assigned but never used (ABAP cleaner)
        cl_abap_unit_assert=>fail(
            msg    = 'Exception raised'
            level  = if_abap_unit_constant=>severity-high
            quit   = if_abap_unit_constant=>quit-test
            detail = 'Please check implementation of method get_calculation_info in class zcl_fgle_fxvariance_utils' ).
    ENDTRY.

    " THEN
    " Assertion for Requested Original Elements
    cl_abap_unit_assert=>assert_equals(
        exp  = requested_calc_elements
        act  = lt_requested_orig_elements
        msg  = | Requested original elements from CDS view is incorrect. Please check the requested original elements|  " Error message
        quit = if_abap_unit_constant=>quit-no ).                 " No test termination
  ENDMETHOD.

  METHOD run_single_test.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zc_exchratevariance WITH DEFAULT KEY.

    " GIVEN: Setup test data
    lt_calculated_data = VALUE #( ( AccountingDocumentType      = is_scenario-AccountingDocumentType
                                    PostingDate                 = is_scenario-PostingDate
                                    ExchangeRateDate            = is_scenario-ExchangeRateDate
                                    ExchangeRateType            = is_scenario-ExchangeRateType
                                    TransactionCurrency         = is_scenario-TransactionCurrency
                                    CompanyCodeCurrency         = is_scenario-CompanyCodeCurrency
                                    AmountInTransactionCurrency = is_scenario-AmountInTransactionCurrency
                                    AmountInCompanyCodeCurrency = is_scenario-AmountInCompanyCodeCurrency ) ).

    " WHEN: Invoke calculation
    TRY.
        fxvariance_hdlr->if_sadl_exit_calc_element_read~calculate(
          EXPORTING it_original_data           = lt_calculated_data
                    it_requested_calc_elements = requested_calc_elements
          CHANGING  ct_calculated_data         = lt_calculated_data ).
      CATCH cx_sadl_exit.
        " Handle exceptions, if necessary
    ENDTRY.

    " THEN: Assertions
    assert_equals_generic( iv_sno      = iv_sno
                           iv_expected = is_scenario-JournalExchRate
                           iv_actual   = lt_calculated_data[ 1 ]-JournalExchRate
                           iv_field    = 'JournalExchRate' ).
    assert_equals_generic( iv_sno      = iv_sno
                           iv_expected = is_scenario-EODExchRate
                           iv_actual   = lt_calculated_data[ 1 ]-EODExchRate
                           iv_field    = 'EODExchRate' ).
    assert_equals_generic( iv_sno      = iv_sno
                           iv_expected = is_scenario-VarianceAmount
                           iv_actual   = lt_calculated_data[ 1 ]-VarianceAmount
                           iv_field    = 'VarianceAmount' ).
    assert_equals_generic( iv_sno      = iv_sno
                           iv_expected = is_scenario-ExchangeRateVariance
                           iv_actual   = lt_calculated_data[ 1 ]-ExchangeRateVariance
                           iv_field    = 'ExchangeRateVariance' ).
  ENDMETHOD.

  METHOD test_all_scenarios.
    DATA lt_scenarios TYPE STANDARD TABLE OF zc_exchratevariance.
    DATA ls_scenario  TYPE zc_exchratevariance.

    " Define scenarios
    lt_scenarios = VALUE #( " Scenario 1
                            " Exchange rate Maintenance
                            " 01.10.2024 GBP EUR 1.20
                            " 01.10.2024 USD EUR 0.90
                            " Therefore, calculated value for GBP to USD = 1.2/0.9 = 1.33 via tri-angulation method.
                            ExchangeRateDate = '20241001'
                            ( AccountingDocumentType      = 'M1'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = 'MCA'
                              AmountInTransactionCurrency = '1000.00'
                              AmountInCompanyCodeCurrency = '1230.00'
                              JournalExchRate             = '1.23000'
                              EODExchRate                 = '1.33333'
                              VarianceAmount              = '103.33'
                              ExchangeRateVariance        = '7.75' )

                            " Scenario 2
                            " Exchange rate Maintenance
                            " 01.10.2024 IDR EUR /1,65340000000 (Indirect)
                            " Having, From-factor as "10000" and To-factor as "1".
                            " Therefore, calculated value for IDR to EUR = /16,534.00
                            ( AccountingDocumentType      = 'M1'
                              TransactionCurrency         = 'IDR'
                              CompanyCodeCurrency         = 'EUR'
                              ExchangeRateType            = 'MCA'
                              AmountInTransactionCurrency = '165.34'
                              AmountInCompanyCodeCurrency = '1.00'
                              JournalExchRate             = '0.00006'
                              EODExchRate                 = '0.00006'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' )

                            " Scenario 3
                            " Exchange rate Maintenance
                            " 01.05.2016 GBP EUR /0,78549
                            ( AccountingDocumentType      = 'SA'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'EUR'
                              ExchangeRateType            = 'EURX'
                              AmountInTransactionCurrency = '1000.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '1.30000'
                              EODExchRate                 = '1.27309'
                              VarianceAmount              = '-26.91'
                              ExchangeRateVariance        = '2.11' )

                            " Scenario 4
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'SA'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = 'M'
                              AmountInTransactionCurrency = '1000.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '1.30000'
                              EODExchRate                 = '1.50000'
                              VarianceAmount              = '200.00'
                              ExchangeRateVariance        = '13.33' )

                            " Scenario 5
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'SA'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '1000.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '1.30000'
                              EODExchRate                 = '1.50000'
                              VarianceAmount              = '200.00'
                              ExchangeRateVariance        = '13.33' )

                            " Scenario 6
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'SA'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '0.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '0.00000'
                              EODExchRate                 = '0.00000'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' )

                            " Scenario 7
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'M1'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '0.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '0.00000'
                              EODExchRate                 = '0.00000'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' )

                            " Scenario 8
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'SA'
                              TransactionCurrency         = 'XYZ'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '0.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '0.00000'
                              EODExchRate                 = '0.00000'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' )

                            " Scenario 9
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'M1'
                              TransactionCurrency         = 'GBP'
                              CompanyCodeCurrency         = 'XYZ'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '0.00'
                              AmountInCompanyCodeCurrency = '1300.00'
                              JournalExchRate             = '0.00000'
                              EODExchRate                 = '0.00000'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' )

                            " Scenario 10
                            " Exchange rate Maintenance
                            " 01.01.2001 GBP USD 1.5
                            ( AccountingDocumentType      = 'M1'
                              TransactionCurrency         = 'USD'
                              CompanyCodeCurrency         = 'USD'
                              ExchangeRateType            = ''
                              AmountInTransactionCurrency = '1000.00'
                              AmountInCompanyCodeCurrency = '1000.00'
                              JournalExchRate             = '1.00000'
                              EODExchRate                 = '1.00000'
                              VarianceAmount              = '0.00'
                              ExchangeRateVariance        = '0.00' ) ).

    LOOP AT lt_scenarios INTO ls_scenario.
      run_single_test( iv_sno      = sy-tabix
                       is_scenario = ls_scenario ).
    ENDLOOP.
  ENDMETHOD.

  METHOD class_teardown.
    CLEAR fxvariance_hdlr.
  ENDMETHOD.
ENDCLASS.
