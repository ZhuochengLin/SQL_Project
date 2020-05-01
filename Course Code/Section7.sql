USE Insurance
GO

-- Section 7 
-- Stored prcedure
----------------------------------------------------------
CREATE PROCEDURE SPGetReserve
AS
BEGIN
	SELECT ReserveID, ClaimantID, ReserveAmount
	FROM Reserve
END

SPGetReserve
EXEC SPGetReserve
EXECUTE SPGetReserve

DROP PROCEDURE SPGetReserve

ALTER PROCEDURE SPGetReserve
	@ReserveType varchar(30)
	, @ReserveAmountMin float
AS
BEGIN
	SELECT ReserveID, ClaimantID, ReserveAmount, RT.reserveTypeID, RT.ReserveTypeDesc
	FROM Reserve R
	INNER JOIN ReserveType RT ON R.ReserveTypeID = RT.reserveTypeID
	WHERE RT.ReserveTypeDesc = @ReserveType
		AND R.ReserveAmount > @ReserveAmountMin
END

SPGetReserve 'Medical', 500
SPGetReserve @ReserveType = 'Medical', @ReserveAmountMin = 500

CREATE TABLE #Temp1 (
	ReserveID int PRIMARY KEY
	, ClaimantID int
	, ReserveAmount float
	, ReserveTypeID int
	, ReserveTypeDesc varchar(30)
)

INSERT INTO #Temp1
EXEC SPGetReserve 'Medical', 500

SELECT * FROM #Temp1

DROP TABLE #Temp1

-- Exercise
----------------------------------------------------------
-- ex 1
CREATE PROCEDURE SPGetNegativeReserveType
AS
BEGIN
	SELECT x.ReserveTypeID
		, CASE WHEN RT.ParentID = 0 THEN RT.ReserveTypeCode ELSE RT2.ReserveTypeCode END AS ReserveBucket
		, x.NegativeCount
		, x.AvgNegativeAmount
	FROM (
		SELECT ReserveTypeID
			, SUM(CASE WHEN ReserveAmount < 0 THEN 1 ELSE 0 END) AS NegativeCount
			, AVG(CASE WHEN ReserveAmount < 0 THEN ReserveAmount ELSE NULL END) AS AvgNegativeAmount
		FROM Reserve
		GROUP BY ReserveTypeID 
		) x
	INNER JOIN ReserveType RT ON RT.reserveTypeID = x.ReserveTypeID
	LEFT JOIN ReserveType RT2 ON RT2.reserveTypeID = RT.ParentID
	ORDER BY x.ReserveTypeID
END
-- ex 2
ALTER PROCEDURE SPGetNegativeReserveType
	@NegativeCount int
	, @ReserveBucket varchar(15) = NULL
	, @MaxAvgNegativeAmount float = NULL
AS
BEGIN
	SELECT ReserveTypeID, ReserveBucket, NegativeCount, AvgNegativeAmount
	FROM (
		SELECT x.ReserveTypeID
			, CASE WHEN RT.ParentID = 0 THEN RT.ReserveTypeCode ELSE RT2.ReserveTypeCode END AS ReserveBucket
			, x.NegativeCount
			, x.AvgNegativeAmount
		FROM (
			SELECT ReserveTypeID
				, SUM(CASE WHEN ReserveAmount < 0 THEN 1 ELSE 0 END) AS NegativeCount
				, AVG(CASE WHEN ReserveAmount < 0 THEN ReserveAmount ELSE NULL END) AS AvgNegativeAmount
			FROM Reserve
			GROUP BY ReserveTypeID 
			) x
		INNER JOIN ReserveType RT ON RT.reserveTypeID = x.ReserveTypeID
		LEFT JOIN ReserveType RT2 ON RT2.reserveTypeID = RT.ParentID
		) sub
		WHERE NegativeCount <= @NegativeCount 
			AND (ReserveBucket = @ReserveBucket OR @ReserveBucket IS NULL)
			AND (@MaxAvgNegativeAmount <= AvgNegativeAmount OR @MaxAvgNegativeAmount IS NULL)
	ORDER BY ReserveTypeID
END

EXEC SPGetNegativeReserveType 1
-- ex 3
CREATE TABLE #Temp1 (
	ReserveTypeID int PRIMARY KEY
	, ReserveBucket varchar(15)
	, NegativeCount float
	, AvgNegativeAmount float
)

INSERT INTO #Temp1
EXEC SPGetNegativeReserveType 1

SELECT * FROM #Temp1

SELECT 
	C.ExaminerCode
	, C.ClaimNumber
	, SUM(R.ReserveAmount) AS ReserveSum
FROM Claim C
INNER JOIN Users U ON C.ExaminerCode = U.UserName
INNER JOIN Claimant Cl ON C.ClaimID = Cl.ClaimID
INNER JOIN Reserve R ON R.ClaimantID = Cl.ClaimantID
INNER JOIN #Temp1 t ON t.ReserveTypeID = r.ReserveTypeID
WHERE U.FirstName = 'Riley' AND U.LastName = 'Kailyn'
GROUP BY C.ExaminerCode, C.ClaimNumber

DROP TABLE #Temp1
-- ex 4
DROP PROCEDURE SPGetNegativeReserveType