********************************************************************************
// purpose: write programs to be used later
// coder: noemie
// to-do: finished  
********************************************************************************

* 1. clearing programs *********************************************************

clear programs 

* 1.1 cleaning date ------------------------------------------------------------

program define clean_date
	gen date_mod=`1'
	gen day=mod(date_mod, 100)
	replace date_mod=floor(date_mod/100)
	gen month=mod(date_mod, 100)
	replace date_mod=floor(date_mod/100)
	rename date_mod year
	gen date_ym=ym(year,month)
	format date_ym %tm
	drop day 
end

* 1.2 cleaning currencies ------------------------------------------------------ 

program define USDtoINR
	local i = 1
	while "``i''" != "" {
	replace ``i''=``i''*USDINR_implied
	local ++i
	}
end

* 1.3 winsorizing -------------------------------------------------------------- 

program define winsor0_top1
   _pctile `1' if `1'!=0, percentiles(99)
   local p=r(r1)
   gen `1'_w0099=`1'
   replace `1'_w0099=`p' if `1'>`p' & `1'!=. &  `1'!=0
end
program define winsor0_top1bot1
   _pctile `1' if `1'!=0, percentiles(99)
   local p=r(r1)
   gen `1'_w0199=`1'
   replace `1'_w0199 =`p' if `1'>`p' & `1'!=. &  `1'!=0
   _pctile `1' if `1'!=0, percentiles(1) 
   local p=r(r1)
   replace `1'_w0199 =`p' if `1'<`p' & `1'!=. &  `1'!=0  
end
program define winsor0_top2
   _pctile `1' if `1'!=0, percentiles(98)
   local p=r(r1)
   gen `1'_w0098=`1'
   replace `1'_w0098=`p' if `1'>`p' & `1'!=. &  `1'!=0
end
program define winsor0_top2bot2
   _pctile `1' if `1'!=0, percentiles(98)
   local p=r(r1)
   gen `1'_w0298=`1'
   replace `1'_w0298 =`p' if `1'>`p' & `1'!=. &  `1'!=0
   _pctile `1' if `1'!=0, percentiles(2) 
   local p=r(r1)
   replace `1'_w0298 =`p' if `1'<`p' & `1'!=. &  `1'!=0  
end

* 1.4 clean company name ------------------------------------------------------- 

program define clean_company_name 
	gen `1'_mod = `1'
	replace `1'_mod = upper(`1'_mod)
	replace `1'_mod = subinstr(`1'_mod,  "LIMITED","LTD", .)
	replace `1'_mod = subinstr(`1'_mod,  "PRIVATE","PVT", .)
	replace `1'_mod = subinstr(`1'_mod,  "INDUSTRIES","INDS.", .)
	replace `1'_mod = subinstr(`1'_mod,  "COMPANY","CO.", .)
	replace `1'_mod = subinstr(`1'_mod,  "MANAGEMENT", "MGMT.", .)
	replace `1'_mod = subinstr(`1'_mod,  "INVESMENT","INVST.", .)
	replace `1'_mod = subinstr(`1'_mod,  "INVESMENTS","INVSTS.", .)
	replace `1'_mod = subinstr(`1'_mod,  "CORPORATION","CORPN.", .)
	replace `1'_mod = subinstr(`1'_mod,  "INTERNATIONAL","INTL.", .)
	replace `1'_mod = subinstr(`1'_mod,  "ORGANISATION","ORGN.",  .)
	replace `1'_mod = subinstr(`1'_mod,  "ENGINEERING","ENGG.", .)
	replace `1'_mod = subinstr(`1'_mod,  "DEVELOPMENT","DEVP.", .)
	replace `1'_mod = subinstr(`1'_mod,  "GOVERNMENT","GOVT", .)
	replace `1'_mod = subinstr(`1'_mod, ".", "", .)
	replace `1'_mod = subinstr(`1'_mod, ",", "", .)
	replace `1'_mod = subinstr(`1'_mod, "(", "", .)
	replace `1'_mod = subinstr(`1'_mod, ")", "", .)
	replace `1'_mod = subinstr(`1'_mod, "&", "AND", .)
	replace `1'_mod = subinstr(`1'_mod, "-", "", .)
	replace `1'_mod = subinstr(`1'_mod, "'", "", .)
	replace `1'_mod = subinstr(`1'_mod, " ", "", .)
	replace `1'_mod = subinstr(`1'_mod, "/", "", .)
	replace `1'_mod = subinstr(`1'_mod, "\", "", .)
	replace `1'_mod=subinstr(`1'_mod,"AND","",.)
	replace `1'_mod=subinstr(`1'_mod,"[MERGED]","",.)
end

* 1.5 create and clean state codes ---------------------------------------------

program define create_state_codes
	gen state_code2=.
	replace state_code2=1 if state_name=="Andhra Pradesh"
	replace state_code2=2 if state_name=="Assam"
	replace state_code2=3 if state_name=="Bihar"
	replace state_code2=4 if state_name=="Gujarat"
	replace state_code2=5 if state_name=="Haryana"
	replace state_code2=6 if state_name=="Himachal Pradesh"
	replace state_code2=7 if state_name=="Jammu and Kashmir"
	replace state_code2=8 if state_name=="Karnataka"
	replace state_code2=9 if state_name=="Kerala"
	replace state_code2=10 if state_name=="Madhya Pradesh"
	replace state_code2=11 if state_name=="Maharashtra"
	replace state_code2=12 if state_name=="Manipur"
	replace state_code2=13 if state_name=="Meghalaya"
	replace state_code2=14 if state_name=="Nagaland"
	replace state_code2=15 if state_name=="Odisha"
	replace state_code2=16 if state_name=="Punjab"
	replace state_code2=17 if state_name=="Rajasthan"
	replace state_code2=18 if state_name=="Tamil Nadu"
	replace state_code2=19 if state_name=="Tripura"
	replace state_code2=20 if state_name=="Uttar Pradesh"
	replace state_code2=21 if state_name=="West Bengal"
	replace state_code2=22 if state_name=="Sikkim"
	replace state_code2=23 if state_name=="Arunachal Pradesh"
	replace state_code2=24 if state_name=="Goa"
	replace state_code2=25 if state_name=="Uttarakhand"
	replace state_code2=26 if state_name=="Chhattisgarh"
	replace state_code2=27 if state_name=="Jharkhand"
	replace state_code2=52 if state_name=="Andaman and Nicobar Islands"
	replace state_code2=53 if state_name=="Chandigarh"
	replace state_code2=54 if state_name=="Dadra & Nagar Haveli Daman & Diu"
	replace state_code2=55 if state_name=="Delhi"
	replace state_code2=57 if state_name=="Lakshadweep"
	replace state_code2=58 if state_name=="Mizoram"
	replace state_code2=59 if state_name=="Puducherry"
	replace state_code2=62 if state_name=="Telangana"
end

program define clean_state_code
	gen state_code2=state_code
	replace state_code2=18 if state_code2==61 // Coimbatore is in Tamil Nadu
	replace state_code2=11 if state_code2==60 // Pune is in Maharastra
	replace state_code2=54 if state_code2==56 // 54 - Dadra & Nagar Haveli and 56 - Daman & Diu are a single state
	gen state_name=""
	replace state_name="Andhra Pradesh" if state_code2==1
	replace state_name="Assam" if state_code2==2
	replace state_name="Bihar" if state_code2==3
	replace state_name="Gujarat" if state_code2==4
	replace state_name="Haryana" if state_code2==5
	replace state_name="Himachal Pradesh" if state_code2==6
	replace state_name="Jammu and Kashmir" if state_code2==7
	replace state_name="Karnataka" if state_code2==8
	replace state_name="Kerala" if state_code2==9
	replace state_name="Madhya Pradesh" if state_code2==10
	replace state_name="Maharashtra" if state_code2==11
	replace state_name="Manipur" if state_code2==12
	replace state_name="Meghalaya" if state_code2==13
	replace state_name="Nagaland" if state_code2==14
	replace state_name="Odisha" if state_code2==15
	replace state_name="Punjab" if state_code2==16
	replace state_name="Rajasthan" if state_code2==17
	replace state_name="Tamil Nadu" if state_code2==18
	replace state_name="Tripura" if state_code2==19
	replace state_name="Uttar Pradesh" if state_code2==20
	replace state_name="West Bengal" if state_code2==21
	replace state_name="Sikkim" if state_code2==22
	replace state_name="Arunachal Pradesh" if state_code2==23
	replace state_name="Goa" if state_code2==24
	replace state_name="Uttarakhand" if state_code2==25
	replace state_name="Chhattisgarh" if state_code2==26
	replace state_name="Jharkhand" if state_code2==27
	replace state_name="Andaman and Nicobar Islands" if state_code2==52
	replace state_name="Chandigarh" if state_code2==53
	replace state_name="Dadra & Nagar Haveli Daman & Diu" if state_code2==54
	replace state_name="Delhi" if state_code2==55
	replace state_name="Lakshadweep" if state_code2==57
	replace state_name="Mizoram" if state_code2==58
	replace state_name="Puducherry" if state_code2==59
	replace state_name="Telangana" if state_code2==62
end

* 1.6 clean nic codes ----------------------------------------------------------

program define clean_nic_prod_code

	// there are two variables, nic_prod_code and test_length_str (imported as string)
	tostring nic_prod_code, replace	
	gen test_length_num = length(nic_prod_code)
	gen test_length_str = length(nic_prod_code_str)

	tab nic_prod_code_str if test_length_str == 2

	preserve 
	keep if test_length_str == 2
	collapse (first)  nic_name, by(nic_prod_code_str)
	tab nic_name nic_prod_code_str
	restore 

	replace nic_prod_code_str= "" if nic_prod_code_str == "34"
	replace nic_prod_code_str = nic_prod_code_str + "xxx" if test_length_str == 2 & nic_prod_code_str != ""

	replace nic_prod_code_str = "089xx" if nic_prod_code_str == "089"
	replace nic_prod_code_str= nic_prod_code_str+"xx" if test_length_str == 3 & nic_prod_code_str != "089xx" 
	replace nic_prod_code_str=  nic_prod_code_str+"x" if inlist(nic_prod_code_str,"0510","0520","0610","0620","0810")  // these now belong to string length 4

	preserve 
		keep if test_length_str == 4
		collapse (first)  nic_name, by(nic_prod_code_str)
		tab nic_name nic_prod_code_str
	restore 

	replace nic_prod_code_str = nic_prod_code_str + "x" if test_length_str == 4 & !inlist(nic_prod_code_str,"0510x","0520x","0610x","0620x","0810x")

	gen test_length_str_final = length(nic_prod_code_str)
	tab test_length_str_final
	drop nic_prod_code 

	gen nic2008_2digit = substr(nic_prod_code_str, 1, 2)
	gen nic2008_3digit = substr(nic_prod_code_str, 1, 3)

	destring nic2008_2digit, replace 
	rename nic_prod_code_str nic_prod_code

	#delimit ;
	label define nic2digit 1 "Crop and animal production, hunting and related service activities"
	2 "Forestry and logging"
	3 "Fishing and aquaculture"
	5 "Mining of coal and lignite"
	6 "Extraction of crude petroleum and natural gas"
	7 "Mining of metal ores"
	8 "Other Mining and quarrying"
	9 "Mining support service activities"
	10 "Manufacture of food products"
	11 "Manufacture of beverages"
	12 "Manufacture of tobacco products"
	13 "Manufacture of textiles"
	14 "Manufacture of wearing apparel"
	15 "Manufacture of leather and related products"
	16 "Manufacture ofwoodand ofproducts ofwoodand cork, except furniture; manufacture of articles of straw and plaiting materials"
	17 "Manufacture of paper and paper products"
	18 "Printing and reproduction of recorded media (This division excludes publishing activities, see section J for publishing activities"
	19 "Manufacture of coke and refined petroleum products"
	20 "Manufacture of chemicals and chemical products"
	21 "Manufacture of pharmaceuticals, medicinal chemical and botanical products"
	22 "Manufacture of rubber and plastics products"
	23 "Manufacture of other non-metallic mineral products"
	24 "Manufacture of Basic Metals"
	25 "Manufacture of fabricated metal"
	26 "Manufacture of computer, electronic and optical products."
	27 "Manufacture of electrical equipment"
	28 "Manufacture of machinery and equipment n.e.c."
	29 "Manufacture of motor vehicles, trailers and semi-trailers"
	30 "Manufacture of other transport equipment"
	31 "Manufacture of furniture"
	32 "Other manufacturing"
	33 "Repair and installation of machinery and equipment"
	34 "Diverse"
	35 "Electricity, Gas, Steam and Aircondition Supply"
	36 "Water collection , treatment and supply"
	37 "Sewerage"
	38 "Waste collection, treatment and disposal activities materials recovery"
	39 "Remediation activities and other waste management services"
	41 "Construction of buildings"
	42 "Civil engineering"
	43 "Specialized construction activities"
	45 "Wholesale and retail trade and repair of motor vehicles and motorcycles"
	46 "Wholesale trade, except of motor vehiclesand motorcycles"
	47 "Retail trade, except of motor vehicles and motorcycles"
	49 "Land transport and transport via pipelines"
	50 "Water transport"
	51 "Air transport"
	52 "Warehousing and support activities for transportation"
	53 "Postal and courier activities"
	55 "Accommodation"
	56 "Food and beverage service activities"
	58 "Publishing activities"
	59 "Motion picture, video and television programme production, sound recording and music publishing activities."
	60 "Programming and broadcasting activities"
	61 "Telecommunications"
	62 "Computer programming, consultancy and related activities"
	63 "Information service activities"
	64 "Financial service activities, except insurance and Pension funding"
	65 "Insurance, reinsurance and pension funding, except compulsory social security"
	66 "Other financial activities"
	68 "Real estate activities"
	69 "Legal and accounting activities"
	70 "Activities of head offices; management consultancyactivities"
	71 "Architecture and engineering activities; technical testing and analysis"
	72 "Scientific research and development"
	73 "Advertising and market research"
	74 "Other professional, scientific and technical activities"
	75 "Veterinary activities"
	77 "Rental and leasing activities"
	78 "Employment activities"
	79 "Travel agency, tour operator and other reservation service activities"
	80 "Security and investigation activities"
	81 "Services to buildings and landscape activities"
	82 "Office administrative, office support and other business support activities"
	84 "Public administration and defence; compulsory social security"
	85 "Education"
	86 "Human health activities"
	87 "Residential care activities"
	88 "Social work activities without accommodation"
	90 "Creative, arts and entertainment activities"
	91 "Libraries, archives, museums and other cultural activities"
	92 "Gambling and betting activities"
	93 "Sports activities and amusement and recreation activities"
	94 "Activities of membership organizations"
	95 "Repair of computers and personal and household goods"
	96 "Other personal service activities"
	97 "Activities of households as employers of domestic personnel"
	98 "Undifferentiated goods- and services-producing activities of private households for own use"
	99 "Activities of extraterritorial organizations and bodies" ;
	#delimit cr
	label values nic2008_2digit nic2digit
end

* 1.7 clean file names ---------------------------------------------------------

program define clean_filename

    // arg 1: file name with extension
    local file_name = subinstr("`1'", ".txt", "", 1)

    shell perl -pne "s/(\||^)NA(?=\||$)/\1\./g" "`file_name'.txt" > "`file_name'_nomiss.txt"  // replaces NA with .---much faster than doing this in Stata

    insheet using "`file_name'_nomiss.txt", delimiter("|") clear

end

* 1.8 homogenize_units ---------------------------------------------------------

program define homogenize_units 
		*** Homogenize units 
		*makes sure sales units don't change over time
		gen UNIT = sales_unit
		*concrete specific conversion
		replace sales_qty=sales_qty*2.41 if sales_unit=="'000 cu.metres" & product_name=="READY MIX CONCRETE"
		replace sales_unit="Tonnes" if sales_unit=="'000 cu.metres" & product_name=="READY MIX CONCRETE"

		*make units homogeneous within companies
		*change '000 tonnes = Tonnes
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 tonnes"
		replace sales_unit="Tonnes" if sales_unit=="'000 tonnes"

		// Number
		replace sales_qty=sales_qty*100 if sales_unit=="'00 nos"
		replace sales_unit="Numbers" if sales_unit=="'00 nos"

		replace sales_qty=sales_qty*1000 if sales_unit=="'000 nos"
		replace sales_unit="Numbers" if sales_unit=="'000 nos"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh nos" // Lakh lakh is a unit in the Indian numbering system equal to one hundred thousand  
		replace sales_unit="Numbers" if sales_unit=="Lakh nos"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million nos"
		replace sales_unit="Numbers" if sales_unit=="Million nos"

		// Kilo Litres
		replace sales_unit="Kls" if sales_unit=="'000 litres"

		replace sales_qty=sales_qty*1000 if sales_unit=="Litres"
		replace sales_unit="Kls" if sales_unit=="Litres"

		replace sales_qty=sales_qty/1000 if sales_unit=="'000 kls."
		replace sales_unit="Kls" if sales_unit=="'000 kls."

		replace sales_qty=sales_qty/1000 if sales_unit=="Million litres"
		replace sales_unit="Kls" if sales_unit=="Million litres"

		replace sales_unit="Kls" if sales_unit=="'000 bulk litres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="'000 milli litres"
		replace sales_unit="Kls" if sales_unit=="'000 milli litres"

		replace sales_unit="Kls" if sales_unit=="Kgs-litres"

		replace sales_qty=sales_qty/100 if sales_unit=="Lakh litres"
		replace sales_unit="Kls" if sales_unit=="Lakh litres"

		replace sales_qty=sales_qty*100000000000 if sales_unit=="Lakh milli litres"
		replace sales_unit="Kls" if sales_unit=="Lakh milli litres"

		// Tonnes
		replace sales_qty=sales_qty*1000 if sales_unit=="Kgs"
		replace sales_unit="Tonnes" if sales_unit=="Kgs"

		replace sales_qty=sales_qty*1000 if sales_unit=="Bulk kgs"
		replace sales_unit="Tonnes" if sales_unit=="Bulk kgs"

		replace sales_qty=sales_qty*100000000 if sales_unit=="Lakh kgs"
		replace sales_unit="Tonnes" if sales_unit=="Lakh kgs"
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh tonnes"
		replace sales_unit="Tonnes" if sales_unit=="Lakh tonnes"
		replace sales_qty=sales_qty*1000000 if sales_unit=="Million tonnes"
		replace sales_unit="Tonnes" if sales_unit=="Million tonnes"
		replace sales_unit="Tonnes" if sales_unit=="Tonnes-number"

		// Number
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh nos"
		replace sales_unit="Numbers" if sales_unit=="Lakh nos"

		replace sales_qty=sales_qty*1000 if sales_unit=="'000 nos"
		replace sales_unit="Numbers" if sales_unit=="'000 nos"

		*IS THIS A MISTAKE?
		*replace sales_unit="'000 nos" if sales_unit=="Tonnes-number"
		*replace sales_unit="'000 nos" if sales_unit=="'000 pieces"

		// Kwh
		replace sales_qty=sales_qty/1000 if sales_unit=="'000 kwh"
		replace sales_unit="Kwh" if sales_unit=="'000 kwh"

		replace sales_unit="Kwh" if sales_unit=="Kw"

		replace sales_qty=sales_qty/100000 if sales_unit=="Lakh kwh"
		replace sales_unit="Kwh" if sales_unit=="Lakh kwh"

		replace sales_qty=sales_qty/1000000 if sales_unit=="Million kwh"
		replace sales_unit="Kwh" if sales_unit=="Million kwh"

		#delimit ;
		local measures  "Ampoules
						Bags
						Bales
						Books
						Bottles
						Boxes
						Cc
						Cans
						Caps
						Carats
						Cards
						Cases
						Containers
						Coils
						Copies
						Crates
						Decimetres
						Doses
						Dozens
						Feet
						Gallons
						Gross
						Hides
						Impression
						Jars
						Kms
						Kcal
						Lbs
						Lines
						Metres
						Packets
						Packs
						Pairs
						Pouches
						Reams
						Reels
						Rolls
						Sachets
						Sets
						Sheets
						Strips
						Tablets
						Tests
						Tubes
						Units
						Vials
						Volumes
						Volts
						Yards";
		#delimit cr				
						

		foreach meas of local measures {


		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh "+lower("`meas'")
		replace sales_unit="`meas'" if sales_unit=="Lakh "+lower("`meas'")

		replace sales_qty=sales_qty*1000 if sales_unit=="'000 "+lower("`meas'")
		replace sales_unit="`meas'" if sales_unit=="'000 "+lower("`meas'")

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million "+lower("`meas'") 
		replace sales_unit="`meas'" if sales_unit=="Million "+lower("`meas'")
		}

		//piece
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 pieces"
		replace sales_unit="Piece" if sales_unit=="'000 pieces"


		//core metres
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 core metres"
		replace sales_unit="Core Metres" if sales_unit=="'000 core metres"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh core metres"
		replace sales_unit="Core Metres" if sales_unit=="Lakh core metres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million core metres"
		replace sales_unit="Core Metres" if sales_unit=="Million core metres"


		//Cubic feet
		replace sales_qty=sales_qty*1000*0.0283168 if sales_unit=="'000 cu.feet"
		replace sales_unit="Cubic metres" if sales_unit=="'000 cu.feet"

		replace sales_qty=sales_qty*100000*0.0283168 if sales_unit=="Lakh cu.feet"
		replace sales_unit="Cubic metres" if sales_unit=="Lakh cu.feet"

		replace sales_qty=sales_qty*1000000*0.0283168 if sales_unit=="Million cu.feet"
		replace sales_unit="Cubic metres" if sales_unit=="Million cu.feet"

		//Cubic metres
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 cu.metres"
		replace sales_unit="Cubic metres" if sales_unit=="'000 cu.metres"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh cu.metres"
		replace sales_unit="Cubic metres" if sales_unit=="Lakh cu.metres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million cu.metres"
		replace sales_unit="Cubic metres" if sales_unit=="Million cu.metres"

		//Dozen Pairs
		replace sales_qty=sales_qty*1000*12 if sales_unit=="'000 dozen pairs"
		replace sales_unit="Pairs" if sales_unit=="'000 dozen pairs"

		replace sales_qty=sales_qty*100000*12 if sales_unit=="Lakh dozen pairs"
		replace sales_unit="Pairs" if sales_unit=="Lakh dozen pairs"

		replace sales_qty=sales_qty*1000000*12 if sales_unit=="Million dozen pairs"
		replace sales_unit="Pairs" if sales_unit=="Million dozen pairs"

		//Horse power
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 horse power"
		replace sales_unit="Horse power" if sales_unit=="'000 horse power"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh horse power"
		replace sales_unit="Horse power" if sales_unit=="Lakh horse power"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million horse power"
		replace sales_unit="Horse power" if sales_unit=="Million horse power"


		//Linear metres
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 linear metres"
		replace sales_unit="Linear Metres" if sales_unit=="'000 linear metres"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh linear metres"
		replace sales_unit="Linear Metres" if sales_unit=="Lakh linear metres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million linear metres"
		replace sales_unit="Linear Metres" if sales_unit=="Million linear metres"


		replace sales_qty=sales_qty*1000 if sales_unit=="'000 running metres"
		replace sales_unit="Linear Metres" if sales_unit=="'000 running metres"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh running metres"
		replace sales_unit="Linear Metres" if sales_unit=="Lakh running metres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million running metres"
		replace sales_unit="Linear Metres" if sales_unit=="Million running metres"


		replace sales_qty=sales_qty*1000*0.3048 if sales_unit=="'000 running feet"
		replace sales_unit="Linear Metres" if sales_unit=="'000 running feet"

		replace sales_qty=sales_qty*100000*0.3048 if sales_unit=="Lakh running feet"
		replace sales_unit="Linear Metres" if sales_unit=="Lakh running feet"

		replace sales_qty=sales_qty*1000000*0.3048 if sales_unit=="Million running feet"
		replace sales_unit="Linear Metres" if sales_unit=="Million running feet"


		//sq metres
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 sq.metres"
		replace sales_unit="Square metres" if sales_unit=="'000 sq.metres"

		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh sq.metres"
		replace sales_unit="Square metres" if sales_unit=="Lakh sq.metres"

		replace sales_qty=sales_qty*1000000 if sales_unit=="Million sq.metres"
		replace sales_unit="Square metres" if sales_unit=="Million sq.metres"

		replace sales_qty=sales_qty*1000*0.0929 if sales_unit=="'000 sq.feet"
		replace sales_unit="Square metres" if sales_unit=="'000 sq.feet"

		replace sales_qty=sales_qty*100000*0.0929 if sales_unit=="Lakh sq.feet"
		replace sales_unit="Square metres" if sales_unit=="Lakh sq.feet"

		replace sales_qty=sales_qty*1000000*0.0929 if sales_unit=="Million sq.feet"
		replace sales_unit="Square metres" if sales_unit=="Million sq.feet"


		replace sales_qty=sales_qty*1000*0.01 if sales_unit=="'000 sq.decimetres"
		replace sales_unit="Square metres" if sales_unit=="'000 sq.decimetres"

		replace sales_qty=sales_qty*100000*0.01 if sales_unit=="Lakh sq.decimetres"
		replace sales_unit="Square metres" if sales_unit=="Lakh sq.decimetres"

		replace sales_qty=sales_qty*1000000*0.01 if sales_unit=="Million sq.decimetres"
		replace sales_unit="Square metres" if sales_unit=="Million sq.decimetres"

		replace sales_qty=sales_qty*100000*0.000645 if sales_unit=="Lakh sq.inches"
		replace sales_unit="Square metres" if sales_unit=="Lakh sq.inches"

		//proof litres
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh proof litres"
		replace sales_unit="Proof litres" if sales_unit=="Lakh proof litres"
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 proof litres"
		replace sales_unit="Proof litres" if sales_unit=="'000 proof litres"

		//proof litres
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh proof kls"
		replace sales_unit="Proof kls" if sales_unit=="Lakh proof kls"

		//quintals
		replace sales_qty=sales_qty*1000 if sales_unit=="'000 quintals"
		replace sales_unit="Quintals" if sales_unit=="'000 quintals"

		//trays
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh trays"
		replace sales_unit="Trays" if sales_unit=="Lakh trays"

		//BOU
		replace sales_qty=sales_qty*100000 if sales_unit=="Lakh BOU"
		replace sales_unit="BOU" if sales_unit=="Lakh BOU"

		//Barrels
		replace sales_qty=sales_qty*1000000 if sales_unit=="Million barrels"
		replace sales_unit="Barrels" if sales_unit=="Million barrels"

		//Radio freq. trans.
		replace sales_qty=sales_qty*1000000 if sales_unit=="Million radio freq. trans."
		replace sales_unit="Radio freq. trans." if sales_unit=="Million radio freq. trans."

		//roll metres
		replace sales_qty=sales_qty*1000000 if sales_unit=="Million roll metres"
		replace sales_unit="Roll metres" if sales_unit=="Million roll metres"

		//pieces 
		replace sales_qty=sales_qty*1000000 if sales_unit=="Mln. pieces"
		replace sales_unit="Piece" if sales_unit=="Mln. pieces"
end

* 2. calculation programs ****************************************************** 

* 2.1 calculate difference ----------------------------------------------------- 

program define diff
	gen diff = (`1'-`2')/(max(abs(`1'),abs(`2'))) if `1'!=. & `2'!=. 
end
program define diffpos
	gen diff = abs(`1'-`2')/(max(abs(`1'),abs(`2'))) if `1'!=. & `2'!=. 
end

* 2.2 calculate normalized difference ------------------------------------------ 

program define normdiff, eclass 
// $Id: personal/n/normdiff.ado, by Keith Kranker <keith.kranker@gmail.com> on 
// 2012/01/07 18:15:06 (revision ef3e55439b13 by user keith) $

	version 9

	syntax varlist(min=1 numeric) [if] [in] ///
		, ///
		over(varname)   	///  Key option --> creates columns
		[ 				    ///  
		noNORMDiff          ///  Exclude column w/ normalized difference 
		Difference			///  Add a column w/ difference between means (not-normalized)
		All                 ///  Add a column w/ mean for treatment and controls
		Tstat				///  Add a column w/ t-statistic for the null hypothesis of equal means
		Pvalue				///  Add a column w/ p-value for the null hypothesis of equal means
			CLuster(passthru) Robust /// pass cluster/robust  to the regression used to calculate the pvalue option
			x(varlist)      ///  pass controls to the regression used to calculate the pvalue option
			fe re be pa     ///  instead of OLS, run xtreg with fe/re/be/pa option, respectively
			i(passthru)     ///  pass controls panel variable to xtreg (doesn't do anything if fe/re/be/pa option
			QUIetly         ///  don't display regressions for pvalue option
		Casewise			///  perform casewise deletion of observations
		n(string)           ///  Specify location of sample size: {below|over|total|off}
		Format(passthru) 	///  Specify format for display of tables (matrix saves all digits)
		]
		
	// Selects observations using the "casewise" behavior based on the marksample
	marksample touse 

	quietly count if `touse'
	local count_touse = r(N)

	quietly count `if' `in' 
	local count_ifin = r(N)

	if !mi("`casewise'") local if "if `touse'"
	if "`if'" == "" local if_and "if"
	else            local if_and "`if' & "

	* Check that `over' is valid:  Must always ==0 or ==1 
	cap assert ( `over' == 0 | `over' == 1) `if' `in' 
		if _rc !=0    	{
			noisily di as error "`over' must equal {0,1} `if' `in'"
			exit
			}

	* Check that n(string) is valid
	if "`n'"=="" local n "below" // defalt
	cap assert ("`n'"=="below" | "`n'"=="over" |"`n'"=="total" |"`n'"=="off")
	if _rc !=0    	{
			noisily di as error "option invalid: n(below|over|total|off)"
			exit
			}

	* Dots to show somthing is happening for really large datasets.		
	local varnum : word count `varlist'
	if (( `varnum' > 10 | `count_touse' > 10000 ) & ( "`noisily'" != "noisily" )) local dots "dots" 
	if "`dots'"=="dots" noisily di as text "Variables completed: " _c
		
	local v=0
	tempvar  temp
	tempname table table_n table_means table_all table_normdiff table_diff table_tstat table_pvalue row_n

	foreach y of local varlist {
		local ++v
		if "`dots'"=="dots" noisily di as res "..`v'" _c

		* Mean, sample varience, and sample size of y, over==0
		summ `y' `if_and' `over'==0 `in', meanonly
		local ybar_0 = r(mean)
		local y_n_0 = r(N)
		quietly gen  `temp' = (`y' - `ybar_0' )^2 `if_and' (`over'==0) `in'
		summ `temp' `if_and' (`over'==0) `in', meanonly
		local var_0 = r(sum) / ( `y_n_0' - 1 )
		drop `temp'
			
		* Mean, sample varience, and sample size of y, over==1
		summ `y' `if_and' `over'==1 `in', meanonly
		local ybar_1 = r(mean)
		local y_n_1 = r(N)
		quietly gen  `temp' = (`y' - `ybar_0' )^2 `if_and' (`over'==1) `in'
		summ `temp' `if_and' (`over'==1) `in', meanonly
		local var_1 = r(sum) / ( `y_n_1' - 1 )
		drop `temp' 	

		* Save means in "`table'" matrix
		mat `table' = ( nullmat(`table') \  `ybar_0' , `ybar_1' )
		mat colname `table' = "Mean:`over'==0" "Mean:`over'==1" 

		* Normalized Difference
		local y_diff_norm  = ( `ybar_1' - `ybar_0' ) / sqrt( `var_1' + `var_0')
		mat `table_normdiff' = ( nullmat( `table_normdiff' ) \ `y_diff_norm' )
		mat colname `table_normdiff' = "Difference:Normalized"
		
		* Mean for both groups
		summ `y' `if_and' inlist(`over',0,1) `in', meanonly
		local ybar_all = r(mean)
		mat `table_all' = ( nullmat( `table_all' ) \ `ybar_all' )
		mat colname `table_all' = "Mean:All"

		mat `table_means' = (nullmat( `table_means') \ `ybar_0' , `ybar_1', `ybar_all' )
		mat colname `table_means' = "Mean:`over'==0" "Mean:`over'==1"  "Mean:All"

		if !missing(`"`pvalue'`fe'`re'`be'`pa'`cluster'`robust'`x'"') {
			* P-value and T-statistic from regression (slower)
			if !missing( "`fe'","`re'","`be'","`pa'") {
				`quietly' di "xtreg `y' `over' `x' `if' `in', `fe' `re' `be' `pa' `cluster' `robust'"
				`quietly'     xtreg `y' `over' `x' `if' `in', `fe' `re' `be' `pa' `cluster' `robust'
			}
			else {
				`quietly' di "regress `y' `over' `x' `if' `in', `cluster' `robust'"
				`quietly'     regress `y' `over' `x' `if' `in', `cluster' `robust'
			}
			
			if missing("`x'") {
				mat `table_diff' = ( nullmat( `table_diff' ) \  _b[`over'] )
				mat colname `table_diff' = "Difference:Means"
			}
			else {
				mat `table_diff' = ( nullmat( `table_diff' ) \ `=`ybar_1' - `ybar_0'', `=_b[`over']' )
				mat colname `table_diff' = "Difference:Means" "Difference:Means_Adjusted"
			}

			mat `table_tstat' =  ( nullmat(`table_tstat') \ `=_b[`over'] / _se[`over']' )
			mat colname `table_tstat' = "Difference:t-statistic"
			
			`quietly' test `over'
			mat `table_pvalue' = ( nullmat(`table_pvalue') \ r(p) )
			mat colname `table_pvalue' = "Difference:p-value"
		  }
		else {
			* Difference (not normalized) (fast option)
			mat `table_diff' = ( nullmat( `table_diff' ) \ `ybar_1' - `ybar_0' )
			mat colname `table_diff' = "Mean:Difference"

			* T-statistic on difference in means (fast option)
			local y_tstat  = ( `ybar_1' - `ybar_0' ) / sqrt( ( `var_1' / `y_n_1' ) + ( `var_0' / `y_n_0' ) )
			mat `table_tstat' = ( nullmat( `table_tstat' ) \ `y_tstat' )
			mat colname `table_tstat' = "Difference:t-stat"
		}

		* Sample Sizes 
		local y_n =  `y_n_1' + `y_n_0'
		mat `table_n' = ( nullmat( `table_n')  \ `y_n_0' , `y_n_1' , `y_n' )
		mat colname `table_n' = "N:`over'==0" "N:`over'==1" "N:All"

	}   // end loop thru varlist

	* Add row labels 
	foreach mat in `table' `table_n' `table_all'  `table_normdiff' `table_diff' `table_tstat' `table_pvalue'  {
		cap mat rowname `mat' = `varlist'  
		} 

	* Total N for last row of table, warning if sample size is inconsistent.
	capture {
		local n_11 = `table_n'[1,1]
		local n_21 = `table_n'[1,2]
		mat `row_n' = ( `n_11' , `n_21')
		mat rownames `row_n' = "N"
		local rows = rowsof( `table_n' )
		forvalues r=2/`rows' {
			local n_1r = `table_n'[`r',1]
			local n_2r = `table_n'[`r',2]
			assert ( `n_1r' == `n_11') & ( `n_2r' == `n_21')
		}
	}	
	if _rc !=0 {
		di as error "The number of observations with data in each row (created by -varlist-) is not uniform." 
			if ( "`n'" == "below" ) {
				di as error "The -n- option was changed from n(" as res "below" as error ") to n(" as res "over" as error ")."
				local n "over"
				}
	}
		
	* Add other statistics and sample sizes.
	if !missing("`all'")         mat `table' = ( `table' , `table_all' )
	if  missing("`normdiff'")    mat `table' = ( `table' , `table_normdiff' )
	if !missing("`difference'")  mat `table' = ( `table' , `table_diff' )
	if !missing("`tstat'")       mat `table' = ( `table' , `table_tstat' )
	if !missing("`pvalue'")      mat `table' = ( `table' , `table_pvalue' )
	if      "`n'"=="over"        mat `table' = ( `table' , `table_n'[....,1..2])
	else if "`n'"=="total"       mat `table' = ( `table' , `table_n'[....,3])
	else if "`n'"=="below"       mat `table' = ( `table' \ `row_n' , ( .z * `table'[1,3...] ) )

	// post results to ereturn
	ereturn clear
	ereturn matrix  table    = `table'
	ereturn matrix  _n       = `table_n' 
	cap ereturn mat means    = `table_means' 
	cap ereturn mat normdiff = `table_normdiff' 
	cap ereturn mat diff     = `table_diff' 
	cap ereturn mat tstat    = `table_tstat' 
	cap ereturn mat pvalue   = `table_pvalue' 
	™

	// display before e(table)
	mat list e(table)               , nodotz `format' noheader	
end

* 3. graph programs ************************************************************ 

* 3.1 define graph look --------------------------------------------------------

program define graph_options
    #delimit ;
    syntax [,
        scheme(string)
        labsize(string)
        bigger_labsize(string)
        ylabel_format(string)
        y_labgap(string)
        ylabel_options(string)
        ylabel_options_invis(string)
        xlabel_format(string)
        x_labgap(string)
        x_angle(string)
        xlabel_options(string)
        xlabel_options_invis(string)
        xtitle_options(string)
        xtitle_options_invis(string)
        ytitle_options(string)
        ytitle_options_invis(string)
        title_options(string)
        subtitle_options(string)
        manual_axis(string)
        plot_margin(string)
        plotregion(string)
        graph_margin(string)
        graphregion(string)
        T_line_options(string)
        marker_color(string)
        marker_symbol(string)
        marker_size(string)
        marker_options(string)
        bar_options(string)
        estimate_options_0(string)
        estimate_options_90(string)
        estimate_options_95(string)
        rcap_options_0(string)
        rcap_options_90(string)
        rcap_options_95(string)
        fit_options(string)
        legend_cols(string)
        legend_position(string)
        legend_margin(string)
        legend_title_options(string)
        legend_options(string)
    ];
    #delimit cr
    
    if "`scheme'"=="" set scheme s1color
    else set scheme `scheme'
    
    if "`labsize'"=="" local labsize medlarge
    if "`bigger_labsize'"=="" local bigger_labsize `labsize'
    if "`ylabel_options'"=="" local ylabel_options nogrid notick labsize(`labsize') angle(horizontal) format(`ylabel_format') labgap(`y_labgap')
    if "`ylabel_options_invis'"=="" local ylabel_options_invis `ylabel_options' labcolor(white)
    if "`xlabel_options'"=="" local xlabel_options nogrid notick labsize(`labsize') valuelabels format(`xlabel_format') angle(`x_angle') labgap(`x_labgap')
    if "`xlabel_options_invis'"=="" local xlabel_options_invis `xlabel_options' labcolor(white)
    if "`xtitle_options'"=="" local xtitle_options size(`labsize') color(black) margin(top) 
    if "`xtitle_options_invis'"=="" local xtitle_options_invis size(`labsize') color(white) margin(top)
    if "`ytitle_options'"=="" local ytitle_options size(`labsize') color(black)
    if "`ytitle_options_invis'"=="" local ytitle_options_invis size(`labsize') color(white)
    if "`title_options'"=="" local title_options size(`labsize') color(black) 
    if "`subtitle_options'"=="" local subtitle_options size(`labsize') color(black) margin(bottom) 
    if "`manual_axis'"=="" local manual_axis lwidth(thin) lcolor(black) lpattern(solid)
    if "`plot_margin'"=="" local plot_margin l=0 r=2 b=0 t=2
    if "`plotregion'"=="" local plotregion plotregion(margin(`plot_margin') fcolor(white) lstyle(none) lcolor(white)) 
    if "`graph_margin'"=="" local graph_margin zero
    if "`graphregion'"=="" local graphregion graphregion(margin(`graph_margin') fcolor(white) lstyle(none) lcolor(white)) 
    if "`T_line_options'"=="" local T_line_options lwidth(thin) lcolor(gray) lpattern(dash)
    if "`marker_color'" == "" local marker_color "black"
    if "`marker_symbol'" == "" local marker_symbol "O"
    if "`marker_size'" == "" local marker_size "medium"
    if "`marker_options'"=="" local marker_options mcolor(`marker_color') msymbol(`marker_symbol') msize(`marker_size')
    if "`bar_options'"=="" local bar_options lwidth(none) lcolor(gs7) fcolor(gs7)
    if "`estimate_options_0'"=="" local estimate_options_0  mcolor(gs7)   msymbol(Oh) msize(medlarge)
    if "`estimate_options_90'"=="" local estimate_options_90  mcolor(gs7)   msymbol(O)  msize(medlarge)
    if "`estimate_options_95'"=="" local estimate_options_95  mcolor(black) msymbol(O)  msize(medlarge)
    if "`rcap_options_0'"==""  local rcap_options_0   lcolor(gs7)   lwidth(thin)
    if "`rcap_options_90'"=="" local rcap_options_90  lcolor(gs7)   lwidth(thin)
    if "`rcap_options_95'"=="" local rcap_options_95  lcolor(black) lwidth(thin)
    if "`fit_options'"=="" local fit_options clwidth(medthick) clcolor(blue) fcolor(none) ///
        alcolor(blue*0.5) alpattern(dash) alwidth(thin)
    if "`legend_cols'"=="" local legend_cols 1
    if "`legend_position'"=="" local legend_position 6
    if "`legend_margin'"=="" local legend_margin zero
    if "`legend_title_options'"=="" local legend_title_options size(`labsize') color(black) margin(l=0 r=0 b=1 t=0) 
    if "`legend_options'"=="" local legend_options region(lwidth(none)) bmargin(`legend_margin') position(`legend_position') cols(`legend_cols') size(`labsize')
    
    c_local labsize `labsize'
    c_local bigger_labsize `bigger_labsize'
    // Axes
    c_local ylabel_options `ylabel_options'
    c_local ylabel_options_invis `ylabel_options_invis'
    c_local xlabel_options `xlabel_options'
    c_local xlabel_options_invis `xlabel_options_invis'
    c_local xtitle_options `xtitle_options'
    c_local xtitle_options_invis `xtitle_options_invis'
    c_local ytitle_options `ytitle_options'
    c_local ytitle_options_invis `ytitle_options_invis'
    // Titles
    c_local title_options `title_options'
    c_local subtitle_options `subtitle_options'
    // Misc
    c_local manual_axis `manual_axis'
    c_local plotregion `plotregion'
    c_local graphregion `graphregion'
    // To put a line right before treatment
    c_local T_line_options `T_line_options'
    // Bars
    c_local bar_options `bar_options'
    // General markers
    c_local marker_color `marker_color'
    c_local marker_symbol `marker_symbol'
    c_local marker_size `marker_size'
    c_local marker_options `marker_options'
    // To show significance: hollow gray (gs7) will be insignificant from 0,
    //  filled-in gray significant at 10%
    //  filled-in black significant at 5%
    c_local estimate_options_0  `estimate_options_0'
    c_local estimate_options_90 `estimate_options_90'
    c_local estimate_options_95 `estimate_options_95'
    c_local rcap_options_0  `rcap_options_0'
    c_local rcap_options_90 `rcap_options_90'
    c_local rcap_options_95 `rcap_options_95'
    // Fit line
    c_local fit_options `fit_options'
    // Legend
    c_local legend_cols `legend_cols'
    c_local legend_position `legend_position'
    c_local legend_margin `legend_margin'
    c_local legend_title_options `legend_title_options'
    c_local legend_options `legend_options'
    // Colorblind colors
    c_local cblind1 "0 0 0" // Black
    c_local cblind2 "153 153 153" // Gray
    c_local cblind3 "230 159 0" // Orange
    c_local cblind4 "86 180 233" // Sky Blue
    c_local cblind5 "0 158 115" // bluish Green
    c_local cblind6 "240 228 66" // Yellow
    c_local cblind7 "0 114 178" // Blue
    c_local cblind8 "213 94 0" // Vermillion
    c_local cblind9 "204 121 167" // reddish Purple
end


// OLD
/*
#delimit ;
label define nic2digit2004 
1 "Agriculture, hunting and related service activities"
2 "Forestry, logging and related service activities"
5 "Fishing, aquaculture and service activities incidental to fishing"
10 "Mining of coal and lignite; extraction of peat"
11 "Extraction of crude petroleum and natural gas; service activities incidental to oil and gas extraction, excluding surveying"
12 "Mining of uranium and thorium ores"
13 "Mining of metal ores"
14 "Other mining and quarrying"
15 "Manufacture of food products and beverages"
16 "Manufacture of tobacco products"
17 "Manufacture of textiles"
18 "Manufacture of wearing apparel; dressing and dyeing of fur"
19 "Tanning and dressing of leather; manufacture of luggage, handbags, saddlery, harness and footwear"
20 "Manufacture of wood and of products of wood and cork, except furniture; manufacture of articles of straw and plaiting materials"
21 "Manufacture of paper and paper products"
22 "Publishing, printing and reproduction of recorded media"
23 "Manufacture of coke, refined petroleum products and nuclear fuel"
24 "Manufacture of chemicals and chemical products"
25 "Manufacture of rubber and plastics products"
26 "Manufacture of other non-metallic mineral products"
27 "Manufacture of basic metals"
28 "Manufacture of fabricated metal products, except machinery and equipment"
29 "Manufacture of machinery and equipment n.e.c."
30 "Manufacture of office, accounting and computing machinery"
31 "Manufacture of electrical machinery and apparatus n.e.c."
32 "Manufacture of radio, television and communication equipment and apparatus"
33 "Manufacture of medical, precision and optical instruments, watches and clocks"
34 "Manufacture of motor vehicles, trailers and semi-trailers"
35 "Manufacture of other transport equipment"
36 "Manufacture of furniture; manufacturing n.e.c."
37 "Recycling"
40 "Electricity, gas, steam and hot water supply"
41 "Collection, purification and distribution of water"
45 "Construction"
50 "Sale, maintenance and repair of motor vehicles and motorcycles; retail sale of automotive fuel"
51 "Wholesale trade and commission trade, except of motor vehicles and motorcycles"
52 "Retail trade, except of motor vehicles and motorcycles; repair of personal and household goods"
55 "Hotels and restaurants"
60 "Land transport; transport via pipelines"
61 "Water transport"
62 "Air transport"
63 "Supporting and auxiliary transport activities; activities of travel agencies"
64 "Post and telecommunications"
65 "Financial intermediation, except insurance and pension funding"
66 "Insurance and pension funding, except compulsory social security"
67 "Activities auxiliary to financial intermediation"
70 "Real estate activities"
71 "Renting of machinery and equipment without operator and of personal and household goods"
72 "Computer and related activities"
73 "Research and development"
74 "Other business activities"
75 "Public administration and defence; compulsory social security"
80 "Education"
85 "Health and social work"
90 "Sewage and refuse disposal, sanitation and similar activities"
91 "Activities of membership organizations n.e.c."
92 "Recreational, cultural and sporting activities"
93 "Other service activities"
95 "Activities of private households as employers of domestic staff"
96 "Undifferentiated goods-producing activities of private households for own use"
97 "Undifferentiated service-producing activities of private households for own use"
99 "Extraterritorial organizations and bodies"
#delimit cr


program define nominaltoreal
	local i = 1
	while "``i''" != "" {
	gen ``i''_R=``i''/(gdp_defl/100)
	local ++i
	}
end
*/ 
