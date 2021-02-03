SCHEMA testdb

{PUBLIC FUNCTION loadStateCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE state.state_code
    DEFINE lName LIKE state.state_name

    --Populate the state combobox
    DECLARE cursStates CURSOR FROM "SELECT state_code, state_name FROM state ORDER BY state_name"
    FOREACH cursStates INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
    END FOREACH

END FUNCTION}

{PUBLIC FUNCTION loadFactoryCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE factory.fac_code
    DEFINE lName LIKE factory.fac_name

    --Populate the factory combobox
    DECLARE cursFactory CURSOR FROM "SELECT fac_code, fac_name FROM factory ORDER BY fac_name"
    FOREACH cursFactory INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION

PUBLIC FUNCTION loadStoreCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE customer.store_num
    DEFINE lName LIKE customer.store_name

    --Populate the stores/customers combobox
    DECLARE cursCustomer CURSOR FROM "SELECT store_num, store_name FROM customer ORDER BY store_name"
    FOREACH cursCustomer INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION}

{PUBLIC FUNCTION loadStockCombo(pCombo ui.ComboBox) RETURNS ()
    DEFINE lCode LIKE stock.stock_num
    DEFINE lName LIKE stock.description

    --Populate the stock combobox
    DECLARE cursStock CURSOR FROM "SELECT stock_num, description FROM stock ORDER BY stock_num"
    FOREACH cursStock INTO lCode, lName
        CALL pCombo.addItem(lCode, lName)
        DISPLAY SFMT("Adding %1 %2", lCode, lName)
    END FOREACH

END FUNCTION}