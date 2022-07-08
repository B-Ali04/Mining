USE [IR]
GO
/****** Object:  StoredProcedure [dbo].[spIR_ProvostWorkloadTable]    Script Date: 7/6/2022 11:10:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[spIR_ProvostWorkloadTable] @AcadYr varchar(7),
	@DeleteInd bit = 0  AS

--- Provost Faculty Workload Table 
--- Per OIR: Yearly request in May/June
---          Include all students
---          Use Registrar data

 
 
--- Course ids for research, prob/sem and field experience courses may change from year to year. 
                          
--- Course Classifications per the Provost:
---      XXX 898 - Internships - Prob/Sem
---      EFB 495 - Undergrad teaching exp - Prob/Sem
---      XXX 420 - Undergrad Internship - Prob/Sem
---      LSA 495 - Readings - Prob/Sem
---      EST 400 - Senior Paper - Research
---      XXX 499 - Honors Thesis/Project - Research
---      XXX 899 - Masters Thesis or Project - Research
---      XXX 999 - Doctoral Thesis Research - Research


--- Course Classifications per OIR:
---      EFB500 - Biology Field Trip - Prob/Sem
                               

--- Course Classifications per OIR and the Registrar:
---      Research - all courses ending in 798, 899, 999
---                 ESF499, EST400  
---      Prob/Sem - all courses ending in 497, 797, 997
 

--- Course Classifications per the Registrar:
---      FCH496 - Research
---      EST495 - Prob/Sem 
---      WPE303 - Prob/Sem
---      496, 696, 796 (except FCH496): Courses with variable credit hours (not research/prob courses)
---      FOR895 - Problem/Sem (grad internship)
---      FTC298 - Research (independent study) 

--- @AcadYr example = 2005-06
  
--- Missing Courses: see if Class Schedule(TS) indicator 
--- on Professor Courses Table is set to 1

/* 5/29/2013 dept change
Hi Cindy-
Ted would like the name of the instructional department to be changed from FEG to ERE on the FW001C reports that I send.  
Thank you.

Maureen O'Neill Fellows, Ph.D. 
Government Relations and Institutional Planning 
________________________________________
From: Theodore A. Endreny 
Sent: Wednesday, May 29, 2013 7:57 PM
To: Maureen O. Fellows
Cc: Teri E. Frese
Subject: Re: ERE Annual Faculty Workload Report

Maureen

Would you, in the future, change our department name to ERE from FEG?

Thanks!

Ted (aka ERE)

Dr. Ted Endreny, P.H., P.E.
*/

DECLARE @SummerSem varchar(5)
SELECT  @SummerSem = substring(@AcadYr,1,4) + '3'

DECLARE @FallSem varchar(5)
SELECT  @FallSem = substring(@AcadYr,1,2) + substring(@AcadYr,6,2) + '1'

DECLARE @SpringSem varchar(5)
SELECT  @SpringSem = substring(@AcadYr,1,2) + substring(@AcadYr,6,2) + '2'

DECLARE @CurrAcadYr varchar(7)
SELECT  @CurrAcadYr = (Select CurrAcadYr from CD..vwCD_IRCurrentAcadYr)


--- Overwrite current activity only 
DELETE FROM IR..WorkloadHistory
WHERE AcadYr = @AcadYr
  AND AcadYr >= @CurrAcadYr


--- Recreate data for a past academic year 
--- Only when requested from IR Office.
DELETE FROM IR..WorkloadHistory
WHERE AcadYr = @AcadYr
  AND @DeleteInd = 1
 


IF NOT EXISTS (select * from IR..WorkloadHistory
               where AcadYr = @AcadYr) 
BEGIN


CREATE TABLE #PROF
       (ProfName        varchar(50) DEFAULT '',
		ProfDept        varchar(6) DEFAULT '',  
		Semester        varchar(5) DEFAULT '',    
		CollInstr       varchar(2) DEFAULT '',
        CourseID        varchar(6) DEFAULT '',
        CampusCd        varchar(2) DEFAULT '',
        InstrTyp        varchar(1) DEFAULT '',
        SectNbr         varchar(2) DEFAULT '',
        ProfCasaTyp     varchar(1) DEFAULT '',
        MeetCasaTyp     varchar(1) DEFAULT '',
        FacContact      smallint default 0,
        CourseTitle     varchar(40) DEFAULT '', 
		MinCredHrs      real NOT NULL DEFAULT 0,
		MaxCredHrs      real NOT NULL DEFAULT 0,
        FileInd         varchar(2) DEFAULT '',
        ProfKey         varchar(12) DEFAULT '',
        SplitWorkload   smallint DEFAULT 0 
)


CREATE TABLE #Workload
       (ProfName        varchar(50) DEFAULT '',
		ProfDept        varchar(6) DEFAULT '',   
        Semester        varchar(5) DEFAULT '',   
        CourseID        varchar(6) DEFAULT '',
   		ProfCasaTyp     varchar(1) DEFAULT '',
        MeetCasaTyp     varchar(1) DEFAULT '',
        SectNbr         varchar(2) DEFAULT '',
		CourseTitle     varchar(40) DEFAULT '',
        CourseTyp       varchar(1) DEFAULT '',
        ResearchInd     varchar(1) DEFAULT '',
        ProbSemInd      varchar(1) DEFAULT '',  
        SummerU         smallint DEFAULT 0,
        SummerG         smallint DEFAULT 0,
        FallU           smallint DEFAULT 0,
        FallG           smallint DEFAULT 0,
        SpringU         smallint DEFAULT 0,
        SpringG 		smallint DEFAULT 0,
        CrHrs           decimal(3,1) DEFAULT 0, 
        VarCrHrsInd     varchar(1) DEFAULT '', 
        RespPercent     smallint DEFAULT 100,
        ResearchU       smallint DEFAULT 0,
        ResearchG       smallint DEFAULT 0,
		ProbSemU        smallint DEFAULT 0,
        ProbSemG        smallint DEFAULT 0, 
        ClassU          int DEFAULT 0,
		ClassG          smallint DEFAULT 0,
        SplitWorkload   smallint DEFAULT 0,
        ProfKey         varchar(12) DEFAULT '',
)
       
--- All Professors except STAFF
--- must select on max casa instruction type (otherwise duplication occurs)
INSERT INTO #PROF (ProfName, ProfDept, Semester, CollInstr, CourseID,
                   CampusCd, InstrTyp, SectNbr, ProfCasaTyp, MeetCasaTyp,
                   FacContact, MinCredHrs, MaxCredHrs, ProfKey)
SELECT distinct ci.FullName,
      Case
         When ci.InstrDept = 'FEG' Then 'ERE'  --- as of 5/29/2013 (see above note)
         When ci.InstrDept <> '' Then ci.InstrDept
         When ci.InstrTyp = 'ST' Then 'STAFF'
         When ci.InstrTyp = 'VI' Then 'VISIT'
         When ci.InstrTyp = 'FC' Then ''
         Else ci.InstrTyp End,
       pc.Semester, pc.CollInstr, pc.CourseID,
       pc.CampusCd, pc.InstrTyp, pc.SectNbr, pc.CasaInstrTyp, '',
       pc.FacultyContact, tc.mincredhrs, tc.maxcredhrs,
       pc.ProfName 
FROM CR..ProfessorCourses pc
inner join CR..Instructors ci on ci.Instructor = pc.ProfName
inner join CR..TermCourses tc on tc.CollInstr = pc.CollInstr
	 AND tc.Semester = pc.Semester AND tc.CourseID  = pc.CourseID
  	 AND tc.CampusCd = pc.CampusCd AND tc.InstrTyp  = pc.InstrTyp
  	 AND tc.SectNbr = pc.SectNbr 
WHERE pc.Semester >= @SummerSem
  AND pc.Semester <= @SpringSem     
  AND pc.CollInstr = '37'
  AND pc.ClassSchedule = 1
  AND pc.ProfName <> 'STAFF'
  AND pc.CasaInstrTyp = 
      (SELECT MAX(pc2.CasaInstrTyp)
       FROM CR..ProfessorCourses pc2
       WHERE pc2.CollInstr = pc.CollInstr
		 AND pc2.Semester  = pc.Semester
         AND pc2.CourseID  = pc.CourseID
  		 AND pc2.CampusCd  = pc.CampusCd 
  		 AND pc2.InstrTyp  = pc.InstrTyp
  		 AND pc2.SectNbr   = pc.SectNbr
         AND pc2.ProfName  = pc.ProfName
         AND pc2.ClassSchedule = 1)  
  AND EXISTS (SELECT * FROM RG..StudentCourses sc
              WHERE sc.collinstr = pc.collinstr
                AND sc.courseid = pc.courseid
                AND sc.semester = pc.semester
                AND sc.instrtyp = pc.instrtyp
                AND sc.sectnbr = pc.sectnbr
                AND sc.crsactioncd <> 'D')   
         

--- STAFF coded as the "main" professor  
--- need to be corrected at some point
INSERT INTO #PROF (ProfName, ProfDept, Semester, CollInstr, CourseID,
                   CampusCd, InstrTyp, SectNbr, ProfCasaTyp, MeetCasaTyp,
                   FacContact, MinCredHrs, MaxCredHrs, ProfKey)
SELECT distinct ci.FullName,
      Case 
         When ci.InstrDept <> '' Then ci.InstrDept
         When ci.InstrTyp = 'ST' Then 'STAFF'
         When ci.InstrTyp = 'VI' Then 'VISIT'
         When ci.InstrTyp = 'FC' Then ''
         Else ci.InstrTyp End,
       pc.Semester, pc.CollInstr, pc.CourseID,
       pc.CampusCd, pc.InstrTyp, pc.SectNbr, pc.CasaInstrTyp, '',
       pc.FacultyContact, tc.mincredhrs, tc.maxcredhrs,
       pc.ProfName 
FROM CR..ProfessorCourses pc
inner join CR..Instructors ci on ci.Instructor = pc.ProfName
inner join CR..TermCourses tc on tc.CollInstr = pc.CollInstr
	 AND tc.Semester = pc.Semester AND tc.CourseID  = pc.CourseID
  	 AND tc.CampusCd = pc.CampusCd AND tc.InstrTyp  = pc.InstrTyp
  	 AND tc.SectNbr = pc.SectNbr 
WHERE pc.Semester >= @SummerSem
  AND pc.Semester <= @SpringSem           
  AND pc.CollInstr = '37'
  AND pc.ProfName = 'STAFF'
  AND pc.PriorityNbr = '01'
  AND pc.ClassSchedule = 1
  AND pc.CasaInstrTyp = 
      (SELECT MAX(pc2.CasaInstrTyp)
       FROM CR..ProfessorCourses pc2
       WHERE pc2.CollInstr = pc.CollInstr
		 AND pc2.Semester  = pc.Semester
         AND pc2.CourseID  = pc.CourseID
  		 AND pc2.CampusCd  = pc.CampusCd 
  		 AND pc2.InstrTyp  = pc.InstrTyp
  		 AND pc2.SectNbr   = pc.SectNbr
         AND pc2.ProfName  = pc.ProfName
         AND pc2.ClassSchedule = 1)  
  AND EXISTS (SELECT * FROM RG..StudentCourses sc
              WHERE sc.collinstr = pc.collinstr
                AND sc.courseid = pc.courseid
                AND sc.semester = pc.semester
                AND sc.instrtyp = pc.instrtyp
                AND sc.sectnbr = pc.sectnbr
                AND sc.crsactioncd <> 'D')   
       
	
UPDATE #PROF
SET CourseTitle = tc.CourseTitle
FROM CR..TermCourses tc
WHERE tc.collinstr = #PROF.collinstr
  AND tc.courseid = #PROF.courseid
  AND tc.semester = #PROF.semester
  AND tc.CampusCd = #PROF.CampusCd 
  AND tc.instrtyp = #PROF.instrtyp
  AND tc.sectnbr = #PROF.sectnbr


 

UPDATE #PROF
SET MeetCasaTyp =   
      isnull((SELECT MAX(mc.CasaInstrTyp)
       FROM CR..MeetingCourses mc
       WHERE mc.CollInstr = #PROF.CollInstr
		 AND mc.Semester  = #PROF.Semester
         AND mc.CourseID  = #PROF.CourseID
  		 AND mc.CampusCd  = #PROF.CampusCd 
  		 AND mc.InstrTyp  = #PROF.InstrTyp
  		 AND mc.SectNbr   = #PROF.SectNbr),'')

 
 


/*  obsolete due to separate STAFF insert 
--- Lab instructor = 'STAFF' but lecture record contains the professor 
--- teaching the course 
UPDATE #PROF
SET ProfName = ci.FullName,
    ProfDept = ci.InstrDept
FROM CR..ProfessorCourses pc
inner join CR..Instructors ci on ci.Instructor = pc.ProfName
WHERE #PROF.ProfName = 'STAFF'
  AND pc.collinstr = #PROF.collinstr
  AND pc.courseid = #PROF.courseid
  AND pc.semester = #PROF.semester
  AND pc.CampusCd  = #PROF.CampusCd 
  AND pc.instrtyp = #PROF.instrtyp
  AND pc.sectnbr = #PROF.sectnbr
  AND pc.PriorityNbr = '01'  
*/
 


--select * from #prof order by profname, courseid

UPDATE #PROF
SET SplitWorkLoad = (SELECT count(distinct pc2.profname)
                     FROM CR..ProfessorCourses pc2
					 WHERE pc2.CollInstr = #PROF.CollInstr
					 AND pc2.Semester  = #PROF.Semester
					 AND pc2.CourseID  = #PROF.CourseID
		  			 AND pc2.CampusCd  = #PROF.CampusCd 
		  			 AND pc2.InstrTyp  = #PROF.InstrTyp
		  			 AND pc2.SectNbr   = #PROF.SectNbr)
 

----------------------------------------------------------------------------------


INSERT INTO #Workload (ProfName, ProfDept, Semester, CourseID, ProfCasaTyp, MeetCasaTyp,
  SectNbr, CourseTitle, CrHrs, VarCrHrsInd, RespPercent, SplitWorkLoad, ProfKey)
SELECT DISTINCT ProfName, ProfDept, Semester, CourseID,
  ProfCasaTyp, MeetCasaTyp, SectNbr, CourseTitle,
  Case When CourseID = 'ESF332' Then 1
       When MinCredHrs = MaxCredHrs Then MinCredHrs
       Else 0 End, 
  Case When MinCredHrs <> MaxCredHrs Then 'V'
       Else '' End,   
  FacContact,
  SplitWorkload,
  ProfKey	
FROM #PROF


DROP TABLE #PROF


--- Identify Research Courses 
UPDATE #Workload
SET ResearchInd = 'Y'
WHERE substring(courseid,4,3) in ('498', '499', '798', '899', '999')
   OR CourseId = 'EST400'
   OR CourseId = 'FCH496'
   OR CourseId = 'FTC298' 


--- Identify Problem/Seminar Courses
UPDATE #Workload
SET ProbSemInd = 'Y'
WHERE substring(courseid,4,3) in ('420','497', '797', '898', '997')
  OR CourseId = 'EFB495' 
  OR CourseId = 'EFB500'  
  OR CourseId = 'LSA495'
  OR CourseId = 'EST495'
  OR CourseId = 'WPE303'
  OR CourseId = 'FOR895'
  

--- Zero Credit Hours indicate courses to be excluded
--- from the ClassU/ClassG fields   
UPDATE #Workload
SET CrHrs = 0,
    VarCrHrsInd = ''  
WHERE ResearchInd = 'Y'
   OR ProbSemInd = 'Y'



/*
--- Courses with Variable Credit Hours
UPDATE #Workload
SET VarCrHrsInd = 'V'
WHERE substring(courseid,4,3) in ('496','696', '796')
  AND CourseID <> 'FCH496' 
  AND CrHrs = 0
*/


--- SU students without a class level are considered to be undergrad students
UPDATE #Workload
SET SummerU = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
                  AND sc.semester = #Workload.Semester 
                  AND sc.courseid = #Workload.CourseId
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('','01','02','03','04','05','08','L8','U8') ),
    SummerG = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
                  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.CourseId
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('06','07','B9','A9','09') )   
WHERE #Workload.Semester = @SummerSem   


UPDATE #Workload
SET FallU = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
                  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.CourseId
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('','01','02','03','04','05','08','L8','U8') ),
    FallG = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
		  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.Courseid
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('06','07','B9','A9','09') )                  
WHERE #Workload.Semester = @FallSem   


UPDATE #Workload
SET SpringU = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
                  AND sc.semester = #Workload.Semester 
                  AND sc.courseid = #Workload.CourseId
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('','01','02','03','04','05','08','L8','U8') ),
    SpringG = (Select count(*) from RG..StudentCourses sc
               inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
               WHERE sc.collinstr = '37'
                  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.CourseId
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D'
                  AND Ts.ClassLevel in ('06','07','B9','A9','09') )  
WHERE #Workload.Semester = @SpringSem   


--- Determine average credits for courses with variable credit hours
UPDATE #Workload
SET Crhrs = (Select sum(creditHrs)from RG..StudentCourses sc
                WHERE sc.collinstr = '37'
				  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.Courseid
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D') / (SummerU + SummerG)                 
WHERE #Workload.Semester = @SummerSem   
  AND #Workload.VarCrHrsInd = 'V'



UPDATE #Workload
SET Crhrs = (Select sum(creditHrs)from RG..StudentCourses sc
                WHERE sc.collinstr = '37'
					AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.Courseid
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D') / (FallU + FallG)                 
WHERE #Workload.Semester = @FallSem   
  AND #Workload.VarCrHrsInd = 'V'


UPDATE #Workload
SET Crhrs = (Select sum(creditHrs)from RG..StudentCourses sc
                WHERE sc.collinstr = '37'
				  AND sc.semester = #Workload.Semester
                  AND sc.courseid = #Workload.Courseid
                  AND sc.CampusCd = 'EF'               
                  AND sc.instrtyp = '2'
                  AND sc.sectNbr = #Workload.SectNbr
                  AND sc.crsactioncd <> 'D') / (SpringU + SpringG)                 
WHERE #Workload.Semester = @SpringSem   
  AND #Workload.VarCrHrsInd = 'V'
--- End of variable credit hours workarea
 


--- Credit Hours for courses with not classified as research or prob/sem   
UPDATE #Workload
SET ClassU = Round(((((SpringU + SummerU + FallU) * CrHrs) * RespPercent) / 100 ), 0) ,
    ClassG = Round(((((SpringG + SummerG + FallG) * CrHrs) * RespPercent) / 100 ), 0)
WHERE CrHrs <> 0 
  

---- Research Credit Hours
---  substring(#Workload.CourseId,4,1) <= '4'; substring(#Workload.CourseId,4,1) >= '5'
UPDATE #Workload
SET ResearchU = isnull((Select sum(sc.CreditHrs) from RG..StudentCourses sc
                 inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
                 WHERE sc.collinstr = '37'
                   AND sc.semester = #Workload.Semester
                   AND sc.courseid = #Workload.CourseId
                   AND sc.CampusCd = 'EF'               
                   AND sc.instrtyp = '2'
				   AND sc.sectNbr = #Workload.SectNbr
                   AND sc.crsactioncd <> 'D' 
                   AND Ts.ClassLevel in ('','01','02','03','04','05','08','L8','U8') ),0),
    ResearchG = isnull((Select sum(sc.CreditHrs) from RG..StudentCourses sc
                 inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
                 WHERE sc.collinstr = '37'
                   AND sc.semester = #Workload.Semester
                   AND sc.courseid = #Workload.CourseId
                   AND sc.CampusCd = 'EF'               
                   AND sc.instrtyp = '2'
				   AND sc.sectNbr = #Workload.SectNbr
                   AND sc.crsactioncd <> 'D'  
                   AND Ts.ClassLevel in ('06','07','B9','A9','09') ),0)
WHERE ResearchInd = 'Y'

--- Doesn't occur frequently
UPDATE #Workload
SET ResearchU = Round( ((ResearchU * RespPercent) / 100 ), 0),
    ResearchG = Round(( (ResearchG * RespPercent) / 100 ), 0)
WHERE ResearchInd = 'Y'
  And RespPercent <> 100 
  

---- Prob/Sem Credit Hours
UPDATE #Workload
SET ProbSemU = isnull((Select sum(sc.CreditHrs) from RG..StudentCourses sc
                 inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
                 WHERE sc.collinstr = '37'
                   AND sc.semester = #Workload.Semester
                   AND sc.courseid = #Workload.CourseId
                   AND sc.CampusCd = 'EF'               
                   AND sc.instrtyp = '2'
				   AND sc.sectNbr = #Workload.SectNbr
                   AND sc.crsactioncd <> 'D'
                   AND Ts.ClassLevel in ('','01','02','03','04','05','08','L8','U8') ),0),
    ProbSemG = isnull((Select sum(sc.CreditHrs) from RG..StudentCourses sc
                 inner join RG..TermSummaries ts on ts.recid = sc.recid and ts.semester = sc.semester
                 WHERE sc.collinstr = '37'
                   AND sc.semester = #Workload.Semester
                   AND sc.courseid = #Workload.CourseId
                   AND sc.CampusCd = 'EF'               
                   AND sc.instrtyp = '2'
				   AND sc.sectNbr = #Workload.SectNbr
                   AND sc.crsactioncd <> 'D'
                   AND Ts.ClassLevel in ('06','07','B9','A9','09') ),0)
WHERE ProbSemInd = 'Y'


--- Doesn't occur frequently
UPDATE #Workload
SET ProbSemU = Round( ((ProbSemU * RespPercent) / 100 ), 0),
    ProbSemG = Round(( (ProbSemG * RespPercent) / 100 ), 0)
WHERE ProbSemInd = 'Y'
  And RespPercent <> 100 
 

--- Course Type: Lab, Field Experience, International or Distance Learning

--- Labs
UPDATE #Workload
SET CourseTyp = 'L'
WHERE ProfCasaTyp = '4'
   OR MeetCasaTyp = '4'


--- Field Experience Courses: Per the Provost)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE courseid in ('EFB500')


--- Field Experience: Fall Courses (per Registrar)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE substring(semester,5,1) = '1'
  and courseid in ('EFB513', 'FOR513')


--- Field Experience: Spring Courses (per Registrar)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE substring(semester,5,1) = '2'
  and courseid in ('EFB523', 'FOR523','EFB484','EFB684')


--- Field Experience: Summer Courses (from Ray)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE substring(semester,5,1) = '3'
  and courseid in ('FOR301', 'FOR303')


--- Field Experience Courses: Not dependent on semester (per Registrar)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE courseid in ('EFB202', 'EFB496', 'EFB618', 'EFB622')


--- Field Experience Courses: Not dependent on semester (per Registrar)
UPDATE #Workload
SET CourseTyp = 'F'
WHERE substring(courseid,5,2) < '97'
  and substring(courseid,1,4) in ('EFB3', 'EFB4')


--- International Courses
UPDATE #Workload
SET CourseTyp = 'I'
FROM CR..TermCourses tc
WHERE tc.CreditType = 'OVR' 
  AND tc.CollInstr = '37'
  AND tc.Semester  = #Workload.Semester
  AND tc.CourseID  = #Workload.CourseID
  AND tc.CampusCd  = 'EF'
  AND tc.InstrTyp  = '2'
  AND tc.SectNbr   = #Workload.SectNbr 


--- Distance Learning Courses
UPDATE #Workload
SET CourseTyp = 'D'
FROM CR..TermCourses tc
WHERE tc.CreditType = 'DSL' 
  AND tc.CollInstr = '37'
  AND tc.Semester  = #Workload.Semester
  AND tc.CourseID  = #Workload.CourseID
  AND tc.CampusCd  = 'EF'
  AND tc.InstrTyp  = '2'
  AND tc.SectNbr   = #Workload.SectNbr 
 

INSERT INTO IR..WorkloadHistory
SELECT @AcadYr, #Workload.*, getdate()
FROM #Workload


---- Change department assigned in CR Instructors Table
---  Per April 2010 email request: Instructors not in FEG dept. 
UPDATE IR..WorkloadHistory
SET ProfDept = ''
WHERE RTrim(ProfName) in ('GERBER, DAVID', 'COLLINS, VIRGINIA')
  AND ProfDept = 'FEG'


DROP TABLE #Workload


END


--select W.*, 
--'OutputToExcel' = @ExcelInd,
--'SumST' = smr.ShortTitle, 
--'SumET' = 'Sum ' + substring(smr.ShortTitle,9,2), 
--'FallST' = fall.ShortTitle, 
--'FallET' = 'Fall ' + substring(fall.ShortTitle,7,2), 
--'SprST' = spr.ShortTitle,
--'SprET' = 'Spr ' + substring(spr.ShortTitle,9,2)  
--from IRSF..Workload W 
--left outer join CD..vwcd_RGSemesters smr on smr.tablecd = @SummerSem
--left outer join CD..vwcd_RGSemesters fall on fall.tablecd = @FallSem
--left outer join CD..vwcd_RGSemesters spr on spr.tablecd = @SpringSem

 
--select #Workload.*, 
--'OutputToExcel' = @ExcelInd,
--'SumST' = smr.ShortTitle, 
--'SumET' = 'Sum ' + substring(smr.ShortTitle,9,2), 
--'FallST' = fall.ShortTitle, 
--'FallET' = 'Fall ' + substring(fall.ShortTitle,7,2), 
--'SprST' = spr.ShortTitle,
--'SprET' = 'Spr ' + substring(spr.ShortTitle,9,2)  
--from #Workload 
--left outer join CD..vwcd_RGSemesters smr on smr.tablecd = @SummerSem
--left outer join CD..vwcd_RGSemesters fall on fall.tablecd = @FallSem
--left outer join CD..vwcd_RGSemesters spr on spr.tablecd = @SpringSem
 


/* 
-----where #Workload.researchind = 'y' or #Workload.probsemind = 'y'
select distinct substring(profname,1,30), profdept, courseid, sectnbr,

substring( coursetitle,1,30) 
from #Workload
where profdept = ''
order by substring(ProfName,1,30), CourseID, SectNbr


---- Original classifications
---- Research Credit Hours
---  Course numbers per Maureen 

---- '420','895','898','899','999' 

---- Prob/Sem Credit Hours
---- course numbers per Maureen: 498 
---- course numbers per Ray: 798 
*/ 
 

 
/* Variable Credit Courses
select distinct Semester, Courseid, CourseTitle  ----, SectNbr, , researchind, probsemind, crhrs 
from #Workload 
where substring(courseid,4,3) not in ('898','420','499')
  and (probsemind  = '' and crhrs = 0)
  and (researchind = '' and crhrs = 0)
order by Semester, CourseID  ---, SectNbr
*/





 






































































































































