
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
--CC_DISABLE_GLOBAL = true
CC_DISABLE_GLOBAL = false

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1334,
    height = 750,
    autoscale = "FIXED_HEIGHT",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        --if ratio <= 1.77 then
        if ratio <= 1.778 then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            return {autoscale = "FIXED_WIDTH"}
        end
    end
}

--[[
保存cocos加载的原始lua文件
]]
CC_COCOS_SCRIPT_ARRAY = 
{
    
}

function CC_COCOS_SAVE_SCRIPT()
    for k,v in pairs(package.loaded) do
        table.insert(CC_COCOS_SCRIPT_ARRAY,tostring(k))
    end
end
