/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Print Operator
   --- */

EXPADV.ServerOperators( )

EXPADV.AddPreparedFunction( nil, "printColor", "...", "",[[
	@define Tbl = { @... }

	for K, Obj in pairs( @Tbl ) do
		if Obj[2] == "c" then continue end
	end

	EXPADV.PrintColor( Context.Player, @Tbl )
]] )

EXPADV.AddPreparedFunction( nil, "print", "...", "",[[
	@define Tbl = { @... }

	for K, Obj in pairs( @Tbl ) do
		@Tbl[K] = EXPADV.ToString( Obj[2], Obj[1] )
	end

	EXPADV.PrintColor( Context.Player, @Tbl )
]] )

if SERVER then
	util.AddNetworkString( "expadv.printcolor" )

	function EXPADV.PrintColor( Player, Tbl )
		net.Start( "expadv.printcolor" )
		net.WriteTable( Tbl )
		net.Send( Player )
	end

end

if CLIENT then
	net.Receive( "expadv.printcolor", function( )
		local Tbl = net.ReadTable( )

		MsgN( "From ExpAdv2:" )
		PrintTable( Tbl )
		
		chat.AddText( unpack( Tbl ) )
	end )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Define boolean class
   --- */

EXPADV.SharedOperators( )

local Boolean = EXPADV.AddClass( nil, "boolean", "b" )
	  
	  Boolean:AddAlias( "bool" )

	  Boolean:DefaultAsLua( false )

if WireLib then
	Boolean:WireInput( "NUMBER", function( Context, MemoryRef )
		return Context.Memory[ MemoryRef ] and 1 or 0
	end ) 

	Boolean:WireOutput( "NUMBER", function( Context, MemoryRef, InValue )
		Context.Memory[ MemoryRef ] = (InValue ~= 0)
	end )
end

EXPADV.AddInlineOperator( nil, "==", "b,b", "b", "(@value 1 == @value 2)" )
EXPADV.AddInlineOperator( nil, "!=", "b,b", "b", "(@value 1 != @value 2)" )

EXPADV.AddInlineOperator( nil, "is", "b", "b", "@value 1" )
EXPADV.AddInlineOperator( nil, "not", "b", "b", "!@value 1" )

EXPADV.AddInlineOperator( nil, "||", "b,b", "b", "(@value 1 or @value 2)" )
EXPADV.AddInlineOperator( nil, "&&", "b,b", "b", "(@value 1 and @value 2)" )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Register variant class!
   --- */

local Variant = EXPADV.AddClass( nil, "variant", "vr" )
		
	  Variant:DefaultAsLua( { false, "b" } )

hook.Add( "Expadv.PostRegisterClass", "expad.variant", function( Name, Class )
	if !Class.LoadOnClient then
		EXPADV.ServerOperators( )
	elseif !Class.LoadOnServer then
		EXPADV.ClientOperators( )
	else EXPADV.SharedOperators( ) end

	EXPADV.AddInlineOperator( nil, "variant", Class.Short, "vr", "{ @value 1, @type 1 }" )

	EXPADV.AddInlineOperator( nil, Name, "vr", Class.Short, string.format( "( @value 1[2] == %q and @value 1[1] or Context:Throw(@trace, %q, \"Attempt to cast value \" .. EXPADV.TypeName(@value 1[2]) .. \" to %s \") )", Class.Short, "cast", Name ) )
end )	


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Register exception class!
   --- */

local Class_Exception = EXPADV.AddClass( nil, "exception", "ex" )

-- TODO

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
@: Exceptions
--- */

EXPADV.AddException( nil, "cast" )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
@: Events
--- */

EXPADV.SharedEvents( )

EXPADV.AddEvent( nil, "tick", "", "" )

hook.Add( "Tick", "Expav.Event", function( ) EXPADV.CallEvent( "tick" ) end )

EXPADV.AddEvent( nil, "think", "", "" )

hook.Add( "Think", "Expav.Event", function( ) EXPADV.CallEvent( "think" ) end )