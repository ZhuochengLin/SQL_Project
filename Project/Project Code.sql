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

-- Step 2
SELECT 
	c.ClaimNumber
	, R.ReserveAmount
	, O.OfficeDesc
	, U.UserName AS ExaminerCode
	, Users2.UserName AS SupervisorCode
	, Users3.UserName AS ManagerCode
	, U.Title AS ExaminerTitle
	, Users2.Title AS SupervisorTitle
	, Users3.Title AS ManagerTitle
	, U.LastFirstName AS ExaminerName
	, Users2.LastFirstName AS SupervisorName
	, Users3.LastFirstName AS ManagerName
	, CS.ClaimStatusDesc 
	, P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName 
	, CL.ReopenedDate
	, CT.ClaimantTypeDesc
	, O.State
	, U.ReserveLimit
	, (CASE WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
		ELSE RT.reserveTypeID END) AS ReserveCostID
FROM Claimant CL
INNER JOIN CLaim C ON C.ClaimID = CL.ClaimID
INNER JOIN Users U ON U.UserName = C.ExaminerCode
INNER JOIN Users Users2 ON U.Supervisor = Users2.UserName
INNER JOIN Users Users3 ON Users2.Supervisor = Users3.UserName
INNER JOIN Office1 O ON O.OfficeID = U.OfficeID
INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = CL.ClaimantTypeID
INNER JOIN Reserve R ON R.ClaimantID = CL.ClaimantID
LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = CL.claimStatusID
LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
LEFT JOIN Patient P ON P.PatientID = CL.PatientID
WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') 
	AND	(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) 
	AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID != 3)) 

-- Step 3
SELECT PivotTable.*
FROM (	
	SELECT 
		c.ClaimNumber
		, R.ReserveAmount
		, (CASE WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID END) AS ReserveTypeBucketID
		, O.OfficeDesc AS Office
		, U.UserName AS ExaminerCode
		, Users2.UserName AS SupervisorCode
		, Users3.UserName AS ManagerCode
		, U.Title AS ExaminerTitle
		, Users2.Title AS SupervisorTitle
		, Users3.Title AS ManagerTitle
		, U.LastFirstName AS ExaminerName
		, Users2.LastFirstName AS SupervisorName
		, Users3.LastFirstName AS ManagerName
		, CS.ClaimStatusDesc 
		, P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName 
		, CL.ReopenedDate
		, CT.ClaimantTypeDesc
		, O.State
		, U.ReserveLimit
	FROM Claimant CL
	INNER JOIN CLaim C ON C.ClaimID = CL.ClaimID
	INNER JOIN Users U ON U.UserName = C.ExaminerCode
	INNER JOIN Users Users2 ON U.Supervisor = Users2.UserName
	INNER JOIN Users Users3 ON Users2.Supervisor = Users3.UserName
	INNER JOIN Office1 O ON O.OfficeID = U.OfficeID
	INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = CL.ClaimantTypeID
	INNER JOIN Reserve R ON R.ClaimantID = CL.ClaimantID
	LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = CL.claimStatusID
	LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
	LEFT JOIN Patient P ON P.PatientID = CL.PatientID
	WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') 
		AND	(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) 
		AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID != 3)) 
) BaseData
PIVOT (
SUM(ReserveAmount)
	FOR ReserveTypeBucketID IN ([1], [2], [3], [4], [5])
) PivotTable
WHERE (PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) 
	-- be careful about the NULL values!
	OR (PivotTable.Office = 'San Diego' 
		AND (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) 
	OR (PivotTable.Office IN ('Sacramento', 'San Francisco') 
		AND (ISNULL([1], 0) > 800 
			OR ISNULL([5], 0) > 100 
			OR (ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))

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
		-- choose the one with more days left, that it the number of days to complete
		WHEN 91 - DaySinceLastPublishedDate >= 15 - DaySinceAdjustedAssignedDate AND DaySinceLastPublishedDate IS NOT NULL THEN 91 - DaySinceLastPublishedDate
		ELSE 15 - DaySinceAdjustedAssignedDate
		END AS DaysToComplete
	, CASE WHEN DaySinceAdjustedAssignedDate <= 14 OR (DaySinceLastPublishedDate <= 90 AND DaySinceLastPublishedDate IS NOT NULL) THEN 0
		-- choose the one with less days left, similar to the previous one
		WHEN DaySinceLastPublishedDate - 90 <= DaySinceAdjustedAssignedDate - 14 AND DaySinceLastPublishedDate IS NOT NULL THEN DaySinceLastPublishedDate - 90
		ELSE DaySinceAdjustedAssignedDate - 14
		END AS DaysOverdue
FROM (	
	SELECT 
		c.ClaimNumber
		, R.ReserveAmount
		, (CASE WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID END) AS ReserveTypeBucketID
		, O.OfficeDesc AS Office
		, U.UserName AS ExaminerCode
		, Users2.UserName AS SupervisorCode
		, Users3.UserName AS ManagerCode
		, U.Title AS ExaminerTitle
		, Users2.Title AS SupervisorTitle
		, Users3.Title AS ManagerTitle
		, U.LastFirstName AS ExaminerName
		, Users2.LastFirstName AS SupervisorName
		, Users3.LastFirstName AS ManagerName
		, CS.ClaimStatusDesc AS ClaimStatus
		, P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName 
		, CL.ReopenedDate
		, CT.ClaimantTypeDesc
		, O.State
		, U.ReserveLimit
		, ADL.ExaminerAssignedDate
		, CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN CL.ReopenedDate
			ELSE ADL.ExaminerAssignedDate
			END AS AdjustedAssignedDate
		, RTP.LastPublishedDate
		-- DATEDIFF is used to find the date difference
		, CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN DATEDIFF(DAY, CL.ReopenedDate, @DateAsOf)
			ELSE DATEDIFF(DAY, ADL.ExaminerAssignedDate, @DateAsOf)
			END AS DaySinceAdjustedAssignedDate
		, DATEDIFF(DAY, LastPublishedDate, @DateAsOf) AS DaySinceLastPublishedDate
	FROM Claimant CL
	INNER JOIN CLaim C ON C.ClaimID = CL.ClaimID
	INNER JOIN Users U ON U.UserName = C.ExaminerCode
	INNER JOIN Users Users2 ON U.Supervisor = Users2.UserName
	INNER JOIN Users Users3 ON Users2.Supervisor = Users3.UserName
	INNER JOIN Office1 O ON O.OfficeID = U.OfficeID
	INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = CL.ClaimantTypeID
	INNER JOIN Reserve R ON R.ClaimantID = CL.ClaimantID
	LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = CL.claimStatusID
	LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
	LEFT JOIN Patient P ON P.PatientID = CL.PatientID
	INNER JOIN @AssignedDateLog ADL ON ADL.PK = C.ClaimID
	LEFT JOIN @ReservingToolPbl RTP ON C.ClaimNumber = RTP.ClaimNumber
	WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') 
		AND	(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) 
		AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID != 3)) 
) BaseData
PIVOT (
SUM(ReserveAmount)
	FOR ReserveTypeBucketID IN ([1], [2], [3], [4], [5])
) PivotTable
WHERE (PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) 
	-- be careful about the NULL values!
	OR (PivotTable.Office = 'San Diego' 
		AND (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) 
	OR (PivotTable.Office IN ('Sacramento', 'San Francisco') 
		AND (ISNULL([1], 0) > 800 
			OR ISNULL([5], 0) > 100 
			OR (ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))

-- Step 6
DROP PROCEDURE SPGetOutstandingRTPublish
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
				-- choose the one with more days left, that it the number of days to complete
				WHEN 91 - DaySinceLastPublishedDate >= 15 - DaySinceAdjustedAssignedDate AND DaySinceLastPublishedDate IS NOT NULL THEN 91 - DaySinceLastPublishedDate
				ELSE 15 - DaySinceAdjustedAssignedDate
				END AS DaysToComplete
			, CASE WHEN DaySinceAdjustedAssignedDate <= 14 OR (DaySinceLastPublishedDate <= 90 AND DaySinceLastPublishedDate IS NOT NULL) THEN 0
				-- choose the one with less days left, similar to the previous one
				WHEN DaySinceLastPublishedDate - 90 <= DaySinceAdjustedAssignedDate - 14 AND DaySinceLastPublishedDate IS NOT NULL THEN DaySinceLastPublishedDate - 90
				ELSE DaySinceAdjustedAssignedDate - 14
				END AS DaysOverdue
		FROM (	
			SELECT 
				c.ClaimNumber
				, R.ReserveAmount
				, (CASE WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
					ELSE RT.reserveTypeID END) AS ReserveTypeBucketID
				, O.OfficeDesc AS Office
				, U.UserName AS ExaminerCode
				, Users2.UserName AS SupervisorCode
				, Users3.UserName AS ManagerCode
				, U.Title AS ExaminerTitle
				, Users2.Title AS SupervisorTitle
				, Users3.Title AS ManagerTitle
				, U.LastFirstName AS ExaminerName
				, Users2.LastFirstName AS SupervisorName
				, Users3.LastFirstName AS ManagerName
				, CS.ClaimStatusDesc AS ClaimStatus
				, P.LastName + ',' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName 
				, CL.ReopenedDate
				, CT.ClaimantTypeDesc
				, O.State
				, U.ReserveLimit
				, ADL.ExaminerAssignedDate
				, CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN CL.ReopenedDate
					ELSE ADL.ExaminerAssignedDate
					END AS AdjustedAssignedDate
				, RTP.LastPublishedDate
				-- DATEDIFF is used to find the date difference
				, CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN DATEDIFF(DAY, CL.ReopenedDate, @DateAsOf)
					ELSE DATEDIFF(DAY, ADL.ExaminerAssignedDate, @DateAsOf)
					END AS DaySinceAdjustedAssignedDate
				, DATEDIFF(DAY, LastPublishedDate, @DateAsOf) AS DaySinceLastPublishedDate
			FROM Claimant CL
			INNER JOIN CLaim C ON C.ClaimID = CL.ClaimID
			INNER JOIN Users U ON U.UserName = C.ExaminerCode
			INNER JOIN Users Users2 ON U.Supervisor = Users2.UserName
			INNER JOIN Users Users3 ON Users2.Supervisor = Users3.UserName
			INNER JOIN Office1 O ON O.OfficeID = U.OfficeID
			INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = CL.ClaimantTypeID
			INNER JOIN Reserve R ON R.ClaimantID = CL.ClaimantID
			LEFT JOIN ClaimStatus CS ON CS.ClaimStatusID = CL.claimStatusID
			LEFT JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
			LEFT JOIN Patient P ON P.PatientID = CL.PatientID
			INNER JOIN @AssignedDateLog ADL ON ADL.PK = C.ClaimID
			LEFT JOIN @ReservingToolPbl RTP ON C.ClaimNumber = RTP.ClaimNumber
			WHERE O.OfficeDesc IN ('Sacramento', 'San Diego', 'San Francisco') 
				AND	(RT.ParentID IN (1, 2, 3, 4, 5) OR RT.reserveTypeID IN (1, 2, 3, 4, 5)) 
				AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID != 3)) 
		) BaseData
		PIVOT (
		SUM(ReserveAmount)
			FOR ReserveTypeBucketID IN ([1], [2], [3], [4], [5])
		) PivotTable
		WHERE (PivotTable.ClaimantTypeDesc IN ('Medical Only', 'First Aid')) 
			-- be careful about the NULL values!
			OR (PivotTable.Office = 'San Diego' 
				AND (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([5], 0) >= PivotTable.ReserveLimit)) 
			OR (PivotTable.Office IN ('Sacramento', 'San Francisco') 
				AND (ISNULL([1], 0) > 800 
					OR ISNULL([5], 0) > 100 
					OR (ISNULL([2], 0) > 0 OR ISNULL([3], 0) > 0 OR iSNULL([4], 0) > 0)))
	) MainQuery
	WHERE (DaysToComplete <= @DaysToComplete OR @DaysToComplete IS NULL)
		AND (DaysOverdue <= @DaysOverdue OR @DaysOverdue IS NULL) 
		AND (Office = @Office OR @Office IS NULL)
		AND (ManagerCode = @ManagerCode OR @ManagerCode IS NULL)
		AND (SupervisorCode = @SupervisorCode OR @SupervisorCode IS NULL)
		AND (ExaminerCode = @ExaminerCode OR @ExaminerCode IS NULL)
		AND (ExaminerTitle LIKE '%' + @Team + '%' OR SupervisorTitle LIKE '%' + @Team + '%' OR ManagerTitle LIKE '%' + @Team + '%' OR @Team IS NULL)
		AND (@ClaimsWithoutRTPublish = 0 OR LastPublishedDate IS NULL)
END

EXEC SPGetOutstandingRTPublish
EXEC SPGetOutstandingRTPublish @ClaimsWithoutRTPublish = 1
EXEC SPGetOutstandingRTPublish NULL, NULL, NULL, NULL, 'qkemp', NULL, NULL, 0