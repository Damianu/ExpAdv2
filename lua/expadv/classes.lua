/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Create base class
   --- */

EXPADV.BaseClassObj = { }

EXPADV.BaseClassObj.__index = EXPADV.BaseClassObj 

local BaseClassObj = EXPADV.BaseClassObj

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Basic Support
   --- */

-- Builds a VM operator, to return the default zero value object of a class.
function BaseClassObj:DefaultAsLua( Default ) -- Object / function( table Trace, table Context )
	if istable( Default ) then
		Default = function( ) return table.Copy( Default ) end
	elseif !isfunction( Default ) then
		Default = function( ) return Default end
	end

	self.CreateNew = Default
end

-- Derives this class as well as its operators and methods from another class.
function BaseClassObj:ExtendClass( ExtendClass ) -- String
	self.DeriveFrom = ExtendClass
end

local Temp_Aliases = { }

-- Allows more convenient names to be used when defining class type in expadv2 script.
function BaseClassObj:AddAlias( Alias ) -- String
	Temp_Aliases[ Alias ] = self
end

-- Use this to define a tostring method for your class, this takes the natives context into account.
function BaseClassObj:StringBuilder( Function ) -- function( table Context, obj Value )
	self.ToString = Function
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then

	local function WireOut( Context, MemoryRef ) return Context.Memory[ MemoryRef ] end

	-- Defines the wire outport type name of your class.
	-- Optonally define a method to translate native type in memory to wire type.
	function BaseClassObj:WireOutput( WireType, Function ) -- String, function( table Context, number MemoryRef )
		self.Wire_Out_Type = string.upper( WireType )

		self.Wire_Out_Util = Function or WireOut
	end

	local function WireIn( Context, MemoryRef, InValue ) Context.Memory[ MemoryRef ] = InValue end

	-- Defines the wire inport type name of your class.
	-- Optonally define a method to translate wire type to native type and store in memory.
	function BaseClassObj:WireInput( WireType, Function ) -- function( table Context, number MemoryRef, obj Value )
		self.Wire_In_Type = string.upper( WireType )
		
		self.Wire_In_Util = Function or WireIn
	end

end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Seralization Support
   --- */

require( "von" )

if von then
	-- Not yet supported, please do not use this method.
	function BaseClassObj:Serialize( Function ) -- function( table Context, obj Value )
		self.SerializeAsString = Function
	end

	-- Not yet supported, please do not use this method.
	function BaseClassObj:Deserialize( Function ) -- function( table Context, String seralized )
		self.DeserializeFromString = Function
	end

	-- Not yet supported, please do not use this method.
	function EXPADV.Serialize( Context, Short, Obj ) -- Table, String, Obj
		-- Assigned: Vercas
		-- Todo: return seralized

		--	This is an initial attempt to check behaviour.
		return von.serialize({Short, Obj})
	end

	-- Not yet supported, please do not use this method.
	function EXPADV.Deserialize( Context, Seralized ) -- Table, String
		-- Assigned: Vercas
		-- Todo: return Short, Obj

		local res = von.deserialize(serialized)

		return res[2], res[1]
	end

end
/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Server -> Client Support
   --- */

EXPADV.BaseClassObj.LoadOnServer = true

EXPADV.BaseClassObj.LoadOnClient = true

-- Defines the class as server side only.
function BaseClassObj:MakeServerOnly( )
	self.LoadOnClient = false
end

-- Defines the class as cleint side only.
function BaseClassObj:MakeClientOnly( )
	self.LoadOnServer = false
end

-- Not yet supported, please do not use this method.
function BaseClassObj:NetSend( Function ) -- function( obj Value )
	self.SendToClient = Function
end

-- Not yet supported, please do not use this method.
function BaseClassObj:NetReceive( Function ) -- function( obj Value )
	self.ReceiveFromServer = Function
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Class framework
   --- */

local Temp_Classes = { }

-- Define and create a new class, this returns the classes module.
-- This function is for internal use only, use BaseComponent:AddClass( ... )
function EXPADV.AddClass( Component, Name, Short ) -- table, string, string
	if #Short > 1 then Short = "_" .. Short end

	local Class = setmetatable( { Component = Component, Name = Name, Short = Short, DeriveFrom = "generic" }, EXPADV.BaseClassObj )

	Temp_Classes[ #Temp_Classes + 1 ] = Class

	return Class
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Define generic Class
   --- */

local Class_Generic = setmetatable( { Name = "generic", Short = "g" }, EXPADV.BaseClassObj )
	-- We do this manually, so it doesnt get treated like the rest!

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Define Null Class
   --- */

   -- TODO

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Define boolean class
   --- */

local Class_Boolean = EXPADV.AddClass( nil, "boolean", "b" )
	  
	  Class_Boolean:AddAlias( "bool" )

	  Class_Boolean:DefaultAsLua( false )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Register variant class!
   --- */

local Class_Variant = EXPADV.AddClass( nil, "variant", "vr" )
		
	  Class_Variant:DefaultAsLua( { false, "b" } )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Register exception class!
   --- */

local Class_Exception = EXPADV.AddClass( nil, "exception", "ex" )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: GetClass
   --- */

-- Returns a classes module, using either name or id as look up.
function EXPADV.GetClass( Name ) -- String
	if !Name then return end

	if EXPADV.Classes[ Name ] then return EXPADV.Classes[ Name ] end

	if EXPADV.ClassAliases[ Name ] then return EXPADV.ClassAliases[ Name ] end

	if #Name > 1 and Name[1] ~= "_" then Name = "_" .. Name end

	if EXPADV.ClassShorts[ Name ] then return EXPADV.ClassShorts[ Name ] end
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Print Lookup!
   --- */

local ToStringLookUp = { }

-- Used during execution to translate class objects to strings.
function EXPADV.ToString( Context, Short, Obj ) -- Table, String, Obj
	return ToStringLookUp[Short]( Context, Obj )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Load classes!
   --- */

-- Internal function, not for public use.
function EXPADV.LoadClasses( )
 	EXPADV.ClassAliases = { }

 	EXPADV.Classes = { generic = Class_Generic }

 	EXPADV.ClassShorts = { g = Class_Generic }

 	EXPADV.CallHook( "PreLoadClasses" )

 	for I = 1, #Temp_Classes do
 		local Class = Temp_Classes[I]

 		if Class.Component and !Class.Component.Enabled then
 			MsgN( "Skipping class " .. Class.Name .. " (component disabled)." )
 			continue
 		end

 		EXPADV.Classes[ Class.Name ] = Class

 		EXPADV.ClassShorts[ Class.Short ] = Class
 	end

 	----------------------------------------------------------

 	for _, Class in pairs( EXPADV.Classes ) do
 		if Class == Class_Generic then continue end

 		local DeriveClass = EXPADV.GetClass( Class.DeriveFrom )

 		if !DeriveClass then
 			EXPADV.Classes[ Class.Name ] = nil

 			EXPADV.ClassShorts[ Class.Short ] = nil

 			MsgN( "Skipping class " .. Class.Name .. " (extends invalid class '" .. (Class.DeriveFrom or "void") .. "')." )
 			
 			continue
 		end

 		Class.DerivedClass = DeriveClass

 		Class.DeriveGeneric = DeriveClass == Class_Generic

 		EXPADV.ClassAliases[ Class.Name ] = Class

 		MsgN( "Registered Class: " .. Class.Name .. " - " .. Class.Short )
 	end -- ^ Derive classes!

 	----------------------------------------------------------

 	for _, Class in pairs( EXPADV.Classes ) do

 		local DeriveClass = Class.DerivedClass

 		if DeriveClass and !Class.CreateNew then
	 		Class.CreateNew = DeriveClass.CreateNew
	 	end

		if Class.CreateNew then
 			EXPADV.AddVMOperator( Class.Component, "default", Class.Short , Class.Short, Class.CreateNew )
 		end

 		if DeriveClass and !Class.DeriveGeneric and !Class.ToString then
	 		Class.ToString = DeriveClass.ToString
	 	end

	 	if !Class.ToString then
	 		function Class.ToString( Context, Trace, Obj )
 				return string.format("<%s: %s>", Class.Name, tostring( Obj ) )
 			end
 		end

 		ToStringLookUp[Class.Short] = Class.ToString
 		EXPADV.AddVMFunction( Class.Component, "tostring", Class.Short , "s", Class.ToString )

 		if Class.DeriveGeneric then continue end
 		if Class == Class_Generic then continue end
 		
 		Class.LoadOnServer = DeriveClass.LoadOnServer

		Class.LoadOnClient = DeriveClass.LoadOnClient

 		if WireLib then

 			if !Class.Wire_Out_Type then
 				Class.Wire_Out_Type = DeriveClass.Wire_Out_Type

 				Class.Wire_Out_Util = DeriveClass.Wire_Out_Util
 			end

 			if !Class.Wire_In_Type then
 				Class.Wire_In_Type = DeriveClass.Wire_In_Type

 				Class.Wire_In_Util = DeriveClass.Wire_In_Util
 			end

 		end

		if !Class.SerializeAsString then
			Class.SerializeAsString = DeriveClass.SerializeAsString
		end

		if !Class.DeserializeFromString then
			Class.DeserializeFromString = DeriveClass.DeserializeFromString
		end

		-- TODO: Extend net usage?

 	end

 	for Name, Class in pairs( EXPADV.Classes ) do
 		EXPADV.CallHook( "RegisterClass", Name, Class )
 	end

 	EXPADV.CallHook( "PostLoadClasses" )

 	for Alias, Class in pairs( EXPADV.ClassAliases ) do
 		
 		if Class.Component and !Class.Component.Enabled then
 			EXPADV.ClassAliases[Alias] = nil
 		end

 	end

 	EXPADV.CallHook( "PostLoadClassAliases" )
end