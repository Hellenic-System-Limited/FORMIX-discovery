(****************************************************************************
*  UNIT          : FXFSrc
*  AUTHOR        : T.B.
*  DATE          : 09/06/09
*  PURPOSE       : FORMIX SourceCode FILE
*  MODIFICATIONS :-
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFSrc;

INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FXMODCTV,FXcfg,FXFTrn;

CONST  SourceCode_FileName   = 'SRCCODE.FIL';

TYPE   PSourceCodeRecord = ^TSourceCodeRecord;
       TSourceCodeRecord = PACKED RECORD
         SRC_ID             : LONGINT;              {1,4}
         SRC_Code           : ARRAY[0..60] OF CHAR; {5,61}
         SRC_Type           : ARRAY[1..8] OF CHAR;  {66,8}
         SRC_Free           : ARRAY[1..20] OF BYTE; {74,20}
       END;

{
SET TRUENULLCREATE=OFF#
CREATE TABLE SOURCE_CODES IN DICTIONARY USING 'SRCCODE.FIL' (
ID            IDENTITY,
Code          VARCHAR(60),
Type          CHAR(8),
Reserved      BINARY(20)
)#
CREATE UNIQUE INDEX ByCodeType IN DICTIONARY ON SOURCE_CODES(Code, Type)#
SET TRUENULLCREATE=ON#
}
    PSourceCodeFile = ^TSourceCodeFile;
    TSourceCodeFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;


VAR SourceCodeFile : PSourceCodeFile;     { File Object Instance Pointer }

IMPLEMENTATION

PROCEDURE TSourceCodeFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TSourceCodeRecord),#0);
 WITH TSourceCodeRecord(RecBuff) DO
  BEGIN
   FillChar(SRC_Type, SizeOf(SRC_Type), ' ');
  END;
END;

FUNCTION TSourceCodeFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TSourceCodeRecord);
   Page_Size := 4096;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {ID   Identity fields are modifiable! }
   INC(SegC,Set_Key(Key_Buf[0],01,04,K_EXTTYPE OR K_MODIFIABLE, EKT_AUTO_INC, 0));
   {ByCodeType}
   INC(SegC,Set_Key(Key_Buf[1],05,61,K_EXTTYPE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_ZSTRING,0));
   INC(SegC,Set_Key(Key_Buf[2],66,08,K_EXTTYPE OR K_MODIFIABLE,
       EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


END.
