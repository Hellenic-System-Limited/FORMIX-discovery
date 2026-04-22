{$O+,F+}
{$I F6COMP}
UNIT FXMODCTV;

INTERFACE
{MODIFICATION FILE SCALE VERSION}
USES F6StdCtv;


CONST COPYRIGHT      :   STRING[10] = 'H.S.L.2009';
      VERSION_NUMBER :   STRING[10] = '1.069';(*******************)
                                              (* LIST MODS BELOW *)
                                              (*******************)
{ IFDEF DEMO                                  CONST COMPILED_FOR = 'Demonstration';    DEFINE CompOK    ENDIF}
{ IFDEF BENSONPARK doesnt do anything         CONST COMPILED_FOR = 'Benson Park';     DEFINE CompOK    ENDIF}
{$IFDEF BUXTED}             CONST COMPILED_FOR = 'Buxted Chickn'; {$DEFINE CompOK} {$ENDIF}
{$IFDEF DAWSONS}            CONST COMPILED_FOR = 'James Dawson';   {$DEFINE CompOK} {$ENDIF}
{$IFDEF MAUNDERS}           CONST COMPILED_FOR = 'Lloyd Maunder';  {$DEFINE CompOK} {$ENDIF}
{ IFDEF GRAMPIAN_PORK_SPEC doesnt do anything CONST COMPILED_FOR = 'Grampian Pork'; DEFINE CompOK ENDIF}
{ IFDEF LAZENBY    doesnt affect PC program   CONST COMPILED_FOR = 'Lazenby''s'; DEFINE CompOK ENDIF}
{ IFDEF MATTHEWS   doesnt do anything         CONST COMPILED_FOR = 'B.Matthews'; DEFINE CompOK ENDIF}
{ IFDEF HILTOND    doesnt do anything         CONST COMPILED_FOR = 'Hilton Foods Ireland'; DEFINE CompOK ENDIF}
{$IFDEF STD}                CONST COMPILED_FOR = 'Standard';      {$DEFINE CompOK} {$ENDIF}
{$IFNDEF CompOK} use STD {$ENDIF}
                                                 {<----max---->}

TYPE  TIngredientRef = STRING[8];
      TProductRef    = STRING[10];
      TRecipeRef     = STRING[8];
      TBatchRef      = STRING[6];
      TLotRef        = STRING[14];
      TUserRef       = STRING[8];
      TUserNameRef   = STRING[30];
      TPasswordRef   = STRING[8];
      TMacroReportRef= STRING[30];
      TMacroIDRef    = STRING[30];
      TMacroHeaderRef= STRING[40];
      TUniqueID      = STRING[32];
      TWorkGrp       = STRING[3];
      TProcessTypes  = (PTWeight,PTStep,PTCount,PTAuto);


      {--------------------- MIX TYPES ---------------------}
TYPE
      TMixType       = (mt_SingleContainerPerMix,
                        mt_SegregatedIngredients,
                        mt_OptionallySegregated,
                        mt_EqualContainersPerMix,
                        mt_CampaignWeighing);
CONST
      MixSet_ProportionallyMixedConts : SET OF TMixType =
                       [mt_SingleContainerPerMix,
                        mt_EqualContainersPerMix];



(*
      MixSet_MixedContsByDefault : SET OF TMixType =
                       [mt_SingleContainerPerMix,
                        mt_OptionallySegregated,
                        mt_EqualContainersPerMix];
*)
(*
      MixSet_DiffContEachWeighing : SET OF TMixType = { but not necces empty }
                       [mt_SegregatedIngredients,
                        mt_EqualContainersPerMix, { assuming > 1 cont per mix }
                        mt_CampaignWeighing];
*)
      MixSet_AutoTareAfterWeighing : SET OF TMixType =
                       [mt_SingleContainerPerMix,
                        mt_OptionallySegregated];

      MixSet_AutoCancelOfTares : SET OF TMixType =
              { (DiffContEachWeighing and optionally segregated ) }
                       [mt_SegregatedIngredients,
                        mt_OptionallySegregated,
                        mt_EqualContainersPerMix,
                        mt_CampaignWeighing];


      LastMixType = mt_CampaignWeighing;

      MixTypeListItems : ARRAY[mt_SingleContainerPerMix..LastMixType] OF
                              TListBoxString = (
           'Single Container per Mix.      (Auto tares between ingredients)',
           'Segregated Ingredients.                 (One mix at a time)    ',
           'Combined and/or Segregated Ingredients. (One mix at a time)    ',
           'Even Ingredient Distribution.           (One mix at a time)    ',
           'Campaign Weighing      (One ingredient at a time for all mixes)');

      {-----------------------------------------------------}

VAR
      UseSingleRecipePerProds : BOOLEAN;
      MENU_NAME               : STRING;

CONST
      MIXBAR_LEN = 14;

IMPLEMENTATION

BEGIN
 UseSingleRecipePerProds := TRUE;
 MENU_NAME               := '.\';
END.

(* Modtypes :- FE  (Functional Enhancement);
               FIX;
               AE  (Aesthetic Enhancement)
               CE  (Code Enhancement)
               MOD (Modification)

Ver   Type  Description
-----  ---  -----------------------------------------------------------------
1.006  CE   Take Over From Neil Spooner
1.007  MOD  Added Compiler Condition MAUNDERS
       AE   Corrected Various Spelling Mistakes (PC APPLICATION)

       LZE  You'll have to compare the source code

1.014
    CE  TB  a) Weight Rounding precision now held in config record.
            b) RoundWt(), now called RoundWtToScaleRes(), now handles any
            resolution not just those that are whole number divisions of 1 kg.
            c) CalcNumMixes() param list now takes order header not seperate
            figures.

            LOADS MORE - beta version
1.016
    FIX TB  Flexible mix type now calculates number of containers as if
            ingredients are seggregated but autotares containers as if they
            are mixed.
1.017
    FE  TB  Loop calling Wait_For_User_Input when first scroller is displayed
            now monitors keyboard/scanner for order/mix number entry.
    AE  TB  Recipe editor now shows F5/F6 function descriptions.
    FE  TB  Order editor now has auto order numbering available.
    FE  TB  Btrieve serial number file (as fops6) added to database.
    FE  TB  New ini added for LAZENBY: SFXPromptForSource.
    CE  TB  SFXScaleDetails ini definition moved to code global to both progs.
    CE  TB  GetAutoBatchNumber function now available to PC program source.
    MOD TB  Mix label barcode now formats mix number to 4 digits, was 2.
    FIX TB  Mix label printing now requires mix batch number passed through
            to it instead of using current weigh batch number.
    FIX TB  Manual tare weight entry now resets WeighProcessController so
            weighing can proceed.
    FIX TB  Manual weight transaction no longer requires scale to be tared off.
    CE  TB  Batch and Lot numbers:
            a) New function StoreIngredientLotNumber added to avoid duplicate
               code after lot number editing.
            b) Current batch number and lot number now set by
               MainWindow.RefeshDetails only, was all over the place.
            c) "Current mix" batch number and global batch number are now
               separate variables. Global batch number (used when auto-batch
               numbering is disabled) is only set from options window.
    FE  TB  Mainwindow now defaults to order header details if no ingredient
            selected.
    CE  TB  ScrollerWindow.WriteScrollerText now exits if window is disabled
            eg. by GetStr to avoid clashes with pop-up keyboard.
    FIX TB  Ingredient not belonging to prep area no longer selectable by user.
    CE  TB  SFXBAS.PAS most functions now removed from interface for clarity.
    CE  TB  GetStr now works when window is not up against left side of screen.
    FIX TB  Contrast adjustment no longer affected by keyboard keys with
            same char interpretations as PGUP and PGDN.

1.018  15/2/2002
    FIX TB  "No tare" ingredients can now start from negative scale
             readings in case reading already includes container tare.

1.019  25/2/2002
    CE  TB  Uses new library 1.078 with improved file object that:
            a) Checks for files existence using DOS.FindFirst aswell as
               btrieve call.
            b) Checks for record length -1 before displaying record mismatch
               message.
    AE  TB  Version number now shown on terminal touchscreen.
    FIX TB  Majority of weight comparisons (including camparing live weight
            with tolerances) now use new function CompareWts which avoids
            comparison of floating point numbers (two weights on the same
            thousandth of a kg could be computed as not equal).
    MOD TB  With the exception of mix type: mt_EqualContainersPerMix,
            high tolerance on ingredient weighings now reflects total mix
            requirement for ingredient and not the current container. Enables
            broader tolerances on ingredients requiring multiple weighings
            until the last weighing is reached.
    MOD TB  Multiple container requirements for an ingredient in one mix
            is now expected as full containers followed by one part container
            instead of equal part containers.
    MOD TB  Weight rounding is now restricted to mix total weight and high
            and low weighing tolerances on terminal.
            Rounding of order line requirements causes problems when they are
            summed by reports or the editor.
    MOD TB  An ingredient in a mix is now considered complete when the weight
            done equals or exceeds the low tolerance of the total ingredient
            requirement in the mix instead of the number of calculated
            containers (enables user to less or more containers than calc).
    FIX TB  I think last part weighing of a 'count' ingredient wasnt being
            changed to a catch weight operation.
    AE  TB  Ingredient weighing cone:
            a) position of low tolerance now refects how large the weight
               requirement is with respect to the container size.
            b) The thickness of the tolerance band now reflects the tightness
               of the tolerance.
            c) A small short line now shows target weight if different from
               the low and high tolerances.
            d) Now when a zero tolerance exists a small tolerance band is
               still shown so that the colour green is seen when the target
               weight is hit.
    CE  TB  RestartScaleTasks() now called RestoreScaleTasks().
    FIX TB  AdvanceMixIfNotWorkable wasnt starting at ingredient line one
            on advancing to next mix number.
    FE  TB  Everybody now has Part Weigh button so that underweight
            containers can be recorded against mix - except for mix type:
            EqualContainersInMix.
    FIX TB  If number of containers for an ingredient in a mix is > 1 and
            the mix type autotares the containers, then the terminal will now
            assume that the container with the previous ingredient should be
            removed.
    FIX TB  StopScaleTasks() now stops WeighProcessController object from
            acting upon scale readings.
    FIX TB  Weighing process is now stopped when printing tickets - stops
            instruction messages appearing too early.
    FIX TB  'Mix Completed' now shown instead of 'Mix finished in area' when
            the mix is completed for all areas (recent bug).
1.020
    FIX TB  IsThisLineCompleteForCurrMix() now uses CompareWts() to avoid
            rounding causing line to appear uncompleted.
    FE  TB  When user is now instructed to remove container - if ingredient
            is a tare ingredient, the semi-auto tare button can be hit
            instead.
    FIX TB  product description shown above ingredient list in Order editor
            now tracks cursor properly.
1.021
    FE  TB  Keyboard can now shift to different character sets.
    FE  TB  IPL printer config option added.
    CE  TB  Child windows can now be disposed of independently of parent.
    CE  TB  Child windows are now automatically painted if parent is.
    FE  TB  Printer port now initialised to 9600 parity-none first. If
            printer comms fail then port is reinit to 38400 parity-even.

1.022  18/3/2002
    FIX TB  Order scroller now resets to left hand end when date is adjusted
            (bug intro circa 1.017).
    CE  TB  Terminal/label qty settings now cached.
    FIX TB  'Complete' status of "Step" type ingredients now determined by
            number of trans not weight done (bug intro 1.020).
    FE  TB  Terminal start-up no longer trys to talk to printer if labels
            are not required.
    FIX TB  Order editor now uses CompareWts() on WOH_WtDoneGross to
            determine if it can be edited.
    FIX TB  Bars Draw method now draws mix totals.
    FIX TB  Lot button now hidden when main window displays only the order
            header.

1.023  03/04/2002
    FIX TB  ifdef FOPSTRACELINK - Correct number of chars in product code
            on source tran now compared with ingredient code.
    MOD TB  ifdef FOPSTRACELINK - if source tran weight is low or Part-Weigh
            button has been hit, user is asked if 'Source Container for
            ingredient is now Empty' and if so, generates a total issue
            tran for fops6.
            Order Cost Report:
    FIX TB  a) %Variance now WtVariance/WtRequired X100
                         was 100 - (WtReqd/WtDone X100).
    FIX TB  b) Cost/kg was uninitialised if WtDone was 0.
    MOD TB  IPL Printer configuration - print test ticket - now prints a mix
            ticket instead of an ingredient ticket.
    FIX TB  Mix Wt Cone - Wt required and done now initialised when cone is.

1.024  05/04/2002
    FIX TB  Low tolerance now rounded up

1.025  09/04/2002
    FIX TB  Calls to ResetScaleTasks() replaced with StopScaletasks and
            RestoreScaleTasks so that filling cones cant go dead after
            selecting a mix option eg View/Change Mix No.

1.026  13/05/2002
        TB  Auto selection of order by scanning mix label:
    FIX     a) No longer attempts to work if scanners dont send a STX prefix.
    FIX     b) Now resets order scroller to date of order scanned.
            c) Now sets current mix number on order to that scanned.
            d) Now auto-selects an ingredient if order is fixed sequence.
    CE  TB  PreWeighingSetup now a function - if returns false line select
            loops breaks back to order select loop.
    MOD TB  Mix label barcode now has 2 digit machine ID on the end.
    FE  TB  ini switch: SFXScanMixLabelsFirst added - User has to scan two
            related 14 digit mix labels before weighing anything to mix.
    MOD TB  LAZENBY - Source barcode scanning -
            a) Option to continue if 20 digits now removed unless its
               8 chars long (fallback source identifying code).
            b) Option to continue if source product does not match
               ingredient now removed.
            c) product of source barcode is now checked before life
               date check.
    FIX TB  Change mix type on terminal now maintains current mix no.
    CE  TB  Edit windows now have the option not to flush the keyboard buffer
            on user activation.
    FE  TB  Master Terminal Setup password added: 2b5aggrs
    MOD TB  LAZENBY - batch number now sent to fops6 is always 1ooooomm
            where ooooo =  last 5 digits of order number and mm = mix no.
    FIX TB  LAZENBY - mid and serial no in tran sent to FOPS6 now reflects
            current terminal settings - stops duplicate tran errors on
            full reweigh&issues.
    FE  TB  ini switch added: FXLastMixCompensation (default = TRUE).
    FIX TB  Jumping back to a different mix from the options menu could
            bypass PreWeighingSetup.  SelChgPending flag added to main
            window. PreWeighingSetup method now clears that instead of
            DrawPending flag.
    FE  TB  User 'HSL ' can now be used with old telephone no. password.
    FE  TB  Master terminal password added (as on OCM).
    FIX TB  Weigh process controller now disabled when modal window active
            eg Disp_Error_msg.

1.027  13/05/2002
    MOD PW  Added High and Low Tolerance to the Recipe Item Editor.
    MOD PW  Added High and Low Tolerance to the Recipe Order Item Editor.
    MOD PW  Changed the Order Schedule HOLD colour from BLUE to LIGHT BLUE.

1.028  21/06/2002
    MOD TB  Tolerance on ingredient weighings now determined by order
            line tolerances instead of ingredient record tolerances.
    CE  TB  FX_RLU unit deleted. contained obsolete recipe lookup.
    CE  TB  Defunct function in recipe editor for copying recipe with same
            name removed. Used FX_RLU unit. (Recipe codes are unique).
            Defunct function for check circular references in recipes
            commented out (recipe lines can only refer to ingredients).
    MOD TB  Proc Loss on recipe can no longer be edited to > 100.0
    MOD TB  Recipe editor checks for untoleranced recipes (pre V1.027) and
            gives user chance to initialise with ingredient defaults.
    FE  TB  Recipe and Order line editors:
            a) Can now call Ingredient lookup with F1 key even if existing
               ingredient code exists.
            b) Default details are now copied onto line whenever ingredient
               code is changed.
    FIX TB  Order editor now check process type of line not ingredient record.
    FE  TB  Escaping from ingredient lookup no longer blanks edit field.
    FIX TB  UnitName and SglUnitName when set via ini file now space padded.
            UnitName now displayed fully in screens constructed via Menu().
    CE  TB  Imported orders now have number of cases/batches reqd set to
            zero on updating the file. This conforms with the editor logic.
    FIX TB  Creating orders via product orders:
            a) With FXUseSingleProds=YES, WOH_SelectByCase now gets set to
               TRUE and therefore stops number of cases on recipe order being
               zeroed.
            b) With FXUseSingleProds=NO, recipe order weight is now calculated
               taking proc loss into account.
    MOD TB  Stock report - Weight To Mix now calculated from order weight
            shortage not mix shortage * recipe std mix wt.
    FIX TB  Ingredient usage export now longer takes a serial number before
            checking it can write the export i.e. has managed to re-create
            MOV.$$$.

1.029  24/06/2002
    FIX TB  Hitting ESC on recipe editor and recipe line editor no longers
            abandons edit of current field.
    FIX TB  Hitting ESC on order line editor no longers abandons edit of
            current field.
    FE  TB  Order line instructions and tolerances are now still editable
            after order has been started.
    FE  TB  High tolerance resestablished on full containers (before the last
            container) of an ingredient. New ini: FXFullContainerHighTol added
            to optionally force high tol to a constant percentage weight.
    FE  TB  New ini: SFXNoAutoCancelOfTares to enable BM to remove bins
            during ingredient loading step in mix type 'flexible'.
    AE  TB  Important touchscreen messages can now be overwritten after 4
            seconds (minor msg secs in ini) were stuck on screen for 10 secs
            (major msg secs in ini).

1.030  28/06/2002
    FIX TB  Equal Ingredient Distribution mix type no longer forces all mixes
            for an order to the same weight (intro. circa 1.017).
    FIX TB  User login at start of mixes appeared to be missed if the same mix
            number was selected on a different order.

            CAMPAIGN WEIGHING retested and fixed since mods intro circa 1.017
            -----------------------------------------------------------------
    FIX TB  Campaign weighing now asks for user on ingredient change instead
            of mix change.
    MOD TB  Since circa 1.017 CAMPAIGN WEIGHING order line scroller has shown
            status of line in current mix, previously only showed a line as
            complete if the ingredient was complete in all mixes.
            If the user skips an order line for some latter mixes this is now
            often hidden from the user until the last order lines have been
            completed.
    FIX TB  Current order line now remains highlighted during campaign
            weighing mix number increments.
    CE  TB  New method on SelRecs: ResetForNextStep() added.
            If PrintAndAdvanceMixIfComplete() returns false (note: mixes dont
            become complete in campaign weighing until the last ingredient is
            worked on) then this function can be used to change SelRecs,
            according to the mix type, if the current op is finished .
1.031  29/06/2002
    FIX TB  Clear down of orders was not using correct key to find orders.
    FE  TB  Customer name for compilation now shown on touchscreen.
    FE  TB  New terminal printer setting: Check Label Taken [ ].
    FE  TB  New terminal printer option: Download Configuration File.
    FE  TB  Edit Printer (IPL) Config option now has full control over
            config setting selection.
    MOD TB  Forward slash key changed for backslash (more usefull).

1.032  17/12/2002
            CLEAR DOWN OF ORDERS IN 1.031 NEVER GOT MERGED IN
        TB  SFORMIX:
            -------
    FIX     Residue of "weight remaining" figure on base window now cleared
            fully.
    FE  TB  Weight simulator option added - set SCALE=NOSCALE in scale
            data file.
    CE  TB  User window now displays time and gross wt (if wt simulator active).
            User window now displayed from first date selection window aswell.
            TimeWindow removed - time now drawn by user window.
    CE  TB  Compile condition TOUCHSCREEN replaced by new ini:
            SFXTOUCHCREEN in section SCALE.
    FE  TB  Printer baud rate and comm frame type now saved to scale settings
            file to avoid trying different baud rates at start-up.
    MOD TB  Printer port settings no longer cleared if printer port
            initialization fails on saving printer port config changes.
    CE  TB  Obsolete var: ReturnLastMousePress removed. No longer needed since
            external keyboard handler was added which stored key presses.
    FIX TB  Manual Weight entry now uses CompareWts to avoid weight does not
            match tolerance error messages.
    MOD TB  On switching scales the interrupts device is no longer disabled.
            Temp fix to not being able to restore scale.

1.033  21/12/2002
            ********* RECREATE FXTRANS.FIL with fixed key defs ************

        TB  SFORMIX:
            -------
    FE  TB  Order sideways scroller now replaced by vertical browser which
            also has two editable filters: Date and Work Group.
    FE  TB  Work group filter (default) added to terminal setup option.
    FE  TB  Messages from other terminals or PC now shown in bordered window
            requiring key press from user to continue, were in status bar.
    CE  TB  DateWindow, which was persistent and was hidden when order had been
            selected, now replaced by dynamic BrowserHeader which displays
            global variables: RecipeDay and CurrentWorkGroup (new).
    CE  TB  MessageWindow (Status bar) now disabled while order selection
            in process (no space left on screen).
    CE  TB  GetStr now pops keyboard up if not already there.
            Use GetStrWithoutKeyboard if no keyboard wanted eg. scan only.
    CE  TB  Disp_Error_Msg now stops and restores scale tasks. Also no longer
            uses a static window pointer allowing user message recursion.
    FIX TB  Order cleardown fix in v1.031 put back in. Criteria window
            wording slightly less ambiguous.
    CE  TB  SQL table create statements added below file record definitions.
    FIX TB  FXTRANS.FIL file create routine no longer creates incorrect
            segment address for key:Date/OrderNo/Suffix causing conflict
            with DDFs.
            File needs to be rebuilt (use this version to create file)
            to avoid:
            a) 'Show Graphical Results' not working
            b) FORMIX - Ingredient Usage Report taking a long time.
    FIX TB  Hitting batch number edit field now invokes touchscreen keyboard
            to make it editable - bug intro. v1.032
    CE  TB  BackgroundTask object now has a flag to automatically suspend
            task if a modal window is on the screen. This flag is set to
            TRUE on the MsgReader object to avoid recursion of Disp_Error_Msg.
    CE  TB  TScrollerWindows now has flag to indicate direction of scroll.
    CE  TB  NonDisabledButton pointer now applies to TChildWindow (ancestor
            of TEdit) as well as TButtonWindow. Calling UndisableAllButtons
            now restores NonDisabledButton to original state allowing one
            modal window to go on top of another.
    FIX TB  SwitchToScale() caused RTE 201 when scale failed to respond, e.g.
            on calibrating scale on start-up when scale was out of range.
            intro. v1.032
    CE  TB  If MessageWin(status bar) is disabled messages are now shown using
            Disp_Error_Msg.
    FE  TB  Four extra fields added to order header.

1.034  07/02/2003
        TB  FORMIX (Office program):
            ------------------------
    FE  TB  WorkGroup added to recipe header file and editor.
    MOD TB  WorkGroup added to order editor.

1.035  18/02/2003
        TB  SFORMIX (Terminal program):
            ---------------------------
    FE  TB  New Options Menu button: 'Add Stock Item Weight', used to
            scan OCM label and use associated weight and date details
            recorded in fops6.
            If the transaction is found in fops6 then the 'actual weight'
            is added to the container weight and the 'max life date' checked
            for expiry. If new ini: FXIngredientsInFops6=YES then product code
            check is made as at Lazenbys (ingred codes have matching prod or
            prod group codes) .
            If the transaction is not found then the label weight is extracted
            from the barcode and the life date is not checked (only pack date
            is in barcode).
    FE  TB  Manual weight option can now be disabled from terminal Setup
            screen.
    CE  TB  New function WeightOkForTran added to centralize tolerance
            limit weight comparisons.
    MOD TB  'No. of mix Tickets' now only controls ticket printing when:
            a) 'Delay Current Mix' is selected
            b) A mix is completed
            c) A mix is finished in a preperation area.
            Other mix ticket printing ops will now always attempt to print
            one ticket.
    MOD TB  Partial Weight button now only active when ingredient is a
            Weighing process (didnt make sense on count processes as
            fixed wt was being used to calculate weight remaining).

1.036  26/03/2003
    FE  TB  CSV recipe order import extended.
    CE  TB  FileMode now set to DENY_NONE at start of program to avoid
            report file viewing / writing contentions.
    MOD TB  Extra custom fields in recipe orders now editable from order
            editor.
    FIX TB  Order browsing no longer leaves order header locked on an aborted
            delete order operation.
    CE  TB  CSV file processing utilities now moved to HSL library.
    FE  TB  Unstarted orders can now be deleted from the order browser.
    CE  TB  List box strings now use new type TListBoxString instead of
            STRING40 which has now been changed back to a STRING[40].

1.037  23/06/2003
        TB  SFORMIX (Terminal program):
            ---------------------------
    FE  TB  Printer comm settings now shown on screen before attempting
            to communicate to printer.
    FE  TB  Printer port address saved in scale data file (defined by
            ini: SFXScaleDataFile) can now be overriden using new ini file
            variable: SFXPrinterPortAddr in section [SCALE]. This enables
            addesses entered at scale (which can be invalid) to be ignored.
    FE  TB  Screen contrast no longer saved in common setting in file
            (CONT.FIL), now saved in scale' data file (SFXScaleDataFile).
            A corrupt CONT.FIL used to stop all terminals on start-up with
            a completely blank screen.
            Contrast on colour screens can no longer be set to completely
            black.
    CE  TB  Various code mods for new SPROMPT program to run without
            crashing (initialisation of variables using CONST; checking
            global object pointers are assigned).
    CE  TB  TouchScreen comms initialisation seperated from option for user
            to hit screen 3 times to recalibrate touchscreen. Done for
            new SPROMPT program.
    FE  TB  Touchscreen can now be recalibrated at any point of the program
            by hitting background at least 4 times in four seconds as well
            as on start-up.
    FIX TB  Calculaton of seconds elapsed since last screen press for auto
            logout of users was incorrect on hour changes.

1.038  17/07/2003
    FIX TB  Internal barcode product check didnt work if ingredient code
            matched a fops product group code (used wrong key on file).

1.039  21/07/2003
            IF FORMIX IS INTEGRATED TO FOPS6 (FOPSTRACELINK {LAZENBY}):
            -----------------------------------------------------------
    MOD TB  a) 'Transaction not found' and Transaction file errors when
               scanning source barcodes: user no longer gets option to
               continue (can enter purchase order number instead in format:
               POnnnnn).
    MOD TB  b) When scanning a source barcode that relates to a fops6
               transaction that has zero weight: the user now has to confirm
               that the source container is not empty and have an access level
               of at least 10 to continue.
    MOD TB  c) When scanning a source barcode that relates to a fops6
               transaction that has less stock weight than is required by mix
               weighing: user is now reminded to use part weigh button when
               source container is emptied.
    MOD TB  d) When user accepts weight, and weight is greater than
               remaining stock weight + 2% of original stock wt on scanned
               transaction: user now has to confirm that all the weight came
               from that source and have an access level of at least 10 to
               continue (doesnt happen if user already had to confirm the
               container as not empty on start of weighing).
    MOD TB  e) User is now asked if 'source container is empty?' (after a
               weighing) when either:
               1.) The partial weigh button was used.
               2.) Source container was less than 10% of its original weight
               3.) Weighing accounts for more than a third of the remaining
                   weight that was left in stock.
               Used to be asked when TARGET weight accounted for a quarter of
               remaining weight in stock.
    CE  TB  f) If source barcode is 20 digits the PLU in the barcode is
               now sent to fops6 instead of '9999'.
    MOD     'Transaction not found' error message when scanning source
            barcodes, without FOPSTRACELINK, now just continues once user
            acknowledges message. Also eight digit loop hole for fops6 link
            now removed.
    FE  TB  Scanning source barcode - Life date has expired error: User can
            no longer ignore error if his access level is less than 10.

1.040  02/09/2003
    FE  TB  New ini [MAIN] SFXAcceptLabelWeight=YES, use to save weighing
            ingredients with a fops internal barcode. Note: Only works if case
            weight will not take ingredient wt over high tolerance.
    FIX TB  When using source weight instead of weighing, transaction no
            longer has to exist if barcode is valid.
    MOD TB  Add Stock Item Weight button removed from 'Options' menu.
    FE  TB  New ini [MAIN] SFXSourceOptional=YES, allows user to hit enter
            on source barcode prompt and continue with weighing.
    FIX TB  If program creates a new terminal settings file the printer comm
            settings are now set to 9600 8 N 1 to avoid settings getting stuck
            with 0 stop bits.
1.041  05/02/2003
    MOD TB  6 digit source barcode can now be entered to identify a fops6
            transaction by its serial number only.
            Requires new ini [MAIN] SFXIntakeMid=nn to identify machine id
            of transactions.
            Also requires a product with a PLU of 9999 to exist in fops6
            database.
    MOD TB  8 digit source barcode loop hole now requires 'PO' followed by
            6 digits.

1.042  24/05/2004
    FE  TB  Now re-initialises printer acknowledgement protocol SYSVAR(18)
            before printing each label - required by PF4i printer.

1.043  17/12/2004
    CE  TB  Now uses HSL library NewUart_Init().

1.044  25/05/2005
    FIX TB  Add Manual Weight wasnt doing anything.
    MOD TB  Fixed weight ingredients:
            If MAUNDERS then
              enter key just adds weight requirement for container as having
              been done - like a manual add weight
            else
              reverted to allowing the user to just hit the enter key
              without weighing anything providing the fixed weight does not
              take it over the high tolerance for the ingredient (otherwise
              Add Ingredient instruction appears but with the addition qty
              not matching the tolerance bars).
    FE  TB  Order Detail Report now shows actual ratio of ingredients in mixes
            if the Show Mix Details option is selected.

1.045  16/06/2005
    FIX TB  Problems related to ingredient being on more than one line of
            an order:
            a) Costs on Order Costing Report doubled up.
            b) Weight done figures on Order Detail Report doubled up.
            c) Weight done figures in mix viewer (F4) doubled up.
            d) Weight done and costs were low in Order Summary Report.
    FIX TB  Order Costing Report for multiple orders wasnt reseting order
            totals between orders.

1.046  23/11/2005
    FE  TB  LAZENBY compilation now has:
            a) Stock issues will be sent to FOPS6 even if no barcode is
               scanned unless new ini: [SCALE] SFXSendIssuesToFops6=NO is
               set. PLU for issue transaction will be extracted from fops6
               product that has a product code matching the current ingredient.
            b) Batch number on transactions is now zero filled (relevant if
               auto batching is switched off).
            c) Batch number on issue tran to fops6 now matches batch number
               on formix tran, was 8 digits calculated from '1'+ord no+mix no.

1.047  28/04/2006
    FE  TB  Two inis added:
            [SCALE] SFXBatchNumbersReqd
            [SCALE] SFXRecallLotNumbers
    FE  TB  Ingredient Usage Report now has a Lot No filter.

1.048  07/09/2007
    FIX MS  Fixed ingredient Assignment report so that is uses full length
            of lot no from selection criteria.

1.049  28/01/2009
    CE  SW  Conversion to FPC compiler

1.050  10/06/2011
    FE  TB  SOURCE_CODES table added to database to store source barcodes.

1.051  29/09/2011
    FE  TB  Transaction Viewer now shows source barcode.

1.052  08/11/2011
    FE  TB  Filepaths in ini file now limited to 50 chars, were 30.

1.053  06/01/2012
    FIX TB  Product line editor now show fields properly. Bug intro 1.049.

1.054  09/07/2013
    MOD TB  Dummy version to hold conversion SQL script CNVF1054 which is
            required by SFormix for Windows.
1.055  05/11/2013
    MOD TB  Dummy version to hold conversion SQL script CNVF1055 which is
            required by SFormix for Windows.

1.056  11/06/2014
    FE  TB  FOPS6 like inis added for printer setup: [PRINTER] FXDEFPRINTER1,
            FXDEFPRINTER2, FXDEFPRINTER3.
1.057  04/06/2024
    FE  SW  Added Ingredient Reqd to Order Detail report
    FE  SW  Order editor F1/F2 to Change number of mixes after order started.

1.058  08/07/2014
    MOD TB  Moving an order status back to WIP no longer clears complete
            status on mixes and sets mix done count down to zero.

1.059
    MOD SW  Lot Codes now 14 characters were 8. And other database changes.

1.060
    FIX TB  CONV1059.SQL no longer creates unnecessary index on LOT.FIL
            and case sensitivity and data types now match conversion exe.
    FIX TB  New SQL script CONV1060.SQL added to fix Cookstowns database
            after applying the original CONV1059.SQL.
    FIX TB  LotIngredient Reference Editor no longer Range Check Errors on
            leaving lot code field.
    CE  TB  Missing FXUTL.PAS added to SVN.

1.061
    FIX TB  Uninitialised data no longer written to INGRED_USAGE table.
            Reports on INGRED_USAGE table now find records correctly.
    FE  TB  Ingredient Usage Report filtered with old dates is now quicker.

1.062
    MOD TB  'Job_Number' field added to Recipe_Header table using
            CONV1062.SQL. Recipe Editor now has Job Number field instead of
            'Barcode' field (unused).

1.063  20/11/2014
    FE  TB  Temperature and TempChecked fields added to Transactions table
            using CONV1063.SQL. Temperature field is visible from the
            Transaction viewer.

1.064  20/04/2016
    FE  TB  Trans_Warnings table added to database using CONV1064.SQL.
            Table tidied by Works Order deletion.

1.065  24/04/2017
    CE  TB  Obsolete compiler defines for HSL customer removed.
       25/04/2017
    FE  TB  Recipes can now be flagged as 'Obsolete'. Mods include:-
            a) Function added to "Edit Recipe" browser to change "Obsolete"
               status of a Recipe.
            b) Selecting an obsolete recipe for a Work Order or Product will
               raise an error message.
            c) Obsolete status is displayed in Recipe Editor and Recipe
               reports.

1.066  19/02/2018
    FE  TB  Ingredient Editor now has radio button for 'Auto' process type.

1.067  17/05/2018
    FE  TB  Trans_Warnings table (FXTRANWR.FIL) now has SrcConcessionNo
            field and an index on that field.
            CONV1067.EXE initialises new field add adds index to data file.
            CONV1067.SQL adds new field and index to DDFs.

1.068  23/05/2019
    FIX TB  Recipe CSV import:-
            . No longer leaves half of the original Recipe Lines at the top
              of the list before appending CSV recipe lines.
            . Now uses ratios in the CSV to calculate and set the percentages
              on each Recipe Line.
            . No longer tries to merge multiple references to the same
              Ingredient Code on a CSV line into one Recipe Line.
    CE  TB  When RECIPEBYPHR is not defined: CalculateRatiosFromPHR()
            (was named CalculateRatios) now sets the percentage on a Recipe
            record's lines if none of the lines currently have a percentage,
            did do nothing.

1.069  07/08/2019
    FE  TB  Program startup now checks that ini files settings: FXFILEPATH
            and FXTEXTPATH, are not the same i.e. the ini file defines
            at least one of these paths. If the check fails, advice about ini
            files is written to the "command prompt" screen.
    FE  TB  FXSharePath now defaults to FXFilePath.
    CE  TB  More "recipe terminal only" code is now ifdef'd out.
            *)
