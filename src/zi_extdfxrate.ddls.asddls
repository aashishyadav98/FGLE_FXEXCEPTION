@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extended Foreign Exchange Rate'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZI_ExtdFXRate as select from /ba1/f4_fxrates
{
  key mdcode as Mdcode,
  key ratetype as Ratetype,
  key from_ccy as FromCcy,
  key to_ccy as ToCcy,
  key conv_type as ConvType,
  key valid_date as ValidDate,
  key sys_time as SysTime,
  status as Status,
  rel_status as RelStatus,
  fx_rate as FxRate,
  uname as Uname
}
