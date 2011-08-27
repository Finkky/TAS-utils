require 'main'

local function batch()


	local filenames = {}
	
	local index = 1
	for line in io.lines() do
		filenames[index] = line
		index = index + 1
    end

	
	for i = 1, #filenames do
		called_main(filenames[i])
		print(filenames[i])
	end

end
batch(...)