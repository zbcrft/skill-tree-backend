-- module/client

local SkillTreeModule = {}
local Network = require(script.Network)

SkillTreeModule.__index = SkillTreeModule

function SkillTreeModule.loadTree(TreeName: string, NodeActivateCallback: (NodeName: string, Success: true?, Value: number) -> (), NodeActivateCallbackForNodesThatAlreadyExistedBeforeLoadingTree: (NodeName: string, Value: number) -> ()?): typeof(SkillTreeModule)
	local TreeTable = setmetatable({
		Name=TreeName,
		NodesData=Network.getTreeData(TreeName),
	}, SkillTreeModule)
	
	Network.bindTree(TreeName, function(NodeName: string, Success: true?)
		if Success then
			if not TreeTable.NodesData[NodeName] then
				TreeTable.NodesData[NodeName] = 0
			end
			
			TreeTable.NodesData[NodeName] += 1
		end
		
		NodeActivateCallback(NodeName, Success, TreeTable:GetNode(NodeName))
	end)
	
	if NodeActivateCallbackForNodesThatAlreadyExistedBeforeLoadingTree then
		for NodeName, Value in TreeTable:GetData() do
			NodeActivateCallbackForNodesThatAlreadyExistedBeforeLoadingTree(NodeName, Value)
		end
	end
	
	return TreeTable
end

function SkillTreeModule:ActivateNode(NodeName: string)
	Network.activateNode(self.Name, NodeName)
end

function SkillTreeModule:GetData(): {[string]: number}
	return self.NodesData
end

function SkillTreeModule:GetNode(NodeName: string): number
	return self.NodesData[NodeName]
end

return SkillTreeModule
