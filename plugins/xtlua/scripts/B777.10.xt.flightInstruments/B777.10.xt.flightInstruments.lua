--[[
*****************************************************************************************
* Script Name: flightInstruments
* Author Name: Crazytimtimtim
* Script Description: Code for cockpit instruments
Plan:
dataref for pilot and copilot inboard knob
knob sets display anim
combine with buttons up top
adjust brightness accordingly

*****************************************************************************************
--]]

--replace create_command
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end

--replace create_dataref
function deferred_dataref(name,nilType,callFunction)
	if callFunction~=nil then
		print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
	end
	return find_dataref(name)
end
--[[
B777DR_inboard_disp_sel_target_capt    = deferred_dataref("Strato/777/inboard_disp_sel_target_capt", "number")
B777DR_inboard_disp_sel_target_fo      = deferred_dataref("Strato/777/inboard_disp_sel_target_fo", "number")
B777DR_inboard_disp_sel_pos_capt       = deferred_dataref("Strato/777/inboard_disp_sel_pos_capt", "number")
B777DR_inboard_disp_sel_pos_fo         = deferred_dataref("Strato/777/inboard_disp_sel_pos_fo", "number")
B777DR_display_pos                     = deferred_dataref("Strato/777/display_pos", "array[5]")
B777DR_mfd_pos                         = deferred_dataref("Strato/777/mfd_pos", "array[3]")
B77CMD_mfd_ctr                         = deferred_command("Strato/777/mfd_ctr", "Set Lower DU to MFD", mfd_ctr_cmdHandler)
B777CMD_mfd_l                          = deferred_command("Strato/777/mfd_l", "Set Left Inboard DU to MFD", mfd_l_cmdHandler)
B777CMD_mfd_r                          = deferred_command("Strato/777/mfd_r", "Set Right Inboard DU to MFD", mfd_r_cmdHandler)]]

--[[if simDR_window_heat1 == 0 then
		window_heat1_target = 0
	elseif simDR_window_heat1 == 1 then
		if simDR_window_heat1_fail ~= 6 then
			if simDR_bus1_volts > 10 or simDR_bus2_volts > 10 then
				if simDR_gear_on_ground == 1 then
					window_heat1_target = 8
				elseif simDR_gear_on_ground == 0 then
					window_heat1_target = 13
				end
			elseif simDR_bus1_volts < 10 and simDR_bus2_volts < 10 then
				window_heat1_target = 0
			end
		elseif simDR_window_heat1_fail == 6 then
			window_heat1_target = 0
		end
	end

-- f/o window

	if simDR_window_heat2 == 0 then
		window_heat2_target = 0
	elseif simDR_window_heat2 == 1 then
		if simDR_window_heat2_fail ~= 6 then
			if simDR_bus1_volts > 10 or simDR_bus2_volts > 10 then
				if simDR_gear_on_ground == 1 then
					window_heat2_target = 8
				elseif simDR_gear_on_ground == 0 then
					window_heat2_target = 13
				end
			elseif simDR_bus1_volts < 10 and simDR_bus2_volts < 10 then
				window_heat2_target = 0
			end
		elseif simDR_window_heat2_fail == 6 then
			window_heat2_target = 0
		end
	end

-- left side windows

	if simDR_window_heat3 == 0 then
		window_heat3_target = 0
	elseif simDR_window_heat3 == 1 then
		if simDR_window_heat3_fail ~= 6 then
			if simDR_bus1_volts > 10 or simDR_bus2_volts > 10 then
				window_heat3_target = 8
			elseif simDR_bus1_volts < 10 and simDR_bus2_volts < 10 then
				window_heat3_target = 0
			end
		elseif simDR_window_heat3_fail == 6 then
			window_heat3_target = 0
		end
	end

-- right side windows

	if simDR_window_heat4 == 0 then
		window_heat4_target = 0
	elseif simDR_window_heat4 == 1 then
		if simDR_window_heat4_fail ~= 6 then
			if simDR_bus1_volts > 10 or simDR_bus2_volts > 10 then
				window_heat4_target = 8
			elseif simDR_bus1_volts < 10 and simDR_bus2_volts < 10 then
				window_heat4_target = 0
			end
		elseif simDR_window_heat4_fail == 6 then
			window_heat4_target = 0
		end
	end

	A333_window1_temp = A333_set_animation_position(A333_window1_temp, window_heat1_target, 0, 13, 0.04)
	A333_window2_temp = A333_set_animation_position(A333_window2_temp, window_heat2_target, 0, 13, 0.04)
	A333_window3_temp = A333_set_animation_position(A333_window3_temp, window_heat3_target, 0, 8, 0.06)
	A333_window4_temp = A333_set_animation_position(A333_window4_temp, window_heat4_target, 0, 8, 0.06)]]

--B777DR_bank_limit_knob_anim            = deferred_dataref("Strato/777/bank_limit_knob_pos", "number")
--window heat 110f
--*************************************************************************************--
--**                             XTLUA GLOBAL VARIABLES                              **--
--*************************************************************************************--

--[[
SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
 per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on
--]]

--*************************************************************************************--
--**                                CREATE VARIABLES                                 **--
--*************************************************************************************--

local B777_kgs_to_lbs = 2.2046226218
local B777_ft_to_mtrs = 0.3048
local B777_adiru_time_remaining_min = 0

local alt_press_counter = 0
local alt_is_fast = 0

local flashCount = 0
--*************************************************************************************--
--**                              FIND X-PLANE DATAREFS                              **--
--*************************************************************************************--
simDR_autopilot_alt                    = find_dataref("sim/cockpit2/autopilot/altitude_dial_ft")
simDR_startup_running                  = find_dataref("sim/operation/prefs/startup_running")
simDR_com1_stby_khz                    = find_dataref("sim/cockpit2/radios/actuators/com1_standby_frequency_khz")
simDR_com1_act_khz                     = find_dataref("sim/cockpit2/radios/actuators/com1_frequency_khz")
simDR_com2_stby_khz                    = find_dataref("sim/cockpit2/radios/actuators/com2_standby_frequency_khz")
simDR_com2_act_khz                     = find_dataref("sim/cockpit2/radios/actuators/com2_frequency_khz")
simDR_total_fuel_kgs                   = find_dataref("sim/flightmodel/weight/m_fuel_total")
simDR_fuel_kgs                         = find_dataref("sim/cockpit2/fuel/fuel_quantity")
simDR_vs_capt                          = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_ias_capt                         = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
simDR_latitude                         = find_dataref("sim/flightmodel/position/latitude")
simDR_groundSpeed                      = find_dataref("sim/flightmodel/position/groundspeed")
simDR_bus_voltage                      = find_dataref("sim/cockpit2/electrical/bus_volts")
simDR_ap_airspeed                      = find_dataref("sim/cockpit/autopilot/airspeed")
simDR_alt_ft_capt                      = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_autopilot_alt                    = find_dataref("sim/cockpit/autopilot/altitude")
simDR_aoa                              = find_dataref("sim/flightmodel2/misc/AoA_angle_degrees")
simDR_radio_alt_capt                   = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_onGround                         = find_dataref("sim/flightmodel/failures/onground_any")
simDR_vertical_speed                   = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_hdg_bug                          = find_dataref("sim/cockpit/autopilot/heading_mag")
simDR_hdg                              = find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")
simDR_map_mode                         = find_dataref("sim/cockpit/switches/EFIS_map_submode")
B777DR_hyd_press                       = find_dataref("Strato/777/hydraulics/press")
B777DR_ovhd_aft_button_target          = find_dataref("Strato/777/cockpit/ovhd/aft/buttons/target")

--*************************************************************************************--
--**                             CUSTOM DATAREF HANDLERS                             **--
--*************************************************************************************--

--*************************************************************************************--
--**                              CREATE CUSTOM DATAREFS                             **--
--*************************************************************************************--

B777DR_nd_mode_selector                = deferred_dataref("Strato/777/fltInst/nd_mode_selector", "number")
B777DR_fuel_lbs                        = deferred_dataref("Strato/777/displays/fuel_lbs", "array[3]")
B777DR_fuel_lbs_total                  = deferred_dataref("Strato/777/displays/fuel_lbs_total", "number")
B777DR_alt_mtrs_capt                   = deferred_dataref("Strato/777/displays/alt_mtrs_capt", "number")
B777DR_autopilot_alt_mtrs_capt         = deferred_dataref("Strato/777/displays/autopilot_alt_mtrs", "number")
B777DR_eicas_mode                      = deferred_dataref("Strato/777/displays/eicas_mode", "number") -- what page the lower eicas is on

B777DR_displayed_com1_act_khz          = deferred_dataref("Strato/777/displays/com1_act_khz", "number") -- COM1 Radio Active Display
B777DR_displayed_com1_stby_khz         = deferred_dataref("Strato/777/displays/com1_stby_khz", "number") -- COM1 Radio Standby Display
B777DR_displayed_com2_act_khz          = deferred_dataref("Strato/777/displays/com2_act_khz", "number") -- COM2 Radio Active Display
B777DR_displayed_com2_stby_khz         = deferred_dataref("Strato/777/displays/com2_stby_khz", "number") -- COM2 Radio Standby Display

B777DR_vs_capt_indicator               = deferred_dataref("Strato/777/displays/vvi_capt", "number")
B777DR_ias_capt_indicator              = deferred_dataref("Strato/777/displays/ias_capt", "number")

B777DR_adiru_status                    = deferred_dataref("Strato/777/fltInst/adiru/status", "number") -- 0 = off, 1 = aligning 2 = aligned
B777DR_adiru_time_remaining_min        = deferred_dataref("Strato/777/fltInst/adiru/time_remaining_min", "number")
B777DR_adiru_time_remaining_sec        = deferred_dataref("Strato/777/fltInst/adiru/time_remaining_sec", "number")
B777DR_temp_adiru_is_aligning          = deferred_dataref("Strato/777/temp/fltInst/adiru/aligning", "number")

B777DR_airspeed_bug_diff               = deferred_dataref("Strato/777/airspeed_bug_diff", "number")
B777DR_displayed_aoa                   = deferred_dataref("Strato/777/displayed_aoa", "number")
B777DR_outlined_RA                     = deferred_dataref("Strato/777/outlined_RA", "number")
B777DR_alt_is_fast_ovrd                = deferred_dataref("Strato/777/alt_step_knob_target", "number")
B777DR_displayed_alt                   = deferred_dataref("Strato/777/displays/displayed_alt", "number")
B777DR_alt_bug_diff                    = deferred_dataref("Strato/777/displays/alt_bug_diff", "number")
B777DR_baro_mode                       = deferred_dataref("Strato/777/baro_mode", "number")
B777DR_minimums_mode                   = deferred_dataref("Strato/777/minimums_mode", "number")
B777DR_minimums_diff                   = deferred_dataref("Strato/777/minimums_diff", "number")
B777DR_minimums_visible                = deferred_dataref("Strato/777/minimums_visible", "number")
B777DR_minimums_mda                    = deferred_dataref("Strato/777/minimums_mda", "number")
B777DR_minimums_dh                     = deferred_dataref("Strato/777/minimums_dh", "number")
B777DR_amber_minimums                  = deferred_dataref("Strato/777/amber_minimums", "number")
B777DR_minimums_mode_knob_anim         = deferred_dataref("Strato/777/minimums_mode_knob_pos", "number")
B777DR_baro_mode_knob_anim             = deferred_dataref("Strato/777/baro_mode_knob_pos", "number")
B777DR_heading_bug_diff                = deferred_dataref("Strato/777/heading_bug_diff", "number")
B777DR_hyd_press_low_any               = deferred_dataref("Strato/777/displays/hyd_press_low_any", "number")

-- Temporary datarefs for display text until custom textures are made
B777DR_txt_TIME_TO_ALIGN               = deferred_dataref("Strato/777/displays/txt/TIME_TO_ALIGN", "string")
B777DR_txt_GS                          = deferred_dataref("Strato/777/displays/txt/GS", "string")
B777DR_txt_TAS                         = deferred_dataref("Strato/777/displays/txt/TAS", "string")
B777DR_txt_ddd                         = deferred_dataref("Strato/777/displays/txt/---", "string")
B777DR_txt_INSTANT_ADIRU_ALIGN         = deferred_dataref("Strato/777/displays/txt/INSTANT_ADIRU_ALIGN", "string")
B777DR_txt_H                           = deferred_dataref("Strato/777/displays/txt/H", "string")
B777DR_txt_REALISTIC_PRK_BRK           = deferred_dataref("Strato/777/displays/txt/REALISTIC_PRK_BRK", "string")

--*************************************************************************************--
--**                             X-PLANE COMMAND HANDLERS                            **--
--*************************************************************************************--



--*************************************************************************************--
--**                                 X-PLANE COMMANDS                                **--
--*************************************************************************************--
simCMD_dh_dn_capt                     = find_command("sim/instruments/dh_ref_down")
simCMD_dh_up_capt                     = find_command("sim/instruments/dh_ref_up")
simCMD_mda_up_capt                    = find_command("sim/instruments/mda_ref_up")
simCMD_mda_dn_capt                    = find_command("sim/instruments/mda_ref_down")

--*************************************************************************************--
--**                             CUSTOM COMMAND HANDLERS                             **--
--*************************************************************************************--

function B777_fltInst_adiru_switch_CMDhandler(phase, duration)
	if phase == 0 then
		if B777DR_ovhd_aft_button_target[1] == 1 then
			B777DR_ovhd_aft_button_target[1] = 0												-- move button to off
			if simDR_ias_capt <= 30 then run_after_time(B777_adiru_off, 2) end					-- turn adiru off
		elseif B777DR_ovhd_aft_button_target[1] == 0 then
			B777DR_ovhd_aft_button_target[1] = 1												-- move button to on
			if simDR_groundSpeed < 1 then
				B777_adiru_time_remaining_min = 60 * (5 + math.abs(simDR_latitude) / 8.182)	-- set adiru alignment time to 5 + (distance from equator / 8.182)
				B777DR_adiru_status = 1
				countdown()
			end
		end
	end
end

function B777_fltInst_adiru_align_now_CMDhandler(phase, duration)
	if phase == 0 then
		B777DR_ovhd_aft_button_target[1] = 1
		B777_align_adiru()
	end
end

function B777_alt_up_CMDhandler(phase, duration)
	if phase == 0 then
		alt_press_counter = alt_press_counter + 1
		if not is_timer_scheduled then run_after_time(checkAltSpd, 0.3) end
		if alt_is_fast == 1 or B777DR_alt_is_fast_ovrd == 1 then
			simDR_autopilot_alt = simDR_autopilot_alt + 1000
		else
			simDR_autopilot_alt = simDR_autopilot_alt + 100
		end

	elseif phase == 2 then
		simDR_autopilot_alt = simDR_autopilot_alt + 1000
	end
end

function B777_alt_dn_CMDhandler(phase, duration)
	if phase == 0 then
		alt_press_counter = alt_press_counter + 1
		if not is_timer_scheduled then run_after_time(checkAltSpd, 0.3) end
		if alt_is_fast == 1 or B777DR_alt_is_fast_ovrd == 1 then
			simDR_autopilot_alt = simDR_autopilot_alt - 1000
		else
			simDR_autopilot_alt = simDR_autopilot_alt - 100
		end
	elseif phase == 2 then
		simDR_autopilot_alt = simDR_autopilot_alt - 1000
	end
end

function B777_minimums_dn_capt_CMDhandler(phase, duration)
	if phase == 0  then
		if B777DR_minimums_mode == 0 then
			if B777DR_minimums_dh > 0 then B777DR_minimums_dh = B777DR_minimums_dh - 1 end
		else
			if B777DR_minimums_mda > -1000 then B777DR_minimums_mda = B777DR_minimums_mda - 1 end
		end
		B777DR_minimums_visible = 1
	end
end

function B777_minimums_up_capt_CMDhandler(phase, duration)
	if phase == 0  then
		if B777DR_minimums_mode == 0 then
			if B777DR_minimums_dh < 999  then B777DR_minimums_dh = B777DR_minimums_dh + 1 end
		else
			if B777DR_minimums_dh < 15000 then B777DR_minimums_mda = B777DR_minimums_mda + 1 end
		end
		B777DR_minimums_visible = 1
	end
end

function B777_minimums_rst_capt_CMDhandler(phase, duration)
	if phase == 0 then
		B777DR_minimums_visible = 0
		B777DR_amber_minimums = 0
	end
end
--*************************************************************************************--
--**                             CREATE CUSTOM COMMANDS                               **--
--*************************************************************************************--

B777CMD_fltInst_adiru_switch         = deferred_command("Strato/B777/button_switch/fltInst/adiru_switch", "ADIRU Switch", B777_fltInst_adiru_switch_CMDhandler)

B777CMD_fltInst_adiru_align_now      = deferred_command("Strato/B777/adiru_align_now", "Align ADIRU Instantly", B777_fltInst_adiru_align_now_CMDhandler)

B777CMD_ap_alt_up                    = deferred_command("Strato/B777/autopilot/alt_up", "Autopilot Altitude Up", B777_alt_up_CMDhandler)
B777CMD_ap_alt_dn                    = deferred_command("Strato/B777/autopilot/alt_dn", "Autopilot Altitude Down", B777_alt_dn_CMDhandler)

B777CMD_minimums_up                  = deferred_command("Strato/B777/minimums_up_capt", "Captain Minimums Up", B777_minimums_up_capt_CMDhandler)
B777CMD_minimums_dn                  = deferred_command("Strato/B777/minimums_dn_capt", "Captain Minimums Down", B777_minimums_dn_capt_CMDhandler)
B777CMD_minimums_rst                 = deferred_command("Strato/B777/minimums_rst_capt", "Captain Minimums Reset", B777_minimums_rst_capt_CMDhandler)

--*************************************************************************************--
--**                                      CODE                                       **--
--*************************************************************************************--

--- Clocks ----------

--- ADIRU ----------
function countdown()
	if B777DR_adiru_status == 1  then
		if B777_adiru_time_remaining_min > 1 then
			B777_adiru_time_remaining_min = B777_adiru_time_remaining_min - 1
			run_after_time(countdown2, 1)
		else
			B777_align_adiru()
		end
	end
end

function countdown2()
	B777_adiru_time_remaining_min = B777_adiru_time_remaining_min - 1
	run_after_time(countdown, 1)
end

function B777_adiru_off()
	B777DR_adiru_status = 0
	B777_adiru_time_remaining_min = 0
end

function B777_align_adiru()
	B777DR_adiru_status = 2
	B777_adiru_time_remaining_min = 0
end

function disableRAOutline()
	B777DR_outlined_RA = 0
end

function checkAltSpd()
	if alt_press_counter >= 3 then
		alt_is_fast = 1
	else
		alt_is_fast = 0
	end
	alt_press_counter = 0
end

---MINIMUMS----------

function minimums_flash_on()
	if flashCount < 6 then
		flashCount = flashCount + 1
		run_after_time(minimums_flash_off, 0.5)
	else
		flashCount = 0
		B777DR_minimums_visible = 1
	end
end

function minimums_flash_off()
	B777DR_minimums_visible = 0
	run_after_time(minimums_flash_on, 0.5)
end

function minimums()
	if B777DR_minimums_mode == 0 then
		B777DR_minimums_diff = B777DR_minimums_dh - simDR_radio_alt_capt
	else
		B777DR_minimums_diff = B777DR_minimums_mda - B777DR_displayed_alt
	end

	if simDR_vertical_speed < 0 then
		if B777DR_minimums_diff < 0 and B777DR_minimums_diff > -2 and B777DR_minimums_visible == 1 then
			minimums_flash_off()
			B777DR_amber_minimums = 1
		end
	end

	if B777DR_minimums_diff > 0 or simDR_onGround == 1 then
		B777DR_amber_minimums = 0
	end
end

---MISC----------

function setAnimations()
	B777DR_minimums_mode_knob_anim = B777_animate(B777DR_minimums_mode, B777DR_minimums_mode_knob_anim, 15)
	B777DR_baro_mode_knob_anim = B777_animate(B777DR_baro_mode, B777DR_baro_mode_knob_anim, 15)
end

function setDispAlt()
	if simDR_alt_ft_capt <= -1000 then
		B777DR_displayed_alt = -1000
	elseif simDR_alt_ft_capt >= 47000 then
		B777DR_displayed_alt = 47000
	else
		B777DR_displayed_alt = simDR_alt_ft_capt
	end
end

function setTXT()
	B777DR_txt_GS                  = "GS"
	B777DR_txt_TAS                 = "TAS"
	B777DR_txt_TIME_TO_ALIGN       = "TIME TO ALIGN"
	B777DR_txt_ddd                 = "---"
	B777DR_txt_INSTANT_ADIRU_ALIGN = "INSTANT ADIRU ALIGN"
	B777DR_txt_REALISTIC_PRK_BRK   = "REALISTIC PARK BRAKE"
end
----- ANIMATION UTILITY -----------------------------------------------------------------
function B777_animate(target, variable, speed)
	if math.abs(target - variable) < 0.1 then return target end
	variable = variable + ((target - variable) * (speed * SIM_PERIOD))
	return variable
end

--*************************************************************************************--
--**                                  EVENT CALLBACKS                                **--
--*************************************************************************************--

function aircraft_load()
	print("flightIinstruments loaded")
end

--function aircraft_unload()

function flight_start()
	B777DR_eicas_mode = 4

	if simDR_startup_running == 1 then
		B777_align_adiru()
	end

	setTXT()
end

--function flight_crash()

--function before_physics()

function after_physics()
	B777DR_displayed_com1_act_khz = simDR_com1_act_khz / 1000
	B777DR_displayed_com1_stby_khz = simDR_com1_stby_khz / 1000

	B777DR_displayed_com2_act_khz = simDR_com2_act_khz / 1000
	B777DR_displayed_com2_stby_khz = simDR_com2_stby_khz / 1000

	for i = 0, 2 do
		B777DR_fuel_lbs[i] = simDR_fuel_kgs[i] * B777_kgs_to_lbs
	end

	B777DR_fuel_lbs_total = (simDR_fuel_kgs[0] + simDR_fuel_kgs[1] + simDR_fuel_kgs[2]) * B777_kgs_to_lbs

	if simDR_vs_capt > 6000 then
		B777DR_vs_capt_indicator = 6000
	elseif simDR_vs_capt < -6000 then
		B777DR_vs_capt_indicator = -6000
	else
		B777DR_vs_capt_indicator = simDR_vs_capt
	end

	if simDR_ias_capt < 30 then
		B777DR_ias_capt_indicator = 30
	elseif simDR_ias_capt > 490 then
		B777DR_ias_capt_indicator = 490
	else
		B777DR_ias_capt_indicator = simDR_ias_capt
	end

	if (simDR_groundSpeed >= 1 or (simDR_bus_voltage[0] == 0 and simDR_bus_voltage[1] == 0)) and B777DR_adiru_status == 1 then
		stop_timer(B777_align_adiru)
		B777_adiru_off()
	end

	B777DR_adiru_time_remaining_min = string.format("%2.0f", math.floor(B777_adiru_time_remaining_min / 60)) -- %0.2f
	B777DR_adiru_time_remaining_sec = math.floor(B777_adiru_time_remaining_min / 60 % 1 * 60)

	if B777DR_adiru_status == 1 then B777DR_temp_adiru_is_aligning = 1 else B777DR_temp_adiru_is_aligning = 0 end

--	print("time remaining min/sec: "..tonumber(B777DR_adiru_time_remaining_min.."."..B777DR_adiru_time_remaining_sec))

	B777DR_airspeed_bug_diff = simDR_ap_airspeed - B777DR_ias_capt_indicator
	B777DR_autopilot_alt_mtrs_capt = simDR_autopilot_alt * B777_ft_to_mtrs

	if simDR_onGround == 1 then
		B777DR_displayed_aoa = 0
	else
		B777DR_displayed_aoa = simDR_aoa
	end

	if simDR_onGround == 0 and simDR_radio_alt_capt <= 2500 and simDR_radio_alt_capt >= 2490 and simDR_vs_capt < 0 then
		B777DR_outlined_RA = 1
		if not is_timer_scheduled(disableRAOutline) then run_after_time(disableRAOutline, 10) end
	end

	B777DR_alt_bug_diff = simDR_autopilot_alt - B777DR_displayed_alt

	B777DR_heading_bug_diff = simDR_hdg_bug - simDR_hdg

	if B777DR_nd_mode_selector < 3 then
		simDR_map_mode = B777DR_nd_mode_selector
	else
		simDR_map_mode = 4
	end

	setDispAlt()
	setAnimations()
	minimums()

	if B777DR_hyd_press[0] < 1200 or B777DR_hyd_press[1] < 1200 or B777DR_hyd_press[2] < 1200 then
		B777DR_hyd_press_low_any = 1
	else
		B777DR_hyd_press_low_any = 0
	end

end

--function after_replay()
