* PREAMBLE

clear all
cls
// unicode encoding set UTF-16
// unicode translate "Colombia LAPOP AmericasBarometer 2018 v1.0_W.dta", invalid
use "/Users/upar/Dropbox/00-SCHOOL/0-University/1-Research/twitter_bites/poverty_and_religion/Data/0-InputData/raw_data/Colombia LAPOP AmericasBarometer 2018 v1.0_W.dta", clear
ssc install ciplot

* GENERATE VARIABLES
	* AGE
	capture drop age_group
	capture gen age_group=q2
	recode age_group (1/29=1) (30/59=2) (60/90=3)
	label var age_group "Grupo de edad"
	label define lab_edad 1 "Joven (18-29)" 2 "Adulto (30-59)" 3 "Mayor (60+)"
	label values age_group lab_edad
	
	* EDUCATION
	codebook ed
	descr ed
	tab ed
	gen educ_nola = ed
	label var educ_nola "Último año de educ. completo"
	
	* RELIGION
	gen relig = q5b
	recode relig 1=4 2=3 3=2 4=1
	label var relig "Importancia de la religión"
	
	gen relig_dummy=1 if relig==3 | relig==4
	recode relig_dummy .=0
	
	* REGION
	gen region = estratopri
	label var
	

* PLOTS
	set scheme s1color
	ciplot relig, by(colestsoc_col) scheme(s1color) aspect(1) ///
		xlab(, ang(90)) name("a", replace)

	ciplot relig, by(q10g) xlab(,ang(40)) name("ing_desagregado", replace) ///
		 note("Fuente: The AmericasBarometer by the" ///
		"LAPOP Lab www.vanderbilt.edu/lapop . " "Realización propia.") 
		
	twoway (lfitci relig q10g, ciplot(rcap)) ///
		(qfitci relig q10g, ciplot(rcap)),  name("lfit_ing_desagregado", replace)	
		
	ciplot relig, by(estratopri) scheme(s1color) aspect(1) ///
		xlab(, ang(35)) name("reg", replace) title("") ///
		note("Fuente: The AmericasBarometer by the" ///
		"LAPOP Lab www.vanderbilt.edu/lapop . " "Realización propia.") ///
		title("Importancia de la" "religión por región")
	
	ciplot relig, by(educ_nola) scheme(s1color) aspect(1) ///
		xlab(, ang(0)) name("edu1", replace)
	ciplot q5br, by(edr) scheme(s1color) aspect(1) ///
		xlab(, ang(90)) name("edu2", replace)

	graph combine edu1 edu2, name("comb", replace) ///
		title("Religión y educación" "Colombia (2018)") note("Fuente: The AmericasBarometer by the LAPOP Lab,  www.vanderbilt.edu/lapop . " "Realización propia.")
		
		
	* KDENSITY
	forvalues x=1/4{
		kdensity educ_nola  if relig==`x', name("kdens_`x'", replace) bw(1)
	}
	graph twoway (kdensity educ_nola  if relig==1, bw(1)) ///
		(kdensity educ_nola  if relig==2, bw(1)) ///
		(kdensity educ_nola  if relig==3, bw(1)) ///
		(kdensity educ_nola  if relig==4, bw(1)), name("kdens_1")
	graph combine kdens_1 kdens_2 kdens_3 kdens_4 
* REGRESSION

	* MODEL 1: Income, Education, region and age group
	reg relig q10g educ_nola i.estratopri i.age_group, r
		coefplot, keep(q10g educ_nola) aspect(1) xline(0, lpattern("dash"))
		outreg2 using "~/Downloads/modelo1.doc", replace label ctitle("Modelo 1")
	
	* MODEL 2: + sex
	reg relig q10g educ_nola i.estratopri i.age_group sex, r
		outreg2 using "~/Downloads/modelo1.doc", append label ctitle("Modelo 2")
	
	* MODEL 3: + unemployd
	reg relig q10g educ_nola i.estratopri i.age_group sex colocup4a etid, r
		outreg2 using "~/Downloads/modelo1.doc", append label ctitle("Modelo 3")
	
	* MODEL 4: + urban
	reg relig q10g educ_nola i.estratopri i.age_group sex colocup4a etid ur, r
		outreg2 using "~/Downloads/modelo1.doc", append label ctitle("Modelo 4")
	
	
	  

*******************************************************************************

* With ELCA

* Test different variables for relationship by religion:
	foreach x in ing_trabajo ing_pensiones ing_arriendos ing_intereses_div ing_otros_nrem{
		di "******************* Prueba para `x' ******************* "
		ttest `x', by(religion)
	}
	
	foreach x in material_pisos material_paredes sp_energia sp_gasnatural sp_acueducto sp_alcantarillado sp_telefono{
		qui tab religion `x', row chi
		qui return list
		if `r(p)'<0.05{
			di "La variable `x'"
			tab `x' religion, row chi
		}
	}
	ciplot ing_
