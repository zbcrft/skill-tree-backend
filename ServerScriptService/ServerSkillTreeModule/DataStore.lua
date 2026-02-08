-- module/server

local DataStore = {}
local DataStoreService = game:GetService("DataStoreService")

local SkillTreeDataStore = DataStoreService:GetDataStore("SkillTreeDataStore")

local NotToSaveTrees: {string} = {} --- put here the treenames of the trees you want to remove from datastores/not save

local function RemoveUnWantedTrees(TreesData: {[string]: {[string]: number}})
	for TreeName, _ in TreesData do
		if table.find(NotToSaveTrees, TreeName) then
			TreesData[TreeName] = nil
		end
	end
end

function DataStore.saveTreesForPlayer(Player: Player, TreesData: {[string]: {[string]: number}})
	assert(typeof(TreesData) == "table", "Trees isn't a table.")
	RemoveUnWantedTrees(TreesData)
	SkillTreeDataStore:SetAsync(Player.UserId, TreesData)
end

function DataStore.loadTreesForPlayer(Player: Player): {[string]: {[string]: number}}
	local TreesData = SkillTreeDataStore:GetAsync(Player.UserId) or {}
	RemoveUnWantedTrees(TreesData)
	return TreesData
end

return DataStore
