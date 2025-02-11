@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@Consumption.ranked: true

@EndUserText.label: 'Exchange Rate Type'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.modelingPattern: #VALUE_HELP_PROVIDER
@ObjectModel.representativeKey: 'ExchangeRateType'
@ObjectModel.supportedCapabilities: [ #VALUE_HELP_PROVIDER, #SEARCHABLE_ENTITY ]
@ObjectModel.usageType: { sizeCategory: #XXL, dataClass: #TRANSACTIONAL, serviceQuality: #X }

@Search.searchable: true

@VDM.viewType: #BASIC

define view entity ZI_ExchangeRateTypeVH
  as select from    tcurv

    left outer join tcurw on tcurw.kurst = tcurv.kurst and tcurw.spras = $session.system_language

{
      @ObjectModel.text.element: [ 'ExchangeRateTypeName' ]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Search.ranking: #HIGH
  key tcurv.kurst                                         as ExchangeRateType,

      @Semantics.text: true
      tcurw.curvw                                         as ExchangeRateTypeName,

      cast(tcurv.bwaer as fis_bwaer_curv preserving type) as ReferenceCurrency
}
