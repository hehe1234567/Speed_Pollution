gen date_td = date(date, "YMD")   // "YMD" 表示年-月-日格式
format date_td %td                    // 设置格式为可读日期

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

***Figure 1
binscatter speed hour if inrange(hour, 0, 23), ///
    by(weekday) discrete line(connect) ///
    title("Hourly average traffic speed (0–23h)")


*********Speed 
bys station_id date hour: egen __wsum = total(1/(distance_to_station^2))
gen  w = (1/(distance_to_station^2)) / __wsum
gen  __contrib = w * speed
bys station_id date hour: egen speed_d = total(__contrib)

* speed_d1
bys station_id date hour: egen __wsum1 = total(1/(distance_to_station))
gen  w1 = (1/(distance_to_station)) / __wsum1
gen  __contrib1 = w1 * speed
bys station_id date hour: egen speed_d1 = total(__contrib1)

*speed_ave
bys station_id date hour: egen speed_avg = mean(speed)

*speed_1k
replace speed=. if distance_to_station>1000
bys station_id date hour: egen speed_avg_1k = mean(speed)

***是不是应该把多余的route删掉？做了个collapose 版本
drop route_id road_id speed distance_to_station __wsum w __contrib __wsum1 w __contrib1 


duplicates drop


************speed and pm2.5 at night
bys station_id date: egen pm25_night = mean(cond(inrange(hour,1,4), pm2_5, .))
bys station_id date: egen spd_night  = mean(cond(inrange(hour,1,4), speed_d,.))

* first difference
gen d_pm25        = pm2_5      - pm25_night
gen d_speed       = speed_d    - spd_night

********generate variables
encode county, gen(county_id)
encode city,gen (city_id)
encode weather, gen (weather_id)
encode wind_dir, gen (wind_dir_id)

gen lnspeed_d=ln(speed_d)
gen lnpm25=ln(pm2_5)
gen lnpm10=ln(pm10)
gen lnso2=ln(so2)
gen lnco=ln(co)
gen lnno2=ln(no2)



***generate binary variables
gen daytime=1 if hour>=7 & hour<= 20
replace daytime=0 if daytime==.

gen summer=1 if month<10 & month>3
replace summer=0 if summer==.

gen urban = strpos(county, "区") > 0



**** Table 1
reg lnpm25 lnspeed_d,r
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnpm25 lnspeed_d, absorb (station_id) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id city_id#date_td) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)

reghdfe lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_1.xls,keep (lnspeed_d)


reghdfe lnpm25 lnspeed_d temperature relative_humidity if pm2_5<150, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d)

egen city_date_hour=group(city_id date_td hour)

reghdfe lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir city_id#date_td#hour) cluster(station_id)
outreg2 using table_2.1.xls,keep (lnspeed_d)


******T2 Robustness Check
reghdfe pm2_5 speed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (speed_d)

reghdfe d_pm25 d_speed temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (d_speed)

reghdfe lnpm25 lnspeed_d temperature relative_humidity if speed_d<77 & speed_d>14, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d)

gen lnspeed_d1=ln(speed_d1)
gen lnspeed_ave=ln(speed_avg)
gen lnspeed_1k=ln(speed_avg_1k)

reghdfe lnpm25 lnspeed_d1 temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_d1)

reghdfe lnpm25 lnspeed_ave temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_ave)

reghdfe lnpm25 lnspeed_1k temperature relative_humidity, absorb (weather_id wind_class wind_dir station_id#date_td) cluster(station_id)
outreg2 using table_2.xls,keep (lnspeed_1k)


***T3 Heterogenous Effect 

reghdfe lnpm25 lnspeed_d  c.lnspeed_d#weekday temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d  c.lnspeed_d#weekday)

reghdfe lnpm25 lnspeed_d c.lnspeed_d#daytime temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d  c.lnspeed_d#daytime) 

reghdfe lnpm25 lnspeed_d c.lnspeed_d#summer temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d  c.lnspeed_d#summer)

reghdfe lnpm25 lnspeed_d  c.lnspeed_d#urban temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_3.xls,keep (lnspeed_d  c.lnspeed_d#urban)



******T4 more pollutants
reghdfe lnpm25 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnpm10 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnso2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnco lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)

reghdfe lnno2 lnspeed_d temperature relative_humidity, absorb (weather_id wind_class wind_dir_id station_id#date_td) cluster(station_id)
outreg2 using table_4.xls,keep (lnspeed_d)