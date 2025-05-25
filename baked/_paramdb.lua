--- BZ98R LUA Extended API ODF Handler.
---
--- Tracks objects by class and odf.
---
--- @module '_paramdb'
--- @author John "Nielk1" Klein

local debugprint = debugprint or function(...) end;

debugprint("_paramdb Loading");

local M = {};

local utility = require("_utility");

--- @param odf string ODF file name
--- @return ClassLabel? classlabel
function M.GetClassLabel(odf)
    local odfHandle = OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    local classLabel = GetODFString(odfHandle, "GameObjectClass", "classLabel");
    return classLabel;
end

--- @param odf string ODF file name
--- @return ClassSig? classlabel
function M.GetClassSig(odf)
    local classLabel = M.GetClassLabel(odf);
    if classLabel == nil then error("GetClassLabel() returned nil."); end
    local classSig = utility.GetClassSig(classLabel);
    return classSig;
end

--- @param odf string ODF file name
--- @return integer scrap cost
function M.GetScrapCost(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    
    local odfHandle = OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end
    local sig = M.GetClassSig(odf)
    if sig == nil then error("GetClassSig() returned nil."); end

    local scrap = 2147483647; -- GameObject default
    
    if sig == utility.ClassSig.person then
        scrap = 0;
    end

    scrap = GetODFInt(odfHandle, "GameObjectClass", "scrapCost", scrap);
    return scrap;
end

--- @param odf string ODF file name
--- @return integer pilot cost
function M.GetPilotCost(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    
    local odfHandle = OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end
    local sig = M.GetClassSig(odf)
    if sig == nil then error("GetClassSig() returned nil."); end

    local pilot = 0; -- GameObject default

    if sig == utility.ClassSig.craft then
        pilot = 1;
    elseif sig == utility.ClassSig.person then
        pilot = 1;
    elseif sig == utility.ClassSig.producer then
        pilot = 0;
    elseif sig == utility.ClassSig.sav then
        pilot = 0;
    elseif sig == utility.ClassSig.torpedo then
        pilot = 0;
    elseif sig == utility.ClassSig.turret then
        pilot = 0;
    end

    local pilot = GetODFInt(odfHandle, "GameObjectClass", "pilotCost", pilot);
    return pilot;
end

--- @param odf string ODF file name
--- @return number time
function M.GetBuildTime(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    
    local odfHandle = OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    local buildTime = GetODFFloat(odfHandle, "GameObjectClass", "buildTime", 5.0);
    return buildTime;
end

debugprint("_paramdb Loaded");

return M;