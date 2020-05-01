USE Insurance
GO

-- Section 5
-- Database
----------------------------------------------------------------
CREATE DATABASE ExampleDB
DROP DATABASE ExampleDB

-- Create table p1
----------------------------------------------------------------
CREATE TABLE Bill (
	BillID int
	, ClaimantID int
	, PatientID int
	, DateReceived datetime
	, DateBilled datetime
	, TotalBilledAmount float
	, ProviderID varchar(8)
	, ProviderName varchar(255)
	, Description varchar(MAX)
)
DROP TABLE Bill
-- Practice
CREATE TABLE PaymentType (
	PaymentTypeID int
	, PaymentTypeDesc varchar(MAX)
	, SettlementFlag bit
)
DROP TABLE PaymentType

-- Create table p2
----------------------------------------------------------------
CREATE TABLE Bill (
	BillID int PRIMARY KEY IDENTITY(1, 1)
	, ClaimantID int FOREIGN KEY REFERENCES Claimant(ClaimantID)
	, PatientID int FOREIGN KEY REFERENCES Patient(PatientID)
	, DateReceived datetime
	, DateBilled datetime
	, TotalBilledAmount float NOT NULL
	, ProviderID varchar(8)
	, ProviderName varchar(255)
	, Description varchar(MAX)
)
-- Practice 
CREATE TABLE Payment (
	PaymentID int PRIMARY KEY IDENTITY(1, 1)
	, ClaimantID int FOREIGN KEY REFERENCES Claimant(ClaimantID)
	, PaidAmount float NOT NULL
	, DatePaid datetime NOT NULL
	, EnteredBy varchar(63)
)
DROP TABLE Payment

-- Alter table
----------------------------------------------------------------
ALTER TABLE Bill
ALTER COLUMN ProviderID varcahr(32)

ALTER TABLE Bill
ADD ExtraBillColumn varchar(MAX)

ALTER TABLE Bill
DROP COLUMN ExtraBillColumn

ALTER TABLE Bill
ALTER COLUMN BillID int NOT NULL

ALTER TABLE Bill
ADD PRIMARY KEY (BillID)

ALTER TABLE Bill
ADD FOREIGN KEY (ClaimantID) REFERENCES CLaimant(ClaimantID)
-- to add identity, use user interface
-- Practice
ALTER TABLE PaymentType
DROP COLUMN SettlementFlag

ALTER TABLE PaymentType
ADD PRIMARY KEY (PaymentTypeID)

ALTER TABLE Payment
ADD Notes varchar(MAX)

ALTER TABLE Payment
ADD PaymentTypeID int

ALTER TABLE Payment
ADD FOREIGN KEY (PaymentTypeID) REFERENCES PaymentType(PaymentTypeID)

-- Variables
----------------------------------------------------------------
DECLARE @InflationRate float
SET @InflationRate = 0.02

SELECT UserName
	, ReserveLimit
	, ReserveLimit * (1 + @InflationRate) AS NextYearReserveLimit
FROM Users

DECLARE @PreviousUser varchar(30)

SELECT TOP 1 @PreviousUser = OldValue
FROM ClaimLog
WHERE PK = 24109
	AND FieldName = 'ExaminerCode'
	AND EntryDate = (
		SELECT MAX(EntryDate) 
		FROM ClaimLog
		WHERE PK = 24109
			AND FieldName = 'ExaminerCode'
	)

SELECT @PreviousUser AS PreviousUser

DECLARE @MedicalReserveTypes_Array TABLE (
	MedicalReserveType varcahr(MAX)
)

DECLARE @Temp_Reserve_Tbl TABLE (
	ClaimNumber varchar(30)
	, TotalReserveAmount float
	, PatientName varchar(63)
)
SELECT * FROM @Temp_Reserve_Tbl
-- Practice
DECLARE @DateAsOf date
SET @DateAsOf = '1/1/2018'

SELECT *
FROM Attachment
WHERE EntryDate < @DateAsOf

-- Exercise
----------------------------------------------------------------
-- ex 1
CREATE TABLE Prices (
	PriceID int PRIMARY KEY IDENTITY(1, 1)
	, ReserveTypeID int FOREIGN KEY REFERENCES ReserveType(ReserveTypeID)
	, ProcedureName varchar(6)
	, ExpectedPrice float
)
SELECT * FROM Prices
DROP TABLE Prices
-- ex 2
CREATE TABLE BillDetail (
	BillDetailID int PRIMARY KEY IDENTITY(1, 1)
	, BillID int FOREIGN KEY REFERENCES Bill(BillID)
	, LineNumber int NOT NULL
	, ProcedureCode varchar(6)
	, Description varchar(MAX)
	, Quantity int
	, PricePerUnit float
	, TotalPrice float NOT NULL
)
SELECT * FROM BillDetail
DROP TABLE BillDetail
-- ex 3
DECLARE @DocumentType varchar(8)
SET @DocumentType = '.pdf'

SELECT @DocumentType
-- ex 4
DECLARE @ReserveSum TABLE (
	ClaimantID int PRIMARY KEY
	, ReserveAmountSum float NOT NULL
)

SELECT * FROM @ReserveSum