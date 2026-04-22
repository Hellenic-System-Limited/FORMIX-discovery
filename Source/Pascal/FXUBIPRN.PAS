(****************************************************************************
*  UNIT          : FXUBIPRN                                                 *
*  AUTHOR        :                                                          *
*  DATE          :                                                          *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXUBIPRN;
INTERFACE

USES Crt,F6StdCtv,F6StdUtl,FXFTRN,SFXStd,FXDetail,FXFIni,FXFWork,
     SFXCONST,F6DtConv,SFXTlist,SFXBAS,FXFMix,SFXPORTS,F6STDWN1,FXModCtv,
     FXFUsers;

PROCEDURE Print_UBI_Ticket(TranRec : PTranRecord;
                           OrdHRec : PWOHeaderRecord;
                           OrdLRec : PWOLineRecord);

PROCEDURE Print_UBI_Mix_Total_Ticket(OrdHRec : PWOHeaderRecord;
                                     CurrentMixBatchStr: TBatchRef;
                                     PrintAllDetails   : BOOLEAN);

IMPLEMENTATION
USES FXUBIPTR;

TYPE TagType = PACKED RECORD
      Name : STRING[15];
      ID   : INTEGER;
     END;

CONST NumSingleTags  = 18;
CONST SingleTags : ARRAY [1..NumSingleTags] OF TagType =
      ((Name:'*ORDERNO'       ;ID: 1),
       (Name:'*INGREDIENTREF' ;ID: 2),
       (Name:'*TICKET'        ;ID: 3),
       (Name:'*TOTWEIGHT'     ;ID: 4),
       (Name:'*USER'          ;ID: 5),
       (Name:'*BATCHNO'       ;ID: 6),
       (Name:'*LOTNO'         ;ID: 7),
       (Name:'*RECIPENO'      ;ID: 8),
       (Name:'*DATE'          ;ID: 9),
       (Name:'*TIME'          ;ID:10),
       (Name:'*MIXNO'         ;ID:11),
       (Name:'*CONTAINERNO'   ;ID:12),
       (Name:'*MIXCOMPLETE'   ;ID:13),
       (Name:'*MIXRANGE'      ;ID:14),
       (Name:'*CONTRANGE'     ;ID:15),
       (Name:'*TEXT1'         ;ID:16),
       (Name:'*TEXT2'         ;ID:17),
       (Name:'*RECIPENAME'    ;ID:18));


  FUNCTION CompTag(VAR SourceTag,CompareTag : STRING) : BOOLEAN;
  BEGIN
   CompTag := StringLIComp(SourceTag,CompareTag,Length(CompareTag)) = 0;
    {COPY(SourceTag,1,Length(CompareTag)) = CompareTag;}
  END;

  { Get Array Position of Tag that Matches Label List Item}
  { From SingleTags Array                                 }
  FUNCTION FindSingleTagNumber(VAR SourceTag : STRING): INTEGER;
  VAR TagID : BYTE;
  BEGIN
   FindSingleTagNumber := 0;
   FOR TagID := 1 TO NumSingleTags DO
    BEGIN
     IF CompTag(SourceTag,SingleTags[TagID].Name) THEN
      BEGIN
       FindSingleTagNumber := SingleTags[TagID].ID;
       Break;
      END;
    END;
  END;


  FUNCTION GetIsMixComplete(OrdHRec : PWOHeaderRecord) : STRING;
  BEGIN
   IF IsMixComplete(OrdHRec^.WOH_CurrentMix,
                    OrdHRec^.WOH_OrderNo,
                    OrdHRec^.WOH_Revision) THEN
     GetIsMixComplete := 'YES'
   ELSE
     GetIsMixComplete := 'NO';
  END;


  PROCEDURE FillRemainingFields(TranRec : PTranRecord;
                                OrdHRec : PWOHeaderRecord;
                                OrdLRec : PWOLineRecord;
                                CurrMixBatchStr      : TBatchRef;
                                Tickets,TotalTickets : INTEGER);
  VAR LabelItemPtr : PLabelTicketItem;
  BEGIN
   WITH OrdHRec^ DO
    BEGIN
     LabelItemPtr := LabelItemHeader;
     WHILE(LabelItemPtr <> NIL) DO
      BEGIN
       WITH LabelItemPtr^ DO
        BEGIN
      	CASE LTI_Type OF
 	 TextItem : BEGIN
  	  CASE FindSingleTagNumber(LabelItemPtr^.LTI_Tag) OF
	   1 : LTI_OutStr := OrderNoToStr(WOH_OrderNo,WOH_Revision);  { *ORDER   }
	   2 : IF TranRec = NIL THEN LTI_OutStr := SPACE_STRING
               ELSE LTI_OutStr := TranRec^.TRN_Ingredient;          { *INGREDIENT}
           3 : LTI_OutStr := IntToStr(Tickets,1)+'/'+
			     IntToStr(TotalTickets,1);              { *TICKET   }
           4 : IF TranRec = NIL THEN LTI_OutStr := SPACE_STRING
               ELSE LTI_OutStr := DoubleToStr(TranRec^.TRN_ContainerWt,9,3)+'kg';
	   5 : LTI_OutStr := CurrentUser.USR_ID;
           6 : IF TranRec =NIL THEN LTI_OutStr := CurrMixBatchStr
               ELSE LTI_OutStr := TranRec^.TRN_BatchNo;
           7 : IF TranRec = NIL THEN LTI_OutStr := SPACE_STRING
               ELSE LTI_OutStr := TranRec^.TRN_LotNo;
           8 : LTI_OutStr := WOH_RecipeNo;
           9 : IF TranRec = NIL THEN LTI_OutStr := Date
               ELSE LTI_OutStr := Days_To_Date(TranRec^.TRN_Date);
           10: IF TranRec = NIL THEN LTI_OutStr := SPACE_STRING
               ELSE LTI_OutStr := TranRec^.TRN_Time;
           11: LTI_OutStr := IntToZeroStr(WOH_CurrentMix,2);
           12: IF TranRec = NIL THEN LTI_OutStr := SPACE_STRING
               ELSE LTI_OutStr := IntToZeroStr(TranRec^.TRN_ContainerNo,2);
           13: LTI_OutStr := GetIsMixComplete(OrdHRec);
           14: LTI_OutStr := IntToStr(WOH_CurrentMix,2)+' of '+
                               IntToStr(WOH_NumMixes,2);
           15: BEGIN
                IF (TranRec <> NIL) AND (OrdLRec <>NIL) THEN
                  LTI_OutStr := IntToStr(TranRec^.TRN_ContainerNo,2)+' of '+
                        IntToStr(CalcLineWeighingsReqdForCurrMix(OrdHRec,
                                                                 OrdLRec),2)
                ELSE
                  LTI_OutStr := SPACE_STRING;
               END;
           16: IF (OrdLRec <> NIL) THEN
                LTI_OutStr := OrdLRec^.WOL_SpecialInstr[1]
               ELSE
                LTI_OutStr := SPACE_STRING;
           17: IF (OrdLRec <> NIL) THEN
                LTI_OutStr := OrdLRec^.WOL_SpecialInstr[2]
               ELSE
                BEGIN
                  IF NOT (COPY(LTI_Tag,1,15) = '*INGREDIENTINFO') THEN
                   BEGIN
                    LTI_OutStr := SPACE_STRING;
                   END;
                END;
           18: BEGIN   { Recipe Name }
                LTI_OutStr := FXFRCP.GetRecipeName(WOH_RecipeNo);
               END;
	  END;            { END CASE FindSingleTagNumber }
	 END;             { END TextItem                 }

	 BarcodeWithReadable,
	 BarcodeWithoutReadable : BEGIN          { Barcode               }
           IF (OrdHRec <> NIL) THEN
            BEGIN
             LTI_OutStr := OrderMixToBarcode(OrdHRec, GetCurrentMachineID);
             LTI_OutStr := Copy(LTI_OutStr,1,Length(LTI_Tag));
            END;
         END;

        END;                                  { END CASE LTI_Type       }
       END;                                   { END WITH LabelItemPtr   }
       LabelItemPtr := LabelItemPtr^.LTI_Next;{ Adv. To Next Label Item }
      END;                                    { END WHILE LabelItemPtr  }
    END;
  END; { END FillRemainingFields }

  PROCEDURE PlayOutTicket(LabelFormatLetter : CHAR;Tickets,TotalTickets : INTEGER);
  VAR PrinterPort : WORD;
      LabelItemPtr : PLabelTicketItem;
      ErrInt       : INTEGER;
      PStatus      : BYTE;
      ErrorMsg     : STRING;

  PROCEDURE SendToPrinter(SendStr : STRING);
  BEGIN
   IF ScaleConfRec.PrinterType = IPL_Printer THEN
     SendToUBIE4Printer(FALSE,SendStr,PrinterPort)
   ELSE
     SendToUBIPrinter(' '+SendStr,PrinterPort);
  END;


  BEGIN
    PrinterPort := GetTicketPrinterPortAddr;
    IF (PrinterPort > 0) THEN
     BEGIN
      { Send Label Format Selector }
      IF ScaleConfRec.PrinterType = IPL_Printer THEN
       BEGIN

        REPEAT
         ErrorMsg := '';
         PStatus  := 0;
         ErrInt := E4PrinterStatus(PrinterPort,PStatus);
         IF ErrInt <> 0 THEN ErrorMsg := 'Printer is not responding';

         IF (PStatus AND 8) = 8 THEN ErrorMsg := 'Printer out of ribbon';
         IF (PStatus AND 4) = 4 THEN ErrorMsg := 'Printer out of paper';
         IF GetLTSCheckSetting AND ((PStatus AND 2) = 2) THEN
                                     ErrorMsg := 'Label not taken';
         IF (PStatus AND 1) = 1 THEN ErrorMsg := 'Print head lifted';
         IF ErrorMsg <> '' THEN
          BEGIN
           IF NOT YesNoWin(Centered(ErrorMsg,44)+CR+LF+
                           Centered('Retry?',44)) THEN Exit;
          END
         ELSE PStatus := 0; { clear unimportant status }
        UNTIL (ErrInt = 0) AND (PStatus = 0);

        SendToUBIE4Printer(TRUE,'?',PrinterPort);
        SendToUBIE4Printer(TRUE,'CLL:LAYOUT RUN"LF'+LabelFormatLetter+'"',PrinterPort);
        SendToPrinter('INPUT ON');
        WriteByteToPort(PrinterPort,STX,40000);
       END
      ELSE
       BEGIN
        SendToUBIPrinter(' ',PrinterPort);
        SendToUBIPrinter(' SF'+LabelFormatLetter,PrinterPort);
       END;

      LabelItemPtr := LabelItemHeader;
      WHILE(LabelItemPtr <> NIL) DO
       BEGIN
	WITH LabelItemPtr^ DO
         BEGIN
          CASE LTI_Type OF
           TextItem,
           BarcodeWithoutReadable : BEGIN
            SendToPrinter(LTI_OutStr);
           END;

           BarcodeWithReadable : BEGIN
            IF ((Tickets) = TotalTickets) THEN
             BEGIN
              SendToPrinter(LTI_OutStr);
              SendToPrinter(LTI_OutStr);
             END
            ELSE
             BEGIN
              SendToPrinter('');
              SendToPrinter('');
             END;
           END;

          END;                                   { END CASE LTI_Type OF    }
	 END;                                    { END WITH LabelItemPtr }
	LabelItemPtr := LabelItemPtr^.LTI_Next;
       END;                                      { END WHILE LabelItemPtr}
      IF ScaleConfRec.PrinterType = IPL_Printer THEN
       BEGIN
        SendToUBIE4Printer(TRUE,CHR(EOT)+'PF1'+#13+'INPUT OFF',PrinterPort);
       END
      ELSE
       BEGIN
        SendToUbiPrinter(' $END01',PrinterPort);   { Tell Printer To Print   }
       END;
      Delay(2000);
     END;                                        { END IF PrinterPort > 0  }
  END;                                           { END PROC. PlayOutTicket }

PROCEDURE Print_UBI_Ticket(TranRec : PTranRecord;
                           OrdHRec : PWOHeaderRecord;
                           OrdLRec : PWOLineRecord);
VAR
    LabelFormatLetter : STRING[1];            { Label Format Letter         }
    Tickets           : INTEGER;              { Ticket  Printing            }
    TotalTickets      : INTEGER;              { Total Tickets To Print      }

BEGIN   { Print_Pallet_BreakDown }
  LabelFormatLetter    := GetExtVar(FXLabFormat,all);  { What Format To Use? }
  LabelFormatLetter[1] := UpCase(LabelFormatLetter[1]);

  TotalTickets         := GetNumberOfTicketsToPrint;

  Get_Label_Items(LabelFormatLetter[1]);
  { Calculate Totals }
  FOR Tickets := 1 TO TotalTickets DO
   BEGIN
    FillRemainingFields(TranRec,OrdHRec,OrdLRec,Space_String,Tickets,TotalTickets);
    PlayOutTicket(LabelFormatLetter[1],Tickets,TotalTickets);
    ClearItemList;                       { Clear For Next Ticket    }
   END;
  DisposeItemList;
END;



PROCEDURE Print_UBI_Mix_Total_Ticket(OrdHRec : PWOHeaderRecord;
                                     CurrentMixBatchStr: TBatchRef;
                                     PrintAllDetails   : BOOLEAN);

CONST IngredientInfo : STRING[15] = '*INGREDIENTINFO';
VAR
    LabelFormatLetter : STRING[1];            { Label Format Letter         }
    IngredCount,
    IngredsPerTicket,
    Tickets,
    TotalTickets : INTEGER;
    Filter : TBuildFilter;
    ListHeader : PTRNList;
    Loop       : PTRNList;

  FUNCTION CompareIngredLineTag(LabelItemPtr : PLabelTicketItem) : BOOLEAN;
  VAR IngredLineNum : INTEGER;
      DummyInt    : INTEGER;
  BEGIN
    CompareIngredLineTag := FALSE;
    IF CompTag(LabelItemPtr^.LTI_Tag,IngredientInfo) THEN
     BEGIN
      VAL(COPY(LabelItemPtr^.LTI_Tag,Length(IngredientInfo)+1,2),IngredLineNum,DummyInt);
      CompareIngredLineTag := ((IngredCount - (IngredsPerTicket*Tickets)) = IngredLineNum);
     END;
  END;

  PROCEDURE FillIngredientLineFields;
  VAR LabelItemPtr : PLabelTicketItem;
  BEGIN
    LabelItemPtr := LabelItemHeader;
    WHILE(LabelItemPtr <> NIL) DO
     BEGIN
      WITH LabelItemPtr^ DO
       BEGIN
        IF (LTI_Type = TextItem) THEN
         BEGIN
          IF CompareIngredLineTag(LabelItemPtr) THEN
           BEGIN
            IF (PrintAllDetails) THEN
             LTI_OutStr := Loop^.Ingredient+' '+
                           IntToStr(Loop^.ContsDone,6)+'  '+
                           IntToStr(Loop^.ContsReq,6)+'  '+
                           DoubleToStr(Loop^.WeightReq,9,3)+'  '+
                           DoubleToStr(Loop^.WeightDone,9,3)
            ELSE
             LTI_OutStr := Loop^.Ingredient+' '+
                           IntToStr(Loop^.ContsDone,6)+'  '+
                           DoubleToStr(Loop^.WeightDone,9,3);
           END;
	 END;                                    { END IF TextItem         }
       END;                                      { END WITH LabelItemPtr   }
      LabelItemPtr := LabelItemPtr^.LTI_Next;    { Adv. To Next Label Item }
     END;                                        { END WHILE LabelItemPtr  }
  END; { FillIngredientLineFields}



  PROCEDURE PrimeFilter;
  BEGIN
   FillChar(Filter,SizeOf(Filter),#0);
   WITH Filter,OrdHRec^ DO
    BEGIN
     WorkNo   := WOH_OrderNo;
     {Needs To Be +1 As Revision Ranges from 0 to 99. Where As Search
      uses 1 to 100, as 0 means filter element not set}
     Revision := WOH_Revision+1;
     IF (WOH_CurrentMix > WOH_NumMixes) OR (WOH_CurrentMix < 1) THEN
       MixNo := 1
     ELSE
       MixNo := WOH_CurrentMix;
    END;
  END;

  {Calculates the number of times *INGREDIENTINFO appears in label format}
  FUNCTION CalculateNumItemsPerTicket : INTEGER;
  VAR LabelItemPtr  : PLabelTicketItem;
      Count         : INTEGER;
  BEGIN
   Count := 0;
   LabelItemPtr := LabelItemHeader;
   WHILE (LabelItemPtr <> NIL) DO
    BEGIN
     IF CompTag(LabelItemPtr^.LTI_Tag,IngredientInfo) THEN INC(Count);
     LabelItemPtr := LabelItemPtr^.LTI_Next;
    END;
   CalCulateNumItemsPerTicket := Count;
  END;


BEGIN
 LabelFormatLetter    := GetExtVar(FXLabMixFormat,all);  { What Format To Use? }
 LabelFormatLetter[1] := UpCase(LabelFormatLetter[1]);
 Get_Label_Items(LabelFormatLetter[1]);

 PrimeFilter;
 IF (PrintAllDetails) THEN
  BEGIN
   ListHeader := BuildOrderTransactionListForMix(Filter)
  END
 ELSE
  BEGIN
   ListHeader := BuildTransactionListForMix(Filter);
  END;

 IF ListHeader <> NIL THEN
  BEGIN
   { mix ticket print (output stage) }

   IngredsPerTicket := CalculateNumItemsPerTicket;
   Tickets := 0;
   IF IngredsPerTicket = 0 THEN       { No Ingredient Details On Ticket}
    BEGIN
     TotalTickets := 1;
     INC(Tickets);
     FillRemainingFields(NIL,OrdHRec,NIL,CurrentMixBatchStr,Tickets,TotalTickets);
     PlayOutTicket(LabelFormatLetter[1],Tickets,TotalTickets);
     ClearItemList;                     { Clear For Next Ticket    }
    END
   ELSE
    BEGIN
     IngredCount := 0;
     TotalTickets := (Filter.NumElements DIV IngredsPerTicket);
     IF (Filter.NumElements - (TotalTickets *IngredsPerTicket)) <> 0 THEN INC(TotalTickets);
     Loop := ListHeader;
     WHILE (Loop <> NIL) DO
      BEGIN
       INC(IngredCount);
       FillIngredientLineFields;
       Loop := loop^.Next;
       IF (IngredCount MOD IngredsPerTicket) = 0 THEN
        BEGIN
         INC(Tickets);
         FillRemainingFields(NIL,OrdHRec,NIL,CurrentMixBatchStr,Tickets,TotalTickets);
         PlayOutTicket(LabelFormatLetter[1],Tickets,TotalTickets);
         ClearItemList;                     { Clear For Next Ticket    }
        END;
      END;
     { Print tast ticket if still some unprinted ingredients }
     IF (IngredCount MOD IngredsPerTicket) <> 0 THEN
      BEGIN
       INC(Tickets);
       FillRemainingFields(NIL,OrdHRec,NIL,CurrentMixBatchStr,Tickets,TotalTickets);
       PlayOutTicket(LabelFormatLetter[1],Tickets,TotalTickets);
      END;
     ClearTransactionList(ListHeader);
    END;
  END;
 DisposeItemList;
END;

END.