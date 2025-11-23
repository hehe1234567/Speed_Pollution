*** raw data

*1, converting data format
gen date_td = date(date, "YMD")   
format date_td %td                    

gen month=month(date_td)
destring wind_class, replace ignore("级")
destring wind_dir,replace


*2, define weekday
gen dow=dow(date_td)

gen holiday = inlist(date_td, ///
td(29sep2023), td(30sep2023), td(01oct2023), td(02oct2023), td(03oct2023), td(04oct2023), td(05oct2023), td(06oct2023), ///
td(30dec2023), td(31dec2023), td(01jan2024), ///
td(10feb2024), td(11feb2024), td(12feb2024), td(13feb2024), td(14feb2024), td(15feb2024), td(16feb2024), td(17feb2024), ///
td(04apr2024), td(05apr2024), td(06apr2024), ///
td(01may2024), td(02may2024), td(03may2024), td(04may2024), td(05may2024), ///
td(08jun2024), td(09jun2024), td(10jun2024))

gen other_day=1 if holiday==0

gen weekday=1 if dow>0 & dow<6 & other_day==1
replace weekday=0 if weekday==.

replace weekday=1 if other_day == inlist(date_td, ///
td(07oct2023), td(08oct2023), ///
td(04feb2024), td(18feb2024), ///
td(07apr2024), ///
td(28apr2024), td(11may2024))

gen weekend= other_day - weekday
replace weekend=0 if weekend==.


*3, speed stylized fact 
binscatter speed hour if inrange(hour, 0, 23), ///
    by(weekday) discrete line(connect) ///
    title("Hourly average traffic speed (0–23h)")

	
*4, constructing speed - inverse square distance
bys station_id date hour: egen wsum = total(1/(distance_to_station^2))
gen  w = (1/(distance_to_station^2)) / wsum
gen  contrib = w * speed
bys station_id date hour: egen speed_d = total(contrib)

* inverse distance
bys station_id date hour: egen wsum1 = total(1/(distance_to_station))
gen  w1 = (1/(distance_to_station)) / wsum1
gen  contrib1 = w1 * speed
bys station_id date hour: egen speed_d1 = total(contrib1)

* Average speed
bys station_id date hour: egen speed_avg = mean(speed)

* Average speed within 1km 
replace speed=. if distance_to_station>1000
bys station_id date hour: egen speed_avg_1k = mean(speed)

* Speed gap and ratio between two routes
bys station_id road_id date hour: egen speed_min_r = min(speed)
bys station_id road_id date hour: egen speed_max_r = max(speed)

gen speed_gap_r   = speed_max_r - speed_min_r
gen speed_ratio_r = speed_min_r / speed_max_r if speed_max_r>0

* 1) minimum speed at road level
gen contrib_min2 = w * speed_min_r
bys station_id date hour: egen speed_min_d2 = total(contrib_min2)

bys station_id date hour: egen has_min = max(!missing(speed_min_r))
replace speed_min_d2 = . if has_min==0
drop has_min

* 2) speed difference between two routes 
gen contrib_gap2 = w * speed_gap_r
bys station_id date hour: egen gap_d2 = total(contrib_gap2)

bys station_id date hour: egen has_gap = max(!missing(speed_gap_r))
replace gap_d2 = . if has_gap==0
drop has_gap

* 3) speed ratio betwen two routes
gen contrib_ratio2 = w * speed_ratio_r
bys station_id date hour: egen ratio_d2 = total(contrib_ratio2)

bys station_id date hour: egen has_ratio = max(!missing(speed_ratio_r))
replace ratio_d2 = . if has_ratio==0
drop has_ratio


***converting air-station level data
drop route_id road_id speed distance_to_station direction_to_station wsum w contrib wsum1 w1 contrib1 speed_min_r speed_max_r speed_gap_r speed_ratio_r contrib_min2 contrib_gap2 contrib_ratio2

duplicates drop



*********air station level data
*5 constructing variables
encode city,gen (city_id)
encode weather, gen (weather_id)
encode wind_dir, gen (wind_dir_id)

gen lnspeed_d=ln(speed_d)
gen lnpm25=ln(pm2_5)
gen lnpm10=ln(pm10)
gen lnso2=ln(so2)
gen lnco=ln(co)
gen lnno2=ln(no2)
gen lno3=ln(o3)

replace aqi=1 if aqi==-1
gen lnaqi=ln(aqi)


****6, Table 1, baseline
* Panel A
reg lnco lnspeed_d,vce(cluster station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id city_id#date_td) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d) 

* Panel B
reg lnno2 lnspeed_d,vce(cluster station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id) cluster(station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id) cluster(station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id city_id#date_td) cluster(station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_1.1.xls,keep (lnspeed_d)


****7 Robustness Check/ Placebo test - Appendix A3
gen lnspeed_d1=ln(speed_d1)
gen lnspeed_avg=ln(speed_avg)
gen lnspeed_1k=ln(speed_avg_1k)
gen lnspeed_min = ln(speed_min_d2)

gen normal=1 if weather=="晴"
replace normal=1 if weather=="阴"
replace normal=1 if weather=="多云"

reghdfe  lnco lnspeed_d1 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d1)

reghdfe  lnco lnspeed_avg temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_avg)

reghdfe  lnco lnspeed_1k temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_1k)

reghdfe  lnco lnspeed_min temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_min)

reghdfe  lnco lnspeed_d temperature relative_humidity if normal==1, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d)

reghdfe  lnco lnspeed_d temperature relative_humidity if pm2_5<150, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d)

reghdfe  lnco lnspeed_d temperature relative_humidity if aqi<200, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d)

reghdfe  lnno2 lnspeed_d1 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d1)

reghdfe  lnno2 lnspeed_avg temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_avg)

reghdfe  lnno2 lnspeed_1k temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_1k)

reghdfe  lnno2 lnspeed_min temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_min)

reghdfe  lnno2 lnspeed_d temperature relative_humidity if normal==1, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d)

reghdfe  lnno2 lnspeed_d temperature relative_humidity if pm2_5<150, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d)

reghdfe  lnno2 lnspeed_d temperature relative_humidity if aqi<200, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d)

**** Placebo 各种污染物
reghdfe  lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d)

reghdfe  lnpm10 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d)

reghdfe  lno3 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d)

reghdfe  lnaqi lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d)


****8  Heteroegenies Effect, T2 in the paper 
*constructing binary varaibles
gen hour_peak = .
replace hour_peak = 1 if inrange(hour,7,9)    // morning peak
replace hour_peak = 1 if inrange(hour,17,19)  // evening peak
replace hour_peak =0 if hour_peak==.

gen daytime=1 if hour>=7 & hour<= 19
replace daytime=0 if daytime==.

*Co
reghdfe lnco lnspeed_d c.lnspeed_d#hour_peak temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d c.lnspeed_d#hour_peak)

reghdfe lnco lnspeed_d c.lnspeed_d#weekday temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d c.lnspeed_d#weekday)

reghdfe lnco lnspeed_d c.lnspeed_d#daytime temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d c.lnspeed_d#daytime)

reghdfe lnco lnspeed_d temperature relative_humidity if hour_peak==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity if weekday==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity if daytime==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

*NO2
reghdfe lnno2 lnspeed_d c.lnspeed_d#hour_peak temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d c.lnspeed_d#hour_peak)

reghdfe lnno2 lnspeed_d c.lnspeed_d#weekday temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d c.lnspeed_d#weekday)

reghdfe lnno2 lnspeed_d c.lnspeed_d#daytime temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d c.lnspeed_d#daytime)

reghdfe lnno2 lnspeed_d temperature relative_humidity if hour_peak==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity if weekday==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity if daytime==0, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_4.1.xls,keep (lnspeed_d)


****9 congestion mechnisms - Table 3 in the paper

*generate early morning speed
bys station_id date: egen early_speed_d = mean(cond(inrange(hour,1,4), speed_d, .))

**congestion measures
gen gap_ff = early_speed_d - speed_d
gen ln_gap_ff = ln(early_speed_d) - ln(speed_d)
gen congestion_ratio = gap_ff/early_speed_d

xtile ln_gap_ff_bin = ln_gap_ff, n(4)
tab ln_gap_ff_bin, gen(d_lngap)

*Panel A congestion mechnisms
reghdfe lnco gap_ff temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (gap_ff)

reghdfe lnco ln_gap_ff temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (ln_gap_ff)

reghdfe lnco congestion_ratio temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (congestion_ratio)

reghdfe lnco gap_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (gap_d2)

reghdfe lnco ratio_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (ratio_d2)

reghdfe lnco gap_ff gap_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (gap_ff gap_d2)

reghdfe lnco congestion_ratio ratio_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (congestion_ratio ratio_d2)

reghdfe lnco d_lngap1 d_lngap2 d_lngap3 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.xls,keep (d_lngap1 d_lngap2 d_lngap3)

****Appendix T-A4 in the paper
reghdfe lnno2 gap_ff temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (gap_ff)

reghdfe lnno2 ln_gap_ff temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (ln_gap_ff)

reghdfe lnno2 congestion_ratio temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (congestion_ratio)

reghdfe lnno2 gap_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (gap_d2)

reghdfe lnno2 ratio_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (ratio_d2)

reghdfe lnno2 gap_ff gap_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (gap_ff gap_d2)

reghdfe lnno2 congestion_ratio ratio_d2 temperature relative_humidity, absorb (weather_id wind_class wind_dir hour station_id#date_td) cluster(station_id)
outreg2 using table_5.1.xls,keep (congestion_ratio ratio_d2)

**** commuting mechnism, T3-Panel B in the paper
reghdfe lnco ln_gap_ff c.ln_gap_ff#hour_peak temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (ln_gap_ff c.ln_gap_ff#hour_peak)

reghdfe lnco ln_gap_ff c.ln_gap_ff#weekday temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (ln_gap_ff c.ln_gap_ff#weekday)

reghdfe lnco c.ln_gap_ff##hour_peak##weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (c.ln_gap_ff##hour_peak##weekday)

reghdfe lnco congestion_ratio c.congestion_ratio#hour_peak temperature relative_humidity, absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (congestion_ratio c.congestion_ratio#hour_peak)

reghdfe lnco congestion_ratio c.congestion_ratio#weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (congestion_ratio c.congestion_ratio#weekday)

reghdfe lnco c.congestion_ratio##hour_peak##weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.xls,keep (c.congestion_ratio##hour_peak##weekday)

*No2 
reghdfe lnno2 ln_gap_ff c.ln_gap_ff#hour_peak temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (ln_gap_ff c.ln_gap_ff#hour_peak)

reghdfe lnno2 ln_gap_ff c.ln_gap_ff#weekday temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (ln_gap_ff c.ln_gap_ff#weekday)

reghdfe lnno2 c.ln_gap_ff##hour_peak##weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (c.ln_gap_ff##hour_peak##weekday)

reghdfe lnno2 congestion_ratio c.congestion_ratio#hour_peak temperature relative_humidity, absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (congestion_ratio c.congestion_ratio#hour_peak)

reghdfe lnno2 congestion_ratio c.congestion_ratio#weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (congestion_ratio c.congestion_ratio#weekday)

reghdfe lnno2 c.congestion_ratio##hour_peak##weekday temperature relative_humidity,absorb(station_id#date_td hour) vce(cluster station_id)
outreg2 using table_6.1.xls,keep (c.congestion_ratio##hour_peak##weekday)


****non-linear effect
xtile gap_dec = ln_gap_ff, nq(10)
*label define gapdec 1 "D1 (lowest cong.)" ///
                    2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                    6 "D6" 7 "D7" 8 "D8" 9 "D9" ///
                    10 "D10 (highest cong.)"
label values gap_dec gapdec

fvset base 10 gap_dec

* lnCO -Figure 2
reghdfe lnco i.gap_dec temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)

coefplot, keep(1.gap_dec 2.gap_dec 3.gap_dec 4.gap_dec 5.gap_dec ///
               6.gap_dec 7.gap_dec 8.gap_dec 9.gap_dec) ///
    vertical ///
    ciopts(recast(rcap)) ///
    xlabel(1 "D1" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
           6 "D6" 7 "D7" 8 "D8" 9 "D9") ///
    yline(0, lpattern(dash)) ///
    xtitle("Decile of congestion (ln_gap_ff)") ///
    ytitle("Effect on ln(CO) vs D10") ///
    title("Non-linear effect of congestion on CO")
	
	
* lnno2 - Appendix A5
reghdfe lnno2 i.gap_dec temperature relative_humidity, ///
    absorb(station_id#date_td hour) vce(cluster station_id)

coefplot, keep(1.gap_dec 2.gap_dec 3.gap_dec 4.gap_dec 5.gap_dec ///
               6.gap_dec 7.gap_dec 8.gap_dec 9.gap_dec) ///
    vertical ///
    ciopts(recast(rcap)) ///
    xlabel(1 "D1" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
           6 "D6" 7 "D7" 8 "D8" 9 "D9") ///
    yline(0, lpattern(dash)) ///
    xtitle("Decile of congestion (ln_gap_ff)") ///
    ytitle("Effect on ln(NO2) vs D10") ///
    title("Non-linear effect of congestion on NO2")