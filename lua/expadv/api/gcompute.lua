local LANGUAGE = GCompute.Languages.Create( "EXPADV2" )

EXPADV.GCompute = LANGUAGE

----------------------------------------------------------------------------------

local Tokenizer = LANGUAGE:GetTokenizer( )
Tokenizer:AddPatternSymbol( GCompute.Lexing.TokenType.Identifier, "[a-zA-Z_][a-zA-Z0-9_]*" )
Tokenizer:AddPatternSymbols( GCompute.Lexing.TokenType.Number, {
		"0b[01]+",
		"0x[0-9a-fA-F]+",
		"[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*",
		"[0-9]+%.[0-9]*e[-+]?[0-9]+",
		"[0-9]+%.[0-9]*",
		"[0-9]+e[-+]?[0-9]+%.[0-9]*",
		"[0-9]+e[-+]?[0-9]+", "[0-9]+"
} )

Tokenizer:AddPlainSymbols( GCompute.Lexing.TokenType.MemberIndexer, { "." } )
Tokenizer:AddPlainSymbol( GCompute.Lexing.TokenType.StatementTerminator, ";" )
Tokenizer:AddPlainSymbols( GCompute.Lexing.TokenType.Newline, { "\r\n", "\r", "\n" } )
Tokenizer:AddPatternSymbol( GCompute.Lexing.TokenType.Whitespace, "[ \t]+" )

Tokenizer:AddPlainSymbol( GCompute.Lexing.TokenType.Comment, "//[^\n\r]*" )
Tokenizer:AddCustomSymbol( GCompute.Lexing.TokenType.Comment, "/*", function( Code, Offset )
	local endOffset = string.find( Code, "*/", Offset + 2, true )
	if endOffset then return string.sub( Code, offset, endOffset + 1), endOffset - Offset + 2 end
	return string.sub( Code, Offset ), string.len( Code ) - Offset + 1
end )

Tokenizer:AddCustomSymbols (GCompute.Lexing.TokenType.String, {"\"", "'"}, function (code, offset)
	local quotationMark = string.sub (code, offset, offset)
	local searchStartOffset = offset + 1
	local backslashOffset = 0
	local quotationMarkOffset = 0
	while true do
		if backslashOffset and backslashOffset < searchStartOffset then
			backslashOffset = string.find (code, "\\", searchStartOffset, true)
		end
		if quotationMarkOffset and quotationMarkOffset < searchStartOffset then
			quotationMarkOffset = string.find (code, quotationMark, searchStartOffset, true)
		end
		
		if backslashOffset and quotationMarkOffset and backslashOffset > quotationMarkOffset then backslashOffset = nil end
		if not backslashOffset then
			if quotationMarkOffset then
				return string.sub (code, offset, quotationMarkOffset), quotationMarkOffset - offset + 1
			else
				return string.sub (code, offset), string.len (code) - offset + 1
			end
		end
		searchStartOffset = backslashOffset + 2
	end
end )
	
----------------------------------------------------------------------------------

local KeywordClassifier = LANGUAGE:GetKeywordClassifier( )
KeywordClassifier:AddKeywords( GCompute.Lexing.KeywordType.Modifier, { "global", "input", "output" } )
KeywordClassifier:AddKeywords( GCompute.Lexing.KeywordType.Control,  { "if", "else", "elseif", "while", "for", "foreach", "switch", "case", "default", "try", "catch" } )
KeywordClassifier:AddKeywords( GCompute.Lexing.KeywordType.Control,  { "break", "return", "continue", "throw" } )
KeywordClassifier:AddKeywords( GCompute.Lexing.KeywordType.DataType, { "method", "function", "event" } )
KeywordClassifier:AddKeywords( GCompute.Lexing.KeywordType.Constant, { "true", "false" } )

----------------------------------------------------------------------------------

local EditorHelperTable = LANGUAGE.EditorHelperTable

function EditorHelperTable:GetCommentFormat( )
	return "//", "/*", "*/"
end

----------------------------------------------------------------------------------

LANGUAGE.RootNamespace = GCompute.NamespaceDefinition( )

function EditorHelperTable:GetRootNamespace( )
    return LANGUAGE.RootNamespace
end


----------------------------------------------------------------------------------

function LANGUAGE.BuildData( )
	local Namespace = LANGUAGE.RootNamespace

	local OperatorTokens = { }

	for _, Token in pairs( EXPADV.Compiler.RawTokens ) do
		OperatorTokens[#OperatorTokens + 1] = Token[1]
	end

	Tokenizer:AddPlainSymbols( GCompute.Lexing.TokenType.Operator, OperatorTokens )

	-------------------------------------------------------------------------------------

	local Classes = { }
	local Void = GCompute.GlobalNamespace:GetMember("void"):ToType( )

	for Name, Class in pairs( EXPADV.Classes ) do
		Classes[Class.Short] = Namespace:AddClass( Name )
	end

	for Name, Class in pairs( EXPADV.Classes ) do
		if Class.DeriveGeneric or !Class.DerivedClass then continue end
		Classes[Class.Short]:AddBaseType( Classes[Class.DerivedClass.Short] )
	end

	-- TODO: !Cake fix this please!
	--for _, Operator in pairs( EXPADV.Functions ) do
		--local ParameterList = GCompute.ParameterList( )
		--local ReturnType = Operator.Return and Classes[Operator.Return]:GetClassType( ) or Void
 
		--if !Operator.Method then
			--local Member = Namespace:GetMember( Operator.Name )
			--if !Member then continue end

			--for I = 1, #Operator.Input do
			--	ParameterList:AddParameter( Classes[Operator.Input[I]]:GetClassType( ) )
			--end

			--Member:GetClass( 1 ):AddConstructor( ParameterList )
		--else
			--local MethodClass = Classes[Operator.Input[I]]

			--for I = 2, #Operator.Input do
			--	ParameterList:AddParameter( Classes[Operator.Input[I]]:GetClassType( ) )
			--end

			--MethodClass:GetNamespace( ):AddMethod( Operator.Name, ParameterList ):SetReturnType( ReturnType )
			
		--end
	--end

	LANGUAGE:DispatchEvent( "NamespaceChanged" )
end

hook.Add( "Expadv.PostLoadCore", "Expadv.GCompute.RequestData", LANGUAGE.BuildData )

GCompute:AddEventListener( "Unloaded", function( ) hook.Remove( "Expadv.PostLoadCore", "Expadv.GCompute.BuildData" ) end )

if EXPADV and EXPADV.IsLoaded then LANGUAGE.BuildData( ) end

----------------------------------------------------------------------------------

local PANEL = { }

function PANEL:Init( )
	self.CellList = vgui.Create( "DListView", self )

	self.CellList:AddColumn( "Cell" )
	self.CellList:AddColumn( "Scope" )
	self.CellList:AddColumn( "Class" )
	self.CellList:AddColumn( "Modifier" )
	self.CellList:AddColumn( "Name" )
	self.CellList:AddColumn( "Value" )

	self.CellList:Dock( FILL )


end

function PANEL:Update( )
	self.CellList:Clear( )

	for MemRef, Cell in pairs( self.Context.Cells ) do
		local Value = self.Context.Memory[MemRef]
		local StrValue = tostring( Value or "#Void" )

		self.CellList:AddLine( MemRef, Cell.Scope, Cell.Return, Cell.Modifier or "N/A", Cell.Variable, StrValue )
	end
end

function PANEL:SetUp( Context, Root, stdOut, stdErr )
	Context.OnStartUp = function( self )
		stdOut:WriteLine( "Executed code root." )
	end

	Context.OnShutDown = function( self )
		stdOut:WriteLine( "Context shut down." )
	end

	Context.OnLuaError = function( self, Msg )
		stdErr:WriteLine( "Lua Error: " .. Msg )
	end

	Context.OnScriptError = function( self, Msg )
		stdErr:WriteLine( "Script Error: " .. Msg )
	end

	Context.OnException = function( self, Exception )
		stdErr:WriteLine( "Uncatched exception: " .. unpack( Exception ) )
	end

	Context.OnUpdate = function( pnl )
		self:Update( )
	end

	Context.Print = function( Trace, Msg )
		stdOut:WriteLine( string.format( "[%i,%i] - %s", Trace[1], Trace[2], Msg ) )
	end

	self.Context = Context

	--self:Update( )

	Context:StartUp( Root )
end

function PANEL:ShutDown( )
	self.Context:ShutDown( )
	EXPADV.UnregisterContext( self.Context )
end

vgui.Register( "EA_GC_Context", PANEL, "DPanel" )

----------------------------------------------------------------------------------

function EditorHelperTable:Run( codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr )
	local OnError = function( ErrMsg )
		compilerStdErr:WriteLine( ErrMsg )
	end

	local OnSucess = function ( Instance, Instruction )
		compilerStdOut:WriteLine( "Compiler Finished." )

		local Native = table.concat( {
			"return function( Context )",
			"setfenv( Context.Enviroment )",
			Instruction.Prepare or "",
			Instruction.Inline or "",
			"end"
		}, "\n" )

		local Compiled = CompileString( Native, "EXPADV2", false )
			
		if isstring( Compiled ) then
			compilerStdErr:WriteLine( "Failed to compile native.")
			compilerStdErr:WriteLine( Compiled )
			return
		end

		local Context = EXPADV.BuildNewContext( Instance, LocalPlayer( ), LocalPlayer( ) )

		EXPADV.RegisterContext( Context )

		compilerStdOut:WriteLine( "Context built." )

		local Frame = vgui.Create( "DFrame" )
		Frame:SetTitle( "Expression Advanced Two" )
		Frame:SetSize( 300, 322 )

		local Pnl = vgui.Create( "EA_GC_Context", Frame )
		Pnl:Dock( FILL )
		Pnl:SetUp( Context, Compiled( ), stdOut, stdErr )

		Frame:Center( )
		Frame:MakePopup( )

		Frame.Close = function( self )
			Pnl:ShutDown( )
			DFrame.Close( self )
		end
	end

	compilerStdOut:WriteLine( "Compiler Started." )

	EXPADV.Compile( codeEditor:GetText( ), { }, true, OnError, OnSucess )
end