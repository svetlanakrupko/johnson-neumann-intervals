capture program drop jn_intervals
program define jn_intervals
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
		display `main_indepvar'
		display `moderator'
		display `mod_val'
		
		local effect = margins_result[1,2]
		local se = margins_result[2,2]
		local p_value = margins_result[4,2]
		
		di "Moderator Value: `mod_val' | Effect: `effect' | SE: `se' | p-value: `p_value'"
		
		local lower_ci = `effect' - 1.96 * `se'
		local upper_ci = `effect' + 1.96 * `se'
		
		local is_significant = `p_value' < ((100 - `level') / 100)
		
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
	
	drop if missing(mod_val, effect, se, p_value, lower_ci, upper_ci, is_significant)
	
	list mod_val effect se p_value lower_ci upper_ci is_significant
end