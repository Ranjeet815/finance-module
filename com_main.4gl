IMPORT FGL company_fun
DATABASE testdb
FUNCTION open_company() 
DEFINE query_ok SMALLINT
DEFINE arr_index INT 

DEFER INTERRUPT
LET arr_index = 1
 
 -- CLOSE WINDOW SCREEN
  OPEN WINDOW w1 WITH FORM "company-sr"

  MENU "company Information"
     COMMAND "find" 
      CALL query_dsg1() RETURNING query_ok
    COMMAND "next"           
      IF (query_ok) THEN
        CALL fetch_rel_com(1)
      ELSE
        MESSAGE "You must query first."
        -- hide the action when ON DIALOG available
       END IF
    COMMAND "previous"
      IF (query_ok) THEN
        CALL fetch_rel_com(-1)
      ELSE
        MESSAGE "You must query first."
      END IF
     COMMAND "Add"
      IF (inpupd_com("A")) THEN
        CALL insert_com()
      END IF
     COMMAND "Delete"
      IF (delete_check_com()) THEN
         CALL delete_com()
      END IF
      COMMAND "Modify" 
    IF inpupd_com("U") THEN
        CALL update_com()
      END IF
      COMMAND "quit" 
      EXIT MENU
  END MENU
  
  CLOSE WINDOW w1
 
  DISCONNECT CURRENT

END FUNCTION 