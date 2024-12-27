
*********************************************************************************		
* 0.Basic Setup
*********************************************************************************		
clear all
set more off
set mem 100m

* The user should only adjust this path: Copy&Paste the name of the attached file with name 'code_sample'
global path "/Users/aristomenischryssafesprogopoulos/Desktop/code_sample/stata_sample" 

* load programs 
quietly: do "$path/data/0.2_programs.do"
* graph output (defined in programs.do)
	global dark_gray gs4
	global med_gray gs7
	global light_gray gs10
	graph_options, graph_margin(l=-2 r=-2 b=-4 t=4) xlabel_options(labsize(vlarge)  format(%9.0fc) labgap(*0.02)) ylabel_options(labsize(vlarge) grid glcolor(ltblue*0.4)) ///
	xtitle_options(size(vlarge) color(black) height(+8)) ytitle_options(size(vlarge) color(black)) marker_options(msize(medsmall) mcolor($dark_gray))
	global plotregion  "plotregion(fcolor(white) lstyle(none) lcolor(white))"
	global graphregion  "graphregion(fcolor(white) lstyle(none) lcolor(white))"


*********************************************************************************		
* 1. Load data 
* Main variables: Firms , Industries (firms belong to industries), Firm-level proximity measures, Firm-level spending to social topics
*********************************************************************************		
use "$path/data/mca_prowess_firm_cluster_hetero_toy.dta", clear
keep mca_cin mca_csr_proj_cluster_repl pro_nic_2dig_2008_md mca_csr_proj_spent_re_su pro_cin row_id pro_csr_spent_re_su flag_holding_company flag_recl*  aff_mean mca_csr_proj_spent_re_socc_su ///
mca_csr_proj_spent_re_socg_su mca_csr_proj_spent_re_dire_su mca_csr_proj_spent_re_otag_su mca_csr_proj_spent_re_miss_su pro_nic_2dig_2008_md pro_nic_2dig_2008_lab
save "$path/data/mca_prowess_firm_cluster_hetero_toy_.dta", replace

label variable mca_cin "firm's code"
label variable mca_csr_proj_cluster_repl "social topic"
label variable pro_nic_2dig_2008_md "National Industrial Classification (NIC)"
label variable mca_csr_proj_spent_re_su "CSR firm spending to social topic"



isid mca_cin mca_csr_proj_cluster_repl
count 
unique mca_csr_proj_cluster_repl if !inlist(mca_csr_proj_cluster_repl,"Couldn't fix classification","missing") 

* 1.1 Create heterogeneity variables: L if firm is Listed *******************************************

gen CIN_listed=substr(pro_cin,1,1)
replace CIN_listed = "U" if row_id > 5000



*********************************************************************************		
* 2. Drop obs 
* When a firm project cannot be clasified into the known social-topic categories 
*********************************************************************************		
	// missing info
	drop if pro_nic_2dig_2008_md== .  
	drop if inlist(mca_csr_proj_cluster_repl,"missing","Couldn't fix classification")  
	
	// firm has no spending at all 
	bys mca_cin: egen mca_csr_proj_spent_re_sum_fi = total(mca_csr_proj_spent_re_su)
	drop if mca_csr_proj_spent_re_sum_fi == 0 
	
	count if mca_csr_proj_spent_re_sum_fi == 0
	count if mca_csr_proj_spent_re_sum_fi == 0 & pro_csr_spent_re_su == 0
	
	// holding companies
	drop if flag_holding_company == 1 
		
	sum flag_recl*
	
	
*********************************************************************************		
* 3. Create variables
* Various income size variables etc
*********************************************************************************		
	// standardize proximity metric
	// we want to standardize the proximity variable after having created the sample 
	sum aff_mean, d
	return list
	replace aff_mean = (aff_mean - `r(mean)')/`r(sd)'
	sum aff_mean, d
	
	// browse all variables for regression needed
	sort mca_cin pro_nic_2dig_2008_md mca_csr_proj_cluster_repl
	//br mca_cin mca_csr_proj_cluster_repl pro_nic_2dig_2008_md pro_nic_2dig_2008_lab aff_* mca_csr_proj_spent_re_su
		
	// create share
	gen mca_csr_proj_spent_re_sh = mca_csr_proj_spent_re_su/mca_csr_proj_spent_re_sum_fi // becomes missing if sum is zero
	
	// create share with zero set to missing 
	gen mca_csr_proj_spent_re_sh_mz = cond(mca_csr_proj_spent_re_sh == 0,.,mca_csr_proj_spent_re_sh) // becomes missing if sum is zero
	
	// create indicator
	gen mca_csr_proj_spent_re_ind = cond(mca_csr_proj_spent_re_su > 0,1,0)

	// create implementation variables 
	foreach var in socc socg dire otag miss {
		gen mca_csr_proj_spent_re_`var'_su_t = mca_csr_proj_spent_re_`var'_su / mca_csr_proj_spent_re_sum_fi  // careful, this becomes zero if sum is zero 
		gen mca_csr_proj_spent_re_`var'_su_r = mca_csr_proj_spent_re_`var'_su / mca_csr_proj_spent_re_su  // careful, this becomes zero if sum is zero 
		gen mca_csr_proj_spent_re_`var'_su_i = cond(mca_csr_proj_spent_re_`var'_su > 0,1,0,.) 
	}
		
	tostring pro_nic_2dig_2008_md, gen(pro_nic_2dig_2008_md_str)
	gen se_ind_topic = pro_nic_2dig_2008_md_str + " " + mca_csr_proj_cluster_repl
	
	encode mca_csr_proj_cluster_repl, gen(mca_csr_proj_cluster_repl_enc) 
	unique mca_csr_proj_cluster_repl_enc  
	
	save "$path/data/mca_prowess_firm_cluster_hetero_toy_final.dta", replace

	
*********************************************************************************		
*  4. Regressions on affinity metric
*  How the proximity of the production function affects the spending behaviour of the firm 
*  Heterogeneity based on whether a firm is Listed or Unlisted
*********************************************************************************		
	reghdfe mca_csr_proj_spent_re_sh aff_mean [aw = mca_csr_proj_spent_re_sum_fi], absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	//reghdfe mca_csr_proj_spent_re_sh aff_mean [aw = mca_csr_proj_spent_re_sum_fi_w], absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	
	gen dummy_list = 0
	replace dummy_list = 1 
	
	foreach dum in L U {
	
	reghdfe mca_csr_proj_spent_re_sh aff_mean if CIN_listed == "`dum'", absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	est store sh_aff_mean_`dum' 
		sum mca_csr_proj_spent_re_sh if CIN_listed == "`dum'"
		estadd scalar avg_dv = `r(mean)'	
		local avg_dv_l = `r(mean)'	
		unique mca_cin if mca_csr_proj_spent_re_sh != .
		estadd scalar firms_N = `r(unique)' 
		unique mca_csr_proj_cluster_repl if mca_csr_proj_spent_re_sh != .
		estadd scalar cluster_N = `r(unique)' 
		estadd local firm_FE "Yes"
		estadd local cluster_FE "Yes"
		local perc_change = _b[aff_mean]/`avg_dv_l'
		display "`perc_change'"
		
	// main regression after exploration (to print)
	reghdfe mca_csr_proj_spent_re_ind aff_mean if CIN_listed == "`dum'", absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	est store ind_aff_mean_`dum' 
		sum mca_csr_proj_spent_re_ind if CIN_listed == "`dum'"
		estadd scalar avg_dv = `r(mean)'		
		local avg_dv_l = `r(mean)'	
		unique mca_cin if mca_csr_proj_spent_re_ind != .
		estadd scalar firms_N = `r(unique)' 
		unique mca_csr_proj_cluster_repl if mca_csr_proj_spent_re_ind != .
		estadd scalar cluster_N = `r(unique)' 
		estadd local firm_FE "Yes"
		estadd local cluster_FE "Yes"
		local perc_change = _b[aff_mean]/`avg_dv_l'
		display "`perc_change'"
		
	reghdfe mca_csr_proj_spent_re_sh_mz aff_mean if CIN_listed == "`dum'", absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	est store sh_mz_aff_mean_`dum' 
		sum mca_csr_proj_spent_re_sh_mz if CIN_listed == "`dum'"
		estadd scalar avg_dv = `r(mean)'
		local avg_dv_l = `r(mean)'	
		unique mca_cin if mca_csr_proj_spent_re_sh_mz != .
		estadd scalar firms_N = `r(unique)' 
		unique mca_csr_proj_cluster_repl if mca_csr_proj_spent_re_sh_mz != .
		estadd scalar cluster_N = `r(unique)' 
		estadd local firm_FE "Yes"
		estadd local cluster_FE "Yes"	
		local perc_change = _b[aff_mean]/`avg_dv_l'
		display "`perc_change'"
		
	}

	local numbers "& (1) & (2) & (3) & (4) & (5) & (6) \\ \hline"
	
		esttab ind_aff_mean_L sh_aff_mean_L sh_mz_aff_mean_L ind_aff_mean_U sh_aff_mean_U sh_mz_aff_mean_U ///
		using "$path/output/aff_metric_het_listed.tex", f drop(_cons) label alignment(c c c c c c) booktabs b(3) se(3) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") ///
		mgroups("Listed" "Unlisted", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nodepvar ///
		mtitle("\specialcell{Any CSR\\Spending}" "\specialcell{CSR Share\\Unconditional}" "\specialcell{CSR Share\\Conditional}" ///
		"\specialcell{Any CSR\\Spending}" "\specialcell{CSR Share\\Unconditional}" "\specialcell{CSR Share\\Conditional}") nonumbers ///
		rename(aff_mean "Proximity") collabels(none) star(* 0.10 ** 0.05 *** 0.01) title(Regression table\label{tab1}) posthead("`numbers'") /// 
		stats(avg_dv firm_FE cluster_FE r2 firms_N cluster_N N, fmt(%9.3fc %9.2fc %9.2fc %9.2fc %9.0fc %9.0fc %9.0fc) layout(	///
		"\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"  "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"  "\multicolumn{1}{c}{@}"  "\multicolumn{1}{c}{@}" 	///
		"\multicolumn{1}{c}{@}") labels(`"Avg dep var"' `"Firm FE"' `"Topic FE"' `"R-squared"' `"Unique firms"' `"Unique topics"' `"Observations"' )) replace
		

		
	
*********************************************************************************		
* 5. Regressions on affinity metric - decile seize 
* How the proximity of the production function affects the spending behaviour of the firm 
* Heterogeneity based on the firm's income size
* Code's Architecture: The user can adjust the local command below and readjust the baseline year to 2015,2016,2017
*********************************************************************************		

// local command: define year baseline
local baseline_year 2017
use "$path/data/mca_prowess_firm_cluster_hetero_toy_final.dta", clear		

	preserve 
		use "$path/data/mca_prowess_firm_year_refined.dta", clear
		keep mca_cin mca_year pro_fin_total_income_re project_ind aff_mean
		egen distinct_cin = tag(mca_cin mca_year) 
		collapse (count) num_distinct_cin = distinct_cin, by(mca_year) 
		list mca_year num_distinct_cin
	restore

	
	preserve 
		use "$path/data/mca_prowess_firm_year_refined.dta", clear
		keep mca_cin mca_year pro_fin_total_income_re project_ind aff_mean
		sort mca_cin mca_year project_ind
		br mca_year mca_cin pro_fin_total_income_re project_ind aff*
		// Check the mcin year for each firm
		gen mca_year_min = .
		bysort mca_year_min mca_cin (mca_year): replace mca_year_min = mca_year if _n == 1
		tab mca_year_min
		keep mca_year mca_year_min mca_cin pro_fin_total_income_re
		distinct mca_cin
		keep if mca_year_min != . 
		distinct mca_cin
	restore
		
	preserve 
		use "$path/data/mca_prowess_firm_year_refined.dta", clear
		keep mca_cin mca_year pro_fin_total_income_re project_ind aff_mean
		sort mca_cin mca_year project_ind
		distinct mca_cin // 7063
		keep if mca_year == `baseline_year'
		distinct mca_cin // 5331
		drop if missing(pro_fin_total_income_re) // 531 observations deleted
		// 2,263 firms do not appear in `baseline_year' or have missing(pro_fin_total_income_re) in `baseline_year'
		duplicates list mca_cin mca_year
		sum pro_fin_total_income_re, d
		tempfile baseline
		save`baseline'
	restore
	
	merge m:1 mca_cin using `baseline', gen(m_baseline)
	
	// assign deciles of size to each firm for the baseline size (`baseline_year')
	xtile CIN_size_`baseline_year' = pro_fin_total_income_re, n(10)
	sort CIN_size_`baseline_year' mca_cin

	sort mca_cin mca_year
	br mca_cin CIN_size_`baseline_year' mca_csr_proj_cluster_repl pro_fin_total_income_re mca_csr_proj_spent_re_sh aff_mean
	distinct mca_cin // 6807
	distinct mca_cin if m_baseline==3 //  4566
	distinct mca_cin if m_baseline==1 // I lose 2007 out of 6807 firms -> they do not appear in `baseline_year' or they have missing(pro_fin_total_income_re) in `baseline_year'
	distinct mca_cin if m_baseline==2 // 234 - this is plausible since the intermediary codes could have dropped those firms for some reason
	
	// check how percentiles work - they work properly
	preserve
		drop if m_baseline== 1
		sort CIN_size_`baseline_year' pro_fin_total_income_re
		sum pro_fin_total_income_re, d
		br mca_cin CIN_size_`baseline_year' pro_fin_total_income_re mca_csr_proj_cluster_repl mca_csr_proj_spent_re_sh aff_mean
	restore
	
	keep if m_baseline==3


	// Regression: Deciles based on `baseline_year' size for mca_csr_proj_spent_re_sh
			foreach decile in 1 2 3 4 5 6 7 8 9 10 {
		eststo est_`decile': reghdfe mca_csr_proj_spent_re_sh aff_mean if CIN_size_`baseline_year' == `decile', absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	}

	coefplot (est_1, keep(aff_mean) rename(aff_mean = "1") lcolor(midblue) mcolor(navy) msymbol(dot) label("Fintech") ciopts(recast(rcap) color(navy))) ///
			 (est_2, keep(aff_mean) rename(aff_mean = "2") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_3, keep(aff_mean) rename(aff_mean = "3") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_4, keep(aff_mean) rename(aff_mean = "4") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_5, keep(aff_mean) rename(aff_mean = "5") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_6, keep(aff_mean) rename(aff_mean = "6") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_7, keep(aff_mean) rename(aff_mean = "7") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_8, keep(aff_mean) rename(aff_mean = "8") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_9, keep(aff_mean) rename(aff_mean = "9") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_10, keep(aff_mean) rename(aff_mean = "10") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))), ///
			 vertical omitted baselevels yline(0, lpattern(dash) lcolor(gs10)) levels(95) ///
			 graphregion(fcolor(white)) ///
			 ytitle("Coefficient", size(medium) height(+5)) ///
			 ylabel(-0.05(0.02)0.07, labsize(medium)) ///
			 yscale(range(-0.025 0.035)) ///
			 xlabel(, labsize(medium)) legend(off)
			 graph export "$path/output/decile_share_`baseline_year'.png", as(png) replace

			 
	// Regression: Deciles based on `baseline_year' size for mca_csr_proj_spent_re_ind
			foreach decile in 1 2 3 4 5 6 7 8 9 10 {
		eststo est_`decile': reghdfe mca_csr_proj_spent_re_ind aff_mean if CIN_size_`baseline_year' == `decile', absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	}

	coefplot (est_1, keep(aff_mean) rename(aff_mean = "1") lcolor(midblue) mcolor(navy) msymbol(dot) label("Fintech") ciopts(recast(rcap) color(navy))) ///
			 (est_2, keep(aff_mean) rename(aff_mean = "2") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_3, keep(aff_mean) rename(aff_mean = "3") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_4, keep(aff_mean) rename(aff_mean = "4") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_5, keep(aff_mean) rename(aff_mean = "5") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_6, keep(aff_mean) rename(aff_mean = "6") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_7, keep(aff_mean) rename(aff_mean = "7") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_8, keep(aff_mean) rename(aff_mean = "8") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_9, keep(aff_mean) rename(aff_mean = "9") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_10, keep(aff_mean) rename(aff_mean = "10") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))), ///
			 vertical omitted baselevels yline(0, lpattern(dash) lcolor(gs10)) levels(95) ///
			 graphregion(fcolor(white)) ///
			 ytitle("Coefficient", size(medium) height(+5)) ///
			 ylabel(-0.05(0.04)0.15, labsize(medium)) ///
			 yscale(range(-0.025 0.035)) ///
			 xlabel(, labsize(medium)) legend(off)
			 
			 graph export "$path/output/decile_ind_`baseline_year'.png", as(png) replace

			 

	// Regression: Deciles based on `baseline_year' size for mca_csr_proj_spent_re_sh_mz
			foreach decile in 1 2 3 4 5 6 7 8 9 10 {
		eststo est_`decile': reghdfe mca_csr_proj_spent_re_sh_mz aff_mean if CIN_size_`baseline_year' == `decile', absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	}

	coefplot (est_1, keep(aff_mean) rename(aff_mean = "1") lcolor(midblue) mcolor(navy) msymbol(dot) label("Fintech") ciopts(recast(rcap) color(navy))) ///
			 (est_2, keep(aff_mean) rename(aff_mean = "2") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_3, keep(aff_mean) rename(aff_mean = "3") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_4, keep(aff_mean) rename(aff_mean = "4") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_5, keep(aff_mean) rename(aff_mean = "5") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_6, keep(aff_mean) rename(aff_mean = "6") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_7, keep(aff_mean) rename(aff_mean = "7") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_8, keep(aff_mean) rename(aff_mean = "8") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_9, keep(aff_mean) rename(aff_mean = "9") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))) ///
			 (est_10, keep(aff_mean) rename(aff_mean = "10") lcolor(midblue) mcolor(navy) msymbol(dot) ciopts(recast(rcap) color(navy))), ///
			 vertical omitted baselevels yline(0, lpattern(dash) lcolor(gs10)) levels(95) ///
			 graphregion(fcolor(white)) ///
			 ytitle("Coefficient", size(medium) height(+5)) ///
			 ylabel(-0.2(0.05)0.2, labsize(medium)) ///
			 yscale(range(-0.025 0.035)) ///
			 xlabel(, labsize(medium)) legend(off)
			 
			 graph export "$path/output/decile_mz_`baseline_year'.png", as(png) replace

		
	// Baseline regression (redundant)
	reghdfe mca_csr_proj_spent_re_sh aff_mean, absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster
	
	// Store baseline coefficient and confidence interval for plots
	scalar baseline_coef = _b[aff_mean]
	scalar baseline_ci_lower = _b[aff_mean] - 1.96 * _se[aff_mean]
	scalar baseline_ci_upper = _b[aff_mean] + 1.96 * _se[aff_mean]
	gen baseline_coef_var = scalar(baseline_coef)
	gen baseline_ci_lower_var = scalar(baseline_ci_lower)
	gen baseline_ci_upper_var = scalar(baseline_ci_upper)

	// Decile Regressions
	gen decile = .
	gen coef = .
	gen ci_lower = .
	gen ci_upper = .
	local i = 1
	
	
	foreach dum in 1 2 3 4 5 6 7 8 9 10 {
		// Run regression for the specific decile
		reghdfe mca_csr_proj_spent_re_sh aff_mean if CIN_size_2017 == `dum', absorb(mca_csr_proj_cluster_repl mca_cin) $se_cluster

		// Store results in the decile rows
		replace decile = `i' in `i'
		replace coef = _b[aff_mean] in `i'
		replace ci_lower = _b[aff_mean] - 1.96*_se[aff_mean] in `i'
		replace ci_upper = _b[aff_mean] + 1.96*_se[aff_mean] in `i'
		
		local i = `i' + 1
	}

	// use the command coefplot 
	twoway ///
		(rarea ci_lower ci_upper decile, color(blue%20)) /// Confidence band for deciles
		(line coef decile, lcolor(blue) lwidth(medium) lpattern(solid) mcolor(blue) msymbol(o)) /// Decile line
		(rarea baseline_ci_lower baseline_ci_upper decile, color(red%20) lpattern(solid)) /// Confidence band for baseline
		(line baseline_coef decile, lcolor(red) lwidth(medium) lpattern(dash)) /// Baseline line
		, ///
		ytitle("Firm β₁") ///
		xtitle("Size decile") ///
		legend(order(1 "Decile CI" 2 "Decile β₁" 3 "Baseline CI" 4 "Baseline β₁")) ///
		xlabel(1(1)10) ///
		scheme(s2color)
		graph export "$path/output/regression_`baseline_year'.png", as(png) replace



	
*********************************************************************************		
* 6. Histogram
* 
*********************************************************************************					
	preserve 
		sort pro_nic_2dig_2008_md aff_mean
		//br if pro_nic_2dig_2008_lab == "Manufacture of chemicals and chemical products"
		sum aff_mean if mca_csr_proj_cluster_repl == "vocational skills" & pro_nic_2dig_2008_lab == "medical and botanical (manuf)"
		local ex_mean = `r(mean)'
		sum aff_mean if mca_csr_proj_cluster_repl == "hunger and malnutrition" & pro_nic_2dig_2008_lab == "medical and botanical (manuf)"
		local ex_1sd_up = `r(mean)'
		sum aff_mean if mca_csr_proj_cluster_repl == "health" & pro_nic_2dig_2008_lab == "medical and botanical (manuf)"
		local ex_1sd_down = `r(mean)'
		
		local ex_mean_f : display %4.2f `ex_mean'
		local ex_1sd_up_f : display %4.2f `ex_1sd_up'
		local ex_1sd_down_f : display %4.2f `ex_1sd_down'
		
		local dark_gray gs4
		local med_gray gs7
		local light_gray gs10
		graph_options, graph_margin(l=-2 r=-2 b=-4 t=4) xlabel_options(labsize(vlarge)  format(%9.0fc) labgap(*0.02)) ylabel_options(labsize(vlarge) ///
		grid glcolor(ltblue*0.4)) xtitle_options(size(vlarge) color(black) height(+8)) ytitle_options(size(vlarge) color(black)) ///
		marker_options(msize(medsmall) mcolor(`dark_gray')) 

		summarize aff_mean
		local m=r(mean)
		local sd=r(sd)
		local m_f : display %4.2f `m'
		local sd_f : display %4.2f `sd'
		local textloc = `m'+0.1
		
		twoway (hist aff_mean, fraction xtitle("Proximity", size(medium) height(+6)) ytitle("Fraction", size(medium) height(+4)) color(ltblue*1.2) width(0.1)) ///
		, ///
		ylabel(0(0.02)0.07, labsize(medium) format(%9.2fc)) ///
		xlabel(-2(1)5, labsize(medium) format(%9.0fc)) xscale(range(-3(1)5)) `graphregion' `plotregion' legend(off)  
		graph export "$path/output/aff_metric_hist_without.png", replace
		
		twoway (hist aff_mean, fraction xtitle("Proximity", size(medium) height(+6)) ytitle("Fraction", size(medium) height(+4)) color(ltblue*1.2) width(0.1)) ///
		(scatteri 0.0 -1.33 0.0 -0.49 0.0 0.88 , mlabsize(medsmall) mlabcolor(black) color(navy)), ///
		ylabel(0(0.02)0.07, labsize(medium) format(%9.2fc)) ///
		xlabel(-2(1)5, labsize(medium) format(%9.0fc)) xscale(range(-3(1)5)) `graphregion' `plotregion' legend(off)    ///
		text(0.006 1.2 "medical x" "health" 0.006 -0.15 "medical x" "hunger" 0.006 -1.33 "medical x" "vocational", justification(left))
		graph export "$path/output/aff_metric_hist_with.png", replace
		
	restore 	 
	
	
	
*********************************************************************************		
* 7. Heatplot
* Industry's proximity to a social-topic
*********************************************************************************			
	// get rank of industries by overall amount spent 
	preserve 
	collapse (sum) mca_csr_proj_spent_re_su, by(pro_nic_2dig_2008_lab) // main csr spending variable: mca_csr_proj_spent_re_su
	drop if pro_nic_2dig_2008_lab == ""
	egen mca_csr_proj_spent_re_su_tot = total(mca_csr_proj_spent_re_su) // why is this not same as aggregate?
	gen mca_csr_proj_spent_re_su_perc = (mca_csr_proj_spent_re_su/mca_csr_proj_spent_re_su_tot)
	gsort -mca_csr_proj_spent_re_su_perc
	gen rank = _n
	keep pro_nic_2dig_2008_lab rank
	tempfile temp
	save `temp'
	restore
	
	gen order = _n
	merge m:1 pro_nic_2dig_2008_lab using `temp'
	sort rank
	br pro_nic_2dig_2008_lab rank
	tab pro_nic_2dig_2008_lab if rank < 21
	
	gen pro_nic_2dig_2008_lab_substr = subinstr(pro_nic_2dig_2008_lab, " (services)","",.)
	replace pro_nic_2dig_2008_lab_substr = subinstr(pro_nic_2dig_2008_lab_substr, " (manuf)","",.)
	replace pro_nic_2dig_2008_lab_substr =  "crude petroleum and natural gas" if pro_nic_2dig_2008_lab_substr == "crude petroleum and natural gas extraction"
	replace pro_nic_2dig_2008_lab_substr =  "electricity, gas, etc" if pro_nic_2dig_2008_lab_substr == "electricity, gas, steam and aircondition"
	replace pro_nic_2dig_2008_lab_substr =  "fabricated material" if pro_nic_2dig_2008_lab_substr == "manufacture of fabricated metal"
	replace pro_nic_2dig_2008_lab_substr =  "crude petroleum, natural gas" if pro_nic_2dig_2008_lab_substr == "crude petroleum and natural gas"
	replace pro_nic_2dig_2008_lab_substr =  "rubber and plastic products" if pro_nic_2dig_2008_lab_substr == "manufacture of rubber and plastics products"
	
	// this variable is standardized now 
	rename aff_mean Proximity
	sum Proximity, d

	 
	preserve 
		// regresses on topic and industry
		// ares: first collapses the proximity by industry before residual 
		// it doesn't make a difference but keep the firm fixed effects
		egen mca_cin_enc = group(mca_cin)
		reghdfe Proximity i.mca_csr_proj_cluster_repl_enc, absorb(mca_cin) resid
		predict aff_mean_res, resid
		sum aff_mean_res
		
		capture: drop ind_nr_2
		capture: label drop ind_2 
		capture: drop topic_nr_2
		capture: label drop topic_2
		gen ind_nr_2 = 1 if pro_nic_2dig_2008_lab_substr =="medical and botanical"
		replace ind_nr_2 = 2 if pro_nic_2dig_2008_lab_substr == "coal and lignite mining" 
		replace ind_nr_2 = 3 if pro_nic_2dig_2008_lab_substr == "civil engineering" 
		replace ind_nr_2 = 4 if pro_nic_2dig_2008_lab_substr == "other transport equipment" 
		replace ind_nr_2 = 5 if pro_nic_2dig_2008_lab_substr == "motor vehicles" 
		replace ind_nr_2 = 6 if pro_nic_2dig_2008_lab_substr == "IT and consultancy"
		replace ind_nr_2 = 7 if pro_nic_2dig_2008_lab_substr == "information provision"
		replace ind_nr_2 = 8 if pro_nic_2dig_2008_lab_substr == "financial"
		replace ind_nr_2 = 9 if pro_nic_2dig_2008_lab_substr == "crude petroleum, natural gas" 
		replace ind_nr_2 = 10 if pro_nic_2dig_2008_lab_substr == "electricity, gas, etc" 
		replace ind_nr_2 = 11 if pro_nic_2dig_2008_lab_substr == "chemicals"
		replace ind_nr_2 = 12 if pro_nic_2dig_2008_lab_substr == "coke and refined petroleum"
		replace ind_nr_2 = 13 if pro_nic_2dig_2008_lab_substr == "machinery and equipment"
		replace ind_nr_2 = 14 if pro_nic_2dig_2008_lab_substr == "basic metals"
		replace ind_nr_2 = 15 if pro_nic_2dig_2008_lab_substr == "non-metallic minerals" 
		replace ind_nr_2 = 16 if pro_nic_2dig_2008_lab_substr ==  "wholesale trade" 

		
		label define ind_2 1 "medical and botanical"  2 "coal and lignite mining" ///
			3 "civil engineering"  4 "other transport equipment"  ///
			5 "motor vehicles" 6 "IT and consultancy"  7 "information provision" 8 "financial" /// 
			9 "crude petroleum, natural gas" ///
			10 "electricity, gas, etc" 11 "chemicals" 12 "coke and refined petroleum" 13  "machinery and equipment" 14 "basic metals" ///
			15 "non-metallic minerals"  16 "wholesale trade"  
			
		label values ind_nr_2 ind_2
		
		gen topic_nr_2 = 1 if mca_csr_proj_cluster_repl == "health"
		replace topic_nr_2 = 2 if mca_csr_proj_cluster_repl == "animal welfare"
		replace topic_nr_2 = 3 if mca_csr_proj_cluster_repl == "agroforestry"
		replace topic_nr_2 = 4 if mca_csr_proj_cluster_repl == "environmental sustainability"
		replace topic_nr_2 = 5 if mca_csr_proj_cluster_repl == "sanitation"
		replace topic_nr_2 = 6 if mca_csr_proj_cluster_repl == "infrastructure"
		replace topic_nr_2 = 7 if mca_csr_proj_cluster_repl == "sports"
		replace topic_nr_2 = 8 if mca_csr_proj_cluster_repl == "vocational skills"
		replace topic_nr_2 = 9 if mca_csr_proj_cluster_repl == "technology incubators"
		replace topic_nr_2 = 10 if mca_csr_proj_cluster_repl ==  "education"
		replace topic_nr_2 = 11 if mca_csr_proj_cluster_repl ==  "women empowerment"
		replace topic_nr_2 = 12 if mca_csr_proj_cluster_repl == "livelihood enhancement"
		replace topic_nr_2 = 13 if mca_csr_proj_cluster_repl == "vulnerable populations"
		replace topic_nr_2 = 14 if mca_csr_proj_cluster_repl == "emergency relief"
		replace topic_nr_2 = 15 if mca_csr_proj_cluster_repl == "safe drinking water"
		replace topic_nr_2 = 16 if mca_csr_proj_cluster_repl == "hunger and malnutrition"
		label define topic_2   1 "health" 2 "animal welfare" 3 "agroforestry" 4 "environmental sustainability" 5 "sanitation" ///
			6 "infrastructure"  7 "sports" 8 "vocational skills" 9 "technology incubators" 10 "education"  11 "women empowerment" ///
				12 "livelihood enhancement"  13 "vulnerable populations"  14 "emergency relief"    15 "safe drinking water"  16  "hunger and malnutrition"
		label values topic_nr_2 topic_2
		
		lab var aff_mean_res "Proximity"
		drop Proximity
		rename aff_mean_res Proximity
		
		heatplot Proximity i.topic_nr_2 i.ind_nr_2 if rank <= 16, xlabel(,angle(60) labsize(small)) ylabel(, labsize(small)) ytitle("") xtitle("") ///
			cuts(-1 -0.5 0 0.5 1) keylabels(, interval size(small) label(1 "") nobox region(lstyle(none)) format(%9.2fc)) colors(gray%30 gray%80 ltblue%90 navy%80 navy) 
	    graph export "$path/output/aff_metric_heatplot_wFE.png", replace
	restore 
	
	
*********************************************************************************		
* 8. Maps for district
* District level spending and value-added per industry
*********************************************************************************			
	
	use  "$path/data/maps.dta", clear
	
	// where do firms "create" money per 1 million?
	// mca_csr_proj_spent_re_off is in million (?)
	gen mca_csr_proj_spent_re_off_pm = mca_csr_proj_spent_re_off/TOT_P_adj
	format mca_csr_proj_spent_re_off_pm %9.0f
	sum mca_csr_proj_spent_re_off_pm, d
	spmap mca_csr_proj_spent_re_off_pm using "$path/data/india_map_2011_coord.dta", id(id) fcolor(Blues) ndfcolor(gray) clmethod(custom) clbreaks(0 5 10 100 5000) ///
	legend(title("CSR money created" "per 1 m people (m rupees)", size(medium)) size(small) position(1))
	graph export "$path/output/map_csr_spending_loc_created_dist.png", replace 

	// where do firms "spend" money per 1 million? 
	// mca_csr_proj_spent_re_plo is in million 
	gen mca_csr_proj_spent_re_plo_pm = mca_csr_proj_spent_re_plo/TOT_P_adj
	format mca_csr_proj_spent_re_plo_pm %9.0f
	sum mca_csr_proj_spent_re_plo_pm, d
	spmap mca_csr_proj_spent_re_plo_pm using "$path/data/india_map_2011_coord.dta", id(id) fcolor(Blues) ndfcolor(gray) clmethod(custom) clbreaks(0 5 10 100 5000) /// 
	legend(title("CSR money spent" "per 1 m people (m rupees)", size(medium)) size(small) position(2))
	graph export "$path/output/map_csr_spending_loc_spent_dist.png", replace 
	



	


