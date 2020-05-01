USE Insurance
GO

-- Step 1
-- Query 1: the last date a claimant re-opened claim
SELECT ClaimantID, ReopenedDate
FROM Claimant

-- Quary 2: the date an examiner was assigned a claim
SELECT PK, MAX(EntryDate) AS ExaminerAssignedDate
FROM ClaimLog
WHERE FieldName = 'ExaminerCode'
GROUP BY PK

-- Quary 3: the last date an examiner published on the Reserving Tool for each claim
SELECT ClaimNumber, MAX(EnteredOn) AS LastDate
FROM ReservingTool
WHERE IsPublished = 1
GROUP BY ClaimNumber

-- Step 4
DECLARE @DateAsOf date
SET @DateAsOf = '1/1/2019'

DECLARE @ReservingToolPbl TABLE (
	ClaimNumber varchar(30),
	LastPublishedDate datetime
)

DECLARE @AssignedDateLog TABLE (
	PK int,
	ExaminerAssignedDate datetime
)

-- Step 5
INSERT INTO @ReservingToolPbl
SELECT ClaimNumber, MAX(EnteredOn) AS LastPublished
FROM ReservingTool
WHERE IsPublished = 1
GROUP BY ClaimNumber

INSERT INTO @AssignedDateLog
SELECT PK, MAX(EntryDate) AS ExaminerAssignedDate
FROM ClaimLog
WHERE FieldName = 'ExaminerCode'
GROUP BY PK

--SELECT * FROM @ReservingToolPbl
--SELECT * FROM @AssignedDateLog

-- Step 3
-- Quary 4: select required fields
SELECT 
		C.ClaimNumber, 
		O.OfficeDesc, 
		U.UserName AS ExaminerCode, 
		U2.UserName AS SupervisorCode, 
		U3.UserName AS ManagerCode,
		U.Title AS ExaminerTitle, 
		U2.Title AS SupervisorTitle, 
		U3.Title AS ManagerTitle,
		U.LastFirstName AS ExaminerName, 
		U2.LastFirstName AS SupervisorName, 
		U3.LastFirstName AS ManagerName,
		CS.ClaimStatusDesc, 
		P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName, 
		Clmt.ReopenedDate, Clmt.ReopenedReasonID, 
		CT.ClaimantTypeDesc, 
		O.State,
		U.ReserveLimit, 
		(CASE
			WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID
			END) AS ReserveCostID
FROM Claim C
LEFT JOIN Users U ON U.UserName = C.ExaminerCode
LEFT JOIN Users U2 ON U.Supervisor = U2.UserName
LEFT JOIN Users U3 On U2.Supervisor = U3.UserName
LEFT JOIN Office O ON U.OfficeID = O.OfficeID
LEFT JOIN Claimant Clmt ON C.ClaimID = Clmt.ClaimID
LEFT JOIN Patient P ON P.PatientID = Clmt.PatientID
LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
LEFT JOIN ClaimantType CT ON CT.ClaimantTypeID = Clmt.ClaimantTypeID
LEFT JOIN Reserve R ON R.ClaimantID = Clmt.ClaimantID
LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') AND
		(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) AND
		CS.ClaimStatusDesc != 'Closed' AND
		Clmt.ReopenedReasonID != 3

-- Quary 4, Use PIVOT, to get the total amount for each Reserve Type
SELECT PivotTable.*
FROM (
	SELECT 
		C.ClaimNumber,
		(CASE
			WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID
		END) AS ReserveTypeID,
		R.ReserveAmount,
		O.OfficeDesc, 
		U.UserName AS ExaminerCode, 
		U2.UserName AS SupervisorCode, 
		U3.UserName AS ManagerCode,
		U.Title AS ExaminerTitle, 
		U2.Title AS SupervisorTitle, 
		U3.Title AS ManagerTitle,
		U.LastFirstName AS ExaminerName, 
		U2.LastFirstName AS SupervisorName, 
		U3.LastFirstName AS ManagerName,
		CS.ClaimStatusDesc, 
		P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName, 
		Clmt.ReopenedDate, Clmt.ReopenedReasonID, 
		CT.ClaimantTypeDesc, 
		O.State,
		U.ReserveLimit
	FROM Claim C
	LEFT JOIN Users U ON U.UserName = C.ExaminerCode
	LEFT JOIN Users U2 ON U.Supervisor = U2.UserName
	LEFT JOIN Users U3 On U2.Supervisor = U3.UserName
	LEFT JOIN Office O ON U.OfficeID = O.OfficeID
	LEFT JOIN Claimant Clmt ON C.ClaimID = Clmt.ClaimID
	LEFT JOIN Patient P ON P.PatientID = Clmt.PatientID
	LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
	LEFT JOIN ClaimantType CT ON CT.ClaimantTypeID = Clmt.ClaimantTypeID
	LEFT JOIN Reserve R ON R.ClaimantID = Clmt.ClaimantID
	LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
	WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') AND
		(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) AND
		CS.ClaimStatusDesc != 'Closed' AND
		Clmt.ReopenedReasonID != 3
) BaseData
PIVOT (
	SUM(ReserveAmount)
	FOR ReserveTypeID IN ([1], [2], [3], [4], [5])
) PivotTable
WHERE 
	(PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) OR
	-- careful about the NULL value!
	(PivotTable.OfficeDesc = 'San Diego' AND 
		(ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) OR
	(PivotTable.OfficeDesc IN ('Sacramento', 'San Francisco') AND 
		(ISNULL([1], 0) > 800 OR ISNULL([5], 0) > 100 OR 
			(ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))



------------------------------------------------------
-- Project Step 5/6
DECLARE @DateAsOf date
SET @DateAsOf = '1/1/2019'

DECLARE @ReservingToolPbl TABLE (
	ClaimNumber varchar(30),
	LastPublishedDate datetime
)

DECLARE @AssignedDateLog TABLE (
	PK int,
	ExaminerAssignedDate datetime
)

INSERT INTO @ReservingToolPbl
SELECT ClaimNumber, MAX(EnteredOn) AS LastPublished
FROM ReservingTool
WHERE IsPublished = 1
GROUP BY ClaimNumber

INSERT INTO @AssignedDateLog
SELECT PK, MAX(EntryDate) AS ExaminerAssignedDate
FROM ClaimLog
WHERE FieldName = 'ExaminerCode'
GROUP BY PK

SELECT ClaimNumber
	, ManagerCode
	, ManagerTitle
	, ManagerName
	, SupervisorCode
	, SupervisorTitle
	, SupervisorName
	, ExaminerCode
	, ExaminerTitle
	, ExaminerName
	, Office
	, ClaimStatus
	, ClaimantName
	, ClaimantTypeDesc
	, ExaminerAssignedDate
	, ReopenedDate
	, AdjustedAssignedDate
	, LastPublishedDate
	, DaySinceAdjustedAssignedDate
	, DaySinceLastPublishedDate
	, CASE WHEN DaySinceAdjustedAssignedDate > 14 AND (DaySinceLastPublishedDate > 90 OR DaySinceLastPublishedDate IS NULL) THEN 0
		WHEN 91 - DaySinceLastPublishedDate >= 15 - DaySinceAdjustedAssignedDate AND DaySinceLastPublishedDate IS NOT NULL THEN 91 - DaySinceLastPublishedDate
		ELSE 15 - DaySinceAdjustedAssignedDate
		END AS DaysToComplete
	, CASE WHEN DaySinceAdjustedAssignedDate <= 14 OR (DaySinceLastPublishedDate <= 90 AND DaySinceLastPublishedDate IS NOT NULL) THEN 0
		WHEN DaySinceLastPublishedDate - 90 <= DaySinceAdjustedAssignedDate - 14 AND DaySinceLastPublishedDate IS NOT NULL THEN DaySinceLastPublishedDate - 90
		ELSE DaySinceAdjustedAssignedDate - 14
		END AS DaysOverdue
FROM (
	SELECT 
		C.ClaimNumber,
		(CASE
			WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID
		END) AS ReserveTypeID,
		R.ReserveAmount,
		O.OfficeDesc AS Office, 
		U.UserName AS ExaminerCode, 
		U2.UserName AS SupervisorCode, 
		U3.UserName AS ManagerCode,
		U.Title AS ExaminerTitle, 
		U2.Title AS SupervisorTitle, 
		U3.Title AS ManagerTitle,
		U.LastFirstName AS ExaminerName, 
		U2.LastFirstName AS SupervisorName, 
		U3.LastFirstName AS ManagerName,
		CS.ClaimStatusDesc AS ClaimStatus, 
		P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName, 
		Clmt.ReopenedDate, Clmt.ReopenedReasonID, 
		CT.ClaimantTypeDesc, 
		O.State,
		U.ReserveLimit,
		ADL.ExaminerAssignedDate,
		CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND Clmt.ReopenedDate > ADL.ExaminerAssignedDate 
			THEN Clmt.ReopenedDate
			ELSE ADL.ExaminerAssignedDate
			END AS AdjustedAssignedDate,
		RTP.LastPublishedDate,
		CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND Clmt.ReopenedDate > ADL.ExaminerAssignedDate 
			THEN DATEDIFF(DAY, Clmt.ReopenedDate, @DateAsOf)
			ELSE DATEDIFF(DAY, ADL.ExaminerAssignedDate, @DateAsOf)
			END AS DaySinceAdjustedAssignedDate,
		DATEDIFF(DAY, LastPublishedDate, @DateAsOf) AS DaySinceLastPublishedDate
	FROM Claim C
	LEFT JOIN Users U ON U.UserName = C.ExaminerCode
	LEFT JOIN Users U2 ON U.Supervisor = U2.UserName
	LEFT JOIN Users U3 On U2.Supervisor = U3.UserName
	LEFT JOIN Office O ON U.OfficeID = O.OfficeID
	LEFT JOIN Claimant Clmt ON C.ClaimID = Clmt.ClaimID
	LEFT JOIN Patient P ON P.PatientID = Clmt.PatientID
	LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
	LEFT JOIN ClaimantType CT ON CT.ClaimantTypeID = Clmt.ClaimantTypeID
	LEFT JOIN Reserve R ON R.ClaimantID = Clmt.ClaimantID
	LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
	INNER JOIN @AssignedDateLog ADL ON ADL.PK = C.ClaimID
	LEFT JOIN @ReservingToolPbl RTP ON RTP.ClaimNumber = C.ClaimNumber
	WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') AND
		(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) AND
		CS.ClaimStatusDesc != 'Closed' AND
		Clmt.ReopenedReasonID != 3
) BaseData
PIVOT (
	SUM(ReserveAmount)
	FOR ReserveTypeID IN ([1], [2], [3], [4], [5])
) PivotTable
WHERE 
	(PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) OR
	-- careful about the NULL value!
	(PivotTable.Office = 'San Diego' AND 
		(ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) OR
	(PivotTable.Office IN ('Sacramento', 'San Francisco') AND 
		(ISNULL([1], 0) > 800 OR ISNULL([5], 0) > 100 OR 
			(ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))

-- Project Step 6/6
CREATE PROCEDURE SPGetOutstandingRTPublish (
	@DaysToComplete int = NULL
	, @DaysOverdue int = NULL
	, @Office varchar(31) = NULL
	, @ManagerCode varchar(31) = NULL
	, @SupervisorCode varchar(31) = NULL
	, @ExaminerCode varchar(31) = NULL
	, @Team varchar(250) = NULL
	, @ClaimsWithoutRTPublish bit = 0 
)
AS
BEGIN
	DECLARE @DateAsOf date
	SET @DateAsOf = '1/1/2019'

	DECLARE @ReservingToolPbl TABLE (
		ClaimNumber varchar(30),
		LastPublishedDate datetime
	)

	DECLARE @AssignedDateLog TABLE (
		PK int,
		ExaminerAssignedDate datetime
	)

	INSERT INTO @ReservingToolPbl
	SELECT ClaimNumber, MAX(EnteredOn) AS LastPublished
	FROM ReservingTool
	WHERE IsPublished = 1
	GROUP BY ClaimNumber

	INSERT INTO @AssignedDateLog
	SELECT PK, MAX(EntryDate) AS ExaminerAssignedDate
	FROM ClaimLog
	WHERE FieldName = 'ExaminerCode'
	GROUP BY PK
	SELECT *
	FROM (
		SELECT ClaimNumber
			, ManagerCode
			, ManagerTitle
			, ManagerName
			, SupervisorCode
			, SupervisorTitle
			, SupervisorName
			, ExaminerCode
			, ExaminerTitle
			, ExaminerName
			, Office
			, ClaimStatus
			, ClaimantName
			, ClaimantTypeDesc
			, ExaminerAssignedDate
			, ReopenedDate
			, AdjustedAssignedDate
			, LastPublishedDate
			, DaySinceAdjustedAssignedDate
			, DaySinceLastPublishedDate
			, CASE WHEN DaySinceAdjustedAssignedDate > 14 AND (DaySinceLastPublishedDate > 90 OR DaySinceLastPublishedDate IS NULL) THEN 0
				WHEN 91 - DaySinceLastPublishedDate >= 15 - DaySinceAdjustedAssignedDate AND DaySinceLastPublishedDate IS NOT NULL THEN 91 - DaySinceLastPublishedDate
				ELSE 15 - DaySinceAdjustedAssignedDate
				END AS DaysToComplete
			, CASE WHEN DaySinceAdjustedAssignedDate <= 14 OR (DaySinceLastPublishedDate <= 90 AND DaySinceLastPublishedDate IS NOT NULL) THEN 0
				WHEN DaySinceLastPublishedDate - 90 <= DaySinceAdjustedAssignedDate - 14 AND DaySinceLastPublishedDate IS NOT NULL THEN DaySinceLastPublishedDate - 90
				ELSE DaySinceAdjustedAssignedDate - 14
				END AS DaysOverdue
		FROM (
			SELECT 
				C.ClaimNumber,
				(CASE
					WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
					ELSE RT.reserveTypeID
				END) AS ReserveTypeID,
				R.ReserveAmount,
				O.OfficeDesc AS Office, 
				U.UserName AS ExaminerCode, 
				U2.UserName AS SupervisorCode, 
				U3.UserName AS ManagerCode,
				U.Title AS ExaminerTitle, 
				U2.Title AS SupervisorTitle, 
				U3.Title AS ManagerTitle,
				U.LastFirstName AS ExaminerName, 
				U2.LastFirstName AS SupervisorName, 
				U3.LastFirstName AS ManagerName,
				CS.ClaimStatusDesc AS ClaimStatus, 
				P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName, 
				Clmt.ReopenedDate, Clmt.ReopenedReasonID, 
				CT.ClaimantTypeDesc, 
				O.State,
				U.ReserveLimit,
				ADL.ExaminerAssignedDate,
				CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND Clmt.ReopenedDate > ADL.ExaminerAssignedDate 
					THEN Clmt.ReopenedDate
					ELSE ADL.ExaminerAssignedDate
					END AS AdjustedAssignedDate,
				RTP.LastPublishedDate,
				CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND Clmt.ReopenedDate > ADL.ExaminerAssignedDate 
					THEN DATEDIFF(DAY, Clmt.ReopenedDate, @DateAsOf)
					ELSE DATEDIFF(DAY, ADL.ExaminerAssignedDate, @DateAsOf)
					END AS DaySinceAdjustedAssignedDate,
				DATEDIFF(DAY, LastPublishedDate, @DateAsOf) AS DaySinceLastPublishedDate
			FROM Claim C
			LEFT JOIN Users U ON U.UserName = C.ExaminerCode
			LEFT JOIN Users U2 ON U.Supervisor = U2.UserName
			LEFT JOIN Users U3 On U2.Supervisor = U3.UserName
			LEFT JOIN Office O ON U.OfficeID = O.OfficeID
			LEFT JOIN Claimant Clmt ON C.ClaimID = Clmt.ClaimID
			LEFT JOIN Patient P ON P.PatientID = Clmt.PatientID
			LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
			LEFT JOIN ClaimantType CT ON CT.ClaimantTypeID = Clmt.ClaimantTypeID
			LEFT JOIN Reserve R ON R.ClaimantID = Clmt.ClaimantID
			LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
			INNER JOIN @AssignedDateLog ADL ON ADL.PK = C.ClaimID
			LEFT JOIN @ReservingToolPbl RTP ON RTP.ClaimNumber = C.ClaimNumber
			WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') AND
				(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) AND
				CS.ClaimStatusDesc != 'Closed' AND
				Clmt.ReopenedReasonID != 3
		) BaseData
		PIVOT (
			SUM(ReserveAmount)
			FOR ReserveTypeID IN ([1], [2], [3], [4], [5])
		) PivotTable
		WHERE 
			(PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) OR
			-- careful about the NULL value!
			(PivotTable.Office = 'San Diego' AND 
				(ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) OR
			(PivotTable.Office IN ('Sacramento', 'San Francisco') AND 
				(ISNULL([1], 0) > 800 OR ISNULL([5], 0) > 100 OR 
					(ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))
		) MainQuary
		WHERE (DaysToComplete <= @DaysToComplete OR @DaysToComplete IS NULL)
			AND (DaysOverdue <= @DaysOverdue OR @DaysOverdue IS NULL) 
			AND (Office = @Office OR @Office IS NULL)
			AND (ManagerCode = @ManagerCode OR @ManagerCode IS NULL)
			AND (SupervisorCode = @SupervisorCode OR @SupervisorCode IS NULL)
			AND (ExaminerCode = @ExaminerCode OR @ExaminerCode IS NULL)
			AND (ExaminerTitle LIKE '%' + @Team + '%' OR SupervisorTitle LIKE '%' + @Team + '%' OR ManagerTitle LIKE '%' + @Team + '%' OR @Team IS NULL)
			AND (@ClaimsWithoutRTPublish = 0 OR LastPublishedDate IS NULL)
END

SPGetOutstandingRTPublish

EXEC SPGetOutstandingRTPublish @SupervisorCode = 'qkemp'

-- Assignment 1

SELECT * 
FROM Claimant Clmt
INNER JOIN ClaimStatus CS ON CS.ClaimStatusID = Clmt.claimStatusID
INNER JOIN Users U ON U.UserName = Clmt.EnteredBy
INNER JOIN Office1 O ON O.OfficeID = U.OfficeID
INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = Clmt.ClaimantTypeID
INNER JOIN Claim C ON C.ClaimID = Clmt.ClaimID
INNER JOIN Reserve R ON R.ClaimantID = Clmt.ClaimantID
INNER JOIN ReservingTool RT ON RT.re
WHERE (CS.ClaimStatusDesc = 'Open' OR (CS.ClaimStatusDesc = 'Re-open' AND Clmt.ReopenedReasonID != 3))
	AND O.City IN ('Sacramento', 'San Francisco', 'San Diego')
	AND ((CT.ClaimantTypeDesc IN ('First Aid', 'Medical Only') OR 
		(O.City = 'San Diego' AND U.Title LIKE '%analyst%' AND ))

SELECT * FROM ReservingTool