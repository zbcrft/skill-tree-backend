-- module/server

local Network = {}

local Binds = {}
local TreeDataRequests: {[number]: {string}} = {}

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "SkillTreeBackendRemoteEvent"
RemoteEvent.Parent = game.ReplicatedStorage

local getTree: (TreeName: string) -> ({any})

local function SendRequest(Player: Player, Request: "NodeActivationResult"|"GetTreeDataResult", ...)
	RemoteEvent:FireClient(Player, Request, ...)
end

local function ActivateNodeRequest(Player: Player, TreeName: string, NodeName: string)
	assert(typeof(TreeName) == "string", `{Player.Name}: TreeName has to be a string.`)
	assert(typeof(NodeName) == "string", `{Player.Name}: NodeName has to be a string.`)
	assert(Binds[TreeName], `{Player.Name}: Tree has no node binded to activation.`)
	assert(Binds[TreeName][NodeName], `{Player.Name}: Node hasn't been binded.`)
	
	local Result = Binds[TreeName][NodeName](Player)
	
	if Result then
		getTree(TreeName):ActivateNode(Player, NodeName)
		
		SendRequest(Player, "NodeActivationResult", TreeName, NodeName, true)
	else
		SendRequest(Player, "NodeActivationResult", TreeName, NodeName, false)
	end
end

local function GetTreeDataRequest(Player: Player, TreeName: string)
	assert(typeof(TreeName) == "string")
	
	local Tree = getTree(TreeName)
	
	if not Tree then
		SendRequest(Player, "GetTreeDataResult", TreeName, false)
		
		return
	end
	
	local TreeData = Tree:HasPlayer(Player) and Tree:GetData(Player)
	
	if TreeData then
		SendRequest(Player, "GetTreeDataResult", TreeName, TreeData)
		
		return
	end
	
	TreeDataRequests[Player.UserId] = if TreeDataRequests[Player.UserId] then TreeDataRequests[Player.UserId] else {}
	
	if not table.find(TreeDataRequests[Player.UserId], TreeName) then
		table.insert(TreeDataRequests[Player.UserId], TreeName)
	end
end

local function ReceivedRequest(Player: Player, Request: "ActivateNode" | "GetTreeData", ...)
	if Request == "ActivateNode" then
		ActivateNodeRequest(Player, ...)
	elseif Request == "GetTreeData" then
		GetTreeDataRequest(Player, ...)
	end
end

RemoteEvent.OnServerEvent:Connect(ReceivedRequest)

function Network.bindNode(TreeName: string, NodeName: string, ActivationCallback: (Player: Player) -> (true?))
	if not Binds[TreeName] then
		Binds[TreeName] = {}
	end
	
	Binds[TreeName][NodeName] = ActivationCallback
end

function Network.unbindNode(TreeName: string, NodeName: string)
	assert(Binds[TreeName], "Tree has no node binded to activation.")
	assert(Binds[TreeName][NodeName], "Node wasn't binded.")
	
	Binds[TreeName][NodeName] = nil
end

function Network.isNodeBinded(TreeName: string, NodeName: string): true?
	if not Binds[TreeName] or not Binds[TreeName][NodeName] then
		return false
	end
	
	return true
end

function Network.setup(getTreeFunction: (TreeName: string) -> ({any}))
	getTree = getTreeFunction
end

function Network.loadTreeToPlayer(Player: Player, TreeName: string, TreeData: {[string]: number})
	local TreeDataRequestPositionInQueue = TreeDataRequests[Player.UserId] and table.find(TreeDataRequests[Player.UserId], TreeName)
	
	if TreeDataRequestPositionInQueue then
		table.remove(TreeDataRequests[Player.UserId], TreeDataRequestPositionInQueue)

		SendRequest(Player, "GetTreeDataResult", TreeName, TreeData)
	end
end

function Network.killPlayer(Player: Player)
	TreeDataRequests[Player.UserId] = nil
end

return Network
