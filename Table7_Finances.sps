* Encoding: UTF-8.
**Open the PAF Finance file**

**Part 1: Select the correct date range and recode**

FILTER OFF.
USE ALL.
SELECT IF (AssessmentDate >= DATE.MDY(07,01,2018)).
EXECUTE.


FILTER OFF.
USE ALL.
SELECT IF (AssessmentDate <= DATE.MDY(03,31,2019)).
EXECUTE.


RECODE FinancialSourceCode (1=1) (2=2) (3=1) (4=4) (5=1) (6=1) (7=1) (8=1) (9=9) (10=10) (11=11) (12=12) (13=13) (14=14) (15=14) (16=14) (17=18) (18=18) (19=19) INTO newfinance.
VALUE LABELS newfinance 1 "family" 2 "wages" 4 "savings" 9 "loans" 10 "housing" 11 "general" 12 "food stamps" 13 "TANF" 14 "SSI/SSDI" 18 "other" 19 "none".
Execute.


** Part 2: Identify Duplicate Cases and find missing CSI#.**

SORT CASES BY CSINumber(A) newfinance(A).
MATCH FILES
  /FILE=*
  /BY CSINumber newfinance
  /FIRST=PrimaryFirst.
VARIABLE LABELS  PrimaryFirst 'Indicator of each first matching case as Primary'.
VALUE LABELS  PrimaryFirst 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryFirst (ORDINAL).
FREQUENCIES VARIABLES=PrimaryFirst.
EXECUTE.

** Part 3: Filter out duplicate**

FILTER OFF.
USE ALL.
SELECT IF (PrimaryFirst = 1).
EXECUTE.


**Part 4**

STRING ProviderSiteIDF (A30).
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
INTO ProviderSiteIDF.
EXECUTE.


SORT CASES BY ProviderSiteIDF(A).

**Part 5: recode and generate aggregate. Save the new file as finances_aggregate**

COMPUTE family=0.
EXECUTE.
DO IF (newfinance = 1).
RECODE family (0=1).
END IF.
EXECUTE.

COMPUTE wages=0.
EXECUTE.
DO IF (newfinance = 2).
RECODE wages (0=1).
END IF.
EXECUTE.

COMPUTE savings=0.
EXECUTE.
DO IF (newfinance = 4).
RECODE savings (0=1).
END IF.
EXECUTE.

COMPUTE loans=0.
EXECUTE.
DO IF (newfinance = 9).
RECODE loans (0=1).
END IF.
EXECUTE.

COMPUTE housing=0.
EXECUTE.
DO IF (newfinance = 10).
RECODE housing (0=1).
END IF.
EXECUTE.

COMPUTE general=0.
EXECUTE.
DO IF (newfinance = 11).
RECODE general (0=1).
END IF.
EXECUTE.

COMPUTE foodstamps=0.
EXECUTE.
DO IF (newfinance = 12).
RECODE foodstamps (0=1).
END IF.
EXECUTE.

COMPUTE TANF=0.
EXECUTE.
DO IF (newfinance = 13).
RECODE TANF (0=1).
END IF.
EXECUTE.

COMPUTE SSIDI=0.
EXECUTE.
DO IF (newfinance = 14).
RECODE SSIDI (0=1).
END IF.
EXECUTE.

COMPUTE other=0.
EXECUTE.
DO IF (newfinance = 18).
RECODE other (0=1).
END IF.
EXECUTE.

COMPUTE none=0.
EXECUTE.
DO IF (newfinance = 19).
RECODE none (0=1).
END IF.
EXECUTE.


DATASET DECLARE finances_aggregate.
AGGREGATE
  /OUTFILE='finances_aggregate'
  /BREAK=CSINumber ProviderSiteIDF
  /family_max=MAX(family) 
  /wages_max=MAX(wages) 
  /savings_max=MAX(savings) 
  /loans_max=MAX(loans) 
  /housing_max=MAX(housing) 
  /general_max=MAX(general) 
  /foodstamps_max=MAX(foodstamps) 
  /TANF_max=MAX(TANF) 
  /SSIDI_max=MAX(SSIDI) 
  /other_max=MAX(other) 
  /none_max=MAX(none). 



**Part 6: merge the finances_aggregate with PAFAssessmentQInfo_clean***

**Part 7**

COMPUTE missing_max=0.
EXECUTE.

DO IF (MISSING(family_max) & MISSING(wages_max) & MISSING(savings_max) & MISSING(loans_max) & 
    MISSING(housing_max) & MISSING(general_max) & MISSING(foodstamps_max) & MISSING(TANF_max) & 
    MISSING(SSIDI_max) & MISSING(other_max)  & MISSING(none_max)).
RECODE missing_max (0=1).
END IF.
EXECUTE.

DO IF (missing_max = 1).
RECODE family_max wages_max savings_max loans_max housing_max general_max foodstamps_max TANF_max 
    SSIDI_max other_max none_max (SYSMIS=0).
END IF.
EXECUTE.


**Exclude the DCR duplicates**

USE ALL.
COMPUTE filter_$=(SYSMISSING(DCRDuplicate)).
VARIABLE LABELS filter_$ 'SYSMISSING(DCRDuplicate) (FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.



CROSSTABS
  /TABLES=ProviderSiteID2 BY family_max wages_max savings_max loans_max housing_max general_max 
    foodstamps_max TANF_max SSIDI_max other_max none_max missing_max 
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN 
  /COUNT ROUND CELL.






