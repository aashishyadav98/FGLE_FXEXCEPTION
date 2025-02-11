@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Consumption view for FX rate variance'

@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #XXL, dataClass: #MIXED }

@VDM.viewType: #CONSUMPTION

define view entity ZC_EXCHRATEVARIANCE
  as select from ZI_EXCHRATEVARIANCE

{
      @Consumption.filter.mandatory: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_LedgerStdVH', element: 'Ledger' } } ]
  key SourceLedger,

      @Consumption.filter.mandatory: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_JournalEntryCompanyCodeVH', element: 'CompanyCode' },
                                            additionalBinding: [ { localElement: 'CompanyCodeCurrency',
                                                                   element: 'Currency' } ] } ]
  key CompanyCode,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_FiscalYearForCompanyCode', element: 'FiscalYear' },
                                            additionalBinding: [ { localElement: 'CompanyCode', element: 'CompanyCode' } ] } ]
  key FiscalYear,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_JournalEntryStdVH', element: 'AccountingDocument' },
                                            additionalBinding: [ { localElement: 'CompanyCode', element: 'CompanyCode' },
                                                                 { localElement: 'FiscalYear',  element: 'FiscalYear'  } ] } ]
  key AccountingDocument,

  key LedgerGLLineItem,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_LedgerStdVH', element: 'Ledger' } } ]
  key Ledger,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_AccountingDocumentTypeStdVH',
                                                      element: 'AccountingDocumentType' } } ]
      AccountingDocumentType,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ChartOfAccountsStdVH', element: 'ChartOfAccounts' } } ]
      ChartOfAccounts,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ControllingArea', element: 'ControllingArea' } } ]
      ControllingArea,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_GLAcctInChtOfAcctsStdVH', element: 'GLAccount' },
                                            additionalBinding: [ { localElement: 'ChartOfAccounts',
                                                                   element: 'ChartOfAccounts' } ] } ]
      GLAccount,

      PostingDate,

      @Consumption.filter: { mandatory: true, selectionType: #INTERVAL }
      @EndUserText.label: 'Processed Date'
      ProcessedDate,

      ExchangeRateDate,

      @Consumption.filter.mandatory: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_ExchangeRateTypeVH', element: 'ExchangeRateType' } } ]
      ExchangeRateType                as ExchangeRateType,

      CreationDateTime,


      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ProfitCenterVH', element: 'ProfitCenter' },
                                            additionalBinding: [ { localElement: 'ControllingArea',
                                                                   element: 'ControllingArea' } ] } ]
      ProfitCenter,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CostCenterStdVH', element: 'CostCenter' },
                                            additionalBinding: [ { localElement: 'ControllingArea',
                                                                   element: 'ControllingArea' } ] } ]
      CostCenter,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ProductVH', element: 'Product' } } ]
      Product,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SegmentStdVH', element: 'Segment' } } ]
      Segment,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Currency', element: 'Currency' } } ]
      TransactionCurrency,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      AmountInTransactionCurrency,

      @Consumption.filter.mandatory: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Currency', element: 'Currency' } } ]
      @EndUserText.label: 'CompanyCode Currency'
      CompanyCodeCurrency,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmountInCompanyCodeCurrency,

      @EndUserText.label: 'Journal Exchange Rate'
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FGLE_FXVARIANCE_UTILS'
      cast(0 as abap.dec(14,5))       as JournalExchRate,

      @EndUserText.label: 'EOD Exchange Rate'
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FGLE_FXVARIANCE_UTILS'
      cast(0 as abap.dec(14,5))       as EODExchRate,

      @EndUserText.label: 'Variance Amount'
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FGLE_FXVARIANCE_UTILS'
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      cast(0 as fis_hsl)              as VarianceAmount,

      @EndUserText.label: 'Variance %'
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FGLE_FXVARIANCE_UTILS'
      cast(0 as gle_fxr_dte_difratex) as ExchangeRateVariance,

      @EndUserText.label: 'Variance Criticality'
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FGLE_FXVARIANCE_UTILS'
      0                               as VarianceCriticality
}
