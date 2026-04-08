@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view on Booking supplements interface view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_TERA_BOOKSUPPL_M
  as projection on ZI_TERA_BOOKSUPPL_M
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      @ObjectModel.text.element: [ 'SupplemenDesc' ]
      SupplementId,
      _SupplementText.Description as SupplemenDesc : localized,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Travel : redirected to ZC_TERA_TRAVEL_M,  
      _Booking : redirected to parent ZC_TERA_BOOKING_M,
      _Supplement,
      _SupplementText
}
