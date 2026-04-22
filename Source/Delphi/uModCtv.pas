unit uModCtv;

interface


implementation

(*

v8.0.0.0
  Initial Windows Version

v8001 02/08/07
  [ms] Taken off cancel button from log in screen.
  [ms] Now no longer exits after three login attempts.
  [ms] Password of 364667 put in for 'Exit' command.
  [ms] Now trims log in password from database for check to work correctly.
  [ms] Fixed download description on the printer during label download.
  [ms] Fixed bug where mix no could be changed buy another terminal and current
       terminal would use the wrong mix no during the calculations.

v8002 02/08/07
  [ms] Added in Abort Mix button.

v8003 03/08/07
  [ms] Fixed current user when logging out then logging in again.
  [ms] now auto updates every 10 seconds if its changed in order browser
       and process orders.
  [ms] fixed bug with container numbers during proccessing orders.

v8004 07/08/07
  [ms] Fixed bug where it now moves min and max weights around to match the scale tolerances.

v8005 08/08/07
  [ms] Changed lot and batch request stuff.
  [ms] Fixed batch number not showing.
  [ms] Fixed problem with exact matching of value on weight graph.

v8006 08/08/07
  [ms] Fixed bug where adding a new ingredient usage wasnt adding in the weight.
  [ms] Now goes back to ingredient select if they cancel batch or lot number entry.
  [ms] Now shows the newly entered lot and batch numbers when entered.

v8007 09/08/07
  [ms] Now takes longer to open up the com ports and will also try 5 times to open them.
  [ms] Fixed bug where could say another user had weighed an ingredient,
       where a rounding problem occurred.
  [ms] Made a couple of options that are not yet setup not visable in the setup screen.

v8008 09/08/07
  [ms] Changed print details so now doesnt include transaction data like old terminal.
  [ms] Fixed product auto refresh after weighing off a complete ingredient.
  [ms] Made adding data to ingredient usage file safer.
  [ms] Will now move on to next ingredient if following the product list.
  [ms] Fixed bug where part weighing last ingredient stopped you from being
       able to move on the product list.
  [ms] On order list page up and down buttons now move it by a page rather than a line.

v8009
  [ms] now space pads string fields in transactions and ingredient usage records.
  [ms] Now makes batch and lot number entries uppercase to work with old formix program.

v8010
  [ms] Fixed bug with lot and batch numbers intro 8009.
  [ms] Now does Lazenbys special batch numbering when entering a transaction.

v8011
  [ms] Fixed bug where could be on the wrong order line number during adding ingredients.
  [ms] now stops order list moving when the orders are updated in the background.

v8012
  [ms] Fixed bug in batch number calculation intro v8010.

v8013
  [ms] All fops6 issue transactions stuff added in.

v8014
  [ms] Fixed bug in finding next incomplete mix no.

v8015
  [ms] Extra message put in so will show reason not connecting to fopsdm.

v8016
  [ms] Fixed bug where mix rec not being initialised on order list update in
       edit window, caused 'Invalid Floating Point Error'

v8017
  [ms] Taken out sql hour glass after complaints.
  [ms] If error occurs in order refresh will now always re-enable buttons.

v8018
  [ms] New ini added to allow one scan to work for lot, batch and source barcode.
  [ms] New ini added to allow product override.
  [ms] New ini added to allow six digit source barcode.

v8019
  [ms]  when correct product selected and was showing wrong error message.

v8020
  [ms] Fixed user override password problem.
  [ms] Fixed group product lookup from fops.

v8021
  [ms] Fixed bug where product override enabled and product was the correct one,
       if true then went into a loop that never exited.

v8022
  [ms] Now always relocates order header before editing a value to stop error 88.
  [ms] Fixed bug where override user not being recorded in the database.

v8023
  [sw] Lots of code revised/refactored to remove duplication and aid readablility
  [sw] Ingredient codes that have spaces no longer generate exception
  [sw] Implemented 'No Tare' option for ingredients
  [sw] Ingredient can now be on a recipe more than once without causing error
  [sw] fixed Preparation area restriction bugs.
  [sw] fixed bug with clicking on main screen grid with no recipes exception
  [sw] fixed bug with login screen allowing entry for all

v8024
  [sw] fixes to transaction label printing
  [sw] fixed mix ticket printing as it did not work
  [sw] will now work with FDL and LDF Direct mode detected from label filename

v8025
  [sw] added button to change global lot/batch in process options menu.

v8026 09/01/2009
  [sw] added LotIRef table to dictionary and lookup of lot number on ingredient
       selection.

v8027 13/07/2009
  [sw] Fix to mix ticket printing ingredients from other recipies.
  [sw] removed Versionconst, version now from resource fork

v8.0.2.8 10/08/2009
  [sw] Added extra label tags *MAXLIFE, *PORDER these retrieve data by using
       the lot number as a reference to a fops6 transaction MMSSSSSS where MM
       is machine and SSSSSS is the serial no. (Ingredient area DRYGOODS ONLY)
  [sw] extended *INGREDIENTINFOXnn to include Ingredient code & where ingredient
       is area DRYGOODS lookup from fops6 Maxlife and Purchase Order.

v8.0.2.9 20/08/2010
  [tb] Added *TRACEDESC for DRYGOODS ingredients and where lot number = fops6
       transaction MMSSSSSS

v8.0.3.0 09/09/2010
  [tb] TdmFops.VerifyFopsBarcode():-
       a) Now returns SourceProdCode instead of conditionally setting
          TdmFops.OverrideProduct.
       b) No longer checks related fops trans product is ok as ingredient
          (now up to caller).
       c) 8 digit barcode now assumed to be mid and rn of fops6 tran.
  [tb] TdmFops.ProductIsInGroup() now does just that check, did take in
       and parse a source barcode.
  [tb] Prompt for override user on accepting a non-perfect fops tran as the
       source is now generic code - udmFormix.OverrideExists.
  [tb] Compile define FOPSTRACELINK now replaced with:
       a) New registry switches  SFXAllowPOBarcode=YES and
          SFXAllowTranNotFound=YES.
       b) Registry switch FXSendFopsIssueTrans=YES.
  [tb] GetASourceBarcode() now handles error codes from VerifyFopsBarcode()
       in particular displays valid barcode lengths to user.
  [tb] PreWeighingSetup():-
       a) Now does it's own source product code check; and now handles it
          before life date checks etc.
       b) A fops transaction without a life date now still has its product
          code and emptiness checked, was skipped.
  [tb] New option to control source barcode rejection overrides remotely. Mods
       include:
       a) New registry file option SFXRemoteOverrides=YES replaces "Override
          User" entry screens with an option to write an override request to
          the new database files. All source rejections are recorded in the
          new database files regardless of whether an override request is made.
       b) Four new database tables RO_REJECTED_OFFERING, REJECTIONS,
          REJECT_REASONS and RO_OVERRIDES
       c) When a six or eight digit source barcode is entered by the user
          ValidateFopsBarcode() will now try to find the full label barcode
          using the FOPS LABEL_DETAIL file. Overrides are related to a
          combination of order number, ingredient code, rejection reason and
          fops label barcode.

v8.0.3.1 18/10/2010
      [tb] Full issue-off-stock transaction (drip loss) sent to fops:
  MOD      a) Now has batch number 99999999, was batch number on ingredient
           transaction (zero would get autobatched).
  FIX      b) Now sent with zero weight (full issue), was sent with current
           scale weight!
  CE  [tb] Unused "registry" settings commented out.

v8.0.3.2 26/11/2010
  CE  [tb] Pervasive tables now use one session per database by calling
           MakeConnection on new created datamodules.

v8.0.3.3 ????

v8.0.14.4  10/06/2011
  FE  [tb] Source barcodes are now saved in a new table SOURCE_CODES.
           CNVF1050.SQL needs to be run first with FXTRANS.FIL renamed.
           CONV1050.SQL needs to be run next with FXTRANS.FIL restored.
           FORMIX v1.050 needs to be run to create the new data file SRCCODE.FIL.
  FE  [tb] New registry setting added: SFXAllowBarcodeLength=14; can be edited
           from scales setup screen. Affects source barcode scan validation.  

v8.0.14.5  28/09/2011
  FIX [tb] Manual weight option now works when a scale is connected.
  MOD [tb] non-working Manual Tare Weight option removed.

v8.0.14.6  03/11/2011
  CE  [tb] Exceptions raised in GetTotsForMixLine() (reads trans file) now
           caught and handled.
  CE  [tb] GetTotsForMixLine() now uses SetRange instead of FindNearest in
           an attempt to stops transactions not being read and allowing
           too many ingredient weighings.
  CE  [tb] Order list for date no longer blanks out after an exception.
  AE  [tb] 'too high' and 'too low' were 'to high' and 'to low'.

v8.0.14.7  06/12/2011
  FIX [tb] Left arrow key now works when a mix is selected that has some
           ingredients completed and are off the left hand side.
  CE  [tb] Windows are no longer stay-on-top when run from the IDE.

v8.0.14.8  08/12/2011
  FIX [tb] Automatic "step on" to next mix and handling of order completion now
           works when running with a PrepArea.
  FIX [tb] Manual weight indicator '(man)' now gets cleared when ingredient is deselected.
  FIX [tb] Ingredient weight reqs over 999.99kg now possible without raising
           'not a valid floating point number' error.
  FIX [tb] Mix is now only marked as Complete when all ingredients are completed,
           not when ingredients in PrepArea are completed.

v8.0.14.9  16/12/2011
  CE  [tb] Obsolete functions commented out:-
           AllLinesCompleteForCurrentMix(), udmFormix.DelayCurrentMix().
  CE  [tb] All TPvTable Posts now wrapped in a database transaction with
           exception messages to avoid no-wait record locks raising an error 84.
  CE  [tb] In multiple table database-transactions, Order Headers are posted after
           MixTotals to avoid deadlocks with MarkMixAsCompleteIfNecess().
  CE  [tb] CancelRange() at end of GetTotsForMixLine was raising a 'Record
           not found' message; now avoided by closing and re-opening the trans file.
  FE  [tb] Part-Issue stock command to FOPS now only sent if ingredient transaction
           is successfully saved.
  CE  [tb] MarkMixCompleteIfNecess(), was named SetMixCompleteAndUpdateOrder(),
           no longer recalcs mix completion, and only increments order header
           mix done count if mix is not currently marked complete.
  FIX [tb] Aborting a mix now decrements Mix Done count on order header by 1,
           did decrement by the number of order lines!
  MOD [tb] Selecting an Order's mix will now cause the mix to be re-checked for
           completion status setting and adjust the mix done count on the
           order header if necessary.
  MOD [tb] Part Weigh button no longer accepts weights that are in tolerance.
           User has to use full weighing button which has extra post
           transaction handling.

v8.0.14.10 27/07/2012
           v8.0.3.301 and 8.0.3.302 from branch from 8.0.3.3 merged in:-
           Wrong Source Product error message now shows source label barcode.
           SFXNoAutoCancelOfTares=TRUE added - "NoTare" ingredients can have
           container filled whilst off the scale pan.

v8.0.14.11 01/08/2012
  CE  [tb] ufrmFormixScalePassword unit deleted - replaced by new function
           GetTerminalPassword() in ufrmFormixStdEntry.
  FE  [tb] New transaction browser added to Options menu enables user to
           view lot numbers and batch numbers used for each ingredient in
           work order.
  FE  [tb] New terminal 'Setup' option 'Allow Keyed Barcode' can be used to hide
           keyboard when source barcode prompt appears for source
           barcode. A passworded button makes keyboard temporarily visible.
  CE  [tb] Global variable frmFormixStdEntry removed so that stacked
           text entry dialogs can be displayed.
  CE  [tb] GetRegBooleanDef() in BaseDM now overriden by TdmFormix so that
           all ini type strings for boolean settings can be used.
  MOD [tb] All On-Off type settings in REGISTRY table now accept any one of
           '0'/'1', 'false'/'true', 'F'/'T', 'NO'/'YES' etc. Settings affected:-
             FXLastMixCompensation anything specified other than 'YES' was "off".
             FXRoundWeights        anything specified other than 'NO'  was "on".
             SFXPromptForSource    anything specified other than 'YES' was "off".
             SFXSourceOptional     anything specified other than 'NO'  was "on".
             AcceptLabelWeight     anything specified other than 'YES' was "off".
  FIX [tb] Abort current mix function now deducts transactions off of order
           line totals.

v8.0.14.12 08/08/2012
  FIX [tb] SFXAUTOADDCOST=TRUE no longer causes an exception on weighing an
           ingredient due to LotCost table not being opened and null fields
           not being accepted in table.

v8.0.14.13 10/12/2012
  FIX [tb] Weight acceptance validation done by dial is now the same as that
           done else where to avoid 'Incorrect Weight' error messages when
           dial shows the weight as acceptable.
  MOD [tb] Dial zones:-
           a) Weight acceptable zone (green) now shrinks if ingredient weight
              tolerance is very tight (but never dissapears), was always
              25% of dial.
           b) Needle in over-weight zone (red) is now more sensitive when
              weight required is small when compared to scale's max weight;
              did give no feedback to the amount of over-weight.
  FE  [tb] FXWtRoundMod (smallest scale weight increment) now editable from
           Scale Setup window.
  CE  [tb] 'FXWtRoundMod' and 'ScaleIncrement' (Dec.Places) registry table
           settings now private to dmFormix with getters and setters (ensures
           consistent default values).
  CE  [tb] GetFloatNumStr():-
           a) parameters changed so that max length and decimal places can be
              specified without specifying the display format.
           b) The current value to be edited can now be passed through instead
              always displaying zero.
  FIX [tb] Remaining weight to add (shown in centre of window in large digits)
           now takes into account the possibility of low tolerance (rounded to
           scale increments) being higher than actual weight remaining when
           shown in a higher precision than scale allows.
  AE  [tb] 'Touch to Accept' message on dial now replaces misleading '%' label.

v8.0.14.14 16/01/2013
  FE  [tb] Ingredient scroll bar:-
           a) now shows new field: 'Wt.Reqd. by Mix'.
           b) now shows label 'Next Weight' (for current container) instead of
              'Weight Remaining' (more room for weight figures).
           c) Current selection now has Aqua background colour, was dark blue.
           d) 'COMPLETE' status message now overwrites 'Next Weight' line, was
              below it (more room for Wt.Reqd. by Mix).
  FIX [tb] Aborting an ingredient selection, e.g. by not scanning a source barcode,
           now clears ingredient information from top left panel and prompts user
           to select an ingredient, did leave 'Add Ingredient' instruction with
           ingredient details still displayed in top left panel (even though
           weight meter would not respond).
  FIX [tb] Part-Weigh completion now reselects current ingredient correctly
           e.g. prompts user for another source barcode, did show 'Add Ingredient'
           instruction without actually re-selecting ingredient.
  CE  [tb] Ingredient auto re-selection e.g. after Part-Weigh, should now cope
           with two order lines with the same ingredient code displayed in the
           scroll bar at the same time.
           (seeks panel by line number instead of code).

v8.0.14.15  27/03/2013
  FE  [tb] QA logging for mixes via web service now available.
  MOD [tb] New ini [DATABASE] QAServiceURL added for QA logging.
           (example '=http//server:portnumber/HSL.WC2.QAService')
           Not defined disables QA logging.
  CE  [tb] PrepArea filter now only read from registry table when udmFormix is
           created, was many times in mix calculations.
  CE  [tb] Date selector on main window now calls a new form with calender
           month control, did make overlapping panel with control visible.
  FIX [tb] Mix completion weight percentage bar now reflects mix weight done,
           did show random results.

v8.0.14.16  04/04/2013
  FIX [tb] Completing all the ingredients for one prep area, for all mixes,
           no longer leaves current mix number on order header one higher than
           allowed (bug intro. 8.0.14.15).

v8.0.14.17  03/05/2013
      [tb] Source item weight check now also checks item status can be issued.

v8.0.14.18  08/05/2013
      [tb] With FXSendFopsIssueTrans=YES, if the ingredient weight less than the source
           weight, the user is now warned and has to confirm to continue.
      [tb] With FXIngredientsInFops6=YES and SFXAllowProductOverride=NO, if the the source
           product does not suit the ingredient the user is now given an error message before
           being stepped back in the program.

v8.0.14.19
      [sw] Two scale configuration.

v8.0.14.20  09/07/2013
      [tb] CNVF1054.SQL adds QA_Complete field to Mix_Totals table definition.
           QA_Complete field gets set if quality assurance process is completed
           for the mix.
      [tb] Quality Assurance process button added to Work Order Options menu.
      [tb] Automatic QA process fired by first ingredient selection for mix now
           removed.
      [tb] Mix detail panel in Work Order window:-
           a) Now shows a Mix QA checkbox. Clicking it will start QA process.
           b) Now shows weight and mixes done progress in separate boxes.
           c) Now always show correct mix weight progress, did show mix weight
              progress of last order in main window list.
      [tb] Orders list box in main window:-
           a) now shows a "QA completed" column.
           b) No longer tries to refresh unless list box is active and
              a date has been selected.
           c) Non-bold, black font in list box indicates QA has not been
              completed but ingredient preparation has.
           d) Order number sequence is now lowest at the top, was at the bottom.
      [tb] Change/View Mix window now shows "Mix QA Complete" column.
      [tb] Ini file section for secondary scale indicators now in the format
           'Scale.TerminalName.ScaleNumber' e.g. 'Scale.Scale1.2'; was without
           the second full stop.

v8.0.14.21  12/07/2013
      [tb] Low level database functions moved from TdmFormix to new ancestor TdmFormixBase.
           New unit udmFormixBase is located in a new 'Database' sub-folder and will be shared
           with FOPS8.

v8.0.14.22
      [sw] Rinstrun Scale Indicator support (ProductVersion shows as 8.0.14.21).

v8.0.14.23  05/11/2013
      [tb] CNVF1055.SQL adds the following fields to MIX_TOTAL table:
           Meat_QA_done, Seasoning_QA_done, Water_QA_done.
           One of these fields will be used instead of QA_Complete field
           (see 8.0.14.20 mods) according to preparation area of terminal;
           QA_Complete field is now redundant.
      [tb] QA Done flags are no longer set to true on selecting the QA entry
           option when there is no connection to a QA web service.
      [tb] View/Change Mix window now shows relevant new QA flag (other QA flags
           can be seen by scrolling sideways).

v8.0.14.24  14/02/2014
      [tb] If the source container scanned relates to a FOPS transaction that
           has less weight than the ingredient about to be weighed, then the
           user no longer has an option to continue unless a new "registry"
           table setting is defined in folder "Scale.scalename",:
           SFXAllowWtAboveSourceWt=TRUE.
      [tb] Ingredient is now always de-selected if PreWeighingSetup conditions fail
           (e.g. source barcode relates to FOPS transaction without weight in
           stock); was only when SFXUseOneScanOnly=TRUE

v8.0.14.25  19/02/2014
      [tb] New "registry" table setting SFXQAAtMixStart=TRUE, in folder
           "Scale.scalename", switches on QA entry when an ingredient is
           selected for a mix that has not had QA completed.

v8.0.14.26  03/04/2014
      [tb] Source ID field added to mix requirements panel; shows "label barcode"
           of FOPS stock item just scanned/entered, or if non-existent, the actual
           source barcode scanned/entered by the user.
      [tb] Source barcodes with a length greater than 20 characters are now assumed
           to be FOPS stock items and are now subject to the same attribute checking
           as 20 digit barcodes; were previously rejected.
      [tb] Manual weighings:-
           a) now show 'Use Part Weigh button to accept' message, instead of
              'Add Ingredient' message, when weight is less than required.
           b) Tare button is now hidden.
      [tb] Registry table now read and cached on entering work order, was read
           continuously during process steps and scale reading updates.
      [tb] SFXAcceptLabelWeight=TRUE now switches ingredient weighing to a manual
           weight matching that currently on the scanned FOPS transaction; setting
           was previously ignored.
      [tb] Source barcode entry, when SFXUseOneScanOnly=FALSE and SFXAllowKeyedBarcode=TRUE,
           no longer "starred out" as if it was a password.
      [tb] Source barcode entry, when SFXUseOneScanOnly=FALSE, now accepts up to
           36 characters, was 33.
      [tb] New "registry" setting SFXAddMixToFopsStock=TRUE (editable via SETUP
           window):-
           a) Changes mix label barcode to 31 character format
              Barcode format = 'M' followed by 30 digits: OOOOOO SS MMMM PPPPP ddmmyy WWWWwww.
           b) Sends an Add-to-Stock command to FOPS when a mix is completed (over all
              prep areas). Requires FOPS to have a product code that matches the Recipe
              code (mix cannot be marked as complete if not).
      [tb] Printing *CONTRANGE on ingredient label no longer potentially causes other
           "star" details to be printed from the wrong transaction.
      [tb] Error message relating to connection to FOPS database now shows database
           name.
      [tb] Current mix totals calculations no longer use same Transactions file
           handle as CreateTransaction function to ensure current transaction details
           are printed correctly.
      [tb] Code change for no significant reason - may be usefull later: With
           SFXAllowTranNotFound=TRUE and a related fops tran for a 20 digit barcode
           is not found, dmFormix.OrigSourceWtKg gets set to the weight in the barcode.

v8.0.14.27  07/05/2014
      [tb] New "registry" setting BatchPrefixForFops=12 (editable via SETUP window)
           can now be used to convert the FORMIX six digit batch number to a FOPS
           eight digit batch number when SFXSendFopsIssueTrans is true.
      [tb] More registry settings cached on entering a work order.
      [tb] GetIntegerNumStr() and GetStdNumericEntry() now return '0' by default,
           did return '';
      [tb] Numeric entries in Setup window no longer lose current values when
           keyboard is displayed.

v8.0.14.28  14/05/2014
      [tb] Label printing no longer access violates if FopsDatabaseName not defined
           in ini file.
      [tb] Extra exception handling added to label field calculation.

v8.0.14.29  20/05/2014
      [tb] *BATCHNO and *LOTNO now work consistently on Mix labels (will print
           first non-blank batch number and lot number recorded in mix when listed
           in order line sequence).

v8.0.14.30  22/05/2014
      [tb] Part-Weigh followed by a valid source barcode for
           SFXAcceptLabelWeight=TRUE (manual weighing) no longer sets process
           step to 'Remove container or Semi-Auto Tare'.

v8.0.14.31 14 Digit barcode scan for lazenby LLLLLLCCCCCCCC where L=LOT C=FopsProduct/Group Code

v8.0.14.32 Attempted fix to prevent nav barcodes (lazenby) being sent to fops

v8.0.14.33 Batch number sent with Add to stock for Mix
           When using source barcode weight then auto accept by clicking analog meter
           registry option SFXJulianBatchNumbers added to prefix batch numbers < 1000 with day number

v8.0.14.33 Add Batch prefix when sending mix add to stock to fops

v8.0.15.1 / 1.059 Lot number extended to 14 Digits, string data types from VARCHAR to CHAR

v8.0.15.2  New registry setting MixTicketsAnytime=NO added to stop the printing of
           mix tickets before the mix is complete over all prep areas, was defaulting
           to this behaviour since v8.0.14.26.

v8.0.60.1  03/09/2014
      [tb] FORMIX.exe should be upgraded to 1.060 (run special SQL at Cookstown).
      [tb] New "registry" table setting for defining the lengths of NAV barcodes.
           Execute the following SQL to add lengths 14 and 18:
           INSERT INTO REGISTRY VALUES ('NavBarcodeLengths', '14,18', 'Scale.')#
           Only barcode lengths 14 and 18 can be interpreted, was only 14.
           Product code in barcode can now have trailing spaces.
      [tb] LotCost table is now opened on program startup and shows a message
           if table structure has not been changed by CONV1059.SQL.
      [tb] LotIRef table is now checked on startup (should always exist since v1.059).

v8.0.60.2
      [sw] PromptForBatchOnOrderChange=True, PromptForBatchOnMixChange=True added
           to control batch number prompting.

v8.0.60.3  25/09/2014
      [tb] SFXAllowProductOverride=YES now works with Lazenbys Nav barcodes.

v8.0.60.4  16/10/2014
      [tb] Tare button no longer does anything if scale indicator is currently minus.

V8.0.60.5  Allow Manual Weight option in settings dialog enable/disable manual weight/tare options.
           "Incorrect source product for ingredient" error no longer exits to order list.

v8.0.60.6  11/11/2014
      [tb] SFXJulianBatchNumbers registry setting now obsolete.
      [tb] New "Scale.scalename" registry setting 'SFXAutoBatchFormat' added. Options:-
             a) not defined or equals nothing: Manually entered Batch numbers are not changed.
             b) '=DDD': Batch numbers entered with less than four characters will be padded
                with leading zeroes to make three characters and then prefixed with the day
                number of the year* e.g. User enters '35' on February 1st, Batch number in
                terminal will be set to '012035'.
             c) '=DDDJJJ': If the user does not manually a batch number or Global Batch
                number the batch number in the terminal will be set to the day number of
                the year* followed by the Job Number set on the Recipe. If a batch number
                is manually entered then the batch number set in the terminal will be
                as for '=DDD' setting.

                *DDD changed to order schedule date in 8.0.60.8

v8.0.60.7  20/11/2014
      [tb] udmFormixBase unit version number now increased to 4. Changes:-
             a) New "Scale.scalename" registry setting 'SFXPromptForTemperature' added.
             b) Memory tables added for caching Ingredient and Recipe descriptions.
      [tb] New terminal option added to prompt for ingredient's temperature before
           weighing (requires FORMIX database v1.063). Temperature is displayed on
           Ingredient Details panel during weighing process and recorded on transaction.

v8.0.60.8  26/11/2014
      [tb] 'DDD' in SFXAutoBatchFormat setting now indicates "order's scheduled day of year",
           was "current day of year".
      [tb] With SFXPromptForTemperature=YES:-
           a) Temperature prompt now defaults to blank, was -273.1.
           b) Temperature prompt no longer stops the process if the cancel button
              is pressed (no temperature is recorded on the transaction).
           c) Temperature prompt no longer stops setting "SFXAcceptLabelWeight=TRUE" from
              creating a weigh transaction without pressing the touchscreen "dial".

v8.0.60.9  11/05/2015
      [tb] udmFormixReport now uses raIDE to enable report designer to edit Calculations.
           udmFormixBase version number now 5 was 4.         

v8.0.60.10 09/03/2016
      [tb] Now uses library 1.144 so that the command line can specify "Mainmenu.ini"
           file lines which are to be used if "Mainmenu.ini" cannot be read.
      [tb] uIni.FormixIni is now just a wrapper for uIniUtils.AppIni .

v8.0.60.11  17/03/2016
      [tb] New registry table setting NavBarcodeFormat=PR08,LT10 makes Nav barcode
           decoder extract product code from beginning of barcode instead
           of the end.

v8.0.60.12  30/03/2016
 HSL-3584
      [tb] New 'Select Operation' window inserted on startup, after Login window.
           Operations available:-
           1. 'Recipe Orders' button takes user to Order Schedule window.
           2. 'Clear Item from Stock' button allows user to issue a barcode to
              batch zero; only enabled if new registry setting 'SFXModeIssue' = TRUE.
           3. 'Issue Item to Production' button allows user to issue a barcode to
              a FOPS "batch"; only enabled if new registry setting 'SFXModeIssue' = TRUE.
           Use script 'InsertModeIssue.SQL' as a template for setting SFXModeIssue to true.
 HSL-3585          
      [tb] New option in Setup window: 'Copy FOPS Trans.Source as Lot' enables "Source
           Barcode" of a scanned FOPS label to be used as the "Lot No" for the next
           weighing.
      [tb] Lot code entry is now done after source barcode verification, was before.     
      [tb] Login window now displays server name and database name.
      [tb] Order schedule window no longer stays on top of other applications unless
           new "Registry table" setting is added: 'SFXProgramStaysOnTop' = TRUE.
           Potentially avoids SFormix pop-up dialogs being hidden by the main window.
      [tb] Keyboard window now has "stay on top" attribute to avoid being hidden by
           other "stay on top" windows.

v8.0.60.13
 HSL-2400
      [tb] Overrides of 'Wrong source product for ingredient', 'Source has gone past
           its life date', 'Source is empty' and "Source weight is less than weighing"
           warnings are now saved in Trans_Warnings table (requires FORMIX version 1.064
           or later).
      [tb] Enter Manual Weight option now disabled if an ingredient is not selected.
      [tb] Tare button no longer flashes whilst no ingredient has been selected.

v8.0.60.14
 HSL-3653
      [tb] Program no longer gets beyond start-up if a connection to the specified FOPS
           database is not made and SFXSendFopsIssueTrans=true or
           SFXAddMixToFopsStock=true.
      [tb] Error messages now replace program "crashes" where Source Barcode validation
           requires access to the FOPS database but a connection has not been made.

v8.0.60.15
 HSL-4250
      [tb] New terminal setup option added: 'Mix Ticket scan required'
           (registry setting SFXMixScanAtOrderSelect); when switched on will make
           the program insist that a related Mix Label barcode is scanned when a Recipe
           Order is selected by the User. When the Order is displayed it will be set to
           the Mix Number related to the Mix Label.

v8.0.60.16
 HSL-4336
      [tb] New label star command '*RECIPEPLU' prints five digit FOPS PLU related to
           recipe code.

v8.0.60.17
 HSL-HSL
      [tb] Batch "blank" no longer stops part-issue commands being sent to FOPS and
           showing error message: ''' is not a valid integer value'

v8.0.60.18
 HSL-4469
      [tb] Registry table setting NavBarcodeFormat can now be set to PR08DT06LT10
           to indicate that "NAV" barcodes MAY contain a life date after the eight
           character product code, in the format YYMMDD.
      [tb] Source barcodes that match one of "NavBarcodeLengths" and have a valid
           YYMMDD date in the position defined by "NavBarcodeFormat", and the
           year of the date is in the range of five years ago, to twenty years
           in the future, will:-
           1. set the terminal Lot number to the characters after the date, instead
              of the characters after the Product code.
           2. have the date checked for expiry and errors handled in the same way
              as for 20 digit HSL barcodes (requires "override user" to proceed).

v8.0.60.19
 HSL-4469
      [tb] 20 digit barcodes starting with a number can no longer be recognised
           as a Cranswick NAV barcode.

v8.0.60.20
 HSL-4484
      [tb] With Registry table tag "PrepArea" set to a value other than '*', the
           Orders list for a selected date now:-
           a) Shows the mixes done according to the number of mixes that have
              been completed in the "PrepArea"s (not neccesarily completed in all
              preparation areas).
           b) Hides the Weight column.
      [tb] Orders List colour coding now modified so that Orders "completed" but
           still requiring QA are shown in a different colour to those Order still
           requiring ingredient weights.

v8.0.60.21
 HSL-4484
      [tb] PrepArea setting in Registry table can now be changed from the
           Terminal's Setup form.

v8.0.60.22
 HSL-4484
      [tb] Ingredient preparation areas now cached during Work Order processing.
      [tb] 'Incorrect Weight' error message no longer raised after accepting a
           "Manual Weight" (tolerance from last Order Line was being used when
           Preparation Area filter was not '*' - bug intro v8.0.60.20).
      [tb] The pivot for the dial pointer is now coloured green when the lowest
           acceptable scale weight for the ingredient tolerance is reached, was
           sometimes coloured yellow.
      [tb] Lowest tolerance weight now always accepted, was sometimes treated as
           if the weight was too low.

v8.0.60.23
 HSL-4484
  CE  [tb] Order List refresh now controlled by a new timer 'tmGridRefresh'
           (seperate from Clock timer).
  CE  [tb] Order List refresh interval is reduced to a second if the user scrolls
           the list.
  FE  [tb] Order List refresh now only calculates the mix-completion status for the
           Orders that are currently visible to the user and that have not been
           calculated in the last ten seconds. Uncalculated rows are shown in
           italic font. Mix-completion was calculated for every Order in the list
           when the list was refreshed.
  MOD [tb] Order List now has a 'CalculatedAt' DateTime field if Prep Area filter
           is not '*'.
  MOD [tb] Preparation Area filter now displayed at top of Order List window.
  CE  [tb] Order List now reliably rebuilt approx every five minutes, was rebuilt
           when the clock in the Order List window "ticked" onto the first second
           of a new ten minute segment of the hour.
  AE  [tb] Order List grid Cursor position now restored after a List refresh, did
           jump down to bottom of grid.
  MOD [tb] Exiting from a Work Order back to the Order List no longer initiates
           a full Order List rebuild.
  FIX [tb] Up and Down arrows in Order List window now move grid rows by one
           "page", did jump by 15 rows.
  FIX [tb] Selecting a Work Order by scanning a Mix Label barcode can no longer
           add the related Order into the main Order List if the Order is not
           scheduled for the Order List's date.

v8.0.60.24
 HSL-4697
  CE  [tb] TdmFormix.RefreshRegistryCache now reads and stores registry settings
           that were read and stored by ufrmFormixProcessRecipe. Registry table
           is now held open between reads.
  CE  [tb] PrintCurrentTransactionTicket() will now display the printer commands
           on the screen if communication with the Printer was not established
           (aids label print debugging).
  CE  [tb] Obsolete code and variables commented out.
  CE  [tb] PreWeighingSetup() code now in new unit uPreWeighingSetup, was in unit
           ufrmFormixProcessRecipe() (was done in preparation for another mode
           of weighing).
  CE  [tb] Unnecessary changing of edit field data in top panel whilst rebuilding
           ingredient scroller now removed.
  CE  [tb] Source Item, Lot No and Temperature edit fields are now all refreshed
           after PreWeighingSetup has been done.
  FE  [tb] Main menu window and Setup window now show the "Terminal Name".
           Main window uses a font that has different characters for upper case
           i and lower case l.

v8.0.60.25
 HSL-4697
  FE  [tb] Label printing now attempts to read star commands from a .LDF file
           first, before resorting to reading them from a .LAB file (like FOPS6);
           did only read them from a .LAB file.
  CE  [tb] Cached registry settings are now refreshed after saving Setup changes.

v8.0.60.26
  CE  [tb] . Duplicate declaration of REG_ScaleIncrement and REG_FxWtRoundMod removed from
             udmformix.
           . Unused SetLotNumber() removed.
           . TerminalName now on dmFormixBase was on dmFormix.
           . RefreshRegistryCache now virtual and called by dmFormxBase.MakeConnection,
             was called by dmFormix.MakeConnection.
           . All Registry settings are now read and set using new GetTermReg...
             functions (except for loading setting values into the memory table
             that defines all the attributes of the registry settings - used by
             GetTermReg... functions).
           . Registry settings used for target Mix Weight calculations are now cached.
  FE  [tb] All possible Registry table settings are now visible and editable from
           new Setup Menu option : 'Show Terminal Settings'.
  FE  [tb] 'Add to Stock' option added to main menu:-
           . Requires a connection to the FOPS database defined in the ini file.
           . Requires location of OCM program and OCM "ini" file to be defined by
             Registry Settings: 'OcmProgramFile' and 'OcmIniFile'.
           . The User is first asked if the item has been weighed as a Recipe Order
             Ingredient. If the answer is 'yes' then it assumed that the source
             item has already had it's weight reduced and all that is needed is
             an OCM Add-to-Stock operation, with a Source Barcode for traceability.
             If the answer is 'no' then it assumed that an OCM Dispense mode
             transaction is required so that the source item's weight will be
             reduced by the new items weight.
           . The User is prompted to scan a Source Barcode. The barcode needs to
             identify a FOPS "Transaction"; it it does not then a 'Failed to
             determine Product Code of Source Item' error message will be displayed.
           . If the Product Code of the Source Item matches a Formix Ingredient
             Code then only the Source Item's Product's Code will be offered to
             the User as the Product to be used in the OCM operation.
           . If the Product Code of the Source Item does not match a Formix
             Ingredient Code but does belong to one or more FOPS Product Groups
             that have a Code that match Formix Ingredient Codes then the FOPS
             Products that belong to those Groups will be offered to the User
             as Products that can be used in the OCM operation.
  FE  [tb] 'Update OCM PLUs' option added to main menu. This updates the PLU
           information stored on the Terminal for 'Add to Stock' operations
           (requires location of OCM program and OCM "ini" file to be defined by
           Registry Settings: 'OcmProgramFile' and 'OcmIniFile').
  FE  [tb] 'Configure Printer' option added to main menu. This option runs
           an OCM function for configuring Printers (some printers do not have
           a User Interface for configuration; requires location of OCM program
           and OCM "ini" file to be defined by Registry Settings: 'OcmProgramFile'
           and 'OcmIniFile').
  FE  [tb] An empty string value in the Registry settings will now cause the default
           value to be used; the default value was only used if a setting was not
           in the Registry table at all.
v8.0.60.27
  CE  [tb] . BuildProductList no longer called before frmformixProcessRecipe is
             is shown (aids auto-selection of ingredient, if required).
           . More use of cache of Ingredients.
           . RefreshOrderLines() commented out; was not doing anything.
           . DeselectCurrentIngredient() now ensures selection highlighting is
             removed from the Order Lines Grid.
           . Result of Locate() on pvtblOrderLine when an Order Line is selected,
             is now checked and an error raised if it returns false.
  AE  [tb] 'Enter Source Barcode' dialog window now shows a description of the
           selected Ingredient in the caption bar.
  FE  [tb] New Ingredient Process Type 'Auto' now handled.
           'Auto' ingredients will be recorded with minimal User intervention:-
           . They do not need to be weighed. The calculated weight for the
             Container is displayed as a manual weight entry. The User just
             needs accept the weight displayed.
           . Source Barcodes will not be prompted for (separately or as "one-scan").
           . Temperature will not be prompted for.
           . Ingredient ticket will not be printed.
           . Lot Code will be blank.

v8.0.60.28 [sw]
v8.0.60.29 [sw]
v8.0.60.30
  FE  [tb] . Terminal users now have to re-enter their passwords after a specified
             number of seconds of not using the touchscreen. This functionality is
             not active until the number of seconds is specified by runing SQL
             script (example for 120 seconds) :
             'INSERT INTO "REGISTRY" VALUES('SFXUserTimeoutSecs','120','Scale.');'.
           . To use a "source barcode" that relates to a FOPS or NAV stock item
             with an expired Use-By date, the User can now be prompted for a
             Concession number instead of an Override User code and password.
             The Concession number gets recorded in the Trans_Warnings table.
             To activate, run SQL script:
             'INSERT INTO "REGISTRY" VALUES('SFXAskforLifeDtConcessionNo','true','Scale.Scale1');'.
           . FOPS8 User codes (with a maximum of eight characters) can now be used
             on the terminals. Note FOPS8 User passwords are case sensitive.
             Activate by adding UseFopsUsers=1 in section [MAIN] of MainMenu.ini.
             Terminal program will not run if it cannot access FOPS database.
             FOPS8 users will need rights to 'Recipe Source Product override',
             'Recipe Source Life Date override' and 'Recipe Source is empty override'
             to be able to override source barcode rejection messages.
             FOPS8 users will need rights to 'Manual entry of Ingredient Weight'
             to perform a Manual Weight operation.
           . Users can now be forced to change their password after a specified
             number of days since last setting their password. This functionality
             requires [MAIN] UseFopsUsers=1. Activate this functionality by
             running SQL script:
             'INSERT INTO "REGISTRY" VALUES('MaxPasswordAge','90','Scale.');'.
  CE  [tb] Data entry forms now only "stay on top" of all other windows
           if the main form is "stay on top".
  CE  [tb] Program is now completely loaded into memory for execution in an attempt
           at avoiding exception C0000006.

v8.0.60.31
  FIX [tb] Data sent to the printer for a Mix Label now matches format defined
           by registry setting FXMixLabFormat, did match format used by
           Transaction Labels or, if undefined, format 'D' (bug intro. 8.0.60.25).

v8.0.60.32
  FIX [tb] Keyboard window key presses no longer raise a 'Send Keys, Failed To
           Set Hook' error message when running on Windows 10.

v8.0.60.33
  FE  [tb] New Setup option 'Show Mixes Done for Area' added (default value is
           true). Switch off to make:-
           1. "Mixes" fields on Terminal display the number of Mixes completed
              over all Preparation Areas instead of the number of Mixes completed
              in the Terminal's Preparation Area (if defined). Bold font on
              a line in the Orders List still indicates that Order is not
              completed in the Preparation Area (if defined).
           2. the Terminal's Order List to include a column that displays the
              progress of the Order as a percentage of total Order weight required.

v8.0.60.34
  CE  [tb] 'This Ingredient has been completed by another terminal' messages now
           show weight done and for what Mix Number, Order number and Line Number.

v8.0.60.35
 [HSL-5539
  FE  [tb] Label star command '*DATE' can now be extended with an adjustment in
           days in the format '+n' or '-n' e.g. *DATE+3.
 ]
v8.0.60.36
 [HSL-6087
  FIX [tb] With SFXPromptForSource=False and EnquireForLotNo=True the Lot Number
           prompt is now presented after selecting an ingredient, wasnt being
           presented at all (bug intro. v8.0.60.12).
  CE  [tb] TdmFormix member CurrentIngredientLot was named CurrentLot to help
           clarify that this is separate from the Global Lot Number.
  MOD [tb] Blanking out the Batch Number, that gets prompted after selecting an
           ingredient, now makes the Global Batch Number get used, did put a
           blank Batch Number on the Transaction.
  MOD [tb] Blanking out the Lot Number, that gets prompted after selecting an
           ingredient, now makes the Global Lot Number get used, did put a
           blank Lot Number on the Transaction.
v8.0.60.37
 [HSL-6625
  FE  [sw] Added option for Mettler Toledo Scale (Serial)
  FIX [sw] Ability to run without fops db dependency restored.
 ]

v8.0.60.38
 [HSL-6804
  CE  [tb] Mix completions are now logged in .\LogFiles\MixProgressLog.TXT.
  CE  [tb] DataModuleCreate() and DataModuleDestroy() methods of TdmFormix are
           now called (bug intro. 8.0.14.21).
 ]
v8.0.60.39
 [HSL-HSL
  FIX [tb] Ingredient description on Mix and Ingredient tickets now found /
           printed when the Ingredient Code is less than eight characters
           (bug intro. v8.0.15.1 / 1.059).
 ]
v8.0.60.40
 [HSL-HSL
  FIX [tb] Ingredient code placed in output for ticket *INGREDIENTINFO command
           now space padded to eight chars (bug intro. v8.0.15.1 / 1.059).
 ]
*)

end.
