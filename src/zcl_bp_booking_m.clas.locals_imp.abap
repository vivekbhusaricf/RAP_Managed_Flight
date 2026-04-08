CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsuppl.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.
    DATA: lv_max_booking_suppl TYPE /dmo/supplement_id.

    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
    ENTITY Booking BY \_BookingSuppl
    FROM CORRESPONDING #( entities )
    LINK DATA(lt_link_booking_suppl).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                               GROUP BY <ls_group_entity>-%tky.

      " Get highest assigned bookingsupplement_id from booking belonging to booking
      lv_max_booking_suppl = REDUCE #( INIT lv_max = CONV /dmo/supplement_id( '0' )
                                 FOR ls_link IN lt_link_booking_suppl USING KEY entity
                                    WHERE ( source-TravelId = <ls_group_entity>-TravelId
                                           AND source-BookingId = <ls_group_entity>-BookingId )
                                 NEXT lv_max = COND /dmo/booking_id( WHEN lv_max < ls_link-target-BookingSupplementId
                                                                     THEN ls_link-target-BookingSupplementId
                                                                     ELSE lv_max ) ).

      " Get highest assigned bookingsupplement_id from incoming entities
      lv_max_booking_suppl = REDUCE #(  INIT lv_max = lv_max_booking_suppl
                                        FOR entity IN entities USING KEY entity
                                            WHERE ( TravelId  = <ls_group_entity>-TravelId AND
                                                    BookingId = <ls_group_entity>-BookingId )
                                        FOR target IN entity-%target
                                        NEXT lv_max = COND /dmo/supplement_id(  WHEN target-BookingSupplementId > lv_max
                                                                                THEN target-BookingSupplementId
                                                                                ELSE lv_max     )
                                         ).
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>)
                       USING KEY entity
                       WHERE TravelId = <ls_group_entity>-TravelId
                             AND BookingId = <ls_group_entity>-BookingId.

        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_suppl>).
          APPEND CORRESPONDING #( <ls_booking_suppl> ) TO mapped-booksupp ASSIGNING FIELD-SYMBOL(<ls_new_book_suppl>).
          IF <ls_booking_suppl>-BookingSupplementId IS INITIAL.
            lv_max_booking_suppl += 1.

            <ls_new_book_suppl>-BookingSupplementId = lv_max_booking_suppl.
          ENDIF.

        ENDLOOP.
      ENDLOOP.


    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
       ENTITY Travel BY \_Booking
       FIELDS ( TravelId BookingStatus )
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_bookings).

    result = VALUE #( FOR ls_booking IN lt_bookings ( %tky = ls_booking-%tky
                                                      %features-%assoc-_BookingSuppl = COND #( WHEN ls_booking-BookingStatus = 'X'
                                                                                            THEN if_abap_behv=>fc-o-disabled
                                                                                            ELSE if_abap_behv=>fc-o-enabled )


                                                )
                    ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
