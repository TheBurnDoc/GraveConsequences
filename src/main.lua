local analogStick = require("lib_analog_stick")
local physics = require "physics"
local levels = require "levels"

physics.start()
physics.setGravity(0, 0)

-- Hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- Menu Screen
local menuScreenGroup
local menuBackground
local playButton
local menuTitle, teamTitle

-- Game Screen
local gameScreenGroup
local background
local foreground
local torch
local level = 0
local numLevels = 2
-- some nice images to show the game state
local gameWonImage, gameLostImage, objectiveImage, storyImage
local exitImageSprite

-- Misc. Variables
local _W = display.contentWidth / 2
local _H = display.contentHeight / 2
local fullWidth = display.contentWidth
local fullHeight = display.contentHeight

local tileSize = 32
local numTilesX = fullWidth / tileSize
local numTilesY = fullHeight / tileSize

-- Audio data
local soundtrack = audio.loadSound("audio/soundtrack.mp3")
local heartbeat = audio.loadSound("audio/Heartbeat(Official).mp3")
local laugh = audio.loadSound("audio/evillaugh.mp3")
--local scream = audio.loadSound("audio/scream.mp3")

-- "Lighting" mask (lol)
local lightingMask = graphics.newMask( "images/circlemask.png" )
local enableLighting = true

local map -- used to store the background image, declaration moved here from loadMap()

-- Debug Options
local showOverlay = false

-- Enemy Data
local enemy -- list of enemy 'objects'
local numberOfEnemies
local deltaX, deltaY
local maximumEnemyMovement = 2 -- how many pixels in x and y the enemy moves
local enemyMovementFrequency = 5 -- e.g. 3 will be every 3rd frame it moves
local enemyMovementCounter = 0
local character
local KILL_RANGE = 30 -- radius from player that enemy will kill within
 -- note this assumes that (x,y) of player and enemy are both centred on the sprite
local closestEnemyPosition = 10000; -- a convenience to store how close the nearest enemy to the player is. used by the heartbeat audio manger to set the volume
local currentHeartbeatVolume = 0.1


--Check if game is running in simulator
local isSimulator = "simulator" == system.getInfo("environment")


-- Main - It all starts here...

function main()
    math.randomseed( os.time() )
    mainMenu()  
end

-- Main Menu

function mainMenu()
    menuScreenGroup = display.newGroup()
    menuScreenBackground = display.newImage("images/spookycemetery.jpg", 0, 0, true)
    menuScreenBackground.x = _W
    menuScreenBackground.y = _H
    
    menuTitle = display.newImage("images/GraveConsequences.png", 0, 0)
    menuTitle.x = _W - 100 ; menuTitle.y = _H - 100
    
    teamTitle = display.newImage("images/team99.png", 0, 0)
    teamTitle.x = _W - 350; teamTitle.y = _H + 340
    
    tapToPlay = display.newImage("images/tapToStart.png", 0, 0)
    tapToPlay.x = _W; tapToPlay.y = _H + 220

    menuScreenGroup:insert(menuScreenBackground)
    menuScreenGroup:insert(menuTitle)
    menuScreenGroup:insert(teamTitle)
    menuScreenGroup:insert(tapToPlay)
    
    -- start the soundtrack on an infinite loop
    -- NB there is a Corona bug that you have to set the volume *before* you start to play
    audio.setVolume(1, { channel=2 } )
    audio.play(soundtrack, { channel=2, loops=-1, fadein=3000})

    menuScreenGroup:addEventListener("tap", loadGame)
    
end

-- Load Game
-- loadGame is triggered by a tap on the main menu screen
function loadGame(event)
    --if event.target.name == "playbutton" then
        --Start Game
        transition.to(menuScreenGroup, {time = 1000, alpha = 0, onComplete = addGameScreen})
    --end
end

-- Build Game Screen

function addGameScreen()
    
    --[[level = level + 1
    if level > numLevels then
        gameCompleted()
    end]]--
    
    exitImageSprite = display.newImage("images/ExitSprite.png", 0, 0)
    exitImageSprite.alpha = 0
    
    character     = display.newGroup()
    character.x   = fullWidth * 0.045
    character.y   = fullHeight * 0.95
    --Tmp           = display.newLine(-8,0, 8,0)
    --Tmp.width     = 2
    --Tmp:setColor (255,255,255, 255)
    --Tmp:append   (0,-24, -8,0)
    mainMan = display.newImage("images/mainCharacter32x32.png",-16,-32)
    mainMan:rotate(90);
    --mainMan.width = 32;
    --mainMan.height = 32;
    --mainMan:
    character:insert  (mainMan)
    --character:insert  (Tmp);
    
    joystick = analogStick.NewStick( 
        {
        x             = fullWidth - 50,
        y             = fullHeight - 50,
        thumbSize     = 16,
        borderSize    = 32, 
        snapBackSpeed = .75, 
        R             = 255,
        G             = 255,
        B             = 255
        } )
    
    maps = {"levelOne", "levelTwo"}
    
    --loadMap(maps[level])
    loadMap("levelOne")
    
    -- do some enemy initialisation
   enemy = {}
   local enemySprite = display.newImage("images/Grim_2.png", {alpha = 0})
   enemySprite.alpha = 0 -- hide the sprite
   --enemy[1] = { x = 100, y = 64, sprite = enemySprite }
   enemy[1] = { x = math.random(250,400), y = math.random(100,200), sprite = enemySprite }
   local enemySprite = display.newImage("images/Grim_2.png", {alpha = 0})
   enemySprite.alpha = 0 -- hide the sprite
   --enemy[2] = { x = 924, y = 64, sprite = enemySprite }
   enemy[2] = { x = math.random(700,1000), y = math.random(100,300), sprite = enemySprite }
   local enemySprite = display.newImage("images/Grim_2.png", {alpha = 0})
   enemySprite.alpha = 0 -- hide the sprite
   --enemy[3] = { x = 924, y = 700, sprite = enemySprite }
   enemy[3] = { x = math.random(700,1000), y = math.random(700,1000), sprite = enemySprite }
   local enemySprite = display.newImage("images/Grim_2.png", {alpha = 0})
   enemySprite.alpha = 0 -- hide the sprite
   --enemy[4] = { x = 500, y = 350, sprite = enemySprite }
   enemy[4] = { x = math.random(400,600), y = math.random(250,450), sprite = enemySprite }
   numberOfEnemies = 4

   exitImageSprite:toFront()
   
    -- dim the lights, if appropriate
    if enableLighting then
      map:setMask( lightingMask )
      map.maskScaleX = 2; map.maskScaleY = 2;
    end
    
    startGame()
    
end

-- Load Map

function loadMap(mapName)
    
    local levelMapper = {levelOne = levelOneArray,
                         levelTwo = levelOneArray}

    currentLevel = levelMapper[mapName]
    
    -- Loading image for sample map
    map = display.newImage("images/" .. mapName .. ".png",0,0);
    
    for x = 1, numTilesX do
        for y = 1, numTilesY do
            -- S is a solid block
            if currentLevel[y][x] == "S" then
                rect = display.newRect((x-1)*tileSize, (y-1)*tileSize, 
                        tileSize, tileSize);
                physics.addBody(rect, "static", {density = 1, friction = 0, bounce = 0})
                if showOverlay then
                    rect:setFillColor(150, 200);
                else
                    rect:setFillColor(255, 0);
                end
            elseif currentLevel[y][x] == "X" then
                local gridCoords = getRandomExitPosition()
                print("Random exit: " .. gridCoords.exitX .. "," .. gridCoords.exitY)
                
                finishLine = display.newRect( (gridCoords.exitX-1)*tileSize, (gridCoords.exitY-1)*tileSize, tileSize, tileSize )
                
                exitImageSprite.x = (gridCoords.exitX - 1) * tileSize + 16
                exitImageSprite.y = (gridCoords.exitY - 1) * tileSize + 16
                exitImageSprite.alpha = 0.1
                
                --[[
                finishLine = display.newRect((x-1)*tileSize, (y-1)*tileSize, 
                        tileSize, tileSize);
                ]]--        
                        
                physics.addBody(finishLine, "static", {density = 0, friction = 0, bounce = 0})
                finishLine.isSensor = true
                
                
                if showOverlay then
                    finishLine:setFillColor(255, 200)
                else
                    finishLine:setFillColor(255, 0)
                end
                
            end
        end
    end
end

function getRandomExitPosition()
  -- Need to choose the exit position randomly
  -- need it to be in the top-left, top-right or bottom-left quadrant
  local quadrant
  local x, y
  local foundSpot = false
  
  while not foundSpot do
     quadrant = math.random(3)
     if quadrant == 1 then
        x = math.random(8,16) -- 1,16
        y = math.random(1,6) -- 1,12
     elseif quadrant == 2 then
        x = math.random(20,32) -- 17,32
        y = math.random(1,12)  -- 1,12
     elseif quadrant == 3 then
        x = math.random(20,32) -- 17,32
        y = math.random(13,24) -- 13,24
     elseif quadrant == 4 then
        x = math.random(1,16)
        y = math.random(13,24)
     end
     if currentLevel[y][x] ~= "S" then
       foundSpot = true
     end
  end -- while ~foundSpot

  local gridCoords = { exitX = x, exitY = y }
  return gridCoords

end -- getRandomExitPosition()

-- gameLoop() called every frame and updates the state of the objects we are controlling manually
function gameLoop()
    
    joystick:move(character, 1.5, true)
    
    -- (Can't work out how to set the light without hardcoding the offset :-s)
    map.maskX = character.x - 512; map.maskY = character.y - 384
    
    updateEnemyPosition()
    
    checkEnemyCollisions()
    
    updateAudioVolume()
    
    distanceToExit = math.sqrt( (character.x - exitImageSprite.x)^2 + (character.y - exitImageSprite.y)^2 )
    if distanceToExit < 150 then
      exitImageSprite.alpha = 0.9
    else
      exitImageSprite.alpha = 0.1
    end
end


function gameCompleted()
    --[[completedText = display.newText("Game Completed", 0, 0, "Arial", 72)
    completedText:setReferencePoint(display.CenterReferencePoint)
    completedText.x = _W
    completedText.Y = _H]]--
    gameWonImage = display.newImage("images/scroll.png", 0, 0)
	gameWonImage.x = _W
	gameWonImage.y = _H
    gameListeners("remove")
    --[[
    storyImage = display.newImage("images/EndGameText.png", 0, 0)
    storyImage.x = _W; storyImage.y = _H]]--
    
    audio.stop( {channel=1} )
    audio.stop( {channel=2} )
    display.remove(mainMan)
    --display.remove(enemySprite.sprite)

	gameWonImage:addEventListener("tap", restartGame)
end

function restartGame( event )
    gameWonImage:removeSelf()
    gameWonImage = nil
    map:removeSelf()
    map = nil
    character:removeSelf()
    character = nil
    exitImageSprite:removeSelf(); exitImageSprite = nil
    removeEnemySprites()
	mainMenu()
end

-- gameOver is called when the player gets too close to a grim reaper
function gameOver()
    -- Angus' death notification
    --[[gameLostImage = display.newImage("images/deathImage.png", 0, 0)
	gameLostImage.x = _W
	gameLostImage.y = _H]]--
	
	gameListeners("remove")

	-- Ronan's death notification
	soul_take_image = display.newImage("images/soul_take.png", 0, 0)
	audio.stop( {channel = 1} )
	audio.stop( {channel = 2} )
	
	--audio.setVolume(0.5, { channel=4 })
	--audio.play( scream, { channel=4 } )
	
	audio.setVolume(0.5, { channel=3 })
	audio.play( laugh, { channel=3 } )
	audio.fadeOut( {channel = 3, time = 4000} )
	
	replayScreenGroup = display.newGroup()
	replayScreenGroup:insert(soul_take_image)
	replayScreenGroup:addEventListener("tap", onObjectTouch)

	
	--transition.to(gameLostImage, {time = 500, delay=2000, alpha = 1.0, onComplete=gameOver_displayReaper} )
end -- gameOver function

--[[
function gameOver_displayReaper()
	-- Ronan's death notification
	soul_take_image = display.newImage("images/soul_take.jpg", 0, 0)
	audio.stop( {channel = 1} )
	audio.stop( {channel = 2} )
		
	audio.setVolume(0.5, { channel=1 })
	audio.play( laugh, { channel=1, duration=1500, onComplete=gameOverText } )
	
	replayScreenGroup = display.newGroup()
	replayScreenGroup:insert(soul_take_image)
	replayScreenGroup:addEventListener("tap", onObjectTouch)
end -- gameOver function]]--

function gameOverText()
    textObj = display.newText("The Grim Reaper has taken your soul!", 0,0, "Helvetica", 30);
    textObj:setReferencePoint(display.CenterReferencePoint);
    textObj.y = 500
    textObj.x = 500

    play_again = display.newText("Tap to play again", 0,0, "Helvetica", 30);
    play_again:setReferencePoint(display.CenterReferencePoint);
    play_again.y = 550
    play_again.x = 550
end -- gameOverText function

--clean up after last level
function onObjectTouch( event)
    soul_take_image:removeSelf(); soul_take_image = nil
    character:removeSelf(); character = nil
    map:removeSelf(); map = nil
    removeEnemySprites()
    exitImageSprite:removeSelf(); exitImageSprite = nil
    --gameLostImage:removeSelf(); gameLostImage = nil
    
    -- possible if the player is enthusiastic the play_again and textObj are nil
    --[[if play_again ~= nil then
	    play_again:removeSelf(); play_again = nil
	end
	if textObj ~= nil then
	    textObj:removeSelf(); textObj = nil
	end]]--
    
    --display.remove(gameLostImage)
    --[[display.remove(textObj)
    display.remove(play_again)
    display.remove(map)
    display.remove(currentEnemy.sprite)
    display.remove(character)
    display.remove(objectiveImage)]]--
    loadGame()
end

function startGame()
    physics.addBody(character, "dynamic", {density = 1, friction = 0, bounce = 0})
    joystick:toFront()
    character:toFront()
    gameListeners("add")
    
    -- start the heartbeat audio on an infinite loop
    audio.setVolume(0.5, { channel=1 } )
    audio.play(heartbeat, { channel=1, loops=-1})
    
    -- show the user some helpful tips
    objectiveImage = display.newImage("images/objectiveImage.png", 0, 0)
    -- hardcode the position like a pro
    objectiveImage.x = 725
    -- fade the instructions over 15 seconds
    transition.to(objectiveImage, {time=11000, alpha = 0})
end

function gameListeners(event)
    if event == "add" then
        Runtime:addEventListener("enterFrame", gameLoop)
        finishLine:addEventListener("collision", gameCompleted)
    elseif event == "remove" then
        Runtime:removeEventListener("enterFrame", gameLoop)
        finishLine:removeEventListener("collision", gameCompleted)
    end
end

function removeEnemySprites()
  local currentEnemy
  for i = 1, numberOfEnemies do
    currentEnemy = enemy[i]
    currentEnemy.sprite:removeSelf()
    currentEnemy.sprite = nil
  end
end -- removeEnemySprites()

-- updateEnemyPosition loops through all enemies and converges them on the player
-- enemies can move through walls! (cheating %^£$&£)
function updateEnemyPosition()

  -- decide if the enemy should move or not
  enemyMovementCounter = enemyMovementCounter + 1
  if enemyMovementCounter < enemyMovementFrequency then
    return
  end
  -- decided the enemy should move
  enemyMovementCounter = 0
  
  -- loop through all enemies and update positions
  -- print(maximumEnemyMovement)
    
  for i = 1, numberOfEnemies do
    currentEnemy = enemy[i]
    
    deltaX = character.x - currentEnemy.x
    deltaY = character.y - currentEnemy.y
    
    if deltaX < 0 then
      deltaX = -maximumEnemyMovement
    else
      deltaX = maximumEnemyMovement
    end
    
    if deltaY < 0 then
      deltaY = -maximumEnemyMovement
    else
      deltaY = maximumEnemyMovement
    end
    
    currentEnemy.x = currentEnemy.x + deltaX
    currentEnemy.y = currentEnemy.y + deltaY
    
    currentEnemy.sprite.x = currentEnemy.x
    currentEnemy.sprite.y = currentEnemy.y
--    enemySprite.x = currentEnemy.x
--    enemySprite.y = currentEnemy.y

    --print("Player @ (" .. character.x .. "," .. character.y .. "), Enemy @ (" .. enemy[1].x .. "," .. enemy[1].y .. ")") 
    
  end
  
end -- function updateEnemyPosition

-- checkEnemyCollisions manually checks in any enemy is near the player character
-- also updates the closestEnemyPosition variable
function checkEnemyCollisions()

  -- set closestEnemyPosition to a stupidly high value to ensure that it is correctly updated each frame
  closestEnemyPosition = 10000

  -- Go through all the enemy objects and check radius 
  for i = 1, numberOfEnemies do
  
    currentEnemy = enemy[i]
  
    -- R is the absolute distance (in pixels) between the player and the current enemy
    R = math.sqrt( (character.x - currentEnemy.x)^2 + (character.y - currentEnemy.y)^2 )
    
    -- Normalise R to set the opacity of the sprite
    -- ... or just hardcode it
    if R > 150 then
    	currentEnemy.sprite.alpha = 0
    elseif R > 100 then
        currentEnemy.sprite.alpha = 0.3
    elseif R > 75 then
        currentEnemy.sprite.alpha = 0.6
    else -- must be close!
        currentEnemy.sprite.alpha = 1
    end
    
    -- Set the property of the closestEnemyPosition, which is used by the audio to set the volume
    if R < closestEnemyPosition then
      closestEnemyPosition = R
    end
    
    -- if the enemy is within the kill range then the player is dead
    if R <= KILL_RANGE then
      gameOver()
      return true
    end
    
  end
  
end -- checkEnemyCollisions function

-- updateAudioVolume adjusts the volume of the heartbeat sound effect based on the normalised proximity of the closest enemy - enemy close = heartbeat loud
-- NB tried to make this a gradual change, but the audio crackles on repeated calls to setVolume() so just have 'loud' and 'quiet'
function updateAudioVolume()
  -- audio volume parameter is between 0 and 1
  
  -- calculate the normalised distance of the closestEnemyPosition
  -- hard code some distances
  -- if 
  
  --[[normalisedDistance = -0.002 * closestEnemyPosition + 1.2
  if normalisedDistance > 1 then
    normalisedDistance = 1
  elseif normalisedDistance < 0.1 then
    normalisedDistance = 0.1
  end]]--
  -- print("Closest pos = " .. closestEnemyPosition .. ", current heartbeat plan = " .. currentHeartbeatVolume .. ", actual volume = " .. audio.getVolume( {channel=1} ))
  
  if closestEnemyPosition <= 130 and currentHeartbeatVolume ~= 1 then
    -- print("panic")
    audio.setVolume(1.0, {channel=1} )
    currentHeartbeatVolume = 1
  end
  if closestEnemyPosition > 130 and currentHeartbeatVolume ~= 0.5 then
    -- print("relax")
    audio.setVolume(0.5, {channel=1})
    currentHeartbeatVolume = 0.5
  end
  
  -- audio.setVolume(normalisedDistance, { channel = 1 } )
  
  -- print(normalisedDistance)
  
end -- function updateAudioVolume


--[[ NONE SHALL PASS ]]--

-- Debug Code - Not for Production Use
local monitorMem = function()
    -- collectgarbage()
    -- print( "MemUsage: " .. collectgarbage("count") )

    local textMem = system.getInfo( "textureMemoryUsed" ) / (1024*1024)
    --print( "TexMem:   " .. textMem )
end

Runtime:addEventListener("enterFrame", monitorMem)

main()
