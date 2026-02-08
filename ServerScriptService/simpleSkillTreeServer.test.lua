-- server

--[[
the skill tree is composed of 3 nodes: Node1, Node2 and SpecialNode.
you can try to activate each of them by sending their name in the chat.

Node2 requires Node1 to be activated at least once
SpecialNode requires the player to be named "fraiseFR004" (sigma)

all trees are stored in datastore called "SkillTreeDataStore"
]]

local ServerSkillTreeModule = require(script.Parent.ServerSkillTreeModule)

local SkillTree = ServerSkillTreeModule.new("Simple Skill Tree")

local function NodeActivatedCallback(Player: Player, NodeName: string, Value: number): true?
	print(`{Player.Name} activated {NodeName} {tostring(Value + 1)} times.`)
	return true
end

SkillTree:AddNode("Node1", {}, NodeActivatedCallback)
SkillTree:AddNode("Node2", {Node1 = 1}, NodeActivatedCallback)

SkillTree:AddNode("SpecialNode", {}, function(Player, _, Value)
	if Player.Name == "fraiseFR004" then
		print(`{Player.Name} activated SpecialNode {tostring(Value + 1)} times.`)
		return true
	else
		print(`{Player.Name} isn't sigma he can't activate SpecialNode.`)
		return
	end
end)