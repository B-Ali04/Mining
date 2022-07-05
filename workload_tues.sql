SELECT (asgn.sirasgn_term_code)                                   AS term_code,
       (sect.ssbsect_sicas_camp_course_id)                        AS key,
       (asgn.sirasgn_crn)                                         AS crn,
       (crse.scbcrse_title)                                       AS title,
       (asgn.sirasgn_pidm)                                        AS pidm,
       (asgn.sirasgn_primary_ind)                                 AS primary_ind,
       (asgn.sirasgn_category)                                    AS session_ind,
       (rii.id)                                                   AS id,
       (rii.lfmi_name)                                            AS lfmi_name,
       (rii.lname)                                                AS lname,
       (rii.fname)                                                AS fname/*,
       (rii.pref_fname)                                           AS pref_fname,
       [ADD_COLUMNS]
       \(asgn.rowid)                                               AS sirasgn_rowid,
       (sect.rowid)                                               AS ssbsect_rowid,
       (rii.spriden_rowid)                                        AS spriden_rowid,
       (rii.spbpers_rowid)                                        AS spbpers_rowid
       */
       /*[ADD_ROWIDS]*/ --select * from sirasgn
FROM (ssbsect sect)
join  (sirasgn asgn) on (asgn.sirasgn_term_code = sect.ssbsect_term_code)
AND    (asgn.sirasgn_crn = sect.ssbsect_crn)
join (rel_identity rii) on rii.pidm = asgn.sirasgn_pidm
join (scbcrse crse) on (crse.scbcrse_subj_code = sect.ssbsect_subj_code)
and (crse.scbcrse_crse_numb = sect.ssbsect_crse_numb)
and (crse.scbcrse_eff_term) = (select max(crse.scbcrse_eff_term)
                            from scbcrse c
                            where c.scbcrse_subj_code = sect.ssbsect_subj_code
                            and c.scbcrse_crse_numb = sect.ssbsect_crse_numb
                            and c.scbcrse_eff_term <= sect.ssbsect_term_code
                            )
--sect.ssbsect_term_code --select * from scbcrse
/*[ADD_JOINS]*/
WHERE  /*(asgn.sirasgn_term_code = sect.ssbsect_term_code)
AND    (asgn.sirasgn_crn = sect.ssbsect_crn)
AND   */ (rii.pidm = asgn.sirasgn_pidm)
and    sect.ssbsect_Term_Code = 202220

/*
the tough part:

sub query to incldue previous semster without initializing a variable
*/

order by lfmi_name, key, session_ind
