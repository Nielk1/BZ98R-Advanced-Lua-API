--- BZ98R LUA Extended API Require Fix.
---
--- Repairs lua loader to look in mod paths for DLL or LUA modules with names longer than 15 characters.
---
--- @module _requirefix
--- @author John "Nielk1" Klein
--- @usage require("_requirefix").addmod("12345").addmod("67890");

local debugprint = debugprint or function(...) end;

debugprint("_requirefix Loading");

local modPaths = {};
local modPathSet ={};
local moduleTable = {};

table.insert(package.loaders, 2, function(modulename) -- TODO is priority 2 too high?
    local errmsg = "";
    local filename = modulename .. ".lua";
    for _, k in ipairs(modPaths) do
        local relativePaths = {"../../workshop/content/301650/"..k.."/"..filename, "mods/"..k.."/"..filename};
        for _, relativePath in ipairs(relativePaths) do
            local cfunc = loadfile(relativePath)
            if (cfunc) then 
                return cfunc; -- TODO test this
            else
                errmsg = errmsg.."\n\tno mod asset '"..relativePath.."'";
            end
        end
    end
    filename = modulename .. ".dll";
    for _, k in ipairs(modPaths) do
        local relativePaths = {"../../workshop/content/301650/"..k.."/"..filename, "mods/"..k.."/"..filename};
        for _, relativePath in ipairs(relativePaths) do
            local cfunc = package.loadlib(relativePath, "luaopen_"..modulename)
            if (cfunc) then 
                return cfunc;
            else
                errmsg = errmsg.."\n\tno mod asset '"..relativePath.."'";
            end
        end
    end
    return errmsg;
end);

moduleTable.addmod = function(mod_id)
    debugprint("Add module require path '"..mod_id.."'");
	if not modPathSet[mod_id] then
		table.insert(modPaths, mod_id);
		modPathSet[mod_id] = true;
	end
    return moduleTable; -- chaining
end;

debugprint("_requirefix Loaded");

return moduleTable;