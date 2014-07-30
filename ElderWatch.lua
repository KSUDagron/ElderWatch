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

    return o
end

function ElderWatch:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ElderWatch OnLoad
-----------------------------------------------------------------------------------------------
function ElderWatch:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ElderWatch.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
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
	Apollo.RegisterEventHandler("VarChange_ZoneName", "OnChangeZoneName", self)
	
	Apollo.RegisterTimerHandler("DungeonTimer", "OnDungeonTimerUpdate", self)
	Apollo.CreateTimer("DungeonTimer", .001, true)
	Apollo.StopTimer("DungeonTimer")
	
	self.wndWatch = Apollo.LoadForm(self.xmlDoc, "MainContainer", nil, self)
	self.wndWatch:Show(false)
	self:OnPublicEventStart()
end

-----------------------------------------------------------------------------------------------
-- ElderWatch Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/elderwatch"
function ElderWatch:OnElderWatchOn()

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
