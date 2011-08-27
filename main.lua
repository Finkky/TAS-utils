require 'persistence'

local soft = "s"
local hard = "h"
local ex = "e"
local containerName = "data"

local AX_beginExp, AX_endExp = "{", "}"
local AX_approx = "~"
local AX_any = "*"

function isInteger(x)
	return math.floor(x)==x
end

string.split = function(str, pattern)
	pattern = pattern or "[^%s]+"
	if pattern:len() == 0 then pattern = "[^%s]+" end
		local parts = {__index = table.insert}
		setmetatable(parts, parts)
		str:gsub(pattern, parts)
		setmetatable(parts, nil)
		parts.__index = nil
	return parts
end

function table.copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function patternize(str) 
	local index = 0
	local patterns = {}
	
	--print(str)
	local skel = string.gsub(str, '%b{}', function(x) table.insert(patterns, {raw=x, parts={}}); index = index + 1; return "{".. index .."}";  end)
	--print(skel)
	
	getApprox = function(x) 
			if (string.find(x, AX_approx)) then
				return string.gsub(x, AX_approx, "") 
			end
		end
		
	isAny = function(x) return x == AX_any end
	
	for i,v in ipairs(patterns) do 
		--print(i, v.raw)
		string.gsub(v.raw, '[~%w_%*]+', 
			function(x) 
				table.insert (patterns[i].parts, {raw=x, any=isAny(x), approx=getApprox(x)}); 
				--print(x, isAny(x), getApprox(x))
				--print(patterns[i].parts[#patterns[i].parts].raw, patterns[i].parts[#patterns[i].parts].any, patterns[i].parts[#patterns[i].parts].approx); 
			end)
	end

	local tbl = {raw = str, skel = skel, patterns = patterns}
	return tbl
end

function doTable(tbl, list, path, parts)
	
	--print(table.concat(parts, "."))
	path.size = path.size + 1
	
	
	for i,v in pairs(tbl) do

		local level = path.size
		if (parts[level] and (parts[level].any or (parts[level].approx and string.find(i, parts[level].approx)) or (tostring(i) == parts[level].raw))) then
			path.stack[level] = i
			if(#parts == level) then
				table.insert(list, table.copy(path.stack))
			end
			if type(v) == "table" then
				doTable(v, list, path, parts)
			end 
			path.stack[level] = nil
			--print(i, parts[level].raw, "******************")
		else
			--print(i, parts[level].raw)
		end
	end
	path.size = path.size - 1
end

function direct(fileSource, fileTarget, unitname, injectPairs)
	
	local valSettingRows = ""
		
	
	
	
	for i = 1, #injectPairs do
		local val		
		if #injectPairs[i].propValue == 1 then

			local temp = injectPairs[i].propValue[1]
			
			local tempV = tonumber(temp)
			if(tempV) then 
				if isInteger(temp) then
					val = string.format("%d", temp)
				else
					val = string.format("%.4f", temp)
				end
			else
				if(temp=="true" or temp=="false" or temp=="{}") then
					val = string.format("%s", temp)
				else
					val = string.format("[[%s]]", temp)
				end
			end
		
		elseif #injectPairs[i].propValue > 1 then
			val = string.format("[[%s]]", table.concat(injectPairs[i].propValue, " "))
		else
			val = "nil"
		end

		
		local path = {}
		string.gsub(injectPairs[i].propName, "[^%.]+", function(x) if tonumber(x) then table.insert(path,  "[" .. tonumber(x) .. "]") else table.insert(path,  "['" .. x .. "']") end; end)
		
		local prop = containerName..  "['".. unitname .. "']".. table.concat(path)
		valSettingRows = valSettingRows .. string.format("pcall(function() %s = %s; end) \n", prop, val)
	end

	--print (valSettingRows)
	
	local expression = string.format(
	[[
		local %s = dofile("%s")
		%s
		return data
	]]
	, containerName, fileSource, valSettingRows)
	
	local doExp = loadstring(expression)
	
	local stat, data = pcall(doExp)

	if not stat then
		print("Syntax/semantic error")
		print("No data were changed")
		return 
	end

	persistence.store(fileTarget, data, {});
end

function called_main(...)
	return main(arg[1],arg[2],arg[3], true)
end
function main(...)
	
	if #arg < 2 then return end
	local flag = arg[4]
	
	if not flag then
		print("file: " ..(arg[1] or "none"))
		print("key: " ..(arg[2] or "none"))
		print("val: " ..(arg[3] or "none"))
		print("flag: " ..(tostring(arg[4]) or "none"))
	end
	
	local temp = "temp.lua"
	local fileout = arg[1]
	
	local filename = arg[1]
	
	local arg = {k=arg[2], v=arg[3], m="se"}
	
	if arg.k then
		arg.k = patternize(arg.k)

		local tdata = dofile(filename)
		
		local list = {}
		local path = {stack = {}, size = 0}
		
		if (#arg.k.patterns ~= 1) then
			print("Ambiguous param ("..#arg.k.patterns.." key)\n")
			return 1
		else
			arg.k.patterns[1].paths = {}
			doTable(tdata, arg.k.patterns[1].paths, {stack = {}, size = 0}, arg.k.patterns[1].parts)
		end
		
		arg.k.finals = {}
		for i = 1, #arg.k.patterns[1].paths do
			arg.k.finals[i] = string.gsub(containerName.. "['" ..table.concat(arg.k.patterns[1].paths[i], "']['") .. "']", "'%d+'", function(x) return  string.gsub(x,"'","") ;  end);
		end
	end
	
	if arg.k and not arg.v then

		local injectText = ""
		for i = 1, #arg.k.finals do
				injectText = injectText .. arg.k.finals[i] .. ","
		end

		local expression = string.format(
		[[
			local %s = dofile("%s")
			return {%s}
		]]
		, containerName, filename, injectText)
		
		local doExp = loadstring(expression)
		
		--print(expression)
		
		local stat, data = pcall(doExp)
		if not (stat or not flag) then
			print(filename .. " : ")
			print("Injected code: ", injectText)
			print("Syntax/semantic error")
			print("No data were changed")

			return
		end
		
		local processedData = {}
		
		if data then
			for i = 1, #data do
				local key = arg.k.patterns[1].paths[i]
				processedData[key] = {}
				local innerIndex = 1
				string.gsub(tostring(data[i]), '[^ ]+', function(x) processedData[key][innerIndex] = x; innerIndex = innerIndex + 1; end)
			end
		end
		
		if not flag then
			for k, v in pairs(processedData) do 
				print(table.concat(k, "."), table.concat(processedData[k], " "))
			end
		end
		
		return processedData
	end 
	
	local valSettingRows = ""
	
	if  arg.k and arg.v then
		arg.v = patternize(arg.v)
		
		for i = 1, #arg.v.patterns do
			arg.v.patterns[i].paths = {}
			doTable(tdata, arg.v.patterns[i].paths, {stack = {}, size = 0}, arg.v.patterns[i].parts)
			if (#arg.v.patterns[i].paths ~= 1) then
				print("Ambiguous param (" .. #arg.v.patterns[i].paths .. " possibilites) (value, ".. i ..")\n")
				return 1
			else 
				arg.v.patterns[i].path = arg.v.patterns[i].paths[1]
			end
		end
		
		local index = 0
		arg.v.final = string.gsub(arg.v.skel, '{%d}', function(x) index = index + 1; return containerName.. "." ..table.concat(arg.v.patterns[index].path, ".");  end)
		
		if string.find(arg.m, ex) then
			for i = 1, #arg.k.finals do
				valSettingRows = valSettingRows .. arg.k.finals[i] .. "=" .. arg.v.final .. "\n"
			end
		end
	end
	
		
	local data
	-- local out
	
	-- out = "%q"
	
	-- if string.find(arg.m, soft) then
		-- arg.hard= false	
		-- local tempV = tonumber(arg.v)
		-- if(tempV) then 
			-- if isInteger(tempV) then
				-- out = "%d"
			-- else
				-- out = "%.4f"
			-- end
		-- else
			-- if(arg.v=="true" or arg.v=="false") then
				-- out = "%s"
			-- else
				-- if string.find(arg.m, ex) then
					-- out = "%s"
				-- else
					-- out = "%q"
				-- end
			-- end
		-- end
	-- else
		-- print("hard")
		-- arg.hard= true
	-- end

	local expression = string.format(
	[[
		local %s = dofile("%s")
		%s
		return data
	]]
	, containerName, filename, valSettingRows)
	

	local doExp = loadstring(expression)
	
	local stat, data = pcall(doExp)

	if not stat then
		print(filename)
		print("Syntax/semantic error")
		print("No data were changed")
		return
	end

	persistence.store(fileout, data, arg);
end


main(...)





