-- client

--[[
the skill tree is composed of 3 nodes: Node1, Node2 and SpecialNode.
you can try to activate each of them by sending their name in the chat.

Node2 requires Node1 to be activated at least once
SpecialNode requires the player to be named "fraiseFR004" (sigma)

all trees are stored in datastore called "SkillTreeDataStore"
]]

local ClientSkillTreeModule = require(script.Parent.ClientSkillTreeModule)

local Tick = tick()

local SkillTree = ClientSkillTreeModule.loadTree("Simple Skill Tree", function(NodeName, Success, Value)
	if Success then
		print(`The player activated {NodeName} {Value} times.`)
	else
		print(`The player couldn't activate {NodeName}, he previously activated the node {Value} times.`)
	end
end)

print(`Loaded tree "Simple Skill Tree" in {math.round((tick() - Tick)*1000)/1000}s, received data:`)
print(SkillTree:GetData())

local ExistingNodes = {"Node1", "Node2", "SpecialNode"}

game.TextChatService.MessageReceived:Connect(function(Message)
	if table.find(ExistingNodes, Message.Text) then
		SkillTree:ActivateNode(Message.Text)
	else
		print("Node doesn't exist")
	end
end)