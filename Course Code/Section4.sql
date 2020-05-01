USE Insurance
GO

-- Section 4
-- Subquary
---------------------------------------------------------------------
SELECT C.ClaimNumber
FROM (
	SELECT TOP 10 *
	FROM Claim
) C

-- Subquary(WHERE)
---------------------------------------------------------------------
SELECT Supervisor, UserName
FROM Users
WHERE UserName IN (
	SELECT DISTINCT EnteredBy
	FROM ReservingTool
)
-- Practice
SELECT MedicalReservingAmount, EnteredOn, IsPublished
FROM ReservingTool
WHERE EnteredOn = (
	SELECT MAX(EnteredOn)
	FROM ReservingTool
	WHERE IsPublished = 1
) AND IsPublished = 1

-- Subquary(FROM)
---------------------------------------------------------------------
SELECT C.ClaimID, R.ReserveAmount, ReserveSum.TotalReserveAmount
	, ReserveAmount / TotalReserveAmount AS ReserveProportion
FROM (
	SELECT Cl2.ClaimantID, SUM(R2.ReserveAmount) AS TotalReserveAmount
	FROM Reserve R2
	INNER JOIN Claimant Cl2 ON Cl2.ClaimantID = R2.ClaimantID
	INNER JOIN Claim C2 ON Cl2.ClaimID = C2.ClaimID
	WHERE C2.ClaimNumber = '500008648-1'
	GROUP BY Cl2.ClaimantID
) ReserveSum
INNER JOIN Reserve R ON ReserveSum.ClaimantID = R.ClaimantID
INNER JOIN Claimant Cl ON Cl.ClaimantID = R.ClaimantID
INNER JOIN Claim C ON Cl.ClaimID = C.ClaimID
WHERE C.ClaimNumber = '500008648-1'

SELECT C.ClaimNumber
	, R.ReserveAmount
	, SUM(ReserveAmount) OVER (PARTITION BY C.ClaimNumber) AS TotalReserveSum
FROM Reserve R
INNER JOIN Claimant Cl ON Cl.ClaimantID = R.ClaimantID
INNER JOIN Claim C ON Cl.ClaimID = C.ClaimID
WHERE C.ClaimNumber = '500008648-1'
-- Practice
SELECT CL.PK AS ClaimID, CL.NewValue AS CurrentExaminer, x.LatestAssignedDate AS AssignedDate
FROM (
	SELECT PK, MAX(EntryDate) AS LatestAssignedDate
	FROM ClaimLog
	WHERE FieldName = 'ExaminerCode'
	GROUP BY PK
) x
INNER JOIN ClaimLog CL ON x.PK = CL.PK AND x.LatestAssignedDate = CL.EntryDate AND CL.FieldName = 'ExaminerCode'
ORDER BY Cl.PK

-- Exercise
---------------------------------------------------------------------
-- ex 1
SELECT *
FROM Reserve
WHERE ReserveAmount > (
	SELECT ReserveAmount
	FROM Reserve
	WHERE ReserveID = 588785
)
-- ex 2
SELECT *
FROM Reserve
WHERE ReserveAmount > (
	SELECT AVG(ReserveAmount)
	FROM Reserve
)
-- ex 3
SELECT ReserveID, ReserveAmount
FROM Reserve
WHERE ReserveAmount = (
	SELECT MIN(ReserveAmount)
	FROM ( 
		SELECT TOP 2 ReserveAmount
		FROM Reserve
		ORDER BY ReserveAmount DESC
	) x
)
-- ex 4
SELECT sub.*, RT1.MedicalReservingAmount AS FirstMedicalAmount, RT2.MedicalReservingAmount AS LastMedicalAmount
FROM (
	SELECT RT_First.ClaimNumber, FirstPublishedDate, LastPublishedDate
	FROM (
		SELECT ClaimNumber, MIN(EnteredOn) AS FirstPublishedDate
		FROM ReservingTool
		WHERE IsPublished = 1
		GROUP BY ClaimNumber
	) RT_First
	INNER JOIN (
		SELECT ClaimNumber, MAX(EnteredOn) AS LastPublishedDate
		FROM ReservingTool
		WHERE IsPublished = 1
		GROUP BY ClaimNumber
	) RT_Last ON RT_Last.ClaimNumber = RT_First.ClaimNumber
) sub
LEFT JOIN ReservingTool RT1 ON RT1.ClaimNumber = sub.ClaimNumber AND RT1.EnteredOn = sub.FirstPublishedDate AND RT1.IsPublished = 1
LEFT JOIN ReservingTool RT2 ON RT2.ClaimNumber = sub.ClaimNumber AND RT2.EnteredOn = sub.LastPublishedDate AND RT2.IsPublished = 1

SELECT sub.*, RT1.MedicalReservingAmount AS FirstMedicalAmount, RT2.MedicalReservingAmount AS LastMedicalAmount
FROM (
	SELECT DISTINCT ClaimNumber
		, MIN(EnteredOn) OVER (PARTITION BY ClaimNumber) AS FirstPublishedDate
		, MAX(EnteredOn) OVER (PARTITIOn BY ClaimNumber) AS LastPublishedDate
	FROM ReservingTool
	WHERE IsPublished = 1
) sub
LEFT JOIN ReservingTool RT1 ON RT1.ClaimNumber = sub.ClaimNumber AND RT1.EnteredOn = sub.FirstPublishedDate AND RT1.IsPublished = 1
LEFT JOIN ReservingTool RT2 ON RT2.ClaimNumber = sub.ClaimNumber AND RT2.EnteredOn = sub.LastPublishedDate AND RT2.IsPublished = 1
