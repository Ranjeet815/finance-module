IMPORT FGL cust_fun
DATABASE testdb
FUNCTION  open_customer()
DEFINE query_ok SMALLINT
DEFINE arr_index INT 

DEFER INTERRUPT
LET arr_index = 1
 
 -- CLOSE WINDOW SCREEN
  OPEN WINDOW w1 WITH FORM "cust_sr"

  MENU "customer Information"
     COMMAND "find" 
      CALL query_cust() RETURNING query_ok
    COMMAND "next"           
      IF (query_ok) THEN
        CALL fetch_rel_cust(1)
      ELSE
        MESSAGE "You must query first."
        -- hide the action when ON DIALOG available
       END IF
    COMMAND "previous"
      IF (query_ok) THEN
        CALL fetch_rel_cust(-1)
      ELSE
        MESSAGE "You must query first."
      END IF
     COMMAND "Add"
      IF (inpupd_cust("A")) THEN
        CALL insert_com()
      END IF
     COMMAND "Delete"
      IF (delete_check_cust()) THEN
         CALL delete_cust()
      END IF
      COMMAND "Modify" 
    IF inpupd_cust("U") THEN
        CALL update_cust()
      END IF
      COMMAND "quit" 
      EXIT MENU
  END MENU
  
  CLOSE WINDOW w1
 
 -- DISCONNECT CURRENT

END FUNCTION 