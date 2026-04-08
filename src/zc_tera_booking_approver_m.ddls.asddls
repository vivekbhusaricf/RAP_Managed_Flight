@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view - Bookings Approver'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_TERA_BOOKING_APPROVER_M
  as projection on ZI_TERA_BOOKING_M
{

  key TravelId,
  key BookingId,
      BookingDate,
      @ObjectModel.text.element: ['CustomerName']
      CustomerId,
      _Customer.LastName         as CustomerName,
      @ObjectModel.text.element: ['CarrierName']
      CarrierId,
      _Carrier.Name              as CarrierName,
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      @ObjectModel.text.element: ['BookingStatusText']
      BookingStatus,
      _Booking_Status._Text.Text as BookingStatusText : localized,
      LastChangedAt,
      /* Associations */
      _Bookingsuppl,
      _Booking_Status,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent ZC_TERA_APPROVER_M
}
