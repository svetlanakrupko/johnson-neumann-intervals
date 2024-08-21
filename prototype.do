

// Example usage:
matrix drop _all
scalar drop _all
program drop _all
* Ensure the dataset is loaded
use "/Users/data/data.dta", clear
melogit populist i.rural##c.house_c [pweight=anweight] || country: i.rural //housing

hello rural house_c, ic(1)

capture program drop hello
program define hello
	set trace on
    version 17
	
    syntax varlist(min=2 max=2) [if] , ic(integer) [level(integer 95)]
	
	local main_indepvar : word 1 of `varlist'
    local moderator : word 2 of `varlist'
	
	confirm variable `main_indepvar'
    if _rc {
        display as error "Error: Main independent variable `main_indepvar' does not exist in the dataset."
        exit 198
    }

    confirm variable `moderator'
    if _rc {
        display as error "Error: Moderator variable `moderator' does not exist in the dataset."
        exit 198
    }
	
	display "Summarize Moderator"
	summarize `moderator'

    local min_mod = r(min)
    local max_mod = r(max)

    matrix results = (., ., ., ., ., ., .)

	forvalues mod_val = `min_mod'(`ic')`max_mod' {
		margins, dydx(`main_indepvar') at(`moderator'=`mod_val')
		matrix margins_result = r(table)
		
		local effect = margins_result[1,2]
		local se = margins_result[2,2]
		local p_value = margins_result[4,2]
		
		local lower_ci = `effect' - 1.96 * `se'
		local upper_ci = `effect' + 1.96 * `se'
		// mod_val when p_value less or equal than (100 - level) / 100
		
		local is_significant = `p_value' <= (100 - `level') / 100
		
		display "Is significant `is_significant'"
		
		matrix new_row = (`mod_val', `effect', `se', `p_value', `lower_ci', `upper_ci', `is_significant')
		matrix results = results \ new_row
	}
	
	matrix list results

	local num_rows = rowsof(results)
	
	clear
	set obs `num_rows'    

    foreach var of local vars_to_drop {
        confirm variable `var'
        if !_rc {
            drop var
        }
    }

	gen mod_val = .
	gen effect = .
	gen se = .
	gen p_value = .
	gen lower_ci = .
	gen upper_ci = .
	gen is_significant = .
	
	forval i = 2/`num_rows' {
		local row_index = `i'
		
		replace mod_val = results[`i', 1] in `row_index'
		replace effect = results[`i', 2] in `row_index'
		replace se = results[`i', 3] in `row_index'
		replace p_value = results[`i', 4] in `row_index'
		replace lower_ci = results[`i', 5] in `row_index'
		replace upper_ci = results[`i', 6] in `row_index'
		replace is_significant = results[`i', 7] in `row_index'
	}
	
	list mod_val effect se p_value lower_ci upper_ci is_significant
end

list mod_val effect se p_value lower_ci upper_ci is_significant

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






***********

*built spcifier regression model
// tempvar main_indepvar
// gen main_indepvar = rural
//
// tab main_indepvar
// tempvar mod fuel_c
*run regression
// melogit populist i.main_indepvar##c.mod [pweight=anweight] || country: i.main_indepvar //housing
*run your function
// jn_intervals main_indepvar mod ic sig_level

// melogit populist i.rural##c.fuel_c [pweight=anweight] || country: i.rural //housing
// ic - iterations_count
