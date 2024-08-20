@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extended Foreign Exchange Rate'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@Analytics.dataCategory: #DIMENSION
define view entity ZI_ExtendedFXRate
  as select from /ba1/f4_fxrates as a
    inner join   ZP_EXTDFXRATE   as b on  a.mdcode     = b.Mdcode
                                      and a.ratetype   = b.Ratetype
                                      and a.from_ccy   = b.FromCcy
                                      and a.to_ccy     = b.ToCcy
                                      and a.conv_type  = b.ConvType
                                      and a.valid_date = b.ValidDate
                                      and a.sys_time   = b.LastestTime
  association [0..*] to I_ExchangeRateTypeText as _Text             on $projection.ExchangeRateType = _Text.ExchangeRateType
  association [0..1] to I_ExchangeRateType     as _ExchangeRateType on $projection.ExchangeRateType = _ExchangeRateType.ExchangeRateType
  association [0..1] to I_Currency             as _SourceCurrency   on $projection.SourceCurrency = _SourceCurrency.Currency
  association [0..1] to I_Currency             as _TargetCurrency   on $projection.TargetCurrency = _TargetCurrency.Currency
{
      
      @ObjectModel.text.association: '_Text'
      @ObjectModel.foreignKey.association: '_ExchangeRateType'
  key a.ratetype   as ExchangeRateType,
      @ObjectModel.foreignKey.association: '_SourceCurrency'
  key a.from_ccy   as SourceCurrency,
      @ObjectModel.foreignKey.association: '_TargetCurrency'
  key a.to_ccy     as TargetCurrency,
  key cast(substring(a.valid_date, 1, 8) as abap.dats) as ExchangeRateValidFrom,
      a.mdcode     as MarketDataArea,
      a.conv_type  as CurrencyConversionCategory,
      a.sys_time   as LastChangeDateTime,
      a.fx_rate    as MktDataExchangeRate,
      a.uname      as LastChangedByUser,

      //Association
      _Text,
      _ExchangeRateType,
      _SourceCurrency,
      _TargetCurrency
}

where a.mdcode    = 'MDCO' and
      a.conv_type = '0' and
      a.fx_rate is not initial;
