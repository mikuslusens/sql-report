--------------------------------------------------------
--  File created - pirmdiena-februâris-22-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body REPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MIKUS"."REPORT" AS

  l_maxwidth number := 100;
  
  PROCEDURE prc_print_cust_accounts(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE,
    p_party_id IN Parties.id_no%TYPE);
  
  PROCEDURE prc_print_acc_operations(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE,
    p_account_no IN Accounts.account_no%TYPE);
  
  FUNCTION test_date(d date) return varchar2;
  
  FUNCTION get_start_balance(p_start_date date, p_account_no Accounts.account_no%TYPE)
  RETURN number;
  
  FUNCTION get_end_balance(p_end_date date, p_account_no Accounts.account_no%TYPE)
  RETURN number;
  
  PROCEDURE print_report(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE)
    
  AS
  
    l_start_date          Operations.timestamp%TYPE             := p_start_date;
    l_end_date            Operations.timestamp%TYPE             := p_end_date;
    l_party_id            Parties.id_no%TYPE;
    l_test                varchar2(10);
    invalid_date          exception;
    
    CURSOR c_private IS
      SELECT id_no
      FROM Parties
      WHERE forename IS NOT NULL
      ORDER BY name;
      
    CURSOR c_company IS
      SELECT id_no
      FROM Parties
      WHERE forename IS NULL
      ORDER BY registration_no;
      
  BEGIN
  
    l_test := test_date(l_start_date);
    IF l_test = 'Invalid' THEN
      RAISE invalid_date;
    END IF;
    
    l_test := test_date(l_end_date);
    IF l_test = 'Invalid' THEN
      RAISE invalid_date;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(LPAD(RPAD('Customer report',LENGTH('Customer report') + (l_maxwidth - LENGTH('Customer report'))/2),l_maxwidth));
    DBMS_OUTPUT.PUT_LINE(RPAD('-',l_maxwidth,'-'));
    
    OPEN c_private;
      LOOP
        FETCH c_private INTO l_party_id;
        EXIT WHEN c_private%NOTFOUND;
        prc_print_cust_accounts(l_start_date, l_end_date, l_party_id);
        DBMS_OUTPUT.PUT_LINE(RPAD('-',l_maxwidth,'-'));
      END LOOP;
    CLOSE c_private;
    
    OPEN c_company;
      LOOP
        FETCH c_company INTO l_party_id;
        EXIT WHEN c_company%NOTFOUND;
        prc_print_cust_accounts(l_start_date, l_end_date, l_party_id);
        DBMS_OUTPUT.PUT_LINE(RPAD('-',l_maxwidth,'-'));
      END LOOP;
    CLOSE c_company;
    
    DBMS_OUTPUT.PUT_LINE(LPAD(RPAD('End of report',LENGTH('End of report') + (l_maxwidth - LENGTH('End of report'))/2),l_maxwidth));
    DBMS_OUTPUT.PUT_LINE(RPAD('-',l_maxwidth,'-'));
    
  EXCEPTION
  
  WHEN invalid_date THEN
    DBMS_OUTPUT.PUT_LINE('Invalid date, must be in format DD-MM-YYYY.');
    
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error encountered: '||SQLERRM);
  
  END print_report;
  
  PROCEDURE prc_print_cust_accounts(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE,
    p_party_id IN Parties.id_no%TYPE)
    
  AS
  
    l_start_date          Operations.timestamp%TYPE             := p_start_date;
    l_end_date            Operations.timestamp%TYPE             := p_end_date;
    l_party_id            Parties.id_no%TYPE                    := p_party_id;
    l_name                Parties.name%TYPE;
    l_forename            Parties.forename%TYPE;
    l_civil_reg_code      Parties.civil_reg_code%TYPE;
    l_registration_no     Parties.registration_no%TYPE;
    l_account_no          Accounts.account_no%TYPE;
    l_account_count       number;
    
    rec_address           Addresses%ROWTYPE;
    
    CURSOR c_cust_name IS
      SELECT name, forename, civil_reg_code, registration_no
      FROM Parties
      WHERE id_no = l_party_id;
      
    CURSOR c_account_no IS
      SELECT account_no FROM Accounts WHERE party_id = l_party_id;
      
  BEGIN
  
    SELECT  PARTY_ID ,
            NVL(STREET, 'N/A'),
            NVL(HOUSE, 'N/A'),
            NVL((TO_CHAR(FLOOR)), 'N/A') ,
            NVL(APARTMENT, 'N/A') ,
            NVL(POST_CODE, 'N/A'),
            NVL(CITY, 'N/A') ,
            NVL(COUNTRY, 'N/A') INTO rec_address FROM Addresses WHERE party_id = l_party_id;
  
    DBMS_OUTPUT.PUT_LINE(rpad((to_char(l_start_date, 'dd-mm-yyyy')||' - '||
                              to_char(l_end_date, 'dd-mm-yyyy')), l_maxwidth/10*3)||
                          lpad((rec_address.street||' '||
                              rec_address.house||'-'||
                              rec_address.apartment||', '||
                              rec_address.city||', '||
                              rec_address.post_code||', '||
                              rec_address.country), l_maxwidth/10*7));
    
--    DBMS_OUTPUT.PUT_LINE('');
    
    OPEN c_cust_name;
    FETCH c_cust_name INTO l_name, l_forename, l_civil_reg_code, l_registration_no;
    CLOSE c_cust_name;
    
    IF l_registration_no IS NULL THEN
      DBMS_OUTPUT.PUT_LINE(rpad((initcap(l_name)||' '||initcap(l_forename)), l_maxwidth/10*5)||lpad((to_char(l_civil_reg_code) ), l_maxwidth/10*5 ) );
    ELSE
      DBMS_OUTPUT.PUT_LINE(rpad(l_name, l_maxwidth/10*5)||lpad(l_registration_no, l_maxwidth/10*5)  );
    END IF;
  
   SELECT COUNT(*) INTO l_account_count FROM Accounts WHERE party_id = l_party_id;
   
  OPEN c_account_no;
   LOOP
    FETCH c_account_no INTO l_account_no;
      IF l_account_no IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Customer has no accounts!');
        EXIT;
      END IF;
      EXIT WHEN c_account_no%NOTFOUND;
      prc_print_acc_operations(l_start_date, l_end_date, l_account_no);
      IF c_account_no%ROWCOUNT != l_account_count THEN
        DBMS_OUTPUT.PUT_LINE(lpad((lpad('-',l_maxwidth/2,'-')), l_maxwidth));
      END IF;
    END LOOP;
  CLOSE c_account_no;
                            
  EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error encountered: '||SQLERRM);
  
  END prc_print_cust_accounts;
  
  PROCEDURE prc_print_acc_operations(
    p_start_date IN Operations.timestamp%TYPE,
    p_end_date IN Operations.timestamp%TYPE,
    p_account_no IN Accounts.account_no%TYPE)
  
  AS
  
    l_start_date          Operations.timestamp%TYPE             := p_start_date;
    l_end_date            Operations.timestamp%TYPE             := p_end_date;
    l_account_no          Accounts.account_no%TYPE              := p_account_no;
    l_start_acc_bal       Accounts.account_balance%TYPE;
    l_end_acc_bal         Accounts.account_balance%TYPE;
    l_timestamp           Operations.timestamp%TYPE;
    l_operation_type      Operations_log.operation_type%TYPE;
    l_forename            Parties.forename%TYPE;
    l_name                Parties.name%TYPE;
    l_amount              Operations.amount%TYPE;
    l_sender_account_no   Operations.sender_account_no%TYPE;
    l_account_type        Accounts.account_type%TYPE;
    l_credit              number;
    l_debit               number;
    
    CURSOR c_acc_operations IS
      SELECT    o.timestamp
                ,ol.operation_type
                ,p.forename
                ,p.name
                ,o.sender_account_no
                ,o.amount
      FROM      Accounts a, Parties p, Operations o, Operations_log ol
      WHERE     (trunc(o.timestamp, 'DAY') BETWEEN trunc(l_start_date, 'DAY') AND trunc(l_end_date, 'DAY')) AND
                o.operation_id = ol.operation_id AND
                o.account_no = a.account_no AND
                a.party_id = p.id_no AND
                o.account_no = l_account_no
      ORDER BY  o.timestamp;
    
    CURSOR c_acc_type IS
      SELECT    account_type FROM Accounts WHERE account_no = l_account_no;
      
    CURSOR c_acc_credit IS
      SELECT    SUM(o.amount)
      FROM      Operations o, Operations_log ol
      WHERE     (trunc(o.timestamp, 'DAY') BETWEEN trunc(l_start_date, 'DAY') AND trunc(l_end_date, 'DAY')) AND
                o.operation_id = ol.operation_id AND
                ol.operation_type = 'Incoming' AND
                o.account_no = l_account_no;
                
    CURSOR c_acc_debit IS
      SELECT    SUM(o.amount)
      FROM      Operations o, Operations_log ol
      WHERE     (trunc(o.timestamp, 'DAY') BETWEEN trunc(l_start_date, 'DAY') AND trunc(l_end_date, 'DAY')) AND
                o.operation_id = ol.operation_id AND
                ol.operation_type = 'Outgoing' AND
                o.account_no = l_account_no;
                
  BEGIN
    OPEN c_acc_type;
    FETCH c_acc_type INTO l_account_type;
    CLOSE c_acc_type;
    
    DBMS_OUTPUT.PUT_LINE('  '||'Account no: '||to_char(l_account_no)||' Type: '||to_char(l_account_type));
    l_start_acc_bal := get_start_balance(l_start_date, l_account_no);
    DBMS_OUTPUT.PUT_LINE(rpad('    '||'Balance on start date:', l_maxwidth/10*7)||lpad(to_char(l_start_acc_bal, '9990.99'), l_maxwidth/10*3));
    
    
    OPEN c_acc_operations;
      LOOP
        FETCH c_acc_operations INTO l_timestamp, l_operation_type, l_forename, l_name, l_sender_account_no, l_amount;
        EXIT WHEN c_acc_operations%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE  (rpad('      '||                              
                              ('Date: '||
                              to_char(l_timestamp, 'DD-MM-YYYY')||
                              ', Time: '||
                              to_char(l_timestamp, 'HH:MI:SS AM')||
                              ', Operation type: '||
                              l_operation_type), l_maxwidth/10*7)||
                              lpad(to_char(l_amount, 'S9999.99')  , l_maxwidth/10*3));

      END LOOP;
    CLOSE c_acc_operations;
    
    l_end_acc_bal := get_end_balance(l_end_date, l_account_no);
    DBMS_OUTPUT.PUT_LINE(rpad('    '||'Balance on period end date:', l_maxwidth/10*7)||lpad(to_char(l_end_acc_bal, '9990.99'), l_maxwidth/10*3));
    
    OPEN c_acc_credit;
    FETCH c_acc_credit INTO l_credit;
      IF l_credit IS NULL THEN
        l_credit := 0;
      END IF;
    CLOSE c_acc_credit;
    
    OPEN c_acc_debit;
    FETCH c_acc_debit INTO l_debit;
      IF l_debit IS NULL THEN
        l_debit := 0;
      END IF;
    CLOSE c_acc_debit;

    DBMS_OUTPUT.PUT_LINE(rpad('    '||'Credit/Debit:', l_maxwidth/10*7)||lpad((to_char(l_credit, 'S9990.99')||'/'||to_char(l_debit, 'S9990.99')), l_maxwidth/10*3));
 
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error encountered: '||SQLERRM);
  
  END prc_print_acc_operations;
  
  FUNCTION get_start_balance(p_start_date date, p_account_no Accounts.account_no%TYPE)
    RETURN number
  IS
    CURSOR c_get_sum IS
      SELECT SUM(o.amount)
      FROM Operations o
      WHERE o.account_no = p_account_no
      AND o.timestamp <= p_start_date;
    l_total number;
  
  BEGIN
    OPEN c_get_sum;
    FETCH c_get_sum INTO l_total;
      IF l_total IS NULL THEN
        l_total := 0;
      END IF;
    CLOSE c_get_sum;
    
    RETURN l_total;
  
  EXCEPTION
    WHEN OTHERS THEN
      IF c_get_sum%ISOPEN THEN CLOSE c_get_sum; END IF;
      DBMS_OUTPUT.PUT_LINE('Error encountered: '||sqlerrm);
      RETURN(NULL);
  END;
  
  FUNCTION get_end_balance(p_end_date date, p_account_no Accounts.account_no%TYPE)
    RETURN number
  IS
    CURSOR c_get_sum IS
      SELECT SUM(o.amount)
      FROM Operations o
      WHERE o.account_no = p_account_no
      AND o.timestamp <= p_end_date;
    l_total number;
  
  BEGIN
    OPEN c_get_sum;
    FETCH c_get_sum INTO l_total;
      IF l_total IS NULL THEN
        l_total := 0;
      END IF;
    CLOSE c_get_sum;
    
    RETURN l_total;
    
  EXCEPTION
    WHEN OTHERS THEN
      IF c_get_sum%ISOPEN THEN CLOSE c_get_sum; END IF;
      DBMS_OUTPUT.PUT_LINE('Error encountered: '||sqlerrm);
      RETURN(NULL);
  END;
  
  FUNCTION test_date(d date) return varchar2
  IS
  v_date date;
  BEGIN
  SELECT to_date(d,'dd-mm-yyyy') INTO v_date FROM dual;
  RETURN 'Valid';
  EXCEPTION
  WHEN OTHERS THEN RETURN 'Invalid';
  END;
    
  
END report;

/
