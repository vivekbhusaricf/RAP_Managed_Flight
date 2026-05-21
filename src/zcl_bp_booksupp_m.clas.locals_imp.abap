CLASS lhc_booksupp DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookSupp~calculateTotalPrice.

ENDCLASS.

CLASS lhc_booksupp IMPLEMENTATION.

  METHOD calculateTotalPrice.
    DATA: lt_travel TYPE TABLE OF zi_tera_travel_m WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    lt_travel = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ) .

    MODIFY ENTITIES OF zi_tera_travel_m in local mode
    ENTITY Travel
    EXECUTE recalcTotPrice
    FROM CORRESPONDING #( lt_travel ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
