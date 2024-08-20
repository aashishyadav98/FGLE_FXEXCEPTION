@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Consumption View - FX Exception Report'
define view entity ZC_FXEXCEPTION_RO
  as select from ZI_FXVARIANCE
{
  key SourceLedger,
  key CompanyCode,
  key FiscalYear,
  key AccountingDocument,
  key LedgerGLLineItem,
  PostingDate,
  ProcessedDate,
  GLAccount,
  ControllingArea,
  ProfitCenter,
  CostCenter,
  Product,
  Segment,
  ExchangeRateDate,
  ExchangeRateType,
  JournalFXRate,
  TransactionCurrency,
  AmountInTransactionCurrency,
  CompanyCodeCurrency,
  AmountInCompanyCodeCurrency,
  EODExchangeRate,
  VarianceAmount,
  ExchangeRateVariance,
  case 
    when ExchangeRateVariance = 0 then 0 -- no change unknown
    when ExchangeRateVariance > 0 and ExchangeRateVariance <= 2.5  then 3 --green color
    when ExchangeRateVariance > 2.5 and ExchangeRateVariance <= 5  then 2 --yellow color
    when ExchangeRateVariance > 5 then 1 -- red color
  end as VarianceCriticality,
  _CompanyCode,
  _CompanyCodeCurrency,
  _CompanyCodeText,
  _ControllingArea,
  _ControllingAreaText,
  _CostCenter,
  _CostCenterText,
  _CostCenterTxt,
  _CurrentProfitCenter,
  _FiscalYear,
  _GLAccountInCompanyCode,
  _GLAccountSTDVH,
  _GLAccountText,
  _JournalEntry,
  _JournalEntryStdVH,
  _Product,
  _ProductText,
  _ProfitCenter,
  _ProfitCenterText,
  _ProfitCenterTxt,
  _Segment,
  _SegmentText,
  _SourceLedger,
  _SourceLedgerText,
  _TransactionCurrency,
  _ExtendedExchangeRate
  
}
