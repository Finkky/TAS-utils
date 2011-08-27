require 'main'


local s = ";"
local lD = "%."
local Y = '1'
local N = '0'
-- local Y = 'yes'
-- local N = 'n/a'
local DC = '-'
local NEW = 'X65594_NEW_594'
local EMPTY = '{}'

local function processHeader(line, dataTempalte)

	local templateIndex = 0
	local templateSubIndex
	local unitnameString

	local doTemp = function(x) 
		if not unitnameString then 
			unitnameString = x; 
		else 
			if (select(1, string.find(x, lD)) == 1) then
				templateIndex = templateIndex + 1; 
				dataTempalte[templateIndex] = {propName = x, subProperties = {}}
				templateSubIndex = 1
			else
				if not dataTempalte[templateIndex].subProperties then error("Wrong data format.") end
				dataTempalte[templateIndex].subProperties[templateSubIndex] = x
				templateSubIndex = templateSubIndex + 1
			end
		end;
	end

	string.gsub(line, "[^"..s.."]+", doTemp)

end

local function processUnitLine(lineSource, dataTempalte)
	
	local lineDataIndex = 1
	local lineData = {}
	
	string.gsub(lineSource, "[^"..s.."]+", function(x) lineData[lineDataIndex] = x; lineDataIndex = lineDataIndex +1; end)

	lineDataIndex = 2
	
	local commands = {}
	
	local digit = "%d+"
	local weaponDefMap = {}
	local newArrays = {}
	local weaponDefOriginalPattern = lD.. "weaponDefs".. lD .. digit.. lD .. "originalName"
	local weaponDefPattern = lD.. "weaponDefs".. lD .. digit .. lD
	
	
	
	for i = 1, #dataTempalte do 

		local dataChunk = lineData[lineDataIndex]
		
		if not (dataChunk == N) then 
			
			commands[i] = {propName = dataTempalte[i].propName, propValue = {}}
			local direct = false
			
			if not (dataChunk == Y) then
				

				
				commands[i].propValue[1] = dataChunk
				direct = true
				
				if (dataChunk == NEW) then
					table.insert(newArrays, dataTempalte[i].propName)
					commands[i].propValue[1] = nil
				end
				
				if string.find(dataTempalte[i].propName, weaponDefOriginalPattern) then
					string.gsub(dataTempalte[i].propName, digit, function(x) weaponDefMap[x] = dataChunk; end)
					commands[i].propValue[1] = nil
				end
			end

			for j = 1, #dataTempalte[i].subProperties do 

				if direct then
					error("Unexpected data")
				end
				
				lineDataIndex = lineDataIndex +1
				
				local subDataChunk = lineData[lineDataIndex]
				
				if (subDataChunk == Y) then
					table.insert(commands[i].propValue, dataTempalte[i].subProperties[j])
				elseif (subDataChunk == N) then
					--OK
				else
					error("Unexpected data")
				end
			end
		else
			commands[i] = {propName = dataTempalte[i].propName, propValue = {}}
			for j = 1, #dataTempalte[i].subProperties do 
				lineDataIndex = lineDataIndex +1
			end
		end
		lineDataIndex = lineDataIndex +1
	end
	
	local tempComms = {}

	for i = 1, #newArrays do
		table.insert(tempComms, {propName = string.gsub(newArrays[i], weaponDefPattern,function(x) return string.gsub(x, digit, function(y) return weaponDefMap[y]; end); end), propValue = {EMPTY}})
		print("*")
	end
	
	for i = 1, #commands do
		commands[i].propName = string.gsub(commands[i].propName, weaponDefPattern,function(x) return string.gsub(x, digit, function(y) return weaponDefMap[y]; end); end)
		if commands[i].propValue[1] or true then
			table.insert(tempComms, commands[i])
		end
	end
	-- for i = 1, #tempComms do 
		-- print(tempComms[i].propName, tempComms[i].propValue[1])
	-- end


	
	return lineData[1], tempComms
end

local function import()
	local fileprefix = "D:/Spring\ TA/TA/units/"

	local headerSource = io.read("*line")
	
	local unitsDataSource = {}
	local index = 1
		
	
	
	for line in io.lines() do
		unitsDataSource[index] = line
		index = index + 1
    end
	
	local dataTempalte = {}
	processHeader(headerSource, dataTempalte)
	
	for i = 1,  #unitsDataSource do --
		
		local unitname, main_commands = processUnitLine(unitsDataSource[i], dataTempalte)
		local filename = fileprefix .. unitname .. ".lua" 
		direct(filename, filename, unitname, main_commands)

		print(i, filename)
			--print (unitname .. main_commands[j].propName, "[["..table.concat(main_commands[j].propValue, " ").. "]]")
	end

end
import(...)









