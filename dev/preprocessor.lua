local lfs = require("lfs") -- LuaFileSystem for directory traversal

-- Input and output directories
local output_dir = "./../temp" -- Temporary directory for preprocessed files

-- Ensure the output directory exists
lfs.mkdir(output_dir)

-- Function to preprocess a file
local function preprocess_file(input_file, output_file)
    local file = io.open(input_file, "r")
    if not file then
        print("Error: Could not open file " .. input_file)
        return
    end

    local lines = {}
    local inBlock = false;
    for line in file:lines() do
        -- Apply transformations to each line
        local transformed = 0

        if inBlock then
            if string.match(line, "^%-%-%- ") then
                line = line:gsub("^%-%-%- (.*)$", "-- %1")
            elseif string.match(line, "^%-%-%-") then
                line = line:gsub("^%-%-%-(.*)$", "--%1")
            else
                inBlock = false;
            end
        else
            if string.match(line, "^%-%-%- ") then
                inBlock = true;
            end
        end

        -- 1. `--- @param name any` -> `-- @param name`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @param%s+([a-zA-Z0-9_]+)%s+any", "-- @param %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 2. `--- @param name type` -> `-- @tparam type name`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @param%s+([a-zA-Z0-9_]+)%s+([a-zA-Z0-9_]+)", "-- @tparam %2 %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 3. `--- @param name? any` -> `-- @param[opt] name`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @param%s+([a-zA-Z0-9_]+)%?%s+any", "-- @param[opt] %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 4. `--- @param name? type` -> `-- @tparam[opt] type name`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @param%s+([a-zA-Z0-9_]+)%?%s+([a-zA-Z0-9_]+)", "-- @tparam[opt] %2 %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 5. `--- @return any` -> `-- @return`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @return%s+any", "-- @return")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 6. `--- @return type` -> `-- @treturn type`
        if transformed == 0 then
            line, transformed = line:gsub("^%-%- @return%s+([a-zA-Z0-9_]+)", "-- @treturn %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 7. Blank lines starting with `--- @diagnostic`
        if transformed == 0 then
            line, transformed = line:gsub("%-%-%- @diagnostic .*", "")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- Add the processed line to the output
        table.insert(lines, line)
    end
    file:close()

    -- Write the transformed content to the output file
    file = io.open(output_file, "w")
    file:write(table.concat(lines, "\n"))
    file:close()
end

-- Function to recursively process all Lua files in a directory
local function preprocess_directory(input_dir, output_dir)
    for file in lfs.dir(input_dir) do
        if file ~= "." and file ~= ".." then
            local input_path = input_dir .. "/" .. file
            local output_path = output_dir .. "/" .. file

            local attr = lfs.attributes(input_path)
            if attr.mode == "directory" then
                lfs.mkdir(output_path)
                preprocess_directory(input_path, output_path)
            elseif file:match("%.lua$") then
                preprocess_file(input_path, output_path)
            end
        end
    end
end

-- Run the preprocessor
preprocess_file("./scriptutils.lua", output_dir .. "/scriptutils.lua")
preprocess_directory("./../baked", output_dir)
print("Preprocessing complete. Files saved to " .. output_dir)