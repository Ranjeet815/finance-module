IMPORT FGL supplier_fun
DATABASE testdb
FUNCTION open_supplier() 
DEFINE query_ok SMALLINT
DEFINE arr_index INT 

DEFER INTERRUPT
LET arr_index = 1
 
 -- CLOSE WINDOW SCREEN
  OPEN WINDOW w1 WITH FORM "supplier_sr"

  MENU "supplier Information"
     COMMAND "find" 
      CALL query_sup() RETURNING query_ok
    COMMAND "next"           
      IF (query_ok) THEN
        CALL fetch_rel_sup(1)
      ELSE
        MESSAGE "You must query first."
        -- hide the action when ON DIALOG available
       END IF
    COMMAND "previous"
      IF (query_ok) THEN
        CALL fetch_rel_sup(-1)
      ELSE
        MESSAGE "You must query first."
      END IF
     COMMAND "Add"
      IF (inpupd_sup("A")) THEN
        CALL insert_sup()
      END IF
     COMMAND "Delete"
      IF (delete_check_sup()) THEN
         CALL delete_sup()
      END IF
      COMMAND "Modify" 
    IF inpupd_sup("U") THEN
        CALL update_sup()
      END IF
      COMMAND "quit" 
      EXIT MENU
  END MENU
  
  CLOSE WINDOW w1
 
  --DISCONNECT CURRENT

END FUNCTION 