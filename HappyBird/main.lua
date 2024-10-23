-- main.lua

-- 启动物理引擎
local physics = require("physics")
physics.start()
physics.setGravity(0, 9.8)

local resetButton

-- 背景设置
local background1 = display.newImageRect("background.png", display.contentWidth, display.contentHeight)
background1.x = display.contentCenterX
background1.y = display.contentCenterY

local background2 = display.newImageRect("background.png", display.contentWidth, display.contentHeight)
background2.x = display.contentCenterX + display.contentWidth
background2.y = display.contentCenterY

-- 背景滚动速度
local scrollSpeed = 2

-- 循环滚动函数
local function scrollBackground()
	print( background1.x )
    background1.x = background1.x - scrollSpeed
    background2.x = background2.x - scrollSpeed

    -- 判断背景是否超出屏幕并重置位置
    if background1.x < -background1.width / 2 then
        background1.x = display.contentCenterX
        background2.x = display.contentCenterX + display.contentWidth
    end
    
end

-- 每帧调用滚动函数
Runtime:addEventListener("enterFrame", scrollBackground)

local backgroundMusic = audio.loadStream("back.mp3")
local musicChannel = audio.play(backgroundMusic, { loops = -1 })  -- 播放并保存通道ID

local shortSound = audio.loadSound("click.mp3")  -- 加载短音效

local endSound = audio.loadStream(  "end.mp3" )        -- 结束音乐




-- 小鸟
local bird = display.newImageRect("bird.png", 50, 50)
bird.x = 100
bird.y = display.contentCenterY
bird.myName = "bird"
physics.addBody(bird, { radius = 25, bounce = 0.3 })

-- 地面
local ground = display.newImageRect( "ground.png",display.contentWidth*2, 100)
ground.x , ground.y = display.contentCenterX, display.contentHeight - 50
--ground:setFillColor(0, 0, 0)
ground.myName = "ground"
physics.addBody(ground, "static")

-- 顶部
local heaven = display.newRect(display.contentCenterX, - 50, display.contentWidth, 100)
heaven:setFillColor(0, 1, 0)
heaven.myName = "heaven"
physics.addBody(heaven, "static")


-- 分数
local score = 0
local scoreText = display.newText("Score: " .. score, display.contentCenterX/2, 50, native.systemFont, 36)
scoreText:setFillColor( 0.5, 0.2, 0.8, 0.2 )
-- 更新分数
local function updateScore()
    score = score + 1
    scoreText.text = "Score: " .. score
end


-- 判断死亡函数
local function gameOver()
	audio.play(endSound)
	resetButton.isVisible = true  -- 复位按钮

    print("Game Over!")
    -- 取消每帧调用的滚动函数
	Runtime:removeEventListener("enterFrame", scrollBackground)
	Runtime:removeEventListener("enterFrame", onEnterFrame)

	-- 停止特定的音乐
	audio.stop(musicChannel)

    -- 停止物理引擎
    physics.pause()
    -- 这里可以添加更多游戏结束时的逻辑，比如显示重试按钮或重新开始游戏
end

-- 碰撞处理函数
local function onCollision(event)
    if event.phase == "began" then
        if (event.object1.myName == "bird" and event.object2.myName == "obstacle") or
           (event.object1.myName == "obstacle" and event.object2.myName == "bird") or 
           (event.object1.myName == "bird" and event.object2.myName == "obstacleup") or 
           (event.object1.myName == "obstacleup" and event.object2.myName == "bird") then
            gameOver()  -- 调用死亡函数
        end
    end
end

Runtime:addEventListener( "collision", onCollision )

-- 障碍物生成
local function createObstacle()
    local obstacleHeight = math.random(50, 150)
    local obstacle = display.newImageRect("bottom.png",50, obstacleHeight)
    obstacle.x , obstacle.y = display.contentWidth, display.contentHeight - 100
    obstacle:setFillColor(1, 0.6, 0)
    obstacle.myName = "obstacle"
    physics.addBody(obstacle, "dynamic", { isSensor = true })
    obstacle:applyForce(-20, -20, obstacle.x, obstacle.y)

    local obstacleup = display.newImageRect("top.png",50, obstacleHeight)
    obstacleup.x , obstacleup.y = display.contentWidth, -100
    obstacleup:setFillColor(0.2, 0.6, 0.2)
    obstacleup.myName = "obstacleup"
    physics.addBody(obstacleup, "dynamic", { isSensor = true })
    obstacleup:applyForce(-10, 0, obstacle.x, obstacle.y)
    
end

-- 点击屏幕控制小鸟飞
local function flap(event)
    if event.phase == "began" then
        bird:setLinearVelocity(0, -200)
    end
    if event.phase == "ended" then  -- 确保是点击结束时播放
        audio.play(shortSound)  -- 播放短音效
    end
end

-- 障碍物生成定时器
timer.performWithDelay(2000, createObstacle, 0)

-- 清除超出屏幕的障碍物
local function onEnterFrame()
    local stage = display.getCurrentStage()
    if stage then
        for i = stage.numChildren, 1, -1 do
            local obj = stage[i]        
            -- 判断障碍物是否超出屏幕
            if obj.x < -50 and (obj.myName=="obstacle" or  obj.myName=="obstacleup") then  -- 当障碍物的 x 位置小于 -50 时，认为超出屏幕
                obj:removeSelf()  -- 移除障碍物
                obj = nil
                updateScore()
            end
            

        end
    end
end

--游戏重置的时候清理

local function clearEvent()       
    local stage = display.getCurrentStage()
    if stage then
        for i = stage.numChildren, 1, -1 do
            local obj = stage[i]        
            -- 判断障碍物是否超出屏幕
            if obj.myName=="obstacle" or obj.myName=="obstacleup" then  -- 当障碍物的 x 位置小于 -50 时，认为超出屏幕
                obj:removeSelf()  -- 移除障碍物
                obj = nil
                updateScore()
            end
            

        end
    end
end


local function onKeyEvent(event)
    if (event.phase == "down" and event.keyName == "space") then
        -- 在这里添加要执行的代码
        audio.play(shortSound)  -- 播放短音效
        print("空格键被按下")
        bird:setLinearVelocity(0, -200)
    end
    return false  -- 返回 false 以继续传播事件
end

-- 激活键盘事件
system.activate("keyboard")
Runtime:addEventListener("key", onKeyEvent)


local function resetGame()
    -- 在这里重置游戏状态，例如重新加载场景或初始化变量
    print("游戏重置")
    musicChannel = audio.play(backgroundMusic, { loops = -1 })  -- 播放并保存通道ID
    clearEvent()
	physics.start()
	score = 0
	updateScore()
	Runtime:addEventListener("enterFrame", scrollBackground)
    -- 例如，重置角色位置
    -- character.x = display.contentCenterX
    -- character.y = display.contentCenterY
end

local function onTouch(event)
    if event.phase == "ended" then
    	resetButton.isVisible = false  -- 隐藏复位按钮

        resetGame()  -- 调用重置函数
    end
    return true
end

-- 创建复位按钮
resetButton = display.newText("重新开始", display.contentCenterX, display.contentCenterY, native.systemFont, 32)
resetButton:setFillColor(1, 0, 0.8)  -- 设置文本颜色为红色
resetButton:addEventListener("touch", onTouch)
resetButton.isVisible = false  -- 隐藏复位按钮




-- 事件监听
Runtime:addEventListener("touch", flap)
Runtime:addEventListener("enterFrame", onEnterFrame)
