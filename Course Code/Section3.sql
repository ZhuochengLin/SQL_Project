USE Insurance
GO

-- Section 3
-- JOINs
---------------------------------------------------------------------
DECLARE @TempTable1 TABLE (ID int)
DECLARE @TempTable2 TABLE (ID int)

INSERT INTO @TempTable1 VALUES (1), (2), (3)
INSERT INTO @TempTable2 VALUES (2), (3), (4), (5)

SELECT T1.ID AS T1, T2.ID AS T2
FROM @TempTable1 T1
INNER JOIN @TempTable2 T2 ON T1.ID = T2.ID

SELECT R.ClaimantID
	, RT.ReserveTypeDesc
	, R.ReserveAmount
FROM Reserve R
INNER JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID

SELECT TOP 100 ClaimNumber, C.ClaimID, CL.*
FROM Claim C
INNER JOIN ClaimLog CL ON C.ClaimID = CL.PK
ORDER BY PK

SELECT C.ClaimNumber, SUM(RT.ExpenseReservingAmount) AS ExpensesSum
FROM Claim C
LEFT JOIN ReservingTool RT ON C.ClaimNumber = RT.ClaimNumber
GROUP BY C.ClaimNumber
ORDER BY SUM(RT.ExpenseReservingAmount)
-- Practice 1
SELECT CS.ClaimStatusDesc, Clmt.ClaimantID, P.MiddleName
FROM Claimant Clmt
INNER JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
INNER JOIN Patient P ON Clmt.PatientID = P.PatientID
WHERE P.MiddleName != ''
-- Practice 2
SELECT C.ClaimNumber, COUNT(CL.PK) AS LockCount
FROM Claim C
LEFT JOIN ClaimLog CL ON CL.PK = C.ClaimID AND FieldName = 'LockedBy'
GROUP BY C.ClaimNumber
ORDER BY LockCount

-- Exercise
---------------------------------------------------------------------
-- ex 1
SELECT C.ClaimNumber, P.FirstName, P.MiddleName, P.LastName
FROM Claim C
INNER JOIN Claimant CL ON C.ClaimID = CL.ClaimID
INNER JOIN Patient P ON CL.PatientID = P.PatientID
WHERE C.ClaimNumber = '752663830-X'
-- ex 2
SELECT O.OfficeDesc AS Office, COUNT(U.UserName) AS UserCount
FROM Office O
LEFT JOIN Users U ON O.OfficeID = U.OfficeID
GROUP BY O.OfficeDesc
ORDER BY COUNT(U.UserName) DESC
-- ex 3
SELECT O.OfficeID, R.*
FROM Reserve R
INNER JOIN Users U ON R.EnteredBy = U.UserName
INNER JOIN Office O ON U.OfficeID = O.OfficeID
WHERE O.OfficeDesc = 'San Francisco'
-- ex 4
SELECT ISNULL(RT2.ReserveTypeDesc, RT1.ReserveTypeDesc) AS ReserveBucket
	, RT2.ReserveTypeDesc AS ReserveParent
	, R.*
FROM Reserve R
INNER JOIN ReserveType RT1 ON R.ReserveTypeID = RT1.reserveTypeID
LEFT JOIN ReserveType RT2 ON RT1.ParentID = RT2.reserveTypeID