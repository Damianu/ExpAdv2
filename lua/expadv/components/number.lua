/*	---	--------------------------------------------------------------------------------
	@: Server -> Math Component
---	*/

local MathComponent = EXPADV.AddComponent( "math" , true )
local Number = MathComponent:AddClass( "number" , "n" )

Number:DefaultAsLua( 0 )
Number:AddAlias( "int" )

if WireLib then
	Number:WireInput( "NUMBER" ) 
	Number:WireOutput( "NUMBER" ) 
end

/*	---	--------------------------------------------------------------------------------
	@:Section -> Math Operators.
---	*/

MathComponent:AddInlineOperator( Name, Input, Return, Inline )
MathComponent:AddPreparedOperator( Name, Input, Return, Prepare, Inline )

-- TODO: COMPONENT NOT YET SUPPORTEDs
MathComponent:AddPreparedOperator("=","n","n",[[
	
]], "@value 2")

-- TODO: COMPONENT NOT YET SUPPORTED
MathComponent:AddPreparedOperator("~","n","b",[[
	
]], "%Changed")

/*	---
	@Compare:
---	*/

MathComponent:AddInlineOperator("==", "n,n", "b", "(@value 1 == @value 2)" )
MathComponent:AddInlineOperator("!=", "n,n", "b", "(@value 1 != @value 2)" )
MathComponent:AddInlineOperator(">", "n,n", "b", "(@value 1 > @value 2)" )
MathComponent:AddInlineOperator("<", "n,n", "b", "(@value 1 < @value 2)" )
MathComponent:AddInlineOperator(">=","n,n", "b", "(@value 1 >= @value 2)" )
MathComponent:AddInlineOperator("<=","n,n", "b", "(@value 1 <= @value 2)" )

/*	---
	@Arithmatic:
---	*/

MathComponent:AddInlineOperator("+", "n,n", "n", "(@value 1 + @value 2)" )
MathComponent:AddInlineOperator("-", "n,n", "n", "(@value 1 - @value 2)" )
MathComponent:AddInlineOperator("*", "n,n", "n", "(@value 1 * @value 2)" )
MathComponent:AddInlineOperator("/", "n,n", "n", "(@value 1 / @value 2)" )
MathComponent:AddInlineOperator("%", "n,n", "n", "(@value 1 % @value 2)" )
MathComponent:AddInlineOperator("^", "n,n", "n", "(@value 1 ^ @value 2)" )

/*	---
	@General:
---	*/

MathComponent:AddInlineOperator("is", "n", "b", "(@value 1 >= 1)" )
MathComponent:AddInlineOperator("not", "n", "b", "(@value 1 < 1)" )
MathComponent:AddInlineOperator("-", "n", "b", "(-@value 1)" )
MathComponent:AddInlineOperator("$", "n", "n", "((%memory[@value 1] or 0) - (%delta[@value 1] or 0))" )

/*	---	---------------------------------------------------------------------------------
	@:Section -> Assignment Operators
---	/*

/*	---
	@Assign Before:
---	*/
	-- TODO: NOT YET SUPPORTED

/*	---
	@Assign After:
---	*/
	-- TODO: NOT YET SUPPORTED
	

/*	---	---------------------------------------------------------------------------------
	@:Section -> Min Max Function
---	*/

	-- TODO ADD THIS AREA
	
/*	---	---------------------------------------------------------------------------------
	@:Section -> Random Numbers
---	*/

	-- TODO ADD THIS AREA
	
/*	---	---------------------------------------------------------------------------------
	@:Section -> Advanced Math
---	*/

	-- TODO ADD THIS AREA
	
/*	---	---------------------------------------------------------------------------------
	@:Section -> Trig
---	*/

	-- TODO ADD THIS AREA
	
/*	---	---------------------------------------------------------------------------------
	@:Section -> Binary
---	*/

	-- TODO ADD THIS AREA

/*	---	---------------------------------------------------------------------------------
	@:Section -> Constants
---	*/

	-- TODO ADD THIS AREA