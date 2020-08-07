/*
Microsoft Data Warehouse Toolkit and Kimball Group, (c) 2005, 2006

This script walks you through table partitioning. It's most useful to run a batch at a time, and see
what happens. If you run the whole script at once, you lose the sense of what's going on.

In this very simple example, the first partition holds all data before Jan-2004, the second partition 
holds January data, the third holds February data, and the fourth holds all data for March onwards. 
Note that a partition function automatically creates partitions to hold all possible values. 
Three boundary points, as in the example below, create four partitions. If you’re using surrogate 
date keys, you need to create an integer function that uses the appropriate key ranges. 
You can create complex partition functions, but most people will just create simple functions 
like the one illustrated here. (This is the main reason to use a meaningful surrogate key for Date.)
The next step is to define a partition scheme, which maps each partition in a partition function to 
a specific physical location. A simple example is illustrated here:
*/
-- Create the partition function
CREATE PARTITION FUNCTION PFMonthly (int)
AS RANGE RIGHT 
FOR VALUES (20040101, 20040201, 20040301)
GO

-- Add the partition scheme
CREATE PARTITION SCHEME PSMonthly
AS PARTITION PFMonthly
ALL TO ( [PRIMARY] )
GO

-- Create a simple table
CREATE TABLE PartitionTable (
	DateKey int NOT NULL, 
	CustomerKey int NOT NULL, 
	SalesAmt money,
CONSTRAINT PKPartitionTable PRIMARY KEY NONCLUSTERED
	(DateKey, CustomerKey))
ON PSMonthly(DateKey)		-- This refers to the partition scheme above
GO

-- Add some rows
INSERT INTO PartitionTable (DateKey, CustomerKey, SalesAmt)
VALUES (20031201, 1, 5000)
INSERT INTO PartitionTable (DateKey, CustomerKey, SalesAmt)
VALUES (20040101, 2, 3000)
INSERT INTO PartitionTable (DateKey, CustomerKey, SalesAmt)
VALUES (20040215, 55, 6000)
INSERT INTO PartitionTable (DateKey, CustomerKey, SalesAmt)
VALUES (20040331, 5, 3000)
INSERT INTO PartitionTable (DateKey, CustomerKey, SalesAmt)
VALUES (20040415, 57, 6000)
GO


-- A query accesses the entire table, exactly as you'd expect.
SELECT * FROM PartitionTable
Go

--Query partition contents
SELECT 
	$partition.PFMonthly(DateKey) AS [Partition#],
	COUNT(*) AS RowCnt, 
	Min(DateKey) AS MinDate, 
	Max(DateKey) AS MaxDate
FROM PartitionTable 
GROUP BY $partition.PFMonthly(DateKey)
ORDER BY [Partition#]
GO

-- Split the range, to add a new partition for April
ALTER PARTITION FUNCTION PFMonthly ()
SPLIT RANGE (20040401)
GO

-- Query partition contents. Note the last partition (which used to have 2 rows)
-- has automatically divided.
SELECT 
	$partition.PFMonthly(DateKey) AS [Partition#],
	COUNT(*) AS RowCnt, 
	Min(DateKey) AS MinDate, 
	Max(DateKey) AS MaxDate
FROM PartitionTable 
GROUP BY $partition.PFMonthly(DateKey)
ORDER BY [Partition#]
GO



/*
The Big Swap

The split that we just described is very handy, but with large data volumes, it'll take FOREVER.
You don't want to manage partitioning by splitting a partition that has data in it. Always
split empty partitions. Use the "big swap" to switch populated partitions into an existing
partitioned table. See below.
*/
-- Create empty partitions for May and June
ALTER PARTITION SCHEME PSMonthly
NEXT USED [PRIMARY]
GO
ALTER PARTITION FUNCTION PFMonthly ()
SPLIT RANGE (20040501)
GO
ALTER PARTITION SCHEME PSMonthly
NEXT USED [PRIMARY]
GO
ALTER PARTITION FUNCTION PFMonthly ()
SPLIT RANGE (20040601)
GO

-- Create an empty table nearly identical to the partitioned table
CREATE TABLE PseudoPartition_200405 (
	DateKey int NOT NULL,
	CustomerKey int NOT NULL,
	SalesAmt money,
CONSTRAINT PKPseudoPartition_200405 PRIMARY KEY NONCLUSTERED
	(DateKey, CustomerKey),
CONSTRAINT CKPseudoPartition_200405 CHECK
	(DateKey >= 20040501 and DateKey <= 20040531)	-- This constraint is vital
)
-- We don’t want the ON <PartitionScheme> clause
GO


-- Insert a few rows by hand. In the real world use a bulk loading technique.
INSERT INTO PseudoPartition_200405 (DateKey, CustomerKey, SalesAmt)
	VALUES (20040505, 33, 5500)
INSERT INTO PseudoPartition_200405 (DateKey, CustomerKey, SalesAmt)
	VALUES (20040515, 27, 6000)
GO


-- The magic switch – very fast even with large data volumes
ALTER TABLE PseudoPartition_200405 SWITCH TO PartitionTable PARTITION 6
GO

SELECT 
	$partition.PFMonthly(DateKey) AS [Partition#],
	COUNT(*) AS RowCnt, 
	Min(DateKey) AS MinDate, 
	Max(DateKey) AS MaxDate
FROM PartitionTable 
GROUP BY $partition.PFMonthly(DateKey)
ORDER BY [Partition#]
GO

/* 
-- Clean-up
DROP Table PartitionTable
DROP Table PseudoPartition_200405
DROP Partition Scheme PSMonthly
DROP Partition Function PFMonthly
*/
