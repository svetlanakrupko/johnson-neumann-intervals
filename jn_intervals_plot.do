drop is_transition_area
gen is_transition_area = 0

forval i = 2/6 {
    if is_significant[`i'] == 1 & is_significant[`i'-1] == 0 {
        replace is_transition_area = 1 if mod_val >= mod_val[`i'-1] & mod_val <= mod_val[`i']
    }
}

list mod_val lower_ci upper_ci is_significant is_transition_area

twoway /// 
	(line effect mod_val) ///
	(rarea lower_ci upper_ci mod_val if is_significant == 0 | is_significant == 1 & is_transition_area == 1, color(red%100) fc(red%30) lcolor(red) lpattern(solid) lwidth(medium) ///
    legend(label(2 "n.s.")) ) ///
    (rarea lower_ci upper_ci mod_val if is_significant == 1, color(green%100) fc(green%30) lcolor(green) lpattern(solid) lwidth(medium) ///
    legend(label(2 "p < 0.05")) ) ///
    , ///
	legend(order(2 3 4) position(7) ring(0) col(1))