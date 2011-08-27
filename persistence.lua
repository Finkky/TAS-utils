--[[ License: MIT (see bottom) ]]

-- Private methods
local write, writeIndent, writers, refCount;

local cmp = function(a,b)
	print(a, b)
	if type(a.k) ~= type(b.k) then return type(a.k) < type(b.k)
	elseif type(a.k) == "table" then return false
	else 
		if type(a.v) == type(b.v) then
			return a.k<b.k
		elseif type(a.v) == "table" then
			return false
		elseif type(b.v) == "table" then		
			return true
		else
			return a.k<b.k
		end
	end
end



lowerkeys = function(table)
	return table
end

function isInteger(x)
return math.floor(x)==x
end

local cmp = function(a,b)
	if type(a.k) ~= type(b.k) then return type(a.k) < type(b.k)
	elseif type(a.k) == "table" then return false
	else 
		if type(a.v) == type(b.v) then
			if type(a.k) == type(b.k) and type(a.k) == "string" then
				return a.k:lower() < b.k:lower()
			end
			return a.k<b.k
		elseif type(a.v) == "table" then
			return false
		elseif type(b.v) == "table" then		
			return true
		else
			if type(a.k) == type(b.k) and type(a.k) == "string" then
				return a.k:lower() < b.k:lower()
			end
			return a.k<b.k
		end
	end
end

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key, v in pairs(t) do
        table.insert( orderedIndex, {k=key,v=v} )
    end
    table.sort( orderedIndex,  cmp)
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
		key = nil
		if (t.__orderedIndex[1]) then
			key = t.__orderedIndex[1].k
		end
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i].k == state then
			if t.__orderedIndex[i+1] then
				key = t.__orderedIndex[i+1].k
			else
				key = nil
			end
            
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

local Params = {wrapper = "unitDef", unamePropName = "unitName"}
local DefContainer
local LuaKW = {["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true, ["while"] = true}



local function isDef(str)
	if str == "featureDefs" or str == "weaponDefs" then
		return true
	end
	return false
end


local file, e;

local writeStringFlag = false
local writeString = ""
local function file_write(str)
	if writeStringFlag then
		writeString = writeString .. str
	else
		writeString = ""
		file:write(str)
	end
end



local postAssignStringBuffer
persistence =
{
	store = function (path, data, arg)
		postAssignStringBuffer = ""
		DefContainer = {}
		
		for k, _ in pairs(data) do
			Params.defName = k
			break
		end
		
		if (LuaKW[k] or (select(1, string.find(Params.defName,"[a-zA-Z]")) ~= 1 ) or string.find(Params.defName,"[^a-zA-Z0-9_]")) then 
			Params.escName = string.format("['%s']", Params.defName)
		else
			Params.escName = string.format(".%s", Params.defName)
		end
		
		if arg then
			Params.features=
				{
					{
						test="heap",
						properties= 
						{
							{
								test = "metal",
								prop = Params.wrapper.. ".buildCostMetal",
								propVal = data[Params.defName]["buildCostMetal"],
							},
							{
								test = "damage",
								prop = Params.wrapper.. ".maxDamage",
								propVal = data[Params.defName]["maxDamage"],
							},
							{
								test = "description",
								prop = Params.wrapper.. ".name",
								propVal = data[Params.defName]["name"],
							}
							
						}
					},
					{
						test="dead",
						properties= 
						{
							{
								test = "metal",
								prop = Params.wrapper.. ".buildCostMetal",
								propVal = data[Params.defName]["buildCostMetal"],
							},
							{
								test = "damage",
								prop = Params.wrapper.. ".maxDamage",
								propVal = data[Params.defName]["maxDamage"],
							},
							{
								test = "description",
								prop = Params.wrapper.. ".name", 
								propVal = data[Params.defName]["name"], 
							}
						}
					},
					-- {
						-- test= "buildtime",
						-- properties= 
						-- {
							-- {
								-- test = "buildtime",
								-- prop = Params.wrapper .. ".buildCostEnergy",  --data.[1].buildCostMetal
								-- propVal = data[Params.defName]["buildCostEnergy"],  --
							-- }
						-- }
					-- }
				}
		end

		
		if type(path) == "string" then
			-- Path, open a file
			file, e = io.open(path, "w");
			if not file then
				return error(e);
			end
		else
			-- Just treat it as file
			file = path;
		end

		local objRefNames = {};
		local key_path = {};
		
		local hr = "--------------------------------------------------------------------------------\n"
		local br = "\n"
		
		file_write("-- UNITDEF -- ".. Params.defName:upper() .." --\n")
		file_write(hr)
		file_write(br)
		file_write(string.format("local %s = %q", Params.unamePropName, Params.defName));
		file_write(br)
		file_write(br)
		file_write(hr)
		file_write(br)
		file_write("local "..Params.wrapper.." = ");
		write(file, data, -1, objRefNames, key_path, arg);
		file_write(br)

		local defPrint = function(k, v)
			file_write(br)
			file_write(hr)
			file_write(br)
			file_write(string.format("local %s = ", k));
			file_write(v)
			file_write(br)
			file_write(string.format("%s.%s = %s", Params.wrapper, k, k));
			file_write(br)
			file_write(br)
		end
			
		local dtemp = "weaponDefs"
		if DefContainer[dtemp] then
			defPrint(dtemp, DefContainer[dtemp])
			DefContainer[dtemp] =nil
		end
		
		dtemp = "featureDefs"
		if DefContainer[dtemp] then
			defPrint(dtemp, DefContainer[dtemp])
			DefContainer[dtemp] =nil
		end

		dtemp = nil
		
		for k , v in pairs(DefContainer) do
			defPrint(k, v)
		end
		
		if(postAssignStringBuffer ~= "") then
			file_write(hr)
			file_write(br)
			file_write(postAssignStringBuffer);
			file_write(br)
		end
		
		file_write(hr)
		file_write(br)
		file_write("return lowerkeys({[".. Params.unamePropName .."] = "..Params.wrapper.."})\n");
		file_write(br)
		file_write(hr)
		
		file:close();
		
	end;

	load = function (path)
		local f, e = loadfile(path);
		if f then
			return f();
		else
			return nil, e;
		end;
	end;
}


local function buildPath(path)
	local str = ""
	for i = 1, #path do
		if(select(1, string.find(path[i],"%[")) == 1) then
			str = str .. path[i]
		else
			str = str .. "." .. path[i]
		end
	end
	return str
end


-- Private methods

-- write thing (dispatcher)
write = function (file, item, level, objRefNames, key_path, arg)
	return writers[type(item)](file, item, level, objRefNames, key_path, arg);
end;

-- write indent
writeIndent = function (file, level)
	local str = ""
	for i = 1, level do
		file_write("\t");
		str = str .."\t"
	end;
	return str
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;


-- Format items for the purpose of restoring
writers = {
	["nil"] = function (file, item)
			file_write("nil");
			return "nil"
		end;
	["number"] = function (file, item, level, _, key_path, arg)
		local str = ""
		if(key_path and arg) then
			
			for k, v in pairs(Params.features) do
				if (string.find(table.concat(key_path, "."):lower(), v.test)) then
					for k2, v2 in ipairs(v.properties) do
						if (key_path[#key_path]:lower() == v2.test) then
							local out = string.format("%.4f * %s", item / v2.propVal, v2.prop)
							if(isDef(key_path[1])) then
								file_write(out)
								str = str .. out
							else
								postAssignStringBuffer = postAssignStringBuffer .. Params.wrapper .. buildPath(key_path) .. " = " .. out .. "\n";
								file_write("nil");
								str = str .. "nil"
							end
							return str
						end
					end
				end
			end
		end
		file_write(item);
		str = str .. item
		return str
	end;
	["string"] = function (file, item, level, _, key_path, arg)
		local str = ""
		if(key_path and arg) then
			for k, v in pairs(Params.features) do
				if (string.find(table.concat(key_path, "."):lower(), v.test)) then
					for k2, v2 in ipairs(v.properties) do
						if (key_path[#key_path]:lower() == v2.test) then
							if(string.find(item, v2.propVal)) then
								local out = string.format("%s .. [[%s]]", v2.prop, string.gsub(item, v2.propVal, ""))
								if(isDef(key_path[1])) then
									file_write(out)
									str = str .. out
								else
									postAssignStringBuffer = postAssignStringBuffer .. Params.wrapper .. buildPath(key_path) .. " = " .. out .. "\n";
									file_write("nil");
									str = str .. "nil"
								end
								return str
							end
						end
					end
				end
			end
		end
		file_write(string.format("[[%s]]", item));
		str = str .. string.format("[[%s]]", item)
		return str
	end;
	["boolean"] = function (file, item)
		local str = ""
			if item then
				file_write("true");
				str = str .. "true"
			else
				file_write("false");
				str = str .. "false"
			end
			return str
		end;
	["table"] = function (file, item, level, objRefNames, key_path, arg)
			local str = ""
			-- Single use table
			
			if level > -1 then
				file_write("{\n");
				str = str .. "{\n"
			end
			
			for k, v in orderedPairs(item) do
				if level > -1 then
					writeIndent(file, level+1);
					if(type(k)=="string") then

						if (LuaKW[k] or (select(1, string.find(k,"[a-zA-Z]")) ~= 1 ) or string.find(k,"[^a-zA-Z0-9_]")) then 
							file_write(string.format("['%s'] = ", k));
							str = str .. string.format("['%s'] = ", k)
							key_path[#key_path + 1] = string.format("['%s']", k)
						else
							file_write(string.format("%s = ", k));
							str = str .. string.format("%s = ", k)
							key_path[#key_path + 1] = string.format("%s", k)
						end
					else
						file_write("[");
						str = str .. "["
						local temps = write(file, k, level+1, objRefNames);
						
						key_path[#key_path + 1] = "[" .. temps .. "]"
						
						str = str .. temps
						file_write("] = ");
						str = str .. "] = "
					end
					

					if isDef(k) then
						writeStringFlag = true
						write(file, v, 0, objRefNames, key_path, arg);
						DefContainer[k] = writeString
						writeStringFlag = false
						file_write("nil");
						str = str .. "nil"
					else
						str = str .. write(file, v, level+1, objRefNames, key_path, arg);
					end

					file_write(",");
					str = str .. ","
					--file_write("-- " ..  table.concat(key_path, "."));
					key_path[#key_path] = nil
					file_write("\n");
					str = str .. "\n"
				else
					write(file, v, 0, objRefNames, key_path, arg);
					break
				end
			end
			
			if level > -1 then
				str = str .. writeIndent(file, level);
				file_write("}");
				str = str .. "}"
			end

			return str
		end;
	["function"] = function (file, item)
			-- Does only work for "normal" functions, not those
			-- with upvalues or c functions
			local dInfo = debug.getinfo(item, "uS");
			if dInfo.nups > 0 then
				file_write("nil --[[functions with upvalue not supported]]");
			elseif dInfo.what ~= "Lua" then
				file_write("nil --[[non-lua function not supported]]");
			else
				local r, s = pcall(string.dump,item);
				if r then
					file_write(string.format("loadstring(%q)", s));
				else
					file_write("nil --[[function could not be dumped]]");
				end
			end
			return "#"
		end;
	["thread"] = function (file, item)
			file_write("nil --[[thread]]\n");
			return "#"
		end;
	["userdata"] = function (file, item)
			file_write("nil --[[userdata]]\n");
			return "#"
		end;
}

--[[
 Copyright (c) 2010 Gerhard Roethlin

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
]]
