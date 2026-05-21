CLASS zcl_read_ent_practice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_read_ent_practice IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
*sort form read

*    READ ENTITY zi_tera_travel_m
*     FROM VALUE #( ( %key-TravelId = '0000004122'
*                     %control = VALUE #( AgencyId    = if_abap_behv=>mk-on
*                                         CUSTOMERID  = if_abap_behv=>mk-on
*                                         BEGINDATE   = if_abap_behv=>mk-on
*                                         )
*
*          )
*                    )
*     RESULT DATA(lt_result_short)
*     FAILED DATA(lt_failed_sort).
*
*    IF lt_failed_sort IS NOT INITIAL.
*      out->write( 'Read failed' ).
*
*    ELSE.
*      out->write( lt_result_short ).
*    ENDIF.

*    READ ENTITY zi_tera_travel_m
*     by \_Booking
*     ALL FIELDS
*     WITH VALUE #( ( %key-TravelId = '0000004122'   )
*                    ( %key-TravelId = '0000004136' )
*                    )
*     RESULT DATA(lt_result_short)
*     FAILED DATA(lt_failed_sort).
*
*    IF lt_failed_sort IS NOT INITIAL.
*      out->write( 'Read failed' ).
*
*    ELSE.
*      out->write( lt_result_short ).
*    ENDIF.


*    READ ENTITIES OF zi_tera_travel_m
*
*    ENTITY zi_tera_travel_m
*    ALL FIELDS
*    WITH VALUE #( ( %key-TravelId = '0000004122'   )
*                    ( %key-TravelId = '0000004133' )
*                    )
*     RESULT DATA(lt_result_travel)
*
*    ENTITY yi_booking_tech_m
*    ALL FIELDS WITH VALUE #( ( %key-TravelId = '0000004122'
*                               %key-BookingId = '0020'
*                                ) )
*     RESULT DATA(lt_result_book)
*
*     FAILED DATA(lt_failed_sort).
*
*    IF lt_failed_sort IS NOT INITIAL.
*      out->write( 'Read failed' ).
*
*    ELSE.
*      out->write( lt_result_travel ).
*      out->write( lt_result_book ).
*    ENDIF.

    DATA: it_optab          TYPE abp_behv_retrievals_tab,
          it_travel         TYPE TABLE FOR READ IMPORT zi_tera_travel_m,
          it_travel_result  TYPE TABLE FOR READ RESULT  zi_tera_travel_m,
          it_booking        TYPE TABLE FOR READ IMPORT zi_tera_travel_m\_Booking,
          it_booking_result TYPE TABLE FOR READ RESULT zi_tera_travel_m\_Booking.

    it_travel = VALUE #( ( %key-TravelId = '0000004122'
                          %control = VALUE #( AgencyId    = if_abap_behv=>mk-on
                                             customerid  = if_abap_behv=>mk-on
                                             begindate   = if_abap_behv=>mk-on
                                          ) ) ).

    it_booking = VALUE #( ( %key-TravelId = '0000004122'
                            %control = VALUE #(
                               BookingDate = if_abap_behv=>mk-on
                                BookingStatus = if_abap_behv=>mk-on
                                BookingId =  if_abap_behv=>mk-on
                            )    ) ).

    it_optab = VALUE #( ( op = if_abap_behv=>op-r-read
                          entity_name = 'zi_tera_travel_m'
                          instances = REF #( it_travel )
                          results  = REF #( it_travel_result )  )
                        ( op = if_abap_behv=>op-r-read_ba
                          entity_name = 'zi_tera_travel_m'
                          sub_name  = '_BOOKING'
                          instances = REF #( it_booking )
                          results  = REF #( it_booking_result )
                            ) ).

    READ ENTITIES
       OPERATIONS it_optab
         FAILED DATA(lt_failed_dy).

    IF lt_failed_dy IS NOT INITIAL.
      out->write( 'Read failed' ).

    ELSE.
      out->write( it_travel_result ).
      out->write( it_booking_result ).
    ENDIF.


  ENDMETHOD.
ENDCLASS.
