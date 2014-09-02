if !EXPADV then return ErrorNoHalt( "Expression Advanced 2, Failed to load tool." ) end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Language
   --- */

if CLIENT then
	language.Add( "Tool.expadv2.name", "Expression Advanced 01000000" )
	language.Add( "Tool.expadv2.desc", "Creats an ingame scriptable entity." )
	language.Add( "Tool.expadv2.help", "TODO - Replace me!" )
	language.Add( "Tool.expadv2.0", "TODO - Fuck me!." )
	
	language.Add( "limit_expadv", "Expression Advanced entity limit reached." )
	language.Add( "Undone_expadv", "Expression Advanced - Removed." )
	language.Add( "Cleanup_expadv", "Expression Advanced - Removed." )
	language.Add( "Cleaned_expadvs", "Expression Advanced - Removed all entitys." )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Tool Information
   --- */

if WireLib then
	TOOL.Name						= "Expression Advanced 2"
	TOOL.Category					= "Chips, Gates"
	TOOL.Tab						= "Wire"
else
	TOOL.Name						= "Expression Advanced 2"
	TOOL.Category					= "Scriptable"
	TOOL.Tab						= "Tools"
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Cvars
   --- */

TOOL.ClientConVar.Model 		= "models/lemongate/lemongate.mdl"
TOOL.ClientConVar.Weldworld 	= 0
TOOL.ClientConVar.Frozen		= 0

hook.Add( "Expadv.PostLoadConfig", "Expadv.Tool", function( )
	EXPADV.CreateSetting( "sboxmax_expadv", 20 )
end )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Model List
   --- */

list.Set( "expadv2.models", "models/lemongate/lemongate.mdl", { } )

if WireLib then
	list.Set( "expadv2.models", "models/bull/gates/processor.mdl", { } )
	list.Set( "expadv2.models", "models/expression 2/cpu_controller.mdl", { } )
	list.Set( "expadv2.models", "models/expression 2/cpu_expression.mdl", { } )
	list.Set( "expadv2.models", "models/expression 2/cpu_interface.mdl", { } )
	list.Set( "expadv2.models", "models/expression 2/cpu_microchip.mdl", { } )
	list.Set( "expadv2.models", "models/expression 2/cpu_processor.mdl", { } )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Clean up
   --- */

cleanup.Register( "expadv" )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Utility
   --- */

local function IsExpAdv( Entity )
	if !IsValid( Entity ) then return false end
	return Entity.Base == "expadv_base"
end -- TODO: Use somthing other then base class comparason.

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Make the entity
   --- */

local function MakeExpadv( Player, Position, Angle, Model )
	if Player:GetCount( "expadv" ) > EXPADV.ReadSetting( "sboxmax_expadv", 20 ) then
		LimitHit( language.GetPhrase("limit_expadv" ) )
		return nil
	end
	
	local ExpAdv = ents.Create( "expadv_gate" )
	if !IsValid( ExpAdv ) then return end

	ExpAdv:SetPos( Position )
	ExpAdv:SetAngles( Angle )
	ExpAdv:SetModel( Model )
	ExpAdv:Activate( )
	ExpAdv:Spawn( )

	Player:AddCount( "expadv", ExpAdv )
	ExpAdv:SetPlayer( Player )
	ExpAdv.player = Player

	return ExpAdv
end

duplicator.RegisterEntityClass( "expadv2", MakeExpadv, "Pos", "Ang", "Model" )

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Right Click
   --- */

function TOOL:RightClick( Trace )
	if CLIENT then return end
	
	if !IsValid( Trace.Entity ) then
		self:GetOwner( ):SendLua( "EXPADV.Editor.Open( )" )
		return false
	end

	-- TODO: Request Code
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Left Click
   --- */

function TOOL:LeftClick( Trace )
	if IsValid( Trace.Entity ) then -- and EXPADV.IsFriend( Trace.Entity, self:GetOwner( ) ) then
		if !Trace.Entity.ExpAdv then
			return
		elseif SERVER then
			net.Start( "expadv.request" )
			net.WriteUInt( Trace.Entity:EntIndex( ), 16 )
			net.Send( self:GetOwner( ) )
		end

		return true
	elseif CLIENT then
		return true
	end

	local Ang = Trace.HitNormal:Angle( ) + Angle( 90, 0, 0 )
	local ExpAdv = MakeExpadv( self:GetOwner( ), Trace.HitPos, Ang, self:GetClientInfo( "Model" ) )

	if !IsValid( ExpAdv ) then return false end

	ExpAdv:SetPos( Trace.HitPos - Trace.HitNormal * ExpAdv:OBBMins().z )

	local WeldWorld = self:GetClientNumber( "weldworld" )

	undo.Create( "expadv" )
	undo.AddEntity( ExpAdv )
	undo.SetPlayer( self:GetOwner( ) ) 

	if self:GetClientNumber( "weld" ) >= 1 then
		if !IsValid( Trace.Entity ) and WeldWorld then
			undo.AddEntity( constraint.Weld( ExpAdv, Trace.Entity, 0, Trace.PhysicsBone, 0, 0, WeldWorld ) )
		end 
	end

	undo.Finish( )

	if self:GetClientNumber("frozen") >= 1 then
		ExpAdv:GetPhysicsObject( ):EnableMotion( false )
	end

	
	self:GetOwner( ):AddCleanup( "expadv2", ExpAdv )

	net.Start( "expadv.request" )
	net.WriteUInt( ExpAdv:EntIndex( ), 16 )
	net.Send( self:GetOwner( ) )

	return true
end


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Tool Panel
   --- */
if CLIENT then
	function TOOL.BuildCPanel( CPanel )
		CPanel:AddControl( "PropSelect", { Label = "Select Model:", ConVar = "expadv2_model", Models = list.Get( "expadv2.models" ), Height = 1 } )
		CPanel:AddControl( "Checkbox", { Label = "Weld to world.", Command = "expadv2_weldworld" } )
		CPanel:AddControl( "Checkbox", { Label = "Place frozen.", Command = "expadv2_frozen" } )
	end
end