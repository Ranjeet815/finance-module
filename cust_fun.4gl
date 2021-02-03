SCHEMA testdb

DEFINE  dr_dsgrec RECORD
      customercode LIKE customer.customercode,
      customername LIKE customer.customername,
     address1 LIKE customer.address1,
     address2 LIKE customer.address2,
     pincode LIKE customer.pincode
    
    END RECORD,
    work_dsgrec RECORD
      customercode LIKE customer.customercode,
      customername LIKE customer.customername,
     address1 LIKE customer.address1,
     address2 LIKE customer.address2,
     pincode LIKE customer.pincode
    END RECORD

FUNCTION query_cust()
  DEFINE cont_ok         SMALLINT,
         dsg_cnt    SMALLINT,
         where_clause STRING

  MESSAGE "Enter search customer criteria"
  LET cont_ok = FALSE
  LET int_flag = FALSE
  
  CONSTRUCT BY NAME where_clause ON customer.*
                             
  IF (int_flag) = TRUE THEN
    LET int_flag=FALSE
    CLEAR FORM
    LET cont_ok = FALSE
    MESSAGE "Canceled by user."
  ELSE      
    CALL get_dsg_cnt_cust(where_clause)
           RETURNING dsg_cnt
    IF (dsg_cnt > 0) THEN
       MESSAGE dsg_cnt using "<<<<", " rows found."
       CALL cust_select(where_clause)
          RETURNING cont_ok
    ELSE
       MESSAGE "No rows found."
       LET cont_ok = FALSE    
    END IF
  END IF
 
    IF (cont_ok) THEN
      CALL display_cust()
    END IF
    
    RETURN cont_ok
 
END FUNCTION

FUNCTION get_dsg_cnt_cust(p_where_clause)
  DEFINE p_where_clause   STRING,
         sql_text         STRING,
         dsg_cnt        SMALLINT
         
  
  LET sql_text = "SELECT COUNT(*) FROM customer WHERE " || p_where_clause CLIPPED
  
  WHENEVER ERROR CONTINUE
  PREPARE dsg_cnt_stmt FROM sql_text
  EXECUTE dsg_cnt_stmt INTO dsg_cnt
  FREE dsg_cnt_stmt
  WHENEVER ERROR STOP
  
  IF SQLCA.SQLCODE <> 0 THEN
    LET dsg_cnt = 0
    ERROR SQLERRMESSAGE
  END IF
  
  RETURN dsg_cnt
  
END FUNCTION
  
FUNCTION cust_select(p_where_clause) 
  DEFINE p_where_clause  STRING,
         sql_text        STRING,
         fetch_ok        SMALLINT
 
  LET sql_text = "SELECT * FROM customer WHERE "  ||
        p_where_clause clipped 
  

  DECLARE dsg_curs SCROLL CURSOR WITH HOLD FROM sql_text  
  
  OPEN dsg_curs
  CALL fetch_cust(1)        --fetch the first row
     RETURNING fetch_ok
  IF NOT (fetch_ok) THEN
     MESSAGE "no rows in table."   -- someone deleted the rows after we checked the count
  END IF
      
  RETURN fetch_ok
 
END FUNCTION
 


FUNCTION fetch_cust (p_fetch_flag)
  DEFINE p_fetch_flag SMALLINT,
         fetch_ok     SMALLINT
         
   LET fetch_ok = TRUE
   WHENEVER ERROR CONTINUE
   IF p_fetch_flag = 1 THEN
     FETCH NEXT dsg_curs
       INTO dr_dsgrec.*
   ELSE
     FETCH PREVIOUS dsg_curs
       INTO dr_dsgrec.*
   END IF
   
  CASE
  WHEN (SQLCA.SQLCODE = 0)
      LET fetch_ok = TRUE
  WHEN (SQLCA.SQLCODE = NOTFOUND)
     LET fetch_ok = FALSE
  WHEN (SQLCA.SQLCODE < 0)
     LET fetch_ok = FALSE
     MESSAGE " Error ", SQLCA.SQLCODE USING "<<<<"
  END CASE
  
  RETURN fetch_ok
  
END FUNCTION



FUNCTION fetch_rel_cust(p_fetch_flag)
  DEFINE p_fetch_flag SMALLINT,
         fetch_ok     SMALLINT
   
  MESSAGE " "       
  CALL fetch_cust(p_fetch_flag)
    RETURNING fetch_ok
    
  IF (fetch_ok) THEN
    CALL display_cust()
  ELSE
    IF (p_fetch_flag = 1) THEN
      MESSAGE "End of list"
    ELSE
      MESSAGE "Beginning of list"
    END IF
  END IF
    
 END FUNCTION
 




 FUNCTION display_cust()
  DISPLAY BY NAME dr_dsgrec.*
END FUNCTION
 


 
 FUNCTION inpupd_cust(au_flag)  
  DEFINE au_flag  CHAR(1),
         cont_ok  SMALLINT
        
  LET cont_ok = TRUE 
  INITIALIZE work_dsgrec.* TO NULL      
  
  IF (au_flag = "A") THEN  
    MESSAGE "Add a new customer "
    LET dr_dsgrec.* = work_dsgrec.*   -- this is an add, set program record to null 
  ELSE
    MESSAGE "Update customer"
    LET work_dsgrec.* = dr_dsgrec.*   -- this is an update, save original 
  END IF
   
  LET int_flag = FALSE
  
  INPUT BY NAME dr_dsgrec.* WITHOUT DEFAULTS ATTRIBUTE (UNBUFFERED) 
  
  BEFORE FIELD customercode
      IF au_flag = "U" THEN
    NEXT FIELD customername
    END IF
  
   ON CHANGE customercode   
      IF au_flag = "A" THEN
         WHENEVER ERROR CONTINUE 
         SELECT customercode, 
               customername, 
               address1,
              address2,
             pincode
            
            INTO dr_dsgrec.*
            FROM customer 
            WHERE customercode = dr_dsgrec.customercode
          WHENEVER ERROR STOP     
          IF (SQLCA.SQLCODE = 0) THEN
             ERROR " customer id number already in database."
             LET cont_ok = FALSE
             CALL display_cust()
             EXIT INPUT
          END IF
      END IF      
      
ON CHANGE customername
     IF (dr_dsgrec.customername IS NULL) THEN
        ERROR "You must enter a customer name."
        NEXT FIELD customername
     END IF 
    
  END INPUT
 
  IF (int_flag) THEN
    LET int_flag = FALSE
    LET cont_ok = FALSE
    MESSAGE "Operation cancelled by user." 
    LET dr_dsgrec.* = work_dsgrec.* 
  END IF
       
  RETURN cont_ok
  
END FUNCTION


FUNCTION insert_cust()

 WHENEVER ERROR CONTINUE   
 INSERT INTO customer(customercode, 
                       customername, 
                       address1,
                      address2,
                      pincode)  
     VALUES (dr_dsgrec.*)
  WHENEVER ERROR STOP
  
  IF SQLCA.SQLCODE = 0 THEN
     MESSAGE "Row added"
  ELSE
     ERROR SQLERRMESSAGE
  END IF
     
                       
END FUNCTION

FUNCTION update_cust()
  DEFINE l_dsgrec RECORD
     customercode LIKE customer.customercode,
      customername LIKE customer.customername,
     address1 LIKE customer.address1,
     address2 LIKE customer.address2,
     pincode LIKE customer.pincode

    END RECORD,
    matches INTEGER,
    cont_ok INTEGER
    
  LET matches = FALSE
  LET cont_ok = FALSE
       
  BEGIN WORK
  WHENEVER ERROR CONTINUE
  SELECT customercode,          -- reselect the row to lock it
       customername, 
       address1,
      address2,
     pincode
    
     INTO l_dsgrec.* FROM customer 
     WHERE customercode = dr_dsgrec.customercode -- FOR UPDATE
   WHENEVER ERROR STOP 
       
   IF SQLCA.SQLCODE = NOTFOUND THEN       
      ERROR "supplier has been deleted"
      LET cont_ok = FALSE
    ELSE                      -- compare records
      IF l_dsgrec.* = work_dsgrec.* THEN
        LET matches = TRUE      
      ELSE
        LET matches = FALSE
      END IF
    
      IF matches = TRUE THEN     
        WHENEVER ERROR CONTINUE
        UPDATE customer SET  customername = dr_dsgrec.customername,
                       customername = dr_dsgrec.customername,
                       address1 = dr_dsgrec.address1,
                        address2 = dr_dsgrec.address2,
                        pincode = dr_dsgrec.pincode
                       
                      WHERE customercode = dr_dsgrec.customercode
        WHENEVER ERROR STOP  
        IF SQLCA.SQLCODE = 0 THEN
            LET cont_ok = TRUE
            MESSAGE "Row updated"
        ELSE
           LET cont_ok = FALSE
           ERROR SQLERRMESSAGE
        END IF 
     ELSE
       LET cont_ok = FALSE
       LET dr_dsgrec.* = l_dsgrec.*      -- replace with latest values retrieved
       DISPLAY BY NAME dr_dsgrec.*         -- remove this for UNBUFFERED
       MESSAGE "Row updated by another user."
     END IF
  END IF
     
  IF cont_ok = TRUE
    THEN COMMIT WORK
  ELSE
      ROLLBACK WORK
  END IF
                    
END FUNCTION

FUNCTION delete_cust()
  DEFINE del_ok SMALLINT
  
    WHENEVER ERROR CONTINUE
    DELETE FROM customer WHERE customercode = dr_dsgrec.customercode
    WHENEVER ERROR STOP
    IF SQLCA.SQLCODE = 0 THEN
       MESSAGE "Row deleted"
       INITIALIZE dr_dsgrec.* TO NULL
       DISPLAY BY NAME dr_dsgrec.* 
    ELSE
      ERROR SQLERRMESSAGE
    END IF 
 
 END FUNCTION   

FUNCTION delete_check_cust()
  DEFINE del_ok SMALLINT,
         del_count SMALLINT
  
  LET del_ok = FALSE
    
  WHENEVER ERROR CONTINUE
  SELECT COUNT(*) INTO del_count FROM ORDERS 
    WHERE orders.customercode = dr_dsgrec.customercode
  WHENEVER ERROR STOP
  
  IF del_count > 0 THEN
    MESSAGE "customer has orders and cannot be deleted"
    LET del_ok = FALSE
  ELSE
    MENU  "Delete" ATTRIBUTE ( STYLE="dialog", COMMENT="Delete the row?" )
    COMMAND "Yes"
      LET del_ok = TRUE
      EXIT MENU
    COMMAND "No"
      MESSAGE "Delete canceled"
      EXIT MENU
    END MENU
  END IF
    
  RETURN del_ok
  
END FUNCTION


FUNCTION clean_up_cust()
 
   WHENEVER ERROR CONTINUE
    CLOSE dsg_curs
    FREE dsg_curs
   WHENEVER ERROR STOP
 
 END FUNCTION  