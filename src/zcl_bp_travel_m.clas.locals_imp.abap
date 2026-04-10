CLASS lsc_zi_tera_travel_m DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_tera_travel_m IMPLEMENTATION.

  METHOD save_modified.

    DATA: lt_travel_log   TYPE TABLE OF ztera_log_trav_m,
          lt_travel_log_c TYPE TABLE OF ztera_log_trav_m.

    IF create-travel IS NOT INITIAL.
      lt_travel_log = CORRESPONDING #( create-travel ).

      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log>).

        <fs_travel_log>-changing_operation = 'CREATE'.
        GET TIME STAMP FIELD <fs_travel_log>-created_at.

        READ TABLE create-travel ASSIGNING FIELD-SYMBOL(<fs_travel>)
                    WITH TABLE KEY entity COMPONENTS TravelId = <fs_travel_log>-travel_id.

        IF sy-subrc IS INITIAL.
          IF <fs_travel>-%control-BookingFee = cl_abap_behv=>flag_changed.
            <fs_travel_log>-changed_field_name = 'Booking Fee'.
            <fs_travel_log>-changed_value = <fs_travel>-BookingFee.
            TRY.
                <fs_travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).
              CATCH  cx_uuid_error.

            ENDTRY.

            APPEND <fs_travel_log> TO lt_travel_log_c.
          ENDIF.
          IF <fs_travel>-%control-BookingFee = cl_abap_behv=>flag_changed.
            <fs_travel_log>-changed_field_name = 'OverallStatus'.
            <fs_travel_log>-changed_value = <fs_travel>-OverallStatus.
            TRY.
                <fs_travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).
              CATCH  cx_uuid_error.
            ENDTRY.
            APPEND <fs_travel_log> TO lt_travel_log_c.
          ENDIF.
        ENDIF.



      ENDLOOP.

      insert ztera_log_trav_m from TABLE lt_travel_log_c.

    ENDIF.

    if update-travel is not initial.

    endif.

    if delete-travel is not initial.

    endif.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS recalctotprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotprice.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecustomer.
    METHODS validatebookingfee FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatebookingfee.

    METHODS validatecurrencycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecurrencycode.

    METHODS validatedates FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedates.

    METHODS validatestatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatestatus.
    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

*  METHOD get_instance_authorizations.
*  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(lt_entities) = entities.
    DELETE lt_entities WHERE TravelId IS NOT INITIAL.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*      IGNORE_BUFFER     =
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines(  lt_entities ) )
*      SUBOBJECT         =
*      TOYEAR            =
          IMPORTING
            number            = DATA(lv_latest_num)
            returncode        = DATA(lv_code)
            returned_quantity = DATA(lv_qty)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lo_error).

        LOOP AT lt_entities INTO DATA(ls_entities).
          APPEND VALUE #( %cid = ls_entities-%cid
                          %key = ls_entities-%key  )
                 TO failed-travel.

          APPEND VALUE #( %cid = ls_entities-%cid
                          %key = ls_entities-%key
                          %msg = lo_error )
                 TO reported-travel.
        ENDLOOP.
        EXIT.
    ENDTRY.
    ASSERT lv_qty = lines( lt_entities ).
    DATA: lt_tera_travel_m TYPE TABLE FOR MAPPED EARLY zi_tera_travel_m,
          ls_tera_travel_m LIKE LINE OF lt_tera_travel_m.
    DATA(lv_curr_num) = lv_latest_num - 1.
    LOOP AT lt_entities INTO ls_entities.
      lv_curr_num = lv_curr_num + 1.
      ls_tera_travel_m = VALUE #( %cid = ls_entities-%cid
                                  TravelId = lv_curr_num    ).
      APPEND ls_tera_travel_m TO mapped-travel.

    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA: lv_max_booking TYPE /dmo/booking_id.

    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(lt_link_data).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                               GROUP BY <ls_group_entity>-TravelId.

      lv_max_booking = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
                                 FOR ls_link IN lt_link_data USING KEY entity
                                    WHERE ( source-TravelId = <ls_group_entity>-TravelId )
                                 NEXT lv_max = COND /dmo/booking_id( WHEN lv_max < ls_link-target-BookingId
                                                                     THEN ls_link-target-BookingId
                                                                     ELSE lv_max ) ).

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>)
                       USING KEY entity
                       WHERE TravelId = <ls_group_entity>-TravelId.

        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).
          IF <ls_booking>-BookingId IS INITIAL.
            lv_max_booking += 10.
            APPEND CORRESPONDING #( <ls_booking> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<ls_new_map_book>).
            <ls_new_map_book>-BookingId = lv_max_booking.
          ENDIF.

        ENDLOOP.
      ENDLOOP.


    ENDLOOP.

  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF zc_tera_travel_m
    ENTITY zc_tera_travel_m
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                        OverallStatus = 'A'   ) ).

    READ ENTITIES OF zc_tera_travel_m
    ENTITY zc_tera_travel_m
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_results).

    result = VALUE #( FOR ls_result IN lt_results ( %tky = ls_result-%tky
                                                    %param = CORRESPONDING #( ls_result ) ) ).


  ENDMETHOD.

  METHOD recalcTotPrice.
  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF zc_tera_travel_m
    ENTITY zc_tera_travel_m
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                        OverallStatus = 'X'   ) ).

    READ ENTITIES OF zc_tera_travel_m
    ENTITY zc_tera_travel_m
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_results).

    result = VALUE #( FOR ls_result IN lt_results ( %tky = ls_result-%tky
                                                    %param = CORRESPONDING #( ls_result ) ) ).

  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    result = VALUE #( FOR ls_travel IN lt_travel ( %tky = ls_travel-%tky
                                                   %features-%action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                                                            THEN if_abap_behv=>fc-o-disabled
                                                                                            ELSE if_abap_behv=>fc-o-enabled )
                                                   %features-%action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                                            THEN if_abap_behv=>fc-o-disabled
                                                                                            ELSE if_abap_behv=>fc-o-enabled )
                                                   %features-%assoc-_Booking      = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                                            THEN if_abap_behv=>fc-o-disabled
                                                                                            ELSE if_abap_behv=>fc-o-enabled )


                                                )
                    ).
  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITY IN LOCAL MODE zi_tera_travel_m
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    DATA: lt_cust TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    lt_cust = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId ).
    DELETE lt_cust WHERE customer_id IS INITIAL.

    SELECT FROM /dmo/customer FIELDS customer_id
       FOR ALL ENTRIES IN @lt_cust
       WHERE customer_id = @lt_cust-customer_id
       INTO TABLE @DATA(lt_customers_db).

    IF sy-subrc IS INITIAL.


    ENDIF.

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).
      IF <fs_travel>-CustomerId IS INITIAL
          OR NOT line_exists( lt_customers_db[ customer_id = <fs_travel>-CustomerId ]  ).

        APPEND VALUE #( %tky = <fs_travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <fs_travel>-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid      = /dmo/cm_flight_messages=>customer_unkown
                                    customer_id = <fs_travel>-CustomerId
                                    severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerId = if_abap_behv=>mk-on
                     )
            TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateBookingFee.
  ENDMETHOD.

  METHOD validateCurrencyCode.
  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BeginDate EndDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(ls_travel).
      IF ls_travel-EndDate < ls_travel-BeginDate.
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = ls_travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                textid = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                severity = if_abap_behv_message=>severity-error
                                begin_date = ls_travel-BeginDate
                                end_date = ls_travel-EndDate )
                        %element-Begindate = if_abap_behv=>mk-on
                        %element-Enddate = if_abap_behv=>mk-on
                      ) TO reported-travel.
        " begin date must be in the future
      ELSEIF ls_travel-BeginDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = ls_travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                textid = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                severity = if_abap_behv_message=>severity-error
                                begin_date = ls_travel-BeginDate
                                )
                        %element-Begindate = if_abap_behv=>mk-on
                        %element-Enddate = if_abap_behv=>mk-on
                      ) TO reported-travel.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF zi_tera_travel_m IN LOCAL MODE
         ENTITY Travel
         FIELDS ( OverallStatus )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(ls_travel).
      CASE ls_travel-OverallStatus.
        WHEN 'O'.
        WHEN 'X'.
        WHEN 'A'.

        WHEN OTHERS.
          APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

          APPEND VALUE #( %tky = ls_travel-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>status_invalid
                                     severity = if_abap_behv_message=>severity-error
                                     status = ls_travel-OverallStatus
                                     )
                          %element-OverallStatus = if_abap_behv=>mk-on

                        ) TO reported-travel.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
