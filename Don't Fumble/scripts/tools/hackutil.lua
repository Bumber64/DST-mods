
--Collection of useful functions for DST modding
--Authored by Bumber64, derived from others' work where noted
--Do whatever you want with my stuff, derived works possibly subject to restrictions

HackUtil = {}

-----------------------------------------
-- Functions derived from others' code --
-----------------------------------------

--Sorted pairs iterator:
--https://stackoverflow.com/a/15706820
function HackUtil.spairs(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys+1] = k
    end

    table.sort(keys)

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local spairs = HackUtil.spairs --local copy for convenience

--Based on Rezecib's UpvalueHacker (but won't crash the game):
--https://github.com/rezecib/Rezecib-s-Rebalance/blob/d4a41b0c28a117c1a4efadf220347a6db7164bb3/scripts/tools/upvaluehacker.lua
--If returns nil, second return is error message. Just concat it after the name of your starting fn and print.
function HackUtil.GetUpvalue(fn, ...)
    local scope_fn = fn
    local cur_name, cur_fn

    for k, v in ipairs({...}) do --we can do all this without a helper fn
        local i = 0
        repeat
            i = i + 1
            cur_name, cur_fn = debug.getupvalue(scope_fn, i)
            if not cur_name then --not found, indicate how far we got
                return nil, " -> "..table.concat({...}, " -> ", 1, k).." not found!"
            end
        until (cur_name == v)

        scope_fn = cur_fn
    end

    return cur_fn
end

--Find scope_fn with HackUtil.GetUpvalue first before calling.
--If a fn with fn_name is found in scope_fn, will replace the fn with new_fn and return true.
function HackUtil.SetUpvalue(scope_fn, new_fn, fn_name)
    local cur_name

    local i = 0
    repeat
        i = i + 1
        cur_name = debug.getupvalue(scope_fn, i)
        if not cur_name then --not found
            return false --DEBUG
        end
    until (cur_name == fn_name)

    debug.setupvalue(scope_fn, i, new_fn)

    return true
end

-----------------------------------
-- Bumber64's original functions --
-----------------------------------

--For printing nested tables on a single line. Optional limit on recursive tables, more compact output than table.inspect(t)
function HackUtil.table_string(t, recursions)
    if type(t) == "table" and (not recursions or recursions >= 0) then
        local s = "{"
        local multi

        for k, v in spairs(t) do
            s = s..(multi and ", " or "")..tostring(k).." = "..HackUtil.table_string(v, recursions and recursions-1 or nil)
            multi = true
        end

        return s.."}"
    elseif type(t) == "string" then
        return "\""..tostring(t).."\""
    elseif type(t) == "number" then
        return tostring(t)
    else
        return "("..tostring(t)..")"
    end
end

local table_string = HackUtil.table_string --local copy for convenience

--Helper fn for HackUtil.brain_exam
local function examine_nodes(node, path)
    local s = ""
    for k, v in ipairs(node.children or {}) do
        s = s..examine_nodes(v, path..", "..tostring(k))
    end

    return path..": \""..tostring(node.name).."\""..(node.getactionfn and " | getactionfn = ("..tostring(node.getactionfn)..")\n" or "\n")..s
end

--Neater and more info than print(self.brain)
--Usage: brain_exam(c_select()) --from console after setting GLOBAL.brain_exam to this fn
function HackUtil.brain_exam(self)
    if self and self.brain and self.brain.bt and self.brain.bt.root then
        print("\nBehaviour nodes for ("..tostring(self.prefab).."):\n"..examine_nodes(self.brain.bt.root, "R"))
    end
end

--Helper fn for HackUtil.surgery_table
--Key on node number and combine redundant paths (for more compact surgery table.)
--WARNING: input table t not preserved, don't use it after calling!
--Sample input: {{1, 2, 4, 2, 2, "StealFoodAction"}, {1, 2, 6, "StealFoodAction"}, {1, 2, 7, "empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end"}}
--Sample output: {1 = {2 = {4 = {2 = {2 = "StealFoodAction"}}, 6 = "StealFoodAction", 7 = "empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end"}}}
local function combine_path_table(t)
    local out = {}
    if #t < 2 then --no possible splits, just convert
        if #t[1] > 1 then --first element is number
            local node_num = table.remove(t[1], 1)
            out[node_num] = combine_path_table(t)
        elseif #t[1] == 1 then --just a table with a string
            out = t[1][1] --return the string instead of a table
        end
        return out
    end

    for _, v in ipairs(t) do --categorize by first node_num
        if #v > 1 then --first element is number
            local node_num = table.remove(v, 1)
            if not out[node_num] then
                out[node_num] = {} --make sure table exists
            end
            table.insert(out[node_num], v)
        end
    end

    for k, v in pairs(out) do --for each node_num in out
        out[k] = combine_path_table(v) --recursively convert and replace tables
    end

    return out
end

--Helper fn for HackUtil.surgery_table
--Takes output of combine_path_table and builds the <prefab.name>_surgery table that HackUtil.perform_surgery uses.
local function build_surgery_table(node, t, node_num, indent)
    indent = indent or 0
    local s = "{"

    if node_num then --not root
        s = s.."num = "..tostring(node_num)..", "
    end

    s = s.."name = \""..node.name.."\", "

    if type(t) == "string" then
        s = s.."fn = "..t.."}" --t can contain arbritrary extra keys (e.g., "cond = ")
    elseif type(t) == "table" then
        local child_s = ""

        local count = 0
        for k, v in spairs(t) do --iterate ascending node_num
            child_s = child_s..(count > 0 and ",\n"..string.rep("    ", indent+1) or "")..build_surgery_table(node.children[k], v, k, indent+1)
            count = count + 1
        end

        s = s..(count > 1 and "children =\n" or "child =\n")..string.rep("    ", indent+1)..
            (count > 1 and "{" or "")..child_s..(count > 1 and "}\n" or "\n")..string.rep("    ", indent).."}"
    end

    return s
end

--Build a table for use with HackUtil.perform_surgery --Set GLOBAL.surgery_table to this fn and run from console.
--Each entry in the "paths" table should be a list of child nodes to follow, terminated by a string that
--  contains a function accessible from your modmain.lua (or wherever you're keeping the outputted surgery table.)
--You may optionally add ", cond = " to the string and a function to be tested by your modmain.lua to check if the replacement should actually occur at runtime.
--Sample use: surgery_table(c_select(), {{1,2,4,2,2,"StealFoodAction"}, {1,2,6,"StealFoodAction"}, {1,2,7,"empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end"}})
--See example modmain.lua for context: https://github.com/Bumber64/DST-mods/blob/3f07de8db94513bb9448d94ff10ddff8d0081abc/Don't%20Fumble/modmain.lua#L368
function HackUtil.surgery_table(self, paths)
    if self and paths and type(paths) == "table" and self.brain and self.brain.bt and self.brain.bt.root then
        local surgery_string = build_surgery_table(self.brain.bt.root, combine_path_table(paths))
        print("\nlocal "..tostring(self.prefab).."_surgery =\n"..surgery_string)
    end
end

--[[
--Sample output of HackUtil.surgery_table:
local bearger_surgery =
{name = "Priority", child =
    {num = 1, name = "Parallel", child =
        {num = 2, name = "Priority", children =
            {{num = 4, name = "Parallel", child =
                {num = 2, name = "Priority", child =
                    {num = 2, name = "DoAction", fn = StealFoodAction}
                }
            },
            {num = 6, name = "DoAction", fn = StealFoodAction},
            {num = 7, name = "AttackHive", fn = empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end}}
        }
    }
}

--Use it like this:
AddBrainPostInit("beargerbrain", function(self)
    local err_msg = HackUtil.perform_surgery(self.bt.root, bearger_surgery)
    if err_msg then
        print(err_msg)
    end
end)
--]]

--Replaces action fns in brain nodes using a pre-generated table from HackUtil.surgery_table filled with node info.
--Sample usage: see AddBrainPostInit example above
function HackUtil.perform_surgery(node, t)
    if not node or not t then
        return ("Brain surgery nil argument!\nnode.name = %s\nt = %s"):format(tostring(node and node.name or nil), table_string(t, 1))
    elseif node.name ~= t.name then
        return ("Brain surgery node name mismatch!\nnode.name = %s\nt.name = %s\nt = %s"):format(tostring(node.name), tostring(t.name), table_string(t, 1))
    elseif t.child then --proceed
        if t.child.num then
            local err_msg = HackUtil.perform_surgery(node.children[t.child.num], t.child)
            if err_msg then
                return err_msg
            end
        else
            return ("Brain surgery nil child.num beyond root node!\nt.name = %s\nt.child.name = %s\nt = %s"):format(tostring(t.name), tostring(t.child.name), table_string(t, 1))
        end
    elseif t.children then --fork
        for i, child in ipairs(t.children) do
            if child.num then
                local err_msg = HackUtil.perform_surgery(node.children[child.num], child)
                if err_msg then
                    return err_msg
                end
            else
                return ("Brain surgery nil child.num beyond root node!\nt.name = %s\nt.children[%d].name = %s\nt = %s"):format(tostring(t.name), i, tostring(child.name), table_string(t, 2))
            end
        end
    end

    if t.fn and (not t.cond or t.cond()) then
        if not node.getactionfn then
            return ("Brain surgery node.getactionfn was nil!\nnode.name = %s\nt = %s"):format(tostring(node.name), table_string(t, 1))
        else
            node.getactionfn = t.fn
        end
    end
end

return HackUtil
