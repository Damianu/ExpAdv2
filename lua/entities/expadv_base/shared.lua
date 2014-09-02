/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Base Class
   --- */

ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"

ENT.PrintName       = "Expression Advanced 2"
ENT.Author          = "Rusketh"
ENT.Contact         = "WM/FacePunch"
ENT.ExpAdv 			= true

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: IsExpAdv2
   --- */

local meta = FindMetaTable( "Entity" )

function meta:IsExpAdv( ) return false end

function ENT:IsExpAdv( ) return true end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: VNET
   --- */

require( "vnet" ) -- Nope, You may not know what this is yet :D

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Initalize Entity
   --- */

function ENT:Initialize( )
	if SERVER then

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetUseType( SIMPLE_USE )

		if WireLib then
			self.Inputs = WireLib.CreateInputs( self, { } )
			self.Outputs = WireLib.CreateOutputs( self, { } )
		end
	end

	self:ResetStatus( )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Status
   --- */

function ENT:ResetStatus( ) end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Client must always know about this entity.
   --- */

function ENT:UpdateTransmitState( )	
	return  TRANSMIT_ALWAYS
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Context Look Up
		-- More useful clientside tbh :D
   --- */

local ContextFromEntID = { }

function EXPADV.GetEntityContext( ID )
	return ContextFromEntID[ ID ]
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: 
   --- */

function ENT:IsRunning( )
	return self.Context ~= nil and self.Context.Online
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Context Callbacks
   --- */

function ENT:OnStartUp( Context ) end

function ENT:OnShutDown( Context ) end

function ENT:OnLuaError( Context, Msg ) end

function ENT:OnScriptError( Context, Msg ) end

function ENT:OnUncatchedException( Context, Exception ) end --OnException

function ENT:OnUpdate( Context )
	if WireLib then self:TriggerOutputs( ) end
end

function ENT:OnHitQuota( Context )
	Context:ShutDown( )
	EXPADV.UnregisterContext( self.Context )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Context
   --- */

function ENT:GetContext( )
	return self.Context
end

function ENT:OnContextCreated( Context )
	-- For usage of derived classes only!
	-- Return true to disable context callbacks.
end

function ENT:CreateContext( Instance, Player )
	local Context = EXPADV.BuildNewContext( Instance, Player, self )

	if !self:OnContextCreated( Context ) then

		Context.OnStartUp = function( ctx ) return self:OnStartUp( ctx ) end

		Context.OnShutDown = function( ctx ) return self:OnShutDown( ctx ) end

		Context.OnLuaError = function( ctx, msg ) MsgN( "LUA ERROR: ", msg ) end -- return self:OnLuaError( ctx, msg ) end

		Context.OnScriptError = function( ctx ) return self:OnScriptError( ctx, msg ) end

		Context.OnException = function( ctx, exc ) return self:OnUncatchedException( ctx, exc ) end
		
		Context.OnUpdate = function( ctx ) return self:OnUpdate( ctx ) end
		
		Context.OnHitQuota = function( ctx ) return self:OnHitQuota( ctx ) end
	end

	ContextFromEntID[ self:EntIndex( ) ] = Context

	EXPADV.RegisterContext( Context )

	self.Context = Context

	return Context
end

function ENT:OnRemove( )
	if !self:IsRunning( ) then return end

	self.Context:ShutDown( )

	EXPADV.UnregisterContext( self.Context )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Compiler
   --- */

function ENT:IsCompiling( )
	return self.Compiler ~= nil
end

function ENT:CompileScript( Root, Files )

	if self:IsRunning( ) then
		self.Context:ShutDown( )
		EXPADV.UnregisterContext( self.Context )
	end

	self.Compiler = EXPADV.Compile( Root, Files,

		function( ErMsg )
			local Cmp = self.Compiler

			self.Compiler = nil

			return self:OnCompileError( ErMsg, Cmp )
		end,

		function( Instance, Instruction )
			self.Compiler = nil -- The instance is the compiler :D
			return self:BuildInstance( Instance, Instruction )
		end
	) -- Now we wait for the callback!
end

function ENT:OnCompileError( ErMsg, Compiler ) end

function ENT:BuildInstance( Instance, Instruction )
	
	local Native = table.concat( {
		"return function( Context )",
		"setfenv( 1, Context.Enviroment )",
		Instruction.Prepare or "",
		Instruction.Inline or "",
		"end"
	}, "\n" )

	local Compiled = CompileString( Native, "EXPADV2", false )

	if isstring( Compiled ) then
		return self:OnCompileError( Compiled, Instance )
	end

	local Context = self:CreateContext( Instance, self.player )
	
	self.Cells = Instance.Cells 

	if WireLib and SERVER then
		self:BuildInputs( self.Cells, Instance.InPorts )
		self:BuildOutputs( self.Cells, Instance.OutPorts )
		self:LoadFromInputs( )
	end

	Context:StartUp( Compiled( ) )

	if CLIENT then
		local Package = vnet.CreatePacket( "expadv.cl_loaded" )

		Package:Entity( self )
		
		Package:Entity( LocalPlayer( ) )

		Package:AddServer( )

		Package:Send( )
	end
end

function ENT:GetCompilePer( )
	if !self.Compiler then return self:IsRunning( ) and 100 or 0 end

	return self.Compiler:PercentCompiled( )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Context Menu
   --- */

local function Filter( self, Entity, Player )
	if !(IsValid( Entity ) and Entity.ExpAdv) then return false end
	if CLIENT then return true end
	
	if !gamemode.Call( "CanProperty", Player, "expadv", Entity ) then
		return false -- Somthing denied access!
	end

	return true
end

local function MenuOpen( ContextMenu, Option, Entity, Trace )
	local SubMenu = Option:AddSubMenu( )
	EXPADV.CallHook( "OpenContextMenu", Entity, SubMenu, Trace, Option )
end

properties.Add( "expadv", {
	MenuLabel = "Expression Advanced",
	MenuIcon  = "fugue/gear.png",
	Order = 999,
	Filter = Filter,
	MenuOpen = MenuOpen,
	Action = function( ) end,
} ) -- We wont use recieve here, Send it yourself :D

