* Encoding: UTF-8.


**Part 1: Update missing DateProviChange by using DateProgmChange** 

**Part 2: Identify Duplicate Cases, find missing CSI#, and filter out duplicates**

SORT CASES BY CSINumber(A) DateProviChange(A) ProviderSiteID(A).
MATCH FILES
  /FILE=*
  /BY CSINumber DateProviChange ProviderSiteID
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
MATCH FILES
  /FILE=*
  /DROP=PrimaryLast InDupGrp MatchSequence.
VARIABLE LABELS  PrimaryFirst 'Indicator of each first matching case as Primary'.
VALUE LABELS  PrimaryFirst 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryFirst (ORDINAL).
FREQUENCIES VARIABLES=PrimaryFirst.
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (PrimaryFirst = 1).
EXECUTE.

**Part 3 ***

SORT CASES BY CSINumber(A) DateProviChange(A).
MATCH FILES
  /FILE=*
  /BY CSINumber DateProviChange
 /DROP = PrimaryFirst  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
MATCH FILES
  /FILE=*
  /DROP=PrimaryLast InDupGrp MatchSequence.
VARIABLE LABELS  PrimaryFirst 'Indicator of each first matching case as Primary'.
VALUE LABELS  PrimaryFirst 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryFirst (ORDINAL).
FREQUENCIES VARIABLES=PrimaryFirst.
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (PrimaryFirst = 1).
EXECUTE.


**Part 4: move youth with multiple transfers so transfer records are on same row. Repeat shift values for maximum number of records***

SORT CASES BY CSINumber(A).
MATCH FILES
  /FILE=*
  /BY CSINumber
 /DROP = PrimaryFirst  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
MATCH FILES
  /FILE=*
  /DROP=PrimaryLast InDupGrp.
VARIABLE LABELS  PrimaryFirst 'Indicator of each first matching case as Primary' MatchSequence 
    'Sequential count of matching cases'.
VALUE LABELS  PrimaryFirst 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryFirst (ORDINAL) /MatchSequence (SCALE).
FREQUENCIES VARIABLES=PrimaryFirst MatchSequence.
EXECUTE.

SHIFT VALUES VARIABLE=DateProviChange RESULT=DateProvichange2 LEAD=1
  /VARIABLE=ProviderSiteID RESULT=TransferSiteID2 LEAD=1.

SHIFT VALUES VARIABLE=DateProvichange2 RESULT=DateProvichange3 LEAD=1
  /VARIABLE=TransferSiteID2 RESULT=TransferSiteID3 LEAD=1.

SHIFT VALUES VARIABLE=DateProvichange3 RESULT=DateProvichange4 LEAD=1
  /VARIABLE=TransferSiteID3 RESULT=TransferSiteID4 LEAD=1.

SORT CASES BY CSINumber.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /PRESORTED
  /BREAK=CSINumber
  /MatchSequence_max=MAX(MatchSequence).

DO IF (MatchSequence = 0).
RECODE DateProvichange2 DateProvichange3 DateProvichange4 (ELSE=SYSMIS).
END IF.
EXECUTE.

DO IF (MatchSequence_max = 2).
RECODE DateProvichange3 DateProvichange4 (ELSE=SYSMIS).
END IF.
EXECUTE.

DO IF (MatchSequence_max = 3).
RECODE DateProvichange4 (ELSE=SYSMIS).
END IF.
EXECUTE.

*Note: if the transfer date is missing- delete the transferprogramID*

**Part 5: Delete duplicate cases**

FILTER OFF.
USE ALL.
SELECT IF (MatchSequence = 0 | MatchSequence = 1).
EXECUTE.


**Part 6: merge the current file into "all clientsinfo_clean" . Rename providersiteID to transfersiteID

**Part 7**

COMPUTE reopentransfer=0.
* transferred.
IF (DateProviChange > AssessmentDate) reopentransfer = 1.
Execute.
* reopened.
IF (ProviderSiteID = TransferSiteID AND DateProviChange > AssessmentDate) reopentransfer=2 .
VALUE LABELS reopentransfer  0 'No' 1 'Transfered' 2 'Reopened'.
Execute.

COMPUTE reopentransfer2=0.
* transferred.
IF (DateProviChange2 > DateProviChange) reopentransfer2 = 1.
Execute.
* reopened.
IF (TransferSiteID = TransferSiteID2 AND DateProviChange2 > DateProviChange) reopentransfer2=2 .
VALUE LABELS reopentransfer2  0 'No' 1 'Transfered' 2 'Reopened'.
Execute.

COMPUTE reopentransfer3=0.
* transferred.
IF (DateProviChange3 > DateProviChange2) reopentransfer3 = 1.
Execute.
* reopened.
IF (TransferSiteID2 = TransferSiteID3 AND DateProviChange3 > DateProviChange2) reopentransfer3=2 .
VALUE LABELS reopentransfer3  0 'No' 1 'Transfered' 2 'Reopened'.
Execute.

COMPUTE reopentransfer4=0.
* transferred.
IF (DateProviChange4 > DateProviChange3) reopentransfer4 = 1.
Execute.
* reopened.
IF (TransferSiteID3 = TransferSiteID4 AND DateProviChange4 > DateProviChange3) reopentransfer3=2 .
VALUE LABELS reopentransfer4  0 'No' 1 'Transfered' 2 'Reopened'.
Execute.

