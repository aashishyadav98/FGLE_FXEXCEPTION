@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'FX Variance'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@Analytics.dataCategory: #CUBE
define view entity ZI_FXVARIANCE as select from ZP_ACDOCA
association [0..1] to ZI_ExtendedFXRate as _ExtendedExchangeRate on $projection.ExchangeRateType    = _ExtendedExchangeRate.ExchangeRateType and
                                                                    $projection.ExchangeRateDate    = _ExtendedExchangeRate.ExchangeRateValidFrom and
                                                                    $projection.TransactionCurrency = _ExtendedExchangeRate.SourceCurrency and
                                                                    $projection.CompanyCodeCurrency = _ExtendedExchangeRate.TargetCurrency
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
  
  cast( round( JournalFXRate, 4 ) as abap.dec(10,4) ) as JournalFXRate,
  /* Dimension */
  TransactionCurrency,
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  @Aggregation.default: #SUM
  AmountInTransactionCurrency,
  CompanyCodeCurrency,
  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  @Aggregation.default: #SUM
  AmountInCompanyCodeCurrency,
  
  cast( round( _ExtendedExchangeRate.MktDataExchangeRate, 4 ) as abap.dec( 10, 4 ) ) as EODExchangeRate,
  @Aggregation.default: #SUM
  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  case _ExtendedExchangeRate.MktDataExchangeRate
  when 0  then 0
  else cast ( 
          cast( 
              ( cast( 
                      AmountInTransactionCurrency as abap.dec( 22, 2 ) 
                    ) 
                * _ExtendedExchangeRate.MktDataExchangeRate
               ) as abap.dec(23,11) 
            ) - cast( 
                      AmountInCompanyCodeCurrency as abap.dec( 22 , 2) 
                    ) 
            as abap.dec(22,2) )        
  end as VarianceAmount,
  
  case _ExtendedExchangeRate.MktDataExchangeRate
    when 0  then 0
    else cast( round( abs( JournalFXRate / _ExtendedExchangeRate.MktDataExchangeRate  - 1 ) * 100  , 1 ) as abap.dec(4,1) )
  end as ExchangeRateVariance,
  
  /* Associations */
  ZP_ACDOCA._CompanyCode,
  ZP_ACDOCA._CompanyCodeCurrency,
  ZP_ACDOCA._CompanyCodeText,
  ZP_ACDOCA._ControllingArea,
  ZP_ACDOCA._ControllingAreaText,
  ZP_ACDOCA._CostCenter,
  ZP_ACDOCA._CostCenterText,
  ZP_ACDOCA._CostCenterTxt,
  ZP_ACDOCA._CurrentProfitCenter,
  ZP_ACDOCA._FiscalYear,
  ZP_ACDOCA._GLAccountInCompanyCode,
  ZP_ACDOCA._GLAccountSTDVH,
  ZP_ACDOCA._GLAccountText,
  ZP_ACDOCA._JournalEntry,
  ZP_ACDOCA._JournalEntryStdVH,
  ZP_ACDOCA._Product,
  ZP_ACDOCA._ProductText,
  ZP_ACDOCA._ProfitCenter,
  ZP_ACDOCA._ProfitCenterText,
  ZP_ACDOCA._ProfitCenterTxt,
  ZP_ACDOCA._Segment,
  ZP_ACDOCA._SegmentText,
  ZP_ACDOCA._SourceLedger,
  ZP_ACDOCA._SourceLedgerText,
  ZP_ACDOCA._TransactionCurrency,
  _ExtendedExchangeRate
}
