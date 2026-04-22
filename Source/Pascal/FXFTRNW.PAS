(****************************************************************************
*  UNIT          : FXFTRNW
*  AUTHOR        : T.Bell
*  DATE          : 20/04/16
*  PURPOSE       : FORMIX TRANSACTION WARNINGS FILE
*  MODIFICATIONS :-
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFTRNW;
INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FXMODCTV,FXcfg,F6StdUtl;
CONST  TransWarnings_FileName   = 'FXTranWr.FIL';


{SQL

SET TRUENULLCREATE=OFF#
CREATE TABLE Trans_Warnings IN DICTIONARY USING 'FXTRANWR.FIL'
(
MC_ID            USMALLINT,
Serial_No        INTEGER,
Reserved1        UTINYINT,
Warning          CHAR(160),
SrcConcessionNo  INTEGER,
Reserved         BINARY(16)
)#
CREATE NOT MODIFIABLE INDEX ById IN DICTIONARY ON
 Trans_Warnings(MC_Id , Serial_No)#
CREATE INDEX BySrcconcess IN DICTIONARY ON
 Trans_Warnings(SrcConcessionNo)#
SET TRUENULLCREATE=ON#
}

TYPE
       PTransWarnRecord = ^TTransWarnRecord;
       TTransWarnRecord = PACKED RECORD
         TRW_Mid            : WORD;                   {0.0}
         TRW_SerialNo       : LONGINT;                {0.1}
         TRW_Warning        : STRING[160];
         TRW_SrcConcessionNo: LONGINT; {concession for using source}
         TRW_Free           : ARRAY[1..16] OF BYTE;
       END;

    PTransWarnFile = ^TTransWarnFile;
    TTransWarnFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord(VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;

VAR TransWarnFile : PTransWarnFile;     { File Object Instance Pointer }

IMPLEMENTATION



PROCEDURE  TTransWarnFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TTransWarnRecord),#0);
 WITH TTransWarnRecord(RecBuff) DO
  BEGIN
   TRW_Warning := Space_String;
  END;
END;

FUNCTION TTransWarnFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
    DummyRec: TTransWarnRecord;
BEGIN
 SegC := 0;
 WITH FileSpec, DummyRec DO
  BEGIN
   Rec_Len   := SizeOf(DummyRec);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 Machine ID}
   INC(SegC,Set_Key(Key_Buf[0],BFieldPos(DummyRec, TRW_Mid),
                    SizeOf(TRW_mid),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_UNSIGNED_BIN,0));
   {0.1 Run Number}
   INC(SegC,Set_Key(Key_Buf[1],BFieldPos(DummyRec, TRW_SerialNo),
                    SizeOf(TRW_SerialNo),K_EXTTYPE OR K_DUPLICATE,
                    EKT_INTEGER,0));

   {1.0  SrcConcessionNo}
   INC(SegC,Set_Key(Key_Buf[2],BFieldPos(DummyRec, TRW_SrcConcessionNo),
                    SizeOf(TRW_SrcConcessionNo),
                    K_EXTTYPE OR K_MODIFIABLE OR K_DUPLICATE,
                    EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

END.
