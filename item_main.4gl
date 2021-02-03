IMPORT FGL item_fun
DATABASE testdb
FUNCTION  open_item()
DEFINE query_ok SMALLINT
DEFINE arr_index INT 

DEFER INTERRUPT
LET arr_index = 1
 
 -- CLOSE WINDOW SCREEN
  OPEN WINDOW w1 WITH FORM "item"

  MENU "item Information"
     COMMAND "find" 
      CALL query_itm() RETURNING query_ok
    COMMAND "next"           
      IF (query_ok) THEN
        CALL fetch_rel_itm(1)
      ELSE
        MESSAGE "You must query first."
        -- hide the action when ON DIALOG available
       END IF
    COMMAND "previous"
      IF (query_ok) THEN
        CALL fetch_rel_itm(-1)
      ELSE
        MESSAGE "You must query first."
      END IF
     COMMAND "Add"
      IF (inpupd_itm("A")) THEN
        CALL insert_itm()
      END IF
     COMMAND "Delete"
      IF (delete_check_itm()) THEN
         CALL delete_itm()
      END IF
      COMMAND "Modify" 
    IF inpupd_itm("U") THEN
        CALL update_itm()
      END IF
      COMMAND "quit" 
      EXIT MENU
  END MENU
  
  CLOSE WINDOW w1
 
  --DISCONNECT CURRENT

END FUNCTION 