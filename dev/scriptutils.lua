--- BZ98R ScriptUtils Stub
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
-- <ol>
--     <li>English</li>
--     <li>French</li>
--     <li>German</li>
--     <li>Spanish</li>
--     <li>Italian</li>
--     <li>Portuguese</li>
--     <li>Russian</li>
-- </ol>
-- [2.0+]
-- @field Language integer

--- Contains the full name of the current language in all-caps: "ENGLISH", "FRENCH", "GERMAN", "SPANISH", "ITALIAN", "PORTUGUESE", or "RUSSIAN"
-- [2.0+]
-- @field LanguageName string

--- Contains the two-letter language code of the current language: "en", "fr", "de", "es", "it", "pt" or "ru"
-- [2.0+]
-- @field LanguageSuffix string

--- Contains the most recently pressed game key (e.g. "Ctrl+Z")
-- @field LastGameKey string

-------------------------------------------------------------------------------
-- Audio Messages
-------------------------------------------------------------------------------
-- @section
-- These functions control audio messages, 2D sounds typically used for radio messages, voiceovers, and narration.
-- Audio messages use the Voice Volume setting from the Audio Options menu.

--- Repeat the last audio message.
-- @function RepeatAudioMessage

--- Plays the given audio file, which must be an uncompressed RIFF WAVE (.WAV) file.
-- Returns an audio message handle.
-- @treturn message
-- @tparam string filename
-- @function AudioMessage

--- Returns true if the audio message has stopped. Returns false otherwise.
-- @treturn boolean
-- @tparam message msg
-- @function IsAudioMessageDone

--- Stops the given audio message.
-- @tparam message msg
-- @function StopAudioMessage

--- Returns true if <em>any</em> audio message is playing. Returns false otherwise.
-- @treturn boolean
-- @function IsAudioMessagePlaying

-------------------------------------------------------------------------------
-- Sound Effects
-------------------------------------------------------------------------------
-- @section
-- These functions control sound effects, either positional 3D sounds attached to objects or global 2D sounds.
-- Sound effects use the Effects Volume setting from the Audio Options menu.

--- Plays the given audio file, which must be an uncompressed RIFF WAVE (.WAV) file.
-- Specifying an object handle creates a positional 3D sound that follows the object as it moves and stops automatically when the object goes away. Otherwise, the sound plays as a global 2D sound.
-- Priority ranges from 0 to 100, with higher priorities taking precedence over lower priorities when there are not enough channels. The default priority is 50 if not specified.
-- Looping sounds will play forever until explicitly stopped with StopSound or the object to which it is attached goes away. Non-looping sounds will play once and stop. The default is non-looping if not specified.
-- Volume ranges from 0 to 100, with 0 being silent and 100 being maximum volume. The default volume is 100 if not specified.
-- Rate overrides the playback rate of the sound file, so a value of 22050 would cause a sound file recorded at 11025 Hz to play back twice as fast. The rate defaults to the file's native rate if not specified.
-- @tparam string filename
-- @tparam[opt] Handle h
-- @tparam[opt] integer priority
-- @tparam[opt] boolean loop
-- @tparam[opt] integer volume
-- @tparam[opt] integer rate
-- @function StartSound

--- Stops the sound using the given filename and associated with the given object. Use a handle of none or nil to stop a global 2D sound.
-- @tparam string filename
-- @tparam[opt] Handle h
-- @function StopSound

-------------------------------------------------------------------------------
-- Game Object
-------------------------------------------------------------------------------
-- @section
-- These functions create, manipulate, and query game objects (vehicles, buildings, people, powerups, and scrap) and return or take as a parameter a game object handle.
-- Object handles are always safe to use, even if the game object itself is missing or destroyed.

--- Returns the handle of the game object with the given label. Returns nil if none exists.
-- @treturn handle
-- @tparam string label
-- @function GetHandle

--- Creates a game object with the given odf name and team number at the location of a game object.
-- Returns the handle of the created object if it created one. Returns nil if it failed.
-- @treturn handle
-- @tparam string odfname
-- @tparam integer teamnum
-- @tparam handle h
-- @function BuildObject

--- Creates a game object with the given odf name and team number at a point on the named path. It uses the start of the path if no point is given.
-- Returns the handle of the created object if it created one. Returns nil if it failed.
-- @treturn handle
-- @tparam string odfname
-- @tparam integer teamnum
-- @tparam string path
-- @tparam[opt] integer point
-- @function BuildObject

--- Creates a game object with the given odf name and team number at the given position vector.
-- Returns the handle of the created object if it created one. Returns nil if it failed.
-- @treturn handle
-- @tparam string odfname
-- @tparam integer teamnum
-- @tparam vector position
-- @function BuildObject

--- Creates a game object with the given odf name and team number with the given transform matrix.
-- Returns the handle of the created object if it created one. Returns nil if it failed.
-- @treturn handle
-- @tparam string odfname
-- @tparam integer teamnum
-- @tparam matrix transform
-- @function BuildObject

--- Removes the game object with the given handle.
-- @tparam handle h
-- @function RemoveObject

--- Returns true if the game object's odf name matches the given odf name. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @tparam string odfname
-- @function IsOdf

--- Returns the odf name of the game object. Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetOdf

--- Returns the base config of the game object which determines what VDF/SDF model it uses. Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetBase

--- Returns the label of the game object (e.g. "avtank0_wingman"). Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetLabel

--- Set the label of the game object (e.g. "tank1").
-- <p>Note: this function was misspelled as SettLabel in 1.5. It can be renamed compatibly with a short snippet of code at the top of the mission script:</p>
-- <pre>SetLabel = SetLabel or SettLabel</pre>
-- @tparam Handle h
-- @tparam string label
-- @function SetLabel

--- Returns the four-character class signature of the game object (e.g. "WING"). Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetClassSig

--- Returns the class label of the game object (e.g. "wingman"). Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetClassLabel

--- Returns the numeric class identifier of the game object. Returns nil if none exists.
-- Looking up the class id number in the ClassId table will convert it to a string. Looking up the class id string in the ClassId table will convert it back to a number.
-- @treturn integer
-- @tparam handle h
-- @function GetClassId

--- This is a global table that converts between class identifier numbers and class identifier names. For example, ClassId.SCRAP or ClassId["SCRAP"] returns the class identifier number (7) for the Scrap class; ClassId[7] returns the class identifier name ("SCRAP") for class identifier number 7. For maintainability, always use this table instead of raw class identifier numbers.
-- Available class identifiers: NONE, HELICOPTER, STRUCTURE1, POWERUP, PERSON, SIGN, VEHICLE, SCRAP, BRIDGE, FLOOR, STRUCTURE2, SCROUNGE, SPINNER, HEADLIGHT_MASK, EYEPOINT, COM, WEAPON, ORDNANCE, EXPLOSION, CHUNK, SORT_OBJECT, NONCOLLIDABLE, VEHICLE_GEOMETRY, STRUCTURE_GEOMETRY, WEAPON_GEOMETRY, ORDNANCE_GEOMETRY, TURRET_GEOMETRY, ROTOR_GEOMETRY, NACELLE_GEOMETRY, FIN_GEOMETRY, COCKPIT_GEOMETRY, WEAPON_HARDPOINT, CANNON_HARDPOINT, ROCKET_HARDPOINT, MORTAR_HARDPOINT, SPECIAL_HARDPOINT, FLAME_EMITTER, SMOKE_EMITTER, DUST_EMITTER, PARKING_LOT
-- @table ClassId

--- Returns the one-letter nation code of the game object (e.g. "a" for American, "b" for Black Dog, "c" for Chinese, and "s" for Soviet).
-- The nation code is usually but not always the same as the first letter of the odf name. The ODF file can override the nation in the [GameObjectClass] section, and player.odf is a hard-coded exception that uses "a" instead of "p".
-- @treturn string
-- @tparam handle h
-- @function GetNation

--- Returns true if the game object exists. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsValid

--- Returns true if the game object exists and (if the object is a vehicle) controlled. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsAlive

--- Returns true if the game object exists and (if the object is a vehicle) controlled and piloted. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsAliveAndPilot

--- Returns true if the game object exists and is a vehicle. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsCraft

--- Returns true if the game object exists and is a building. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsBuilding

--- Returns true if the game object exists and is a person. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsPerson

--- Returns true if the game object exists and has less health than the threshold. Returns false otherwise.
-- @treturn boolean
-- @function IsDamaged ( handle h [, float threshold] )

--- Returns true if the game object was recycled by a Construction Rig on the given team.
-- [2.1+]
-- @treturn boolean
-- @tparam handle h
-- @tparam integer team
-- @function IsRecycledByTeam

-------------------------------------------------------------------------------
-- Team Number
-------------------------------------------------------------------------------
-- @section
-- These functions get and set team number. Team 0 is the neutral or environment team.

--- Returns the game object's team number.
-- @treturn integer
-- @tparam handle h
-- @function GetTeamNum

--- Sets the game object's team number.
-- @tparam handle h
-- @tparam integer team
-- @function SetTeamNum

--- Returns the game object's perceived team number (as opposed to its real team number).
-- The perceived team will differ from the real team when a player enters an empty enemy vehicle without being seen until they attack something.
-- @treturn teamnum
-- @tparam handle h
-- @tparam teamnum t
-- @function GetPerceivedTeam

--- Set the game object's perceived team number (as opposed to its real team number).
-- Units on the game object's perceived team will treat it as friendly until it "blows its cover" by attacking, at which point it will revert to its real team.
-- Units on the game object's real team will treat it as friendly regardless of its perceived team.
-- @tparam handle h
-- @tparam teamnum t
-- @function SetPerceivedTeam

-------------------------------------------------------------------------------
-- Target
-------------------------------------------------------------------------------
-- @section
-- These function get and set a unit's target.

--- Sets the local player's target.
-- @tparam handle t
-- @function SetUserTarget

--- Returns the local player's target. Returns nil if it has none.
-- @treturn handle
-- @function GetUserTarget

--- Sets the game object's target.
-- @tparam handle h
-- @tparam handle t
-- @function SetTarget

--- Returns the game object's target. Returns nil if it has none.
-- @treturn handle
-- @tparam handle h
-- @function GetTarget

-------------------------------------------------------------------------------
-- Owner
-------------------------------------------------------------------------------
-- @section
-- These functions get and set owner. The default owner for a game object is the game object that created it.

--- Sets the game object's owner.
-- @tparam handle h
-- @tparam handle o
-- @function SetOwner

--- Returns the game object's owner. Returns nil if it has none.
-- @treturn handle
-- @tparam handle h
-- @function GetOwner

-------------------------------------------------------------------------------
-- Pilot Class
-------------------------------------------------------------------------------
-- @section
-- These functions get and set vehicle pilot class.

--- Sets the vehicle's pilot class to the given odf name. This does nothing useful for non-vehicle game objects. An odf name of nil resets the vehicle to the default assignment based on nation.
-- @tparam handle h
-- @tparam string odfname
-- @function SetPilotClass

--- Returns the odf name of the vehicle's pilot class. Returns nil if none exists.
-- @treturn string
-- @tparam handle h
-- @function GetPilotClass

-------------------------------------------------------------------------------
-- Position and Orientation
-------------------------------------------------------------------------------
-- @section
-- These functions get and set position and orientation.

--- Teleports the game object to a point on the named path. It uses the start of the path if no point is given.
-- @tparam handle h
-- @tparam string path
-- @tparam[opt] integer point
-- @function SetPosition

--- Teleports the game object to the position vector.
-- @tparam handle h
-- @tparam vector position
-- @function SetPosition

--- Teleports the game object to the position of the transform matrix.
-- @tparam handle h
-- @tparam matrix transform
-- @function SetPosition

--- Returns the game object's position vector. Returns nil if none exists.
-- @treturn vector
-- @tparam handle h
-- @function GetPosition

--- Returns the path point's position vector. Returns nil if none exists.
-- @treturn vector
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetPosition

--- Returns the game object's front vector. Returns nil if none exists.
-- @treturn vector
-- @tparam handle h
-- @function GetFront

--- Teleports the game object to the given transform matrix.
-- @tparam handle h
-- @tparam matrix transform
-- @function SetTransform

--- Returns the game object's transform matrix. Returns nil if none exists.
-- @treturn matrix
-- @tparam handle h
-- @function GetTransform

-------------------------------------------------------------------------------
-- Linear Velocity
-------------------------------------------------------------------------------
-- @section
-- These functions get and set linear velocity.

--- Returns the game object's linear velocity vector. Returns nil if none exists.
-- @treturn vector
-- @tparam handle h
-- @function GetVelocity

--- Sets the game object's angular velocity vector. 
-- @tparam handle h
-- @tparam vector velocity
-- @function SetVelocity

-------------------------------------------------------------------------------
-- Angular Velocity
-------------------------------------------------------------------------------
-- @section
-- These functions get and set angular velocity.

--- Returns the game object's angular velocity vector. Returns nil if none exists.
-- @treturn vector
-- @tparam handle h
-- @function GetOmega

--- Sets the game object's angular velocity vector.
-- @tparam handle h
-- @tparam vector omega
-- @function SetOmega

-------------------------------------------------------------------------------
-- Position Helpers
-------------------------------------------------------------------------------
-- @section
-- These functions help generate position values close to a center point.

--- Returns a ground position offset from the center by the radius in a direction controlled by the angle.
-- If no radius is given, it uses a default radius of zero.
-- If no angle is given, it uses a default angle of zero.
-- An angle of zero is +X (due east), pi * 0.5 is +Z (due north), pi is -X (due west), and pi * 1.5 is -Z (due south).
-- @treturn vector
-- @tparam vector center
-- @tparam[opt] number radius
-- @tparam[opt] number angle
-- @function GetCircularPos

--- Returns a ground position in a ring around the center between minradius and maxradius with roughly the same terrain height as the terrain height at the center.
-- This is good for scattering spawn positions around a point while excluding positions that are too high or too low.
-- If no radius is given, it uses the default radius of zero.
-- @treturn vector
-- @tparam vector center
-- @tparam[opt] number minradius
-- @tparam[opt] number maxradius
-- @function GetPositionNear

-------------------------------------------------------------------------------
-- Shot
-------------------------------------------------------------------------------
-- @section
-- These functions query a game object for information about ordnance hits.

--- Returns who scored the most recent hit on the game object. Returns nil if none exists.
-- @treturn handle
-- @tparam handle h
-- @function GetWhoShotMe

--- Returns the last time an enemy shot the game object.
-- @treturn float
-- @tparam handle h
-- @function GetLastEnemyShot

--- Returns the last time a friend shot the game object.
-- @treturn float
-- @tparam handle h
-- @function GetLastFriendShot

-------------------------------------------------------------------------------
-- Alliances
-------------------------------------------------------------------------------
-- @section
-- These functions control and query alliances between teams.
-- The team manager assigns each player a separate team number, starting with 1 and going as high as 15. Team 0 is the neutral "environment" team.
-- Unless specifically overridden, every team is friendly with itself, neutral with team 0, and hostile to everyone else.

--- Sets team alliances back to default.
-- @function DefaultAllies

--- Sets whether team alliances are locked. Locking alliances prevents players from allying or un-allying, preserving alliances set up by the mission script.
-- @tparam boolean lock
-- @function LockAllies

--- Makes the two teams allies of each other.
-- This function affects both teams so Ally(1, 2) and Ally(2, 1) produces the identical results, unlike the "half-allied" state created by the "ally" game key.
-- @tparam integer team1
-- @tparam integer team2
-- @function Ally

--- Makes the two teams enemies of each other.
-- This function affects both teams so UnAlly(1, 2) and UnAlly(2, 1) produces the identical results, unlike the "half-enemy" state created by the "unally" game key.
-- @tparam integer team1
-- @tparam integer team2
-- @function UnAlly

--- Returns true if team1 considers team2 an ally. Returns false otherwise.
-- Due to the possibility of player-initiated "half-alliances", IsTeamAllied(team1, team2) might not return the same result as IsTeamAllied(team2, team1).
-- @treturn boolean
-- @tparam integer team1
-- @tparam integer team2
-- @function IsTeamAllied

--- Returns true if game object "me" considers game object "him" an ally. Returns false otherwise.
-- Due to the possibility of player-initiated "half-alliances", IsAlly(me, him) might not return the same result as IsAlly(him, me).
-- @treturn boolean
-- @tparam handle me
-- @tparam handle him
-- @function IsAlly

-------------------------------------------------------------------------------
-- Objective Marker
-------------------------------------------------------------------------------
-- @section
-- These functions control objective markers.
-- Objectives are visible to all teams from any distance and from any direction, with an arrow pointing to off-screen objectives. There is currently no way to make team-specific objectives.

--- Sets the game object as an objective to all teams.
-- @tparam handle h
-- @function SetObjectiveOn

--- Sets the game object back to normal.
-- @tparam handle h
-- @function SetObjectiveOff

--- Gets the game object's visible name.
-- @treturn string
-- @tparam handle h
-- @function GetObjectiveName

--- Sets the game object's visible name.
-- @tparam handle h
-- @tparam string name
-- @function SetObjectiveName

--- Sets the game object's visible name. This function is effectively an alias for SetObjectiveName.
-- [2.1+]
-- @tparam handle h
-- @tparam string name
-- @function SetName

-------------------------------------------------------------------------------
-- Distance
-------------------------------------------------------------------------------
-- @section
-- These functions measure and return the distance between a game object and a reference point.

--- Returns the distance in meters between the two game objects.
-- @treturn number
-- @tparam handle h1
-- @tparam handle h2
-- @function GetDistance

--- Returns the distance in meters between the game object and a point on the path. It uses the start of the path if no point is given.
-- @treturn number
-- @tparam handle h1
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetDistance

--- Returns the distance in meters between the game object and a position vector.
-- @treturn number
-- @tparam handle h1
-- @tparam vector position
-- @function GetDistance

--- Returns the distance in meters between the game object and the position of a transform matrix.
-- @treturn number
-- @tparam handle h1
-- @tparam matrix transform
-- @function GetDistance

--- Returns true if the units are closer than the given distance of each other. Returns false otherwise.
-- (This function is equivalent to GetDistance (h1, h2) < d)
-- @treturn boolean
-- @tparam handle h1
-- @tparam handle h2
-- @tparam number dist
-- @function IsWithin

--- Returns true if the bounding spheres of the two game objects are within the specified tolerance. The default tolerance is 1.3 meters if not specified.
-- [2.1+]
-- @treturn bool
-- @tparam handle h1
-- @tparam handle h2
-- @tparam[opt] number tolerance
-- @function IsTouching

-------------------------------------------------------------------------------
-- Nearest
-------------------------------------------------------------------------------
-- @section
-- These functions find and return the game object of the requested type closest to a reference point.

--- Returns the game object closest to the given game object. Returns nil if none exists.
-- @treturn handle
-- @tparam handle h
-- @function GetNearestObject

--- Returns the game object closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetNearestObject

--- Returns the game object closest to the position vector. Returns nil if none exists.
-- @treturn handle
-- @tparam vector position
-- @function GetNearestObject

--- Returns the game object closest to the position of the transform matrix. Returns nil if none exists.
-- @treturn handle
-- @tparam matrix transform
-- @function GetNearestObject

--- Returns the craft closest to the given game object. Returns nil if none exists.
-- @treturn handle
-- @tparam handle h
-- @function GetNearestVehicle

--- Returns the craft closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetNearestVehicle

--- Returns the vehicle closest to the position vector. Returns nil if none exists.
-- @treturn handle
-- @tparam vector position
-- @function GetNearestVehicle

--- Returns the vehicle closest to the position of the transform matrix. Returns nil if none exists.
-- @treturn handle
-- @tparam matrix transform
-- @function GetNearestVehicle

--- Returns the building closest to the given game object. Returns nil if none exists.
-- @treturn handle
-- @tparam handle h
-- @function GetNearestBuilding

--- Returns the building closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetNearestBuilding

--- Returns the building closest to the position vector. Returns nil if none exists.
-- @treturn handle
-- @tparam vector position
-- @function GetNearestBuilding

--- Returns the building closest to the position of the transform matrix. Returns nil if none exists.
-- @treturn handle
-- @tparam matrix transform
-- @function GetNearestBuilding

--- Returns the enemy closest to the given game object. Returns nil if none exists.
-- @treturn handle
-- @tparam handle h
-- @function GetNearestEnemy

--- Returns the enemy closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetNearestEnemy

--- Returns the enemy closest to the position vector. Returns nil if none exists.
-- @treturn handle
-- @tparam vector position
-- @function GetNearestEnemy

--- Returns the enemy closest to the position of the transform matrix. Returns nil if none exists.
-- @treturn handle
-- @tparam matrix transform
-- @function GetNearestEnemy

--- Returns the friend closest to the given game object. Returns nil if none exists.
-- [2.0+]
-- @treturn handle
-- @tparam handle h
-- @function GetNearestFriend

--- Returns the friend closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
-- [2.0+]
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetNearestFriend

--- Returns the friend closest to the position vector. Returns nil if none exists.
-- [2.0+]
-- @treturn handle
-- @tparam vector position
-- @function GetNearestFriend

--- Returns the friend closest to the position of the transform matrix. Returns nil if none exists.
-- [2.0+]
-- @treturn handle
-- @tparam matrix transform
-- @function GetNearestFriend

--- Returns the craft or person on the given team closest to the given game object. Returns nil if none exists.
-- [2.0+]
-- @treturn handle
-- @tparam handle h
-- @tparam int team
-- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to a point on the path. It uses the start of the path if no point is given. Returns nil if none exists.
--  [2.1+]
-- @treturn handle
-- @tparam string path
-- @tparam[opt] integer point
-- @tparam int team
-- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to the position of the transform matrix. Returns nil if none exists.
--  [2.1+]
-- @treturn handle
-- @tparam vector position
-- @tparam int team
-- @function GetNearestUnitOnTeam

--- Returns the craft or person on the given team closest to the position vector. Returns nil if none exists.
--  [2.1+]
-- @treturn handle
-- @tparam matrix transform
-- @tparam int team
-- @function GetNearestUnitOnTeam

--- Returns how many objects with the given team and odf name are closer than the given distance.
-- @treturn integer
-- @tparam handle h
-- @tparam number dist
-- @tparam integer team
-- @tparam string odfname
-- @function CountUnitsNearObject

-------------------------------------------------------------------------------
-- Iterators
-------------------------------------------------------------------------------
-- @section
-- These functions return iterator functions for use with Lua's "for <variable> in <expression> do ... end" form. For example: "for h in AllCraft() do print(h, GetLabel(h)) end" will print the game object handle and label of every craft in the world.

--- Enumerates game objects within the given distance of the game object.
-- @treturn iterator
-- @tparam number dist
-- @tparam handle h
-- @function ObjectsInRange

--- Enumerates game objects within the given distance of the path point. It uses the start of the path if no point is given.
-- @treturn iterator
-- @tparam number dist
-- @tparam name path
-- @tparam[opt] integer point
-- @function ObjectsInRange

--- Enumerates game objects within the given distance of the position vector.
-- @treturn iterator
-- @tparam number dist
-- @tparam vector position
-- @function ObjectsInRange

--- Enumerates game objects within the given distance of the transform matrix.
-- @treturn iterator
-- @tparam number dist
-- @tparam matrix transform
-- @function ObjectsInRange

--- Enumerates all game objects.
-- Use this function sparingly at runtime since it enumerates <em>all</em> game objects, including every last piece of scrap. If you're specifically looking for craft, use AllCraft() instead.
-- @treturn iterator
-- @function AllObjects

--- Enumerates all craft.
-- @treturn iterator
-- @function AllCraft

--- Enumerates all game objects currently selected by the local player.
-- @treturn iterator
-- @function SelectedObjects 

--- Enumerates all game objects marked as objectives.
-- @treturn iterator
-- @function ObjectiveObjects

-------------------------------------------------------------------------------
-- Scrap Management
-------------------------------------------------------------------------------
-- @section
-- These functions remove scrap, either to reduce the global game object count or to remove clutter around a location.

--- While the global scrap count is above the limit, remove the oldest scrap piece. It no limit is given, it uses the default limit of 300.
-- @tparam[opt] integer limit
-- @function GetRidOfSomeScrap

--- Clear all scrap within the given distance of a game object.
-- @tparam number distance
-- @tparam handle h
-- @function ClearScrapAround

--- Clear all scrap within the given distance of a point on the path. It uses the start of the path if no point is given.
-- @tparam number distance
-- @tparam string path
-- @tparam[opt] integer point
-- @function ClearScrapAround

--- Clear all scrap within the given distance of a position vector.
-- @tparam number distance
-- @tparam vector position
-- @function ClearScrapAround

--- Clear all scrap within the given distance of the position of a transform matrix.
-- @tparam number distance
-- @tparam matrix transform
-- @function ClearScrapAround

-------------------------------------------------------------------------------
-- Team Slots
-------------------------------------------------------------------------------
-- @section
-- These functions look up game objects in team slots.

--- This is a global table that converts between team slot numbers and team slot names. For example, TeamSlot.PLAYER or TeamSlot["PLAYER"] returns the team slot (0) for the player; TeamSlot[0] returns the team slot name ("PLAYER") for team slot 0. For maintainability, always use this table instead of raw team slot numbers.
-- Available slots: UNDEFINED, PLAYER, RECYCLER, FACTORY, ARMORY, CONSTRUCT,MIN_OFFENSE, MAX_OFFENSE, MIN_DEFENSE, MAX_DEFENSE, MIN_UTILITY, MAX_UTILITY,MIN_BEACON, MAX_BEACON, MIN_POWER, MAX_POWER, MIN_COMM, MAX_COMM, MIN_REPAIR, MAX_REPAIR, MIN_SUPPLY, MAX_SUPPLY, MIN_SILO, MAX_SILO,MIN_BARRACKS, MAX_BARRACKS, MIN_GUNTOWER, MAX_GUNTOWER.
-- Slots starting with MIN_ and MAX_ represent the lower and upper bound of a range of slots.
-- @table TeamSlot

--- Get the game object in the specified team slot.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam integer slot
-- @tparam[opt] integer team
-- @function GetTeamSlot

--- Returns the game object controlled by the player on the given team. Returns nil if none exists.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam[opt] integer team
-- @function GetPlayerHandle

--- Returns the Recycler on the given team. Returns nil if none exists.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam[opt] integer team
-- @function GetRecyclerHandle

--- Returns the Factory on the given team. Returns nil if none exists.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam[opt] integer team
-- @function GetFactoryHandle

--- Returns the Armory on the given team. Returns nil if none exists.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam[opt] integer team
-- @function GetArmoryHandle

--- Returns the Constructor on the given team. Returns nil if none exists.
-- It uses the local player team if no team is given.
-- @treturn handle
-- @tparam[opt] integer team
-- @function GetConstructorHandle

-------------------------------------------------------------------------------
-- Team Pilots
-------------------------------------------------------------------------------
-- @section
-- These functions get and set pilot counts for a team.

--- Adds pilots to the team's pilot count, clamped between zero and maximum count.
-- Returns the new pilot count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function AddPilot

--- Sets the team's pilot count, clamped between zero and maximum count.
-- Returns the new pilot count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function SetPilot

--- Returns the team's pilot count.
-- @treturn integer
-- @tparam integer team
-- @function GetPilot

--- Adds pilots to the team's maximum pilot count.
-- Returns the new pilot count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function AddMaxPilot

--- Sets the team's maximum pilot count.
-- Returns the new pilot count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function SetMaxPilot

--- Returns the team's maximum pilot count.
-- @treturn integer
-- @tparam integer team
-- @function GetMaxPilot

-------------------------------------------------------------------------------
-- Team Scrap
-------------------------------------------------------------------------------
-- @section
-- These functions get and set scrap values for a team.

--- Adds to the team's scrap count, clamped between zero and maximum count.
-- Returns the new scrap count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function AddScrap

--- Sets the team's scrap count, clamped between zero and maximum count.
-- Returns the new scrap count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function SetScrap

--- Returns the team's scrap count.
-- @treturn integer
-- @tparam integer team
-- @function GetScrap

--- Adds to the team's maximum scrap count.
-- Returns the new maximum scrap count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function AddMaxScrap

--- Sets the team's maximum scrap count.
-- Returns the new maximum scrap count.
-- @treturn integer
-- @tparam integer team
-- @tparam integer count
-- @function SetMaxScrap

--- Returns the team's maximum scrap count.
-- @treturn integer
-- @tparam integer team
-- @function GetMaxScrap

-------------------------------------------------------------------------------
-- Deploy
-------------------------------------------------------------------------------
-- @section
-- These functions control deployable craft (such as Turret Tanks or Producer units).

--- Returns true if the game object is a deployed craft. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsDeployed

--- Tells the game object to deploy.
-- @tparam handle h
-- @function Deploy

-------------------------------------------------------------------------------
-- Selection
-------------------------------------------------------------------------------
-- @section
-- These functions access selection state (i.e. whether the player has selected a game object)

--- Returns true if the game object is selected. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsSelected

-------------------------------------------------------------------------------
-- Mission-Critical [2.0+]
-------------------------------------------------------------------------------
-- @section
-- The "mission critical" property indicates that a game object is vital to the success of the mission and disables the "Pick Me Up" and "Recycle" commands that (eventually) cause IsAlive() to report false.

--- Returns true if the game object is marked as mission-critical. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsCritical [2.0+]

--- Sets the game object's mission-critical status.
-- If critical is true or not specified, the object is marked as mission-critical. Otherwise, the object is marked as not mission critical.
-- @tparam handle h
-- @tparam[opt] bool critical
-- @function SetCritical [2.0+]

-------------------------------------------------------------------------------
-- Weapon
-------------------------------------------------------------------------------
-- @section
-- These functions access unit weapons and damage.

--- Sets what weapons the unit's AI process will use.
-- To calculate the mask value, add up the values of the weapon hardpoint slots you want to enable.
-- weaponHard1: 1 weaponHard2: 2 weaponHard3: 4 weaponHard4: 8 weaponHard5: 16
-- @tparam handle h
-- @tparam integer mask
-- @function SetWeaponMask

--- Gives the game object the named weapon in the given slot. If no slot is given, it chooses a slot based on hardpoint type and weapon priority like a weapon powerup would. If the weapon name is empty, nil, or blank and a slot is given, it removes the weapon in that slot.
-- Returns true if it succeeded. Returns false otherwise.
-- @tparam handle h
-- @tparam[opt] string weaponname
-- @tparam[opt] integer slot
-- @function GiveWeapon

--- Returns the odf name of the weapon in the given slot on the game object. Returns nil if the game object does not exist or the slot is empty.
-- For example, an "avtank" game object would return "gatstab" for index 0 and "gminigun" for index 1.
-- @treturn string
-- @tparam handle h
-- @tparam integer slot
-- @function GetWeaponClass

--- Tells the game object to fire at the given target.
-- @tparam handle me
-- @tparam handle him
-- @function FireAt

--- Applies damage to the game object.
-- @tparam handle h
-- @tparam number amount
-- @function Damage

-------------------------------------------------------------------------------
-- Time
-------------------------------------------------------------------------------
-- @section
-- These function report various global time values.

--- Returns the elapsed time in seconds since the start of the mission.
-- @treturn number
-- @function GetTime

--- Returns the simulation time step in seconds.
-- @treturn number
-- @function GetTimeStep

--- Returns the current system time in milliseconds. This is mostly useful for performance profiling.
-- @treturn number
-- @function GetTimeNow

-------------------------------------------------------------------------------
-- Mission
-------------------------------------------------------------------------------
-- @section
-- These functions control general mission properties like strategic AI and mission flow

--- Enables (or disables) strategic AI control for a given team. As of version 1.5.2.7, mission scripts must enable AI control for any team that intends to use an AIP.
-- IMPORTANT SAFETY TIP: only call this function from the "root" of the Lua mission script! The strategic AI gets set up shortly afterward and attempting to use SetAIControl later will crash the game.
-- @tparam integer team
-- @tparam[opt] boolean control
-- @function SetAIControl

--- Returns true if a given team is AI controlled. Returns false otherwise.
-- Unlike SetAIControl, this function may be called at any time.
-- @treturn boolean
-- @tparam integer team
-- @function GetAIControl

--- Returns the current AIP for the team. It uses team 2 if no team number is given.
-- @treturn string
-- @tparam[opt] integer team
-- @function GetAIP 

--- Switches the team's AI plan. It uses team 2 if no team number is given.
-- @tparam string aipname
-- @tparam[opt] integer team
-- @function SetAIP

--- Fails the mission after the given time elapses. If supplied with a filename (usually a .des), it sets the failure message to text from that file.
-- @tparam number time
-- @tparam[opt] string filename
-- @function FailMission

--- Succeeds the mission after the given time elapses. If supplied with a filename (usually a .des), it sets the success message to text from that file.
-- @tparam number time
-- @tparam[opt] string filename
-- @function SucceedMission

-------------------------------------------------------------------------------
-- Objective Messages
-------------------------------------------------------------------------------
-- @section
-- These functions control the objective panel visible at the right of the screen.

--- Clears all objective messages.
-- @function ClearObjectives

--- Adds an objective message with the given name and properties.
-- The message defaults to white if no color is given. The color may be "black", "dkgrey", "grey", "white", "blue", "dkblue", "green", "dkgreen", "yellow", "dkyellow", "red", or "dkred"; the value is case-insensitive.
-- The message lasts 8 seconds if no duration is given.
-- The message text defaults to the contents of of the file with the specified name (usually an .otf).
-- Script-supplied message text is only available in version 2.0.121.1 or higher.
-- @tparam string name
-- @tparam[opt] string color
-- @tparam[opt] number duration
-- @tparam[opt] string text
-- @function AddObjective

--- Updates the objective message with the given name. If no objective exists with that name, it does nothing.
-- The message defaults to white if no color is given. The color may be "black", "dkgrey", "grey", "white", "blue", "dkblue", "green", "dkgreen", "yellow", "dkyellow", "red", or "dkred"; the value is case-insensitive.
-- The message lasts 8 seconds if no duration is given.
-- The message text will keep its previous value if no text is given.
-- Script-supplied message text is only available in version 2.0.121.1 or higher.
-- @tparam string name
-- @tparam[opt] string color
-- @tparam[opt] number duration
-- @tparam[opt] string text
-- @function UpdateObjective

--- Removes the objective message with the given file name. Messages after the removed message will be moved up to fill the vacancy. If no objective exists with that file name, it does nothing.
-- @tparam string name
-- @function RemoveObjective

-------------------------------------------------------------------------------
-- Cockpit Timer
-------------------------------------------------------------------------------
-- @section
-- These functions control the large timer at the top of the screen.

--- Starts the cockpit timer counting down from the given time. If a warn time is given, the timer will turn yellow when it reaches that value. If an alert time is given, the timer will turn red when it reaches that value. All time values are in seconds.
-- The start time can be up to 35999, which will appear on-screen as 9:59:59. If the remaining time is an hour or less, the timer will show only minutes and seconds.
-- @tparam integer time
-- @tparam[opt] integer warn
-- @tparam[opt] integer alert
-- @function StartCockpitTimer

--- Starts the cockpit timer counting up from the given time. If a warn time is given, the timer will turn yellow when it reaches that value. If an alert time is given, the timer will turn red when it reaches that value. All time values are in seconds.
-- The on-screen timer will always show hours, minutes, and seconds The hours digit will malfunction after 10 hours.
-- @tparam integer time
-- @tparam[opt] integer warn
-- @tparam[opt] integer alert
-- @function StartCockpitTimerUp

--- Stops the cockpit timer.
-- @function StopCockpitTimer

--- Hides the cockpit timer.
-- @function HideCockpitTimer

--- Returns the current time in seconds on the cockpit timer.
-- @treturn integer
-- @function GetCockpitTimer

-------------------------------------------------------------------------------
-- Earthquake
-------------------------------------------------------------------------------
-- @section
-- These functions control the global earthquake effect.

--- Starts a global earthquake effect.
-- @tparam number magnitude
-- @function StartEarthquake

--- Changes the magnitude of an existing earthquake effect.
-- Important: note the inconsistent capitalization, which matches the internal C++ script utility functions.
-- @tparam number magnitude
-- @function UpdateEarthQuake

--- Stops the global earthquake effect.
-- @function StopEarthquake

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
-- @tparam string path
-- @tparam integer type
-- @function SetPathType [2.0+]

--- Returns the type of the named path.
-- @treturn integer
-- @tparam string path
-- @function GetPathType [2.0+]

--- Changes the named path to one-way. Once a unit reaches the end of the path, it will stop.
-- @tparam string path
-- @function SetPathOneWay

--- Changes the named path to round-trip. Once a unit reaches the end of the path, it will follow the path backwards to the start and begin again.
-- @tparam string path
-- @function SetPathRoundTrip

--- Changes the named path to looping. Once a unit reaches the end of the path, it will continue along to the start and begin again.
-- @tparam string path
-- @function SetPathLoop

-------------------------------------------------------------------------------
-- Path Points [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Returns the number of points in the named path, or 0 if the path does not exist.
-- [2.0+]
-- @treturn integer
-- @tparam string path
-- @function GetPathPointCount

-------------------------------------------------------------------------------
-- Path Area [2.0+]
-------------------------------------------------------------------------------
-- @section
-- These functions treat a path as the boundary of a closed polygonal area.

--- Returns how many times the named path loops around the given game object.
-- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
-- [2.0+]
-- @treturn integer
-- @tparam string path
-- @tparam handle h
-- @function GetWindingNumber

--- Returns how many times the named path loops around the given position.
-- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
-- [2.0+]
-- @treturn integer
-- @tparam string path
-- @tparam vector position
-- @function GetWindingNumber

--- Returns how many times the named path loops around the position of the given transform.
-- Each full counterclockwise loop adds one and each full clockwise loop subtracts one.
-- [2.0+]
-- @treturn integer
-- @tparam string path
-- @tparam matrix transform
-- @function GetWindingNumber

--- Returns true if the given game object is inside the area bounded by the named path. Returns false otherwise.
-- This function is equivalent to <pre>GetWindingNumber( path, h ) ~= 0</pre>
-- [2.0+]
-- @treturn boolean
-- @tparam string path
-- @tparam handle h
-- @function IsInsideArea

--- Returns true if the given position is inside the area bounded by the named path. Returns false otherwise.
-- This function is equivalent to <pre>GetWindingNumber( path, position ) ~= 0</pre>
-- [2.0+]
-- @treturn boolean
-- @tparam string path
-- @tparam vector position
-- @function IsInsideArea

--- Returns true if the position of the given transform is inside the area bounded by the named path. Returns false otherwise.
-- This function is equivalent to <pre>GetWindingNumber( path, transform ) ~= 0</pre>
-- [2.0+]
-- @treturn boolean
-- @tparam string path
-- @tparam matrix transform
-- @function IsInsideArea

-------------------------------------------------------------------------------
-- Unit Commands
-------------------------------------------------------------------------------
-- @section
-- These functions send commands to units or query their command state.

--- This is a global table that converts between command numbers and command names. For example, AiCommand.GO or AiCommand["GO"] returns the command number (3) for the "go" command; AiCommand[3] returns the command name ("GO") for command number 3. For maintainability, always use this table instead of raw command numbers.
-- Available commands: NONE, SELECT, STOP, GO, ATTACK, FOLLOW, FORMATION, PICKUP, DROPOFF, NO_DROPOFF, GET_REPAIR, GET_RELOAD, GET_WEAPON, GET_CAMERA, GET_BOMB, DEFEND, GO_TO_GEYSER, RESCUE, RECYCLE, SCAVENGE, HUNT, BUILD, PATROL, STAGE, SEND, GET_IN, LAY_MINES, CLOAK [2.1+], DECLOAK [2.1+].
-- @table AiCommand

--- Returns true if the game object can be commanded. Returns false otherwise.
-- @treturn boolean
-- @tparam handle me
-- @function CanCommand

--- Returns true if the game object is a producer that can build at the moment. Returns false otherwise.
-- @treturn boolean
-- @tparam handle me
-- @function CanBuild

--- Returns true if the game object is a producer and currently busy. Returns false otherwise.
-- @treturn boolean
-- @tparam handle me
-- @function IsBusy

--- Returns the current command for the game object. Looking up the command number in the AiCommand table will convert it to a string. Looking up the command string in the AiCommand table will convert it back to a number.
-- @treturn integer
-- @tparam handle me
-- @function GetCurrentCommand

--- Returns the target of the current command for the game object. Returns nil if it has none.
-- @treturn handle
-- @tparam handle me
-- @function GetCurrentWho

--- Gets the independence of a unit.
-- @treturn integer
-- @tparam handle me
-- @function GetIndependence

--- Sets the independence of a unit. 1 (the default) lets the unit take initiative (e.g. attack nearby enemies), while 0 prevents that.
-- @tparam handle me
-- @tparam integer independence
-- @function SetIndependence

--- Commands the unit using the given parameters. Be careful with this since not all commands work with all units and some have strict requirements on their parameters.
-- "Command" is the command to issue, normally chosen from the global AiCommand table (e.g. AiCommand.GO).
-- "Priority" is the command priority; a value of 0 leaves the unit commandable by the player while the default value of 1 makes it uncommandable.
-- "Who" is an optional target game object.
-- "Where" is an optional destination, and can be a matrix (transform), a vector (position), or a string (path name).
-- "When" is an optional absolute time value only used by command AiCommand.STAGE.
-- "Param" is an optional odf name only used by command AiCommand.BUILD.
-- @tparam handle me
-- @tparam integer command
-- @tparam[opt] integer priority
-- @tparam[opt] handle who
-- @tparam[opt] matrix|vector|string where
-- @tparam[opt] number when
-- @tparam[opt] string param
-- @function SetCommand

--- Commands the unit to attack the given target.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Attack

--- Commands the unit to go to the named path.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string path
-- @tparam[opt] integer priority
-- @function Goto

--- Commands the unit to go to the given target
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Goto

--- Commands the unit to go to the given position vector
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam vector position
-- @tparam[opt] integer priority
-- @function Goto

--- Commands the unit to go to the position of the given transform matrix
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam matrix transform
-- @tparam[opt] integer priority
-- @function Goto

--- Commands the unit to lay mines at the named path; only minelayer units support this.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string path
-- @tparam[opt] integer priority
-- @function Mine

--- Commands the unit to lay mines at the given position vector
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam vector position
-- @tparam[opt] integer priority
-- @function Mine

--- Commands the unit to lay mines at the position of the transform matrix
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam matrix transform
-- @tparam[opt] integer priority
-- @function Mine

--- Commands the unit to follow the given target.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Follow

--- Returns true if the unit is currently following the given target.
-- [2.1+]
-- @treturn boolean
-- @tparam handle me
-- @tparam handle him
-- @function IsFollowing

--- Commands the unit to defend its current location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam[opt] integer priority
-- @function Defend

--- Commands the unit to defend the given target.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Defend2

--- Commands the unit to stop at its current location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam[opt] integer priority
-- @function Stop

--- Commands the unit to patrol along the named path. This is equivalent to Goto with an independence of 1.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string path
-- @tparam[opt] integer priority
-- @function Patrol

--- Commands the unit to retreat to the named path. This is equivalent to Goto with an independence of 0.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string path
-- @tparam[opt] integer priority
-- @function Retreat

--- Commands the unit to retreat to the given target. This is equivalent to Goto with an independence of 0.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Retreat

--- Commands the pilot to get into the target vehicle.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function GetIn

--- Commands the unit to pick up the target object. Deployed units pack up (ignoring the target), scavengers pick up scrap, and tugs pick up and carry objects.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Pickup

--- Commands the unit to drop off at the named path. Tugs drop off their cargo and Construction Rigs build the selected item at the location using their current facing.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string path
-- @tparam[opt] integer priority
-- @function Dropoff

--- Commands the unit to drop off at the position vector. Tugs drop off their cargo and Construction Rigs build the selected item at the location using their current facing.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam vector position
-- @tparam[opt] integer priority
-- @function Dropoff

--- Commands the unit to drop off at the position of the transform matrix. Tugs drop off their cargo and Construction Rigs build the selected item with the facing of the transform matrix.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam matrix transform
-- @tparam[opt] integer priority
-- @function Dropoff

--- Commands a producer to build the given odf name. The Armory and Construction Rig need an additional Dropoff to give them a location to build but first need at least one simulation update to process the Build.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string odfname
-- @tparam[opt] integer priority
-- @function Build

--- Commands a producer to build the given odf name at the location of the target game object. A Construction Rig will build at the location and an Armory will launch the item to the location. Other producers will ignore the location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string odfname
-- @tparam handle target
-- @tparam[opt] integer priority
-- @function BuildAt

--- Commands a producer to build the given odf name at the named path. A Construction Rig will build at the location and an Armory will launch the item to the location. Other producers will ignore the location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string odfname
-- @tparam string path
-- @tparam[opt] integer priority
-- @function BuildAt

--- Commands a producer to build the given odf name at the position vector. A Construction Rig will build at the location with their current facing and an Armory will launch the item to the location. Other producers will ignore the location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string odfname
-- @tparam vector position
-- @tparam[opt] integer priority
-- @function BuildAt

--- Commands a producer to build the given odf name at the transform matrix. A Construction Rig will build at the location with the facing of the transform and an Armory will launch the item to the location. Other producers will ignore the location.
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- @tparam handle me
-- @tparam string odfname
-- @tparam matrix transform
-- @tparam[opt] integer priority
-- @function BuildAt

--- Commands the unit to follow the given target closely. This function is equivalent to SetCommand(me, AiCommand.FORMATION, priority, him).
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- [2.1+]
-- @tparam handle me
-- @tparam handle him
-- @tparam[opt] integer priority
-- @function Formation

--- Commands the unit to hunt for targets autonomously. This function is equivalent to SetCommand(me, AiCommand.HUNT, priority).
-- Priority 0 leaves the unit commandable while the default priority 1 makes it uncommandable.
-- [2.1+]
-- @tparam handle me
-- @tparam[opt] integer priority
-- @function Hunt

-------------------------------------------------------------------------------
-- Tug Cargo
-------------------------------------------------------------------------------
-- @section
-- These functions query Tug and Cargo.

--- Returns true if the unit is a tug carrying cargo.
-- @treturn boolean
-- @tparam handle tug
-- @function HasCargo

--- Returns the handle of the cargo if the unit is a tug carrying cargo. Returns nil otherwise.
-- [2.1+]
-- @treturn handle
-- @tparam handle tug
-- @function GetCargo

--- Returns the handle of the tug carrying the object. Returns nil if not carried.
-- @treturn handle
-- @tparam handle cargo
-- @function GetTug

-------------------------------------------------------------------------------
-- Pilot Actions
-------------------------------------------------------------------------------
-- @section
-- These functions control the pilot of a vehicle.

--- Commands the vehicle's pilot to eject.
-- @tparam handle h
-- @function EjectPilot

--- Commands the vehicle's pilot to hop out.
-- @tparam handle h
-- @function HopOut

--- Kills the vehicle's pilot as if sniped.
-- @tparam handle h
-- @function KillPilot

--- Removes the vehicle's pilot cleanly.
-- @tparam handle h
-- @function RemovePilot

--- Returns the vehicle that the pilot most recently hopped out of.
-- @treturn handle
-- @tparam handle h
-- @function HoppedOutOf

-------------------------------------------------------------------------------
-- Health Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set health values on a game object.

--- Returns the fractional health of the game object between 0 and 1.
-- @treturn number
-- @tparam handle h
-- @function GetHealth

--- Returns the current health value of the game object.
-- @treturn number
-- @tparam handle h
-- @function GetCurHealth

--- Returns the maximum health value of the game object.
-- @treturn number
-- @tparam handle h
-- @function GetMaxHealth

--- Sets the current health of the game object.
-- @tparam handle h
-- @tparam number health
-- @function SetCurHealth

--- Sets the maximum health of the game object.
-- @tparam handle h
-- @tparam number health
-- @function SetMaxHealth

--- Adds to the current health of the game object.
-- @tparam handle h
-- @tparam number health
-- @function AddHealth

--- Sets the unit's current health to maximum.
-- [2.1+]
-- @tparam handle h
-- @function GiveMaxHealth

-------------------------------------------------------------------------------
-- Ammo Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set ammo values on a game object.

--- Returns the fractional ammo of the game object between 0 and 1.
-- @treturn number
-- @tparam handle h
-- @function GetAmmo

--- Returns the current ammo value of the game object.
-- @treturn number
-- @tparam handle h
-- @function GetCurAmmo

--- Returns the maximum ammo value of the game object.
-- @treturn number
-- @tparam handle h
-- @function GetMaxAmmo

--- Sets the current ammo of the game object.
-- @tparam handle h
-- @tparam number ammo
-- @function SetCurAmmo

--- Sets the maximum ammo of the game object.
-- @tparam handle h
-- @tparam number ammo
-- @function SetMaxAmmo

--- Adds to the current ammo of the game object.
-- @tparam handle h
-- @tparam number ammo
-- @function AddAmmo

--- Sets the unit's current ammo to maximum.
-- [2.1+]
-- @tparam handle h
-- @function GiveMaxAmmo

-------------------------------------------------------------------------------
-- Cinematic Camera
-------------------------------------------------------------------------------
-- These functions control the cinematic camera for in-engine cut scenes (or "cineractives" as the Interstate '76 team at Activision called them).
-- @section

--- Starts the cinematic camera and disables normal input.
-- Always returns true.
-- @treturn boolean
-- @function CameraReady

--- Moves a cinematic camera along a path at a given height and speed while looking at a target game object.
-- Returns true when the camera arrives at its destination. Returns false otherwise.
-- @treturn boolean
-- @tparam string path
-- @tparam integer height
-- @tparam integer speed
-- @tparam handle target
-- @function CameraPath

--- Moves a cinematic camera long a path at a given height and speed while looking along the path direction.
-- Returns true when the camera arrives at its destination. Returns false otherwise.
-- @treturn boolean
-- @tparam string path
-- @tparam integer height
-- @tparam integer speed
-- @function CameraPathDir

--- Returns true when the camera arrives at its destination. Returns false otherwise.
-- @treturn boolean
-- @function PanDone

--- Offsets a cinematic camera from a base game object while looking at a target game object. The right, up, and forward offsets are in centimeters.
-- Returns true if the base or handle game object does not exist. Returns false otherwise.
-- @treturn boolean
-- @tparam handle base
-- @tparam integer right
-- @tparam integer up
-- @tparam integer forward
-- @tparam handle target
-- @function CameraObject

--- Finishes the cinematic camera and enables normal input.
-- Always returns true.
-- @treturn boolean
-- @function CameraFinish

--- Returns true if the player canceled the cinematic. Returns false otherwise.
-- @treturn boolean
-- @function CameraCancelled

-------------------------------------------------------------------------------
-- Info Display
-------------------------------------------------------------------------------
-- @section

--- Returns true if the game object inspected by the info display matches the given odf name.
-- @treturn boolean
-- @tparam string odfname
-- @function IsInfo

-------------------------------------------------------------------------------
-- Network
-------------------------------------------------------------------------------
-- @section
-- LuaMission currently has limited network support, but can detect if the mission is being run in multiplayer and if the local machine is hosting.

--- Returns true if the game is a network game. Returns false otherwise.
-- @treturn boolean
-- @function IsNetGame

--- Returns true if the local machine is hosting a network game. Returns false otherwise.
-- @treturn boolean
-- @function IsHosting

--- Sets the game object as local to the machine the script is running on, transferring ownership from its original owner if it was remote. Important safety tip: only call this on one machine at a time!
-- @tparam handle h
-- @function SetLocal

--- Returns true if the game is local to the machine the script is running on. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsLocal

--- Returns true if the game object is remote to the machine the script is running on. Returns false otherwise.
-- @treturn boolean
-- @tparam handle h
-- @function IsRemote

--- Adds a system text message to the chat window on the local machine.
-- @tparam string message
-- @function DisplayMessage

--- Send a script-defined message across the network.
-- To is the player network id of the recipient. None, nil, or 0 broadcasts to all players.
-- Type is a one-character string indicating the script-defined message type.
-- Other parameters will be sent as data and passed to the recipient's Receive function as parameters. Send supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
-- The sent packet can contain up to 244 bytes of data (255 bytes maximum for an Anet packet minus 6 bytes for the packet header and 5 bytes for the reliable transmission header)
-- <table><tbody>
--   <tr><th colspan="2">Type</th><th>Bytes</th></tr>
--   <tr><td colspan="2">nil</td><td>1</td></tr>
--   <tr><td colspan="2">boolean</td><td>1</td></tr>
--   <tr><td rowspan="2">handle</td><td>invalid (zero)</td><td>1</td></tr>
--   <tr><td>valid (nonzero)</td><td>1 + sizeof(int) = 5</td></tr>
--   <tr><td rowspan="5">number</td><td>zero</td><td>1</td></tr>
--   <tr><td>char (integer -128 to 127)</td><td>1 + sizeof(char) = 2</td></tr>
--   <tr><td>short (integer -32768 to 32767)</td><td>1 + sizeof(short) = 3</td></tr>
--   <tr><td>int (integer)</td><td>1 + sizeof(int) = 5</td></tr>
--   <tr><td>double (non-integer)</td><td>1 + sizeof(double) = 9</td></tr>
--   <tr><td rowspan="2">string</td><td>length &lt; 31</td><td>1 + length</td></tr>
--   <tr><td>length &gt;= 31</td><td>2 + length</td></tr>
--   <tr><td rowspan="2">table</td><td>count &lt; 31</td><td>1 + count + size of keys and values</td></tr>
--   <tr><td>count &gt;= 31</td><td>2 + count + size of keys and values</td></tr>
--   <tr><td rowspan="2">userdata</td><td>VECTOR_3D</td><td>1 + sizeof(VECTOR_3D) = 13</td></tr>
--   <tr><td>MAT_3D</td><td>1 + sizeof(REDUCED_MAT) = 12</td></tr>
-- </tbody></table>
-- @tparam integer to
-- @tparam string type
-- @param ...
-- @function Send

-------------------------------------------------------------------------------
-- Read ODF
-------------------------------------------------------------------------------
-- @section
-- These functions read values from an external ODF, INI, or TRN file.

--- Opens the named file as an ODF. If the file name has no extension, the function will append ".odf" automatically.
-- If the file is not already open, the function reads in and parses the file into an internal database. If you need to read values from it relatively frequently, save the handle into a global variable to prevent it from closing.
-- Returns the file handle if it succeeded. Returns nil if it failed.
-- @treturn odfhandle
-- @tparam string filename
-- @function OpenODF

--- Reads a boolean value from the named label in the named section of the ODF file. Use a nil section to read labels that aren't in a section.
-- It considers values starting with 'Y', 'y', 'T', 't', or '1' to be true and value starting with 'N', 'n', 'F', 'f', or '0' to be false. Other values are considered undefined.
-- If a value is not found or is undefined, it uses the default value. If no default value is given, the default value is false. 
-- Returns the value and whether the value was found.
-- @treturn boolean
-- @treturn boolean
-- @tparam odfhandle odf
-- @tparam[opt] string section
-- @tparam string label
-- @tparam[opt] string default
-- @function GetODFBool

--- Reads an integer value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section. 
-- If no value is found, it uses the default value. If no default value is given, the default value is 0. 
-- Returns the value and whether the value was found.
-- @treturn integer
-- @treturn boolean
-- @tparam odfhandle odf
-- @tparam[opt] string section
-- @tparam string label
-- @tparam[opt] string default
-- @function GetODFInt

--- Reads a floating-point value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section.
-- If no value is found, it uses the default value. If no default value is given, the default value is 0.0.
-- Returns the value and whether the value was found.
-- @treturn number
-- @treturn boolean
-- @tparam odfhandle odf
-- @tparam[opt] string section
-- @tparam string label
-- @tparam[opt] string default
-- @function GetODFFloat

--- Reads a string value from the named label in the named section of the ODF file. Use nil as the section to read labels that aren't in a section.
-- If a value is not found, it uses the default value. If no default value is given, the default value is nil.
-- Returns the value and whether the value was found.
-- @treturn string
-- @treturn boolean
-- @tparam odfhandle odf
-- @tparam[opt] string section
-- @tparam string label
-- @tparam[opt] string default
-- @function GetODFString

-------------------------------------------------------------------------------
-- Terrain
-------------------------------------------------------------------------------
-- @section
-- These functions return height and normal from the terrain height field.

--- Returns the terrain height and normal vector at the location of the game object.
-- @treturn number
-- @treturn vector
-- @tparam handle h
-- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at a point on the named path. It uses the start of the path if no point is given.
-- @treturn number
-- @treturn vector
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at the position vector.
-- @treturn number
-- @treturn vector
-- @tparam vector position
-- @function GetTerrainHeightAndNormal

--- Returns the terrain height and normal vector at the position of the transform matrix.
-- @treturn number
-- @treturn vector
-- @tparam matrix transform
-- @function GetTerrainHeightAndNormal

-------------------------------------------------------------------------------
-- Floor
-------------------------------------------------------------------------------
-- These functions return height and normal from the terrain height field and the upward-facing polygons of any entities marked as floor owners.
-- @section

--- Returns the floor height and normal vector at the location of the game object.
-- @treturn number
-- @treturn vector
-- @tparam handle h
-- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at a point on the named path. It uses the start of the path if no point is given.
-- @treturn number
-- @treturn vector
-- @tparam string path
-- @tparam[opt] integer point
-- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at the position vector.
-- @treturn number
-- @treturn vector
-- @tparam vector position
-- @function GetFloorHeightAndNormal

--- Returns the floor height and normal vector at the position of the transform matrix.
-- @treturn number
-- @treturn vector
-- @tparam matrix transform
-- @function GetFloorHeightAndNormal

-------------------------------------------------------------------------------
-- Map
-------------------------------------------------------------------------------
-- @section

--- Returns the name of the BZN file for the map. This can be used to generate an ODF name for mission settings.
-- [2.0+]
-- @treturn string
-- @function GetMissionFilename

--- Returns the name of the TRN file for the map. This can be used with OpenODF() to read values from the TRN file.
-- @treturn string
-- @function GetMapTRNFilename

-------------------------------------------------------------------------------
-- Files [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Returns the contents of the named file as a string, or nil if the file could not be opened.
-- [2.0+]
-- @tparam string filename
-- @function string UseItem

-------------------------------------------------------------------------------
-- Effects [2.0+]
-------------------------------------------------------------------------------
-- @section

--- Starts a full screen color fade.
-- Ratio sets the opacity, with 0.0 transparent and 1.0 almost opaque
-- Rate sets how fast the opacity decreases over time.
-- R, G, and B set the color components and range from 0 to 255
-- [2.0+]
-- @tparam number ratio
-- @tparam number rate
-- @tparam integer r
-- @tparam integer g
-- @tparam integer b
-- @function ColorFade

-------------------------------------------------------------------------------
-- Vector
-------------------------------------------------------------------------------
-- @section
-- This is a custom userdata representing a position or direction. It has three number components: x, y, and z.

--- Returns a vector whose components have the given number values. If no value is given for a component, the default value is 0.0.
-- @treturn vector
-- @tparam[opt] number x
-- @tparam[opt] number y
-- @tparam[opt] number z
-- @function SetVector

--- Returns the <a href="http://en.wikipedia.org/wiki/Dot_product">dot product</a> between vectors a and b.
-- Equivalent to a.x * b.x + a.y * b.y + a.z * b.z.
-- @treturn number
-- @tparam vector a
-- @tparam vector a
-- @function DotProduct

--- Returns the <a href="http://en.wikipedia.org/wiki/Cross_product">cross product</a> between vectors a and b.
-- Equivalent to SetVector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x).
-- @treturn vector
-- @tparam vector a
-- @tparam vector b
-- @function CrossProduct

--- Returns the vector scaled to unit length.
-- Equivalent to SetVector(v.x * scale, v.y * scale, v.z * scale) where scale is 1.0f / sqrt(v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>).
-- @treturn vector
-- @tparam vector v
-- @function Normalize

--- Returns the length of the vector.
-- Equivalent to sqrt(v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>).
-- @treturn number
-- @tparam vector v
-- @function Length

--- Returns the squared length of the vector.
-- Equivalent to v.x<sup>2</sup> + v.y<sup>2</sup> + v.z<sup>2</sup>.
-- @treturn number
-- @tparam vector v
-- @function LengthSquared

--- Returns the 2D distance between vectors a and b.
-- Equivalent to sqrt((b.x - a.x)<sup>2</sup> + (b.z - a.z)<sup>2</sup>).
-- @treturn number
-- @tparam vector a
-- @tparam vector b
-- @function Distance2D

--- Returns the squared 2D distance of the vector.
-- Equivalent to (b.x - a.x)<sup>2</sup> + (b.z - a.z)<sup>2</sup>.
-- @treturn number
-- @tparam vector a
-- @tparam vector b
-- @function Distance2DSquared

--- Returns the 3D distance between vectors a and b.
-- Equivalent to sqrt((b.x - a.x)<sup>2</sup> + (b.y - a.y)<sup>2</sup> + (b.z - a.z)<sup>2</sup>).
-- @treturn number
-- @tparam vector a
-- @tparam vector b
-- @function Distance3D

--- Returns the squared 3D distance of the vector.
-- Equivalent to (b.x - a.x)<sup>2</sup> + (b.y - a.y)<sup>2</sup> + (b.z - a.z)<sup>2</sup>.
-- @treturn number
-- @tparam vector a
-- @tparam vector b
-- @function Distance3DSquared

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
-- @treturn matrix
-- @tparam[opt] number right_x
-- @tparam[opt] number right_y
-- @tparam[opt] number right_z
-- @tparam[opt] number up_x
-- @tparam[opt] number up_y
-- @tparam[opt] number up_z
-- @tparam[opt] number front_x
-- @tparam[opt] number front_y
-- @tparam[opt] number front_z
-- @tparam[opt] number posit_x
-- @tparam[opt] number posit_y
-- @tparam[opt] number posit_z
-- @function SetMatrix

--- Global value representing the identity matrix.
-- Equivalent to SetMatrix(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0).
-- @function matrix IdentityMatrix

--- Build a matrix representing a rotation by an angle around an axis. The angle is in radians. If no value is given for the angle or an axis component, the default value is zero. The axis must be unit-length (i.e. axis_x<sup>2</sup> + axis_y<sup>2</sup> + axis_z<sup>2</sup> = 1.0 or the resulting matrix will be wrong.
-- @treturn matrix
-- @tparam[opt] number angle
-- @tparam[opt] number axis_x
-- @tparam[opt] number axis_y
-- @tparam[opt] number axis_z
-- @function BuildAxisRotationMatrix

--- Build a matrix representing a rotation by an angle around an axis. The angle is in radians. If no value is given for the angle, the default value is zero. The axis must be unit-length (i.e. axis.x<sup>2</sup> + axis.y<sup>2</sup> + axis.z<sup>2</sup> = 1.0 or the resulting matrix will be wrong.
-- @treturn matrix
-- @tparam[opt] number angle
-- @tparam vector axis
-- @function BuildAxisRotationMatrix

--- Build a matrix with the given pitch, yaw, and roll angles and position. The angles are in radians. If no value is given for a component, the default value is zero.
-- @treturn matrix
-- @tparam[opt] number pitch
-- @tparam[opt] number yaw
-- @tparam[opt] number roll
-- @tparam[opt] number posit_x
-- @tparam[opt] number posit_y
-- @tparam[opt] number posit_z
-- @function BuildPositionRotationMatrix

--- Build a matrix with the given pitch, yaw, and roll angles and position. The angles are in radians. If no value is given for a component, the default value is zero.
-- @treturn matrix
-- @tparam[opt] number pitch
-- @tparam[opt] number yaw
-- @tparam[opt] number roll
-- @tparam vector position
-- @function BuildPositionRotationMatrix

--- Build a matrix with zero position, its up axis along the specified up vector, oriented so that its front axis points as close as possible to the heading vector. If up is not specified, the default value is the Y axis. If heading is not specified, the default value is the Z axis.
-- @treturn matrix
-- @tparam[opt] vector up
-- @tparam[opt] vector heading
-- @function BuildOrthogonalMatrix

--- Build a matrix with the given position vector, its front axis pointing along the direction vector, and zero roll. If position is not specified, the default value is a zero vector. If direction is not specified, the default value is the Z axis.
-- @treturn matrix
-- @tparam[opt] vector position
-- @tparam[opt] vector direction
-- @function BuildDirectionalMatrix

--- Multiply two matrices.
-- @tparam matrix matrix1
-- @tparam matrix matrix2
-- @function matrix:mul

--- Transform a vector by a matrix.
-- @tparam matrix matrix
-- @tparam vector vector
-- @function matrix:mul

-------------------------------------------------------------------------------
-- Portal Functions [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions control the Portal building introduced in The Red Odyssey expansion.

--- Sets the specified Portal direction to "out", indicated by a blue visual effect while active.
-- [2.1+]
-- @tparam handle portal
-- @function PortalOut

--- Sets the specified Portal direction to "in", indicated by an orange visual effect while active.
-- [2.1+]
-- @tparam handle portal
-- @function PortalIn

--- Deactivates the specified Portal, stopping the visual effect.
-- [2.1+]
-- @tparam handle portal
-- @function DeactivatePortal

--- Activates the specified Portal, starting the visual effect.
-- [2.1+]
-- @tparam handle portal
-- @function ActivatePortal

--- Returns true if the specified Portal direction is "in". Returns false otherwise.
-- [2.1+]
-- @treturn bool
-- @tparam handle portal
-- @function IsIn

--- Returns true if the specified Portal is active. Returns false otherwise.
-- Important: note the capitalization!
-- [2.1+]
-- @treturn bool
-- @tparam handle portal
-- @function isPortalActive

--- Creates a game object with the given odf name and team number at the location of a portal.
-- The object is created at the location of the visual effect and given a 50 m/s initial velocity.
-- [2.1+]
-- @treturn handle
-- @tparam string odfname
-- @tparam integer teamnum
-- @tparam handle portal
-- @function BuildObjectAtPortal

-------------------------------------------------------------------------------
-- Cloak [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions control the cloaking state of craft capable of cloaking.

--- Makes the specified unit cloak if it can.
-- Note: unlike SetCommand(h, AiCommand.CLOAK), this does not change the unit's current command.
-- [2.1+]
-- @tparam handle h
-- @function Cloak

--- Makes the specified unit de-cloak if it can.
-- Note: unlike SetCommand(h, AiCommand.DECLOAK), this does not change the unit's current command.
-- [2.1+]
-- @tparam handle h
-- @function Decloak

--- Instantly sets the unit as cloaked (with no fade out).
-- [2.1+]
-- @tparam handle h
-- @function SetCloaked

--- Instant sets the unit as uncloaked (with no fade in).
-- [2.1+]
-- @tparam handle h
-- @function SetDecloaked

--- Returns true if the unit is cloaked. Returns false otherwise
-- [2.1+]
-- @treturn bool
-- @tparam handle h
-- @function IsCloaked

--- Enable or disable cloaking for a specified cloaking-capable unit.
-- Note: this does not grant a non-cloaking-capable unit the ability to cloak.
-- [2.1+]
-- @tparam handle h
-- @tparam bool enable
-- @function EnableCloaking

--- Enable or disable cloaking for all cloaking-capable units.
-- Note: this does not grant a non-cloaking-capable unit the ability to cloak.
-- [2.1+]
-- @tparam bool enable
-- @function EnableAllCloaking

-------------------------------------------------------------------------------
-- Hide [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions hide and show game objects. When hidden, the object is invisible (similar to Phantom VIR and cloak) and undetectable on radar (similar to RED Field and cloak). The effect is similar to but separate from cloaking. For the most part, AI units ignore the hidden state.

--- Hides a game object.
-- [2.1+]
-- @tparam handle h
-- @function Hide

--- Un-hides a game object.
-- [2.1+]
-- @tparam handle h
-- @function UnHide

-------------------------------------------------------------------------------
-- Explosion [2.1+]
-------------------------------------------------------------------------------
-- @section
-- These functions create explosions at a specified location. They do not return a handle because explosions are not game objects and thus not visible to the scripting system.

--- Creates an explosion with the given odf name at the location of a game object.
-- [2.1+]
-- @tparam string odfname
-- @tparam handle h
-- @function MakeExplosion

--- Creates an explosion with the given odf name at the start of the named path.
-- [2.1+]
-- @tparam string odfname
-- @tparam string path
-- @function MakeExplosion

--- Creates an explosion with the given odf name at the given position vector.
-- [2.1+]
-- @tparam string odfname
-- @tparam vector position
-- @function MakeExplosion

--- Creates an explosion with the given odf name with the given transform matrix.
-- [2.1+]
-- @tparam string odfname
-- @tparam matrix transform
-- @function MakeExplosion
