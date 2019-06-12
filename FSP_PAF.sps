


**Open the PAFAssessmentQ file**

** Part 1: Identify Duplicate Cases by checking CSI# using the below syntax. **

SORT CASES BY CSINumber(A).
MATCH FILES
  /FILE=*
  /BY CSINumber
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

** Part 2: Double check each duplicate's value. For the ones with different values (e.g. providersiteID, partnershipstatus, date of birth, etc.), change their PrimaryFirst to '1'. Note: when checking the duplicates, mark the ones 
with more information as '1' and the ones with less information as '0' in the PrimaryFirst***

FILTER OFF.
USE ALL.
SELECT IF (PrimaryFirst = 1).
EXECUTE.

**Part 3**

RECODE ReferredBy EmotionalDisturbance AttendanceCurr GradesCurr ProbationStatus WICodeStatus 
    PhysicianCurr ActiveProblem AbuseServices ResidentialCode (SYSMIS=99).

RECODE ReferredBy  (3=18).


Value Labels ReferredBy 1 "self" 2 "family" 3 "significant other" 4 "friend" 5 "school" 6 "primary care" 7 "emergency room" 8 "mental health facility" 
   9 "social services agency" 10 "substance abuse facility" 11 "faithbased organization" 12 "other county"
   13 "homeless shelter" 14 "street outreach" 15 "juvenile hall"  16 "jail or prison" 17 "acute psychiatric" 18 "other" 99 "missing".


Value Labels AttendanceCurr 1 "always" 2 "most" 3 "sometimes" 4 "infrequently" 5 "never" 99 "missing". 


Value Labels GradesCurr 1 "very good" 2 "good" 3 "average" 4 "below average" 5 "poor" 99 "missing". 


RECODE ResidentialCode (1=1) (2=2) (3=3) (4=4) (5=4) (6=6) (7=7) (8=8) (9=8) (10=8) (11=11) (12=11) (13=13) (14=14) (15=15) (16=15) (17=17) (18=18) (20=17) (22=17) (21=14) (27=15) (99=99) INTO rescode2. 
VARIABLE LABELS  rescode2 'residential codes collapsed'. 
Value Labels rescode2 1 "with parents" 2 "with other family" 3 "apartment alone" 4 "foster care" 6 "emergency shelter" 7 "homeless" 8 "hospital" 11 "group home" 13 "community treatment" 14 "residential treatment" 
   15 "juvenile hall/jail" 17 "other" 18 "unknown" 99 "missing".
Execute.

COMPUTE age=DATE.MDY(12,31,2018) - DateOfBirth.
EXECUTE. 

COMPUTE age_yr=age / (365.25*24*60*60). 
EXECUTE.

SORT CASES BY rescode2(A).

**Part 4: after running the below syntax, check to see that there are no blanks in ProviderSiteID2. If blank, double check the provider site ID list***


STRING ProviderSiteID2 (A30).
RECODE ProviderSiteID 
('37C7'='CRF-Crossroads')  
('37H5'='CRF-Douglas Young') 
('37B9'='CRF-Nueva Visa')
('37HH'='CRF-MAST')
('37EL'='ECS-Para Las Familias')
('37EJ'='FHC Community Circle Central')
('37EK'='FHC Community Circle East')
('37J6'='Fred Finch Wraparound')
('37GN'='MHS-School Based')
('37FE'='NA-TBS')
('37K6'='NCLifeline')
('37K5'='NCLifeline')
('37HB'='Palomar Fallbrook')
('37EB'='Palomar Family Counseling')
('37QU'='Pathways Cornerstone')
('3711'='Rady Central')
('37LV'='Rady CES')
('37HD'='Rady NC')
('3721'='Rady NI')
('37K2'='SAY School Based')
('37LA'='SBCS')
('37G5'='SDCC-East Region OP')
('37OA'='SDCC-FFAST')
('37P5'='SDCC WrapWorks')
('37K3'='SDYS')
('37H7'='SDYS-Counseling Cove')
('37BN'='SYHC-YES')
('37AK'='UPAC')
('37PX'='UPAC MCC')
('37EG'='VH-VHLAC Escondido')
('37GI'='VH-VHLAC North Inland')
('37OS'='VH-Merit Academy')
('37GS'='YMCA Tides')
INTO ProviderSiteID2.
EXECUTE.

SORT CASES BY ProviderSiteID2(A).

**Exclude the DCR duplicates**

USE ALL.
COMPUTE filter_$=(SYSMISSING(DCRDuplicate)).
VARIABLE LABELS filter_$ 'SYSMISSING(DCRDuplicate) (FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.


**Part 5**

CROSSTABS
  /TABLES=ProviderSiteID2 BY ReferredBy rescode2 AttendanceCurr GradesCurr EmotionalDisturbance  
    ProbationStatus WICodeStatus ActiveProblem AbuseServices PhysicianCurr 
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN 
  /COUNT ROUND CELL.








