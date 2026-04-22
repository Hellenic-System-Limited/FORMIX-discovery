(****************************************************************************
*  UNIT          : FXFGen                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX File Generation                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFGen;

INTERFACE

USES Crt,Dos,FileObj,FXModCtv,F6StdCtv,F6StdUtl,F6StdWin,F6StdWn1,FxFStock,
     F6LokOut,F6Btrv,FX_Msg,FXTime,FXFINI,FXCfg,FXFIngr,FXFWork,FXFTrn,FxFRcp,
     FXExit,FXFILot,FXFProd,FXFNet,FXFUsers,FXFCost,FXFMacro,FXFMix,FXFSerNo,
     FXFSrc,FXFTrnW;

PROCEDURE Init_System;
PROCEDURE System_Shutdown;
PROCEDURE FillScreen(INST : BOOLEAN);

VAR ResetTranBrowser : BOOLEAN;
    ResetWOBrowser : BOOLEAN;
IMPLEMENTATION

PROCEDURE Init_Config;
VAR  MenuTest : FILE;
BEGIN
 Load_Config_Rec;
 WITH Config_Rec^ DO
  BEGIN
   IF CONF_FPath = CONF_TPath THEN
    BEGIN
     WriteLn('The following settings need to be defined in section [MAIN] of an INI file:-');
     WriteLn('FXFILEPATH');
     WriteLn('FXTEXTPATH');
     WriteLn('FXARCPATH');
     WriteLn('FXRAMPATH');
     WriteLn;
     Writeln('Default INI file = FORMIX.INI');
     Writeln('To override settings in default INI file, define FORMIXINI on the command line.');
     WriteLn('Acceptable command line parameters:-');
     Writeln('  FORMIXINI=filename.INI');
     WriteLn('  FORMIXINI=filenameNoExtn');
     Exit_System(0);
    END;
   MENU_NAME   := GetUpCaseExtVar(FXMenuFileName,all);
   IF (NowtButSpace(MENU_NAME)) THEN MENU_NAME := 'MENU.FMU';
   MENU_NAME   := Conf_TPath+MENU_NAME;
   Assign(MenuTest,MENU_NAME);
   {$I-}
   Reset(MenuTest);
   {$I+}
   IF IoResult <> 0 THEN
    BEGIN
     WriteLn('ERROR - Menu File Not Found');
     WriteLn;
     Exit_System(0);
    END;
   Close(MenuTest);
  END;
END;


{NB IF New Fails Then The Program Will Run Time Error}
FUNCTION AllocateFileHandles : BOOLEAN;
BEGIN
  AllocateFileHandles := FALSE;
  WITH Config_Rec^ DO
   BEGIN
    { Ingredient File }
    New(IngredientFile,Init(Conf_SFPath+Ingredient_File_Name));
    IF NOT Assigned(IngredientFile) THEN Exit;
    {Transaction File }
    New(TransFile,Init(Conf_FPath+Transaction_FileName));
    IF NOT Assigned(TransFile) THEN Exit;
    New(TransWarnFile,Init(Conf_FPath+TransWarnings_FileName));
    IF NOT Assigned(TransWarnFile) THEN Exit;
    { Works Order Header File }
    New(WorkHeaderFile,Init(Conf_FPath + WOHeader_File_Name));
    IF NOT Assigned(WorkHeaderFile) THEN Exit;
    { Works Order Line File }
    New(WorkLineFile  ,Init(Conf_FPath + WOLine_File_Name));
    IF NOT Assigned(WorkLineFile)   THEN Exit;
    { Recipe Header File }
    New(RecipeHeaderFile,Init(Conf_FPath + Recipe_Header_FileName));
    IF NOT Assigned(RecipeHeaderFile) THEN EXIT;
    { Recipe Line File   }
    New(RecipeLineFile,Init(Conf_FPath + Recipe_Line_FileName));
    IF NOT Assigned(RecipeLineFile) THEN EXIT;
    { Lot / Ingredient Reference File }
    New(LotIngredientFile,Init(Config_Rec^.Conf_FPath+LI_FileName));
    IF NOT Assigned(LotIngredientFile) THEN EXIT;
    { Product Header File }
    New(ProdHeaderFile,Init(Conf_FPath + Product_Header_FileName));
    IF NOT Assigned(ProdHeaderFile) THEN EXIT;
    { Product Line File }
    New(ProdLineFile,Init(Conf_FPath+Product_Line_FileName));
    IF NOT Assigned(ProdLineFile) THEN EXIT;
    { Product Cooking Method File }
    New(ProdDescFile,Init(Conf_FPath+Product_Desc_FileName));
    IF NOT Assigned(ProdDescFile) THEN EXIT;
    { Product Order Schedule }
    New(ProdOrderFile,Init(Conf_FPath+Product_Order_FileName));
    IF NOT Assigned(ProdOrderFile) THEN EXIT;
    { Ingredient Usage Totals File }
    New(NetFile,Init(Conf_FPath+NetPack_FileName));
    IF NOT Assigned(NetFile) THEN EXIT;
    { User ID File }
    New(UserFile,Init(Conf_FPath+User_FileName));
    IF NOT Assigned(UserFile) THEN EXIT;
    {Ingredient/Lot Cost File}
    New(CostFile,Init(Conf_FPath+Cost_FileName));
    IF NOT Assigned(CostFile) THEN EXIT;
    New(RepMacroFile,Init(Conf_SFPath+RepMacro_FileName));
    IF NOT Assigned(RepMacroFile) THEN EXIT;
    New(MacroHeaderFile,Init(Conf_SFPath+MacroHeader_FileName));
    IF NOT Assigned(MacroHeaderFile) THEN EXIT;
    New(MacroLineFile,Init(Conf_SFPath+MacroLine_FileName));
    IF NOT Assigned(MacroLineFile) THEN EXIT;
    New(MixStatusFile,init(Conf_FPath+MixStatus_FileName));
    IF NOT Assigned(MixStatusFile) THEN EXIT;
    New(StockFile,Init(Conf_FPath+Stock_FileName));
    IF NOT Assigned(StockFile) THEN EXIT;
    New(SerialNoFile,Init(Conf_FPath+SerialNoFileName));
    IF NOT Assigned(SerialNoFile) THEN EXIT;
    New(SourceCodeFile,Init(Conf_FPath+SourceCode_FileName));
    IF NOT Assigned(SourceCodeFile) THEN EXIT;
   END;
  AllocateFileHandles := TRUE;
END;

PROCEDURE DisposeOfFile(TheFile : PBtrvFileObject);
BEGIN
 IF Assigned(TheFile) THEN Dispose(TheFile,Done);
END;

PROCEDURE NullFileHandles;
BEGIN
 IngredientFile     := NIL;
 WorkHeaderFile     := NIL;
 WorkLineFile       := NIL;
 TransFile          := NIL;
 TransWarnFile      := NIL;
 RecipeHeaderFile   := NIL;
 RecipeLineFile     := NIL;
 LotIngredientFile  := NIL;
 ProdHeaderFile     := NIL;
 ProdLineFile       := NIL;
 ProdDescFile       := NIL;
 ProdOrderFile      := NIL;
 NetFile            := NIL;
 UserFile           := NIL;
 CostFile           := NIL;
 RepMacroFile       := NIL;
 MacroHeaderFile    := NIL;
 MacroLineFile      := NIL;
 MixStatusFile      := NIL;
 StockFile          := NIL;
 SerialNoFile       := NIL;
 SourceCodeFile     := NIL;
END;


PROCEDURE DisposeFileHandles;
BEGIN
 DisposeOfFile(IngredientFile);
 DisposeOfFile(WorkHeaderFile);
 DisposeOfFile(WorkLineFile);
 DisposeOfFile(TransFile);
 DisposeOfFile(TransWarnFile);
 DisposeOfFile(RecipeHeaderFile);
 DisposeOfFile(RecipeLineFile);
 DisposeOfFile(LotIngredientFile);
 DisposeOfFile(ProdHeaderFile);
 DisposeOfFile(ProdLineFile);
 DisposeOfFile(ProdDescFile);
 DisposeOfFile(ProdOrderFile);
 DisposeOfFile(NetFile);
 DisposeOfFile(UserFile);
 DisposeOfFile(CostFile);
 DisposeOfFile(RepMacroFile);
 DisposeOfFile(MacroHeaderFile);
 DisposeOfFile(MacroLineFile);
 DisposeOfFile(MixStatusFile);
 DisposeOfFile(StockFile);
 DisposeOfFile(SerialNoFile);
 DisposeOfFile(SourceCodeFile);
 NullFileHandles;
END;


FUNCTION Init_Files : BOOLEAN;
VAR Result : BOOLEAN;

 FUNCTION CheckFiles : BOOLEAN;
 BEGIN
  CheckFiles := FALSE;
  IF IngredientFile^.CheckIfThere   ('Ingredients')    <> 0 THEN Exit;
  IF WorkHeaderFile^.CheckIfThere   ('Order Header')   <> 0 THEN Exit;
  IF WorkLineFile^.CheckIfThere     ('Order Line')     <> 0 THEN Exit;
  IF TransFile^.CheckIfThere        ('Transaction')    <> 0 THEN Exit;
  IF TransWarnFile^.CheckIfThere    ('Trans. Warning') <> 0 THEN Exit;
  IF RecipeHeaderFile^.CheckIfThere ('Recipe Header')  <> 0 THEN Exit;
  IF RecipeLineFile^.CheckIfThere   ('Recipe Line')    <> 0 THEN Exit;
  IF ProdHeaderFile^.CheckIfThere   ('Product Header') <> 0 THEN EXIT;
  IF ProdLineFile^.CheckIfThere     ('Product Line')   <> 0 THEN EXIT;
  IF ProdDescFile^.CheckIfThere     ('Product Desc')   <> 0 THEN EXIT;
  IF ProdOrderFile^.CheckIfThere    ('Product Order')  <> 0 THEN EXIT;
  IF NetFile^.CheckIfThere          ('Ingredient Use') <> 0 THEN EXIT;
  IF LotIngredientFile^.CheckIfThere('Lot/Ingredient') <> 0 THEN EXIT;
  IF UserFile^.CheckIfThere         ('User')           <> 0 THEN EXIT;
  IF CostFile^.CheckIfThere         ('Cost')           <> 0 THEN EXIT;
  IF RepMacroFile^.CheckIfThere     ('Report Macro')   <> 0 THEN EXIT;
  IF MacroHeaderFile^.CheckIfThere  ('Macro Header')   <> 0 THEN EXIT;
  IF MacroLineFile^.CheckIfThere    ('Macro Line')     <> 0 THEN EXIT;
  IF MixStatusFile^.CheckIfThere    ('Mix Status')     <> 0 THEN EXIT;
  IF StockFile^.CheckIfThere        ('Stock File')     <> 0 THEN EXIT;
  IF SerialNoFile^.CheckIfThere     ('Serial No.')     <> 0 THEN EXIT;
  IF SourceCodeFile^.CheckIfThere   ('Source Code')    <> 0 THEN EXIT;
  CheckFiles := TRUE;
 END;

BEGIN
 CursorOff;
 NullFileHandles;
 Result := AllocateFileHandles;
 IF Result THEN Result := CheckFiles;
 IF Result THEN
  BEGIN
   GotoXY(1,WhereY); ClrEol;
   Write('All Files Complete');
  END
 ELSE DisposeFileHandles;

 Init_Files := Result;
 WriteLn;
 CursorOn;
END;


PROCEDURE FillScreen(INST : BOOLEAN);
VAR Loop  : INTEGER;
    FChar : BYTE;
    Lstr  : STRING;
    i : INTEGER;
BEGIN
{$IFDEF WINDOWS}
 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(178);
 FOR Loop := 1 to 4 DO
   WriteDirectAt(1,Loop,Lstr);
 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(177);
 FOR Loop := 5 to 8 DO
   WriteDirectAt(1,Loop,Lstr);
 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(176);
 FOR Loop := 9 to 12 DO
   WriteDirectAt(1,Loop,Lstr);

 WriteDirectAt(1,13,COPY(SPACE_STRING,1,80));

 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(176);
 FOR Loop := 14 to 17 DO
   WriteDirectAt(1,Loop,Lstr);

 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(177);
 FOR Loop := 18 to 21 DO
   WriteDirectAt(1,Loop,Lstr);

 LStr := '';
 FOR i:= 1 to 80 do Lstr := LStr+CHR(178);
 FOR Loop := 22 to 24 DO
   WriteDirectAt(1,Loop,LStr);

 WriteDirectAt(1,25,COPY(SPACE_STRING,1,80));

{$ELSE}
 FChar := 179;
 Loop  := 0;
 WHILE (Loop <=1919) DO
  BEGIN
   IF (Loop MOD 640) = 0 THEN DEC (FChar);
   scrn_ptr^[Loop] := FChar;
   INC(Loop,2);
  END;

 Loop := 1920;
 WHILE (Loop<=2079) DO
  BEGIN
   Scrn_ptr^[Loop] := 32;
   INC(Loop,2);
  END;

 FChar := 175;
 Loop  := 2080;
 WHILE (Loop <=3838) DO
  BEGIN
   IF ((Loop-2080) MOD 640) = 0 THEN INC (FChar);
   scrn_ptr^[Loop] := FChar;
   INC(Loop,2);
  END;
{$ENDIF}

 IF INST THEN
  BEGIN
{$IFDEF WINDOWS}
   WriteDirectAt(1,1,COPY(SPACE_STRING,1,80));
{$ELSE}
   Loop := 0;
   WHILE (Loop<160) DO
    BEGIN
     scrn_ptr^[Loop] := 32;
     scrn_ptr^[Loop+24*160+1] :=7*16+15;
     INC(Loop,2);
    END;
{$ENDIF}
   TextBackGround(WHITE);
   TextColor(WHITE);
   WriteAt(1,25,'Formix2 Recipe Weighing System V'+VERSION_NUMBER+'   (c) '+COPYRIGHT);
   TextColor(BLACK);
   FillChar (lstr,51,#205);
   lstr[0] := CHR(50);
   WriteAt(16, 6,lstr);
   WriteAt(16, 8,lstr);
   WriteAt(16,19,lstr);
   FOR Loop := 7 TO 18 DO
    BEGIN
     WriteAT(15,Loop,#186);
     WriteAT(66,Loop,#186);
    END;
   WriteAt(15,06,#201); WriteAt(66,06,#187);
   WriteAt(15,08,#204); WriteAt(66,08,#185);
   WriteAt(15,19,#200); WriteAt(66,19,#188);
   WriteAt (16,07,'                                                  ');
   WriteAt (16,09,'                 Menu Bar Keys                    ');
   WriteAt (16,10,'  E,O,R,M,U,Q+ Alt   to directly select a menu    ');
   WriteAt (16,11,' '+CU_L_KEY+' & '+CU_R_KEY+'         to move cursor to menu       ');
   WriteAt (16,12,' '+NEXT_KEY+'  & '+ENTER_KEY+'          to select highlighted menu   ');
   WriteAt (16,13,'                                                 ');
   WriteAt (16,14,'               Menu Option Keys                   ');
   WriteAt (16,15,'  A to Z             to directly select a menu    ');
   WriteAt (16,16,' '+NEXT_KEY+' & '+PREV_KEY+'           to move cursor to option     ');
   WriteAt (16,17,'  '+ENTER_KEY+'                to select highlighted option ');
   Writeat (16,18,' Press  ALT + H while using an option to get help ');
{$IFNDEF WINDOWS}
   {Shadow Instructions - isn't a window to save memory}
   Loop := 2913+160;
   WHILE (Loop <=(3011+160)) DO
    BEGIN
     scrn_ptr^[Loop] := (16*Black) + DarkGray;
     INC(Loop,2);
    END;

   Loop := 1093;
   WHILE (Loop <(3013+320)) DO
    BEGIN
     scrn_ptr^[Loop]   := (16*Black) + DarkGray;
     scrn_ptr^[Loop+2] := (16*Black) + DarkGray;
     INC(Loop,160);
    END;
{$ENDIF}
  END;
END;


PROCEDURE Init_System;
VAR ErrInt,i    : INTEGER;
    NewRange    : STRING[1];
BEGIN
 FILEOBJ.BTRV_ERROR_AUTO_DISP_SET := [
                 berr_Lost,       { GetNext is lost in a duplicate key.}
                 berr_InvalidSpec,{ invalid parameters in create call }
                 berr_InvalidOp,  { btrieve call was invalid }
                 berr_Critical];  { Record manager configuration error,
				      or fault or server fault }
 Win_Init;
 CheckSnow := FALSE;
 StopProcess := FALSE;
 UnlockH := 0; UnlockM := 0; UnlockY := 0; UnlockMo := 0; UnlockD := 0;
 IF NOT Allocate_Config_Rec THEN
  BEGIN
   Disp_Error_Msg('Unable To Continue - Due To Low Memory');
   Exit_System(0);
  END;
 Init_Config;
{$IFDEF DPMI}
 IF SetUpDPMIBtrvMem(4096) <> 0 THEN
  BEGIN
   Show_Btrv_Err(BMemError);
   Exit_System(0);
  END;
{$ENDIF}
{$IFDEF MULTIPASSWORD}
 BuildMenuList;
{$ENDIF}
 IF NOT Init_Files THEN
  BEGIN
   Disp_Error_Msg('Unable To Continue - Database Incomplete');
   Exit_System(0);
  END;
 (* Check Factory *)

 Set_Colours(LightGray,White,Yellow,Green,Red);
 ClrScr;
 PROP_CommsProc := Disptime;
 MsgInit;
 BuildMenuList;
END;

PROCEDURE System_Shutdown;
BEGIN
 DisposeFileHandles;
END;

END.
