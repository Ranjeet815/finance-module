IMPORT util
IMPORT FGL account_main
IMPORT FGL com_main
IMPORT FGL cust_main
IMPORT FGL item_main
IMPORT FGL supplier_main
IMPORT FGL tans_main
IMPORT FGL supilier_main
DATABASE testdb

MAIN 

CLOSE WINDOW SCREEN

OPEN WINDOW finance WITH FORM "finance_main"

    MENU
            ON ACTION account
            CALL open_account()

            ON ACTION company
            CALL open_company()

            ON ACTION customer
            CALL open_customer()

            ON ACTION item
            CALL open_item()

            ON ACTION supplier
            CALL open_supplier()

             ON ACTION transection_cust
             CALL open_trans()

            ON ACTION transection_sup
             CALL open_sup()

            ON ACTION EXIT
            EXIT MENU 
    
    END MENU

END MAIN 