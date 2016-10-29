--------------------------------------------------------
--  File created - pirmdiena-februâris-22-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package REPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MIKUS"."REPORT" AS

PROCEDURE print_report(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE);


END report;

/
