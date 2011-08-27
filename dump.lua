require 'main'



local function preProcessUnit(unitTable,  unitData)

	for k, v in pairs(unitTable) do
	
		if(k[2] == "weapons") then
			if k[4] and k[4] == "def" then
			
				if not unitData.weaponMap[v[1]] then 
					unitData.weaponMap[v[1]] = unitData.weaponIndex
					unitData.weaponIndex = unitData.weaponIndex + 1
				end
			end
		end
		
		if(k[2] == "featureDefs") then
			if k[3] then 
				if not unitData.featureMap[k[3]] then 
					unitData.featureMap[k[3]] = unitData.featureIndex
					unitData.featureIndex = unitData.featureIndex + 1
				end
			end
		end
		
		if(k[2] == "weaponDefs") then
			if k[3] then 
				if not unitData.weaponMap[k[3]] then 
					unitData.weaponMap[k[3]] = unitData.weaponIndex
					unitData.weaponIndex = unitData.weaponIndex + 1
				end
			end
		end
	end
	return unitData
end

local function processUnit(bigTable, unitTable,  unitData)

	local key
	for k, v in pairs(unitTable) do
		key = k[1]
		
		k[1] = ""
		
		if(k[2] == "weapons") then
			if k[4] and k[4] == "def" then
			
				if not unitData.weaponMap[v[1]] then error("BANG") return end
				v[1] = unitData.weaponMap[v[1]]

			end
		end
		
		if(k[2] == "featureDefs") then
			if k[3] then 
				if not unitData.featureMap[k[3]] then error("BANG") return end
				k[3] = unitData.featureMap[k[3]]
			end
		end
		
		if(k[2] == "weaponDefs") then
			if k[3] then 
				if not unitData.weaponMap[k[3]] then  error("BANG")	return 	end
				k[3] = unitData.weaponMap[k[3]]
			end
		end

		valName = table.concat(k, ".")
		
		--print(#v)
		
		
		if not bigTable.data[key] then
			bigTable.data[key] = {}
		end
		
		if not bigTable.metadata[valName] then
			bigTable.metadata[valName] = {vals={}, maxVals=0}
		end
		
		bigTable.data[key][valName] = v
		
		for i = 1, #v do 
			bigTable.metadata[valName].vals[v[i]] = v[i]
		end
		bigTable.metadata[valName].maxVals = math.max(bigTable.metadata[valName].maxVals, #v)
		--if #v > 1 then print(key, #v) end
	end
	
	if key then

		for k, v in pairs(unitData.weaponMap) do
			local temp = string.format( ".weaponDefs.%d.originalName", v)
			bigTable.data[key][temp] = {k}
			bigTable.metadata[temp] = {vals={}, maxVals=1}
			bigTable.metadata[temp].vals[k] = k
			
		end
		
		for k, v in pairs(unitData.featureMap) do
			local temp = string.format( ".featureDefs.%d.originalName", v)
			bigTable.data[key][temp] = {k}
			bigTable.metadata[temp] = {vals={}, maxVals=1}
			bigTable.metadata[temp].vals[k] = k
		end
	end
	
	
	
	return bigTable, unitData
end

local s = ";"
--local Y = 1
local Y = "yes"
--local N = 0
local N = "n/a"

local function dumpTable(bigTable) 
	local content = ""
	local header = "unitname" .. s
	
	local vals = {}
	
	for k, v in pairs(bigTable.metadata) do
		local index = 1
		vals[k] = {vals={}, maxVals=v.maxVals}
		for _, v2 in pairs(v.vals) do
			vals[k].vals[index] = v2
			index = index + 1
		end
		if #vals[k].vals > 1 then
			table.sort(vals[k].vals, function(a, b) return tostring(a) < tostring(b); end)
		end
	end

	
	local tempVals = {}
	local j = 1
	for k, v in pairs(vals) do
		tempVals[j] = {k=k,v=v.vals, m = v.maxVals}
		j = j + 1
	end
	
	table.sort(tempVals, function(a,b) return a.k< b.k end)
	
	for l = 1, #tempVals do
		local k = tempVals[l].k
		local v = tempVals[l].v
		local maxv = tempVals[l].m
		
		header = header .. k .. s
		if maxv > 1 then
			for m = 1, #v do
				header = header .. v[m] .. s
			end
		end
	end
	
	content = content ..header .."\n"
	
	for unitName, unitData in pairs(bigTable.data) do
		local row = unitName  .. s
		

		for l = 1, #tempVals do
		--for k, v in pairs(vals) do
			local k = tempVals[l].k
			local v = tempVals[l].v
			local maxv = tempVals[l].m
			
			if unitData[k] then
				if maxv >1 then
					row = row .. Y .. s
					table.sort(unitData[k], function(a, b) return tostring(a) < tostring(b); end)
					local upi = 1
					for vi = 1, #v do 
						
						if(v[vi] == unitData[k][upi]) then
							 row = row .. Y .. s
							 upi = upi + 1
						else
							row = row .. N .. s
						end
					end			
				else
					-- local valOut
					-- local tempV = tonumber(unitData[k][1])
					-- if(tempV) then 
						-- if isInteger(tempV) then
							-- valOut = string.format("%d", unitData[k][1])
						-- else
							-- valOut = string.format("%.2f", unitData[k][1])
						-- end
					-- else
						-- if(arg.v=="true" or arg.v=="false") then
							-- valOut = string.format("%s", unitData[k][1])
						-- else
							-- valOut = string.format("%s", unitData[k][1])
						-- end
					-- end
					row = row .. unitData[k][1] .. s
				end
			else
				if maxv >1 then
					row = row .. Y .. s
					for vi = 1, #v do 
						row = row .. N .. s
					end			
				else
					row = row .. N .. s
				end
			end
		end
		local counter = 0
		content = content.. row .."\n"
		
	end
	
	print(content)
end

local function dump()

	local filenames = {}
	
	local index = 1
	for line in io.lines() do
		filenames[index] = line
		index = index + 1
    end
	
	bigTable = {data = {}, metadata = {}}
	
	
	
	for i = 1, #filenames do
	
		local unitData = {featureIndex = 1,  weaponIndex = 1, featureMap = {}, weaponMap = {}}
				
		for k = 1, #arg do
			unitData = preProcessUnit(called_main(filenames[i], arg[k] or "{}") or {},  unitData)
		end
		
		local temp = {}
		for k, v in pairs(unitData.featureMap) do
			table.insert(temp, k)
		end
		table.sort(temp)
		
		for i = 1, #temp do
			unitData.featureMap[temp[i]] = i
		end
		
		temp = {}
		for k, v in pairs(unitData.weaponMap) do
			table.insert(temp, k)
		end
		table.sort(temp)
		
		for i = 1, #temp do
			unitData.weaponMap[temp[i]] = i
		end
		
				
		for k = 1, #arg do
			bigTable, unitData = processUnit(bigTable, called_main(filenames[i], arg[k] or "{}") or {},  unitData)
		end
	end
	
	dumpTable(bigTable)
	
	--main("abuilderlvl1.lua", "{*.*.*.~Cat}")
end
dump(...)
