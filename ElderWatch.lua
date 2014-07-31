-----------------------------------------------------------------------------------------------
-- Client Lua Script for ElderWatch
-- Copyright (c) KSUDagron on Curse.com All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ElderWatch Module Definition
-----------------------------------------------------------------------------------------------
local ElderWatch = {}
local ElderWatchInst = nil
local nWidth = 390
local nHeight = 53
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ElderWatch:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	self.location = {}
	self.location.options = { 200, 200, 200 + nWidth, 200 + nHeight}

    return o
end

function ElderWatch:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = { }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ElderWatch OnLoad
-----------------------------------------------------------------------------------------------
function ElderWatch:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ElderWatch.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ElderWatch:OnSave(saveDepth)
	if saveDepth ~= GameLib.CodeEnumAddonSaveLevel.Character then return nil end
	
	local savedVariables = {}	
	local nLeft, nTop, nRight, nBottom = self.wndWatch:GetAnchorOffsets()
	savedVariables.location = { nLeft, nTop, nLeft + nWidth, nTop + nHeight}
		
	return savedVariables
end

function ElderWatch:OnRestore(saveDepth, savedVariables)
	if saveDepth ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if savedVariables == {} or savedVariables == nil then return end

	if savedVariables.location ~= nil then
		self.location = savedVariables.location
	end
end

-----------------------------------------------------------------------------------------------
-- ElderWatch OnDocLoaded
-----------------------------------------------------------------------------------------------
function ElderWatch:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		Apollo.RegisterSlashCommand("elderwatch", "OnElderWatchOn", self)
	end
	
	Apollo.RegisterEventHandler("PublicEventStart", "OnPublicEventStart", self)
	Apollo.RegisterEventHandler("PublicEventLeave", "OnPublicEventLeave", self)
	Apollo.RegisterEventHandler("PublicEventEnd", "OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("VarChange_ZoneName", "OnChangeZoneName", self)
	
	Apollo.RegisterTimerHandler("DungeonTimer", "OnDungeonTimerUpdate", self)
	Apollo.CreateTimer("DungeonTimer", .001, true)
	Apollo.StopTimer("DungeonTimer")
	
	self.wndWatch = Apollo.LoadForm(self.xmlDoc, "MainContainer", nil, self)
	self.wndWatch:Show(false)
	self:OnPublicEventStart()
	
	self.wndWatch:SetAnchorOffsets(unpack(self.location))
end

-----------------------------------------------------------------------------------------------
-- ElderWatch Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/elderwatch"
function ElderWatch:OnElderWatchOn()
	self.wndWatch:Invoke()
end

function ElderWatch:OnPublicEventStart()
	local tActiveEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(tActiveEvents) do
		local eEventType = peEvent:GetEventType()
		if eEventType == PublicEvent.PublicEventType_Dungeon then
			self.dungeon = peEvent
		end
	end

	if self.dungeon then
		local nTime = self.dungeon:GetElapsedTime()
		local nHour = math.floor(nTime / 3600000)
		local nTime = nTime % 3600000
		local nMinute = math.floor(nTime / 60000)
		local nTime = nTime % 60000
		local nSecond = math.floor(nTime / 1000)
		local nMillisecond = nTime % 1000
		if self.wndWatch then
			self.wndWatch:Invoke()
			Apollo.StartTimer("DungeonTimer")
		end
	end
end

function ElderWatch:OnPublicEventLeave()
	if self.dungeon then
		Apollo.StopTimer("DungeonTimer")
		self.dungeon = nil
		self.zone = nil
		self.wndWatch:Close()
	end
end

function ElderWatch:OnPublicEventEnd()
	if self.dungeon then
		Apollo.StopTimer("DungeonTimer")
	end
end

function ElderWatch:OnChangeZoneName(oVar, strNewZone)
	self.wndWatch:FindChild("InstanceName"):SetText(strNewZone)
end

function ElderWatch:OnDungeonTimerUpdate()
	if self.zone == nil then
		self.zone = GameLib.GetCurrentZoneMap().strName
	end
	
	if self.dungeon then
		local nTime = self.dungeon:GetElapsedTime()
		local nHour = math.floor(nTime / 3600000)
		local nTime = nTime % 3600000
		local nMinute = math.floor(nTime / 60000)
		local nTime = nTime % 60000
		local nSecond = math.floor(nTime / 1000)
		local nMillisecond = nTime % 1000
		self.wndWatch:FindChild("InstanceName"):SetText(self.zone)
		self.wndWatch:FindChild("InstanceTimer"):SetText(string.format("%02d:%02d:%02d.%03d", tostring(nHour), tostring(nMinute), tostring(nSecond), tostring(nMillisecond)))
	end
end

-----------------------------------------------------------------------------------------------
-- ElderWatch Instance
-----------------------------------------------------------------------------------------------
ElderWatchInst = ElderWatch:new()
ElderWatchInst:Init()

---------------------------------------------------------------------------------------------------
-- MainContainer Functions
---------------------------------------------------------------------------------------------------
function ElderWatch:OnToggleDetails( wndHandler, wndControl, eMouseButton )
	self.wndWatch:Close()
end

