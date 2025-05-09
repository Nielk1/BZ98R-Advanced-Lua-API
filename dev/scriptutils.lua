--- BZ98R ScriptUtils Stub.
--
-- Stubs for ScriptUtils LDoc
--
-- @module ScriptUtils

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------
-- @section
-- The Lua scripting system defines some global variables that can be of use to user scripts.

--- Contains current build version
--
-- Battlezone 1.5 versions start with "1"
--
-- Battlezone 98 Redux versions start with "2"
--
-- For example "1.5.2.27u1"
-- @field GameVersion string

--- Contains the index of the current language.
--- <ol>
---     <li>English</li>
---     <li>French</li>
---     <li>German</li>
---     <li>Spanish</li>
---     <li>Italian</li>
---     <li>Portuguese</li>
---     <li>Russian</li>
--- </ol>
--- [2.0+]
--- @field Language integer

--- Contains the full name of the current language in all-caps: "ENGLISH", "FRENCH", "GERMAN", "SPANISH", "ITALIAN", "PORTUGUESE", or "RUSSIAN"
--- [2.0+]
--- @field LanguageName string

--- Contains the two-letter language code of the current language: "en", "fr", "de", "es", "it", "pt" or "ru"
--- [2.0+]
--- @field LanguageSuffix string

--- Contains the most recently pressed game key (e.g. "Ctrl+Z")
--- @field LastGameKey string

-------------------------------------------------------------------------------
-- Audio Messages
-------------------------------------------------------------------------------
-- @section
-- These functions control audio messages, 2D sounds typically used for radio messages, voiceovers, and narration.
-- Audio messages use the Voice Volume setting from the Audio Options menu.

--- Repeat the last audio message.
--- @function RepeatAudioMessage

--- Plays the given audio file, which must be an uncompressed RIFF WAVE (.WAV) file.
--- Returns an audio message handle.
--- @return message
--- @param filename string
--- @function AudioMessage
function AudioMessage(filename) end

--- Returns true if the audio message has stopped. Returns false otherwise.
--- @return boolean
--- @param msg message
--- @function IsAudioMessageDone

--- Stops the given audio message.
--- @param msg message
--- @function StopAudioMessage

--- Returns true if <em>any</em> audio message is playing. Returns false otherwise.
--- @return boolean
--- @function IsAudioMessagePlaying

-------------------------------------------------------------------------------
-- Sound Effects
-------------------------------------------------------------------------------
-- @section
-- These functions control sound effects, either positional 3D sounds attached to objects or global 2D sounds.
-- Sound effects use the Effects Volume setting from the Audio Options menu.

--- Plays the given audio file, which must be an uncompressed RIFF WAVE (.WAV) file.
--- Specifying an object handle creates a positional 3D sound that follows the object as it moves and stops automatically when the object goes away. Otherwise, the sound plays as a global 2D sound.
--- Priority ranges from 0 to 100, with higher priorities taking precedence over lower priorities when there are not enough channels. The default priority is 50 if not specified.
--- Looping sounds will play forever until explicitly stopped with StopSound or the object to which it is attached goes away. Non-looping sounds will play once and stop. The default is non-looping if not specified.
--- Volume ranges from 0 to 100, with 0 being silent and 100 being maximum volume. The default volume is 100 if not specified.
--- Rate overrides the playback rate of the sound file, so a value of 22050 would cause a sound file recorded at 11025 Hz to play back twice as fast. The rate defaults to the file's native rate if not specified.
--- @param filename string
--- @param h? Handle
--- @param priority? integer
--- @param loop? boolean
--- @param volume? integer
--- @param rate? integer
--- @function StartSound

--- Stops the sound using the given filename and associated with the given object. Use a handle of none or nil to stop a global 2D sound.
--- @param filename string
--- @param h? Handle
--- @function StopSound

-------------------------------------------------------------------------------
-- Game Object
-------------------------------------------------------------------------------
-- @section
-- These functions create, manipulate, and query game objects (vehicles, buildings, people, powerups, and scrap) and return or take as a parameter a game object handle.
-- Object handles are always safe to use, even if the game object itself is missing or destroyed.

--- Returns the handle of the game object with the given label. Returns nil if none exists.
--- @return handle
--- @param label string
--- @function GetHandle
function GetHandle(label) end

--- Creates a game object with the given odf name and team number at the location of a game object.
--- Returns the handle of the created object if it created one. Returns nil if it failed.
--- @return handle
--- @param odfname string
--- @param teamnum integer
--- @param h handle
--- @function BuildObject

--- Creates a game object with the given odf name and team number at a point on the named path. It uses the start of the path if no point is given.
--- Returns the handle of the created object if it created one. Returns nil if it failed.
--- @return handle
--- @param odfname string
--- @param teamnum integer
--- @param path string
--- @param point? integer
--- @function BuildObject

--- Creates a game object with the given odf name and team number at the given position vector.
--- Returns the handle of the created object if it created one. Returns nil if it failed.
--- @return handle
--- @param odfname string
--- @param teamnum integer
--- @param position vector
--- @function BuildObject

--- Creates a game object with the given odf name and team number with the given transform matrix.
--- Returns the handle of the created object if it created one. Returns nil if it failed.
--- @return handle
--- @param odfname string
--- @param teamnum integer
--- @param transform matrix
--- @function BuildObject

--- Removes the game object with the given handle.
--- @param h handle
--- @function RemoveObject
function RemoveObject(h) end

--- Returns true if the game object's odf name matches the given odf name. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @param odfname string
--- @function IsOdf

--- Returns the odf name of the game object. Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetOdf

--- Returns the base config of the game object which determines what VDF/SDF model it uses. Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetBase

--- Returns the label of the game object (e.g. "avtank0_wingman"). Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetLabel

--- Set the label of the game object (e.g. "tank1").
--- <p>Note: this function was misspelled as SettLabel in 1.5. It can be renamed compatibly with a short snippet of code at the top of the mission script:</p>
--- <pre>SetLabel = SetLabel or SettLabel</pre>
--- @param h Handle
--- @param label string
--- @function SetLabel

--- Returns the four-character class signature of the game object (e.g. "WING"). Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetClassSig

--- Returns the class label of the game object (e.g. "wingman"). Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetClassLabel

--- Returns the numeric class identifier of the game object. Returns nil if none exists.
--- Looking up the class id number in the ClassId table will convert it to a string. Looking up the class id string in the ClassId table will convert it back to a number.
--- @return integer
--- @param h handle
--- @function GetClassId

--- This is a global table that converts between class identifier numbers and class identifier names.
--- Many of these values likely never appear in game and are leftover from Interstate '76
--- @table ClassId
ClassId = {
    NONE = 0, -- 0

    HELICOPTER = 1, -- 1
    STRUCTURE1 = 2, -- 2 (Wooden Structures)
    POWERUP = 3, -- 3
    PERSON = 4, -- 4
    SIGN = 5, -- 5
    VEHICLE = 6, -- 6
    SCRAP = 7, -- 7
    BRIDGE = 8, -- 8 (A structure which can contain the floor)
    FLOOR = 9, -- 9 (The floor in a bridge)
    STRUCTURE2 = 10, -- 10 (Metal Structures)
    SCROUNGE = 11, -- 11
    SPINNER = 15, -- 15

    HEADLIGHT_MASK = 38, -- 38

    EYEPOINT = 40, -- 40
    COM = 42, -- 42

    WEAPON = 50, -- 50
    ORDNANCE = 51, -- 51
    EXPLOSION = 52, -- 52
    CHUNK = 53, -- 53
    SORT_OBJECT = 54, -- 54
    NONCOLLIDABLE = 55, -- 55

    VEHICLE_GEOMETRY = 60, -- 60
    STRUCTURE_GEOMETRY = 61, -- 61
    WEAPON_GEOMETRY = 63, -- 63
    ORDNANCE_GEOMETRY = 64, -- 64
    TURRET_GEOMETRY = 65, -- 65
    ROTOR_GEOMETRY = 66, -- 66
    NACELLE_GEOMETRY = 67, -- 67
    FIN_GEOMETRY = 68, -- 68
    COCKPIT_GEOMETRY = 69, -- 69

    WEAPON_HARDPOINT = 70, -- 70
    CANNON_HARDPOINT = 71, -- 71
    ROCKET_HARDPOINT = 72, -- 72
    MORTAR_HARDPOINT = 73, -- 73
    SPECIAL_HARDPOINT = 74, -- 74

    FLAME_EMITTER = 75, -- 75
    SMOKE_EMITTER = 76, -- 76
    DUST_EMITTER = 77, -- 77

    PARKING_LOT = 81, -- 81

    [0] = "NONE", -- NONE
    [1] = "HELICOPTER", -- HELICOPTER
    [2] = "STRUCTURE1", -- STRUCTURE1
    [3] = "POWERUP", -- POWERUP
    [4] = "PERSON", -- PERSON
    [5] = "SIGN", -- SIGN
    [6] = "VEHICLE", -- VEHICLE
    [7] = "SCRAP", -- SCRAP
    [8] = "BRIDGE", -- BRIDGE
    [9] = "FLOOR", -- FLOOR
    [10] = "STRUCTURE2", -- STRUCTURE2
    [11] = "SCROUNGE", -- SCROUNGE
    [15] = "SPINNER", -- SPINNER
    [38] = "HEADLIGHT_MASK", -- HEADLIGHT_MASK
    [40] = "EYEPOINT", -- EYEPOINT
    [42] = "COM", -- COM
    [50] = "WEAPON", -- WEAPON
    [51] = "ORDNANCE", -- ORDNANCE
    [52] = "EXPLOSION", -- EXPLOSION
    [53] = "CHUNK", -- CHUNK
    [54] = "SORT_OBJECT", -- SORT_OBJECT
    [55] = "NONCOLLIDABLE", -- NONCOLLIDABLE
    [60] = "VEHICLE_GEOMETRY", -- VEHICLE_GEOMETRY
    [61] = "STRUCTURE_GEOMETRY", -- STRUCTURE_GEOMETRY
    [63] = "WEAPON_GEOMETRY", -- WEAPON_GEOMETRY
    [64] = "ORDNANCE_GEOMETRY", -- ORDNANCE_GEOMETRY
    [65] = "TURRET_GEOMETRY", -- TURRET_GEOMETRY
    [66] = "ROTOR_GEOMETRY", -- ROTOR_GEOMETRY
    [67] = "NACELLE_GEOMETRY", -- NACELLE_GEOMETRY
    [68] = "FIN_GEOMETRY", -- FIN_GEOMETRY
    [69] = "COCKPIT_GEOMETRY", -- COCKPIT_GEOMETRY
    [70] = "WEAPON_HARDPOINT", -- WEAPON_HARDPOINT
    [71] = "CANNON_HARDPOINT", -- CANNON_HARDPOINT
    [72] = "ROCKET_HARDPOINT", -- ROCKET_HARDPOINT
    [73] = "MORTAR_HARDPOINT", -- MORTAR_HARDPOINT
    [74] = "SPECIAL_HARDPOINT", -- SPECIAL_HARDPOINT
    [75] = "FLAME_EMITTER", -- FLAME_EMITTER
    [76] = "SMOKE_EMITTER", -- SMOKE_EMITTER
    [77] = "DUST_EMITTER", -- DUST_EMITTER
    [81] = "PARKING_LOT", -- PARKING_LOT
}

--- Returns the one-letter nation code of the game object (e.g. "a" for American, "b" for Black Dog, "c" for Chinese, and "s" for Soviet).
--- The nation code is usually but not always the same as the first letter of the odf name. The ODF file can override the nation in the [GameObjectClass] section, and player.odf is a hard-coded exception that uses "a" instead of "p".
--- @return string
--- @param h handle
--- @function GetNation

--- Returns true if the game object exists. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsValid
function IsValid(h) end

--- Returns true if the game object exists and (if the object is a vehicle) controlled. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsAlive
function IsAlive(h) end

--- Returns true if the game object exists and (if the object is a vehicle) controlled and piloted. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsAliveAndPilot
function IsAliveAndPilot(h) end

--- Returns true if the game object exists and is a vehicle. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsCraft
function IsCraft(h) end

--- Returns true if the game object exists and is a building. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsBuilding
function IsBuilding(h) end

--- Returns true if the game object exists and is a person. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsPerson
function IsPerson(h) end

--- Returns true if the game object exists and has less health than the threshold. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @param threshold? float
--- @function IsDamaged
function IsDamaged(h, threshold) end

--- Returns true if the game object was recycled by a Construction Rig on the given team.
--- [2.1+]
--- @return boolean
--- @param h handle
--- @param team integer
--- @function IsRecycledByTeam

-------------------------------------------------------------------------------
-- Team Number
-------------------------------------------------------------------------------
-- @section
-- These functions get and set team number. Team 0 is the neutral or environment team.

--- Returns the game object's team number.
--- @return integer
--- @param h handle
--- @function GetTeamNum

--- Sets the game object's team number.
--- @param h handle
--- @param team integer
--- @function SetTeamNum

--- Returns the game object's perceived team number (as opposed to its real team number).
--- The perceived team will differ from the real team when a player enters an empty enemy vehicle without being seen until they attack something.
--- @return teamnum
--- @param h handle
--- @param t teamnum
--- @function GetPerceivedTeam

--- Set the game object's perceived team number (as opposed to its real team number).
--- Units on the game object's perceived team will treat it as friendly until it "blows its cover" by attacking, at which point it will revert to its real team.
--- Units on the game object's real team will treat it as friendly regardless of its perceived team.
--- @param h handle
--- @param t teamnum
--- @function SetPerceivedTeam

-------------------------------------------------------------------------------
-- Target
-------------------------------------------------------------------------------
-- @section
-- These function get and set a unit's target.

--- Sets the local player's target.
--- @param t handle
--- @function SetUserTarget

--- Returns the local player's target. Returns nil if it has none.
--- @return handle
--- @function GetUserTarget

--- Sets the game object's target.
--- @param h handle
--- @param t handle
--- @function SetTarget

--- Returns the game object's target. Returns nil if it has none.
--- @return handle
--- @param h handle
--- @function GetTarget

-------------------------------------------------------------------------------
-- Owner
-------------------------------------------------------------------------------
-- @section
-- These functions get and set owner. The default owner for a game object is the game object that created it.

--- Sets the game object's owner.
--- @param h handle
--- @param o handle
--- @function SetOwner

--- Returns the game object's owner. Returns nil if it has none.
--- @return handle
--- @param h handle
--- @function GetOwner

-------------------------------------------------------------------------------
-- Pilot Class
-------------------------------------------------------------------------------
-- @section
-- These functions get and set vehicle pilot class.

--- Sets the vehicle's pilot class to the given odf name. This does nothing useful for non-vehicle game objects. An odf name of nil resets the vehicle to the default assignment based on nation.
--- @param h handle
--- @param odfname string
--- @function SetPilotClass

--- Returns the odf name of the vehicle's pilot class. Returns nil if none exists.
--- @return string
--- @param h handle
--- @function GetPilotClass

-------------------------------------------------------------------------------
-- Position and Orientation
-------------------------------------------------------------------------------
-- @section
-- These functions get and set position and orientation.

--- Teleports the game object to a point on the named path. It uses the start of the path if no point is given.
--- @param h handle
--- @param path string
--- @param point? integer
--- @function SetPosition

--- Teleports the game object to the position vector.
--- @param h handle
--- @param position vector
--- @function SetPosition

--- Teleports the game object to the position of the transform matrix.
--- @param h handle
--- @param transform matrix
--- @function SetPosition

--- Returns the game object's position vector. Returns nil if none exists.
--- @return vector
--- @param h handle
--- @function GetPosition

--- Returns the path point's position vector. Returns nil if none exists.
--- @return vector
--- @param path string
--- @param point? integer
--- @function GetPosition

--- Returns the game object's front vector. Returns nil if none exists.
--- @return vector
--- @param h handle
--- @function GetFront

--- Teleports the game object to the given transform matrix.
--- @param h handle
--- @param transform matrix
--- @function SetTransform

--- Returns the game object's transform matrix. Returns nil if none exists.
--- @return matrix
--- @param h handle
--- @function GetTransform

-------------------------------------------------------------------------------
-- Linear Velocity
-------------------------------------------------------------------------------
-- @section
-- These functions get and set linear velocity.

--- Returns the game object's linear velocity vector. Returns nil if none exists.
--- @return vector
--- @param h handle
--- @function GetVelocity

--- Sets the game object's angular velocity vector. 
--- @param h handle
--- @param velocity vector
--- @function SetVelocity

-------------------------------------------------------------------------------
-- Angular Velocity
-------------------------------------------------------------------------------
-- @section
-- These functions get and set angular velocity.

--- Returns the game object's angular velocity vector. Returns nil if none exists.
--- @return vector
--- @param h handle
--- @function GetOmega

--- Sets the game object's angular velocity vector.
--- @param h handle
--- @param omega vector
--- @function SetOmega

-------------------------------------------------------------------------------
-- Position Helpers
-------------------------------------------------------------------------------
-- @section
-- These functions help generate position values close to a center point.

--- Returns a ground position offset from the center by the radius in a direction controlled by the angle.
--- If no radius is given, it uses a default radius of zero.
--- If no angle is given, it uses a default angle of zero.
--- An angle of zero is +X (due east), pi * 0.5 is +Z (due north), pi is -X (due west), and pi * 1.5 is -Z (due south).
--- @return vector
--- @param center vector
--- @param radius? number
--- @param angle? number
--- @function GetCircularPos

--- Returns a ground position in a ring around the center between minradius and maxradius with roughly the same terrain height as the terrain height at the center.
--- This is good for scattering spawn positions around a point while excluding positions that are too high or too low.
--- If no radius is given, it uses the default radius of zero.
--- @return vector
--- @param center vector
--- @param minradius? number
--- @param maxradius? number
--- @function GetPositionNear

-------------------------------------------------------------------------------
-- Shot
-------------------------------------------------------------------------------
-- @section
-- These functions query a game object for information about ordnance hits.

--- Returns who scored the most recent hit on the game object. Returns nil if none exists.
--- @return handle
--- @param h handle
--- @function GetWhoShotMe

--- Returns the last time an enemy shot the game object.
--- @return float
--- @param h handle
--- @function GetLastEnemyShot

--- Returns the last time a friend shot the game object.
--- @return float
--- @param h handle
--- @function GetLastFriendShot

-------------------------------------------------------------------------------
-- Alliances
-------------------------------------------------------------------------------
-- @section
-- These functions control and query alliances between teams.
-- The team manager assigns each player a separate team number, starting with 1 and going as high as 15. Team 0 is the neutral "environment" team.
-- Unless specifically overridden, every team is friendly with itself, neutral with team 0, and hostile to everyone else.

--- Sets team alliances back to default.
--- @function DefaultAllies

--- Sets whether team alliances are locked. Locking alliances prevents players from allying or un-allying, preserving alliances set up by the mission script.
--- @param lock boolean
--- @function LockAllies

--- Makes the two teams allies of each other.
--- This function affects both teams so Ally(1, 2) and Ally(2, 1) produces the identical results, unlike the "half-allied" state created by the "ally" game key.
--- @param team1 integer
--- @param team2 integer
--- @function Ally

--- Makes the two teams enemies of each other.
--- This function affects both teams so UnAlly(1, 2) and UnAlly(2, 1) produces the identical results, unlike the "half-enemy" state created by the "unally" game key.
--- @param team1 integer
--- @param team2 integer
--- @function UnAlly

--- Returns true if team1 considers team2 an ally. Returns false otherwise.
--- Due to the possibility of player-initiated "half-alliances", IsTeamAllied(team1, team2) might not return the same result as IsTeamAllied(team2, team1).
--- @return boolean
--- @param team1 integer
--- @param team2 integer
--- @function IsTeamAllied

--- Returns true if game object "me" considers game object "him" an ally. Returns false otherwise.
--- Due to the possibility of player-initiated "half-alliances", IsAlly(me, him) might not return the same result as IsAlly(him, me).
--- @return boolean
--- @param me handle
--- @param him handle
--- @function IsAlly

-------------------------------------------------------------------------------
-- Objective Marker
-------------------------------------------------------------------------------
-- @section
-- These functions control objective markers.
-- Objectives are visible to all teams from any distance and from any direction, with an arrow pointing to off-screen objectives. There is currently no way to make team-specific objectives.

--- Sets the game object as an objective to all teams.
--- @param h handle
--- @function SetObjectiveOn
function SetObjectiveOn(h) end

--- Sets the game object back to normal.
--- @param h handle
--- @function SetObjectiveOff
function SetObjectiveOff(h) end

--- Gets the game object's visible name.
--- @return string
--- @param h handle
--- @function GetObjectiveName
function GetObjectiveName(h) end

--- Sets the game object's visible name.
--- @param h handle
--- @param name string
--- @function SetObjectiveName
function SetObjectiveName(h, name) end

--- Sets the game object's visible name. This function is effectively an alias for SetObjectiveName.
--- [2.1+]
--- @param h handle
--- @param name string
--- @function SetName
function SetName(h, name) end

-------------------------------------------------------------------------------
-- Distance
-------------------------------------------------------------------------------
-- @section
-- These functions measure and return the distance between a game object and a reference point.

--- Returns the distance in meters between the two game objects.
--- @return number
--- @param h1 handle
--- @param h2 handle
--- @function GetDistance

--- Returns the distance in meters between the game object and a point on the path. It uses the start of the path if no point is given.
--- @return number
--- @param h1 handle
--- @param path string
--- @param point? integer
--- @function GetDistance

--- Returns the distance in meters between the game object and a position vector.
--- @return number
--- @param h1 handle
--- @param position vector
--- @function GetDistance

--- Returns the distance in meters between the game object and the position of a transform matrix.
--- @return number
--- @param h1 handle
--- @param transform matrix
--- @function GetDistance
function GetDistance(h1, location) end

--- Returns true if the units are closer than the given distance of each other. Returns false otherwise.
--- (This function is equivalent to GetDistance (h1, h2) < d)
--- @return boolean
--- @param h1 handle
--- @param h2 handle
--- @param dist number
--- @function IsWithin

--- Returns true if the bounding spheres of the two game objects are within the specified tolerance. The default tolerance is 1.3 meters if not specified.
--- [2.1+]
--- @return bool
--- @param h1 handle
--- @param h2 handle
--- @param tolerance? number
--- @function IsTouching

-------------------------------------------------------------------------------
-- Nearest
-------------------------------------------------------------------------------
-- @section
-- These functions find and return the game object of the requested type closest to a reference point.

--- Returns the game object closest to the given game object. Returns nil if none exists.
--- @return handle
--- @param h handle
--- @function GetNearestObject

--- Returns the game object closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--- @return handle
--- @param path string
--- @param point? integer
--- @function GetNearestObject

--- Returns the game object closest to the position vector. Returns nil if none exists.
--- @return handle
--- @param position vector
--- @function GetNearestObject

--- Returns the game object closest to the position of the transform matrix. Returns nil if none exists.
--- @return handle
--- @param transform matrix
--- @function GetNearestObject

--- Returns the craft closest to the given game object. Returns nil if none exists.
--- @return handle
--- @param h handle
--- @function GetNearestVehicle

--- Returns the craft closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--- @return handle
--- @param path string
--- @param point? integer
--- @function GetNearestVehicle

--- Returns the vehicle closest to the position vector. Returns nil if none exists.
--- @return handle
--- @param position vector
--- @function GetNearestVehicle

--- Returns the vehicle closest to the position of the transform matrix. Returns nil if none exists.
--- @return handle
--- @param transform matrix
--- @function GetNearestVehicle

--- Returns the building closest to the given game object. Returns nil if none exists.
--- @return handle
--- @param h handle
--- @function GetNearestBuilding

--- Returns the building closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--- @return handle
--- @param path string
--- @param point? integer
--- @function GetNearestBuilding

--- Returns the building closest to the position vector. Returns nil if none exists.
--- @return handle
--- @param position vector
--- @function GetNearestBuilding

--- Returns the building closest to the position of the transform matrix. Returns nil if none exists.
--- @return handle
--- @param transform matrix
--- @function GetNearestBuilding

--- Returns the enemy closest to the given game object. Returns nil if none exists.
--- @return handle
--- @param h handle
--- @function GetNearestEnemy

--- Returns the enemy closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--- @return handle
--- @param path string
--- @param point? integer
--- @function GetNearestEnemy

--- Returns the enemy closest to the position vector. Returns nil if none exists.
--- @return handle
--- @param position vector
--- @function GetNearestEnemy

--- Returns the enemy closest to the position of the transform matrix. Returns nil if none exists.
--- @return handle
--- @param transform matrix
--- @function GetNearestEnemy

--- Returns the friend closest to the given game object. Returns nil if none exists.
--- [2.0+]
--- @return handle
--- @param h handle
--- @function GetNearestFriend

--- Returns the friend closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--- [2.0+]
--- @return handle
--- @param path string
--- @param point? integer
--- @function GetNearestFriend

--- Returns the friend closest to the position vector. Returns nil if none exists.
--- [2.0+]
--- @return handle
--- @param position vector
--- @function GetNearestFriend

--- Returns the friend closest to the position of the transform matrix. Returns nil if none exists.
--- [2.0+]
--- @return handle
--- @param transform matrix
--- @function GetNearestFriend

--- Returns the craft or person on the given team closest to the given game object. Returns nil if none exists.
--- [2.0+]
--- @return handle
--- @param h handle
--- @param team int
--- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
---  [2.1+]
--- @return handle
--- @param path string
--- @param point? integer
--- @param team int
--- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to the position of the transform matrix. Returns nil if none exists.
---  [2.1+]
--- @return handle
--- @param position vector
--- @param team int
--- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to the position vector. Returns nil if none exists.
---  [2.1+]
--- @return handle
--- @param transform matrix
--- @param team int
--- @function GetNearestUnitOnTeam

--- Returns how many objects with the given team and odf name are closer than the given distance.
--- @return integer
--- @param h handle
--- @param dist number
--- @param team integer
--- @param odfname string
--- @function CountUnitsNearObject

-------------------------------------------------------------------------------
-- Iterators
-------------------------------------------------------------------------------
-- @section
-- These functions return iterator functions for use with Lua's "for <variable> in <expression> do ... end" form. For example: "for h in AllCraft() do print(h, GetLabel(h)) end" will print the game object handle and label of every craft in the world.

--- Enumerates game objects within the given distance of the game object.
--- @return iterator
--- @param dist number
--- @param h handle
--- @function ObjectsInRange

--- Enumerates game objects within the given distance of the path point. It uses the start of the path if no point is given.
--- @return iterator
--- @param dist number
--- @param path name
--- @param point? integer
--- @function ObjectsInRange

--- Enumerates game objects within the given distance of the position vector.
--- @return iterator
--- @param dist number
--- @param position vector
--- @function ObjectsInRange

--- Enumerates game objects within the given distance of the transform matrix.
--- @return iterator
--- @param dist number
--- @param transform matrix
--- @function ObjectsInRange

--- Enumerates all game objects.
--- Use this function sparingly at runtime since it enumerates <em>all</em> game objects, including every last piece of scrap. If you're specifically looking for craft, use AllCraft() instead.
--- @return iterator
--- @function AllObjects

--- Enumerates all craft.
--- @return iterator
--- @function AllCraft

--- Enumerates all game objects currently selected by the local player.
--- @return iterator
--- @function SelectedObjects 

--- Enumerates all game objects marked as objectives.
--- @return iterator
--- @function ObjectiveObjects

-------------------------------------------------------------------------------
-- Scrap Management
-------------------------------------------------------------------------------
-- @section
-- These functions remove scrap, either to reduce the global game object count or to remove clutter around a location.

--- While the global scrap count is above the limit, remove the oldest scrap piece. It no limit is given, it uses the default limit of 300.
--- @param limit? integer
--- @function GetRidOfSomeScrap

--- Clear all scrap within the given distance of a game object.
--- @param distance number
--- @param h handle
--- @function ClearScrapAround

--- Clear all scrap within the given distance of a point on the path. It uses the start of the path if no point is given.
--- @param distance number
--- @param path string
--- @param point? integer
--- @function ClearScrapAround

--- Clear all scrap within the given distance of a position vector.
--- @param distance number
--- @param position vector
--- @function ClearScrapAround

--- Clear all scrap within the given distance of the position of a transform matrix.
--- @param distance number
--- @param transform matrix
--- @function ClearScrapAround

-------------------------------------------------------------------------------
-- Team Slots
-------------------------------------------------------------------------------
-- @section
-- These functions look up game objects in team slots.

--- This is a global table that converts between team slot numbers and team slot names. For example, TeamSlot.PLAYER or TeamSlot["PLAYER"] returns the team slot (0) for the player; TeamSlot[0] returns the team slot name ("PLAYER") for team slot 0. For maintainability, always use this table instead of raw team slot numbers.
--- Slots starting with MIN_ and MAX_ represent the lower and upper bound of a range of slots.
--- @table TeamSlot
TeamSlot = {
    UNDEFINED = -1, -- -1
    PLAYER = 0, -- 0

    RECYCLER = 1, -- 1
    FACTORY = 2, -- 2
    ARMORY = 3, -- 3
    CONSTRUCT = 4, -- 4

    MIN_OFFENSE = 5, -- 5
    MAX_OFFENSE = 14, -- 14
    MIN_DEFENSE = 15, -- 15
    MAX_DEFENSE = 24, -- 24
    MIN_UTILITY = 25, -- 25
    MAX_UTILITY = 34, -- 34

    MIN_BEACON = 35, -- 35
    MAX_BEACON = 44, -- 44

    MIN_POWER = 45, -- 45
    MAX_POWER = 54, -- 54
    MIN_COMM = 55, -- 55
    MAX_COMM = 59, -- 59
    MIN_REPAIR = 60, -- 60
    MAX_REPAIR = 64, -- 64
    MIN_SUPPLY = 65, -- 65
    MAX_SUPPLY = 69, -- 69
    MIN_SILO = 70, -- 70
    MAX_SILO = 74, -- 74
    MIN_BARRACKS = 75, -- 75
    MAX_BARRACKS = 79, -- 79
    MIN_GUNTOWER = 80, -- 80
    MAX_GUNTOWER = 89, -- 89

    [-1] = "UNDEFINED", -- UNDEFINED
    [0] = "PLAYER", -- PLAYER

    [1] = "RECYCLER", -- RECYCLER
    [2] = "FACTORY", -- FACTORY
    [3] = "ARMORY", -- ARMORY
    [4] = "CONSTRUCT", -- CONSTRUCT

    [5] = "MIN_OFFENSE", -- MIN_OFFENSE
    [14] = "MAX_OFFENSE", -- MAX_OFFENSE
    [15] = "MIN_DEFENSE", -- MIN_DEFENSE
    [24] = "MAX_DEFENSE", -- MAX_DEFENSE
    [25] = "MIN_UTILITY", -- MIN_UTILITY
    [34] = "MAX_UTILITY", -- MAX_UTILITY

    [35] = "MIN_BEACON", -- MIN_BEACON
    [44] = "MAX_BEACON", -- MAX_BEACON

    [45] = "MIN_POWER", -- MIN_POWER
    [54] = "MAX_POWER", -- MAX_POWER
    [55] = "MIN_COMM", -- MIN_COMM
    [59] = "MAX_COMM", -- MAX_COMM
    [60] = "MIN_REPAIR", -- MIN_REPAIR
    [64] = "MAX_REPAIR", -- MAX_REPAIR
    [65] = "MIN_SUPPLY", -- MIN_SUPPLY
    [69] = "MAX_SUPPLY", -- MAX_SUPPLY
    [70] = "MIN_SILO", -- MIN_SILO
    [74] = "MAX_SILO", -- MAX_SILO
    [75] = "MIN_BARRACKS", -- MIN_BARRACKS
    [79] = "MAX_BARRACKS", -- MAX_BARRACKS
    [80] = "MIN_GUNTOWER", -- MIN_GUNTOWER
    [89] = "MAX_GUNTOWER", -- MAX_GUNTOWER
}

--- Get the game object in the specified team slot.
--- It uses the local player team if no team is given.
--- @return handle
--- @param slot integer
--- @param team? integer
--- @function GetTeamSlot
function GetTeamSlot(slot, team) end

--- Returns the game object controlled by the player on the given team. Returns nil if none exists.
--- It uses the local player team if no team is given.
--- @return handle
--- @param team? integer
--- @function GetPlayerHandle
function GetPlayerHandle(team) end

--- Returns the Recycler on the given team. Returns nil if none exists.
--- It uses the local player team if no team is given.
--- @return handle
--- @param team? integer
--- @function GetRecyclerHandle

--- Returns the Factory on the given team. Returns nil if none exists.
--- It uses the local player team if no team is given.
--- @return handle
--- @param team? integer
--- @function GetFactoryHandle

--- Returns the Armory on the given team. Returns nil if none exists.
--- It uses the local player team if no team is given.
--- @return handle
--- @param team? integer
--- @function GetArmoryHandle

--- Returns the Constructor on the given team. Returns nil if none exists.
--- It uses the local player team if no team is given.
--- @return handle
--- @param team? integer
--- @function GetConstructorHandle

-------------------------------------------------------------------------------
-- Team Pilots
-------------------------------------------------------------------------------
-- @section
-- These functions get and set pilot counts for a team.

--- Adds pilots to the team's pilot count, clamped between zero and maximum count.
--- Returns the new pilot count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function AddPilot
function AddPilot(team, count) end

--- Sets the team's pilot count, clamped between zero and maximum count.
--- Returns the new pilot count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function SetPilot
function SetPilot(team, count) end

--- Returns the team's pilot count.
--- @return integer
--- @param team integer
--- @function GetPilot

--- Adds pilots to the team's maximum pilot count.
--- Returns the new pilot count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function AddMaxPilot

--- Sets the team's maximum pilot count.
--- Returns the new pilot count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function SetMaxPilot

--- Returns the team's maximum pilot count.
--- @return integer
--- @param team integer
--- @function GetMaxPilot

-------------------------------------------------------------------------------
-- Team Scrap
-------------------------------------------------------------------------------
-- @section
-- These functions get and set scrap values for a team.

--- Adds to the team's scrap count, clamped between zero and maximum count.
--- Returns the new scrap count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function AddScrap
function AddScrap(team, count) end

--- Sets the team's scrap count, clamped between zero and maximum count.
--- Returns the new scrap count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function SetScrap
function SetScrap(team, count) end

--- Returns the team's scrap count.
--- @return integer
--- @param team integer
--- @function GetScrap
function GetScrap(team) end

--- Adds to the team's maximum scrap count.
--- Returns the new maximum scrap count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function AddMaxScrap

--- Sets the team's maximum scrap count.
--- Returns the new maximum scrap count.
--- @return integer
--- @param team integer
--- @param count integer
--- @function SetMaxScrap

--- Returns the team's maximum scrap count.
--- @return integer
--- @param team integer
--- @function GetMaxScrap

-------------------------------------------------------------------------------
-- Deploy
-------------------------------------------------------------------------------
-- @section
-- These functions control deployable craft (such as Turret Tanks or Producer units).

--- Returns true if the game object is a deployed craft. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsDeployed

--- Tells the game object to deploy.
--- @param h handle
--- @function Deploy

-------------------------------------------------------------------------------
-- Selection
-------------------------------------------------------------------------------
-- @section
-- These functions access selection state (i.e. whether the player has selected a game object)

--- Returns true if the game object is selected. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsSelected

-------------------------------------------------------------------------------
-- Mission-Critical [2.0+]
-------------------------------------------------------------------------------
-- @section
-- The "mission critical" property indicates that a game object is vital to the success of the mission and disables the "Pick Me Up" and "Recycle" commands that (eventually) cause IsAlive() to report false.

--- Returns true if the game object is marked as mission-critical. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsCritical [2.0+]

--- Sets the game object's mission-critical status.
--- If critical is true or not specified, the object is marked as mission-critical. Otherwise, the object is marked as not mission critical.
--- @param h handle
--- @param critical? bool
--- @function SetCritical [2.0+]

-------------------------------------------------------------------------------
-- Weapon
-------------------------------------------------------------------------------
-- @section
-- These functions access unit weapons and damage.

--- Sets what weapons the unit's AI process will use.
--- To calculate the mask value, add up the values of the weapon hardpoint slots you want to enable.
--- weaponHard1: 1 weaponHard2: 2 weaponHard3: 4 weaponHard4: 8 weaponHard5: 16
--- @param h handle
--- @param mask integer
--- @function SetWeaponMask

--- Gives the game object the named weapon in the given slot. If no slot is given, it chooses a slot based on hardpoint type and weapon priority like a weapon powerup would. If the weapon name is empty, nil, or blank and a slot is given, it removes the weapon in that slot.
--- Returns true if it succeeded. Returns false otherwise.
--- @param h handle
--- @param weaponname? string
--- @param slot? integer
--- @function GiveWeapon

--- Returns the odf name of the weapon in the given slot on the game object. Returns nil if the game object does not exist or the slot is empty.
--- For example, an "avtank" game object would return "gatstab" for index 0 and "gminigun" for index 1.
--- @return string
--- @param h handle
--- @param slot integer
--- @function GetWeaponClass

--- Tells the game object to fire at the given target.
--- @param me handle
--- @param him handle
--- @function FireAt

--- Applies damage to the game object.
--- @param h handle
--- @param amount number
--- @function Damage
function Damage(h, amount) end

-------------------------------------------------------------------------------
-- Time
-------------------------------------------------------------------------------
-- @section
-- These function report various global time values.

--- Returns the elapsed time in seconds since the start of the mission.
--- @return number
--- @function GetTime
function GetTime() end

--- Returns the simulation time step in seconds.
--- @return number
--- @function GetTimeStep

--- Returns the current system time in milliseconds. This is mostly useful for performance profiling.
--- @return number
--- @function GetTimeNow

-------------------------------------------------------------------------------
-- Mission
-------------------------------------------------------------------------------
-- @section
-- These functions control general mission properties like strategic AI and mission flow

--- Enables (or disables) strategic AI control for a given team. As of version 1.5.2.7, mission scripts must enable AI control for any team that intends to use an AIP.
--- IMPORTANT SAFETY TIP: only call this function from the "root" of the Lua mission script! The strategic AI gets set up shortly afterward and attempting to use SetAIControl later will crash the game.
--- @param team integer
--- @param control? boolean, defaults to true
--- @function SetAIControl
function SetAIControl(team, control) end

--- Returns true if a given team is AI controlled. Returns false otherwise.
--- Unlike SetAIControl, this function may be called at any time.
--- @return boolean
--- @param team integer
--- @function GetAIControl

--- Returns the current AIP for the team. It uses team 2 if no team number is given.
--- @return string
--- @param team? integer
--- @function GetAIP 

--- Switches the team's AI plan. It uses team 2 if no team number is given.
--- @param aipname string
--- @param team? integer
--- @function SetAIP

--- Fails the mission after the given time elapses. If supplied with a filename (usually a .des), it sets the failure message to text from that file.
--- @param time number
--- @param filename? string
--- @function FailMission
function FailMission(time, filename) end

--- Succeeds the mission after the given time elapses. If supplied with a filename (usually a .des), it sets the success message to text from that file.
--- @param time number
--- @param filename? string
--- @function SucceedMission
function SucceedMission(time, filename) end

-------------------------------------------------------------------------------
-- Objective Messages
-------------------------------------------------------------------------------
-- @section
-- These functions control the objective panel visible at the right of the screen.

--- Clears all objective messages.
--- @deprecated use objective.ClearObjectives()
function ClearObjectives() end

--- Adds an objective message with the given name and properties.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param color? string Default to WHITE. See @{_utility.ColorLabels};
--- @param duration? number defaults to 8 seconds
--- @param text? string Override text from the target objective file. [2.0+]
--- @function AddObjective
--- @deprecated use objective.AddObjective()
function AddObjective(name, color, duration, text) end

--- Updates the objective message with the given name. If no objective exists with that name, it does nothing.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param color? string Default to WHITE. See @{_utility.ColorLabels};
--- @param duration? number defaults to 8 seconds
--- @param text? string Override text from the target objective file. [2.0+]
--- @function UpdateObjective
function UpdateObjective(name, color, duration, text) end

--- Removes the objective message with the given file name. Messages after the removed message will be moved up to fill the vacancy. If no objective exists with that file name, it does nothing.
--- @param name string
--- @function RemoveObjective
function RemoveObjective(name) end

-------------------------------------------------------------------------------
-- Cockpit Timer
-------------------------------------------------------------------------------
-- @section
-- These functions control the large timer at the top of the screen.

--- Starts the cockpit timer counting down from the given time. If a warn time is given, the timer will turn yellow when it reaches that value. If an alert time is given, the timer will turn red when it reaches that value. All time values are in seconds.
--- The start time can be up to 35999, which will appear on-screen as 9:59:59. If the remaining time is an hour or less, the timer will show only minutes and seconds.
--- @param time integer
--- @param warn? integer
--- @param alert? integer
--- @function StartCockpitTimer

--- Starts the cockpit timer counting up from the given time. If a warn time is given, the timer will turn yellow when it reaches that value. If an alert time is given, the timer will turn red when it reaches that value. All time values are in seconds.
--- The on-screen timer will always show hours, minutes, and seconds The hours digit will malfunction after 10 hours.
--- @param time integer
--- @param warn? integer
--- @param alert? integer
--- @function StartCockpitTimerUp

--- Stops the cockpit timer.
--- @function StopCockpitTimer

--- Hides the cockpit timer.
--- @function HideCockpitTimer

--- Returns the current time in seconds on the cockpit timer.
--- @return integer
--- @function GetCockpitTimer

-------------------------------------------------------------------------------
-- Earthquake
-------------------------------------------------------------------------------
-- @section
-- These functions control the global earthquake effect.

--- Starts a global earthquake effect.
--- @param magnitude number
--- @function StartEarthquake

--- Changes the magnitude of an existing earthquake effect.
--- Important: note the inconsistent capitalization, which matches the internal C++ script utility functions.
--- @param magnitude number
--- @function UpdateEarthQuake

--- Stops the global earthquake effect.
--- @function StopEarthquake

-------------------------------------------------------------------------------
-- Path Type
-------------------------------------------------------------------------------
-- @section
-- These functions get and set the looping type of a path.
-- Looking up the path type number in the PathType table will convert it to a string. Looking up the path type string in the PathType table will convert it to a number.
-- <ul>
--     <li>0: one-way</li>
--     <li>1: round-trip</li>
--     <li>2: loop</li>
-- </ul>

--- Changes the named path to the given path type.
--- @param path string
--- @param type integer
--- @function SetPathType [2.0+]

--- Returns the type of the named path.
--- @return integer
--- @param path string
--- @function GetPathType [2.0+]

--- Changes the named path to one-way. Once a unit reaches the end of the path, it will stop.
--- @param path string
--- @function SetPathOneWay

--- Changes the named path to round-trip. Once a unit reaches the end of the path, it will follow the path backwards to the start and begin again.
--- @param path string
--- @function SetPathRoundTrip

--- Changes the named path to looping. Once a unit reaches the end of the path, it will continue along to the start and begin again.
--- @param path string
--- @function SetPathLoop

-------------------------------------------------------------------------------
-- Path Points [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Returns the number of points in the named path, or 0 if the path does not exist.
--- [2.0+]
--- @return integer
--- @param path string
--- @function GetPathPointCount

-------------------------------------------------------------------------------
-- Path Area [2.0+]
-------------------------------------------------------------------------------
-- @section
-- These functions treat a path as the boundary of a closed polygonal area.

--- Returns how many times the named path loops around the given game object.
--- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
--- [2.0+]
--- @return integer
--- @param path string
--- @param h handle
--- @function GetWindingNumber

--- Returns how many times the named path loops around the given position.
--- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
--- [2.0+]
--- @return integer
--- @param path string
--- @param position vector
--- @function GetWindingNumber

--- Returns how many times the named path loops around the position of the given transform.
--- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
--- [2.0+]
--- @return integer
--- @param path string
--- @param transform matrix
--- @function GetWindingNumber

--- Returns true if the given game object is inside the area bounded by the named path. Returns false otherwise.
--- This function is equivalent to <pre>GetWindingNumber( path, h ) ~= 0</pre>
--- [2.0+]
--- @return boolean
--- @param path string
--- @param h handle
--- @function IsInsideArea

--- Returns true if the given position is inside the area bounded by the named path. Returns false otherwise.
--- This function is equivalent to <pre>GetWindingNumber( path, position ) ~= 0</pre>
--- [2.0+]
--- @return boolean
--- @param path string
--- @param position vector
--- @function IsInsideArea

--- Returns true if the position of the given transform is inside the area bounded by the named path. Returns false otherwise.
--- This function is equivalent to <pre>GetWindingNumber( path, transform ) ~= 0</pre>
--- [2.0+]
--- @return boolean
--- @param path string
--- @param transform matrix
--- @function IsInsideArea

-------------------------------------------------------------------------------
-- Unit Commands
-------------------------------------------------------------------------------
-- @section
-- These functions send commands to units or query their command state.

--- This is a global table that converts between command numbers and command names. For example, AiCommand.GO or AiCommand["GO"] returns the command number (3) for the "go" command; AiCommand[3] returns the command name ("GO") for command number 3. For maintainability, always use this table instead of raw command numbers.
--- @table AiCommand
AiCommand = {
    NONE = 0, -- 0
    SELECT = 1, -- 1
    STOP = 2, -- 2
    GO = 3, -- 3
    ATTACK = 4, -- 4
    FOLLOW = 5, -- 5
    FORMATION = 6, -- 6
    PICKUP = 7, -- 7
    DROPOFF = 8, -- 8
    NO_DROPOFF = 9, -- 9
    GET_REPAIR = 10, -- 10
    GET_RELOAD = 11, -- 11
    GET_WEAPON = 12, -- 12
    GET_CAMERA = 13, -- 13
    GET_BOMB = 14, -- 14
    DEFEND = 15, -- 15
    GO_TO_GEYSER = 16, -- 16
    RESCUE = 17, -- 17
    RECYCLE = 18, -- 18
    SCAVENGE = 19, -- 19
    HUNT = 20, -- 20
    BUILD = 21, -- 21
    PATROL = 22, -- 22
    STAGE = 23, -- 23
    SEND = 24, -- 24
    GET_IN = 25, -- 25
    LAY_MINES = 26, -- 26
    CLOAK = 27, -- 27 [2.1+]
    DECLOAK = 28, -- 28 [2.1+]
    [0] = "NONE", -- NONE
    [1] = "SELECT", -- SELECT
    [2] = "STOP", -- STOP
    [3] = "GO", -- GO
    [4] = "ATTACK", -- ATTACK
    [5] = "FOLLOW", -- FOLLOW
    [6] = "FORMATION", -- FORMATION
    [7] = "PICKUP", -- PICKUP
    [8] = "DROPOFF", -- DROPOFF
    [9] = "NO_DROPOFF", -- NO_DROPOFF
    [10] = "GET_REPAIR", -- GET_REPAIR
    [11] = "GET_RELOAD", -- GET_RELOAD
    [12] = "GET_WEAPON", -- GET_WEAPON
    [13] = "GET_CAMERA", -- GET_CAMERA
    [14] = "GET_BOMB", -- GET_BOMB
    [15] = "DEFEND", -- DEFEND
    [16] = "GO_TO_GEYSER", -- GO_TO_GEYSER
    [17] = "RESCUE", -- RESCUE
    [18] = "RECYCLE", -- RECYCLE
    [19] = "SCAVENGE", -- SCAVENGE
    [20] = "HUNT", -- HUNT
    [21] = "BUILD", -- BUILD
    [22] = "PATROL", -- PATROL
    [23] = "STAGE", -- STAGE
    [24] = "SEND", -- SEND
    [25] = "GET_IN", -- GET_IN
    [26] = "LAY_MINES", -- LAY_MINES
    [27] = "CLOAK", -- CLOAK [2.1+]
    [28] = "DECLOAK", -- DECLOAK [2.1+]
}

--- Returns true if the game object can be commanded. Returns false otherwise.
--- @return boolean
--- @param me handle
--- @function CanCommand

--- Returns true if the game object is a producer that can build at the moment. Returns false otherwise.
--- @return boolean
--- @param me handle
--- @function CanBuild

--- Returns true if the game object is a producer and currently busy. Returns false otherwise.
--- @return boolean
--- @param me handle
--- @function IsBusy

--- Returns the current command for the game object. Looking up the command number in the AiCommand table will convert it to a string. Looking up the command string in the AiCommand table will convert it back to a number.
--- @return integer
--- @param me handle
--- @function GetCurrentCommand

--- Returns the target of the current command for the game object. Returns nil if it has none.
--- @return handle
--- @param me handle
--- @function GetCurrentWho

--- Gets the independence of a unit.
--- @return integer
--- @param me handle
--- @function GetIndependence

--- Sets the independence of a unit. 1 (the default) lets the unit take initiative (e.g. attack nearby enemies), while 0 prevents that.
--- @param me handle
--- @param independence integer
--- @function SetIndependence

--- Commands the unit using the given parameters. Be careful with this since not all commands work with all units and some have strict requirements on their parameters.
--- "Command" is the command to issue, normally chosen from the global AiCommand table (e.g. AiCommand.GO).
--- "Priority" is the command priority; a value of 0 leaves the unit commandable by the player while the default value of 1 makes it uncommandable.
--- "Who" is an optional target game object.
--- "Where" is an optional destination, and can be a matrix (transform), a vector (position), or a string (path name).
--- "When" is an optional absolute time value only used by command AiCommand.STAGE.
--- "Param" is an optional odf name only used by command AiCommand.BUILD.
--- @param me handle
--- @param command integer
--- @param priority? integer
--- @param who? handle
--- @tparam[opt] matrix|vector|string where
--- @param when? number
--- @param param? string
--- @function SetCommand

--- Commands the unit to attack the given target.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Attack

--- Commands the unit to go to the named path.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param path string
--- @param priority? integer
--- @function Goto

--- Commands the unit to go to the given target
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Goto

--- Commands the unit to go to the given position vector
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param position vector
--- @param priority? integer
--- @function Goto

--- Commands the unit to go to the position of the given transform matrix
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param transform matrix
--- @param priority? integer
--- @function Goto
function Goto(me, location, priority) end

--- Commands the unit to lay mines at the named path; only minelayer units support this.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param path string
--- @param priority? integer
--- @function Mine

--- Commands the unit to lay mines at the given position vector
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param position vector
--- @param priority? integer
--- @function Mine

--- Commands the unit to lay mines at the position of the transform matrix
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param transform matrix
--- @param priority? integer
--- @function Mine

--- Commands the unit to follow the given target.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Follow

--- Returns true if the unit is currently following the given target.
--- [2.1+]
--- @return boolean
--- @param me handle
--- @param him handle
--- @function IsFollowing

--- Commands the unit to defend its current location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param priority? integer
--- @function Defend

--- Commands the unit to defend the given target.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Defend2

--- Commands the unit to stop at its current location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param priority? integer
--- @function Stop

--- Commands the unit to patrol along the named path. This is equivalent to Goto with an independence of 1.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param path string
--- @param priority? integer
--- @function Patrol

--- Commands the unit to retreat to the named path. This is equivalent to Goto with an independence of 0.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param path string
--- @param priority? integer
--- @function Retreat

--- Commands the unit to retreat to the given target. This is equivalent to Goto with an independence of 0.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Retreat

--- Commands the pilot to get into the target vehicle.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function GetIn

--- Commands the unit to pick up the target object. Deployed units pack up (ignoring the target), scavengers pick up scrap, and tugs pick up and carry objects.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Pickup

--- Commands the unit to drop off at the named path. Tugs drop off their cargo and Construction Rigs build the selected item at the location using their current facing.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param path string
--- @param priority? integer
--- @function Dropoff

--- Commands the unit to drop off at the position vector. Tugs drop off their cargo and Construction Rigs build the selected item at the location using their current facing.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param position vector
--- @param priority? integer
--- @function Dropoff

--- Commands the unit to drop off at the position of the transform matrix. Tugs drop off their cargo and Construction Rigs build the selected item with the facing of the transform matrix.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param transform matrix
--- @param priority? integer
--- @function Dropoff

--- Commands a producer to build the given odf name. The Armory and Construction Rig need an additional Dropoff to give them a location to build but first need at least one simulation update to process the Build.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param odfname string
--- @param priority? integer
--- @function Build

--- Commands a producer to build the given odf name at the location of the target game object. A Construction Rig will build at the location and an Armory will launch the item to the location. Other producers will ignore the location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param odfname string
--- @param target handle
--- @param priority? integer
--- @function BuildAt

--- Commands a producer to build the given odf name at the named path. A Construction Rig will build at the location and an Armory will launch the item to the location. Other producers will ignore the location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param odfname string
--- @param path string
--- @param priority? integer
--- @function BuildAt

--- Commands a producer to build the given odf name at the position vector. A Construction Rig will build at the location with their current facing and an Armory will launch the item to the location. Other producers will ignore the location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param odfname string
--- @param position vector
--- @param priority? integer
--- @function BuildAt

--- Commands a producer to build the given odf name at the transform matrix. A Construction Rig will build at the location with the facing of the transform and an Armory will launch the item to the location. Other producers will ignore the location.
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- @param me handle
--- @param odfname string
--- @param transform matrix
--- @param priority? integer
--- @function BuildAt

--- Commands the unit to follow the given target closely. This function is equivalent to SetCommand(me, AiCommand.FORMATION, priority, him).
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- [2.1+]
--- @param me handle
--- @param him handle
--- @param priority? integer
--- @function Formation

--- Commands the unit to hunt for targets autonomously. This function is equivalent to SetCommand(me, AiCommand.HUNT, priority).
--- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
--- [2.1+]
--- @param me handle
--- @param priority? integer
--- @function Hunt

-------------------------------------------------------------------------------
-- Tug Cargo
-------------------------------------------------------------------------------
-- @section
-- These functions query Tug and Cargo.

--- Returns true if the unit is a tug carrying cargo.
--- @return boolean
--- @param tug handle
--- @function HasCargo

--- Returns the handle of the cargo if the unit is a tug carrying cargo. Returns nil otherwise.
--- [2.1+]
--- @return handle
--- @param tug handle
--- @function GetCargo

--- Returns the handle of the tug carrying the object. Returns nil if not carried.
--- @return handle
--- @param cargo handle
--- @function GetTug

-------------------------------------------------------------------------------
-- Pilot Actions
-------------------------------------------------------------------------------
-- @section
-- These functions control the pilot of a vehicle.

--- Commands the vehicle's pilot to eject.
--- @param h handle
--- @function EjectPilot

--- Commands the vehicle's pilot to hop out.
--- @param h handle
--- @function HopOut

--- Kills the vehicle's pilot as if sniped.
--- @param h handle
--- @function KillPilot

--- Removes the vehicle's pilot cleanly.
--- @param h handle
--- @function RemovePilot

--- Returns the vehicle that the pilot most recently hopped out of.
--- @return handle
--- @param h handle
--- @function HoppedOutOf

-------------------------------------------------------------------------------
-- Health Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set health values on a game object.

--- Returns the fractional health of the game object between 0 and 1.
--- @return number
--- @param h handle
--- @function GetHealth

--- Returns the current health value of the game object.
--- @return number
--- @param h handle
--- @function GetCurHealth

--- Returns the maximum health value of the game object.
--- @return number
--- @param h handle
--- @function GetMaxHealth

--- Sets the current health of the game object.
--- @param h handle
--- @param health number
--- @function SetCurHealth

--- Sets the maximum health of the game object.
--- @param h handle
--- @param health number
--- @function SetMaxHealth

--- Adds to the current health of the game object.
--- @param h handle
--- @param health number
--- @function AddHealth

--- Sets the unit's current health to maximum.
--- [2.1+]
--- @param h handle
--- @function GiveMaxHealth

-------------------------------------------------------------------------------
-- Ammo Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set ammo values on a game object.

--- Returns the fractional ammo of the game object between 0 and 1.
--- @return number
--- @param h handle
--- @function GetAmmo

--- Returns the current ammo value of the game object.
--- @return number
--- @param h handle
--- @function GetCurAmmo

--- Returns the maximum ammo value of the game object.
--- @return number
--- @param h handle
--- @function GetMaxAmmo

--- Sets the current ammo of the game object.
--- @param h handle
--- @param ammo number
--- @function SetCurAmmo

--- Sets the maximum ammo of the game object.
--- @param h handle
--- @param ammo number
--- @function SetMaxAmmo

--- Adds to the current ammo of the game object.
--- @param h handle
--- @param ammo number
--- @function AddAmmo

--- Sets the unit's current ammo to maximum.
--- [2.1+]
--- @param h handle
--- @function GiveMaxAmmo

-------------------------------------------------------------------------------
-- Cinematic Camera
-------------------------------------------------------------------------------
-- These functions control the cinematic camera for in-engine cut scenes (or "cineractives" as the Interstate '76 team at Activision called them).
-- @section

--- Starts the cinematic camera and disables normal input.
--- Always returns true.
--- @return boolean
--- @function CameraReady
function CameraReady() end

--- Moves a cinematic camera along a path at a given height and speed while looking at a target game object.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @return boolean
--- @param path string
--- @param height integer
--- @param speed integer
--- @param target handle
--- @function CameraPath
function CameraPath(path, height, speed, target) end

--- Moves a cinematic camera long a path at a given height and speed while looking along the path direction.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @return boolean
--- @param path string
--- @param height integer
--- @param speed integer
--- @function CameraPathDir

--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @return boolean
--- @function PanDone

--- Offsets a cinematic camera from a base game object while looking at a target game object. The right, up, and forward offsets are in centimeters.
--- Returns true if the base or handle game object does not exist. Returns false otherwise.
--- @return boolean
--- @param base handle
--- @param right integer
--- @param up integer
--- @param forward integer
--- @param target handle
--- @function CameraObject

--- Finishes the cinematic camera and enables normal input.
--- Always returns true.
--- @return boolean
--- @function CameraFinish
function CameraFinish() end

--- Returns true if the player canceled the cinematic. Returns false otherwise.
--- @return boolean
--- @function CameraCancelled
function CameraCancelled() end

-------------------------------------------------------------------------------
-- Info Display
-------------------------------------------------------------------------------
-- @section

--- Returns true if the game object inspected by the info display matches the given odf name.
--- @return boolean
--- @param odfname string
--- @function IsInfo

-------------------------------------------------------------------------------
-- Network
-------------------------------------------------------------------------------
-- @section
-- LuaMission currently has limited network support, but can detect if the mission is being run in multiplayer and if the local machine is hosting.

--- Returns true if the game is a network game. Returns false otherwise.
--- @return boolean
--- @function IsNetGame

--- Returns true if the local machine is hosting a network game. Returns false otherwise.
--- @return boolean
--- @function IsHosting

--- Sets the game object as local to the machine the script is running on, transferring ownership from its original owner if it was remote. Important safety tip: only call this on one machine at a time!
--- @param h handle
--- @function SetLocal

--- Returns true if the game is local to the machine the script is running on. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsLocal

--- Returns true if the game object is remote to the machine the script is running on. Returns false otherwise.
--- @return boolean
--- @param h handle
--- @function IsRemote

--- Adds a system text message to the chat window on the local machine.
--- @param message string
--- @function DisplayMessage

--- Send a script-defined message across the network.
--- To is the player network id of the recipient. None, nil, or 0 broadcasts to all players.
--- Type is a one-character string indicating the script-defined message type.
--- Other parameters will be sent as data and passed to the recipient's Receive function as parameters. Send supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
--- The sent packet can contain up to 244 bytes of data (255 bytes maximum for an Anet packet minus 6 bytes for the packet header and 5 bytes for the reliable transmission header)
--- <table><tbody>
---   <tr><th colspan="2">Type</th><th>Bytes</th></tr>
---   <tr><td colspan="2">nil</td><td>1</td></tr>
---   <tr><td colspan="2">boolean</td><td>1</td></tr>
---   <tr><td rowspan="2">handle</td><td>invalid (zero)</td><td>1</td></tr>
---   <tr><td>valid (nonzero)</td><td>1 + sizeof(int) = 5</td></tr>
---   <tr><td rowspan="5">number</td><td>zero</td><td>1</td></tr>
---   <tr><td>char (integer -128 to 127)</td><td>1 + sizeof(char) = 2</td></tr>
---   <tr><td>short (integer -32768 to 32767)</td><td>1 + sizeof(short) = 3</td></tr>
---   <tr><td>int (integer)</td><td>1 + sizeof(int) = 5</td></tr>
---   <tr><td>double (non-integer)</td><td>1 + sizeof(double) = 9</td></tr>
---   <tr><td rowspan="2">string</td><td>length &lt; 31</td><td>1 + length</td></tr>
---   <tr><td>length &gt;= 31</td><td>2 + length</td></tr>
---   <tr><td rowspan="2">table</td><td>count &lt; 31</td><td>1 + count + size of keys and values</td></tr>
---   <tr><td>count &gt;= 31</td><td>2 + count + size of keys and values</td></tr>
---   <tr><td rowspan="2">userdata</td><td>VECTOR_3D</td><td>1 + sizeof(VECTOR_3D) = 13</td></tr>
---   <tr><td>MAT_3D</td><td>1 + sizeof(REDUCED_MAT) = 12</td></tr>
--- </tbody></table>
--- @param to integer
--- @param type string
--- @param ...
--- @function Send

-------------------------------------------------------------------------------
-- Read ODF
-------------------------------------------------------------------------------
-- @section
-- These functions read values from an external ODF, INI, or TRN file.

--- Opens the named file as an ODF. If the file name has no extension, the function will append ".odf" automatically.
--- If the file is not already open, the function reads in and parses the file into an internal database. If you need to read values from it relatively frequently, save the handle into a global variable to prevent it from closing.
--- Returns the file handle if it succeeded. Returns nil if it failed.
--- @return odfhandle
--- @param filename string
--- @function OpenODF

--- Reads a boolean value from the named label in the named section of the ODF file. Use a nil section to read labels that aren't in a section.
--- It considers values starting with 'Y', 'y', 'T', 't', or '1' to be true and value starting with 'N', 'n', 'F', 'f', or '0' to be false. Other values are considered undefined.
--- If a value is not found or is undefined, it uses the default value. If no default value is given, the default value is false. 
--- Returns the value and whether the value was found.
--- @return boolean
--- @return boolean
--- @param odf odfhandle
--- @param section? string
--- @param label string
--- @param default? string
--- @function GetODFBool

--- Reads an integer value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section. 
--- If no value is found, it uses the default value. If no default value is given, the default value is 0. 
--- Returns the value and whether the value was found.
--- @return integer
--- @return boolean
--- @param odf odfhandle
--- @param section? string
--- @param label string
--- @param default? string
--- @function GetODFInt

--- Reads a floating-point value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section.
--- If no value is found, it uses the default value. If no default value is given, the default value is 0.0.
--- Returns the value and whether the value was found.
--- @return number
--- @return boolean
--- @param odf odfhandle
--- @param section? string
--- @param label string
--- @param default? string
--- @function GetODFFloat

--- Reads a string value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section.
--- If a value is not found, it uses the default value. If no default value is given, the default value is nil.
--- Returns the value and whether the value was found.
--- @return string
--- @return boolean
--- @param odf odfhandle
--- @param section? string
--- @param label string
--- @param default? string
--- @function GetODFString

-------------------------------------------------------------------------------
-- Terrain
-------------------------------------------------------------------------------
-- @section
-- These functions return height and normal from the terrain height field.

--- Returns the terrain height and normal vector at the location of the game object.
--- @return number
--- @return vector
--- @param h handle
--- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at a point on the named path. It uses the start of the path if no point is given.
--- @return number
--- @return vector
--- @param path string
--- @param point? integer
--- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at the position vector.
--- @return number
--- @return vector
--- @param position vector
--- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at the position of the transform matrix.
--- @return number
--- @return vector
--- @param transform matrix
--- @function GetTerrainHeightAndNormal

-------------------------------------------------------------------------------
-- Floor
-------------------------------------------------------------------------------
-- These functions return height and normal from the terrain height field and the upward-facing polygons of any entities marked as floor owners.
-- @section

--- Returns the floor height and normal vector at the location of the game object.
--- @return number
--- @return vector
--- @param h handle
--- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at a point on the named path. It uses the start of the path if no point is given.
--- @return number
--- @return vector
--- @param path string
--- @param point? integer
--- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at the position vector.
--- @return number
--- @return vector
--- @param position vector
--- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at the position of the transform matrix.
--- @return number
--- @return vector
--- @param transform matrix
--- @function GetFloorHeightAndNormal

-------------------------------------------------------------------------------
-- Map
-------------------------------------------------------------------------------
-- @section

--- Returns the name of the BZN file for the map. This can be used to generate an ODF name for mission settings.
--- [2.0+]
--- @return string
--- @function GetMissionFilename

--- Returns the name of the TRN file for the map. This can be used with OpenODF() to read values from the TRN file.
--- @return string
--- @function GetMapTRNFilename

-------------------------------------------------------------------------------
-- Files [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Returns the contents of the named file as a string, or nil if the file could not be opened.
--- [2.0+]
--- @param filename string
--- @function string UseItem

-------------------------------------------------------------------------------
-- Effects [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Starts a full screen color fade.
--- Ratio sets the opacity, with 0.0 transparent and 1.0 almost opaque
--- Rate sets how fast the opacity decreases over time.
--- R, G, and B set the color components and range from 0 to 255
--- [2.0+]
--- @param ratio number
--- @param rate number
--- @param r integer
--- @param g integer
--- @param b integer
--- @function ColorFade

-------------------------------------------------------------------------------
-- Vector
-------------------------------------------------------------------------------
-- @section
-- This is a custom userdata representing a position or direction. It has three number components: x, y, and z.

--- Returns a vector whose components have the given number values. If no value is given for a component, the default value is 0.0.
--- @return vector
--- @param x? number
--- @param y? number
--- @param z? number
--- @function SetVector

--- Returns the <a href="http://en.wikipedia.org/wiki/Dot_product">dot product</a> between vectors a and b.
--- Equivalent to a.x * b.x + a.y * b.y + a.z * b.z.
--- @return number
--- @param a vector
--- @param a vector
--- @function DotProduct

--- Returns the <a href="http://en.wikipedia.org/wiki/Cross_product">cross product</a> between vectors a and b.
--- Equivalent to SetVector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x).
--- @return vector
--- @param a vector
--- @param b vector
--- @function CrossProduct

--- Returns the vector scaled to unit length.
--- Equivalent to SetVector(v.x * scale, v.y * scale, v.z * scale) where scale is 1.0f / sqrt(v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>).
--- @return vector
--- @param v vector
--- @function Normalize

--- Returns the length of the vector.
--- Equivalent to sqrt(v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>).
--- @return number
--- @param v vector
--- @function Length

--- Returns the squared length of the vector.
--- Equivalent to v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>.
--- @return number
--- @param v vector
--- @function LengthSquared

--- Returns the 2D distance between vectors a and b.
--- Equivalent to sqrt((b.x - a.x)<sup>2</sup> + (b.z - a.z)<sup>2</sup>).
--- @return number
--- @param a vector
--- @param b vector
--- @function Distance2D

--- Returns the squared 2D distance of the vector.
--- Equivalent to (b.x - a.x)<sup>2</sup> + (b.z - a.z)<sup>2</sup>.
--- @return number
--- @param a vector
--- @param b vector
--- @function Distance2DSquared

--- Returns the 3D distance between vectors a and b.
--- Equivalent to sqrt((b.x - a.x)<sup>2</sup> + (b.y - a.y)<sup>2</sup> + (b.z - a.z)<sup>2</sup>).
--- @return number
--- @param a vector
--- @param b vector
--- @function Distance3D

--- Returns the squared 3D distance of the vector.
--- Equivalent to (b.x - a.x)<sup>2</sup> + (b.y - a.y)<sup>2</sup> + (b.z - a.z)<sup>2</sup>.
--- @return number
--- @param a vector
--- @param b vector
--- @function Distance3DSquared

--- Negate the vector.
--
-- Equivalent to SetVector(-vector.x, -vector.y, -vector.z).
-- @tparam vector vector
-- @function vector:unm

--- Add two vectors.
--
-- Equivalent to SetVector(vector1.x + vector2.x, vector1.y + vector2.y, vector1.z + vector2.z).
-- @tparam vector vector1
-- @tparam vector vector2
-- @function vector:add

--- Subtract two vectors.
--
-- Equivlent to SetVector(vector1.x - vector2.x, vector1.y - vector2.y, vector1.z - vector2.z).
-- @tparam vector vector1
-- @tparam vector vector2
-- @function vector:sub

--- Multiply a number by a vector.
--
-- Equivalent to SetVector( number * vector.x, number * vector.y, number * vector.z).
-- @tparam number number
-- @tparam vector vector
-- @function vector:mul

--- Multiply a vector by a number.
--
-- Equivalent to SetVector(vector.x * number, vector.y * number, vector.z * number).
-- @tparam vector vector
-- @tparam number number
-- @function vector:mul

--- Multiply two vectors.
--
-- Equivlent to SetVector(vector1.x * vector2.x, vector1.y * vector2.y, vector1.z * vector2.z)
-- @tparam vector vector1
-- @tparam vector vector2
-- @function vector:mul

--- Divide a number by a vector.
--
-- Equivalent to SetVector( number / vector.x, number / vector.y, number / vector.z).
-- @tparam number number
-- @tparam vector vector
-- @function vector:div

--- Divide a vector by a number.
--
-- Equivalent to SetVector(vector.x / number, vector.y / number, vector.z / number).
-- @tparam vector vector
-- @tparam number number
-- @function vector:div

--- Divide two vectors.
--
-- Equivlent to SetVector(vector1.x / vector2.x, vector1.y / vector2.y, vector1.z / vector2.z)
-- @tparam vector vector1
-- @tparam vector vector2
-- @function vector:div

--- Check if two vectors are equal.
--
-- @tparam vector vector1
-- @tparam vector vector2
-- @function vector:eq

-------------------------------------------------------------------------------
-- Matrix
-------------------------------------------------------------------------------
-- @section
-- This is a custom userdata representing an orientation and position in space. It has four vector components (right, up, front, and posit) sharing space with twelve number components (right_x, right_y, right_z, up_x, up_y, up_z, front_x, front_y, front_z, posit_x, posit_y, posit_z).

--- Returns a matrix whose components have the given number values. If no value is given for a component, the default value is zero. Be careful with this since it's easy to build a non-orthonormal matrix that will break all kinds of built-in assumptions.
--- @return matrix
--- @param right_x? number
--- @param right_y? number
--- @param right_z? number
--- @param up_x? number
--- @param up_y? number
--- @param up_z? number
--- @param front_x? number
--- @param front_y? number
--- @param front_z? number
--- @param posit_x? number
--- @param posit_y? number
--- @param posit_z? number
--- @function SetMatrix

--- Global value representing the identity matrix.
--- Equivalent to SetMatrix(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0).
--- @function matrix IdentityMatrix

--- Build a matrix representing a rotation by an angle around an axis. The angle is in radians. If no value is given for the angle or an axis component, the default value is zero. The axis must be unit-length (i.e. axis_x<sup>2</sup> + axis_y<sup>2</sup> + axis_z<sup>2</sup> = 1.0 or the resulting matrix will be wrong.
--- @return matrix
--- @param angle? number
--- @param axis_x? number
--- @param axis_y? number
--- @param axis_z? number
--- @function BuildAxisRotationMatrix

--- Build a matrix representing a rotation by an angle around an axis. The angle is in radians. If no value is given for the angle, the default value is zero. The axis must be unit-length (i.e. axis.x<sup>2</sup> + axis.y<sup>2</sup> + axis.z<sup>2</sup> = 1.0 or the resulting matrix will be wrong.
--- @return matrix
--- @param angle? number
--- @param axis vector
--- @function BuildAxisRotationMatrix

--- Build a matrix with the given pitch, yaw, and roll angles and position. The angles are in radians. If no value is given for a component, the default value is zero.
--- @return matrix
--- @param pitch? number
--- @param yaw? number
--- @param roll? number
--- @param posit_x? number
--- @param posit_y? number
--- @param posit_z? number
--- @function BuildPositionRotationMatrix

--- Build a matrix with the given pitch, yaw, and roll angles and position. The angles are in radians. If no value is given for a component, the default value is zero.
--- @return matrix
--- @param pitch? number
--- @param yaw? number
--- @param roll? number
--- @param position vector
--- @function BuildPositionRotationMatrix

--- Build a matrix with zero position, its up axis along the specified up vector, oriented so that its front axis points as close as possible to the heading vector. If up is not specified, the default value is the Y axis. If heading is not specified, the default value is the Z axis.
--- @return matrix
--- @param up? vector
--- @param heading? vector
--- @function BuildOrthogonalMatrix

--- Build a matrix with the given position vector, its front axis pointing along the direction vector, and zero roll. If position is not specified, the default value is a zero vector. If direction is not specified, the default value is the Z axis.
--- @return matrix
--- @param position? vector
--- @param direction? vector
--- @function BuildDirectionalMatrix

--- Multiply two matrices.
--- @param matrix1 matrix
--- @param matrix2 matrix
--- @function matrix:mul

--- Transform a vector by a matrix.
--- @param matrix matrix
--- @param vector vector
--- @function matrix:mul

-------------------------------------------------------------------------------
-- Portal Functions [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions control the Portal building introduced in The Red Odyssey expansion.

--- Sets the specified Portal direction to "out", indicated by a blue visual effect while active.
--- [2.1+]
--- @param portal handle
--- @function PortalOut

--- Sets the specified Portal direction to "in", indicated by an orange visual effect while active.
--- [2.1+]
--- @param portal handle
--- @function PortalIn

--- Deactivates the specified Portal, stopping the visual effect.
--- [2.1+]
--- @param portal handle
--- @function DeactivatePortal

--- Activates the specified Portal, starting the visual effect.
--- [2.1+]
--- @param portal handle
--- @function ActivatePortal

--- Returns true if the specified Portal direction is "in". Returns false otherwise.
--- [2.1+]
--- @return bool
--- @param portal handle
--- @function IsIn

--- Returns true if the specified Portal is active. Returns false otherwise.
--- Important: note the capitalization!
--- [2.1+]
--- @return bool
--- @param portal handle
--- @function isPortalActive

--- Creates a game object with the given odf name and team number at the location of a portal.
--- The object is created at the location of the visual effect and given a 50 m/s initial velocity.
--- [2.1+]
--- @return handle
--- @param odfname string
--- @param teamnum integer
--- @param portal handle
--- @function BuildObjectAtPortal

-------------------------------------------------------------------------------
-- Cloak [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions control the cloaking state of craft capable of cloaking.

--- Makes the specified unit cloak if it can.
--- Note: unlike SetCommand(h, AiCommand.CLOAK), this does not change the unit's current command.
--- [2.1+]
--- @param h handle
--- @function Cloak

--- Makes the specified unit de-cloak if it can.
--- Note: unlike SetCommand(h, AiCommand.DECLOAK), this does not change the unit's current command.
--- [2.1+]
--- @param h handle
--- @function Decloak

--- Instantly sets the unit as cloaked (with no fade out).
--- [2.1+]
--- @param h handle
--- @function SetCloaked

--- Instant sets the unit as uncloaked (with no fade in).
--- [2.1+]
--- @param h handle
--- @function SetDecloaked

--- Returns true if the unit is cloaked. Returns false otherwise
--- [2.1+]
--- @return bool
--- @param h handle
--- @function IsCloaked

--- Enable or disable cloaking for a specified cloaking-capable unit.
--- Note: this does not grant a non-cloaking-capable unit the ability to cloak.
--- [2.1+]
--- @param h handle
--- @param enable bool
--- @function EnableCloaking

--- Enable or disable cloaking for all cloaking-capable units.
--- Note: this does not grant a non-cloaking-capable unit the ability to cloak.
--- [2.1+]
--- @param enable bool
--- @function EnableAllCloaking

-------------------------------------------------------------------------------
-- Hide [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions hide and show game objects. When hidden, the object is invisible (similar to Phantom VIR and cloak) and undetectable on radar (similar to RED Field and cloak). The effect is similar to but separate from cloaking. For the most part, AI units ignore the hidden state.

--- Hides a game object.
--- [2.1+]
--- @param h handle
--- @function Hide

--- Un-hides a game object.
--- [2.1+]
--- @param h handle
--- @function UnHide

-------------------------------------------------------------------------------
-- Explosion [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions create explosions at a specified location. They do not return a handle because explosions are not game objects and thus not visible to the scripting system.

--- Creates an explosion with the given odf name at the location of a game object.
--- [2.1+]
--- @param odfname string
--- @param h handle
--- @function MakeExplosion

--- Creates an explosion with the given odf name at the start of the named path.
--- [2.1+]
--- @param odfname string
--- @param path string
--- @function MakeExplosion

--- Creates an explosion with the given odf name at the given position vector.
--- [2.1+]
--- @param odfname string
--- @param position vector
--- @function MakeExplosion

--- Creates an explosion with the given odf name with the given transform matrix.
--- [2.1+]
--- @param odfname string
--- @param transform matrix
--- @function MakeExplosion
