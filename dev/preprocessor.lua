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

    local lineCounter = 0;

    local lines = {}
    local pendingblock = nil;
    local inBlock = false;
    for line in file:lines() do
        lineCounter = lineCounter + 1;

        -- Apply transformations to each line
        local transformed = 0

        if inBlock then
            if string.match(line, "^%s*%-%-%- ") then
                line = line:gsub("^%s*%-%-%- (.*)$", "-- %1")
            elseif string.match(line, "^%s*%-%-%-") then
                line = line:gsub("^%s*%-%-%-(.*)$", "--%1")
            else
                inBlock = false;
                if pendingblock then
                    local dontLike = false;
                    for i = 1, #pendingblock do
                        if string.match(pendingblock[i], "^%-%- @overload") then
                            dontLike = true;
                            break;
                        end
                    end
                    if not dontLike then
                        for i = 1, #pendingblock do
                            table.insert(lines, pendingblock[i]);
                        end
                    end
                    pendingblock = nil;
                end
            end
        else
            if string.match(line, "^%s*%-%-%- ") then
                inBlock = true;
                pendingblock = {};
            end
        end

        line = line:gsub("%-%- \\@", "-- @")

        -- 1. `--- @module 'name'` -> `-- @module name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @module%s+'([a-zA-Z0-9_]+)'", "-- @module %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 1. `--- @vararg any` -> `-- @param ...`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @vararg%s+any", "-- @param ...")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 2. `--- @vararg type` -> `-- @tparam ... type`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @vararg%s+([a-zA-Z0-9_]+)", "-- @tparam %1 ...")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 1. `--- @param name any` -> `-- @param name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @param%s+([a-zA-Z0-9_]+)%s+any", "-- @param %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 2. `--- @param name type` -> `-- @tparam type name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @param%s+([a-zA-Z0-9_]+)%s+([a-zA-Z0-9_|]+)", "-- @tparam %2 %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 3. `--- @param name? any` -> `-- @param[opt] name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @param%s+([a-zA-Z0-9_]+)%?%s+any", "-- @param[opt] %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 4. `--- @param name? type` -> `-- @tparam[opt] type name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @param%s+([a-zA-Z0-9_]+)%?%s+([a-zA-Z0-9_|]+)", "-- @tparam[opt] %2 %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 5. `--- @return any[]` -> `-- @return`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @return%s+any%[%]", "-- @return any[]")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 6. `--- @return any` -> `-- @return`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @return%s+any", "-- @return")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 7. `--- @return type?` -> `-- @treturn type|nil`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @return%s+([a-zA-Z0-9_|]+)%?", "-- @treturn %1|nil")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 7. `--- @return type` -> `-- @treturn type`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @return%s+([a-zA-Z0-9_|]+)", "-- @treturn %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- X. `--- @type stuff` -> `--`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @type.*", "-- ")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 8. `--- @alias name type` -> `-- @type name`
        if transformed == 0 then
            line, transformed = line:gsub("%-%- @alias%s+([a-zA-Z0-9_]+)%s+([a-zA-Z0-9_|-]+)", "-- @type %1")
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 9. Blank lines starting with `--- @operator`
        if transformed == 0 then
            --line, transformed = line:gsub("%-%-%- @operator .*", "")
            if string.match(line, "%-%-%- @operator .*") then
                line = nil;
                transformed = 1;
            end
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 9. Blank lines starting with `--- @diagnostic`
        if transformed == 0 then
            --line, transformed = line:gsub("%-%-%- @diagnostic .*", "")
            if string.match(line, "%-%-%- @diagnostic .*") then
                line = nil;
                transformed = 1;
            end
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 9. Blank lines starting with `--- @cast`
        if transformed == 0 then
            --line, transformed = line:gsub("%-%-%- @cast .*", "")
            if string.match(line, "%-%-%- @cast .*") then
                line = nil;
                transformed = 1;
            end
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 9. Blank lines starting with `--- @operator`
        if transformed == 0 then
            --line, transformed = line:gsub("%-%-%- @operator .*", "")
            if string.match(line, "%-%- @operator .*") then
                line = nil;
                transformed = 1;
            end
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- 9. Blank lines starting with `--- @diagnostic`
        if transformed == 0 then
            --line, transformed = line:gsub("%-%-%- @diagnostic .*", "")
            if string.match(line, "%-%- @diagnostic .*") then
                line = nil;
                transformed = 1;
            end
            --if transformed > 0 then print("Processing line: " .. line) end
        end

        -- Add the processed line to the output
        if line then
            if pendingblock then
                table.insert(pendingblock, line);
            else
                table.insert(lines, line)
            end
        else
            if pendingblock then
                table.insert(pendingblock, '');
            else
                table.insert(lines, '')
            end
        end
    end
    if pendingblock then
        for i = 1, #pendingblock do
            table.insert(lines, pendingblock[i]);
        end
        pendingblock = nil;
    end
    file:close()

    -- Write the transformed content to the output file
    file = io.open(output_file, "w")
    if not file then
        error("Error: Could not open output file " .. output_file)
        return
    end
    file:write(table.concat(lines, "\n"))
    file:close()

    print("Processed "..string.format("%5d", lineCounter).." line file: " .. input_file .. " -> " .. output_file)
    return lineCounter;
end

-- Function to recursively process all Lua files in a directory
local function preprocess_directory(input_dir, output_dir)
    local lineCounter = 0;
    for file in lfs.dir(input_dir) do
        if file ~= "." and file ~= ".." then
            local input_path = input_dir .. "/" .. file
            local output_path = output_dir .. "/" .. file

            local attr = lfs.attributes(input_path)
            if attr.mode == "directory" then
                lfs.mkdir(output_path)
                lineCounter = lineCounter + preprocess_directory(input_path, output_path)
            elseif file:match("%.lua$") then
                lineCounter = lineCounter + preprocess_file(input_path, output_path)
            end
        end
    end
    return lineCounter;
end

-- Run the preprocessor
local lineCounterAll = preprocess_file("./scriptutils.lua", output_dir .. "/scriptutils.lua")
lineCounterAll = lineCounterAll + preprocess_directory("./../baked", output_dir)
print("Preprocessing complete. Total lines: "..tostring(lineCounterAll).." Files saved to " .. output_dir)