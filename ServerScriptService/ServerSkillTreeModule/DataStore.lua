-- module/server

local DataStore = {}
local DataStoreService = game:GetService("DataStoreService")

local SkillTreeDataStore = DataStoreService:GetDataStore("SkillTreeDataStore")

function DataStore.saveTreesForPlayer(Player: Player, TreesData: {[string]: {[string]: number}})
	assert(typeof(TreesData) == "table", "Trees isn't a table.")
	
	SkillTreeDataStore:SetAsync(Player.UserId, TreesData)
end

function DataStore.loadTreesForPlayer(Player: Player): {[string]: {[string]: number}}
	return SkillTreeDataStore:GetAsync(Player.UserId) or {}
end

return DataStore
