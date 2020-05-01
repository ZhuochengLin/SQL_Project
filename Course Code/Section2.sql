USE Insurance
GO
-- Section 2
-- SELECT, ORDER BY, WHERE
---------------------------------------------------------------------------
SELECT *
FROM Users

SELECT *
FROM ClaimLog
ORDER BY PK

SELECT TOP 4 UserName, LastFirstName, Title, PaymentLimit
FROM Users
ORDER BY PaymentLimit DESC

SELECT ClaimNumber, InjuryState, ExaminerCode 
FROM Claim
WHERE ExaminerCode = 'lnikki'

SELECT UserName, Title, ReserveLimit 
FROM Users
WHERE Title LIKE '%specialist%'
-- Practice 
SELECT *
FROM Claimant
WHERE YEAR(ClosedDate) = 2018

-- AND, OR, NULL
---------------------------------------------------------------------------
SELECT *
FROM ClaimLog
WHERE FieldName = 'ExaminerCode' AND OldValue = 'Unassigned'

SELECT *
FROM Users
WHERE UserName = 'dclara' OR Supervisor = 'dclara'

SELECT ClaimantID
	, ClosedDate
	, ReopenedDate
	, TRY_CONVERT(int, ClosedDate - ReopenedDate) AS DateDifference
FROM Claimant
WHERE ClosedDate IS NOT NULL
-- Practice
SELECT *
FROM Claimant
WHERE YEAR(ClosedDate) = 2018
	AND ReopenedDate IS NULL

-- Aggregate Functions
---------------------------------------------------------------------------
SELECT MAX(PaymentLimit) AS MaximumPaymentLimit 
	, MIN(PaymentLimit) AS MinimumPaymentLimit
	, AVG(PaymentLimit) AS AvgPaymentLimit
FROM Users

SELECT COUNT(ReopenedDate) AS ReopenedCount
FROM Claimant
--Practice
SELECT AVG(ReserveAmount) AS AverageReserveAmount
FROM Reserve

-- DISTINCT vs GROUP BY
SELECT DISTINCT ExaminerCode
FROM Claim

SELECT DISTINCT ExaminerCode
	, InjuryState
	, JurisdictionID
	, YEAR(EntryDate) AS EntryYear
FROM Claim

SELECT ExaminerCode
	, COUNT(*) AS NumberOfClaimsHandled
FROM Claim
GROUP BY ExaminerCode
-- Practice
SELECT EnteredBy
	, COUNT(*) AS NumberOfPublishes
FROM ReservingTool
WHERE IsPublished = 1
GROUP BY EnteredBy

-- Other statements
---------------------------------------------------------------------------
-- INTO, make new table
SELECT *
INTO Office1
FROM Office

SELECT TOP 10 BusinessName, COUNT(BusinessName) AS Employees
INTO Top10Inc
FROM Patient
WHERE BusinessName LIKE '%inc%'
GROUP BY BusinessName
ORDER BY COUNT(BusinessName)
-- WHERE ... IN ...
SELECT *
FROM Attachment
WHERE EnteredBy IN ('qkemp', 'kgus', 'unassigned')
-- HAVING, filtering after group by
SELECT EnteredBy
	, COUNT(*) AS NumberOfPublishes
FROM ReservingTool
WHERE IsPublished = 1
GROUP BY EnteredBy
HAVING COUNT(*) > 50


-- Exercise
---------------------------------------------------------------------------
-- ex1
SELECT *
FROM Attachment
WHERE EnteredBy = 'lnikki'
	AND FileName LIKE '%.pdf'
-- ex2
SELECT *
FROM ReserveType
WHERE reserveTypeID = 1 OR ParentID = 1
-- ex3
SELECT ClaimantID, COUNT(*) AS ReserveChangeCount
FROM Reserve
GROUP BY ClaimantID
HAVING COUNT(*) >= 15
-- ex4
-- copy the format of a table to a new table, without any data 
SELECT TOP 0 *
INTO Claim2
FROM Claim
-- ex 5
SELECT RIGHT(FileName, 4) AS AttachmentType
	, COUNT(*) AS Counts
FROM Attachment
GROUP BY RIGHT(FileName, 4)
ORDER BY COUNT(*) DESC