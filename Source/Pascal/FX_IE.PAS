(****************************************************************************
*  UNIT          : FX_IE                                                    *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX INGREDIENT EDITOR                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_IE;
INTERFACE

USES Crt,F6StdCtv,F6Screen,F6StdWin,F6StdWn1,F6StdUtl,F6StdUt1,FXFMenu,
     F6RecChg,FXFINGR,FXHelp,FXModCtv;

PROCEDURE Edit_Ingredient(IngredientRef : TIngredientRef);

IMPLEMENTATION

FUNCTION CompIngredient(Rec1,Rec2 : PIngredient_Record) : BOOLEAN;
BEGIN
 CompIngredient := MemCompare(Rec1^,Rec2^,SizeOf(Rec1^)) = 0;
END;

PROCEDURE Edit_Ingredient(IngredientRef : TIngredientRef);
CONST
      CODE_F  = 1; { Ingredient Ref                   }
      DESC_F  = 2; { "        " Description           }
      TYPW_F  = 3; { "        " Type (Weight)         }
      TYPS_F  = 4; { "        " "  " (Step  )         }
      TYPC_F  = 5; { "        " "  " (Count )         }
      TYPAUTO_F = 6;
      LOTL_F  = 7; { "        " Low Tolerance         }
      STDWT_F = 8;
      HITL_F  = 9; { "        " Hi Tolerance          }
      NOTARE_F= 10;
      LOSSWT_F= 11; { Percentage Remaining After Cooking}
      CONTSZ_F= 12; { Default Container Size }
      SG_F    = 13; { Specific Gravity                 }
      HazCde_F= 14;{ Hazard Code                      }
      Area_F  = 15;{ Preperation area}
      Cost_F  = 16;{ Base Cost                        }
      INS1_F  = 17;{ Instructions Field 1             }
      INS2_F  = 18;{ Instructions Field 2             }

      FIRST_F = 1;
      LAST_F  = INS2_F;
      WIN_X      = 1;           { WINDOW X Offset       (Global )     }
      WIN_Y      = 2;           { WINDOW Y Offset       (Global )     }
      WIN_WIDTH  = 77;          { WINDOW Width          (Global )     }
      WIN_DEPTH  = 22;

VAR EditWin       : WindowRecord;                { Editor Window Record     }
    IngredientRec : TIngredient_Record;
    HoldRec       : TIngredient_Record;
    TestRec       : TIngredient_Record;
    ErrInt        : INTEGER;                     { General Error Usage      }
    EditRec       : BOOLEAN;                     {                          }
    NewRec        : BOOLEAN;                     { New Record Flag          }
    SaveEdit      : BOOLEAN;                     { Save Record Flag         }
    SkipCode      : BOOLEAN;                     { Skip & Retain Record Flag}
    First_Field   : INTEGER;                     { First Edit Field         }
    Index         : INTEGER;                     { Current Edit Field       }
    WrkStr        : STRING[50];                  { Working Field String     }
    File_Error    : INTEGER;
    Dummy         : INTEGER;

 FUNCTION Output_value(Field_No : INTEGER) : STRING;
 VAR Field_Str : STRING;
 BEGIN
  IF (DatCtl[Field_No] = 02) THEN EXIT;
  WITH IngredientRec DO
   BEGIN
    CASE Field_No OF
     CODE_F   : Field_Str := ING_Ingredient;
     DESC_F   : Field_Str := ING_Description;
     TYPW_F   : IF ING_DefaultProcessType = PTWeight THEN Field_Str := RADIO_CHAR ELSE Field_Str :=' ';
     TYPS_F   : IF ING_DefaultProcessType = PTStep   THEN Field_Str := RADIO_CHAR ELSE Field_Str :=' ';
     TYPC_F   : IF ING_DefaultProcessType = PTCount  THEN Field_Str := RADIO_CHAR ELSE Field_Str :=' ';
     TYPAUTO_F: IF ING_DefaultProcessType = PTAuto   THEN Field_Str := RADIO_CHAR ELSE Field_Str :=' ';
     LOTL_F   : Field_Str := DoubleToZeroStr(ING_DefaultLowTol,6,3);
     STDWT_F  : Field_Str := DoubleToZeroStr(ING_DefaultStdWt,8,3);
     HITL_F   : Field_Str := DoubleToZeroStr(ING_DefaultHighTol,6,3);
     NOTARE_F : IF (ING_NoTare) THEN Field_Str := TICK_CHAR ELSE Field_Str := ' ';
     CONTSZ_F : Field_Str := DoubleToZeroStr(ING_DefaultContSize,8,3);
     INS1_F   : Field_Str := ING_DefaultInstructions[1];
     INS2_F   : Field_Str := ING_DefaultInstructions[2];
     LOSSWT_F : Field_Str := DoubleToZeroStr(ING_DefaultYield,9,3);
     SG_F     : Field_Str := DoubleToZeroStr(ING_SG,6,2);
     HazCde_F : Field_Str := ING_Hazard_Code;
     Area_F   : Field_Str := ING_PrepArea;
     Cost_F   : Field_Str := DoubleToZeroStr(ING_Cost,9,3);
    END;                                         { END ( Case Field_No )    }
   END;                                          { END ( WITH IngredientRec)}
  Output_value := Field_Str+SPACE_STRING;        { Return Field Content     }
 END;

 PROCEDURE Input_value(IvStr : STRING; Field_No : INTEGER);
 VAR  CheckIngredient : TIngredient_Record;
 BEGIN
  IF (DatCtl[Field_No] = 02) THEN EXIT;
  WITH IngredientRec DO
   BEGIN
    CASE Field_No OF                             { Load Which Field?        }
      CODE_F : BEGIN
        IF NOT NowtButSpace(IvStr) THEN
         BEGIN
          CheckIngredient.ING_Ingredient := IvStr;
          IF IngredientFile^.ReadRecord('EQ',FALSE,FALSE,CheckIngredient,0) = 0 THEN
           BEGIN
            Disp_Error_Msg('Ingredient Code In Use By Another Ingredient');
            ch1 :=' ';
           END
          ELSE
           BEGIN
            ING_Ingredient := IvStr;
           END
         END
        ELSE
         BEGIN
          Disp_Error_Msg('Ingredient Reference Required');
          ch1 :=' ';
         END;
      END;
      DESC_F   : ING_Description     := IvStr;
      TYPW_F   : IF IvStr[1] = RADIO_CHAR THEN ING_DefaultProcessType := PTWeight;
      TYPS_F   : IF IvStr[1] = RADIO_CHAR THEN ING_DefaultProcessType := PTStep;
      TYPC_F   : IF IvStr[1] = RADIO_CHAR THEN ING_DefaultProcessType := PTCount;
      TYPAUTO_F: IF IvStr[1] = RADIO_CHAR THEN ING_DefaultProcessType := PTAuto;
      LOTL_F   : ING_DefaultLowTol          := StringToDouble(IvStr);
      STDWT_F  : ING_DefaultStdWt           := StringToDouble(IvStr);
      HITL_F   : ING_DefaultHighTol         := StringToDouble(IvStr);
      NOTARE_F : IF (IvStr[1] = TICK_CHAR) THEN ING_NoTare := TRUE
                 ELSE ING_NoTare := FALSE;
      CONTSZ_F : ING_DefaultContSize   := StringToDouble(IvStr);
      INS1_F   : ING_DefaultInstructions[1] := IvStr;
      INS2_F   : ING_DefaultInstructions[2] := IvStr;
      LOSSWT_F : ING_DefaultYield := StringToDouble(IvStr);
      SG_F     : ING_SG := StringToDouble(IvStr);
      HazCde_F : ING_Hazard_Code := IvStr[1];
      Area_F   : ING_PrepArea := IvStr;
      Cost_F   : ING_Cost := StringToDouble(IvStr);
    END;                                         { END (CASE Field_No)     }
  END;                                           { END (WITH)              }
 END;

 PROCEDURE EditField(Field_NO:INTEGER);
 BEGIN
  CASE Index OF
    CODE_F,
    DESC_F,
    INS1_F,
    INS2_F,
    HazCde_F,
    Area_F : BEGIN           { STRING ENTRIES }
      GetLine(WrkStr,LenOrd[Index],XcoOrd[Index],YcoOrd[Index]);
    END;

    TYPW_F,
    TYPS_F,
    TYPC_F,
    TYPAUTO_F: BEGIN            { RADIO BUTTONS }
      GetRadio(WrkStr,XcoOrd[Index],YCoOrd[Index]);
    END;

    NOTARE_F : GetTick(WrkStr,XcoOrd[Index],YCoOrd[Index]);

    SG_F : GetFloat(XcoOrd[Index],YcoOrd[Index],WrkStr,LenOrd[Index],2);
                  { NUMERIC FIELDS  9.3 & 6.3 }


    LOTL_F,
    STDWT_F,
    HITL_F,
    LOSSWT_F,
    CONTSZ_F,
    Cost_F : BEGIN            { TOLERANCE % FIELDS 6.3    }
      GetFloat(XcoOrd[Index],YcoOrd[Index],WrkStr,LenOrd[Index],3);         { Window Posn }
    END;
  END;                                           { END (CASE Index)         }
 END;

 PROCEDURE Display_Value(Field_Str : STRING; Fld : INTEGER);
 BEGIN
  IF (DatCtl[Fld] = 02) THEN EXIT;
  WITH IngredientRec DO
   BEGIN
    CASE Fld OF                                   { Which Field?           }
       CODE_F,
       DESC_F,
       INS1_F,
       INS2_F,
       LOSSWT_F,
       HazCde_F,
       Area_F : BEGIN
        WriteField(XcoOrd[Fld],YcoOrd[Fld],COPY(Field_Str,1,LenOrd[Fld]),TRUE);
       END;

       TYPW_F,
       TYPS_F,
       TYPC_F,
       TYPAUTO_F: BEGIN
        WriteRadio(XcoOrd[TYPW_F],YcoOrd[TYPW_F],(ING_DefaultProcessType = PTWeight));
        WriteRadio(XcoOrd[TYPS_F],YcoOrd[TYPW_F],(ING_DefaultProcessType = PTStep));
        WriteRadio(XcoOrd[TYPC_F],YcoOrd[TYPC_F],(ING_DefaultProcessType = PTCount));
        WriteRadio(XcoOrd[TYPAUTO_F],YcoOrd[TYPAUTO_F],(ING_DefaultProcessType = PTAuto));
       END;

       Cost_F : WriteField(XcoOrd[Fld],YCoOrd[Fld],
                           DoubleToZeroStr(ING_Cost,9,3),TRUE);

       SG_F   : WriteField(XcoOrd[Fld],YCoOrd[Fld],
                           DoubleToZeroStr(ING_SG,6,2),TRUE);

       LOTL_F : WriteField(XcoOrd[Fld],YCoOrd[Fld],
                           DoubleToZeroStr(ING_DefaultLowTol,6,3),TRUE);
       STDWT_F: WriteField(XCoOrd[Fld],YCoOrd[Fld],DoubleToStr(ING_DefaultStdWt,8,3),TRUE);

       CONTSZ_F: WriteField(XCoOrd[Fld],YCoOrd[Fld],DoubleToStr(ING_DefaultContSize,8,3),TRUE);
       HITL_F : WriteField(XcoOrd[Fld],YCoOrd[Fld],
                           DoubleToZeroStr(ING_DefaultHighTol,6,3),TRUE);
       NOTARE_F : WriteTickBox(XcoOrd[Fld],YCoOrd[Fld],ING_NoTare);
     END;
   END;
 END;

BEGIN
 Esc_Flag := FALSE;
 SkipCode := FALSE;

 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WIDTH,WIN_Y+WIN_DEPTH,TRUE,SW_DEFAULT,SW_DEFAULT,EditWin);
 CursorOn;
 { Open Ingredients File }
 IngredientFile^.OpenFile;

 REPEAT
  menucr := '';
  ClrScr;
  BackColourScheme;
  IF NOT LoadMenu('FXINGR',TRUE) THEN
   BEGIN
    ForeColourScheme;
    Disp_Error_Msg('Menu File Not Found FXINGR.TXT');
    BREAK;
   END
  ELSE IF No_Of <> LAST_F THEN
   BEGIN
    ForeColourScheme;
    Disp_Error_Msg('Incorrect FXINGR.TXT.  Should have '+
                   IntToStr(LAST_F,1)+' fields.');
    BREAK;
   END;

  ForeColourScheme;

  EditRec := TRUE;
  NewRec  := NowtButSpace(IngredientRef);
  IngredientFile^.InitRecord(IngredientRec);
  IF (NOT NewRec) THEN
   BEGIN
   { Seek Record To Edit }
    IngredientFile^.GetIngredient(IngredientRef,IngredientRec,FALSE);
    EditRec := (IngredientFile^.BtrvErr = 0);
   END;

  IF NOT EditRec THEN
   BEGIN
    Esc_Flag := TRUE;
   END
  ELSE
   BEGIN
    HoldRec := IngredientRec;

    FOR Index := FIRST_F TO No_of DO                  { Display All Fields }
     BEGIN
      Display_Value(Output_value(index),index);
     END;

    IF NewRec THEN First_Field := CODE_F
    ELSE First_Field := DESC_F;
    Index := First_Field;                       { Locate To First Field    }

    SaveEdit := TRUE;
    REPEAT
     Wrkstr := Output_Value(Index);              { Get Field Contents      }
     EditField(Index);
     IF (ch1 = ESC) AND (NOT Funckey) THEN esc_flag := TRUE;

     IF  (NewRec) AND (Esc_Flag)
     AND (Index = CODE_F) AND (NowtButSpace(WrkStr)) THEN
      BEGIN
       FuncKey := TRUE;
       ch1 := FN_F10
      END;

     IF ch1 <> FN_F10 THEN
      BEGIN
       Input_value(Wrkstr,Index);                { Store Field Contents     }
       Display_value(Output_Value(index),index); { Display Field            }
      END;


     IF Funckey THEN
      BEGIN
       CASE ch1 OF
        NEXT   : REPEAT
         INC(Index);
	 IF Index > LAST_F THEN Index :=First_Field;
	UNTIL DatCtl[Index] = 0;

        PREV   : REPEAT
         DEC(Index);
	 IF Index < First_Field THEN Index := No_of;
	UNTIL DatCtl[Index] = 0;
{$IFDEF HELPON}
        FN_F8 : BEGIN
         DisplayHint(Index,XcoOrd[Index],YCoOrd[Index]);
        END;
{$ENDIF}
        FN_F10 : BEGIN
         InChr :='Y';
         IF NOT NewRec THEN
          BEGIN
           IF YesNoWin('     Abandon Ingredient Edit'+CRLF+
                       '       Are You Sure (Y/N)?') THEN
            BEGIN
             SaveEdit := FALSE;
             Esc_flag := TRUE;
            END;

          END; { END (FN_F10) }
        END;
       END; { END (CASE) }
     END;
    UNTIL Esc_flag;

    IF (SaveEdit) AND NOT NowtButSpace(IngredientRec.ING_Ingredient) THEN
     BEGIN
      IF NewRec THEN
       BEGIN
        IngredientFile^.AddRecord(IngredientRec);
        IF IngredientFile^.BtrvErr = BDuplicate THEN
         BEGIN
          Rec_Changed_Error(FALSE);
          IngredientRef := IngredientRec.ING_Ingredient;
          Esc_Flag := FALSE;
         END;
       END
      ELSE                        { Update To Existing Record }
       BEGIN
        { Re-Read Record From File }
        TestRec := IngredientRec;
        IngredientFile^.GetIngredient(IngredientRec.ING_Ingredient,TestRec,TRUE);

        IF IngredientFile^.BtrvErr = BNoRecord THEN { Deleted ? }
         BEGIN
          IF Upcase(Rec_Changed_Error(TRUE)) = 'Y' THEN
            Show_Btrv_Err(IngredientFile^.AddRecord(IngredientRec))
         END
        ELSE IF  (NOT CompIngredient(@TestRec,@HoldRec))
             AND (IngredientFile^.BtrvErr = 0) THEN { Changed ? }
         BEGIN
          Show_Btrv_Err(IngredientFile^.UpdateRecord(TestRec)); { Unlock }
          Rec_Changed_Error(FALSE);
          { Set Key Value For Re-Display of Record }
          IngredientRef := IngredientRec.ING_Ingredient;
          ESC_Flag := FALSE;
         END
        ELSE IF (IngredientFile^.BtrvErr = 0) THEN { Not Deleted or Changed }
         BEGIN
          Show_Btrv_Err(IngredientFile^.UpdateRecord(IngredientRec))
         END
        ELSE Show_Btrv_Err(IngredientFile^.BtrvErr); { Btrieve Problem     }
       END;
     END; { END (IF SaveEdit) }
   END;
 UNTIL Esc_flag;
 Esc_Flag := FALSE;
 Show_Btrv_Err(IngredientFile^.CloseFile);
 LoseWindow(EditWin);
END;

END.
