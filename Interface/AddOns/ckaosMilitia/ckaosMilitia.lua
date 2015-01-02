local addonName, addon, _ = ...

local F, C = unpack(Aurora or FreeUI)
addon = CreateFrame('Frame')

--  Use this section to enable/disable specific features
-- --------------------------------------------------------
local skipBattleAnimation    = false
local showExtraMissionInfo   = false
local showRewardCounts       = false
local desaturateUnavailable  = false
local showFollowerReturnTime = false
local showRequiredResources  = false
local doubleClickToAddFollower = true
local setMissionFrameMovable = true
-- --------------------------------------------------------
-- DO NOT TOUCH ANYTHING BELOW THIS POINT!

-- GLOBALS: _G, C_Garrison, C_Timer, GameTooltip, GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage, ITEM_QUALITY_COLORS
-- GLOBALS: CreateFrame, IsAddOnLoaded, RGBTableToColorCode, HybridScrollFrame_GetOffset, GetItemInfo, BreakUpLargeNumbers, HandleModifiedItemClick
-- GLOBALS: GarrisonMissionComplete_FindAnimIndexFor, GarrisonMissionComplete_AnimRewards
-- GLOBALS: pairs, ipairs, wipe, table, strsplit, tostring, strjoin, strrep
local tinsert, tsort = table.insert, table.sort
local emptyTable = {}

local propertyOrder = {'iLevel', 'level', 'quality', 'name'}
local function SortFollowers(a, b)
	local dataA, dataB = C_Garrison.GetFollowerInfo(a), C_Garrison.GetFollowerInfo(b)
	for _, property in ipairs(propertyOrder) do
		if dataA[property] ~= dataB[property] then
			return dataA[property] < dataB[property]
		end
	end
end

local mechanics, traits = {}, {}
local abilities = {
	ability = {},
	trait = {},
}
local function ScanFollowerAbilities()
	wipe(abilities.ability)
	wipe(abilities.trait)
	for index, follower in pairs(C_Garrison.GetFollowers()) do
		if follower.isCollected then
			for abilityIndex, ability in pairs(C_Garrison.GetFollowerAbilities(follower.followerID)) do
				local dataTable, key
				-- 232: dancer counters danger zones
				if ability.isTrait and ability.id ~= 232 then
					key = ability.id
					dataTable = abilities.trait
					-- store trait info
					traits[ability.id] = traits[ability.id] or {
						icon = ability.icon,
						name = ability.name,
						description = ability.description,
					}
				else
					local mechanicID, mechanicInfo = next(ability.counters)
					key = mechanicID
					dataTable = abilities.ability
					-- store reference to info table
					mechanics[mechanicID] = mechanicInfo
				end

				if not dataTable[key] then dataTable[key] = {} end
				tinsert(dataTable[key], follower.followerID)
				tsort(dataTable[key], SortFollowers)
			end
		end
	end
	return abilities
end

local function GetMissionTimeLeft(followerID)
	for index, mission in ipairs(GarrisonMissionFrame.MissionTab.MissionList.inProgressMissions) do
		for _, missionFollowerID in ipairs(mission.followers) do
			if missionFollowerID == followerID then
				return mission.timeLeft
			end
		end
	end
end

local function ShowAbilityTooltip(self)
	local followers = self.threatID and abilities.ability[self.threatID]
	if not followers then return end

	if self.description then
		GameTooltip:AddLine(self.description, 255, 255, 255, true)
		GameTooltip:AddLine(' ')
	end

	for _, followerID in pairs(followers) do
		local data = C_Garrison.GetFollowerInfo(followerID)
		local qualityColor = RGBTableToColorCode(_G.ITEM_QUALITY_COLORS[data.quality])
		local displayLevel
		if data.level < 100 then
			-- display invisible zero to keep padding intact
			displayLevel = '|c000000000|r'..qualityColor..data.level..'|r '
		else
			displayLevel = qualityColor .. data.iLevel .. '|r '
		end
		local status, name = data.status or '', data.name
		local color  = _G.YELLOW_FONT_COLOR
		if status == _G.GARRISON_FOLLOWER_INACTIVE then
			color = _G.GRAY_FONT_COLOR
			name  = _G.GRAY_FONT_COLOR_CODE .. name .. '|r'
		elseif status == _G.GARRISON_FOLLOWER_ON_MISSION then
			color = _G.RED_FONT_COLOR
		end
		if showFollowerReturnTime and status == _G.GARRISON_FOLLOWER_ON_MISSION then
			-- follower will return from her mission
			status = GetMissionTimeLeft(followerID)
		end
		GameTooltip:AddDoubleLine(displayLevel..name, status, nil, nil, nil, color.r, color.g, color.b)
	end
	GameTooltip:Show()
end

local function GetTab(frame, index)
	local tab = addon[index]
	if not tab then
		tab = CreateFrame('CheckButton', nil, nil, 'SpellBookSkillLineTabTemplate', index)
		tab:HookScript('OnEnter', ShowAbilityTooltip)
		tab:RegisterForClicks() -- disable clicking
		tab:Show()
		local count = tab:CreateFontString(nil, nil, 'NumberFontNormalSmall')
			  count:SetFont("Interface\\AddOns\\FreeUI\\media\\PFTempestaSeven.ttf", 8, "OUTLINEMONOCHROME")
		      count:SetAllPoints()
		      count:SetJustifyH('RIGHT')
		      count:SetJustifyV('BOTTOM')
		tab.count = count
		addon[index] = tab
	end

	tab:SetParent(frame)
	tab:ClearAllPoints()
	tab:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 11, 16 - 44*index)

	
	return tab
end

local function UpdateFollowerTabs(frame)
	-- don't update for invisible frames
	if not frame or not frame:IsShown() then return end

	ScanFollowerAbilities()
	local index = 1
	for threatID, followers in pairs(abilities.ability) do
		local numAvailable, numFollowers = #followers, #followers
		for _, followerID in pairs(followers) do
			local data = C_Garrison.GetFollowerInfo(followerID)
			if data.status and data.status ~= _G.GARRISON_FOLLOWER_IN_PARTY then
				numAvailable = numAvailable - 1
				if data.status == _G.GARRISON_FOLLOWER_INACTIVE then
					-- don't count inactive followers in tab count
					numFollowers = numFollowers - 1
				end
			end
		end

		local tab = GetTab(frame, index)
		tab.threatID = threatID
		local threatInfo = mechanics[threatID]
		tab:SetNormalTexture(threatInfo.icon)
		tab.tooltip = ('|T%1$s:0|t %2$s'):format(threatInfo.icon, threatInfo.name)
		tab.description = threatInfo.description
		tab.count:SetText(numAvailable ~= numFollowers and ('%d/%d'):format(numAvailable, numFollowers) or numFollowers)
		F.CreateBG(tab)
--	F.CreateSD(tab, 5, 0, 0, 0, 1, 0)

	F.ReskinTab(tab)
		index = index + 1
	end
end

-- allow to immediately click the reward chest
local function SkipBattleAnimation(self, missionID, canComplete, success)
	self.Stage.EncountersFrame.FadeOut:Play()
	self.animIndex = GarrisonMissionComplete_FindAnimIndexFor(GarrisonMissionComplete_AnimRewards) - 1
	self.animTimeLeft = 0
end

-- add extra info to mission list for easier overview
local function UpdateMissionList()
	local self     = GarrisonMissionFrame.MissionTab.MissionList
	local active   = self.showInProgress
	local missions = active and self.inProgressMissions or self.availableMissions

	local offset  = HybridScrollFrame_GetOffset(self.listScroll)
	local buttons = self.listScroll.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		local mission = missions[i + offset]
		if button:IsShown() then
			if not button.threats then button.threats = {} end
			if active then
				-- show success chance
				local success = C_Garrison.GetRewardChance(mission.missionID)
				if not button.successChance then
					button.successChance = button:CreateFontString(nil, nil, 'GameFontHighlightLarge')
					button.successChance:SetAllPoints(button.MissionType)
				end
				button.successChance:SetText(success..'%')
				button.successChance:Show()
			elseif button.successChance then
				button.successChance:Hide()
			end

			-- show number of followers
			if not button.followers then
				button.followers = button:CreateFontString(nil, nil, 'GameFontNormal')
				button.followers:SetPoint('CENTER', button, 'TOPLEFT', 40, -16)
			end
			local icon = '|TInterface\\FriendsFrame\\UI-Toast-FriendOnlineIcon:0:0:0:0:32:32:4:26:4:26|t'
			button.followers:SetText(strrep(icon, mission.numFollowers))

			-- show required abilities
			local _, _, env, envDesc, envIcon, _, _, enemies = C_Garrison.GetMissionInfo(mission.missionID)
			local numThreats = 1
			for j = 1, #enemies do
				for threatID, threat in pairs(enemies[j].mechanics) do
					local threatButton = button.threats[numThreats]
					if not threatButton then
						threatButton = CreateFrame('Frame', nil, button, 'GarrisonMissionMechanicTemplate', numThreats)
						if numThreats == 1 then
							threatButton:SetPoint('TOPLEFT', button.Title, 'BOTTOMLEFT', 0, -2)
						else
							threatButton:SetPoint('LEFT', button.threats[numThreats-1], 'RIGHT', 8, 0)
						end
						button.threats[numThreats] = threatButton
					end
					threatButton.threatID = threatID
					threatButton.info = threat
					threatButton.Icon:SetTexture(threat.icon)
					threatButton:Show()

					-- desaturate threats we cannot counter
					if not active and desaturateUnavailable then
						local numCounters = 0
						for _, followerID in ipairs(abilities.ability[threatID] or emptyTable) do
							if C_Garrison.GetFollowerLevel(followerID) + 2 >= mission.level
								and C_Garrison.GetFollowerItemLevelAverage(followerID) + 14 >= mission.iLevel
								and not C_Garrison.GetFollowerStatus(followerID) then
								-- must have high level, high gear and be available
								numCounters = numCounters + 1
							end
						end
						-- might have used up followers for previous counters
						for prevThreatIndex = 1, numThreats - 1 do
							if button.threats[prevThreatIndex].threatID == threatID then
								numCounters = numCounters - 1
							end
						end
						threatButton.Icon:SetDesaturated(numCounters < 1)
						threatButton.Icon:SetAlpha(numCounters < 1 and 0.5 or 1)
					else
						threatButton.Icon:SetDesaturated(false)
						threatButton.Icon:SetAlpha(1)
					end

					numThreats = numThreats + 1
				end
			end
			-- move title text
			if numThreats > 1 then
				local anchorFrom, relativeTo, anchorTo, xOffset, yOffset = button.Title:GetPoint()
				button.Title:SetPoint(anchorFrom, relativeTo, anchorTo, xOffset, yOffset + 10)
			end

			if showRequiredResources and not active then
				local duration = mission.duration
				if mission.durationSeconds >= _G.GARRISON_LONG_MISSION_TIME then
					duration = _G.GARRISON_LONG_MISSION_TIME_FORMAT:format(mission.duration)
				end
				button.Summary:SetDrawLayer('OVERLAY') -- fix our icon layer
				button.Summary:SetFormattedText('(%2$s, %1$s |TInterface\\Icons\\inv_garrison_resource:0:0:0:0|t)',
					mission.cost or 0, duration)
			end

			-- hide unused threat buttons
			while button.threats[numThreats] do
				button.threats[numThreats]:Hide()
				numThreats = numThreats + 1
			end
		end
	end
end

local function GetPrettyAmount(value)
	-- mini money formatter: only handles values > 0
	value = tostring(value)
	local gold, silver, copper = value:sub(1, -5), value:sub(-4, -3), value:sub(-2, -1)
	      gold, silver, copper = (gold or 0)*1, (silver or 0)*1, (copper or 0)*1
	local stringFormat = strjoin('',
		gold > 0 and '%1$s' or '', gold > 0 and '|cffffd700g|r' or '',
		silver > 0 and '%2$02d' or '', silver > 0 and '|cffc7c7cfs|r' or '',
		copper > 0 and '%3$02d' or '', copper > 0 and '|cffeda55fc|r' or '')
	return (stringFormat):format(gold, silver, copper)
end

local function OnRewardClick(self, btn, up)
	HandleModifiedItemClick(self.link)
end

-- show reward counts
local function UpdateMissionRewards(self, rewards, numRewards)
	if numRewards <= 0 then return end
	local index = 1
	for id, reward in pairs(rewards) do
		local button = self.Rewards[index]
		local quantity = reward.quantity or reward.followerXP
		if not reward.itemID then
			if reward.currencyID == 0 then
				-- gold coin reward
				quantity = GetPrettyAmount(quantity)
			else
				-- garrison resources/apexis shards/followerXP/playerXP
				quantity = BreakUpLargeNumbers(quantity)
			end
		elseif reward.quantity == 1 then
			-- show item level
			local _, link, quality, iLevel = GetItemInfo(reward.itemID)
			if iLevel and iLevel > 1 then
				quantity = ITEM_QUALITY_COLORS[quality or _G.LE_ITEM_QUALITY_COMMON].hex .. iLevel .. '|r'
			end
		end
		if quantity and quantity ~= 1 then
			button.Quantity:Show()
			button.Quantity:SetText(quantity)
		end
		index = index + 1
	end
end

addon:SetScript('OnEvent', function(self, event, ...)
	if self[event] then self[event](self, event, ...) end
end)

addon:RegisterEvent('GARRISON_MISSION_NPC_OPENED')
function addon:GARRISON_MISSION_NPC_OPENED()
	UpdateFollowerTabs(GarrisonMissionFrame)
end
addon:RegisterEvent('GARRISON_RECRUITMENT_NPC_OPENED')
function addon:GARRISON_RECRUITMENT_NPC_OPENED()
	UpdateFollowerTabs(GarrisonRecruiterFrame)
end
addon:RegisterEvent('GARRISON_SHOW_LANDING_PAGE')
function addon:GARRISON_SHOW_LANDING_PAGE()
	UpdateFollowerTabs(GarrisonLandingPage)
end
addon:RegisterEvent('GARRISON_FOLLOWER_LIST_UPDATE')
function addon:GARRISON_FOLLOWER_LIST_UPDATE()
	for _, frame in pairs({GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage}) do
		UpdateFollowerTabs(frame)
	end
end

if skipBattleAnimation then
	hooksecurefunc('GarrisonMissionComplete_OnMissionCompleteResponse', SkipBattleAnimation)
end
if showExtraMissionInfo then
	hooksecurefunc('GarrisonMissionList_Update', UpdateMissionList)
	hooksecurefunc(GarrisonMissionFrame.MissionTab.MissionList.listScroll, 'update', UpdateMissionList)
	GarrisonMissionFrame.MissionTab.MissionPage.CloseButton:HookScript('OnClick', UpdateMissionList)
end
if showRewardCounts then
	hooksecurefunc('GarrisonMissionButton_SetRewards', UpdateMissionRewards)
end
-- if doubleClickToAddFollower then
-- 	for index, button in ipairs(GarrisonMissionFrame.FollowerList.listScroll.buttons) do
-- 		button:HookScript('OnDoubleClick', function(self, btn)
-- 			if GarrisonMissionFrame.selectedTab ~= 1 then return end
-- 			-- collapse button
-- 			self:GetScript('OnClick')(self, btn)

-- 			-- add to mission
-- 			local info = C_Garrison.GetFollowerInfo(self.id)
-- 			if info.status == GARRISON_FOLLOWER_IN_PARTY then
-- 				local missionID = GarrisonMissionFrame.MissionTab.MissionPage.missionInfo.missionID
-- 				C_Garrison.RemoveFollowerFromMission(missionID, self.id)
-- 			elseif not info.status then
-- 				-- cannot add inactive/on mission/... followers
-- 				GarrisonMissionPage_AddFollower(self.id)
-- 			end
-- 			GarrisonMissionPage_UpdateParty()
-- 		end)
-- 	end
-- end
-- if setMissionFrameMovable then
-- 	local frame = GarrisonMissionFrame
-- 	      frame:SetMovable(true)
-- 	frame:CreateTitleRegion():SetAllPoints(frame.TopBorder)
-- end

-- initialize on the currently shown frame
ScanFollowerAbilities()
C_Timer.After(0.1, addon.GARRISON_FOLLOWER_LIST_UPDATE)
