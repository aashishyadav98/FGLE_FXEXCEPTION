@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Interface view for FX rate variance'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #XXL, dataClass: #MIXED }

@VDM.viewType: #BASIC

define view entity ZI_EXCHRATEVARIANCE
  as select from I_JournalEntryItem

{
  key SourceLedger,
  key CompanyCode,
  key FiscalYear,
  key AccountingDocument,
  key LedgerGLLineItem,
  key Ledger,

      AccountingDocumentType,
      ChartOfAccounts,
      ControllingArea,
      GLAccount,

      cast(ProfitCenter as fis_prctr preserving type) as ProfitCenter,
      cast(CostCenter as fis_kostl preserving type)   as CostCenter,
      Product,
      Segment,

      TransactionCurrency,

      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      AmountInTransactionCurrency,

      CompanyCodeCurrency,

      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmountInCompanyCodeCurrency,

      PostingDate,
      CreationDateTime,
      CreationDate                                    as ProcessedDate,

      _JournalEntry.ExchangeRateDate                  as ExchangeRateDate,
      _JournalEntry.ExchangeRateType                  as ExchangeRateType
}
