

local StickLib   = require("lib_analog_stick")
 
local screenW = display.contentWidth
local screenH = display.contentHeight
local Text        = display.newText( " ", screenW*.6, screenH-20, native.systemFont, 15 )
 
-- CREATE A SPACE SHIP
local Ship      = display.newGroup()
Ship.x          = screenW * .5
Ship.y          = screenH * .5
Tmp             = display.newLine(-8,0, 8,0)
Tmp.width       = 2
Tmp:setColor (255,255,255, 255)
Tmp:append   (0,-24, -8,0)
Ship:insert  (Tmp)
 
-- CREATE ANALOG STICK
MyStick = StickLib.NewStick( 
        {
        x             = screenW*.1,
        y             = screenH*.85,
        thumbSize     = 16,
        borderSize    = 32, 
        snapBackSpeed = .75, 
        R             = 255,
        G             = 255,
        B             = 255
        } )
 
----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------
local function main( event )
        
        -- MOVE THE SHIP
        MyStick:move(Ship, 7.0, true)
 
        -- SHOW STICK INFO
        Text.text = "ANGLE = "..MyStick:getAngle().."   DISTANCE = "..math.ceil(MyStick:getDistance()).."   PERCENT = "..math.ceil(MyStick:getPercent()*100).."%"
        
        print(Text);
        
end
 
Runtime:addEventListener( "enterFrame", main )