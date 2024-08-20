@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Private view for Accounting documents'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@VDM.private: true
@Analytics.dataCategory: #CUBE
define view entity ZP_ACDOCA as select from I_JournalEntryItem as Item
  association [0..1] to I_JournalEntryStdVH as _JournalEntryStdVH on  $projection.CompanyCode         = _JournalEntryStdVH.CompanyCode 
                                                                  and $projection.FiscalYear          = _JournalEntryStdVH.FiscalYear
                                                                  and $projection.AccountingDocument  = _JournalEntryStdVH.AccountingDocument 
  association [0..1] to I_GLAccount as _GLAccountSTDVH            on  $projection.CompanyCode         = _GLAccountSTDVH.CompanyCode
                                                                  and $projection.GLAccount           = _GLAccountSTDVH.GLAccount 
{
  key Item.SourceLedger,
  key Item.CompanyCode,
  key Item.FiscalYear,
  key Item.AccountingDocument,
  key Item.LedgerGLLineItem,
  key Item.Ledger,
  Item.PostingDate,
  Item._JournalEntry.AccountingDocumentCreationDate as ProcessedDate,
  Item.GLAccount,
  Item.ControllingArea,
  Item.ProfitCenter,
  Item.CostCenter,
  Item.Product,
  Item.Segment,
  case Item._JournalEntry.ExchangeRateDate
    when '0000-00-00' then Item.PostingDate
    else Item._JournalEntry.ExchangeRateDate 
  end as ExchangeRateDate,
  Item._JournalEntry.ExchangeRateType as ExchangeRateType,
  cast ( cast( Item.AmountInCompanyCodeCurrency as abap.dec(23,11) ) / cast( Item.AmountInTransactionCurrency as abap.dec(23,11) ) as abap.dec(15,11) ) as JournalFXRate,
  @ObjectModel.foreignKey.association: '_TransactionCurrency'
  Item.TransactionCurrency,
  @Aggregation.default: #SUM
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
  Item.AmountInTransactionCurrency, //
  
  @ObjectModel.foreignKey.association: '_CompanyCodeCurrency'
  Item.CompanyCodeCurrency,
  @Aggregation.default: #SUM
  @Semantics: { amount : {currencyCode: 'CompanyCodeCurrency'} }
  Item.AmountInCompanyCodeCurrency,
  
    /* Associations */
  Item._CompanyCode,
  Item._CompanyCodeCurrency,
  Item._CompanyCodeText,
  Item._ControllingArea,
  Item._ControllingAreaText,
  Item._CostCenter,
  Item._CostCenterText,
  Item._CostCenterTxt,
  Item._CurrentProfitCenter,
  Item._FiscalYear,
  Item._GLAccountInCompanyCode,
  _GLAccountSTDVH,
  Item._GLAccountText,
  Item._JournalEntry,
  _JournalEntryStdVH,
  Item._Product,
  Item._ProductText,
  Item._ProfitCenter,
  Item._ProfitCenterText,
  Item._ProfitCenterTxt,
  Item._Segment,
  Item._SegmentText,
  Item._SourceLedger,
  Item._SourceLedgerText,
  Item._TransactionCurrency
}

where Item.AmountInTransactionCurrency is not initial and
      Item.SourceLedger = Item.Ledger;
