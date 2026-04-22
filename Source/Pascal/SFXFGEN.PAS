(****************************************************************************
*  UNIT          : FXFGen                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX File Generation                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXFGen;

INTERFACE
USES Crt,FXFILot,FXFNet,FXFUsers,FXCfg,FXFCost,FXFIngr,FXFWork,FxFTrn,FxFRcp,
     F6StdWn1,F6Btrv,FileObj,F6StdUtl,FXFMix,FXDetail,FXFStock,SFXGraph,
     SFXComms,F6StdCtv,FxfIni;

FUNCTION  SystemInit: BOOLEAN;
PROCEDURE SystemDone;
FUNCTION  SystemConfigInit : BOOLEAN;

PROCEDURE OpenAllFiles;
PROCEDURE CloseAllFilesIfPossible;
PROCEDURE CloseAllFiles;

IMPLEMENTATION
VAR
    AllFilesOpen     : BOOLEAN;

PROCEDURE ConfigInit;
BEGIN
 Load_Config_Rec;
END;

PROCEDURE OpenAllFiles;
BEGIN
{Open All The Files}
 StockFile^.OpenFile;
 WorkHeaderFile^.OpenFile;
 WorkLineFIle^.OpenFile;
 RecipeHeaderFile^.OpenFile;
 IngredientFile^.OpenFile;
 LotIngredientFile^.OpenFile;
 TransFile^.OpenFile;
 NetFile^.OpenFile;
 UserFile^.OpenFile;
 CostFile^.OpenFile;
 MixStatusFile^.OpenFile;
 AllFilesOpen := TRUE;
END;

{Close Back To Front From Above}
PROCEDURE CloseAllFiles;
BEGIN
 MixStatusFile^.CloseFile;
 CostFile^.CloseFile;
 UserFile^.CloseFile;
 NetFile^.CloseFile;
 TransFile^.CloseFile;
 LotIngredientFile^.CloseFile;
 IngredientFile^.CloseFile;
 RecipeHeaderFile^.CloseFile;
 WorkLineFIle^.CloseFile;
 WorkHeaderFile^.CloseFile;
 StockFile^.CloseFile;
END;

PROCEDURE NullFileHandles;
BEGIN
 IngredientFile     := NIL;
 WorkHeaderFile     := NIL;
 StockFile          := NIL;
 WorkLineFile       := NIL;
 TransFile          := NIL;
 RecipeHeaderFile   := NIL;
 RecipeLineFile     := NIL;
 LotIngredientFile  := NIL;
 NetFile            := NIL;
 CostFile           := NIL;
 UserFile           := NIL;
 MixStatusFile      := NIL;
END;

PROCEDURE DisposeOfFile(TheFile : PBtrvFileObject);
BEGIN
 IF Assigned(TheFile) THEN Dispose(TheFile,Done);
END;


PROCEDURE DisposeFileHandles;
BEGIN
 DisposeOfFile(IngredientFile);
 DisposeOfFile(WorkHeaderFile);
 DisposeOfFile(StockFile);
 DisposeOfFile(WorkLineFile);
 DisposeOfFile(TransFile);
 DisposeOfFile(RecipeHeaderFile);
 DisposeOfFile(RecipeLineFile);
 DisposeOfFile(LotIngredientFile);
 DisposeOFFile(NetFile);
 DisposeOfFIle(UserFile);
 DisposeOfFile(CostFile);
 DisposeOfFile(MixStatusFile);
 NullFileHandles;
END;

PROCEDURE CloseAllFilesIfPossible;
BEGIN
 IF NOT AllFilesOpen THEN EXIT;
 DisposeFileHandles;
 AllFilesOpen := FALSE;
END;


FUNCTION AllocateFileHandles : BOOLEAN;
VAR ErrorOccured : BOOLEAN;

 FUNCTION AssignFile(BtrvFile : PBtrvFileObject) : PBtrvFileObject;
 BEGIN
  IF BtrvFile = NIL THEN ErrorOccured := TRUE;
  AssignFile := BtrvFile;
 END;

BEGIN
  AllocateFileHandles := FALSE;
  { Ingredient File }
  New(IngredientFile,Init(Config_Rec^.Conf_SFPath+ Ingredient_File_Name));
  IF NOT Assigned(IngredientFile) THEN Exit;
  { Works Order Header File }
  New(WorkHeaderFile,Init(Config_Rec^.Conf_FPath + WOHeader_File_Name));
  IF NOT Assigned(WorkHeaderFile) THEN Exit;
  { Stock File }
{  AssignFile(New(PStockFile,Init(Config_Rec^.Conf_FPath + Stock_FileName)));}
  New(StockFile,Init(Config_Rec^.Conf_FPath + Stock_FileName));
  IF NOT Assigned(StockFile) THEN EXIT;
  { Works Order Line File }
  New(WorkLineFile  ,Init(Config_Rec^.Conf_FPath + WOLine_File_Name));
  IF NOT Assigned(WorkLineFile)   THEN Exit;
  {Transaction File}
  New(TransFile     ,Init(Config_Rec^.Conf_FPath + Transaction_FileName));
  IF NOT Assigned(TransFile)      THEN Exit;
  {Recipe Header File}
  NEW(RecipeHeaderFile,Init(Config_Rec^.Conf_FPath+Recipe_Header_FileName));
  IF NOT Assigned(TransFile)      THEN Exit;
  {Lot/Ingredient File}
  New(LotIngredientFile,Init(Config_Rec^.Conf_FPath+LI_FileName));
  IF NOT Assigned(LotIngredientFile) THEN EXIT;
  {Net Ingreident Usage FIle}
  New(NetFile,Init(Config_Rec^.conf_FPath+NetPack_FileName));
  IF NOT Assigned(NetFile) THEN EXIT;
  {User access File}
  New(UserFile,Init(Config_Rec^.Conf_FPath+User_FileName));
  IF NOT Assigned(UserFile) THEN EXIT;
  {Ingreidnet/Lot Costing File}
  New(CostFile,Init(Config_Rec^.Conf_FPath+Cost_FileName));
  IF NOT Assigned(CostFile) THEN EXIT;

  New(MixStatusfile,Init(Config_Rec^.Conf_FPath+MixStatus_FileName));
  IF NOT Assigned(MixStatusFile) THEN EXIT;
  AllocateFileHandles := TRUE;
END;

FUNCTION Init_Files : BOOLEAN;
VAR Result : BOOLEAN;


 FUNCTION CheckFiles : BOOLEAN;
 BEGIN
  CheckFiles := FALSE;
  IF IngredientFile^.CheckIfThere   ('Ingredients')    <> 0 THEN Exit;
  IF WorkHeaderFile^.CheckIfThere   ('Order Header')   <> 0 THEN Exit;
  IF StockFile^.CheckIfThere        ('Stock File')     <> 0 THEN EXIT;
  IF WorkLineFile^.CheckIfThere     ('Order Line')     <> 0 THEN Exit;
  IF TransFile^.CheckIfThere        ('Transaction')    <> 0 THEN Exit;
  IF RecipeHeaderFile^.CheckIfThere ('Recipe Header')  <> 0 THEN Exit;
  IF NetFile^.CheckIfTHere          ('Ingredient Use') <> 0 THEN EXIT;
  IF LotIngredientFile^.CheckIfThere('Lot/Ingredient') <> 0 THEN EXIT;
  IF UserFile^.CheckIfThere         ('User')           <> 0 THEN EXIT;
  IF CostFIle^.CheckIfThere         ('Cost')           <> 0 THEN EXIT;
  IF MixStatusFile^.CheckIfThere    ('Mix Status')     <> 0 THEN EXIT;
  CheckFiles := TRUE;
 END;

BEGIN
 NullFileHandles;
 Result := AllocateFileHandles;
 IF Result THEN Result := CheckFiles;
 IF Result THEN
  BEGIN
   MoveToXY(1,48);
   WriteStr('All Files Complete                     ');
  END
 ELSE DisposeFileHandles;

 Init_Files := Result;
END;

FUNCTION GetBtrvVersion : BOOLEAN;
TYPE BtrvVersionInfo = PACKED RECORD
       MajorVersion : WORD;
       MinorVersion : WORD;
       OSType       : CHAR;
     END;
VAR DataBuffer : BtrvVersionInfo;
    DataLength : INTEGER;
    BtrvErr    : INTEGER;
    Temp       : LONGINT;
    TempPBlock : ARRAY[0..127] OF BYTE;
BEGIN
 {MoveToXy(0,0);}
 DataLength := SizeOf(DataBuffer);
 BtrvErr := Btrv(26,TempPBlock,DataBuffer,DataLength,Temp,0,0);
 IF BtrvErr = 20 THEN
  BEGIN
   GetBtrvVersion := FALSE;
   Disp_Error_Msg('Error Btrieve Record Manager Has Not Been Loaded');
   EXIT;
  END;
 WITH DataBuffer DO
  WriteStrAt(1,46,'Btrieve Record Manager Version '+IntToStr(MajorVersion,1)+'.'+IntToStr(MinorVersion,1));
 GetBtrvVersion := TRUE;
END;


FUNCTION SystemConfigInit  : BOOLEAN;
BEGIN
 SystemConfigInit := FALSE;
 IF NOT Allocate_Config_Rec THEN
  BEGIN
   Disp_Error_Msg('Unable To Continue - Due To Low Memory');
   EXIT;
  END;
 ConfigInit;
 SystemConfigInit := TRUE;
END;



FUNCTION SystemInit : BOOLEAN;
VAR ErrInt,i    : INTEGER;
BEGIN
 SystemInit := FALSE;
 UnlockH := 0; UnlockM := 0; UnlockY := 0; UnlockMo := 0; UnlockD := 0;
{$IFDEF DPMI}
 IF SetUpDPMIBtrvMem(4096) <> 0 THEN
  BEGIN
   Show_Btrv_Err(BMemError);
   EXIT;
  END;
{$ENDIF}
 IF NOT GetBtrvVersion THEN EXIT;{Used to test that btrieve has been loaded}
 WriteStrAt(1,50,'Using INI File '+FOPS6INI_VAR);
 IF (NOT Init_Files)
{$IFNDEF NOCOMMS}
  OR (NOT CheckParamFile)
{$ENDIF}
  THEN
  BEGIN
   Disp_Error_Msg('Unable To Continue - Database Incomplete');
   EXIT;
  END;
{$IFNDEF NOCOMMS}
 GetParameters;
{$ENDIF}
 SystemInit := TRUE;
END;

PROCEDURE SystemDone;
BEGIN
 Dispose_Config_Rec;
 CloseAllFilesIfPossible;
{$IFDEF DPMI}
 FreeDPMIBtrvMem;
{$ENDIF}
END;


END.
