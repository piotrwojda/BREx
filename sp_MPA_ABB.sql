USE [Reports]
GO

/****** Object:  StoredProcedure [dbo].[SP_MPA_ABB]    Script Date: 2016-05-21 21:58:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO




CREATE                PROCEDURE [dbo].[SP_MPA_ABB](@periodNo int) AS

BEGIN

SET NOCOUNT ON

DECLARE @TableName VARCHAR(100), @SQL VARCHAR(8000), @Quarter VARCHAR(2), @Year VARCHAR(4)

SELECT @TableName = 'RawData_' + CONVERT(VARCHAR(4),DATEPART(YYYY, Period_Start)) + '.DBO.SalesTransaction_' + CONVERT(VARCHAR(1),DATEPART(QUARTER, Period_Start)) + 'Q' + CONVERT(VARCHAR(4),DATEPART(YYYY, Period_Start)) 
		,@Quarter = '0' + CONVERT(VARCHAR(1),DATEPART(QUARTER, Period_Start))
		,@Year = DATEPART(YYYY, Period_Start)
FROM IDSMetaData.DBO.IDCPeriods WHERE PeriodID = @PeriodNo

SET @SQL = "
		INSERT INTO 
			Reports..MPA_SALES
				(DDMCODE
				,STATECODE
				,CLASS
				,ITEMCODE
				,ITEMDESCRIPTION
				,QUANTITY
				,BONUS
				,TOTALQTY
				,SALESVALUE
				,PFC
				,YR
				,MTH
				,BATCH)
		SELECT 
				DDMCODE
				,STATECODE
				,CLASS
				,ITEMCODE
				,ITEMDESCRIPTION
				,SUM(ISNULL(QUANTITY,0)*N.QtyFct)
				,SUM(ISNULL(BONUS,0)*N.QtyFct)
				,SUM((ISNULL(S.Quantity,0)+ISNULL(S.Bonus,0))*N.QtyFct)
				,SUM(ISNULL(SALESVALUE,0)*N.ValFct)
				,N.PFC
				,'" + @Year + "'
				,'" + @Quarter + "'
				,s.batch
			FROM " + @TableName + " S
		INNER JOIN 
			NORMALIZEDDATA.DBO.NORMALIZEDPRODUCTS N 
				on (N.ProdCode=S.ITEMCODE) 
				and (N.dscode=S.ddmcode)
		where 
			S.DDMCODE='ABB'
		GROUP BY 
			DDMCODE
			,STATECODE
			,CLASS
			,ITEMCODE
			,ITEMDESCRIPTION
			,N.PFC
			,s.batch"
EXEC (@SQL)
		
DELETE FROM Reports.DBO.MPA_SALES WHERE SALESVALUE < 0  and ddmcode='ABB';

--UPDATE LABCODE
UPDATE Reports.DBO.MPA_SALES 
    SET LABCODE = (replicate('0',4-len(ltrim(rtrim(N.LABCODE))))+(ltrim(rtrim(N.LABCODE))))
    FROM Reports.DBO.MPA_SALES S, NDF..SRCHMAST N
    WHERE N.PFC=S.PFC  AND S.DDMCODE='ABB';


DELETE FROM Reports.DBO.MPA_SALES WHERE (PFC='0000000' OR LABCODE=' ')

--DOC W
UPDATE Reports.DBO.MPA_SALES
    SET REGION ='01'
where (class ='1'  or class like 'DR%') and ddmcode='ABB';

--PHA W
UPDATE Reports.DBO.MPA_SALES
    SET REGION ='09'
where (class ='3' or class like 'RXP%') and ddmcode='ABB';

--HOS W
UPDATE Reports.DBO.MPA_SALES
    SET REGION ='10'
where (class ='4' or class = 'HP-') and ddmcode='ABB';


----update invalid class to valid as per advise by LO
UPDATE Reports.DBO.MPA_SALES
    SET REGION ='01'
where (class like 'HPM%') and ddmcode='ABB';

UPDATE Reports.DBO.MPA_SALES
    SET REGION ='01'
where (class like 'NHD%') and ddmcode='ABB';

UPDATE Reports.DBO.MPA_SALES
    SET REGION ='01'
where (class like 'OTH%') and ddmcode='ABB';

UPDATE Reports.DBO.MPA_SALES
    SET REGION ='09'
where (class like 'DSD%') and ddmcode='ABB';


DELETE FROM Reports.DBO.MPA_SALES WHERE ISNULL(REGION,' ')=' ' and ddmcode='ABB';

----- to delete pfc with delflag "S" --- daric jan 22,2013
delete n 
from Reports.DBO.MPA_SALES n
inner join ndf..srchmast x on n.pfc=x.pfc
where x.delflag='S' and ddmcode='ABB'

-- UPDATED BY MARK MENDOZA
-- JULY 31, 2015
-- BONUS ---------------------------------------------------------------------		
	INSERT INTO Reports.DBO.MPA_SALES_Bonus 
		SELECT	 
			[DDMCode]
		  ,[StateCode]
		  ,[Class]
		  ,[ItemCode]
		  ,[ItemDescription]
		  ,[Quantity]
		  ,[Bonus]
		  ,[TotalQty]
		  ,[SalesValue] = 1
		  ,[PFC]
		  ,[LABCODE]
		  ,[YR]
		  ,[MTH]
		  ,[region]
		  ,[Class2]
		  ,[Batch]
		  ,[State]
		  ,[Class3]
		  ,[Class4]
		FROM Reports.DBO.MPA_SALES 
		WHERE 
			(Quantity > 0 OR TOTALQTY > 0) AND 
			SALESVALUE = 0 AND 
			PFC <> 0 AND 
			DDMCODE='ABB'
			
	--UPDATE Reports.DBO.MPA_SALES SET SALESVALUE = 1 
	--	WHERE (Quantity > 0 OR TOTALQTY) AND SALESVALUE = 0 AND PFC <> 0 AND DDMCODE='ABB'
------------------------------------------------------------------------------

INSERT INTO Reports.DBO.MPA_T109
SELECT S.PFC, S.TOTALQTY,CAST((S.salesvalue*100) AS BIGINT),SUBSTRING(P.ATCCODE,1,5),S.LABCODE,S.YR,S.MTH,S.REGION
FROM Reports.DBO.MPA_SALES S
inner join NDF..PACK P on (P.PFC=S.PFC)
WHERE P.DELFLAG NOT IN ('C','Z') AND S.TOTALQTY>0 and s.ddmcode='ABB'

END













GO

