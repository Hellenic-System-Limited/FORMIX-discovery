(****************************************************************************
*  UNIT          : FXTFLOG                                                  *
*  AUTHOR        : S.M.Wright                                               *
*  DATE          : 07/06/00                                                 *
*  PURPOSE       : Generic Text Log File Tool                               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXTFLOG;

INTERFACE

USES F6STDCTV,F6STDUTL;


TYPE PTextFileLogger = ^TTextFileLogger;
     TTextFileLogger = OBJECT
       PRIVATE
       FullFilePath   : STRING;
       LOG_FILE       : FILE;
       TITLE_STR      : STRING;
       FUNCTION OpenErrorLog  : INTEGER;
       FUNCTION CloseErrorLog : INTEGER;

       PUBLIC
       CONSTRUCTOR Init(FileName : STRING; TITLE : STRING);
       DESTRUCTOR  Done;

       FUNCTION    WriteError(ErrorStr : STRING) : INTEGER;   VIRTUAL;
       FUNCTION    WriteErrorTS(ErrorStr : STRING) : INTEGER; VIRTUAL;
     END;

IMPLEMENTATION

(*********************** TTextFileLogger METHODS **************************)

CONSTRUCTOR TTextFileLogger.Init(FileName : STRING;Title : STRING);
BEGIN
  FullFilePath := FileName;
  TITLE_STR    := Title;
END;

DESTRUCTOR TTextFileLogger.Done;
BEGIN
END;

FUNCTION TTextFileLogger.OpenErrorLog : INTEGER;
VAR FileErr      : INTEGER;
    SaveFileMode : INTEGER;
    ErrCode      : INTEGER;
BEGIN
  SaveFileMode := FileMode;
  FileMode := READ_WRITE + DENY_NONE;
  OpenErrorLog := 0;

  Assign(LOG_FILE,FullFilePath);
  {$I-}
  Reset(LOG_FILE,1);
  {$I+}
  FileErr := IOResult;
  IF FileErr = FILE_NOT_FOUND THEN
   BEGIN
    {$I-}
    ReWrite(LOG_FILE,1);
    {$I+}
    FileErr := IOResult;
    IF FileErr = 0 THEN
     BEGIN
      {$I-}
      BlockWrite(LOG_FILE,TITLE_STR[1],Length(TITLE_STR),ErrCode);
      {$I+}
      FileErr := IOResult;
     END;
   END
  ELSE IF FileErr = 0 THEN { seek end of file }
   BEGIN
    {$I-}
    Seek(LOG_FILE,FileSize(LOG_FILE));
    {$I+}
    FileErr := IOResult;
   END;
  OpenErrorLog := FileErr;
  FileMode := SaveFileMode;
END;

FUNCTION TTextFileLogger.CloseErrorLog : INTEGER;
BEGIN
  {$I-}
  Close(LOG_FILE);
  {$I+}
  CloseErrorLog := IOResult;
END;

FUNCTION TTextFileLogger.WriteError(ErrorStr : STRING) : INTEGER;
VAR ErrCode : INTEGER;
BEGIN {WriteErrorLog}
 ErrCode := FILE_NOT_FOUND;
 IF OpenErrorLog = 0 THEN
  BEGIN
   ErrorStr := ErrorStr + CR+LF;
   {$I-}
   BlockWrite(LOG_FILE,ErrorStr[1],Length(ErrorStr),ErrCode);
   {$I+}
   ErrCode := IOResult;
   CloseErrorLog;
  END;
 WriteError := ErrCode;
END;


FUNCTION TTextFileLogger.WriteErrorTS(ErrorStr : STRING) : INTEGER;
BEGIN
 WriteErrorTS := WriteError(Date+' '+Time+'-'+ErrorStr);
END;


END.
