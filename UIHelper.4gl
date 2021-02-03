PUBLIC FUNCTION informationDialog(pTitle STRING, pMessage STRING)
    MENU pTitle ATTRIBUTES(STYLE="dialog",COMMENT=pMessage)
        ON ACTION ACCEPT
            EXIT MENU
    END MENU
END FUNCTION

PUBLIC FUNCTION deleteConfirmation() RETURNS BOOLEAN
    DEFINE lConfirmed   BOOLEAN = FALSE
    MENU "Confirm Delete"
     ATTRIBUTES(STYLE="dialog",COMMENT="Do you want to delete the current record?")
        ON ACTION YES ATTRIBUTES(TEXT="Yes")
            LET lConfirmed = TRUE
            EXIT MENU
        ON ACTION NO ATTRIBUTES(TEXT="No")
            EXIT MENU
    END MENU
    RETURN lConfirmed
END FUNCTION