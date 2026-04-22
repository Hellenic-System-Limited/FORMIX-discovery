
SET TRUENULLCREATE=OFF#
CREATE TABLE REJECT_REASONS using 'REJREASN.FIL'(
Reason_no    INTEGER,
Description  CHAR(50)
)#
CREATE UNIQUE INDEX "ByReason" ON REJECT_REASONS (Reason_no)#
SET TRUENULLCREATE=ON#

INSERT INTO REJECT_REASONS (Reason_no,Description) VALUES (1,'Wrong source product for ingredient')#
INSERT INTO REJECT_REASONS (Reason_no,Description) VALUES (2,'Source has gone past its life date')#
INSERT INTO REJECT_REASONS (Reason_no,Description) VALUES (3,'Source is empty')#


SET TRUENULLCREATE=OFF#
CREATE TABLE RO_REJECTED_OFFERING using 'REJOFFER.FIL'(
Offer_id               IDENTITY,
Order_no               INTEGER,
Ingredient             CHAR(8),
Barcode                VARCHAR(60),
Reason_no              INTEGER,
Label_barcode          VARCHAR(60),
Current_override_id    INTEGER,
)#
CREATE UNIQUE NOT MODIFIABLE INDEX "ByOrdIngBarRej" ON RO_REJECTED_OFFERING (
  Order_no, Ingredient, Barcode, Reason_no)#
CREATE INDEX "ByReason" ON RO_REJECTED_OFFERING (Reason_no)#
CREATE INDEX "ByBarcode" ON RO_REJECTED_OFFERING (Barcode)#
SET TRUENULLCREATE=ON#


SET TRUENULLCREATE=OFF#
CREATE TABLE RO_OVERRIDES using 'ROVERIDE.FIL'(
Override_id          IDENTITY,
Offer_id             INTEGER,
Denied               BIT,
Reason               VARCHAR(100),
Valid_from_date      DATE,
Valid_from_time      TIME,
Valid_to_date        DATE,
Valid_to_time        TIME,
Authorized_by        VARCHAR(30),
Authorization_date   DATE,
Authorization_time   TIME
)#
CREATE INDEX "ByOffer" ON RO_OVERRIDES(Offer_id)#
CREATE INDEX "ByAuthorizedate" ON RO_OVERRIDES(Authorization_date)#
CREATE INDEX "ByTodate" ON RO_OVERRIDES(Valid_to_date)#
SET TRUENULLCREATE=ON#

SET TRUENULLCREATE=OFF#
CREATE TABLE REJECTIONS using 'REJECTS.FIL'(
Offer_id          INTEGER,
User_code         CHAR(8),
Rejection_Date    DATE,
Rejection_Time    TIME,
Override_requested BIT
)#
CREATE INDEX "ByOffer" ON REJECTIONS(Offer_id)#
CREATE INDEX "ByDateTime" ON REJECTIONS(Rejection_date, Rejection_time)#
CREATE INDEX "ByUser" ON REJECTIONS(User_code)#
SET TRUENULLCREATE=ON#

