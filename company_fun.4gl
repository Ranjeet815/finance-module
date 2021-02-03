SCHEMA testdb

DEFINE  dr_dsgrec RECORD
      companycode LIKE company.companycode,
      companyname LIKE company.companyname,
     address1 LIKE company.address1,
     address2 LIKE company.address2,
     pincode LIKE company.pincode
    
    END RECORD,
    work_dsgrec RECORD
      companycode LIKE company.companycode,
      companyname LIKE company.companyname,
     address1 LIKE company.address1,
     address2 LIKE company.address2,
     pincode LIKE company.pincode
    END RECORD

FUNCTION query_dsg1()
  DEFINE cont_ok         SMALLINT,
         dsg_cnt    SMALLINT,
         where_clause STRING

  MESSAGE "Enter search company criteria"
  LET cont_ok = FALSE
  LET int_flag = FALSE
  
  CONSTRUCT BY NAME where_clause ON company.*
                             
  IF (int_flag) = TRUE THEN
    LET int_flag=FALSE
    CLEAR FORM
    LET cont_ok = FALSE
    MESSAGE "Canceled by user."
  ELSE      
    CALL get_dsg_cnt_desg1(where_clause)
           RETURNING dsg_cnt
    IF (dsg_cnt > 0) THEN
       MESSAGE dsg_cnt using "<<<<", " rows found."
       CALL dsg_select1(where_clause)
          RETURNING cont_ok
    ELSE
       MESSAGE "No rows found."
       LET cont_ok = FALSE    
    END IF
  END IF
 
    IF (cont_ok) THEN
      CALL display_com()
    END IF
    
    RETURN cont_ok
 
END FUNCTION

FUNCTION get_dsg_cnt_desg1(p_where_clause)
  DEFINE p_where_clause   STRING,
         sql_text         STRING,
         dsg_cnt        SMALLINT
         
  
  LET sql_text = "SELECT COUNT(*) FROM company WHERE " || p_where_clause CLIPPED
  
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
  
FUNCTION dsg_select1(p_where_clause) 
  DEFINE p_where_clause  STRING,
         sql_text        STRING,
         fetch_ok        SMALLINT
 
  LET sql_text = "SELECT * FROM company WHERE "  ||
        p_where_clause clipped 
  

  DECLARE dsg_curs SCROLL CURSOR WITH HOLD FROM sql_text  
  
  OPEN dsg_curs
  CALL fetch_com(1)        --fetch the first row
     RETURNING fetch_ok
  IF NOT (fetch_ok) THEN
     MESSAGE "no rows in table."   -- someone deleted the rows after we checked the count
  END IF
      
  RETURN fetch_ok
 
END FUNCTION
 


FUNCTION fetch_com (p_fetch_flag)
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



FUNCTION fetch_rel_com(p_fetch_flag)
  DEFINE p_fetch_flag SMALLINT,
         fetch_ok     SMALLINT
   
  MESSAGE " "       
  CALL fetch_com(p_fetch_flag)
    RETURNING fetch_ok
    
  IF (fetch_ok) THEN
    CALL display_com()
  ELSE
    IF (p_fetch_flag = 1) THEN
      MESSAGE "End of list"
    ELSE
      MESSAGE "Beginning of list"
    END IF
  END IF
    
 END FUNCTION
 




 FUNCTION display_com()
  DISPLAY BY NAME dr_dsgrec.*
END FUNCTION
 


 
 FUNCTION inpupd_com(au_flag)  
  DEFINE au_flag  CHAR(1),
         cont_ok  SMALLINT
        
  LET cont_ok = TRUE 
  INITIALIZE work_dsgrec.* TO NULL      
  
  IF (au_flag = "A") THEN  
    MESSAGE "Add a new company "
    LET dr_dsgrec.* = work_dsgrec.*   -- this is an add, set program record to null 
  ELSE
    MESSAGE "Update company"
    LET work_dsgrec.* = dr_dsgrec.*   -- this is an update, save original 
  END IF
   
  LET int_flag = FALSE
  
  INPUT BY NAME dr_dsgrec.* WITHOUT DEFAULTS ATTRIBUTE (UNBUFFERED) 
  
  BEFORE FIELD companycode
      IF au_flag = "U" THEN
    NEXT FIELD companyname
    END IF
  
   ON CHANGE companycode   
      IF au_flag = "A" THEN
         WHENEVER ERROR CONTINUE 
         SELECT companycode, 
               companyname, 
               address1,
              address2,
             pincode
            
            INTO dr_dsgrec.*
            FROM company 
            WHERE companycode = dr_dsgrec.companycode
          WHENEVER ERROR STOP     
          IF (SQLCA.SQLCODE = 0) THEN
             ERROR " company id number already in database."
             LET cont_ok = FALSE
             CALL display_com()
             EXIT INPUT
          END IF
      END IF      
      
ON CHANGE companyname
     IF (dr_dsgrec.companyname IS NULL) THEN
        ERROR "You must enter a company name."
        NEXT FIELD companyname
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


FUNCTION insert_com()

 WHENEVER ERROR CONTINUE   
 INSERT INTO company(companycode, 
                       companyname, 
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

FUNCTION update_com()
  DEFINE l_dsgrec RECORD
     companycode LIKE company.companycode,
      companyname LIKE company.companyname,
     address1 LIKE company.address1,
     address2 LIKE company.address2,
     pincode LIKE company.pincode

    END RECORD,
    matches INTEGER,
    cont_ok INTEGER
    
  LET matches = FALSE
  LET cont_ok = FALSE
       
  BEGIN WORK
  WHENEVER ERROR CONTINUE
  SELECT companycode,          -- reselect the row to lock it
       companyname, 
       address1,
      address2,
     pincode
    
     INTO l_dsgrec.* FROM company 
     WHERE companycode = dr_dsgrec.companycode -- FOR UPDATE
   WHENEVER ERROR STOP 
       
   IF SQLCA.SQLCODE = NOTFOUND THEN       
      ERROR "company has been deleted"
      LET cont_ok = FALSE
    ELSE                      -- compare records
      IF l_dsgrec.* = work_dsgrec.* THEN
        LET matches = TRUE      
      ELSE
        LET matches = FALSE
      END IF
    
      IF matches = TRUE THEN     
        WHENEVER ERROR CONTINUE
        UPDATE company SET  companyname = dr_dsgrec.companyname,
                       companyname = dr_dsgrec.companyname,
                       address1 = dr_dsgrec.address1,
                        address2 = dr_dsgrec.address2,
                        pincode = dr_dsgrec.pincode
                       
                      WHERE companycode = dr_dsgrec.companycode
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

FUNCTION delete_com()
  DEFINE del_ok SMALLINT
  
    WHENEVER ERROR CONTINUE
    DELETE FROM company WHERE companycode = dr_dsgrec.companycode
    WHENEVER ERROR STOP
    IF SQLCA.SQLCODE = 0 THEN
       MESSAGE "Row deleted"
       INITIALIZE dr_dsgrec.* TO NULL
       DISPLAY BY NAME dr_dsgrec.* 
    ELSE
      ERROR SQLERRMESSAGE
    END IF 
 
 END FUNCTION   

FUNCTION delete_check_com()
  DEFINE del_ok SMALLINT,
         del_count SMALLINT
  
  LET del_ok = FALSE
    
  WHENEVER ERROR CONTINUE
  SELECT COUNT(*) INTO del_count FROM ORDERS 
    WHERE orders.companycode = dr_dsgrec.companycode
  WHENEVER ERROR STOP
  
  IF del_count > 0 THEN
    MESSAGE "company has orders and cannot be deleted"
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


FUNCTION clean_up_com()
 
   WHENEVER ERROR CONTINUE
    CLOSE dsg_curs
    FREE dsg_curs
   WHENEVER ERROR STOP
 
 END FUNCTION  