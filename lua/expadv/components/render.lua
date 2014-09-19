/* -----------------------------------------------------------------------------------
	@: Newer Better Render Library
   --- */

local Component = EXPADV.AddComponent( "render", true )

require( "Vector2" )

EXPADV.ClientOperators( )

/* -----------------------------------------------------------------------------------
	@: Fonts
   --- */

Component.ValidFonts = {
	["DebugFixed"] = true,
	["DebugFixedSmall"] = true,
	["Default"] = true,
	["Marlett"] = true,
	["Trebuchet18"] = true,
	["Trebuchet24"] = true,
	["HudHintTextLarge"] = true,
	["HudHintTextSmall"] = true,
	["CenterPrintText"] = true,
	["HudSelectionText"] = true,
	["CloseCaption_Normal"] = true,
	["CloseCaption_Bold"] = true,
	["CloseCaption_BoldItalic"] = true,
	["ChatFont"] = true,
	["TargetID"] = true,
	["TargetIDSmall"] = true,
	["HL2MPTypeDeath"] = true,
	["BudgetLabel"] = true
}

Component.CreatedFonts = { }

function Component.CreateFont( Base, Size )
	local FontName = string.format( "expadv_%s_%i", Base, Size )
	if Component.CreatedFonts[FontName] then return FontName end
	
	if !Component.ValidFonts[BaseFont] then
		BaseFont = "default"
		FontName = string.format( "expadv_default_%i", Size )
		if Component.CreatedFonts[FontName] then return FontName end
	end

	Component.CreatedFonts[FontName] = true

	surface.CreateFont( FontName, {
		font = BaseFont,
		size = Size,
		weight = 500,
		antialias = true,
		additive = true,
	} )

	return FontName
end

Component:AddVMFunction( "setFont", "s,n", "s",
	function( Context, Trace, Base, Size )
		surface.SetFont( Component.CreateFont( Base, Size ) )
	end )

Component:AddVMFunction( "setFont", "s,n,c", "s",
	function( Context, Trace, Base, Size, Color )
		surface.SetFont( Component.CreateFont( Base, Size ) )
		surface.SetTextColor( Color )
	end )

Component:AddVMFunction( "setFontColor", "c", "","$surface.SetTextColor( @value 1 )" )

Component:AddInlineFunction( "getTextWidth", "s", "n", "$surface.GetTextSize( @value 1 )" )

Component:AddPreparedFunction( "getTextHeight", "s", "n", "@define _, tall = $surface.GetTextSize( @value 1 )", "@tall" )

Component:AddFunctionHelper( "setFont", "s,n", "Sets the current font and fontsize." )
Component:AddFunctionHelper( "setFont", "s,n,c", "Sets the current font, fontsize and font color." )
Component:AddFunctionHelper(  "setFontColor", "c", "Sets the current font color." )
Component:AddFunctionHelper(  "getTextWidth", "s", "Returns the width of drawing string using the current font." )
Component:AddFunctionHelper(  "getTextHeight", "s", "Returns the width of drawing string using the current font." )

/* -----------------------------------------------------------------------------------
	@: Text
   --- */

Component:AddPreparedFunction( "drawText", "v2,s", "",
	[[$surface.SetTextPos( @value 1.x, @value 1.y )
	$surface.DrawText( @value 2 )
]])

Component:AddPreparedFunction( "drawTextCentered", "v2,s", "",
	[[@define x = @value 1.x - ($surface.GetTextSize( @value 2 ) * 0.5)
	surface.SetTextPos( @x, @value 1.y )
	surface.DrawText( @value 2 )
]])

Component:AddPreparedFunction( "drawTextAlignedRight", "v2,s", "",
	[[@define x = @value 1.x - $surface.GetTextSize( @value 2 )
	surface.SetTextPos( @x, @value 1.y )
	surface.DrawText( @value 2 )
]])

Component:AddFunctionHelper( "drawText", "v,s", "Draws a line of text aligned left of position." )
Component:AddFunctionHelper( "drawTextCentered", "v,s", "Draws a line of text aligned center of position." )
Component:AddFunctionHelper( "drawTextAlignedRight", "v,s", "Draws a line of text aligned right of position." )

/* -----------------------------------------------------------------------------------
	@: Color / Material
   --- */

Component:AddPreparedFunction( "getTextureSize", "s", "n", "$surface.GetTextureSize( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "setDrawTexture", "s", "", "$surface.SetTexture( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "setDrawColor", "n,n,n,n", "", "$surface.SetDrawColor( @value 1, @value 2, @value 3, @value 4 )" )
EXPADV.AddFunctionAlias( "setDrawColor", "n,n,n" )
EXPADV.AddFunctionAlias( "setDrawColor", "c" )

Component:AddFunctionHelper( "getTextureSize", "s", "Returns the size of a texture" )
Component:AddFunctionHelper( "setDrawTexture", "s", "Sets the texture used for rendering polys and boxs" )
Component:AddFunctionHelper( "setDrawColor", "n,n,n,n", "Sets the color used for next draw operations" )

/* -----------------------------------------------------------------------------------
	@: Objects Line
   --- */

Component:AddPreparedFunction( "drawLine", "v2,v2", "", [[
	$surface.DrawLine( @value 1.x, @value 1.y, @value 2.x, @value 2.y )
]] )

Component:AddFunctionHelper( "drawLine", "v2,v2", "Draws a line between 2 points" )

/* -----------------------------------------------------------------------------------
	@: Rectangles
   --- */

Component:AddPreparedFunction( "drawBox", "v2,v2", "", "$surface.DrawRect( @value 1.x, @value 1.y, @value 2.x, @value 2.y )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2", "", "$surface.DrawTexturedRect( @value 1.x, @value 1.y, @value 2.x, @value 2.y )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n", "", "$surface.DrawTexturedRectRotated( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3 )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n,n,n,n", "", "$surface.DrawTexturedRectUV( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3, @value 4, @value 5, @value 6 )" )


Component:AddFunctionHelper( "drawBox", "v2,v2", "Draws a box ( Position, Size )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2", "Draws a textured box ( Position, Size )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n", "Draws a rotated textured box ( Position, Size, Angle )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n,n,n,n", "Draws a textured box with uv co-ordinates ( Position, Size, U1, V1, U2, V2 )." )

/* -----------------------------------------------------------------------------------
	@: Polys
   --- */

Component:AddPreparedFunction( "drawTriangle", "v2,v2,v2", "", "$surface.DrawPoly( {@value 1, @value 2, @value 3} )" )

Component:AddPreparedFunction( "drawPoly", "c,...", "", [[
	@define polygon = { }

	for _, Variant in pairs( { @... } ) do
		if Variant[2] == "_v2" then
			@polygon[#@polygon + 1] = Variant[1]
		end
	end

	$surface.DrawPoly( @polygon )
]] )


Component:AddFunctionHelper( "drawTriangle", "v2,v2,v2", "Draws a traingle from 3 points." )
Component:AddFunctionHelper( "drawPoly", "c,...", "Draws a polygon using 2d vectors." )

/* -----------------------------------------------------------------------------------
	@: Screen
   --- */

Component:AddPreparedFunction( "pauseNextFrame", "b", "", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	Context.entity:SetRenderingPaused( @value 1 )
end]] )

Component:AddFunctionHelper( "pauseNextFrame", "b", "While set to true the screen will not draw the next frame." )

Component:AddInlineFunction( "nextFramePaused", "", "b", "((IsValid( Context.entity ) and Context.entity.Screen) and Context.entity:GetRenderingPaused( ) or false)" )
Component:AddFunctionHelper( "pauseNextFrame", "b", "returns true, if the screens next frame is paused." )

Component:AddPreparedFunction( "noFrameReresh", "b", "", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	Context.entity:SetNoClearFrame( @value 1 )
end]] )

Component:AddFunctionHelper( "noFrameReresh", "b", "While set to true the screen will not draw the next frame." )

Component:AddInlineFunction( "frameResheshDisabled", "", "b", "((IsValid( Context.entity ) and Context.entity.Screen) and Context.entity:GetNoClearFrame( ) or false)" )
Component:AddFunctionHelper( "frameResheshDisabled", "b", "returns true, if the screens is set not to clear the screen each frame." )

EXPADV.SharedOperators( )

Component:AddPreparedFunction( "getScreenCursor", "ply:", "v2", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:GetCursor( @value 1 )
else
	@value = Vector2(0,0)
end]], "@value" )

Component:AddFunctionHelper( "getScreenCursor", "ply:", "Returns the cursor psotion of a player, for a screen." )

Component:AddPreparedFunction( "screenToLocal", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:ScreenToLocalVector( @value 1 )
else
	@value = Vector(0,0,0)
end]], "@value" )

Component:AddFunctionHelper( "screenToLocal", "v2", "Returns the position on screen as a local vector." )

Component:AddPreparedFunction( "screenToWorld", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:LocalToWorld( Context.entity:ScreenToLocalVector( @value 1 ) )
else
	@value = Vector(0,0,0)
end]], "@value" )

Component:AddFunctionHelper( "screenToWorld", "v2", "Returns the position on screen as a world vector." )


/* -----------------------------------------------------------------------------------
	@: Hud Event
   --- */

EXPADV.ClientEvents( )

Component:AddEvent( "drawScreen", "n,n", "" )
Component:AddEvent( "drawHUD", "n,n", "" )

hook.Add( "HUDPaint", "expadv.hudpaint", function( )
	if !EXPADV.IsLoaded then return end

	local W, H = ScrW( ), ScrH( )

	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online then continue end
		
		local Event = Context.event_drawHUD
		
		if !Event or !Context.EnableHUD then continue end
		
		Context:Execute( "Event drawHUD", Event, W, H )
	end
end )

/* -----------------------------------------------------------------------------------
	@: Enable Hud Rendering
   --- */

function Component:OnOpenContextMenu( Entity, Menu, Trace, Option )
	if !Entity.Context or !Entity.Context.event_drawHUD then return end

	if Entity.Context.EnableHUD then
		Menu:AddOption( "Disable HUD Rendering", function( ) Entity.Context.EnableHUD = false end )
	else
		Menu:AddOption( "Enable HUD Rendering", function( ) Entity.Context.EnableHUD = true end )
	end
end