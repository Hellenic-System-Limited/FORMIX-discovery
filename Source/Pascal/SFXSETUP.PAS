UNIT SFXSetUp;
{$O+,F+}
{$I F6COMP}
INTERFACE
USES F6StdCtv,F6StdWn1,F6StdUtl,FXModCtv,FXFMix,SFXBtn,SFXGraph,SFXWin,
     SFXFont,SFXKbd,SFXStd,SFXConst,SFXEdit,FXDetail,FXChoice,SFXTList,
     SFXUtils,FxStdUt1,SFXMsg,SFXList,SFXTiket,SFXCurr;

PROCEDURE RunSetUp;
PROCEDURE EditGlobalBatchAndLotNo;

IMPLEMENTATION

PROCEDURE RunSetUp;
CONST TextCol1 = 30;
      TextCol2 = 70;

VAR HoldFont : PFontType;
    SelWin   : PEditScreen;
    CurrentRN: LONGINT;
    CurrentMI: WORD;
    AskForLB : BOOLEAN;
    DisKey   : BOOLEAN;
    PassWord : PassWordStr;
    UseLotNo : BOOLEAN;
    WrkGrpFilter : TWorkGrp;
    AllowManWts : BOOLEAN;

 PROCEDURE WriteStaticText;
 CONST FL_MID = 2; YP_MID = 07;
       FL_RUN = 6; YP_RUN = 12;
       FL_ELB = 1; YP_ELB = 17;
       FL_DKI = 1; YP_DKI = 22;
       FL_ULN = 1; YP_ULN = 07;
       FL_WGR = 3; YP_WGR = 12;
       FL_MWT = 1; YP_MWT = 17;

 VAR E : PEdit;
 BEGIN
  CurrentMI := GetCurrentMachineID;
  CurrentRN := GetCurrentRunNumber;
  AskForLB  := ShouldUserBePromptedForLotBatch;
  DisKey    := DisregardKeyIngredient;
  UseLotNo  := LotNumbersReqd;
  WrkGrpFilter := GetWorkGroupFilter;
  AllowManWts  := GetManWtTickBox;
  New(E,Init(2,YP_MID,TextCol1-FL_MID,StdEdit,SelWin,'Machine ID :'              ,et_integer ,FL_MID,CurrentMI));
  New(E,Init(2,YP_RUN,TextCol1-FL_RUN,StdEdit,SelWin,'Run Number :'              ,et_long    ,FL_RUN,CurrentRN));
  New(E,Init(2,YP_ELB,TextCol1-FL_ELB,StdEdit,SelWin,'Enquire For Lot/Batch No :',et_checkbox,FL_ELB,AskForLB));
  New(E,Init(2,YP_DKI,TextCol1-FL_DKI,StdEdit,SelWin,'Disregard Key Ingredient :',et_checkbox,FL_DKI,DisKey));
  { New Column }
  New(E,Init(TextCol2-TextCol1,YP_ULN,TextCol2-FL_ULN,StdEdit,SelWin,
             'Lot Numbers Required:',et_checkbox,FL_ULN,UseLotNo));
  New(E,Init(TextCol2-TextCol1,YP_WGR,TextCol2-FL_WGR,StdEdit,SelWin,
             'Work Group Filter :',et_AnyCharStr,FL_WGR,WrkGrpFilter));
  New(E,Init(TextCol2-TextCol1,YP_MWT,TextCol2-FL_MWT,StdEdit,SelWin,
             'Allow Manual Weights :',et_checkbox,FL_MWT,AllowManWts));
 END;

 PROCEDURE SaveChanges;
 BEGIN
  SetCurrentMachineID(CurrentMI);
  SetCurrentRunNumber(CurrentRN);
  SetPromptForLotBatch(AskForLB);
  SetDisregardKeyIngredient(DisKey);
  SetLotOptions(UseLotNo);
  SetWorkGroupFilter(WrkGrpFilter);
  IF NOT Str_Equal(WrkGrpFilter,CurrentWorkGroup,Length(WrkGrpFilter)) THEN
    CurrentWorkGroup := WrkGrpFilter;
  SetManWtTickBox(AllowManWts);
 END;

BEGIN
 ClrGraphWin;
 New(SelWin,Init);
 WriteStaticText;
 SelWin^.MainLoop;
 IF SelWin^.OptionSelected = idSave THEN SaveChanges;
 Dispose(SelWin,Done);
 ClrGraphWin;
END;


PROCEDURE EditGlobalBatchAndLotNo;
CONST TextCol1 = 30;
      TextCol2 = 70;
VAR
    SelWin   : PEditScreen;
    BatchEdit: TBatchRef;
    LotEdit  : TLotRef;

 PROCEDURE WriteStaticText;
 VAR
     E : PEdit;
 BEGIN
  New(E,Init(1,6,TextCol1-6,StdEdit,SelWin, 'Global Batch No.:',et_string,6,BatchEdit));
  New(E,init(1,12,TextCol1-8,StdEdit,SelWin,'Global Lot No.  :',et_string,8,LotEdit));
 END;

 PROCEDURE SaveChanges;
 BEGIN
  GlobalBatchNumber := BatchEdit;
  GlobalLotNumber   := LotEdit;
 END;

 PROCEDURE Init;
 BEGIN
  BatchEdit := GlobalBatchNumber;
  LotEdit   := GlobalLotNumber;
 END;

BEGIN
 Init;
 ClrGraphWin;
 New(SelWin,Init);
 WriteStaticText;
 SelWin^.MainLoop;
 IF SelWin^.OptionSelected = idSave THEN SaveChanges;
 Dispose(SelWin,Done);
 ClrGraphWin;
END;

END.