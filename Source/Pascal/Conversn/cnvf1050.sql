--this needs to be run WITHOUT FXTRANS.FIL in the FIL folder
SET TRUENULLCREATE=OFF#
DROP TABLE Transactions IN DICTIONARY#
CREATE TABLE Transactions IN DICTIONARY USING 'FXTRANS.FIL'
(
Reserved1        UTINYINT,
Ingredient       CHAR(8),
Order_No         INTEGER,
Reserved2        UTINYINT,
Recipe_No        CHAR(8),
MC_ID            USMALLINT,
Serial_No        INTEGER,
Reserved3        UTINYINT,
Trans_Time       CHAR(5),
Trans_Date       INTEGER,
Order_Line_No    INTEGER,
Reserved4        CHAR(1),
Weight_In_Mix    DOUBLE,
Reserved5        UTINYINT,
Batch_No         CHAR(6),
Reserved6        UTINYINT,
Lot_No           CHAR(8),
Container_No     SMALLINT,
Mix_No           USMALLINT,
Status           USMALLINT,
Order_No_Suffix  UTINYINT,
Reserved7        UTINYINT,
User_ID          CHAR(8),
Calc_Post_Mix_Wt DOUBLE,
Weight_on_Scale  DOUBLE,
Source_code_id   INTEGER,
Reserved         BINARY(8)
)#
CREATE NOT MODIFIABLE INDEX ByDateOrder IN DICTIONARY ON
 Transactions(Trans_Date , Order_No , Order_No_Suffix)#
CREATE UNIQUE NOT MODIFIABLE INDEX ById IN DICTIONARY ON
 Transactions(MC_Id , Serial_No)#
CREATE NOT MODIFIABLE INDEX ByOrderMixLine IN DICTIONARY ON
 Transactions(Order_No , Order_No_Suffix , Mix_No , Order_Line_No)#
SET TRUENULLCREATE=ON#

SET TRUENULLCREATE=OFF#
CREATE TABLE SOURCE_CODES IN DICTIONARY USING 'SRCCODE.FIL' (
ID            IDENTITY,
Code          VARCHAR(60),
Type          CHAR(8),
Reserved      BINARY(20)
)#
CREATE UNIQUE INDEX ByCodeType IN DICTIONARY ON SOURCE_CODES(Code, Type)#
SET TRUENULLCREATE=ON#
