IMPORT util
IMPORT FGL DynamicUI
IMPORT FGL UIHelper
IMPORT FGL enums

SCHEMA testdb

CONSTANT cBaseSQL = "SELECT suppliercode FROM supplier"
CONSTANT cOrderBy = "suppliercode"



TYPE t_orders RECORD LIKE supplier.*
TYPE t_order_num LIKE supplier.suppliercode
TYPE t_stock_num LIKE supplier.suppliercode

TYPE t_items RECORD
    
    customercode LIKE trans_details.customercode,
    trans_num LIKE trans_details.trans_num,
    tran_date LIKE trans_details.tran_date,
    acc_type LIKE trans_details.acc_type,
    item_code LIKE trans_details.item_code,
    quantity LIKE trans_details.quantity,
     rate LIKE trans_details.rate,
      ammount LIKE trans_details.ammount,
       ammount_paid LIKE trans_details.ammount_paid,
        status LIKE trans_details.status
    
  
END RECORD

DEFINE m_order t_orders
DEFINE m_numList DYNAMIC ARRAY OF t_order_num
DEFINE mCurrentRow INTEGER = 0
DEFINE mCursorDefined BOOLEAN = FALSE
DEFINE mItemList DYNAMIC ARRAY OF t_items




FUNCTION  open_sup()

    WHENEVER ANY ERROR CALL errorHandler
    CALL STARTLOG("inputOrders_sup.log")
    DATABASE testdb

    OPEN WINDOW inputForm WITH FORM "sup_t"
  --  CLOSE WINDOW SCREEN
    CALL ui.Window.getCurrent().getForm().loadToolBar("RecordManager")

    WHILE searchOrders()
        DISPLAY "Looping back to search"
    END WHILE
    
    CLOSE WINDOW inputForm
    
END FUNCTION 

PRIVATE FUNCTION searchOrders() RETURNS BOOLEAN
    DEFINE lWherePart STRING
    DEFINE lReturnStatus BOOLEAN = FALSE
     
    
    DISPLAY "EVENT Details Search Mode" TO formonly.mode_label
    LET lWherePart = DynamicUI.dynamicConstruct(base.TypeInfo.create(m_order))
    IF lWherePart.getLength() > 0 THEN
        IF buildQuery(lWherePart) THEN
            CALL viewOrders()
            LET lReturnStatus = TRUE
        ELSE
            ERROR "No matches found"
        END IF
    END IF

    RETURN lReturnStatus


    
END FUNCTION

PRIVATE FUNCTION buildQuery(pWherePart STRING) RETURNS BOOLEAN
    DEFINE lSQLSelect STRING
    DEFINE lReturnStatus BOOLEAN = TRUE
    DEFINE lNumber t_order_num
   IF pWherePart MATCHES " WHERE*" THEN
        LET lSQLSelect = cBaseSQL, pWherePart
    ELSE
        LET lSQLSelect = SFMT("%1\n WHERE %2 ORDER BY %3", cBaseSQL, pWherePart, cOrderBy)
    END IF
    TRY
        LET mCurrentRow = 0
        CALL m_numList.clear()
        DECLARE cursOrderNum CURSOR FROM lSQLSelect
        FOREACH cursOrderNum INTO lNumber
            LET mCurrentRow = mCurrentRow + 1
            LET m_numList[mCurrentRow] = lNumber
        END FOREACH
        IF m_numList.getLength() > 0 THEN
            LET lReturnStatus = fetchRecord(fetchAction.firstRecord)
        ELSE
            LET lReturnStatus = FALSE
        END IF
    CATCH
        LET lReturnStatus = FALSE
    END TRY

    RETURN lReturnStatus
END FUNCTION #buildQuery




PRIVATE FUNCTION fetchRecord(pFetchAction INTEGER) RETURNS BOOLEAN
    DEFINE lReturnStatus BOOLEAN = FALSE
    DEFINE r_item RECORD LIKE trans_details.*
    DEFINE lIndex INTEGER = 0

    IF mCursorDefined == FALSE THEN
        DECLARE cursOrdersByNum CURSOR FROM "SELECT * FROM supplier WHERE suppliercode = ?"
         DECLARE cursItemsByNum CURSOR FROM "SELECT * FROM trans_details WHERE suppliercode = ? ORDER BY customercode"
        LET mCursorDefined = TRUE
    END IF

    CASE pFetchAction
        WHEN fetchAction.firstRecord
            LET mCurrentRow = 1
        WHEN fetchAction.previousRecord
            LET mCurrentRow = IIF(mCurrentRow > 1, mCurrentRow - 1, 1)
        WHEN fetchAction.nextRecord
            LET mCurrentRow = IIF(mCurrentRow < m_numList.getLength(), mCurrentRow + 1, m_numList.getLength())
        WHEN fetchAction.lastRecord
            LET mCurrentRow = m_numList.getLength()
        OTHERWISE
            IF mCurrentRow < 1 THEN
                LET mCurrentRow = 1
            ELSE
                IF mCurrentRow > m_numList.getLength() THEN
                    LET mCurrentRow = m_numList.getLength()
                END IF
            END IF
    END CASE

    TRY
        OPEN cursOrdersByNum USING m_numList[mCurrentRow]
        FETCH cursOrdersByNum INTO m_order.*
        LET lReturnStatus = (SQLCA.sqlcode == 0)
        CLOSE cursOrdersByNum
        IF lReturnStatus THEN
            CALL mItemList.clear()
            LET lIndex = 0
            FOREACH cursItemsByNum USING m_order.suppliercode INTO r_item.*
                LET lIndex = lIndex + 1
               
                LET mItemList[lIndex].customercode = r_item.customercode
                LET mItemList[lIndex].trans_num = r_item.trans_num
                LET mItemList[lIndex].tran_date = r_item.tran_date
                LET mItemList[lIndex].acc_type = r_item.acc_type
                LET mItemList[lIndex].item_code = r_item.item_code
                LET mItemList[lIndex].quantity = r_item.quantity
                LET mItemList[lIndex].rate = r_item.rate
                LET mItemList[lIndex].ammount = r_item.ammount
                LET mItemList[lIndex].ammount_paid = r_item.ammount_paid
                LET mItemList[lIndex].status = r_item.status
            END FOREACH
        END IF
    CATCH
        LET lReturnStatus = FALSE
    END TRY

    RETURN lReturnStatus

END FUNCTION #fetchRecord

PRIVATE FUNCTION viewOrders() RETURNS ()

    LET int_flag = FALSE
    WHILE int_flag == FALSE

        DISPLAY m_order.* TO U_User.*
        DISPLAY SFMT("View Mode %1 of %2", mCurrentRow, m_numList.getLength()) TO formonly.mode_label
        
        DISPLAY ARRAY mItemList TO trans_details.*
         ATTRIBUTES(ACCEPT=FALSE)
            ON ACTION CANCEL
                LET int_flag = TRUE
                EXIT DISPLAY
            ON ACTION FIRST
                IF fetchRecord(fetchAction.firstRecord) THEN
                    EXIT DISPLAY
                END IF
            ON ACTION PREVIOUS
                IF fetchRecord(fetchAction.previousRecord) THEN
                    EXIT DISPLAY
                END IF
            ON ACTION NEXT
                IF fetchRecord(fetchAction.nextRecord) THEN
                    EXIT DISPLAY
                END IF
            ON ACTION LAST
                IF fetchRecord(fetchAction.lastRecord) THEN
                    EXIT DISPLAY
                END IF
            ON ACTION add_rec
                IF inputOrder_sup(inputMode.addMode) THEN
                    IF fetchRecord(fetchAction.refreshRecord) THEN
                        EXIT DISPLAY
                    END IF
                END IF
            ON ACTION edit_rec
                IF inputOrder_sup(inputMode.changeMode) THEN
                    IF fetchRecord(fetchAction.refreshRecord) THEN
                        EXIT DISPLAY
                    END IF
                END IF
            ON ACTION del_rec
            IF UIHelper.deleteConfirmation() THEN
                    #Should delete here, but I won't
                    IF fetchRecord(fetchAction.previousRecord) THEN
                        EXIT DISPLAY
                    END IF
                END IF
                
            AFTER DISPLAY
                CONTINUE DISPLAY
        END DISPLAY

    END WHILE
    LET int_flag  = FALSE

END FUNCTION #viewOrders

PUBLIC FUNCTION inputOrder_sup(pMode INTEGER) RETURNS BOOLEAN
    DEFINE lReturnStatus BOOLEAN = FALSE
    DEFINE r_order t_orders
    DEFINE lItemList DYNAMIC ARRAY OF t_items
    DEFINE lNumber t_order_num
    DEFINE lRow INTEGER
    DEFINE lDeletedItems DYNAMIC ARRAY OF t_stock_num
    DEFINE lIndex INTEGER = 0
    --DEFINE 
    --id INTEGER ,
  -- name LIKE zoom_tr.training_dec
    
          
          
    

    #Do Input Statement...
    IF pMode == inputMode.changeMode THEN
        LET r_order.* = m_order.*
        CALL mItemList.copyTo(lItemList)
        CALL lDeletedItems.clear()
        DISPLAY "Change mode" TO formonly.mode_label
        DISPLAY SFMT("Order record: %1", util.JSON.stringify(r_order))
    ELSE
        DISPLAY "Add mode" TO formonly.mode_label
        #Set some meaningful defaults
        LET r_order.suppliercode = 101
        LET r_order.suppliername= "N"
    END IF

    DIALOG
     ATTRIBUTES(UNBUFFERED)
     
        INPUT r_order.* FROM U_User.*
         ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
            BEFORE INPUT
                IF pMode == inputMode.changeMode THEN
                    CALL ui.Dialog.getCurrent().setFieldActive("U_User.suppliercode", FALSE)
                END IF
            AFTER FIELD suppliercode
                IF pMode == inputMode.addMode AND r_order.suppliercode IS NOT NULL THEN
                    SELECT suppliercode INTO lNumber
                      FROM trans_details WHERE suppliercode = r_order.suppliercode
                    IF SQLCA.SQLCODE == 0 AND lNumber IS NOT NULL THEN
                        #Order record already exists for key
                        ERROR "EVENT Details number already exists in the database"
                        NEXT FIELD suppliercode
                    END IF
                END IF
        END INPUT

        INPUT ARRAY lItemList FROM E_Event.*
         ATTRIBUTES(DELETE ROW=TRUE, INSERT ROW=FALSE, APPEND ROW=TRUE, AUTO APPEND=TRUE, WITHOUT DEFAULTS=TRUE)
            BEFORE ROW
                LET lRow = arr_curr()
                
                LET lItemList[lRow].customercode = NVL(lItemList[lRow].customercode, 0)
                LET lItemList[lRow].trans_num = NVL(lItemList[lRow].trans_num, 0)
                LET lItemList[lRow].tran_date = NVL(lItemList[lRow].tran_date, 0)
                LET lItemList[lRow].acc_type = NVL(lItemList[lRow].acc_type, 0)
                LET lItemList[lRow].item_code = NVL(lItemList[lRow].item_code, 0)
                LET lItemList[lRow].quantity = NVL(lItemList[lRow].quantity, 0)
                LET lItemList[lRow].rate = NVL(lItemList[lRow].rate, 0)
                LET lItemList[lRow].ammount = NVL(lItemList[lRow].ammount, 0)
                LET lItemList[lRow].ammount_paid = NVL(lItemList[lRow].ammount_paid, 0)
                LET lItemList[lRow].status = NVL(lItemList[lRow].status, 0)

            BEFORE DELETE
                IF pMode == inputMode.changeMode THEN
                    #In change mode, track the deleted rows
                    LET lRow = arr_curr()
                    CALL lDeletedItems.appendElement()
                    LET lIndex = lDeletedItems.getLength()
                    LET lDeletedItems[lIndex] = lItemList[lRow].customercode
                END IF
            AFTER ROW
                #Validate Data
               IF LENGTH(lItemList[lRow].customercode) == 0 THEN
                    ERROR "customercode "
                    NEXT FIELD customercode
                END IF
              
             

                 IF lItemList[lRow].trans_num  <= 0  THEN
                    ERROR "trans_num  to be greater than 0"
                   NEXT FIELD trans_num
                END IF

                 IF lItemList[lRow].tran_date IS NULL  THEN
                    ERROR "tran_date  to be greater than "
                   NEXT FIELD tran_date
                END IF

              IF lItemList[lRow].acc_type IS NULL THEN
                 ERROR "Enter acc_type "
                 NEXT FIELD acc_type
             ELSE IF NOT lItemList[lRow].acc_type  MATCHES "[a-zA-Z]*"  THEN
                    ERROR "acc_type  can not be integer "
                    NEXT FIELD acc_type
                    END IF
             END IF
               
                
               IF lItemList[lRow].item_code  <= 0  THEN
                    ERROR "item_code  to be greater than 0"
                   NEXT FIELD item_code
                END IF

                IF lItemList[lRow].quantity  <= 0  THEN
                ERROR "quantity  to be greater than 0"
                   NEXT FIELD quantity
                END IF
                IF lItemList[lRow].rate  <= 0  THEN
                ERROR "rate  to be greater than 0"
                   NEXT FIELD rate
                END IF

                IF lItemList[lRow].ammount  <= 0  THEN
                ERROR "ammount  to be greater than 0"
                   NEXT FIELD ammount
                END IF

                 IF lItemList[lRow].ammount_paid  <= 0  THEN
                ERROR "ammount_paid  to be greater than 0"
                   NEXT FIELD ammount_paid
                END IF

                  IF lItemList[lRow].status  <= 0  THEN
                ERROR "ammount_paid  to be greater than 0"
                   NEXT FIELD status
                END IF

             {  IF lItemList[lRow].creator_name IS NULL THEN
                 ERROR "Enter creator_name "
                 NEXT FIELD creator_name
             ELSE IF NOT lItemList[lRow].creator_name  MATCHES "[a-zA-Z]*"  THEN
                    ERROR "creator_name  can not be integer "
                    NEXT FIELD creator_name
                    END IF
             END IF


             
               IF lItemList[lRow].city IS NULL THEN
                 ERROR "Enter city "
                 NEXT FIELD city
             ELSE IF NOT lItemList[lRow].city  MATCHES "[a-zA-Z]*"  THEN
                    ERROR "city  can not be integer "
                    NEXT FIELD city
                    END IF
             END IF}
                 
                FOR lIndex = 1 TO lItemList.getLength()
                    IF lIndex == lRow THEN
                        CONTINUE FOR
                    END IF
                    --IF lItemList[lIndex].emp_id == lItemList[lRow].emp_id THEN
                    --    ERROR "Duplicate Employyee Infometion number for two different Employee"
                    --    NEXT FIELD emp_id
                    --END IF
                END FOR
         --   ON CHANGE emp_name, dep_code, emp_num, emp_email, basic_stipend
                #When the quantity or price change, change the total_cost
              --  IF lItemList[lRow].emp_name IS NOT NULL AND lItemList[lRow].emp_num IS NOT NULL AND lItemList[lRow].emp_email IS NOT NULL  AND lItemList[lRow].basic_stipend IS  NOT NULL THEN
                   -- LET lItemList[lRow].total_cost = lItemList[lRow].subject_price * lItemList[lRow].subject_price
             --   END IF
        END INPUT

        ON ACTION save
            ACCEPT DIALOG


          {  ON ACTION zoom1
       CALL display_custlist() RETURNING id, name
       IF (id > 1) THEN
          LET r_order.training_id = id
          LET r_order.training_dec = name
       END IF}


       { ON ACTION p 
       CALL display_custlist() RETURNING id, name
       IF id > 0 THEN
          DISPLAY id TO zoom.collage_id
          DISPLAY name TO zoom.address
       END IF}


       ON ACTION CANCEL
            LET int_flag = TRUE
            EXIT DIALOG
      --  ON ACTION cencel
           -- CALL AUITreeInspector.inspectAUITree()
        AFTER DIALOG
            IF LENGTH(r_order.suppliername) == 0 THEN
                ERROR "suppliername is missing"
                NEXT FIELD suppliername
            END IF

    END DIALOG

    IF int_flag THEN
        LET lReturnStatus = FALSE
    ELSE
        TRY
            IF pMode == inputMode.addMode THEN
                INSERT INTO supplier VALUES(r_order.*)
                CALL m_numList.appendElement()
                LET mCurrentRow = m_numList.getLength()
                LET m_numList[mCurrentRow] = r_order.suppliercode
                FOR lIndex = 1 TO lItemList.getLength()
                    INSERT INTO trans_details (suppliercode, customercode, trans_num, tran_date, acc_type, item_code,quantity,rate,ammount,ammount_paid,status)
                     VALUES(r_order.suppliercode, lItemList[lIndex].customercode,lItemList[lIndex].trans_num,lItemList[lIndex].tran_date,lItemList[lIndex].acc_type, lItemList[lIndex].item_code,  lItemList[lIndex].quantity,lItemList[lIndex].rate, lItemList[lIndex].ammount, lItemList[lIndex].ammount_paid, lItemList[lIndex].status)
                END FOR
            ELSE
                UPDATE supplier
                   SET supplier.*= r_order.*
                 WHERE suppliercode = r_order.suppliercode
                 FOR lIndex = 1 TO lDeletedItems.getLength()
                    DELETE FROM trans_details 
                     WHERE supplier = r_order.suppliercode
                       AND customercode = lDeletedItems[lIndex]
                 END FOR
                 FOR lIndex = 1 TO lItemList.getLength()
                     SELECT suppliercode INTO lNumber FROM trans_details
                      WHERE suppliercode = r_order.suppliercode
                        AND customercode = lItemList[lIndex].customercode
                    IF sqlca.sqlcode == 0 THEN
                        UPDATE trans_details
                           SET trans_num = lItemList[lIndex].trans_num,
                               tran_date = lItemList[lIndex].tran_date,
                                acc_type = lItemList[lIndex].acc_type,
                                item_code = lItemList[lIndex].item_code,
                                quantity = lItemList[lIndex].quantity,
                                 rate = lItemList[lIndex].rate,
                                 ammount = lItemList[lIndex].ammount,
                                 ammount_paid = lItemList[lIndex].ammount_paid,
                                 status = lItemList[lIndex].status
                                 
                             
                         WHERE suppliercode = r_order.suppliercode
                           AND customercode = lItemList[lIndex].customercode
                    ELSE
                        IF sqlca.sqlcode == NOTFOUND THEN
                            INSERT INTO trans_details (suppliercode,customercode, trans_num, tran_date, acc_type, item_code,quantity,rate,ammount,ammount_paid,status)
                            VALUES(r_order.suppliercode, lItemList[lIndex].customercode,lItemList[lIndex].trans_num,lItemList[lIndex].tran_date,lItemList[lIndex].acc_type, lItemList[lIndex].item_code,  lItemList[lIndex].quantity,lItemList[lIndex].rate, lItemList[lIndex].ammount, lItemList[lIndex].ammount_paid, lItemList[lIndex].status)
                        END IF
                    END IF
                 END FOR
            END IF
            LET m_order.* = r_order.*
            CALL lItemList.copyTo(mItemList)
            LET lReturnStatus = TRUE
        CATCH
            LET lReturnStatus = FALSE
       -- ERROR "An error occurred while saving the data"
        END TRY
    END IF
    LET int_flag = FALSE
    RETURN lReturnStatus

END FUNCTION #inputOrders

{PUBLIC FUNCTION loadCountryCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE country.country_code
    DEFINE lName LIKE country.country_name

    --Populate the factory combobox
    DECLARE cursFactory CURSOR FROM "SELECT country_code, country_name FROM country ORDER BY country_name"
    FOREACH cursFactory INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION

PUBLIC FUNCTION loadEvent_nameCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE event_name.event_code
    DEFINE lName LIKE event_name.event_name

    --Populate the stores/customers combobox
    DECLARE cursCNTR CURSOR FROM "SELECT event_code, event_name FROM event_name ORDER BY event_name"
    FOREACH cursCNTR INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION


PUBLIC FUNCTION loadGenderCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE gender1.gender_id
    DEFINE lName LIKE  gender1.gender_name

    --Populate the stores/customers combobox
    DECLARE cursGender CURSOR FROM "SELECT gender_id, gender_name FROM gender1 ORDER BY gender_name"
    FOREACH cursGender INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION}

PRIVATE FUNCTION errorHandler() RETURNS ()
    DEFINE lMessage STRING
    LET lMessage = SFMT("Error Code: %1\n%2", STATUS, err_get(STATUS))
    CALL ERRORLOG(base.Application.getStackTrace())
   CALL UIHelper.informationDialog("Error Occurred", lMessage)
END FUNCTION