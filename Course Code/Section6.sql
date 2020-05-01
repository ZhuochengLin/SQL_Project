USE Insurance
GO

-- Section 6
-- INSERT INTO
--------------------------------------------------------------
SELECT TOP 0 *
INTO Office2
FROM Office1

INSERT INTO Office2 (
	OfficeCode
	, OfficeDesc
	, City
	, State
)
VALUES (
	'ATL'
	, 'Atlana'
	, ''
	, 'GA'
)
SELECT * FROM Office2

DECLARE @Temp_Reserves_Tbl TABLE (
	ClaimNumber varchar(30)
	, TotalReserveAmount float
	, PatientName varchar(63)
)
INSERT INTO @Temp_Reserves_Tbl (
	ClaimNumber
	, TotalReserveAmount
	, PatientName
)
VALUES ('12345ABC', 100, 'Rob the Builder')
SELECT * FROM @Temp_Reserves_Tbl
-- Practice
INSERT INTO Users (
	UserName
	, FirstName
	, LastName
	, MiddleName
)
VALUES (
	'zclin'
	, 'Zhuocheng'
	, 'Lin'
	, ''
)

-- UPDATE, DELETE
--------------------------------------------------------------
UPDATE Office1
SET City = OfficeDesc
	, OfficeDesc = ''

SELECT * FROM Office1
UPDATE Office1
SET State = 'IL'
WHERE State IS NULL

DELETE FROM Office1
WHERE OfficeID > 4
-- Practice
UPDATE Users
SET Title = 'Senior'
	, ReserveLimit = 2 * ReserveLimit
WHERE UserName = 'zclin'

-- INSERT INTO from a table
--------------------------------------------------------------
DECLARE @Temp_Reserves_Tbl TABLE (
	ClaimNumber varchar(30)
	, TotalReserveAmount float
	, PatientName varchar(63)
)

INSERT INTO @Temp_Reserves_Tbl
SELECT C.ClaimNumber
	, SUM(R.ReserveAmount) AS ReserveSum
	, TRIM(P.LastName + ' ' + P.FirstName + P.MiddleName) AS PatientName
FROM Claim C
INNER JOIN Claimant Cl ON Cl.ClaimID = C.ClaimID
INNER JOIN Reserve R ON R.ClaimantID = Cl.ClaimantID
INNER JOIN Patient P ON P.PatientID = Cl.PatientID
GROUP BY C.ClaimNumber, TRIM(P.LastName + ' ' + P.FirstName + P.MiddleName)

SELECT * FROM @Temp_Reserves_Tbl
-- Practice
CREATE TABLE MedicalReserveCases (
	 ReservingToolID int FOREIGN KEY REFERENCES ReservingTool(ReservingToolID)
	 , ClaimNumber varchar(30)
	 , WorstCaseMedicalReserves float
)
INSERT INTO MedicalReserveCases
SELECT ReservingToolID
	, ClaimNumber
	, MedicalReservingAmount * 2 
FROM ReservingTool

SELECT * FROM MedicalReserveCases

-- UPDATE from a table
--------------------------------------------------------------
UPDATE MedicalReserveCases
SET ClaimNumber = C.NewClaimNumber
FROM MedicalReserveCases M
INNER JOIN ClaimNumberFixes  C ON M.ClaimNumber = C.OldClaimNumber

SELECT * FROM MedicalReserveCases
-- Practice
ALTER TABLE MedicalReserveCases
ADD BestCaseMedicalReserves float

UPDATE MedicalReserveCases
SET BestCaseMedicalReserves = RT.MedicalReservingAmount * 0.5
FROM MedicalReserveCases M
INNER JOIN ReservingTool RT ON RT.ReservingToolID = M.ReservingToolID

SELECT * FROM MedicalReserveCases

-- #Temporary tables
--------------------------------------------------------------
SELECT NewValue AS StartingUser
INTO #Temp
FROM ClaimLog
WHERE FieldName = 'ExaminerCode'
	AND OldValue = 'unassigned'

SELECT * FROM #Temp
DROP TABLE #Temp

CREATE TABLE #Temp (
	ClaimID int
	, CurrentExaminer varchar(50)
	, PreviousExaminer varchar(50)
	, AssignedDate datetime
	, Level int
)

INSERT INTO #Temp
SELECT CL.PK AS ClaimID
	, CL.NewValue AS CurrentExaminer
	, NULL AS PreviousExaminer
	, x.LatestAssignedDate AS AssignedDate
	, 0 AS Level
FROM (
	SELECT PK, MAX(EntryDate) AS LatestAssignedDate
	FROM ClaimLog
	WHERE FieldName = 'ExaminerCode'
	GROUP BY PK	
) x
INNER JOIN ClaimLog CL ON CL.PK = x.PK 
	AND CL.FieldName = 'ExaminerCode'
	AND CL.EntryDate = x.LatestAssignedDate
ORDER BY CL.PK

SELECT * FROM #Temp

INSERT INTO #Temp
SELECT T2.ClaimID
	, T2.CurrentExaminer
	, CL2.NewValue AS PreviousExaminer
	, x.LatestAssignedDate AS AssignedDate
	, 1 AS Level
FROM (
	SELECT CL.PK, MAX(EntryDate) AS LatestAssignedDate
	FROM ClaimLog CL
	INNER JOIN #Temp T ON T.ClaimID = CL.PK
	WHERE CL.FieldName = 'ExaminerCode' AND CL.EntryDate < T.AssignedDate
	GROUP BY PK	
) x
INNER JOIN ClaimLog CL2 ON CL2.PK = x.PK 
	AND CL2.FieldName = 'ExaminerCode'
	AND CL2.EntryDate = x.LatestAssignedDate
INNER JOIN #Temp T2 ON CL2.PK = T2.ClaimID 
ORDER BY CL2.PK

SELECT * FROM #Temp
ORDER BY ClaimID, Level

-- Exercise
--------------------------------------------------------------
-- ex 1
USE [UPDATE]
GO

UPDATE [G&T Results 2017-18_Temp]
SET [Entering Grade Level] = 1
WHERE [Entering Grade Level] IS NULL
-- ex 2
-- step 1
UPDATE [G&T Results 2017-18_Temp]
SET [School Preferences] = REPLACE([School Preferences], '/', ',')
-- step 2
SELECT [School Preferences]
	, CHARINDEX(',', [School Preferences], 1) AS CommaIndex
	, CASE WHEN CHARINDEX(',', [School Preferences], 1) = 0 THEN [School Preferences]
		ELSE LEFT([School Preferences], CHARINDEX(',', [School Preferences], 1) - 1) 
		END AS PreferredSchool
FROM [G&T Results 2017-18_Temp]
-- step 3
UPDATE [G&T Results 2017-18_Temp]
SET [School Assigned] = 
	CASE WHEN CHARINDEX(',', [School Preferences], 1) = 0 THEN [School Preferences]
		ELSE LEFT([School Preferences], CHARINDEX(',', [School Preferences], 1) - 1) 
		END

WHERE [Overall Score] = 99 
	AND ([School Assigned] IS NULL OR TRIM([School Assigned]) = 'NONE')

SELECT * FROM [G&T Results 2017-18_Temp]
-- ex 3
SELECT * 
INTO [G&T Results 2018-19_Temp]
FROM [G&T Results 2018-19]

SELECT * FROM [G&T Results 2018-19_Temp]

DELETE FROM [G&T Results 2018-19_Temp]
WHERE [Timestamp] IS NULL
-- ex 4
USE Insurance
GO

SELECT * FROM ReservingTool

INSERT INTO ReserveType 
VALUES (1, '', 'Fatality Misc', 10)
-- ex 5
DECLARE @LargestClaimsInReservingTool TABLE (
	ReservingToolID int
	, ClaimNumber varchar(30)
	, PublishedDate datetime
	, TotalReservingAmount float
)

INSERT INTO @LargestClaimsInReservingTool
SELECT TOP 5
	ReservingToolID
	, ClaimNumber
	, EnteredOn AS PublishedDate
	, MedicalReservingAmount + TDReservingAmount + PDReservingAmount + ExpenseReservingAmount AS TotalReservingAmount
FROM ReservingTool
WHERE IsPublished = 1
ORDER BY MedicalReservingAmount + TDReservingAmount + PDReservingAmount + ExpenseReservingAmount

SELECT * FROM @LargestClaimsInReservingTool
-- ex 6
CREATE TABLE #TotalIncurredTable (
	ClaimantID int PRIMARY KEY
	, ClaimNumber varchar(30)
	, TotalIncurredAmount float
)

INSERT INTO #TotalIncurredTable
SELECT Clmt.ClaimantID
	, C.ClaimNumber
	, SUM(ReserveAmount)
FROM Reserve R
INNER JOIN Claimant Clmt ON Clmt.ClaimantID = R.ClaimantID
INNER JOIN Claim C ON C.ClaimID = Clmt.ClaimID
GROUP BY Clmt.ClaimantID, C.ClaimNumber
ORDER BY SUM(ReserveAmount)

SELECT * FROM #TotalIncurredTable
DROP TABLE #TotalIncurredTable
