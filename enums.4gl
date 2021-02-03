PUBLIC DEFINE fetchAction RECORD
    firstRecord INTEGER,
    previousRecord INTEGER,
    nextRecord INTEGER,
    lastRecord INTEGER,
    refreshRecord INTEGER
END RECORD = (
    firstRecord: 0,
    previousRecord: 1,
    nextRecord: 2,
    lastRecord: 3,
    refreshRecord: 99
)

PUBLIC DEFINE inputMode RECORD
    addMode INTEGER,
    changeMode INTEGER
END RECORD = (
    addMode: 0,
    changeMode: 1
)