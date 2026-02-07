-- module/client

local Network = {}

local Binds = {}
local RemoteEvent:RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("SkillTreeBackendRemoteEvent")

local function NodeActivationResultRequest(TreeName: string, NodeName: string, Result: true?)
	assert(Binds[TreeName], "Tree hasn't been binded to activation.")
	
	Binds[TreeName](NodeName, Result)
end

local ReceivedTreeData = {}
local function GetTreeDataResultRequest(TreeName: string, Data: {[string]: number})
	if Data == false then
		ReceivedTreeData[TreeName] = {}
		
		error("Failed to load tree data, tree hasn't been created on server yet.")
	end
	
	ReceivedTreeData[TreeName] = Data
end

local function ReceivedRequest(Request: "NodeActivationResult" | "GetTreeDataResult", ...)
	if Request == "NodeActivationResult" then
		NodeActivationResultRequest(...)
	elseif Request == "GetTreeDataResult" then
		GetTreeDataResultRequest(...)
	end
end

RemoteEvent.OnClientEvent:Connect(ReceivedRequest)

function Network.bindTree(TreeName: string, NodeActivateCallback: (NodeName: string, Success: true?) -> ())
	Binds[TreeName] = NodeActivateCallback
end

function Network.activateNode(TreeName: string, NodeName: string)
	RemoteEvent:FireServer("ActivateNode", TreeName, NodeName)
end

function Network.getTreeData(TreeName: string): {[string]: number}
	ReceivedTreeData[TreeName] = nil
	
	RemoteEvent:FireServer("GetTreeData", TreeName)
	
	while not ReceivedTreeData[TreeName] do
		task.wait()
	end
	
	local TreeData = table.clone(ReceivedTreeData[TreeName])
	ReceivedTreeData[TreeName] = nil
	
	return TreeData
end

return Network