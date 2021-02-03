IMPORT util

PUBLIC TYPE t_field RECORD
    name STRING,
    type STRING
END RECORD

PUBLIC TYPE t_dialogEvent RECORD
    dialog_type STRING,
    dialog_event STRING
END RECORD

PUBLIC DEFINE dialogTypes RECORD
    dialogType STRING,
    constructType STRING,
    displayArrayType STRING,
    inputType STRING,
    inputArrayType STRING
END RECORD = (
    dialogType: "DIALOG",
    constructType: "CONSTRUCT",
    displayArrayType: "DISPLAY ARRAY",
    inputType: "INPUT",
    inputArrayType: "INPUT ARRAY"
)

PUBLIC TYPE t_displayArrayCallback RECORD
    getDialogTriggers FUNCTION() RETURNS DYNAMIC ARRAY OF STRING,
    handleDialogEvents FUNCTION(pDialog ui.Dialog, pEvent STRING, pCurrentRow INTEGER) RETURNS BOOLEAN
END RECORD
 
PUBLIC TYPE t_searchListCallback RECORD
    getDialogTriggers FUNCTION() RETURNS DYNAMIC ARRAY OF t_dialogEvent,
    handleDialogEvents FUNCTION(pDialog ui.Dialog, pEvent STRING, pCurrentRow INTEGER) RETURNS BOOLEAN,
    executeSearch FUNCTION(pWherePart STRING) RETURNS util.JSONArray,
    enableMultiSelect FUNCTION() RETURNS BOOLEAN
END RECORD

PUBLIC FUNCTION dynamicConstruct(pRecordNode om.DomNode) RETURNS STRING
    DEFINE lDialog ui.Dialog
    DEFINE lFieldList DYNAMIC ARRAY OF t_field
    DEFINE lTrigger STRING

    LET lFieldList = getRecordDefinition(pRecordNode)

   LET lDialog = ui.Dialog.createConstructByName(lFieldList)
    CALL lDialog.addTrigger("ON ACTION do_search")
    CALL lDialog.addTrigger("ON ACTION cancel")

    LET int_flag = FALSE
    WHILE (lTrigger := lDialog.nextEvent()) IS NOT NULL

        CASE lTrigger
            WHEN "ON ACTION do_search"
                CALL lDialog.accept()
            WHEN "ON ACTION cancel"
                LET int_flag = TRUE
                EXIT WHILE
            WHEN "AFTER CONSTRUCT"
                EXIT WHILE
        END CASE
    
    END WHILE
    
    IF int_flag THEN
        RETURN ""
    END IF

    RETURN getWherePart(lDialog, lFieldList)

END FUNCTION #dynamicConstruct

PUBLIC FUNCTION dynamicDisplayArray(pRecordNode om.DomNode, 
                                    pJsonArray util.JSONArray,
                                    pScreenRecord STRING,
                                    pCallback t_displayArrayCallback) RETURNS ()
    DEFINE lFieldList DYNAMIC ARRAY OF t_field
    DEFINE lDialog ui.Dialog
    DEFINE lRow INTEGER
    DEFINE x, y INTEGER
    DEFINE lTrigger STRING
    DEFINE lJsonObj util.JSONObject
    DEFINE lFieldName STRING
    DEFINE lStatus BOOLEAN
    DEFINE lTriggerList DYNAMIC ARRAY OF STRING

    LET lFieldList = getRecordDefinition(pRecordNode)
    LET lDialog = ui.Dialog.createDisplayArrayTo(lFieldList, pScreenRecord)

    CALL lDialog.addTrigger("ON ACTION accept")
    CALL lDialog.addTrigger("ON ACTION cancel")

    LET lTriggerList = pCallback.getDialogTriggers()
    FOR x = 1 TO lTriggerList.getLength()
        CALL lDialog.addTrigger(lTriggerList[x])
    END FOR
    
    #Outer Loop - iterate through the rows
    FOR x = 1 TO pJsonArray.getLength()
        CALL lDialog.setCurrentRow(pScreenRecord, x)
        LET lJsonObj = pJsonArray.get(x)
        #Inner Loop - iterate through the columns
        FOR y = 1 TO lFieldList.getLength()
            LET lFieldName = lFieldList[y].name
            CALL lDialog.setFieldValue(lFieldName, lJsonObj.get(lFieldName))
        END FOR
    END FOR

    LET int_flag = FALSE
    WHILE (lTrigger := lDialog.nextEvent()) IS NOT NULL

        CASE lTrigger
            WHEN "BEFORE DISPLAY"
                CALL lDialog.setCurrentRow(pScreenRecord, 1)
            WHEN "ON ACTION cancel"
                LET int_flag = TRUE
                EXIT WHILE
            WHEN "ON ACTION accept"
                CALL lDialog.accept()
            OTHERWISE
                DISPLAY SFMT("Event: %1", lTrigger)
                LET lRow = lDialog.getCurrentRow(pScreenRecord)
                LET lStatus = pCallback.handleDialogEvents(lDialog, lTrigger, lRow)
        END CASE
    
    END WHILE

END FUNCTION

PUBLIC FUNCTION dynamicSearchList(pRecordNode om.DomNode, 
                                  pScreenRecord STRING,
                                  pArrayRecordPrefix STRING,
                                  pCallback t_searchListCallback) RETURNS ()

    DEFINE lFieldList DYNAMIC ARRAY OF t_field
    DEFINE lArrayFieldList DYNAMIC ARRAY OF t_field
    DEFINE lDialog ui.Dialog
    DEFINE lRow INTEGER
    DEFINE x INTEGER
    DEFINE lTrigger STRING
    DEFINE lJsonArray util.JSONArray
    DEFINE lStatus BOOLEAN
    DEFINE lTriggerList DYNAMIC ARRAY OF t_dialogEvent
    DEFINE lCurrentDialog STRING

    LET lFieldList = getRecordDefinition(pRecordNode)

    #Create the multi-dialog object
    LET lDialog = ui.Dialog.createMultipleDialog()
    CALL lDialog.addTrigger("ON ACTION accept")
    CALL lDialog.addTrigger("ON ACTION cancel")

    LET lTriggerList = pCallback.getDialogTriggers()
    FOR x = 1 TO lTriggerList.getLength()
        IF lTriggerList[x].dialog_type == dialogTypes.dialogType THEN
            CALL lDialog.addTrigger(lTriggerList[x].dialog_event)
        END IF
    END FOR

    #Create the Construct dialog
    CALL lDialog.addConstructByName(lFieldList, dialogTypes.constructType)
    CALL lDialog.addTrigger("ON ACTION do_search")
    FOR x = 1 TO lTriggerList.getLength()
        IF lTriggerList[x].dialog_type == dialogTypes.constructType THEN
            CALL lDialog.addTrigger(lTriggerList[x].dialog_event)
        END IF
    END FOR

    #Build the Array Field List from the Field List (using the prefix)
    CALL lFieldList.copyTo(lArrayFieldList)
    FOR x = 1 TO lArrayFieldList.getLength()
        LET lArrayFieldList[x].name = pArrayRecordPrefix, lArrayFieldList[x].name
    END FOR
    
    #Create the Display Array dialog
    CALL lDialog.addDisplayArrayTo(lArrayFieldList, pScreenRecord)
    FOR x = 1 TO lTriggerList.getLength()
        IF lTriggerList[x].dialog_type == dialogTypes.displayArrayType THEN
            CALL lDialog.addTrigger(lTriggerList[x].dialog_event)
        END IF
    END FOR

    IF pCallback.enableMultiSelect IS NOT NULL THEN
        IF pCallback.enableMultiSelect() THEN
            CALL lDialog.setSelectionMode(pScreenRecord, 1)
        END IF
    END IF

    LET int_flag = FALSE
    WHILE (lTrigger := lDialog.nextEvent()) IS NOT NULL

        CASE lTrigger
            WHEN "ON ACTION cancel"
                LET int_flag = TRUE
                EXIT WHILE
            WHEN "ON ACTION accept"
                CALL lDialog.accept()
            WHEN SFMT("BEFORE CONSTRUCT %1", dialogTypes.constructType)
                LET lCurrentDialog = dialogTypes.constructType
            WHEN SFMT("BEFORE DISPLAY %1", pScreenRecord)
                CALL lDialog.setCurrentRow(pScreenRecord, 1)
                LET lCurrentDialog = dialogTypes.displayArrayType
            WHEN SFMT("ON ACTION %1.do_search", dialogTypes.constructType)
                CALL lDialog.accept()
            WHEN "AFTER DIALOG"
                IF lCurrentDialog == dialogTypes.constructType THEN
                    LET lJSONArray = pCallback.executeSearch(getWherePart(lDialog, lFieldList))
                    CALL displayArrayValues(lDialog, lJSONArray, lFieldList, pArrayRecordPrefix, pScreenRecord)
                    CALL lDialog.setCurrentRow(pScreenRecord, 1)
                END IF
                
            OTHERWISE
                DISPLAY SFMT("Event: %1", lTrigger)
                LET lRow = lDialog.getCurrentRow(pScreenRecord)
                LET lStatus = pCallback.handleDialogEvents(lDialog, lTrigger, lRow)
        END CASE
    
    END WHILE
    

END FUNCTION

########### Internal Helper Functions ####################
PRIVATE FUNCTION getRecordDefinition(pRecordNode om.DomNode) RETURNS DYNAMIC ARRAY OF t_field
    DEFINE lNodeList om.NodeList
    DEFINE lIndex INTEGER
    DEFINE lNode om.DomNode
    DEFINE lFieldList DYNAMIC ARRAY OF t_field

    DISPLAY pRecordNode.toString()
    LET lNodeList = pRecordNode.selectByTagName("Field")
    FOR lIndex = 1 TO lNodeList.getLength()
        LET lNode = lNodeList.item(lIndex)
        LET lFieldList[lIndex].name = lNode.getAttribute("name")
        LET lFieldList[lIndex].type = lNode.getAttribute("type")
    END FOR

    RETURN lFieldList
    
END FUNCTION

PRIVATE FUNCTION getWherePart(pDialog ui.Dialog, pFieldList DYNAMIC ARRAY OF t_field) RETURNS STRING
    DEFINE lIndex INTEGER
    DEFINE lFieldName STRING
    DEFINE lFieldSearch STRING
    DEFINE lWherePart STRING

    FOR lIndex = 1 TO pFieldList.getLength()
        LET lFieldName = pFieldList[lIndex].name
        LET lFieldSearch = pDialog.getQueryFromField(lFieldName)
        IF lFieldSearch.getLength() > 0 THEN
            IF lWherePart.getLength() == 0 THEN
                LET lWherePart = SFMT(" WHERE %1", lFieldSearch)
            ELSE
                LET lWherePart = SFMT("%1 AND %2", lWherePart, lFieldSearch)
            END IF
        END IF
    END FOR

    IF lWherePart.getLength() == 0 THEN
        LET lWherePart = " WHERE 1=1"
    END IF

    RETURN lWherePart

END FUNCTION

PRIVATE FUNCTION displayArrayValues(pDialog ui.Dialog, 
                                    pJsonArray util.JSONArray, 
                                    pFieldList DYNAMIC ARRAY OF t_field,
                                    pFieldPrefix STRING,
                                    pScreenRecord STRING) RETURNS ()
    DEFINE x, y INTEGER
    DEFINE lFieldName STRING
    DEFINE lPrefixedName STRING
    DEFINE lJsonObj util.JSONObject

    CALL pDialog.setArrayLength(pScreenRecord, pJsonArray.getLength())
    #Outer Loop - iterate through the rows
    FOR x = 1 TO pJsonArray.getLength()
        LET lJsonObj = pJsonArray.get(x)
        CALL pDialog.setCurrentRow(pScreenRecord, x)
        DISPLAY SFMT("Setting current row to: %1", x)
        #Inner Loop - iterate through the columns
        FOR y = 1 TO pFieldList.getLength()
            LET lFieldName = pFieldList[y].name
            LET lPrefixedName = pFieldPrefix, lFieldName
            DISPLAY SFMT("Form Field: %1 Column: %2 ScreenRecord: %3", lPrefixedName, lFieldName, pScreenRecord)
            CALL pDialog.setFieldValue(lPrefixedName, lJsonObj.get(lFieldName))
        END FOR
    END FOR

END FUNCTION
