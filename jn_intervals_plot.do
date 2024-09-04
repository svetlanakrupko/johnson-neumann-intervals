drop is_significant
gen is_significant = 0

list mod_val effect se p_value lower_ci upper_ci is_significant

local is_significant_values "1 1 1 1 1 0 0 0 0 0 0 0 1 1 1 0 1"
local i = 1
foreach val of local is_significant_values {
    replace is_significant = `val' in `i'
    local i = `i' + 1
}

list mod_val lower_ci upper_ci is_significant

count
local n = r(N)
gen id = _n

forval i = `n'(-1)1 {
    if (is_significant[`i'-1] == is_significant[`i'+1] & is_significant[`i'] != is_significant[`i'-1]) {
        expand 2 in `i'
        replace id = id + 0.1 in `=`i'+1'
    }
}
list id mod_val lower_ci upper_ci is_significant
sort id
drop id
list mod_val lower_ci upper_ci is_significant

drop is_transition_area
gen is_transition_area = 0
count
local n = r(N)
forval i = 1/`n' {
	replace is_transition_area = 0 in 1
	replace is_transition_area = 0 in `i' if is_significant[`i'] == 1
	replace is_transition_area = 1 in `i' if (is_significant[`i'] == 0) & (is_significant[`i'-1] == 1)
	replace is_transition_area = 1 in `i' if (is_significant[`i'] == 0) & (is_significant[`i'+1] == 1) & (is_significant[`i'-1] != 0)
	replace is_transition_area = 0 in `n'
}

list mod_val lower_ci upper_ci is_significant is_transition_area

drop new_mod_val
drop new_lower_ci
drop new_upper_ci

gen new_mod_val = mod_val
gen new_lower_ci = lower_ci
gen new_upper_ci = upper_ci
replace new_mod_val = . if ((is_transition_area == 0) & (is_significant == 0))
replace new_lower_ci = . if ((is_transition_area == 0) & (is_significant == 0))
replace new_upper_ci = . if ((is_transition_area == 0) & (is_significant == 0))
list new_mod_val new_lower_ci new_upper_ci

drop insignificant_mod_val
drop insignificant_lower_ci
drop insignificant_upper_ci

gen insignificant_mod_val = mod_val
gen insignificant_lower_ci = lower_ci
gen insignificant_upper_ci = upper_ci
replace insignificant_mod_val = . if is_significant == 1
replace insignificant_lower_ci = . if is_significant == 1
replace insignificant_upper_ci = . if is_significant == 1
list insignificant_mod_val insignificant_lower_ci insignificant_upper_ci

list insignificant_mod_val insignificant_lower_ci insignificant_upper_ci new_mod_val new_lower_ci new_upper_ci is_significant is_transition_area

twoway /// 
	(rarea new_lower_ci new_upper_ci new_mod_val, color(green%100) fc(green%30) lcolor(green) lpattern(solid) lwidth(medium) ///
    legend(label(3 "p < 0.05")) cmissing(n)) ///
	(rarea insignificant_lower_ci insignificant_upper_ci insignificant_mod_val, color(red%100) fc(red%30) lcolor(red) lpattern(solid) lwidth(medium) ///
    legend(label(2 "n.s.")) cmissing(n)) ///
    , ///
	legend(order(2 3 4) position(7) ring(0) col(1))