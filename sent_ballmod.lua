
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "Bouncy Ball"
ENT.Author = "Garry Newman"
ENT.Information = "An edible bouncy ball"
ENT.Category = "Fun + Games"

ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.MinSize = 4
ENT.MaxSize = 128
local fnames = {"Jacob","Emily","Michael","Hannah","Matthew","Alexis","Joshua","Sarah","Nicholas","Samantha","Christopher","Ashley","Andrew","Madison","Joseph","Taylor","Daniel","Jessica","Tyler","Elizabeth","Brandon","Alyssa","Ryan","Lauren","Austin","Kayla","William","Brianna","John","Megan","David","Victoria","Zachary","Emma","Anthony","Abigail","James","Rachel","Justin","Olivia","Alexander","Jennifer","Jonathan","Amanda","Dylan","Sydney","Noah","Morgan","Christian","Nicole","Robert","Jasmine","Samuel","Grace","Kyle","Destiny","Benjamin","Anna","Jordan","Julia","Thomas","Haley","Nathan","Alexandra","Cameron","Kaitlyn","Kevin","Natalie","Jose","Brittany","Hunter","Katherine","Ethan","Stephanie","Aaron","Rebecca","Eric","Maria","Jason","Allison","Caleb","Amber","Logan","Savannah","Brian","Danielle","Adam","Courtney","Cody","Mary","Juan","Gabrielle","Steven","Brooke","Connor","Jordan","Timothy","Sierra","Charles","Sara","Isaiah","Kimberly","Jack","Mackenzie","Gabriel","Sophia","Jared","Hailey","Luis","Katelyn","Sean","Michelle","Evan","Vanessa","Alex","Erin","Carlos","Andrea","Elijah","Isabella","Richard","Jenna","Nathaniel","Shelby","Patrick","Chloe","Isaac","Melissa","Seth","Bailey","Trevor","Makayla","Luke","Paige","Devin","Mariah","Mark","Kaylee","Jesus","Madeline","Ian","Caroline","Mason","Kelsey","Angel","Marissa","Bryan","Breanna","Cole","Christina","Chase","Faith","Dakota","Autumn","Garrett","Kiara","Adrian","Jacqueline","Antonio","Tiffany","Jeremy","Laura","Jesse","Briana","Jackson","Alexandria","Blake","Cheyenne","Dalton","Mikayla","Stephen","Claire","Tanner","Cassandra","Alejandro","Sabrina","Kenneth","Alexa","Lucas","Angela","Miguel","Kathryn","Spencer","Katie","Bryce","Caitlin","Paul","Miranda","Victor","Kelly","Brendan","Lindsey","Jake","Isabel","Marcus","Catherine","Tristan","Cassidy","Jeffrey","Leslie"}
function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "BallSize", { KeyName = "ballsize", Edit = { type = "Float", min = self.MinSize, max = self.MaxSize, order = 1 } } )
	self:NetworkVar( "Vector", 0, "BallColor", { KeyName = "ballcolor", Edit = { type = "VectorColor", order = 2 } } )
	self:NetworkVar( "String", 0, "MyName", {Edit = {type = "String", title = "Name", order = 3}})
	self:NetworkVarNotify( "BallSize", self.OnBallSizeChanged )

end

-- This is the spawn function. It's called when a client calls the entity to be spawned.
-- If you want to make your SENT spawnable you need one of these functions to properly create the entity
--
-- ply is the name of the player that is spawning it
-- tr is the trace from the player's eyes
--
function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local size = math.random( 16, 48 )

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * size )
	ent:SetBallSize( size )
	ent:Spawn()
	ent:Activate()

	return ent

end

--[[---------------------------------------------------------
	Name: Initialize
-----------------------------------------------------------]]
function ENT:Initialize()

	-- We do NOT want to execute anything below in this FUNCTION on CLIENT
	if ( CLIENT ) then return end

	-- Use the helibomb model just for the shadow (because it's about the same size)
	self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )

	-- We will put this here just in case, even though it should be called from OnBallSizeChanged in any case
	self:RebuildPhysics()

	-- Select a random color for the ball
	self:SetBallColor( table.Random( {
		Vector( 1, 0.3, 0.3 ),
		Vector( 0.3, 1, 0.3 ),
		Vector( 1, 1, 0.3 ),
		Vector( 0.2, 0.3, 1 ),
	} ) )
	self:SetMyName(table.Random(fnames))

end

function ENT:RebuildPhysics( value )

	local size = math.Clamp( value or self:GetBallSize(), self.MinSize, self.MaxSize ) / 2.1
	self:PhysicsInitSphere( size, "metal_bouncy" )
	self:SetCollisionBounds( Vector( -size, -size, -size ), Vector( size, size, size ) )

	self:PhysWake()

end

function ENT:OnBallSizeChanged( varname, oldvalue, newvalue )

	-- Do not rebuild if the size wasn't changed
	if ( oldvalue == newvalue ) then return end

	self:RebuildPhysics( newvalue )

end

--[[---------------------------------------------------------
	Name: PhysicsCollide
-----------------------------------------------------------]]
local BounceSound = Sound( "garrysmod/balloon_pop_cute.wav" )

function ENT:PhysicsCollide( data, physobj )

	-- Play sound on bounce
	if ( data.Speed > 60 && data.DeltaTime > 0.2 ) then

		local pitch = 32 + 128 - math.Clamp( self:GetBallSize(), self.MinSize, self.MaxSize )
		sound.Play( BounceSound, self:GetPos(), 75, math.random( pitch - 10, pitch + 10 ), math.Clamp( data.Speed / 150, 0, 1 ) )

	end

	-- Bounce like a crazy bitch
	local LastSpeed = math.max( data.OurOldVelocity:Length(), data.Speed )
	local NewVelocity = physobj:GetVelocity()
	NewVelocity:Normalize()

	LastSpeed = math.max( NewVelocity:Length(), LastSpeed )

	local TargetVelocity = NewVelocity * LastSpeed * 0.9

	physobj:SetVelocity( TargetVelocity )

end

--[[---------------------------------------------------------
	Name: OnTakeDamage
-----------------------------------------------------------]]
function ENT:OnTakeDamage( dmginfo )

	-- React physically when shot/getting blown
	self:TakePhysicsDamage( dmginfo )

end

--[[---------------------------------------------------------
	Name: Use
-----------------------------------------------------------]]
function ENT:Use( activator, caller )

	self:Remove()

	if ( activator:IsPlayer() ) then

		-- Give the collecting player some free health
		local health = activator:Health()
		activator:SetHealth( health + 5 )
		activator:SendLua( "achievements.EatBall()" )

	end

end

if ( SERVER ) then return end -- We do NOT want to execute anything below in this FILE on SERVER

local matBall = Material( "sprites/sent_ball" )
local ply = LocalPlayer()
function ENT:Draw()

	local pos = self:GetPos()

	render.SetMaterial( matBall )

	local lcolor = render.ComputeLighting( self:GetPos(), Vector( 0, 0, 1 ) )
	local c = self:GetBallColor()
	local size = math.Clamp( self:GetBallSize(), self.MinSize, self.MaxSize )

	lcolor.x = c.r * ( math.Clamp( lcolor.x, 0, 1 ) + 0.5 ) * 255
	lcolor.y = c.g * ( math.Clamp( lcolor.y, 0, 1 ) + 0.5 ) * 255
	lcolor.z = c.b * ( math.Clamp( lcolor.z, 0, 1 ) + 0.5 ) * 255
	if(IsValid(ply) and ply:IsPlayer()) then
		local a = ply:EyeAngles()
		a = Angle(0, a.y-90, a.z+90)
		render.DrawSprite( pos, size, size, Color( lcolor.x, lcolor.y, lcolor.z, 255 ) )
		cam.Start3D2D(pos + (Angle():Up() * 30), a, .5)
			draw.SimpleText(self:GetMyName(), "Trebuchet18", 0, 0, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		cam.End3D2D()
	end
end
