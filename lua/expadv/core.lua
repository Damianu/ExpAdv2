/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Create the Expression Advanced Namespace.
   --- */

EXPADV = { }

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Sometimes We might need to convert objects into native.
   --- */

local Cache, ToLua, ToLuaTable = { }

EXPADV.__Cache = Cache

function ToLua( Value, bNoTables )
	if !Value then return "nil" end
	
	local Type = type(Value)
	
	if Type == "number" then
		return Value
	elseif Type == "string" then
		return string.format( "%q", Value )
	elseif Type == "boolean" then
		return Value and "true" or "false"
	elseif Type == "table" and !bNoTables then
		return ToLuaTable( Value )
	elseif Type == "function" and !NoTables then
		local Index = #Cache + 1
		Cache[Index] = Value
		return "EXPADV.__Cache[" .. Index .. "]"
	end
end

EXPADV.ToLua = ToLua

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: We need config files.
   --- */

function ToLuaTable( Table )
	local Lua = "{"
	
	for Key, Value in pairs(Table) do
		local kLua = ToLua( Key, true )
		local vLua = ToLua( Value )
		
		if !kLua then
			error("TableToLua invalid Key of type " .. type(Key))
		elseif !vLua then
			error("TableToLua invalid Value of type " .. type(Value))
		end
		
		Lua = string.format( "%s[%s] = %s, ", Lua, kLua, vLua )
		
		--Lua .. "[" .. kLua .. "] = " .. vLua .. ", ")
	end
	
	return Lua .. "}"
end

EXPADV.ToLuaTable = ToLuaTable

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: We need config files.
   --- */

EXPADV.Config = { }

function EXPADV.LoadConfig( )
	local Config = { }

	if file.Exists( "expadv.txt", "DATA" ) then
		Config = util.KeyValuesToTable( file.Read( "expadv.txt", "DATA" ) )
	end
	
	Config.EnabledComponents = Config.EnabledComponents or { }

	Config.Components = Config.Components or { }

	Config.Settings = Config.Settings or { }

	MsgN( "ExpAdv: Loaded config file, sucessfully." )

	EXPADV.Config = Config
end

-- Saves the config file.
function EXPADV.SaveConfig( )
	-- EXPADV.RunHook( "PreSaveConfig", EXPADV.Config )

	file.Write( "expadv.txt", util.TableToKeyValues( EXPADV.Config ) )
end

-- Creates a new setting on the config.
function EXPADV.CreateSetting( Name, Default ) -- String, Obj
	Name = string.lower( Name )

	EXPADV.Config.Settings[ Name ] = Config.Settings[ Name ] or Default
end

-- Reads a setting from the config.
function EXPADV.ReadSetting( Name, Default ) -- String, Obj
	return EXPADV.Config.Settings[ string.lower( Name ) ] or Default
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Exceptions
   --- */

local Temp_Exceptions = { }

-- Registers a new exception type.
function EXPADV.AddException( Component, Exception ) -- Table, String
	Temp_Exceptions[ #Temp_Exceptions + 1 ] = { Component = Component, Exception = Exception }
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: We have files to load, lets load them.
   --- */

function EXPADV.IncludeCore( )
	include( "expadv/components.lua" )
	include( "expadv/classes.lua" )
	include( "expadv/operators.lua" )
	include( "expadv/events.lua" )
	include( "expadv/context.lua" )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Lets loads the core.
   --- */

if SERVER then util.AddNetworkString( "expadv.config" ) end

function EXPADV.LoadCore( )
	EXPADV.LoadConfig( )

	EXPADV.IncludeCore( )

	include( "expadv/components/core.lua" )
	include( "expadv/components/number.lua" )
	include( "expadv/components/string.lua" )

	EXPADV.LoadComponents( )

	EXPADV.LoadClasses( )

	EXPADV.LoadOperators( )

	EXPADV.LoadFunctions( )

	EXPADV.LoadEvents( )

	EXPADV.Exceptions = { stack = "stack" }

	for I = 1, #Temp_Exceptions do
		local Exception = Temp_Exceptions[I]

		if Exception.Component and !Exception.Component.Enabled then
			continue
		end

		EXPADV.Exceptions[ Exception.Exception ] = Exception.Exception
	end

	include( "expadv/compiler/main.lua" )

	EXPADV.SaveConfig( )

	if SERVER then
		net.Start( "expadv.config")
			net.WriteTable( EXPADV.Config )
		net.Broadcast( )

		hook.Add( "PlayerInitialSpawn", "lemon.config", function( Player )
			net.Start( "expadv.config")
				net.WriteTable( EXPADV.Config )
			net.Send( Player )
		end )
	end
		
end

if CLIET then
	net.Receive( "expadv.config", function( )
		EXPADV.Config = net.ReadTable ( )

		EXPADV.LoadCore( )
	end )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Test Build.
   --- */

hook.Add( "Initialize", "lemon.babysteps", function( )
	EXPADV.LoadCore( )
end )



