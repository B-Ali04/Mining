/*
Hey were to pick up, sgbstdn is writting everything out again uh probably best if you get that out of the way first

*/
SELECT 
       f_get_desc_fnc('STVDEPT', SGBSTDN.SGBSTDN_DEPT_CODE, 30)   AS dept,
       F_FORMAT_NAME(shrtckn.shrtckn_pidm, 'LFMI')               AS full_name, 
       shrtckn.shrtckn_pidm                                    AS pidm,
       shrtckn.shrtckn_term_code                               AS term_code,
       shrtckn.shrtckn_seq_no                                  AS tckn_seq_no,
       shrtckn.shrtckn_crn                                     AS crn,
       shrtckn.shrtckn_subj_code                               AS subj_code,
       shrtckn.shrtckn_crse_numb                               AS crse_numb,
       f_get_sgbstdn_rowid(shrtckn.shrtckn_pidm, shrtckn_term_code) SGBSTDN_ROWID

FROM   shrtckn shrtckn
left outer join shrtckl shrtckl on shrtckl.shrtckl_pidm = shrtckn.shrtckn_pidm
     AND shrtckl.shrtckl_term_code = shrtckn.shrtckn_term_code
     AND shrtckl.shrtckl_tckn_seq_no = shrtckn.shrtckn_seq_no
left outer join  shrtckg shrtckg on shrtckg.shrtckg_pidm = shrtckn.shrtckn_pidm
     AND shrtckg.shrtckg_term_code = shrtckn.shrtckn_term_code 
     AND shrtckg.shrtckg_seq_no = shrtckn.shrtckn_seq_no
     AND shrtckg.shrtckg_tckn_seq_no = (SELECT MAX(shrtckg_tckn_seq_no)
                               FROM   shrtckg shrtckg1
                               WHERE  shrtckg1.shrtckg_pidm = shrtckg.shrtckg_pidm
                               AND    shrtckg1.shrtckg_term_code = shrtckg.shrtckg_term_code)


left outer join SGBSTDN SGBSTDN on SGBSTDN.SGBSTDN_PIDM = SHRTCKN.SHRTCKN_PIDM
        and SGBSTDN.SGBSTDN_STST_CODE = 'AS'
        --and SGBSTDN.SGBSTDN_TERM_CODE_EFF = SHRTCKN.SHRTCKN_TERM_CODE
        /*
        and SGBSTDN.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN.SGBSTDN_TERM_CODE_EFF)
                                            FROM SGBSTDN SGBSTDNX
                                            WHERE SGBSTDNX.SGBSTDN_PIDM = SGBSTDN.SGBSTDN_PIDM
                                            AND SGBSTDNX.SGBSTDN_TERM_CODE_EFF >= SHRTCKN.SHRTCKN_TERM_CODE)
                                            */
                                         
WHERE  
shrtckn.shrtckn_term_code in (201820) --fall 2017, 
and (shrtckg.shrtckg_gmod_code = 'Y'             
    or (shrtckg.shrtckg_gmod_code is null and shrtckn_coll_code = 'SU'))
    and SGBSTDN.SGBSTDN_TERM_CODE_EFF = fy_sgbstdn_eff_term(SGBSTDN.SGBSTDN_PIDM, shrtckn.shrtckn_term_code)
--    and SGBSTDN.SGBSTDN_TERM_CODE_EFF = SHRTCKN.SHRTCKN_TERM_CODE
    /*
        and SGBSTDN.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN.SGBSTDN_TERM_CODE_EFF)
                                            FROM SGBSTDN SGBSTDNX
                                            WHERE SGBSTDNX.SGBSTDN_PIDM = SGBSTDN.SGBSTDN_PIDM
                                            AND SGBSTDNX.SGBSTDN_TERM_CODE_EFF <= SHRTCKN.SHRTCKN_TERM_CODE)
*/
order by
      --shrtckn.shrtckn_term_Code, f_get_desc_fnc('STVDEPT', SGBSTDN.SGBSTDN_DEPT_CODE, 30),
       (shrtckn.shrtckn_subj_code), (shrtckn.shrtckn_crse_numb), F_FORMAT_NAME(shrtckn.shrtckn_pidm, 'LFMI')          
