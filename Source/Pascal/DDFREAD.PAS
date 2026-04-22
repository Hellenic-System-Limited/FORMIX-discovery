{$I F6COMP}
UNIT DDFRead;
INTERFACE
USES F6BTrv,FileObj,FXCFG,F6StdCtv;

CONST
     FileDDFName  = 'FILE.DDF';
     FieldDDFName = 'FIELD.DDF';
     IndexDDFName = 'INDEX.DDF';

TYPE
     TDDFName  = ARRAY[1..20] OF CHAR;


TYPE
     PFILE_DDF = ^TFILE_DDF;
     TFILE_DDF = PACKED RECORD
      FILE_ID       : INTEGER;
      FILE_Name     : TDDFName;
      FILE_Location : ARRAY[0..63] of CHAR;
      FILE_Flags    : BYTE;
      FILE_Unknown  : ARRAY[1..10] of CHAR;
     END;
TYPE
     PFIELD_DDF = ^TFIELD_DDF;
     TFIELD_DDF = PACKED RECORD
      FIELD_ID       : INTEGER;
      FIELD_FileCode : INTEGER;
      FIELD_Name     : TDDFName;
      FIELD_DataType : BYTE;
      FIELD_Offset   : INTEGER;
      FIELD_Size     : INTEGER;
      FIELD_Dectype  : BYTE;
      FIELD_Flags    : INTEGER;
     END;

TYPE
     PINDEF_DDF = ^TINDEX_DDF;
     TINDEX_DDF = PACKED RECORD
      INDEX_ID           : INTEGER;
      INDEX_Field        : INTEGER;
      INDEX_Number       : INTEGER;
      INDEX_Part         : INTEGER;
      INDEX_Flags        : INTEGER;
     END;

    PFileDDFFile = ^TFileDDFFile;
    TFileDDFFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;

    PFieldDDFFile = ^TFieldDDFFile;
    TFieldDDFFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;

    PIndexDDFFile = ^TIndexDDFFile;
    TIndexDDFFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;

VAR
  FileDDFFile  : PFileDDFFile;
  FieldDDFFile : PFieldDDFFile;
  IndexDDFFile : PIndexDDFFile;

FUNCTION AllocateDDFFileHandles : BOOLEAN;
PROCEDURE StringTOLString(Str : ARRAY OF CHAR;VAR LStr : STRING);
PROCEDURE LStringTOString(LStr : STRING;VAR Str : ARRAY OF CHAR);
PROCEDURE DisposeDDFFileHandles;

IMPLEMENTATION

PROCEDURE StringTOLString(Str : ARRAY OF CHAR;VAR LStr : STRING);
BEGIN
 Move(Str,LStr[1],High(Str)-Low(Str)+1);
 LStr[0]:=Char(High(Str)-Low(Str)+1);
END;

PROCEDURE LStringTOString(LStr : STRING;VAR Str : ARRAY OF CHAR);
VAR TempStr : STRING;
BEGIN
 TempStr :=COPY(LStr+SPACE_STRING,1,High(Str)-Low(Str)+1);
 Move(TempStr[1],Str,High(Str)-Low(Str)+1);
END;

PROCEDURE DisposeDDFFileHandles;
BEGIN
 IF FileDDFFile  <> NIL THEN Dispose(FileDDFFile,Done);
 IF FieldDDFFile <> NIL THEN Dispose(FieldDDFFile,Done);
 IF IndexDDFFile <> NIL THEN Dispose(IndexDDFFile,Done);
END;

FUNCTION AllocateDDFFileHandles : BOOLEAN;
BEGIN
  AllocateDDFFileHandles := FALSE;

  New(FileDDFFile,Init(Config_Rec^.Conf_SFPath+FileDDFName));
  IF NOT Assigned(FileDDFFile) THEN Exit;

  New(FieldDDFFile,Init(Config_Rec^.Conf_SFPath +FieldDDFName));
  IF NOT Assigned(FieldDDFFile) THEN Exit;

  New(IndexDDFFile  ,Init(Config_Rec^.Conf_SFPath +IndexDDFName));
  IF NOT Assigned(IndexDDFFile)   THEN Exit;

  AllocateDDFFileHandles := TRUE;
END;



PROCEDURE TFileDDFFile.InitRecord     (VAR RecBuff);
BEGIN
 FIllChar(RecBuff,SizeOf(TFILE_DDF),#0);
{ WITH RecBuff DO
  BEGIN
   FILE_ID       := 0;
   FILE_Flags    := 0;
  END;}
END;

FUNCTION  TFileDDFFile.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TFILE_DDF);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 ID}
   INC(SegC,Set_Key(Key_Buf[0],01,02,K_EXTTYPE,EKT_INTEGER,0));
   {1.0 Name}
   INC(SegC,Set_Key(Key_Buf[1],03,20,K_EXTTYPE,EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;



PROCEDURE TFieldDDFFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TFIELD_DDF),#0);
END;

FUNCTION  TFieldDDFFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TFILE_DDF);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 4;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 ID }
   INC(SegC,Set_Key(Key_Buf[0],01,02,K_EXTTYPE,EKT_INTEGER,0));
   {1.0 FileCode}
   INC(SegC,Set_Key(Key_Buf[1],03,02,K_EXTTYPE,EKT_INTEGER,0));
   {2.0 Name}
   INC(SegC,Set_Key(Key_Buf[2],05,20,K_EXTTYPE,EKT_STRING,0));
   {3.0 FileCode}
   INC(SegC,Set_Key(Key_Buf[3],03,02,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   {3.1 Name}
   INC(SegC,Set_Key(Key_Buf[4],05,20,K_EXTTYPE,EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;



PROCEDURE TIndexDDFFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TINDEX_DDF),#0);
END;

FUNCTION  TIndexDDFFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TFILE_DDF);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 ID }
   INC(SegC,Set_Key(Key_Buf[0],01,02,K_EXTTYPE,EKT_INTEGER,0));
   {1.0 Field}
   INC(SegC,Set_Key(Key_Buf[1],03,02,K_EXTTYPE,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


END.