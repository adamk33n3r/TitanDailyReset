-- **************************************************************************
-- * TitanXP.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************

-- ******************************** Constants *******************************
local TITAN_DAILY_RESET_ID = "DailyReset";
local TITAN_DAILY_RESET_VERSION = "9.1.0-1";
local _G = getfenv(0);
local TITAN_DAILY_RESET_FREQUENCY_ELAPSED = 0;
local updateTable = {TITAN_DAILY_RESET_ID, TITAN_PANEL_UPDATE_ALL};
-- ******************************** Variables *******************************
local TitanPanelDailyResetButton_ButtonAdded = nil;
local found = nil;
local lastMobXP, lastXP, XPGain = 0, 0, 0
local L = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local DDM = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
-- ******************************** Functions *******************************

-- **************************************************************************
-- NAME : TitanPanelDailyReset_OnLoad()
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
function TitanPanelDailyResetButton_OnLoad(self)
	self.registry = { 
		id = TITAN_DAILY_RESET_ID,
		category = "Information",
		version = TITAN_DAILY_RESET_VERSION,
		menuText = "Daily Reset",
		buttonTextFunction = "TitanPanelDailyResetButton_GetButtonText",
		tooltipTitle = "Daily Reset Info",
		tooltipTextFunction = "TitanPanelDailyResetButton_GetTooltipText",
		controlVariables = {
			-- ShowColoredText = false,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			DisplayOnRightSide = false,
			UpdateInterval = 1,
		}
	};
end

function TitanPanelRightClickMenu_PrepareDailyResetMenu()
	local info

	if _G["L_UIDROPDOWNMENU_MENU_LEVEL"] == 2 then
		if _G["L_UIDROPDOWNMENU_MENU_VALUE"] == "UpdateInterval" then
			TitanPanelRightClickMenu_AddTitle("Update Interval", _G["L_UIDROPDOWNMENU_MENU_LEVEL"]);
			intervals = { 1, 5, 10, 30, 60 }
			for idx, interval in ipairs(intervals) do
				info = {}
				info.text = pluralize(interval, "second")
				info.checked = TitanGetVar(TITAN_DAILY_RESET_ID, "UpdateInterval") == interval
				info.func = function()
					TitanSetVar(TITAN_DAILY_RESET_ID, "UpdateInterval", interval)
				end
				DDM:UIDropDownMenu_AddButton(info, _G["L_UIDROPDOWNMENU_MENU_LEVEL"])
			end
		end

		return
	end

	info = {}
	info.notCheckable = true
	info.text = "Update Inverval"
	info.value = "UpdateInterval"
	info.hasArrow = 1
	DDM:UIDropDownMenu_AddButton(info)
end

-- **************************************************************************
-- NAME : TitanPanelDailyResetButton_OnUpdate(elapsed)
-- DESC : Update button data
-- VARS : elapsed = time since last update
-- **************************************************************************
function TitanPanelDailyResetButton_OnUpdate(self, elapsed)
	TITAN_DAILY_RESET_FREQUENCY_ELAPSED = TITAN_DAILY_RESET_FREQUENCY_ELAPSED - elapsed
	if TITAN_DAILY_RESET_FREQUENCY_ELAPSED <= 0 then
		TITAN_DAILY_RESET_FREQUENCY_ELAPSED = TitanGetVar(TITAN_DAILY_RESET_ID, "UpdateInterval")
		TitanPanelPluginHandle_OnUpdate(updateTable)
	end
end

function pluralize(num, str)
	return format("%d %s", num, num > 1 and str.."s" or str)
end

function getTimeNextTuesday(time)
	for i = 0, 7 do
		local checkTime = time + 24*3600*i
		if date("%A", checkTime) == "Tuesday" then
			return date("*t", checkTime)
		end
	end
end

function formatTimeLeft(timeLeft, extra)
	extra = extra or false
	local rounding = extra and 0 or 0.5
	-- Disable rounding for now
	rounding = 0
	local days = floor(timeLeft / 86400 + rounding)
	local hours = floor(mod(timeLeft, 86400) / 3600 + rounding)
	local minutes = floor(mod(timeLeft, 3600) / 60 + rounding)
	local seconds = floor(mod(timeLeft, 60))

	local timeTable = {
		{
			name = "day",
			value = days,
		}, {
			name = "hour",
			value = hours,
		}, {
			name = "minute",
			value = minutes,
		}, {
			name = "second",
			value = seconds,
		},
	}

	local formatString = ""
	for idx, unit in ipairs(timeTable) do
		if unit.value > 0 then
			if unit.name == "day" and not extra then
			end

			formatString = formatString..pluralize(unit.value, unit.name)
			if extra or unit.value == 1 then
			-- if extra then
				formatString = formatString.." and "
				extra = false
			else
				break
			end

		end
	end

	return TitanUtils_GetHighlightText(formatString)
end

function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
 end

-- **************************************************************************
-- NAME : TitanPanelDailyResetButton_GetButtonText(id)
-- DESC : Calculate time based logic for button text
-- VARS : id = button ID
-- NOTE : Because the panel gets loaded before XP we need to check whether
--        the variables have been initialized and take action if they haven't
-- **************************************************************************
function TitanPanelDailyResetButton_GetButtonText(id)
    return "Daily reset in "..formatTimeLeft(GetQuestResetTime())
end

-- **************************************************************************
-- NAME : TitanPanelDailyResetButton_GetTooltipText()
-- DESC : Display tooltip text
-- **************************************************************************
function TitanPanelDailyResetButton_GetTooltipText()
	local resetTime = GetQuestResetTime()

	-- Get's the next tuesday starting from next daily reset
	local nextTuesday = getTimeNextTuesday(time() + GetQuestResetTime())

	return "Daily reset in "..formatTimeLeft(resetTime, true).."\nWeekly reset in "..formatTimeLeft(difftime(time(nextTuesday), time()), true)
end
