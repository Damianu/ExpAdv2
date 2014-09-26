/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Wire Mod
   --- */

if !WireLib then return end

local function SortPorts( PortA, PortB )
	local TypeA = PortA[2] or "NORMAL"
	local TypeB = PortB[2] or "NORMAL"

	if TypeA ~= TypeB then
		if TypeA == "NORMAL" then
			return true
		elseif TypeB == "NORMAL" then
			return false
		end

		return TypeA < TypeB
	else
		return PortA[1] < PortB[1]
	end
end

function ENT:BuildInputs( Cells, Ports )
	local Unsorted = { }

	for Variable, Reference in pairs( Ports ) do
		local Cell = Cells[ Reference ]
		Unsorted[ #Unsorted + 1 ] = { Variable, Cell.ClassObj.Wire_In_Type }
	end

	table.sort( Unsorted, SortPorts )

	local Names = { }
	local Types = { }

	for I = 1, #Unsorted do
		local Port = Unsorted[I]
		Names[I] = Port[1]
		Types[I] = Port[2]
	end

	self.InPorts = Ports
	self.DupeInPorts = { Names, Types }
	self.Inputs = WireLib.AdjustSpecialInputs( self, Names, Types )
end


function ENT:BuildOutputs( Cells, Ports )
	local OutClick = { }
	local Unsorted = { }

	for Variable, Reference in pairs( Ports ) do
		local Cell = Cells[ Reference ]
		Unsorted[ #Unsorted + 1 ] = { Variable, Cell.ClassObj.Wire_Out_Type }

		if Cell.ClassObj.HasUpdateCheck then
			OutClick[ Reference ] = Variable
		end
	end

	table.sort( Unsorted, SortPorts )

	local Names = { }
	local Types = { }

	for I = 1, #Unsorted do
		local Port = Unsorted[I]
		Names[I] = Port[1]
		Types[I] = Port[2]
	end

	self.OutPorts = Ports
	self.OutClick = OutClick
	self.DupeOutPorts = { Names, Types }

	self.Outputs = WireLib.AdjustSpecialOutputs( self, Names, Types )
end


function ENT:LoadFromInputs( )
	--Note: This will load inports into memory!
	local Cells = self.Cells

	for Variable, Port in pairs( self.Inputs ) do
		local Reference = self.InPorts[ Variable ]

		if Reference then
			local Cell = Cells[ Reference ]

			if Cell and Port.Type == Cell.ClassObj.Wire_In_Type then
				Cell.ClassObj.Wire_In_Util( self.Context, Reference, Port.Value )
			end
		end
	end
end

function ENT:TriggerInput( Key, Value )
	local Context = self.Context
	if !self.Context then return end

	local Reference = self.InPorts[ Key ]
	local Cell = self.Cells[ Reference ]

	if !Cell then return end

	Cell.ClassObj.Wire_In_Util( self.Context, Reference, Value )
	Context.Trigger[ Reference ] = true

	self:CallEvent( "trigger", Key, Cell.Class.Name )

	Context.Trigger[ Reference ] = false
end

function ENT:TriggerOutputs( )
	local Context = self.Context
	if !self.Context then return end

	local Cells = self.Cells

	for Name, Reference in pairs( self.OutPorts ) do
		local Class = Cells[ Reference ].ClassObj

		if Context.Trigger[ Reference ] then
			local Value = Class.Wire_Out_Util( Context, Reference )
			WireLib.TriggerOutput( self, Name, Value )
		elseif self.OutClick[ Reference ] then
			local Val = Context.Memory[ Reference ]

			if Val and Val.HasChanged then
				Val.HasChanged = nil
				local Value = Class.Wire_Out_Util( Context, Reference )
				WireLib.TriggerOutput( self, Name, Value )
			end
		end
	end
end
