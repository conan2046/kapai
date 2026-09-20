local root = arg[1] or '.'
local sent, states, resets = {}, {}, 0
local protocol = { HERO=24, UPDATE_PET_INFO=70, UPDATE_PET=71, FORMATION=48 }
function protocol.newMessage(command)
    local m={command=command,data={}}
    function m:WriteByte(v) self.data[#self.data+1]={'byte',v} end
    function m:WriteWord(v) self.data[#self.data+1]={'word',v} end
    return m
end
package.preload['Protocol']=function()return protocol end
package.preload['Hero.EquipmentController']=function()return {} end
package.preload['World.WorldController']=function()return {} end
package.preload['Hero.LegacyFormationModel']=function()return {Reset=function()end} end
Bridge={Send=function(_,m)sent[#sent+1]=m end,
    SetHeroBuildState=function(_,...)states[#states+1]={...} end,
    ResetHeroBuildUi=function()resets=resets+1 end,
    HasCommandLineFlag=function()return false end}
local controller=assert(loadfile(root..'/unityclient/Assets/ProjectX/Resources/Lua/Hero/HeroController.lua.txt'))()
controller.requestBuild(10,-1,0)
assert(sent[1].command==24 and #sent[1].data==2)
assert(sent[1].data[1][2]==40 and sent[1].data[2][2]==10)
controller.requestBuild(10,2,5)
assert(#sent[2].data==4 and sent[2].data[1][2]==41)
assert(sent[2].data[3][2]==2 and sent[2].data[4][2]==5)
local function response(values)
    local m={Remaining=#values,index=0}
    local function read(self)
        self.index=self.index+1;self.Remaining=self.Remaining-1
        return values[self.index]
    end
    m.ReadWord,m.ReadByte,m.ReadString=read,read,read
    return m
end
assert(controller.onPacket(24,response({40,10,1,2,5,2,101,3,102,7})))
assert(states[1][1]==10 and states[1][2]==2 and states[1][3]==5 and states[1][4]=='')
assert(states[1][5]=='101:3;102:7')
assert(controller.onPacket(24,response({41,10,0,'save failed'})))
assert(states[2][4]=='save failed')
assert(controller.onPacket(24,response({40,10,1,0,0,0,'trailing'})))
assert(states[3][4]~='')
controller.reset()
assert(resets==1)
print('PASS: real HeroController query/set serialization, response success/rejection/trailing-data and disconnect reset')
