-- module/server

local SkillTreeModule = {}
local Network = require(script.Network)
local DataStore = require(script.DataStore)

local Trees = {}
local PlayerTreesData: {[Player]: {Tick: number, TreesData: {[string]: {[string]: number}}}} = {}
SkillTreeModule.__index = SkillTreeModule

function SkillTreeModule.new(TreeName: string): typeof(SkillTreeModule)
	assert(not Trees[TreeName], "Tree already exists.")
	
	local TreeTable = setmetatable({
		Name=TreeName,
		DataPerPlayer={},
		Nodes={},
	}, SkillTreeModule)
	
	Trees[TreeName] = TreeTable
	
	for PlayerUserId, TreesData in PlayerTreesData do
		local Player = game.Players:GetPlayerByUserId(PlayerUserId)
		
		if not Player then
			continue
		end
		
		TreesData = TreesData.TreesData
		
		if TreesData[TreeName] then
			TreeTable:SetData(Player, TreesData[TreeName])
		end
	end
	
	return TreeTable
end

function SkillTreeModule.getTree(TreeName: string): typeof(SkillTreeModule)
	assert(Trees[TreeName], "Tree not found.")
	
	return Trees[TreeName]
end

function SkillTreeModule.getTreeData(Player: Player, TreeName: string): {[string]: number}
	return SkillTreeModule.getTree(TreeName):GetData(Player)
end

function SkillTreeModule:AddNode(NodeName: string, LockedByNodesGroup: {[string]: number}, ActivateCallback: (Player: Player, NodeName: string, Value: number) -> (true?))
	assert(not self.Nodes[NodeName], "Node already exists.")
	
	self.Nodes[NodeName] = {LockedByNodesGroup = LockedByNodesGroup, ActivateCallback = ActivateCallback}
end

function SkillTreeModule:RemoveNode(NodeName: string)
	assert(self.Nodes[NodeName], "Node doesn't exist.")
	
	self.Nodes[NodeName] = nil
end

function SkillTreeModule:CallActivateNodeCallback(Player: Player, NodeName: string): true?
	for OtherNodeName, Value in self.Nodes[NodeName].LockedByNodesGroup do
		if self:GetNode(Player, OtherNodeName) < Value then
			return
		end
	end

	return self.Nodes[NodeName].ActivateCallback(Player, NodeName, self:GetNode(Player, NodeName))
end

function SkillTreeModule:ActivateNode(Player: Player, NodeName: string)
	assert(self.Nodes[NodeName], "Node doesn't exist.")
	local Data = self:GetData(Player)
	
	if not Data[NodeName] then
		Data[NodeName] = 1
	else
		Data[NodeName] += 1
	end
end

function SkillTreeModule:SetData(Player: Player, TreeData: {[string]: number})
	self.DataPerPlayer[Player.UserId] = TreeData
end

function SkillTreeModule:GetData(Player: Player): {[string]: number}
	assert(self.DataPerPlayer[Player.UserId], "Couldn't find player.")
	
	return self.DataPerPlayer[Player.UserId]
end

function SkillTreeModule:HasPlayer(Player: Player): true?
	if self.DataPerPlayer[Player.UserId] then
		return true
	end
end

function SkillTreeModule:GetNode(Player: Player, NodeName: string): number
	local Data = self:GetData(Player)

	return Data[NodeName] or 0
end

function SkillTreeModule:KillPlayer(Player: Player)
	self.DataPerPlayer[Player.UserId] = nil
end

Network.setup(SkillTreeModule.getTree)

game.Players.PlayerRemoving:Connect(function(Player: Player)
	local TreesData = PlayerTreesData[Player.UserId].TreesData
	local Tick = PlayerTreesData[Player.UserId].Tick
	
	for _, Tree in Trees do
		if Tree:HasPlayer(Player) then
			TreesData[Tree.Name] = Tree:GetData(Player)
			
			Tree:KillPlayer(Player)
		end
	end
	
	Network.killPlayer(Player)
	
	DataStore.saveTreesForPlayer(Player, TreesData)
	
	if Tick == PlayerTreesData[Player.UserId].Tick then
		for Key in TreesData do
			TreesData[Key] = nil
		end
		
		PlayerTreesData[Player.UserId] = nil
	end
end)

game.Players.PlayerAdded:Connect(function(Player: Player)
	local TreesData = DataStore.loadTreesForPlayer(Player)
	
	PlayerTreesData[Player.UserId] = {Tick = tick(), TreesData = TreesData}
	
	for _, Tree in Trees do
		Tree:SetData(Player, TreesData[Tree.Name] or {})
		Network.loadTreeToPlayer(Player, Tree.Name, Tree:GetData(Player))
	end
end)

return SkillTreeModule