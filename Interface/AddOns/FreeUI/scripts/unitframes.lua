local F, C, L = unpack(select(2, ...))

if not C.unitframes.enable then return end

local parent, ns = ...
local oUF = ns.oUF

local locale = GetLocale()
local Font_UF
local Font_UF_Size
local Font_UF_Flag

if C.appearance.fontUseAlternativeFont then
	Font_UF_Flag = "OUTLINE"
else
	Font_UF_Flag = 'OUTLINEMONOCHROME'
end

if C.appearance.fontUseAlternativeFont then
	Font_UF = C.media.font2
else
	Font_UF = 'Fonts\\Zpix.ttf'
end

if C.appearance.fontUseAlternativeFont then
	Font_UF_Size = 12
else
	Font_UF_Size = 8
end

local name = UnitName("player")
local realm = GetRealmName()
local class = select(2, UnitClass("player"))

-- local colors = setmetatable({
-- 	power = setmetatable({
-- 		["MANA"] = {.9, .9, .9},
-- 		["RAGE"] = {.9, .1, .1},
-- 		["FUEL"] = {0, 0.55, 0.5},
-- 		["FOCUS"] = {.9, .5, .1},
-- 		["ENERGY"] = {.9, .9, .1},
-- 		["AMMOSLOT"] = {0.8, 0.6, 0},
-- 		["RUNIC_POWER"] = {.1, .9, .9},
-- 		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
-- 		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
-- 	}, {__index = oUF.colors.power}),
-- }, {__index = oUF.colors})

oUF.colors.power['MANA'] = {0.37, 0.6, 1}
oUF.colors.power['RAGE']  = {0.9,  0.3,  0.23}
oUF.colors.power['FOCUS']  = {1, 0.81,  0.27}
oUF.colors.power['RUNIC_POWER']  = {0, 0.81, 1}
oUF.colors.power['AMMOSLOT'] = {0.78,1, 0.78}
oUF.colors.power['FUEL'] = {0.9,  0.3,  0.23}
oUF.colors.power['POWER_TYPE_STEAM'] = {0.55, 0.57, 0.61}
oUF.colors.power['POWER_TYPE_PYRITE'] = {0.60, 0.09, 0.17}
oUF.colors.power['POWER_TYPE_HEAT'] = {0.55,0.57,0.61}
oUF.colors.power['POWER_TYPE_OOZE'] = {0.76,1,0}
oUF.colors.power['POWER_TYPE_BLOOD_POWER'] = {0.7,0,1}

local powerHeight = C.unitframes.power_height
local altPowerHeight = C.unitframes.altpower_height
local playerWidth = C.unitframes.player_width
local playerHeight = C.unitframes.player_height
local targetWidth = C.unitframes.target_width
local targetHeight = C.unitframes.target_height
local targettargetWidth = C.unitframes.targettarget_width
local targettargetHeight = C.unitframes.targettarget_height
local focusWidth = C.unitframes.focus_width
local focusHeight = C.unitframes.focus_height
local focustargetWidth = C.unitframes.focustarget_width
local focustargetHeight = C.unitframes.focustarget_height
local petWidth = C.unitframes.pet_width
local petHeight = C.unitframes.pet_height
local bossWidth = C.unitframes.boss_width
local bossHeight = C.unitframes.boss_height
local arenaWidth = C.unitframes.arena_width
local arenaHeight = C.unitframes.arena_height
local partyWidth = C.unitframes.party_width
local partyHeight = C.unitframes.party_height
local partyWidthHealer = C.unitframes.party_width_healer
local partyHeightHealer = C.unitframes.party_height_healer
local raidWidth = C.unitframes.raid_width
local raidHeight = C.unitframes.raid_height

-- [[ Initialize / load layout option ]]

-- this can't use the normal options system
-- because we want users to be able to switch layout using /commands even when options gui is disabled
local addonLoaded
addonLoaded = function(_, addon)
	if addon ~= "FreeUI" then return end

	F.UnregisterEvent("ADDON_LOADED", addonLoaded)
	addonLoaded = nil
end

F.RegisterEvent("ADDON_LOADED", addonLoaded)

--[[ Short values ]]

local siValue = function(val)
	if(val >= 1e6) then
		return format("%.2fm", val * 0.000001)
	elseif(val >= 1e4) then
		return format("%.1fk", val * 0.001)
	else
		return val
	end
end

local function hex(r, g, b)
    if not r then return '|cffFFFFFF' end
    if(type(r) == 'table') then
        if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
    end
    return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

-- [[ Smooth ]]

local smoothing = {}
local function Smooth(self, value)
	local _, max = self:GetMinMaxValues()
	if value == self:GetValue() or (self._max and self._max ~= max) then
		smoothing[self] = nil
		self:SetValue_(value)
	else
		smoothing[self] = value
	end
	self._max = max
end

local function SmoothBar(bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = Smooth
end

local smoother, min, max = CreateFrame('Frame'), math.min, math.max
smoother:SetScript('OnUpdate', function()
	local rate = GetFramerate()
	local limit = 30/rate
	for bar, value in pairs(smoothing) do
		local cur = bar:GetValue()
		local new = cur + min((value-cur)/3, max(value-cur, limit))
		if new ~= new then
			-- Mad hax to prevent QNAN.
			new = value
		end
		bar:SetValue_(new)
		if cur == value or abs(new - value) < 2 then
			bar:SetValue_(value)
			smoothing[bar] = nil
		end
	end
end)

-- [[ Update resurrection/selection name colour ]]

local updateNameColour = function(self, unit)
	if UnitIsUnit(unit, "target") then
		self.Text:SetTextColor(.1, .7, 1)
	elseif UnitIsDead(unit) then
		self.Text:SetTextColor(.6, .6, .6)
	else
		self.Text:SetTextColor(1, 1, 1)
	end
end

-- to use on child frame
local updateNameColourAlt = function(self)
	local frame = self:GetParent()
	if frame.unit then
		if UnitIsUnit(frame.unit, "target") then
			frame.Text:SetTextColor(.1, .7, 1)
		elseif UnitIsDead(frame.unit) then
			frame.Text:SetTextColor(.6, .6, .6)
		else
			frame.Text:SetTextColor(1, 1, 1)
		end
	else
		frame.Text:SetTextColor(1, 1, 1)
	end
end

--[[ Tags ]]

oUF.Tags.Methods['free:playerHealth'] = function(unit)
	if UnitIsDead(unit) or UnitIsGhost(unit) then return end

	return siValue(UnitHealth(unit))
end
oUF.Tags.Events['free:playerHealth'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['free:health'] = function(unit)
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)

	return format("|cffffffff%s|r %.0f", siValue(min), (min/max)*100)
end
oUF.Tags.Events['free:health'] = oUF.Tags.Events.missinghp

-- boss health requires frequent updates to work
oUF.Tags.Methods['free:bosshealth'] = function(unit)
	local val = oUF.Tags.Methods['free:health'](unit)
	return val or ""
end
oUF.Tags.Events['free:bosshealth'] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_TARGETABLE_CHANGED"

--------------------------- utf8 short string ---------------------------------
local function usub(str, len)
    local i = 1
    local n = 0
    while true do
        local b,e = string.find(str, "([%z\1-\127\194-\244][\128-\191]*)", i)
        if(b == nil) then
            return str
        end
        i = e + 1
        n = n + 1
        if(n > len) then
            local r = string.sub(str, 1, b-1)
            return r
        end
    end
end

local function getSummary(str)
    local t = string.gsub(str, "<.->", "")
    return usub(t, 100, "...")
end

local function shortName(unit)
	local name = UnitName(unit)
	if name and name:len() > 4 then name = usub(name, 4) end

	return name
end

oUF.Tags.Methods['free:name'] = function(unit)
	if not UnitIsConnected(unit) then
		return "Off"
	elseif UnitIsDead(unit) then
		return "Dead"
	elseif UnitIsGhost(unit) then
		return "Ghost"
	else
		return shortName(unit)
	end
end
oUF.Tags.Events['free:name'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['free:missinghealth'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)

	if not UnitIsConnected(unit) then
		return "Off"
	elseif UnitIsDead(unit) then
		return "Dead"
	elseif UnitIsGhost(unit) then
		return "Ghost"
	elseif min ~= max then
		return siValue(max-min)
	else
		return shortName(unit)
	end
end
oUF.Tags.Events['free:missinghealth'] = oUF.Tags.Events.missinghp

-- show demonic fury value for demolock
oUF.Tags.Methods['free:demofury'] = function(unit)
	local spec = GetSpecialization()
	local fury = UnitPower('player', SPELL_POWER_DEMONIC_FURY)
	if class == 'WARLOCK' and spec == SPEC_WARLOCK_DEMONOLOGY then
		local r, g, b = 0.9, 0.37, 0.37
		return hex(r, g, b)..siValue(fury)
	else
		return nil
	end
end
oUF.Tags.Events['free:demofury'] = 'UNIT_POWER PLAYER_SPECIALIZATION_CHANGED PLAYER_TALENT_UPDATE UNIT_HEALTH UNIT_CONNECTION'

oUF.Tags.Methods['free:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min)
end
oUF.Tags.Events['free:power'] = oUF.Tags.Events.missingpp

--[[ Update health ]]

local PostUpdateHealth = function(Health, unit, min, max)
	local self = Health:GetParent()
	local r, g, b
	local reaction = C.reactioncolours[UnitReaction(unit, "player") or 5]

	local offline = not UnitIsConnected(unit)
	local tapped = not UnitPlayerControlled(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit)

	if tapped or offline then
		r, g, b = .6, .6, .6
	elseif unit == "pet" then
		local _, class = UnitClass("player")
		r, g, b = C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if class then r, g, b = C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b else r, g, b = 1, 1, 1 end
	elseif unit:find("boss%d") then
		r, g, b = self.ColorGradient(min, max, unpack(self.colors.smooth))
	else
		r, g, b = unpack(reaction)
	end

	if unit == "target" or unit:find("arena") then
		Health.value:SetTextColor(unpack(reaction))
	end

	if not C.unitframes.healerClasscolours then
		if offline or UnitIsDead(unit) or UnitIsGhost(unit) then
			self.Healthdef:Hide()
		else
			self.Healthdef:SetMinMaxValues(0, max)
			self.Healthdef:SetValue(max-min)
	--		self.Healthdef:GetStatusBarTexture():SetVertexColor(self.ColorGradient(min, max, unpack(self.colors.smooth)))
			self.Healthdef:GetStatusBarTexture():SetVertexColor(r, g, b)	-- 掉血用职业染色！
			self.Healthdef:Show()
		end

		self.Power:SetStatusBarColor(r, g, b)
		self.Power.bg:SetVertexColor(r/2, g/2, b/2)

		if tapped or offline then
			self.gradient:SetGradientAlpha("VERTICAL", .6, .6, .6, .6, .4, .4, .4, .6)
		else
			self.gradient:SetGradientAlpha("VERTICAL", .3, .3, .3, .6, .1, .1, .1, .6)
		end

		if self.Text then
			updateNameColour(self, unit)
		end
	else
		if UnitIsDead(unit) or UnitIsGhost(unit) then
			Health:SetValue(0)
		end
		Health:GetStatusBarTexture():SetGradient("VERTICAL", r, g, b, r/2, g/2, b/2)
	end
end

--[[ Hide Blizz frames ]]

if IsAddOnLoaded("Blizzard_CompactRaidFrames") then
	CompactRaidFrameManager:SetParent(FreeUIHider)
	CompactUnitFrameProfiles:UnregisterAllEvents()
end

for i = 1, MAX_PARTY_MEMBERS do
	local pet = "PartyMemberFrame"..i.."PetFrame"

	_G[pet]:SetParent(FreeUIHider)
	_G[pet.."HealthBar"]:UnregisterAllEvents()
end

--[[ Debuff highlight ]]

local PostUpdateIcon = function(_, unit, icon, index, _, filter)
	local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)
	if icon.isDebuff and dtype and UnitIsFriend("player", unit) then
		local color = DebuffTypeColor[dtype]
		icon.bg:SetVertexColor(color.r, color.g, color.b)
	else
		icon.bg:SetVertexColor(0, 0, 0)
	end
end

--[[ Update power value ]]

local PostUpdatePower = function(Power, unit, cur, max, min)
	local Health = Power:GetParent().Health
	if max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then
		Power:SetValue(0)
	end

	if Power.Text then
		Power.Text:SetTextColor(Power:GetStatusBarColor())
	end
end

-- [[ Threat update (party) ]]

local UpdateThreat = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local threat = self.Threat

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	if(status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
		self.bd:SetBackdropBorderColor(r, g, b)
	else
		self.bd:SetBackdropBorderColor(0, 0, 0)
	end
end

--[[ Global ]]

local Shared = function(self, unit, isSingle)
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks("AnyUp")

	local bd = CreateFrame("Frame", nil, self)
	bd:SetPoint("TOPLEFT", -1, 1)
	bd:SetPoint("BOTTOMRIGHT", 1, -1)
	bd:SetFrameStrata("BACKGROUND")

	F.CreateSD(bd, 5, 0, 0, 0, .8, -2)

	self.bd = bd


	--[[ Health ]]

	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetFrameStrata("LOW")
	Health:SetStatusBarTexture(C.media.texture)
	Health:SetStatusBarColor(0, 0, 0, 0)

	Health.frequentUpdates = true
	SmoothBar(Health)

	Health:SetPoint("TOP")
	Health:SetPoint("LEFT")
	Health:SetPoint("RIGHT")
	Health:SetPoint("BOTTOM", 0, 1 + powerHeight)

	self.Health = Health

	--[[ Gradient ]]

	if not C.unitframes.healerClasscolours then
		local gradient = Health:CreateTexture(nil, "BACKGROUND")
		gradient:SetPoint("TOPLEFT")
		gradient:SetPoint("BOTTOMRIGHT")
		gradient:SetTexture(C.media.backdrop)
		gradient:SetGradientAlpha("VERTICAL", .3, .3, .3, .6, .1, .1, .1, .6)

		self.gradient = gradient

		F.CreateBD(bd, 0)
	else
		F.CreateBD(bd)
	end

	--[[ Health deficit colour ]]

	if not C.unitframes.healerClasscolours then
		local Healthdef = CreateFrame("StatusBar", nil, self)
		Healthdef:SetFrameStrata("LOW")
		Healthdef:SetAllPoints(Health)
		Healthdef:SetStatusBarTexture(C.media.texture)
		Healthdef:SetStatusBarColor(1, 1, 1)

		Healthdef:SetReverseFill(true)
		SmoothBar(Healthdef)

		self.Healthdef = Healthdef
	end

	--[[ Power ]]

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetStatusBarTexture(C.media.texture)

	Power.frequentUpdates = true
	SmoothBar(Power)

	Power:SetHeight(powerHeight)

	Power:SetPoint("LEFT")
	Power:SetPoint("RIGHT")
	Power:SetPoint("TOP", Health, "BOTTOM", 0, -1)

	self.Power = Power

	local Powertex = Power:CreateTexture(nil, "OVERLAY")
	Powertex:SetHeight(1)
	Powertex:SetPoint("TOPLEFT", 0, 1)
	Powertex:SetPoint("TOPRIGHT", 0, 1)
	Powertex:SetTexture(C.media.backdrop)
	Powertex:SetVertexColor(0, 0, 0)

	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetHeight(powerHeight)
	Power.bg:SetPoint("LEFT")
	Power.bg:SetPoint("RIGHT")
	Power.bg:SetTexture(C.media.backdrop)
	Power.bg:SetVertexColor(0, 0, 0, .5)

	-- Colour power by power type. Because this is brighter, make the background darker for contrast.
	if C.unitframes.healerClasscolours then
		Power.colorPower = true
		Power.bg:SetVertexColor(0, 0, 0, .25)
	end

	--[[ Alt Power ]]

	if unit == "player" or unit == "pet" then
		local AltPowerBar = CreateFrame("StatusBar", nil, self)
		AltPowerBar:SetWidth(playerWidth)
		AltPowerBar:SetHeight(altPowerHeight)
		AltPowerBar:SetStatusBarTexture(C.media.texture)
		AltPowerBar:SetPoint("BOTTOM", oUF_FreePlayer, 0, -2)

		local abd = CreateFrame("Frame", nil, AltPowerBar)
		abd:SetPoint("TOPLEFT", -1, 1)
		abd:SetPoint("BOTTOMRIGHT", 1, -1)
		abd:SetFrameLevel(AltPowerBar:GetFrameLevel()-1)
		F.CreateBD(abd)

		AltPowerBar.Text = F.CreateFS(AltPowerBar, C.FONT_SIZE_NORMAL, "RIGHT")
		AltPowerBar.Text:SetPoint("BOTTOM", oUF_FreePlayer, "TOP", 0, 3)

		AltPowerBar:SetScript("OnValueChanged", function(_, value)
			local min, max = AltPowerBar:GetMinMaxValues()
			local r, g, b = self.ColorGradient(value, max, unpack(self.colors.smooth))
			AltPowerBar:SetStatusBarColor(r, g, b)
			AltPowerBar.Text:SetTextColor(r, g, b)
		end)

		AltPowerBar.PostUpdate = function(_, _, cur)
			AltPowerBar.Text:SetText(cur)
		end

		SmoothBar(AltPowerBar)

		AltPowerBar:EnableMouse(true)

		self.AltPowerBar = AltPowerBar
	end

	--[[ Castbar ]]

	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(C.media.backdrop)
	Castbar:SetStatusBarColor(0, 0, 0, 0)

	local Spark = Castbar:CreateTexture(nil, "OVERLAY")
	Spark:SetBlendMode("ADD")
	Spark:SetWidth(16)
	Castbar.Spark = Spark

	self.Castbar = Castbar

	local PostCastStart = function(Castbar, unit, spell, spellrank)
		if self.Iconbg then
			if Castbar.interrupt and (unit=="target" or unit:find("boss%d")) then
				self.Iconbg:SetVertexColor(1, 0, 0)
			else
				self.Iconbg:SetVertexColor(0, 0, 0)
			end
		end
	end

	local PostCastStop = function(Castbar, unit)
		if Castbar.Text then Castbar.Text:SetText("") end
	end

	local PostCastStopUpdate = function(self, event, unit)
		if(unit ~= self.unit) then return end
		return PostCastStop(self.Castbar, unit)
	end

	self:RegisterEvent("UNIT_NAME_UPDATE", PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

	-- [[ Heal prediction ]]

	local mhpb = self:CreateTexture()
	mhpb:SetTexture(C.media.texture)
	mhpb:SetVertexColor(0, .5, 1)

	local ohpb = self:CreateTexture()
	ohpb:SetTexture(C.media.texture)
	ohpb:SetVertexColor(.5, 0, 1)

	self.HealPrediction = {
		-- status bar to show my incoming heals
		myBar = mhpb,
		otherBar = ohpb,
		maxOverflow = 1,
		frequentUpdates = true,
	}

	if C.unitframes.absorb then
		local absorbBar = self:CreateTexture()
		absorbBar:SetTexture(C.media.texture)
		absorbBar:SetVertexColor(.8, .34, .8)

		local overAbsorbGlow = self:CreateTexture(nil, "OVERLAY")
		overAbsorbGlow:SetWidth(16)
		overAbsorbGlow:SetBlendMode("ADD")
		overAbsorbGlow:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", -7, 0)
		overAbsorbGlow:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", -7, 0)

		self.HealPrediction["absorbBar"] = absorbBar
		self.HealPrediction["overAbsorbGlow"] = overAbsorbGlow
	end

	-- [[ Raid target icons ]]

	local RaidIcon = self:CreateTexture()
	RaidIcon:SetSize(16, 16)
	RaidIcon:SetPoint("RIGHT", self, "LEFT", -3, 0)

	self.RaidIcon = RaidIcon

	-- [[ SpellRange ]]
	self.SpellRange = {
	    insideAlpha = 1,
        outsideAlpha = .4}

	-- [[ Counter bar ]]

	if unit == "player" or unit == "pet" then
		local CounterBar = CreateFrame("StatusBar", nil, self)
		CounterBar:SetWidth(playerWidth)
		CounterBar:SetHeight(16)
		CounterBar:SetStatusBarTexture(C.media.texture)
		CounterBar:SetPoint("TOP", UIParent, "TOP", 0, -100)

		local cbd = CreateFrame("Frame", nil, CounterBar)
		cbd:SetPoint("TOPLEFT", -1, 1)
		cbd:SetPoint("BOTTOMRIGHT", 1, -1)
		cbd:SetFrameLevel(CounterBar:GetFrameLevel()-1)
		F.CreateBD(cbd)

		CounterBar.Text = F.CreateFS(CounterBar)
		CounterBar.Text:SetPoint("CENTER")

		local r, g, b
		local max

		CounterBar:SetScript("OnValueChanged", function(_, value)
			_, max = CounterBar:GetMinMaxValues()
			r, g, b = self.ColorGradient(value, max, unpack(self.colors.smooth))
			CounterBar:SetStatusBarColor(r, g, b)

			CounterBar.Text:SetText(floor(value))
		end)

		self.CounterBar = CounterBar
	end

	--[[ Set up the layout ]]

	self.colors = colors

	self.disallowVehicleSwap = true

	if(isSingle) then
		if unit == "player" then
			self:SetSize(playerWidth, playerHeight)
		elseif unit == "target" then
			self:SetSize(targetWidth, targetHeight)
		elseif unit == "targettarget" then
			self:SetSize(targettargetWidth, targettargetHeight)
		elseif unit:find("arena%d") then
			self:SetSize(arenaWidth, arenaHeight)
		elseif unit == "focus" then
			self:SetSize(focusWidth, focusHeight)
		elseif unit == "focustarget" then
			self:SetSize(focustargetWidth, focustargetHeight)
		elseif unit == "pet" then
			self:SetSize(petWidth, petHeight)
		elseif unit and unit:find("boss%d") then
			self:SetSize(bossWidth, bossHeight)
		end
	end

	Castbar.PostChannelStart = PostCastStart
	Castbar.PostCastStart = PostCastStart

	Castbar.PostCastStop = PostCastStop
	Castbar.PostChannelStop = PostCastStop

	Health.PostUpdate = PostUpdateHealth
	Power.PostUpdate = PostUpdatePower
end

-- [[ Unit specific functions ]]

local UnitSpecific = {
	pet = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(petHeight - powerHeight - 1)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		local Name = F.CreateFS(self, 8)
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 1)
		Name:SetWidth(80)
		Name:SetHeight(12)
		Name:SetJustifyH"LEFT"
		Name:SetTextColor(1, 1, 1)

		self:Tag(Name, '[name]')
		self.Name = Name
	end,

	player = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		-- Health and power

		Health:SetHeight(playerHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "LEFT")
		HealthPoints:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, 3)
		self:Tag(HealthPoints, '[dead][offline][free:playerHealth]')
		Health.value = HealthPoints

		local PowerText = F.CreateFS(Power, C.FONT_SIZE_NORMAL, "RIGHT")
		PowerText:SetPoint("BOTTOMRIGHT", Health, "TOPRIGHT", 0, 3)
		if powerType ~= 0 then PowerText.frequentUpdates = .1 end
		local spec = GetSpecialization()
		local fury = UnitPower('player', SPELL_POWER_DEMONIC_FURY)
		if class == 'WARLOCK' and spec == SPEC_WARLOCK_DEMONOLOGY then
			self:Tag(PowerText, '[free:demofury]')
		else
			self:Tag(PowerText, '[free:power]')
		end
		Power.Text = PowerText

		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:Hide()

		-- Cast bar

		if C.unitframes.castbar then
			Castbar.Width = self:GetWidth()
			Spark:SetHeight(self.Health:GetHeight())
			Castbar.Text = F.CreateFS(Castbar)
			if locale == "zhCN" then
				Castbar.Text:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
			end
			Castbar.Text:SetDrawLayer("ARTWORK")

			local IconFrame = CreateFrame("Frame", nil, Castbar)

			local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
			Icon:SetAllPoints(IconFrame)
			Icon:SetTexCoord(.08, .92, .08, .92)

			F.CreateSD(IconFrame, 5, 0, 0, 0, .8, -1)

			Castbar.Icon = Icon

			self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
			self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
			self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
			self.Iconbg:SetTexture(C.media.backdrop)

			Castbar:SetStatusBarTexture(C.media.texture)
			Castbar:SetStatusBarColor(unpack(C.class))
			Castbar:SetWidth(self:GetWidth())
			Castbar:SetHeight(self:GetHeight())
			Castbar:SetPoint(unpack(C.unitframes.player_castbar))
			Castbar.Text:SetAllPoints(Castbar)
			local sf = Castbar:CreateTexture(nil, "OVERLAY")
			sf:SetVertexColor(.5, .5, .5, .5)
			Castbar.SafeZone = sf
			IconFrame:SetPoint("RIGHT", Castbar, "LEFT", -10, 0)
			IconFrame:SetSize(22, 22)

			local bg = CreateFrame("Frame", nil, Castbar)
			bg:SetPoint("TOPLEFT", -1, 1)
			bg:SetPoint("BOTTOMRIGHT", 1, -1)
			bg:SetFrameLevel(Castbar:GetFrameLevel()-1)
			F.CreateBD(bg)
			F.CreateSD(bg, 5, 0, 0, 0, .8, -2)
		end

		-- PVP

		if C.unitframes.pvp then
			local PvP = F.CreateFS(self)
			PvP:SetPoint("BOTTOMRIGHT", Health, "TOPRIGHT", -50, 3)
			PvP:SetText("P")

			local UpdatePvP = function(self, event, unit)
				if(unit ~= self.unit) then return end

				local pvp = self.PvP

				local factionGroup = UnitFactionGroup(unit)
				if(UnitIsPVPFreeForAll(unit) or (factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(unit))) then
					if factionGroup == "Alliance" then
						PvP:SetTextColor(0, 0.68, 0.94)
					else
						PvP:SetTextColor(1, 0, 0)
					end

					pvp:Show()
				else
					pvp:Hide()
				end
			end

			self.PvP = PvP
			PvP.Override = UpdatePvP
		end

		-- Debuffs

		-- We position these later on
		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs.initialAnchor = "TOPRIGHT"
		Debuffs["growth-x"] = "LEFT"
		Debuffs["growth-y"] = "DOWN"
		Debuffs['spacing-x'] = 3
		Debuffs['spacing-y'] = 3

		Debuffs:SetHeight(60)
		Debuffs:SetWidth(playerWidth)
		Debuffs.num = C.unitframes.num_player_debuffs
		Debuffs.size = 18

		self.Debuffs = Debuffs
		Debuffs.PostUpdateIcon = PostUpdateIcon

		-- Class specific

		if class == "DEATHKNIGHT" and C.classmod.deathknight then
			local runes = CreateFrame("Frame", nil, self)
			runes:SetWidth(playerWidth)
			runes:SetHeight(2)
			runes:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			-- local rbd = CreateFrame("Frame", nil, runes)
			-- rbd:SetBackdrop({
			-- 	edgeFile = C.media.backdrop,
			-- 	edgeSize = 1,
			-- })
			-- rbd:SetBackdropBorderColor(0, 0, 0)
			-- rbd:SetPoint("TOPLEFT", -1, 1)
			-- rbd:SetPoint("BOTTOMRIGHT", 1, -1)
			F.CreateBDFrame(runes)

			for i = 1, 6 do
				runes[i] = CreateFrame("StatusBar", nil, self)
				runes[i]:SetHeight(2)
				runes[i]:SetStatusBarTexture(C.media.texture)
				runes[i]:SetStatusBarColor(0 ,0 ,0, 1)

				local rbd = CreateFrame("Frame", nil, runes[i])
				rbd:SetBackdrop({
					edgeFile = C.media.backdrop,
					edgeSize = 1,
				})
				rbd:SetBackdropBorderColor(0, 0, 0)
				rbd:SetPoint("TOPLEFT", runes[i], -1, 1)
				rbd:SetPoint("BOTTOMRIGHT", runes[i], 1, -1)

				if i == 1 then
					runes[i]:SetPoint("LEFT", runes)
					runes[i]:SetWidth(playerWidth/6)
				else
					runes[i]:SetPoint("LEFT", runes[i-1], "RIGHT", 1, 0)
					runes[i]:SetWidth((playerWidth/6)-1)
				end
			end

			self.Runes = runes
			self.SpecialPowerBar = runes
		elseif class == "DRUID" and (C.classmod.druidEclipse or C.classmod.druidMana) then
			local druidMana, eclipseBar

			local function moveDebuffAnchors()
				if (druidMana and druidMana:IsShown()) or (eclipseBar and eclipseBar:IsShown()) then
					local offset
					if (druidMana and druidMana:IsShown()) then
						offset = 1
					else
						offset = 2
					end
					if self.AltPowerBar:IsShown() then
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(7 + offset + altPowerHeight))
					else
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(6 + offset))
					end
				else
					if self.AltPowerBar:IsShown() then
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(4 + altPowerHeight))
					else
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
					end
				end
			end
			if C.classmod.druidMana then
				druidMana = CreateFrame("StatusBar", nil, self)
				druidMana:SetStatusBarTexture(C.media.backdrop)
				druidMana:SetStatusBarColor(0, 0.76, 1)
				druidMana:SetSize(playerWidth, 1)
				druidMana:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

				F.CreateBDFrame(druidMana, .25)

				self.DruidMana = druidMana

				druidMana.PostUpdate = moveDebuffAnchors
			end

			if C.classmod.druidEclipse then
				eclipseBar = CreateFrame("Frame", nil, self)
				eclipseBar:SetWidth(playerWidth)
				eclipseBar:SetHeight(2)
				eclipseBar:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

				F.CreateBDFrame(eclipseBar, .25)

				local glow = CreateFrame("Frame", nil, eclipseBar)
				glow:SetBackdrop({
					edgeFile = C.media.glow,
					edgeSize = 5,
				})
				glow:SetPoint("TOPLEFT", -6, 6)
				glow:SetPoint("BOTTOMRIGHT", 6, -6)

				local LunarBar = CreateFrame("StatusBar", nil, eclipseBar)
				LunarBar:SetPoint("LEFT", eclipseBar, "LEFT")
				LunarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
				LunarBar:SetStatusBarTexture(C.media.texture)
				LunarBar:SetStatusBarColor(.80, .82, .60)
				eclipseBar.LunarBar = LunarBar

				SmoothBar(LunarBar)

				local SolarBar = CreateFrame("StatusBar", nil, eclipseBar)
				SolarBar:SetPoint("LEFT", LunarBar:GetStatusBarTexture(), "RIGHT")
				SolarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
				SolarBar:SetStatusBarTexture(C.media.texture)
				SolarBar:SetStatusBarColor(.30, .52, .90)
				eclipseBar.SolarBar = SolarBar

				SmoothBar(SolarBar)

				local spark = SolarBar:CreateTexture(nil, "OVERLAY")
				spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
				spark:SetBlendMode("ADD")
				spark:SetHeight(4)
				spark:SetPoint("CENTER", SolarBar:GetStatusBarTexture(), "LEFT")

				local eclipseBarText = F.CreateFS(eclipseBar, 24)
				eclipseBarText:SetPoint("LEFT", self, "RIGHT", 10, 0)
				eclipseBarText:Hide()

				self.EclipseBar = eclipseBar

				eclipseBar:RegisterEvent("PLAYER_REGEN_ENABLED")
				eclipseBar:RegisterEvent("PLAYER_REGEN_DISABLED")
				eclipseBar:HookScript("OnEvent", function(self, event)
					if event == "PLAYER_REGEN_DISABLED" then
						eclipseBarText:Show()
					elseif event == "PLAYER_REGEN_ENABLED" then
						eclipseBarText:Hide()
					end
				end)

				eclipseBar.PostUnitAura = function(self, unit)
					if self.hasSolarEclipse then
						glow:SetBackdropBorderColor(.80, .82, .60, 1)
					elseif self.hasLunarEclipse then
						glow:SetBackdropBorderColor(.30, .52, .90, 1)
					else
						glow:SetBackdropBorderColor(0, 0, 0, 0)
					end
				end

				eclipseBar.PostUpdatePower = function(self, unit, power)
					if power == 0 then
						eclipseBarText:SetText("")
					else
						eclipseBarText:SetText(math.abs(power))

						if power < 0 then
							eclipseBarText:SetTextColor(.30, .52, .90)
						else
							eclipseBarText:SetTextColor(.80, .82, .60)
						end
					end
				end

				eclipseBar.PostUpdateVisibility = moveDebuffAnchors
			end

			self.AltPowerBar:HookScript("OnShow", moveDebuffAnchors)
			self.AltPowerBar:HookScript("OnHide", moveDebuffAnchors)
		elseif class == "MAGE" and C.classmod.mage then
			local rp = CreateFrame("Frame", nil, self)
			rp:SetSize(playerWidth, 2)
			rp:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			for i = 1, 2 do
				rp[i] = CreateFrame("StatusBar", nil, rp)
				rp[i]:SetHeight(2)
				rp[i]:SetStatusBarTexture(C.media.texture)

				F.CreateBDFrame(rp[i])

				if i == 1 then
					rp[i]:SetPoint("LEFT", rp)
					rp[i]:SetWidth(playerWidth/2)
				else
					rp[i]:SetPoint("LEFT", rp[i-1], "RIGHT", 1, 0)
					rp[i]:SetWidth((playerWidth/2)-1)
				end
			end

			self.RunePower = rp
			self.SpecialPowerBar = rp
		elseif class == "MONK" and C.classmod.monk then
			local pulsating = false

			local r, g, b = PowerBarColor["CHI"].r, PowerBarColor["CHI"].g, PowerBarColor["CHI"].b

			local UpdateOrbs = function(self, event, unit, powerType)
				if unit ~= "player" then return end
				if event == "UNIT_POWER_FREQUENT" then
					if not (powerType == "CHI" or powerType == "DARK_FORCE") then
						return
					end
				end

				local chi = UnitPower(unit, SPELL_POWER_CHI)

				if chi == UnitPowerMax(unit, SPELL_POWER_CHI) then
					if not pulsating then
						pulsating = true
						self.glow:SetAlpha(1)
						F.CreatePulse(self.glow)
						self.count:SetText(chi)
						self.count:SetTextColor(r, g, b)
						F.SetFS(self.count, 40)
					end
				elseif chi == 0 then
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText("")
					pulsating = false
				else
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText(chi)
					self.count:SetTextColor(1, 1, 1)
					F.SetFS(self.count, 24)
					pulsating = false
				end
			end

			local glow = CreateFrame("Frame", nil, self)
			glow:SetBackdrop({
				edgeFile = C.media.glow,
				edgeSize = 5,
			})
			glow:SetPoint("TOPLEFT", self, -6, 6)
			glow:SetPoint("BOTTOMRIGHT", self, 6, -6)
			glow:SetBackdropBorderColor(r, g, b)

			self.glow = glow

			local count = F.CreateFS(self, 24)
			count:SetPoint("LEFT", self, "RIGHT", 10, 0)

			self.count = count

			self.Harmony = glow
			glow.Override = UpdateOrbs

			-- Brewmaster stagger bar

			local staggerBar = CreateFrame("StatusBar", nil, self)
			staggerBar:SetSize(playerWidth, 2)
			staggerBar:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)
			staggerBar:SetStatusBarTexture(C.media.texture)
			F.CreateBDFrame(staggerBar)

			self.Stagger = staggerBar
			self.SpecialPowerBar = staggerBar
		elseif class == "PALADIN" and C.classmod.paladinHP then
			local UpdateHoly = function(self, event, unit, powerType)
				if(self.unit ~= unit or (powerType and powerType ~= 'HOLY_POWER')) then return end

				local num = UnitPower(unit, SPELL_POWER_HOLY_POWER)

				if(num == UnitPowerMax("player", SPELL_POWER_HOLY_POWER)) then
					self.glow:SetAlpha(1)
					F.CreatePulse(self.glow)
					self.count:SetText(num)
					self.count:SetTextColor(1, 1, 0)
					F.SetFS(self.count, 40)
				elseif num == 0 then
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText("")
				else
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText(num)
					self.count:SetTextColor(1, 1, 1)
					F.SetFS(self.count, 24)
				end
			end

			local glow = CreateFrame("Frame", nil, self)
			glow:SetBackdrop({
				edgeFile = C.media.glow,
				edgeSize = 5,
			})
			glow:SetPoint("TOPLEFT", self, -6, 6)
			glow:SetPoint("BOTTOMRIGHT", self, 6, -6)
			glow:SetBackdropBorderColor(228/255, 225/255, 16/255)

			self.glow = glow

			local count = F.CreateFS(self, 24)
			count:SetPoint("LEFT", self, "RIGHT", 10, 0)

			self.count = count

			self.HolyPower = glow
			glow.Override = UpdateHoly
		elseif class == "PRIEST" and C.classmod.priest then
			local UpdateOrbs = function(self, event, unit, powerType)
				if(self.unit ~= unit or (powerType and powerType ~= 'SHADOW_ORBS')) then return end

				local numOrbs = UnitPower("player", SPELL_POWER_SHADOW_ORBS)

				if(numOrbs == PRIEST_BAR_NUM_ORBS) then
					self.glow:SetAlpha(1)
					F.CreatePulse(self.glow)
					self.count:SetText(numOrbs)
					self.count:SetTextColor(.6, 0, 1)
					F.SetFS(self.count, 40)
				elseif numOrbs == 0 then
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText("")
				else
					self.glow:SetScript("OnUpdate", nil)
					self.glow:SetAlpha(0)
					self.count:SetText(numOrbs)
					self.count:SetTextColor(1, 1, 1)
					F.SetFS(self.count, 24)
				end
			end

			local glow = CreateFrame("Frame", nil, self)
			glow:SetBackdrop({
				edgeFile = C.media.glow,
				edgeSize = 5,
			})
			glow:SetPoint("TOPLEFT", self, -6, 6)
			glow:SetPoint("BOTTOMRIGHT", self, 6, -6)
			glow:SetBackdropBorderColor(.6, 0, 1)

			self.glow = glow

			local count = F.CreateFS(self, 24)
			count:SetPoint("LEFT", self, "RIGHT", 10, 0)

			self.count = count

			self.ShadowOrbs = glow
			glow.Override = UpdateOrbs
		elseif class == "WARLOCK" and C.classmod.warlock then
			local bars = CreateFrame("Frame", nil, self)
			bars:SetWidth(playerWidth)
			bars:SetHeight(2)
			bars:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			for i = 1, 4 do
				bars[i] = CreateFrame("StatusBar", nil, bars)
				bars[i]:SetHeight(2)
				bars[i]:SetStatusBarTexture(C.media.texture)

				local bbd = CreateFrame("Frame", nil, bars[i])
				bbd:SetPoint("TOPLEFT", bars[i], -1, 1)
				bbd:SetPoint("BOTTOMRIGHT", bars[i], 1, -1)
				bbd:SetFrameLevel(bars[i]:GetFrameLevel()-1)
				F.CreateBD(bbd)

				if i == 1 then
					bars[i]:SetPoint("LEFT", bars)
					bars[i]:SetWidth(playerWidth/4)
				else
					bars[i]:SetPoint("LEFT", bars[i-1], "RIGHT", 1, 0)
					bars[i]:SetWidth((playerWidth/4)-1)
				end
			end

			self.WarlockSpecBars = bars
			self.SpecialPowerBar = bars
		end

		local function moveDebuffAnchors()
			if self.SpecialPowerBar and self.SpecialPowerBar:IsShown() then
				if self.AltPowerBar:IsShown() then
					Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(9 + altPowerHeight))
				else
					Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -8)
				end
			else
				if self.AltPowerBar:IsShown() then
					Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(4 + altPowerHeight))
				else
					Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
				end
			end
		end

		self.AltPowerBar:HookScript("OnShow", moveDebuffAnchors)
		self.AltPowerBar:HookScript("OnHide", moveDebuffAnchors)
		if self.SpecialPowerBar then
			self.SpecialPowerBar:HookScript("OnShow", moveDebuffAnchors)
			self.SpecialPowerBar:HookScript("OnHide", moveDebuffAnchors)
		end
		moveDebuffAnchors()

		-- Status indicator

		local statusIndicator = CreateFrame("Frame")
		local statusText = F.CreateFS(Health)
		statusText:SetPoint("LEFT", HealthPoints, "RIGHT", 10, 0)

		local function updateStatus()
			if UnitAffectingCombat("player") and C.unitframes.statusIndicatorCombat then
				statusText:SetText("!")
				statusText:SetTextColor(1, 0, 0)
			elseif IsResting() then
				statusText:SetText("Zzz")
				statusText:SetTextColor(.8, .8, .8)
			else
				statusText:SetText("")
			end
		end

		local function checkEvents()
			if C.unitframes.statusIndicator then
				statusText:Show()
				statusIndicator:RegisterEvent("PLAYER_ENTERING_WORLD")
				statusIndicator:RegisterEvent("PLAYER_UPDATE_RESTING")

				if C.unitframes.statusIndicatorCombat then
					statusIndicator:RegisterEvent("PLAYER_REGEN_ENABLED")
					statusIndicator:RegisterEvent("PLAYER_REGEN_DISABLED")
				else
					statusIndicator:UnregisterEvent("PLAYER_REGEN_ENABLED")
					statusIndicator:UnregisterEvent("PLAYER_REGEN_DISABLED")
				end

				updateStatus()
			else
				statusIndicator:UnregisterEvent("PLAYER_ENTERING_WORLD")
				statusIndicator:UnregisterEvent("PLAYER_UPDATE_RESTING")
				statusIndicator:UnregisterEvent("PLAYER_REGEN_ENABLED")
				statusIndicator:UnregisterEvent("PLAYER_REGEN_DISABLED")
				statusText:Hide()
			end
		end

		checkEvents()

		F.AddOptionsCallback("unitframes", "statusIndicator", checkEvents)
		F.AddOptionsCallback("unitframes", "statusIndicatorCombat", checkEvents)

		statusIndicator:SetScript("OnEvent", updateStatus)


	end,

	target = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(targetHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "LEFT")
		HealthPoints:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 3)
		self:Tag(HealthPoints, '[dead][offline][free:health]')
		Health.value = HealthPoints

		local PowerText = F.CreateFS(Power)
		PowerText:SetPoint("BOTTOMLEFT", HealthPoints, "BOTTOMRIGHT", 3, 0)
		if powerType ~= 0 then PowerText.frequentUpdates = .1 end
		self:Tag(PowerText, '[free:power]')

		-- Cast bar

		if C.unitframes.castbar then
			Castbar.Width = self:GetWidth()
			Spark:SetHeight(self.Health:GetHeight())
			Castbar.Text = F.CreateFS(Castbar)
			if locale == "zhCN" then
				Castbar.Text:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
			end
			Castbar.Text:SetDrawLayer("ARTWORK")

			local IconFrame = CreateFrame("Frame", nil, Castbar)

			local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
			Icon:SetAllPoints(IconFrame)
			Icon:SetTexCoord(.08, .92, .08, .92)

			F.CreateSD(IconFrame, 5, 0, 0, 0, .8, -1)

			Castbar.Icon = Icon

			self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
			self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
			self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
			self.Iconbg:SetTexture(C.media.backdrop)

			Castbar:SetStatusBarTexture(C.media.texture)
			Castbar:SetStatusBarColor(219/255, 0, 11/255)
			Castbar:SetWidth(229)
			Castbar:SetHeight(4)
			Castbar:SetPoint(unpack(C.unitframes.target_castbar))
			Castbar.Text:SetPoint("TOP", Castbar, "BOTTOM", 0, -4)
			local sf = Castbar:CreateTexture(nil, "OVERLAY")
			sf:SetVertexColor(.5, .5, .5, .5)
			Castbar.SafeZone = sf
			IconFrame:SetPoint("LEFT", Castbar, "RIGHT", 10, 0)
			IconFrame:SetSize(14, 14)

			local bg = CreateFrame("Frame", nil, Castbar)
			bg:SetPoint("TOPLEFT", -1, 1)
			bg:SetPoint("BOTTOMRIGHT", 1, -1)
			bg:SetFrameLevel(Castbar:GetFrameLevel()-1)
			F.CreateBD(bg)
			F.CreateSD(bg, 5, 0, 0, 0, .8, -2)
		end

		local tt = CreateFrame("Frame", nil, self)
		tt:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 7 + C.appearance.fontSizeNormal + (C.unitframes.targettarget and 10 or 0))
		tt:SetWidth(80)
		tt:SetHeight(12)

		local ttt = F.CreateFS(tt, C.FONT_SIZE_NORMAL, "RIGHT")
		ttt:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 88, 2)
		ttt:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
		ttt:SetWidth(80)
		ttt:SetHeight(12)

		tt:RegisterEvent("UNIT_TARGET")
		tt:RegisterEvent("PLAYER_TARGET_CHANGED")
		tt:SetScript("OnEvent", function()
			if(UnitName("targettarget")==UnitName("player")) then
				ttt:SetText("> YOU <")
				ttt:SetTextColor(1, 0, 0)
			else
				ttt:SetText(UnitName"targettarget")
				ttt:SetTextColor(1, 1, 1)
			end
		end)


		local Name = F.CreateFS(self)
		Name:SetPoint("BOTTOMLEFT", PowerText, "BOTTOMRIGHT")
		Name:SetPoint("RIGHT", self)
		Name:SetJustifyH("RIGHT")
		Name:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
		Name:SetTextColor(1, 1, 1)

		self:Tag(Name, '[name]')
		self.Name = Name

		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Auras.initialAnchor = "TOPLEFT"
		Auras["growth-x"] = "RIGHT"
		Auras["growth-y"] = "DOWN"
		Auras['spacing-x'] = 3
		Auras['spacing-y'] = 3
		Auras.numDebuffs = C.unitframes.num_target_debuffs
		Auras.numBuffs = C.unitframes.num_target_buffs
		Auras:SetHeight(500)
		Auras:SetWidth(targetWidth)
		Auras.size = 18
		Auras.gap = true

		self.Auras = Auras

		Auras.showStealableBuffs = true
		Auras.PostUpdateIcon = PostUpdateIcon

		-- complicated filter is complicated
		-- icon hides if:
		-- it's a debuff on an enemy target which isn't yours, isn't cast by the target and isn't in the useful buffs filter
		-- it's a buff on an enemy player target which is not important

		local playerUnits = {
			player = true,
			pet = true,
			vehicle = true,
		}

		Auras.CustomFilter = function(_, unit, icon, _, _, _, _, _, _, _, caster, _, _, spellID)
			if(icon.isDebuff and not UnitIsFriend("player", unit) and not playerUnits[icon.owner] and icon.owner ~= self.unit and not C.debuffFilter[spellID])
			or(not icon.isDebuff and UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and not C.dangerousBuffs[spellID]) then
				return false
			end
			return true
		end

		local QuestIcon = F.CreateFS(self)
		QuestIcon:SetText("!")
		QuestIcon:SetTextColor(228/255, 225/255, 16/255)
		QuestIcon:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)

		QuestIcon.PostUpdate = function(self, isQuestBoss)
			if isQuestBoss then
				Name:ClearAllPoints()
				Name:SetPoint("BOTTOMLEFT", PowerText, "BOTTOMRIGHT")
				Name:SetPoint("RIGHT", QuestIcon, "LEFT", 0, 0)
			else
				Name:ClearAllPoints()
				Name:SetPoint("BOTTOMLEFT", PowerText, "BOTTOMRIGHT")
				Name:SetPoint("RIGHT", self)
			end
		end

		self.QuestIcon = QuestIcon
	end,

	targettarget = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(targettargetHeight - powerHeight - 1)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(Health:GetHeight())

		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint("LEFT", self, "RIGHT", 3, 0)
	end,

	focus = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(focusHeight - powerHeight - 1)

		-- Cast bar

		if C.unitframes.castbar then
			Castbar.Width = self:GetWidth()
			Spark:SetHeight(self.Health:GetHeight())
			Castbar.Text = F.CreateFS(Castbar)
			if locale == "zhCN" then
				Castbar.Text:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
			end
			Castbar.Text:SetDrawLayer("ARTWORK")

			local IconFrame = CreateFrame("Frame", nil, Castbar)

			local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
			Icon:SetAllPoints(IconFrame)
			Icon:SetTexCoord(.08, .92, .08, .92)

			F.CreateSD(IconFrame, 5, 0, 0, 0, .8, -1)

			Castbar.Icon = Icon

			self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
			self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
			self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
			self.Iconbg:SetTexture(C.media.backdrop)

			Castbar:SetStatusBarTexture(C.media.texture)
			Castbar:SetStatusBarColor(219/255, 0, 11/255)
			Castbar:SetWidth(168)
			Castbar:SetHeight(4)
			Castbar:SetPoint(unpack(C.unitframes.focus_castbar))
			Castbar.Text:SetPoint("TOP", Castbar, "BOTTOM", 0, -4)
			local sf = Castbar:CreateTexture(nil, "OVERLAY")
			sf:SetVertexColor(.5, .5, .5, .5)
			Castbar.SafeZone = sf
			IconFrame:SetPoint("LEFT", Castbar, "RIGHT", 10, 0)
			IconFrame:SetSize(14, 14)

			local bg = CreateFrame("Frame", nil, Castbar)
			bg:SetPoint("TOPLEFT", -1, 1)
			bg:SetPoint("BOTTOMRIGHT", 1, -1)
			bg:SetFrameLevel(Castbar:GetFrameLevel()-1)
			F.CreateBD(bg)
			F.CreateSD(bg, 5, 0, 0, 0, .8, -2)
		end

		local tt = CreateFrame("Frame", nil, self)
		tt:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 7 + C.appearance.fontSizeNormal + (C.unitframes.focustarget and 10 or 0))
		tt:SetWidth(80)
		tt:SetHeight(12)

		local ttt = F.CreateFS(tt, C.FONT_SIZE_NORMAL, "RIGHT")
		ttt:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 88, 2)
		ttt:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
		ttt:SetWidth(80)
		ttt:SetHeight(12)

		tt:RegisterEvent("UNIT_TARGET")
		tt:RegisterEvent("PLAYER_FOCUS_CHANGED")
		tt:SetScript("OnEvent", function()
			if(UnitName("focustarget")==UnitName("player")) then
				ttt:SetText("> YOU <")
				ttt:SetTextColor(1, 0, 0)
			else
				ttt:SetText(UnitName"focustarget")
				ttt:SetTextColor(1, 1, 1)
			end
		end)

		local Name = F.CreateFS(self, 8)
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 1)
		Name:SetWidth(80)
		Name:SetHeight(12)
		Name:SetJustifyH"LEFT"
		Name:SetFont(Font_UF, Font_UF_Size, Font_UF_Flag)
		Name:SetTextColor(1, 1, 1)

		self:Tag(Name, '[name]')
		self.Name = Name

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0)
		Debuffs.initialAnchor = "BOTTOMLEFT"
		Debuffs["growth-x"] = "RIGHT"
		Debuffs["growth-y"] = "UP"
		Debuffs["spacing-x"] = 3
		Debuffs:SetHeight(18)
		Debuffs:SetWidth(focusWidth)
		Debuffs.size = 18
		Debuffs.num = C.unitframes.num_focus_debuffs
		self.Debuffs = Debuffs
		self.Debuffs.onlyShowPlayer = true

		Debuffs.PostUpdateIcon = PostUpdateIcon
	end,

	focustarget = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(focustargetHeight - powerHeight - 1)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(Health:GetHeight())

		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint("LEFT", self, "RIGHT", 3, 0)

	end,


	boss = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		self:SetAttribute('initial-height', bossHeight)
		self:SetAttribute('initial-width', bossWidth)

		Health:SetHeight(bossHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "RIGHT")
		HealthPoints:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 4)
		self:Tag(HealthPoints, '[dead][free:bosshealth]')

		Health.value = HealthPoints

		local Name = F.CreateFS(self, C.FONT_SIZE_NORMAL, "LEFT")
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
		Name:SetWidth((bossWidth / 2) + 10)
		Name:SetHeight(8)

		self:Tag(Name, '[name]')
		self.Name = Name

		local AltPowerBar = CreateFrame("StatusBar", nil, self)
		AltPowerBar:SetWidth(bossWidth)
		AltPowerBar:SetHeight(altPowerHeight)
		AltPowerBar:SetStatusBarTexture(C.media.texture)
		AltPowerBar:SetPoint("BOTTOM", 0, -2)

		local abd = CreateFrame("Frame", nil, AltPowerBar)
		abd:SetPoint("TOPLEFT", -1, 1)
		abd:SetPoint("BOTTOMRIGHT", 1, -1)
		abd:SetFrameLevel(AltPowerBar:GetFrameLevel()-1)
		F.CreateBD(abd)

		AltPowerBar.Text = F.CreateFS(AltPowerBar, C.FONT_SIZE_NORMAL, "CENTER")
		AltPowerBar.Text:SetPoint("CENTER", self, "TOP", 0, 6)

		AltPowerBar:SetScript("OnValueChanged", function(_, value)
			local min, max = AltPowerBar:GetMinMaxValues()
			local r, g, b = self.ColorGradient(value, max, unpack(self.colors.smooth))

			AltPowerBar:SetStatusBarColor(r, g, b)
			AltPowerBar.Text:SetTextColor(r, g, b)
		end)

		AltPowerBar.PostUpdate = function(_, _, cur)
			AltPowerBar.Text:SetText(cur)
		end

		self.AltPowerBar = AltPowerBar

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		Castbar.Text = F.CreateFS(self)
		Castbar.Text:SetDrawLayer("ARTWORK")
		Castbar.Text:SetAllPoints(Health)

		local IconFrame = CreateFrame("Frame", nil, Castbar)
		IconFrame:SetPoint("RIGHT", self, "LEFT", -4, 0)
		IconFrame:SetHeight(22)
		IconFrame:SetWidth(22)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "TOPLEFT"
		Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "DOWN"
		Buffs['spacing-x'] = 3
		Buffs['spacing-y'] = 3

		Buffs:SetHeight(26)
		Buffs:SetWidth(bossWidth - 26)
		Buffs.num = C.unitframes.num_boss_buffs
		Buffs.size = 26

		self.Buffs = Buffs
		Buffs.PostUpdateIcon = PostUpdateIcon

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
		Debuffs.initialAnchor = "TOPRIGHT"
		Debuffs["growth-x"] = "LEFT"
		Debuffs["growth-y"] = "DOWN"
		Debuffs["spacing-x"] = 3
		Debuffs['spacing-y'] = 3
		Debuffs:SetHeight(26)
		Debuffs:SetWidth(bossWidth - 26)
		Debuffs.size = 26
		Debuffs.num = 8
		self.Debuffs = Debuffs
		self.Debuffs.onlyShowPlayer = true

		Debuffs.PostUpdateIcon = PostUpdateIcon

		AltPowerBar:HookScript("OnShow", function()
			Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -(5 + altPowerHeight))
		end)

		AltPowerBar:HookScript("OnHide", function()
			Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -(3 + altPowerHeight))
		end)
	end,

	arena = function(self, ...)
		if not C.unitframes.enableArena then return end

		Shared(self, ...)

		local Health = self.Health
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		self:SetAttribute('initial-height', arenaHeight)
		self:SetAttribute('initial-width', arenaWidth)

		Health:SetHeight(arenaHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "RIGHT")
		HealthPoints:SetPoint("RIGHT", self, "TOPRIGHT", 0, 6)
		self:Tag(HealthPoints, '[dead][offline][free:health]')

		Health.value = HealthPoints

		local Name = F.CreateFS(self, C.FONT_SIZE_NORMAL, "LEFT")
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		Name:SetWidth(110)
		Name:SetHeight(8)

		self:Tag(Name, '[name]')
		self.Name = Name

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		Castbar.Text = F.CreateFS(self)
		Castbar.Text:SetDrawLayer("ARTWORK")
		Castbar.Text:SetAllPoints(Health)

		local IconFrame = CreateFrame("Frame", nil, Castbar)
		IconFrame:SetPoint("LEFT", self, "RIGHT", 3, 0)
		IconFrame:SetHeight(22)
		IconFrame:SetWidth(22)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "TOPLEFT"
		Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "DOWN"
		Buffs['spacing-x'] = 3
		Buffs['spacing-y'] = 3

		Buffs:SetHeight(22)
		Buffs:SetWidth(arenaWidth)
		Buffs.num = C.unitframes.num_arena_buffs
		Buffs.size = 22

		self.Buffs = Buffs

		Buffs.PostUpdateIcon = PostUpdateIcon

		self.RaidIcon:SetPoint("LEFT", self, "RIGHT", 3, 0)
	end,
}

do
	UnitSpecific.party = function(self, ...)
		Shared(self, ...)

		self.disallowVehicleSwap = false

		local Health, Power = self.Health, self.Power

		local Text = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "CENTER")
		Text:SetPoint("CENTER", 1, 0)
		self.Text = Text

		self:Tag(Text, '[dead][offline]')

		-- if FreeUIConfig.layout == 2 then
		-- 	Health:SetHeight(partyHeightHealer - powerHeight - 1)
		-- 	self:Tag(Text, '[free:missinghealth]')

		-- else
		-- 	Health:SetHeight(partyHeight - powerHeight - 1)
		-- 	if C.unitframes.partyNameAlways then
		-- 		self:Tag(Text, '[free:name]')
		-- 	else
		-- 		self:Tag(Text, '[dead][offline]')
		-- 	end
		-- end

		self.ResurrectIcon = self:CreateTexture(nil, "OVERLAY")
		self.ResurrectIcon:SetSize(16, 16)
		self.ResurrectIcon:SetPoint("CENTER")

		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint("CENTER", self, "CENTER")

		local Leader = F.CreateFS(self, C.FONT_SIZE_NORMAL, "LEFT")
		Leader:SetText("l")
		Leader:SetPoint("TOPLEFT", Health, 2, -1)

		self.Leader = Leader

		local MasterLooter = F.CreateFS(self, C.FONT_SIZE_NORMAL, "RIGHT")
		MasterLooter:SetText("m")
		MasterLooter:SetPoint("TOPRIGHT", Health, 1, 0)

		self.MasterLooter = MasterLooter

		local rc = self:CreateTexture(nil, "OVERLAY")
		rc:SetPoint("TOPLEFT", Health)
		rc:SetSize(16, 16)

		self.ReadyCheck = rc

		local UpdateLFD = function(self, event)
			local lfdrole = self.LFDRole
			local role = UnitGroupRolesAssigned(self.unit)

			if role == "DAMAGER" then
				lfdrole:SetTextColor(1, .1, .1, 1)
				lfdrole:SetText(".")
			elseif role == "TANK" then
				lfdrole:SetTextColor(.3, .4, 1, 1)
				lfdrole:SetText("x")
			elseif role == "HEALER" then
				lfdrole:SetTextColor(0, 1, 0, 1)
				lfdrole:SetText("+")
			else
				lfdrole:SetTextColor(0, 0, 0, 0)
			end
		end

		local lfd = F.CreateFS(Health, C.FONT_SIZE_NORMAL, "CENTER")
		lfd:SetPoint("BOTTOM", Health, 1, 1)
		lfd.Override = UpdateLFD

		self.LFDRole = lfd

			local Debuffs = CreateFrame("Frame", nil, self)
			Debuffs.initialAnchor = "CENTER"
			Debuffs:SetPoint("BOTTOM", 0, powerHeight - 1)
			Debuffs["growth-x"] = "RIGHT"
			Debuffs["spacing-x"] = 3

			Debuffs:SetHeight(16)
			Debuffs:SetWidth(37)
			Debuffs.num = 2
			Debuffs.size = 16

			self.Debuffs = Debuffs

			Debuffs.PostCreateIcon = function(icons, index)
				index:EnableMouse(false)
			end

			-- Import the global table for faster usage
			local hideDebuffs = C.hideDebuffs

			Debuffs.CustomFilter = function(_, _, _, _, _, _, _, _, _, _, caster, _, _, spellID)
				if hideDebuffs[spellID] then
					return false
				end
				return true
			end

			Debuffs.PostUpdate = function(icons)
				local vb = icons.visibleDebuffs

				if vb == 2 then
					Debuffs:SetPoint("BOTTOM", -9, 0)
				else
					Debuffs:SetPoint("BOTTOM")
				end
			end

			Debuffs.PostUpdateIcon = function(icons, unit, icon, index, _, filter)
				local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)
				if dtype and UnitIsFriend("player", unit) then
					local color = DebuffTypeColor[dtype]
					icon.bg:SetVertexColor(color.r, color.g, color.b)
				else
					icon.bg:SetVertexColor(0, 0, 0)
				end
				icon:EnableMouse(false)
			end

			local Buffs = CreateFrame("Frame", nil, self)
			Buffs.initialAnchor = "CENTER"
			Buffs:SetPoint("TOP", 0, -2)
			Buffs["growth-x"] = "RIGHT"
			Buffs["spacing-x"] = 3

			Buffs:SetSize(43, 12)
			Buffs.num = 0 			-- remove aura icon from raid grid
			Buffs.size = 12

			self.Buffs = Buffs

			Buffs.PostCreateIcon = function(icons, index)
				index:EnableMouse(false)
				index.cd.noshowcd = true
			end

			Buffs.PostUpdateIcon = function(_, _, icon)
				icon:EnableMouse(false)
			end

			local myBuffs = C.myBuffs
			local allBuffs = C.allBuffs

			Buffs.CustomFilter = function(_, _, _, _, _, _, _, _, _, _, caster, _, _, spellID)
				if (caster == "player" and myBuffs[spellID]) or allBuffs[spellID] then
					return true
				end
			end

			Buffs.PostUpdate = function(icons)
				local vb = icons.visibleBuffs

				if vb == 3 then
					Buffs:SetPoint("TOP", -15, -2)
				elseif vb == 2 then
					Buffs:SetPoint("TOP", -7, -2)
				else
					Buffs:SetPoint("TOP", 0, -2)
				end
			end

		local Threat = CreateFrame("Frame", nil, self)
		self.Threat = Threat
		Threat.Override = UpdateThreat

		local select = CreateFrame("Frame", nil, self)
		select:RegisterEvent("PLAYER_TARGET_CHANGED")
		select:SetScript("OnEvent", updateNameColourAlt)

		self.Range = range
	end
end

--[[ Register and activate style ]]

oUF:RegisterStyle("Free", Shared)
for unit,layout in next, UnitSpecific do
	oUF:RegisterStyle('Free - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Free - ' .. unit:gsub("^%l", string.upper))
	elseif(UnitSpecific[unit:match('[^%d]+')]) then -- boss1 -> boss
		self:SetActiveStyle('Free - ' .. unit:match('[^%d]+'):gsub("^%l", string.upper))
	else
		self:SetActiveStyle'Free'
	end

	local object = self:Spawn(unit)
	object:SetPoint(...)
	return object
end

local function round(x)
	return floor(x + .5)
end

oUF:Factory(function(self)
	local partyPos, raidPos
	local player, target

	if C.unitframes.autoPosition then
		player = spawnHelper(self, 'player', "BOTTOM", UIParent, "CENTER", -275, round(GetScreenHeight()/-11.43))
	else
		player = spawnHelper(self, 'player', unpack(C.unitframes.player))
	end

	target = spawnHelper(self, 'target', unpack(C.unitframes.target))
	partyPos = C.unitframes.party
	raidPos = C.unitframes.raid

	spawnHelper(self, 'focus', "LEFT", target, "RIGHT", 8, -100)
	spawnHelper(self, 'focustarget', "LEFT", target, "RIGHT", 96, -100)
	spawnHelper(self, 'pet', "RIGHT", player, "LEFT", -8, 0)
	spawnHelper(self, 'targettarget', "LEFT", target, "RIGHT", 8, 0)

	for n = 1, MAX_BOSS_FRAMES do
		spawnHelper(self, 'boss' .. n, 'RIGHT', -30, 220 - (60 * n))
	end

	if C.unitframes.enableArena then
		for n = 1, 5 do
			spawnHelper(self, 'arena' .. n, 'LEFT', UIParent, 20, 100 - (56 * n))
		end
	end

	if not C.unitframes.enableGroup then return end

	self:SetActiveStyle'Free - Party'

	local party_width, party_height
	party_width = partyWidth
	party_height = partyHeight

	local party = self:SpawnHeader(nil, nil, "party,raid",
		'showParty', true,
		'showPlayer', true,
		'showSolo', false,
		'xoffset', 5,
		'yoffset', -8,
		'maxColumns', 5,
		'unitsperColumn', 1,
		'columnSpacing', 6,
		'columnAnchorPoint', "LEFT",
		'oUF-initialConfigFunction', ([[
			self:SetHeight(%d)
			self:SetWidth(%d)
		]]):format(party_height, party_width)
	)

	party:SetPoint(unpack(partyPos))

	local raid = self:SpawnHeader(nil, nil, "raid",
		'showParty', false,
		'showRaid', true,
		'xoffset', 5,
		'yOffset', -8,
		'point', "TOP",
		'groupFilter', '1,2,3,4,5,6,7,8',
		'groupingOrder', '1,2,3,4,5,6,7,8',
		'groupBy', 'GROUP',
		'maxColumns', 8,
		'unitsPerColumn', 5,
		'columnSpacing', 6,  -- 团队框架横向间隔
		'columnAnchorPoint', "RIGHT",
		'oUF-initialConfigFunction', ([[
			self:SetHeight(%d)
			self:SetWidth(%d)
		]]):format(raidHeight, raidWidth)
	)

	raid:SetPoint(unpack(raidPos))

	if C.unitframes.limitRaidSize then
		raid:SetAttribute("groupFilter", "1,2,3,4,5,6")
	end

	F.AddOptionsCallback("unitframes", "limitRaidSize", function()
		if C.unitframes.limitRaidSize then
			raid:SetAttribute("groupFilter", "1,2,3,4,5,6")
		else
			raid:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
		end
	end)

	local raidToParty = CreateFrame("Frame")

	local function togglePartyAndRaid(event)
		if InCombatLockdown() then
			raidToParty:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		elseif (event and event == "PLAYER_REGEN_ENABLED") then
			raidToParty:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end

		local numGroup = GetNumGroupMembers()

		if numGroup > 5 then
			party:SetAttribute("showParty", false)
			party:SetAttribute("showRaid", false)
			raid:SetAttribute("showRaid", true)
		else
			raid:SetAttribute("showRaid", false)
			-- if in a party, or in a raid where everyone is in one party (subgroup), show party
			-- if in a raid where people are spread across subgroups, show raid
			if GetNumSubgroupMembers() + 1 < numGroup then
				party:SetAttribute("showParty", false)
				party:SetAttribute("showRaid", true)
			else
				party:SetAttribute("showParty", true)
				party:SetAttribute("showRaid", false)
			end
		end
	end

	raidToParty:SetScript("OnEvent", togglePartyAndRaid)

	local function checkShowRaidFrames()
		if C.unitframes.showRaidFrames then
			raidToParty:RegisterEvent("PLAYER_ENTERING_WORLD")
			raidToParty:RegisterEvent("GROUP_ROSTER_UPDATE")

			togglePartyAndRaid()
		else
			raidToParty:UnregisterEvent("PLAYER_ENTERING_WORLD")
			raidToParty:UnregisterEvent("GROUP_ROSTER_UPDATE")

			party:SetAttribute("showParty", true)
			party:SetAttribute("showRaid", true)
			raid:SetAttribute("showRaid", false)
		end
	end

	checkShowRaidFrames()
	F.AddOptionsCallback("unitframes", "showRaidFrames", checkShowRaidFrames)
end)
