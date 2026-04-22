(****************************************************************************
*  UNIT          : F6FPROD                                                  *
*  AUTHOR        : C. J. Collins AND S. M. Wright                           *
*  DATE          : 03/11/93                                                 *
*  PURPOSE       : FOPS6 PRODUCT FILE MANAGMENT                             *
*  MODIFICATIONS :-                                                         *
*****************************************************************************
{$O+,F+}
{$I F6COMP}
*)
UNIT F6FPROD;
{Fops6 Product File Routines}
INTERFACE
(*
USES F6Btrv,FOPSFILE,F6StdCtv,F6FNotB,F6BtrTrn,F6StdUtl,F6FACODE,
     F6AddWgt,F6StdWn1,F6Lists,F6FGroup;
*)
USES F6StdCTV;

CONST Prod_file_name = 'PRODUCT.FIL';
      NO_OF_PLU      = 9999;
{ * - indicates an indexed field }
      MaxCalcCode    = 5;
      Calc_Desc : ARRAY [0..MaxCalcCode] OF STRING[12] = ('FROM DATE 1 ',
                                                          'FROM DATE 2 ',
                                                          'FROM DATE 3 ',
                                                          'FROM DATE 4 ',
                                                          'FROM PACK DT',
                                                          'FROM KILL DT');
      Calc_Char : ARRAY [0..MaxCalcCode] OF CHAR = ('1','2','3','4','P','K');

      { Bit Positions of ocm function flags in PLU_TDate field }
      td_AutoPrint = 6;
      td_NoBarWt   = 4;


TYPE   TBatchAssignType = (AT_Input,AT_Output,AT_None);

       PLUDates = PACKED RECORD
         PLU_dt  : CHAR;                     { plu date type             }
         PLU_ad  : INTEGER;                  { plu date addition         }
         PLU_From: CHAR;                     { Calc Date Form 1,2,3,4,K,P}
       END;

       PLU_ptr = ^PLU_Record;
       PLU_Record  = PACKED RECORD
{* 0}    PLU_no      : Prod_Type;                {   1 FOPS Product code     }
	 PLU_name    : STRING[40];               {  10 Name/description      }
{* 1}    PLU_plu      : WORD;                     {  51 PLU number            }
{* 2}    PLU_Dcp      : STRING[11];               {  53 JS DCP Code for Doc   }
         PLU_Site     : Site_Type;                {  65 Product Site          }
         PLU_OLDSOC   : Prod_Type;                {  74 Sales Order Code      }
         PLU_Dumps    : WORD;                     {  83 DUMP File Flags       }
         PLU_lab      : CHAR;                     {  85 Label type            }
         PLU_OldLcod  : STRING[4];                {  86 OLD Barcode Lookup code   }
         PLU_PrStkRmFrom:STRING[2];               {  91 JBA Prodn "From" room }
         PLU_ran      : CHAR;                     {  94 Range                 }
         PLU_txt      : ARRAY[0..7] OF WORD;      {  95 Text references       }
         PLU_tare     : DOUBLE;                   { 111 Tare wt               }
                                                  { Field is not used if ini F6taresonpackaging
                                                    is used}
         PLU_hi       : DOUBLE;                   { 119 Hi weight             }
         PLU_lo       : DOUBLE;                   { 127 Lo weight             }
         PLU_date     : ARRAY[0..3] OF PLUDates;  { 135 Date type records     }
         PLU_BDate    : BYTE;                     { 151 AddOn Barcode Date Ref}
         PLU_TDate    : BYTE;                     { 152 Tranaction Date Ref   }
         PLU_lbl      : BYTE;                     { 153 no of labels          }
         PLU_tol      : CHAR;                     { 154 tolerance over ride   }
         PLU_pric     : DOUBLE;                   { 155 Base Price of PLU     }
         PLU_std      : DOUBLE;                   { 163 PLU Std weight        }
         PLU_npp      : BYTE;                     { 171 No of Boxes/Pallet    }
         PLU_Prn      : CHAR;                     { 172 printer used by ocm   }
         PLU_Fwt      : DOUBLE;                   { 173 Fixed Weight field    }
         PLU_intake   : TBatchAssignType;         { 181 Batch In/Out/None     }
         PLU_Bgrp     : STRING[3];                { 182 Auto Batch Prd Prefix }
         PLU_Link     : STRING[4];                { 186 PLU Link Code         }
         PLU_AGrp     : STRING[4];                { 191 Auto Grouping Code    }
         PLU_Pack     : STRING[4];                { 196 Product Pack Code     }
         PLU_ppc      : BYTE;                     { 201 packs per case        }
         PLU_StdY     : DOUBLE;                   { 202 Standard Group Yield  }
         PLU_CasesPMin: DOUBLE;                   { cases/minute/line }
{*5}     PLU_BCode    : STRING[14];               { 218 Fixed Barcode         }
         PLU_Eq       : DOUBLE;                   { 233 Product Equivalent    }
         PLU_BatGrp   : CHAR;                     { 241 Grouping For Batch    }
{*3.0}   PLU_ACode1   : Prod_Type;                { 242 Stock Analysis Code 1 }
{*3.1,4} PLU_ACode2   : Prod_Type;                { 251 Stock Analysis Code 2 }
         PLU_ACode3   : Prod_Type;                { 260 Tray  Analysis Code 3 }
         PLU_ACode4   : Prod_Type;                { 269 Crate Analysis Code 4 }
         PLU_IPacks   : BYTE;                     { 278 Packs/Internal Use Tray}
         PLU_Parent   : Prod_Type;                { 279 Parent Product Code   }
         PLU_SLine    : STRING[2];                { 288 Slicing Line (BOWES)  }
         PLU_Chiller  : Prod_Type;                { 291 Chiller ID for prod   }
         PLU_OrdUnits : CHAR;                     { 300 Default ordering units}
         PLU_PackLife : ARRAY[0..1] OF BYTE;      { 301 Earliest/Latest Max Life }
         PLU_Max      : ARRAY[0..1] OF BYTE;{NOT USED} { 303 }
{* 6}    PLU_Soc      : SOC_Type;                 { 305 New SOC Code          }
         PLU_MinProd  : WORD;                     { 319 Minimum Production Time}
         PLU_MaxProd  : WORD;                     { 321 Maximum Production Time}
         PLU_Nominal1 : Prod_Type;                { 323 Norminal Analysis Code }
         PLU_AbbrDesc : STRING[10];               { 332 For PDCU   }
         PLU_IBgrp    : STRING[3];                { 343 Input Batch Suffix }
         PLU_BarLookup: STRING[11];               { 347 OCM barcode lookup }
         PLU_BarOffset: STRING[4];                { 359 OCM bar lookup offset}
         PLU_ExportDel: Boolean;                  { 364 Delivery Exporting }
         PLU_TeamSize : BYTE;                     { 365 OCM Team Size for line effic report}
         PLU_Imported : BOOLEAN;                  { 366 PLU was imported from another system}
         PLU_Yld      : DOUBLE;                   { 367 Prod Yield              }
         PLU_PcsPPack : WORD;                     { 375 Pieces per pack(not case)}
        {PLU_PrStkRmFrom is at top of record}
         PLU_PrStkRmTo   : STRING[2];             { 377 JBA prodn "To" Stock room }
         PLU_IssStkRmFrom: STRING[2];             { 380 JBA issue "to" stock room }
         PLU_IssStkRmTo  : STRING[2];             { 383 JBA issue "from" room     }
         PLU_PRTUPOOnDel : BOOLEAN;               { 386 print units per outer on dawn delivery note}
         PLU_PickArea : BYTE;                     { 387 stock location product is picked from }
         PLU_PickRack : CHAR;                     { 388 "                                 "  }
         PLU_PickLoc  : BYTE;                     { 389 "                                 "  }
         PLU_InitArea : BYTE;                     { 390 first stock location for product(D.T.P.) }
         PLU_InitRack : CHAR;                     { 391 "                                 "     }
         PLU_InitLoc  : BYTE;                     { 392 "                                 "     }
         PLU_CompGrpPLU:LONGINT;                  { 393 added for Dawn Group Barcode PLU }
         PLU_WeightAdj: DOUBLE;                   { 397 Weight Adjust For Iceberg }
         PLU_SKUCode  : STRING[8];
         PLU_AddSapItemPfx : BOOLEAN;             { add F6CompanySapItemPrefix to prod code in SAP exports }
         PLU_CoGrpSOPCode  : STRING[17];
         PLU_CoGrpSuppId   : STRING[8];  { eg supp id in dawn grp barcode }
         PLU_ImportSubst   : BOOLEAN;    { edit as if it was imported }
         PLU_TraceCodesId  : LONGINT;
         PLU_Nominal2      : STRING[13];
         PLU_BarcodeFormat : INTEGER;
         PLU_AltDespLocn   : STRING[2];
         PLU_AltPickArea   : BYTE;
         PLU_AltPickRack   : CHAR;
         PLU_AltPickLoc    : BYTE;
       END;             {  size = offset of last field + last field  = 468 }

IMPLEMENTATION

END.