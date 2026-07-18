# ImodAnim Lua 调用清单

> 由 `python tools/ui_migration/imod_usage.py` 生成；只统计去除 Lua 注释后的活动代码。

## 汇总

| 指标 | 数量 |
|---|---:|
| 调用 | 208 |
| 构造入口 | 67 |
| 源文件 | 41 |
| 固定资源路径 | 24 |
| 动态加载表达式 | 38 |
| 固定路径可解析 | 18 |
| 固定路径缺资源 | 6 |

## 固定资源路径

| 路径 | 状态 |
|---|---|
| `effect/biaobai/butflay` | 缺 ANI/PNG |
| `effect/hehua/hehua_yu` | 缺 ANI/PNG |
| `item/equipLight` | 可解析 |
| `jiazaiquan` | 可解析 |
| `res2/animation/battle/quality2` | 可解析 |
| `res2/animation/battle/quality7` | 可解析 |
| `res2/fx/choukaluzi` | 可解析 |
| `res2/fx/choukashenjiang` | 可解析 |
| `res2/fx/jieshourenwu` | 可解析 |
| `res2/fx/loading` | 可解析 |
| `res2/fx/lvdian` | 可解析 |
| `res2/fx/qiandao` | 可解析 |
| `res2/fx/renwulan` | 可解析 |
| `res2/fx/shengji_yuan` | 可解析 |
| `res2/fx/shengxing` | 可解析 |
| `res2/fx/shenqizhanshi` | 可解析 |
| `res2/fx/wancheng` | 可解析 |
| `res2/fx/yueka` | 可解析 |
| `res2/fx/zhandoukaishi` | 可解析 |
| `res2/skill_name/battle_hero_anger_boom` | 缺 ANI/PNG |
| `res2/skill_name/battle_hero_anger_burning` | 缺 ANI/PNG |
| `res2/skill_name/battle_pet_anger_boom` | 缺 ANI/PNG |
| `res2/skill_name/battle_pet_anger_burning` | 缺 ANI/PNG |
| `UI/role` | 可解析 |

## 动态加载表达式

| 位置 | 调用 |
|---|---|
| `Common/Utils.lua:936` | `ImodAnim:createWithFileSync(str)` |
| `Common/Utils.lua:1298` | `ImodAnim:createWithFileSync(path)` |
| `Common/Utils.lua:3133` | `pAnim:initAnimWithNameSync(pngStr)` |
| `Common/Utils.lua:3732` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `Common/Utils.lua:3742` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `Data/PetkaPaiManager.lua:1378` | `_pBgAni:initAnimWithNameSync(bgAnim)` |
| `Logic/LBattleLogic.lua:1989` | `ImodAnim:createWithFile(skillPath)` |
| `Logic/LBattleLogic.lua:2797` | `ImodAnim:createWithFile(skillPath)` |
| `Logic/LBattleLogic.lua:4279` | `ImodAnim:createWithFile(skillPath)` |
| `Logic/LResLogic.lua:325` | `ImodAnim:createWithFileSync(filePath)` |
| `View/Activity/DonateUI.lua:215` | `self.m_pAniImod:initAnimWithName(png, ani)` |
| `View/Battle/BattleUnitNode.lua:300` | `self.m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/Battle/BattleUnitNode.lua:343` | `self.m_pModelAni:initAnimWithName(aniFile)` |
| `View/Battle/BattleUnitNode.lua:373` | `self.m_pModelAni:initAnimWithName(aniFile)` |
| `View/Battle/BattleUnitNode.lua:386` | `modelAni:initAnimWithName(aniFile)` |
| `View/Battle/BattleUnitNode.lua:851` | `ImodAnim:createWithFileSync(fileName)` |
| `View/Battle/BattleUnitNode.lua:1030` | `ImodAnim:createWithFileSync(pngFileName)` |
| `View/Battle/BattleUnitNode.lua:1283` | `modelAni:addAnimWithName(WeaponPng .. suffix .. ".png", WeaponPng .. suffix .. ".ani")` |
| `View/Battle/BattleUnitNode.lua:1725` | `self.m_pModelAni:initAnimWithName(aniFile)` |
| `View/Battle/BattleUnitNode.lua:1767` | `modelAni:initAnimWithName(aniFile)` |
| `View/Battle/BattleUnitNode.lua:1863` | `ImodAnim:createWithFile(aniFile)` |
| `View/Battle/BattleUnitNode.lua:1867` | `modelAni:initAnimWithName(aniFile)` |
| `View/Common/PetFormationUI.lua:395` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:633` | `self.m_pAniImod[i]:initAnimWithName(png, ani)` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:751` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/FaBao/FaBaoCultivateMainUI.lua:545` | `self.m_pAniImod[i]:initAnimWithName(png, ani)` |
| `View/HappyDraw/SingleDrawResultUI.lua:423` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/HappyDraw/TenDrawResultUI.lua:231` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/HeroBook/HeroBookUI.lua:245` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/JingJie/jingjieUI.lua:267` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/KaPaiPet/PetBagPetSubUI.lua:444` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/Login/LoginBgUI.lua:60` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/Login/RoleCreateUI.lua:123` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |
| `View/Login/RoleCreateUI.lua:136` | `self.m_pCreateImod:initAnimWithNameSync(pngStr)` |
| `View/Monopoly/MonopolyUI.lua:470` | `self.m_pCreateImod:initAnimWithName(pngStr, aniStr)` |
| `View/StageGoal/ShenqiGiftUI.lua:218` | `self.m_pArtifactImod:initAnimWithName(png, ani)` |
| `View/WorldMap/CurMapSubUI.lua:484` | `ImodAnim:createWithFileSync(fileName)` |
| `View/XueZhan/XueZhanMainUI.lua:131` | `m_pBgAni:initAnimWithNameSync(bgAnim)` |

## 全部活动调用

| 位置 | 接收者 | 方法 | 参数 |
|---|---|---|---|
| `Common/Utils.lua:936` | `ImodAnim` | `createWithFileSync` | `str` |
| `Common/Utils.lua:1298` | `ImodAnim` | `createWithFileSync` | `path` |
| `Common/Utils.lua:1305` | `pCreateImod` | `PlayActionRepeat` | `0` |
| `Common/Utils.lua:1662` | `ImodAnim` | `createWithFileSync` | `"item/equipLight"` |
| `Common/Utils.lua:1663` | `imod` | `PlayActionRepeat` | `0, 0.1` |
| `Common/Utils.lua:3127` | `ImodAnim` | `create` | `` |
| `Common/Utils.lua:3133` | `pAnim` | `initAnimWithNameSync` | `pngStr` |
| `Common/Utils.lua:3134` | `pAnim` | `PlayNewAction` | `0, true` |
| `Common/Utils.lua:3731` | `ImodAnim` | `create` | `` |
| `Common/Utils.lua:3732` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `Common/Utils.lua:3733` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `Common/Utils.lua:3741` | `ImodAnim` | `create` | `` |
| `Common/Utils.lua:3742` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `Common/Utils.lua:3743` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `Data/PetkaPaiManager.lua:1377` | `ImodAnim` | `create` | `` |
| `Data/PetkaPaiManager.lua:1378` | `_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `Data/PetkaPaiManager.lua:1379` | `_pBgAni` | `PlayAction` | `0, time` |
| `Logic/LBattleLogic.lua:1989` | `ImodAnim` | `createWithFile` | `skillPath` |
| `Logic/LBattleLogic.lua:1993` | `ani` | `setFlippedX` | `flipx` |
| `Logic/LBattleLogic.lua:1997` | `ani` | `PlayNewAction` | `0` |
| `Logic/LBattleLogic.lua:1998` | `ani` | `SetSpeedScale` | `1/self.m_speed` |
| `Logic/LBattleLogic.lua:2024` | `ani` | `registerScriptEndCBHandler` | `LBattleLogic.BTSkillPlayEndCallback` |
| `Logic/LBattleLogic.lua:2034` | `ani` | `PlayNewAction` | `0, true` |
| `Logic/LBattleLogic.lua:2035` | `ani` | `SetSpeedScale` | `1/self.m_speed` |
| `Logic/LBattleLogic.lua:2797` | `ImodAnim` | `createWithFile` | `skillPath` |
| `Logic/LBattleLogic.lua:2799` | `ani` | `setFlippedX` | `flipx` |
| `Logic/LBattleLogic.lua:2803` | `ani` | `PlayNewAction` | `0` |
| `Logic/LBattleLogic.lua:2804` | `ani` | `SetSpeedScale` | `1/self.m_speed` |
| `Logic/LBattleLogic.lua:2819` | `ani` | `registerScriptEndCBHandler` | `LBattleLogic.BTSkillPlayEndCallback` |
| `Logic/LBattleLogic.lua:2829` | `ani` | `PlayNewAction` | `0, true` |
| `Logic/LBattleLogic.lua:2830` | `ani` | `SetSpeedScale` | `1/self.m_speed` |
| `Logic/LBattleLogic.lua:3285` | `ImodAnim` | `createWithFileSync` | `"res2/fx/loading"` |
| `Logic/LBattleLogic.lua:3292` | `self.m_pBtUnitAppearAnis[ind]` | `PlayAction` | `0` |
| `Logic/LBattleLogic.lua:3293` | `self.m_pBtUnitAppearAnis[ind]` | `registerScriptEndCBHandler` | `LBattleLogic.AppearAniPlayEnd` |
| `Logic/LBattleLogic.lua:3296` | `self.m_pBtUnitAppearAnis[ind]` | `PlayAction` | `0` |
| `Logic/LBattleLogic.lua:3297` | `self.m_pBtUnitAppearAnis[ind]` | `registerScriptEndCBHandler` | `LBattleLogic.AppearAniPlayEnd` |
| `Logic/LBattleLogic.lua:3592` | `ImodAnim` | `createWithFileSync` | `"res2/fx/zhandoukaishi"` |
| `Logic/LBattleLogic.lua:3597` | `self.m_startAni` | `stop` | `` |
| `Logic/LBattleLogic.lua:3600` | `self.m_startAni` | `registerScriptEndCBHandler` | `AniPlayEnd` |
| `Logic/LBattleLogic.lua:3605` | `self.m_startAni` | `PlayAction` | `0` |
| `Logic/LBattleLogic.lua:4279` | `ImodAnim` | `createWithFile` | `skillPath` |
| `Logic/LResLogic.lua:325` | `ImodAnim` | `createWithFileSync` | `filePath` |
| `Logic/LUILogic.lua:597` | `ImodAnim` | `createWithFileSync` | `"res2/fx/jieshourenwu"` |
| `Logic/LUILogic.lua:604` | `ani` | `PlayNewAction` | `0` |
| `Logic/LUILogic.lua:605` | `ani` | `registerScriptEndCBHandler` | `AniPlayEnd` |
| `Logic/LUILogic.lua:626` | `ImodAnim` | `createWithFileSync` | `"res2/fx/wancheng"` |
| `Logic/LUILogic.lua:633` | `ani` | `PlayNewAction` | `0` |
| `Logic/LUILogic.lua:634` | `ani` | `registerScriptEndCBHandler` | `AniPlayEnd` |
| `View/Activity/DonateUI.lua:79` | `ImodAnim` | `create` | `` |
| `View/Activity/DonateUI.lua:215` | `self.m_pAniImod` | `initAnimWithName` | `png, ani` |
| `View/Activity/DonateUI.lua:216` | `self.m_pAniImod` | `PlayNewAction` | `0, true` |
| `View/Battle/BattleUnitNode.lua:35` | `ImodAnim` | `create` | `` |
| `View/Battle/BattleUnitNode.lua:38` | `ImodAnim` | `create` | `` |
| `View/Battle/BattleUnitNode.lua:206` | `ImodAnim` | `create` | `` |
| `View/Battle/BattleUnitNode.lua:300` | `self.m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/Battle/BattleUnitNode.lua:301` | `self.m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/Battle/BattleUnitNode.lua:343` | `self.m_pModelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:348` | `self.m_pModelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:349` | `self.m_pModelAni` | `PlayNewAction` | `AnimateIdx, loop` |
| `View/Battle/BattleUnitNode.lua:373` | `self.m_pModelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:378` | `self.m_pModelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:379` | `self.m_pModelAni` | `PlayNewAction` | `AnimateIdx, true` |
| `View/Battle/BattleUnitNode.lua:380` | `self.m_pModelAni` | `SetSpeedScale` | `1` |
| `View/Battle/BattleUnitNode.lua:386` | `modelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:387` | `modelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:394` | `modelAni` | `PlayNewAction` | `AnimateIdx, true` |
| `View/Battle/BattleUnitNode.lua:851` | `ImodAnim` | `createWithFileSync` | `fileName` |
| `View/Battle/BattleUnitNode.lua:852` | `buffNode` | `PlayActionRepeat` | `0` |
| `View/Battle/BattleUnitNode.lua:1030` | `ImodAnim` | `createWithFileSync` | `pngFileName` |
| `View/Battle/BattleUnitNode.lua:1033` | `QualityEffect` | `PlayActionRepeat` | `0, 0.1` |
| `View/Battle/BattleUnitNode.lua:1283` | `modelAni` | `addAnimWithName` | `WeaponPng .. suffix .. ".png", WeaponPng .. suffix .. ".ani"` |
| `View/Battle/BattleUnitNode.lua:1612` | `ImodAnim` | `createWithFile` | `"res2/skill_name/battle_hero_anger_boom.png", "res2/skill_name/battle_hero_anger_boom.ani"` |
| `View/Battle/BattleUnitNode.lua:1613` | `imod` | `PlayAction` | `0` |
| `View/Battle/BattleUnitNode.lua:1625` | `ImodAnim` | `createWithFile` | `"res2/skill_name/battle_pet_anger_boom.png", "res2/skill_name/battle_pet_anger_boom.ani"` |
| `View/Battle/BattleUnitNode.lua:1626` | `imod` | `PlayAction` | `0` |
| `View/Battle/BattleUnitNode.lua:1645` | `ImodAnim` | `createWithFile` | `"res2/skill_name/battle_pet_anger_burning.png", "res2/skill_name/battle_pet_anger_burning.ani"` |
| `View/Battle/BattleUnitNode.lua:1646` | `imod` | `PlayAction` | `0` |
| `View/Battle/BattleUnitNode.lua:1657` | `ImodAnim` | `createWithFile` | `"res2/skill_name/battle_hero_anger_burning.png", "res2/skill_name/battle_hero_anger_burning.ani"` |
| `View/Battle/BattleUnitNode.lua:1658` | `imod` | `PlayAction` | `0` |
| `View/Battle/BattleUnitNode.lua:1725` | `self.m_pModelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:1726` | `self.m_pModelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:1733` | `self.m_pModelAni` | `PlayNewAction` | `AnimateIdx, loop` |
| `View/Battle/BattleUnitNode.lua:1734` | `self.m_pModelAni` | `SetSpeedScale` | `speed` |
| `View/Battle/BattleUnitNode.lua:1747` | `self.m_pModelAni` | `unregisterScriptEndCBHandler` | `` |
| `View/Battle/BattleUnitNode.lua:1751` | `self.m_pModelAni` | `registerScriptEndCBHandler` | `AniPlayEnd` |
| `View/Battle/BattleUnitNode.lua:1754` | `self.m_pModelAni` | `unregisterScriptEndCBHandler` | `` |
| `View/Battle/BattleUnitNode.lua:1767` | `modelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:1768` | `modelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:1775` | `modelAni` | `PlayNewAction` | `AnimateIdx, loop` |
| `View/Battle/BattleUnitNode.lua:1863` | `ImodAnim` | `createWithFile` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:1867` | `modelAni` | `initAnimWithName` | `aniFile` |
| `View/Battle/BattleUnitNode.lua:1870` | `modelAni` | `setFlippedX` | `IsFlipX` |
| `View/Battle/BattleUnitNode.lua:1880` | `modelAni` | `PlayNewAction` | `AnimateIdx, loop` |
| `View/Common/PetFormationUI.lua:394` | `ImodAnim` | `create` | `` |
| `View/Common/PetFormationUI.lua:395` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/Common/PetFormationUI.lua:396` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/Common/WaitAniUI.lua:135` | `ImodAnim` | `createWithFileSync` | `"jiazaiquan"` |
| `View/Common/WaitAniUI.lua:136` | `displayAni` | `PlayActionRepeat` | `0, 0.1, true` |
| `View/DailySign/DailySignUI.lua:290` | `ImodAnim` | `createWithFileSync` | `"res2/fx/qiandao"` |
| `View/DailySign/DailySignUI.lua:292` | `self.signdata.ani` | `PlayActionRepeat` | `0` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:629` | `ImodAnim` | `create` | `` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:633` | `self.m_pAniImod[i]` | `initAnimWithName` | `png, ani` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:663` | `self.m_pAniImod[i]` | `PlayNewAction` | `0, true` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:667` | `self.m_pAniImod[i]` | `PlayNewAction` | `0, false` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:737` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:739` | `m_pBgAni` | `PlayAction` | `0, time` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:750` | `ImodAnim` | `create` | `` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:751` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:753` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:755` | `m_pBgAni` | `PlayAction` | `0, time` |
| `View/EquipCultivate/EquipCultivateMainUI.lua:777` | `m_pBgAni` | `stop` | `` |
| `View/FaBao/FaBaoCultivateMainUI.lua:541` | `ImodAnim` | `create` | `` |
| `View/FaBao/FaBaoCultivateMainUI.lua:545` | `self.m_pAniImod[i]` | `initAnimWithName` | `png, ani` |
| `View/FaBao/FaBaoCultivateMainUI.lua:575` | `self.m_pAniImod[i]` | `PlayNewAction` | `0, true` |
| `View/FaBao/FaBaoCultivateMainUI.lua:579` | `self.m_pAniImod[i]` | `PlayNewAction` | `0, false` |
| `View/FuBenMap/FuBenDetailUI.lua:704` | `ImodAnim` | `createWithFile` | `"res2/animation/battle/quality2.png", "res2/animation/battle/quality2.ani"` |
| `View/FuBenMap/FuBenDetailUI.lua:705` | `imod` | `PlayAction` | `0` |
| `View/FuBenMap/FuBenDetailUI.lua:709` | `ImodAnim` | `createWithFile` | `"res2/animation/battle/quality7.png", "res2/animation/battle/quality7.ani"` |
| `View/FuBenMap/FuBenDetailUI.lua:710` | `imod` | `PlayAction` | `0` |
| `View/Global/SkillCellUI.lua:174` | `ImodAnim` | `createWithFileSync` | `"item/equipLight"` |
| `View/Global/SkillCellUI.lua:175` | `imod` | `PlayActionRepeat` | `0, 0.1` |
| `View/HappyDraw/HappyDrawUI.lua:632` | `ImodAnim` | `createWithFileSync` | `"res2/fx/choukaluzi"` |
| `View/HappyDraw/HappyDrawUI.lua:639` | `pAni` | `PlayAction` | `0` |
| `View/HappyDraw/SingleDrawResultUI.lua:422` | `ImodAnim` | `create` | `` |
| `View/HappyDraw/SingleDrawResultUI.lua:423` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/HappyDraw/SingleDrawResultUI.lua:424` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/HappyDraw/TenDrawResultUI.lua:230` | `ImodAnim` | `create` | `` |
| `View/HappyDraw/TenDrawResultUI.lua:231` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/HappyDraw/TenDrawResultUI.lua:232` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/HeroBook/HeroBookUI.lua:244` | `ImodAnim` | `create` | `` |
| `View/HeroBook/HeroBookUI.lua:245` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/HeroBook/HeroBookUI.lua:246` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/ImproveUI/ShowWingHorseUI.lua:71` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shenqizhanshi"` |
| `View/ImproveUI/ShowWingHorseUI.lua:74` | `pAnim` | `PlayActionRepeat` | `0` |
| `View/JingJie/jingjieUI.lua:264` | `ImodAnim` | `create` | `` |
| `View/JingJie/jingjieUI.lua:267` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/JingJie/jingjieUI.lua:270` | `m_pBgAni` | `PlayAction` | `0` |
| `View/KaPaiPet/PetBagPetSubUI.lua:443` | `ImodAnim` | `create` | `` |
| `View/KaPaiPet/PetBagPetSubUI.lua:444` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/KaPaiPet/PetBagPetSubUI.lua:446` | `m_pBgAni` | `PlayActionRepeat` | `0, 1` |
| `View/KaPaiPet/PetBagPetSubUI.lua:448` | `m_pBgAni` | `PlayAction` | `0, 1` |
| `View/KaPaiPet/PetStarUpSucUI.lua:134` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shenqizhanshi"` |
| `View/KaPaiPet/PetStarUpSucUI.lua:137` | `pAnim` | `PlayActionRepeat` | `0` |
| `View/Login/LoginBgUI.lua:59` | `ImodAnim` | `create` | `` |
| `View/Login/LoginBgUI.lua:60` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/Login/LoginBgUI.lua:61` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/Login/RoleCreateUI.lua:112` | `ImodAnim` | `create` | `` |
| `View/Login/RoleCreateUI.lua:122` | `ImodAnim` | `create` | `` |
| `View/Login/RoleCreateUI.lua:123` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/Login/RoleCreateUI.lua:124` | `m_pBgAni` | `PlayActionRepeat` | `0` |
| `View/Login/RoleCreateUI.lua:136` | `self.m_pCreateImod` | `initAnimWithNameSync` | `pngStr` |
| `View/Login/RoleCreateUI.lua:137` | `self.m_pCreateImod` | `PlayNewAction` | `0, true` |
| `View/LuckyDraw/LDCellUI.lua:63` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shenqizhanshi"` |
| `View/LuckyDraw/LDCellUI.lua:68` | `pAnim` | `PlayActionRepeat` | `0` |
| `View/LuckyDraw/LDCellUI.lua:282` | `ImodAnim` | `createWithFileSync` | `"res2/fx/choukashenjiang"` |
| `View/LuckyDraw/LDCellUI.lua:288` | `pAni` | `PlayAction` | `0` |
| `View/LuckyDraw/LuckyDrawUI.lua:821` | `ImodAnim` | `createWithFileSync` | `"res2/fx/choukaluzi"` |
| `View/LuckyDraw/LuckyDrawUI.lua:828` | `pAni` | `PlayAction` | `0` |
| `View/Main/TaskTrackSubUI.lua:809` | `ImodAnim` | `createWithFileSync` | `"res2/fx/renwulan"` |
| `View/Main/TaskTrackSubUI.lua:818` | `self.m_pEffectAni` | `PlayNewAction` | `0, true` |
| `View/Monopoly/MonopolyUI.lua:338` | `ImodAnim` | `create` | `` |
| `View/Monopoly/MonopolyUI.lua:345` | `self.m_pCreateImod` | `SetSpeedScale` | `1 / 2` |
| `View/Monopoly/MonopolyUI.lua:470` | `self.m_pCreateImod` | `initAnimWithName` | `pngStr, aniStr` |
| `View/Monopoly/MonopolyUI.lua:471` | `self.m_pCreateImod` | `PlayAction` | `0` |
| `View/Monopoly/MonopolyUI.lua:472` | `self.m_pCreateImod` | `registerScriptEndCBHandler` | `OnAniEndCallBack` |
| `View/Pet/PetSkillSubUI.lua:108` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shengji_yuan"` |
| `View/Pet/PetSkillSubUI.lua:112` | `ani` | `registerScriptEndCBHandler` | `AniPlayEndCallback` |
| `View/Pet/PetSkillSubUI.lua:113` | `ani` | `PlayAction` | `0` |
| `View/Pet/PetStarUpgradeShowUI.lua:139` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shenqizhanshi"` |
| `View/Pet/PetStarUpgradeShowUI.lua:142` | `pAnim` | `PlayActionRepeat` | `0` |
| `View/Pet/PetUpgradeSubUI.lua:193` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shengxing"` |
| `View/Pet/PetUpgradeSubUI.lua:197` | `ani` | `registerScriptEndCBHandler` | `AniPlayEndCallback` |
| `View/Pet/PetUpgradeSubUI.lua:198` | `ani` | `PlayAction` | `0` |
| `View/Pet/PetUpgradeSubUI.lua:264` | `ImodAnim` | `createWithFileSync` | `"res2/fx/lvdian"` |
| `View/Pet/PetUpgradeSubUI.lua:268` | `ani` | `registerScriptEndCBHandler` | `AniPlayEndCallback` |
| `View/Pet/PetUpgradeSubUI.lua:269` | `ani` | `PlayAction` | `0` |
| `View/Pet/PetXiulianSubUI.lua:66` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shengji_yuan"` |
| `View/Pet/PetXiulianSubUI.lua:70` | `ani` | `registerScriptEndCBHandler` | `AniPlayEndCallback` |
| `View/Pet/PetXiulianSubUI.lua:71` | `ani` | `PlayAction` | `0` |
| `View/PreView/PreViewDetailUI.lua:59` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shenqizhanshi"` |
| `View/PreView/PreViewDetailUI.lua:62` | `pAnim` | `PlayActionRepeat` | `0` |
| `View/Skill/SkillUI.lua:87` | `ImodAnim` | `createWithFileSync` | `"res2/fx/shengji_yuan"` |
| `View/Skill/SkillUI.lua:88` | `ani` | `registerScriptEndCBHandler` | `aniPlayEndCallback` |
| `View/Skill/SkillUI.lua:89` | `ani` | `PlayAction` | `0` |
| `View/Social/xianhuapar_biaobai.lua:64` | `ImodAnim` | `create` | `` |
| `View/Social/xianhuapar_biaobai.lua:65` | `bat` | `initAnimWithName` | `"effect/biaobai/butflay.png", "effect/biaobai/butflay.ani"` |
| `View/Social/xianhuapar_biaobai.lua:68` | `bat` | `PlayActionRepeat` | `0` |
| `View/Social/xianhuapar_hehua.lua:40` | `ImodAnim` | `create` | `` |
| `View/Social/xianhuapar_hehua.lua:41` | `bat` | `initAnimWithName` | `"effect/hehua/hehua_yu.png", "effect/hehua/hehua_yu.ani"` |
| `View/Social/xianhuapar_hehua.lua:44` | `bat` | `PlayActionRepeat` | `0` |
| `View/StageGoal/ShenqiGiftUI.lua:102` | `ImodAnim` | `create` | `` |
| `View/StageGoal/ShenqiGiftUI.lua:218` | `self.m_pArtifactImod` | `initAnimWithName` | `png, ani` |
| `View/StageGoal/ShenqiGiftUI.lua:219` | `self.m_pArtifactImod` | `PlayNewAction` | `0, true` |
| `View/Welfare/PlatinumUI.lua:335` | `ImodAnim` | `create` | `` |
| `View/Welfare/PlatinumUI.lua:341` | `self.m_pCreateImod` | `initAnimWithNameSync` | `"res2/fx/yueka"` |
| `View/Welfare/PlatinumUI.lua:342` | `self.m_pCreateImod` | `PlayActionRepeat` | `0` |
| `View/Welfare/PlatinumUI.lua:346` | `ImodAnim` | `create` | `` |
| `View/Welfare/PlatinumUI.lua:349` | `self.m_pLmCreateImod` | `initAnimWithNameSync` | `"res2/fx/yueka"` |
| `View/Welfare/PlatinumUI.lua:350` | `self.m_pLmCreateImod` | `PlayActionRepeat` | `0` |
| `View/WorldMap/CurMapSubUI.lua:320` | `ImodAnim` | `createWithFileSync` | `"UI/role"` |
| `View/WorldMap/CurMapSubUI.lua:321` | `self.m_pHeroAni` | `PlayActionRepeat` | `0` |
| `View/WorldMap/CurMapSubUI.lua:484` | `ImodAnim` | `createWithFileSync` | `fileName` |
| `View/WorldMap/CurMapSubUI.lua:485` | `imod` | `PlayActionRepeat` | `0` |
| `View/WorldMap/WorldMapSubUI.lua:86` | `ImodAnim` | `createWithFileSync` | `"UI/role"` |
| `View/WorldMap/WorldMapSubUI.lua:87` | `self.m_pCurAni` | `PlayActionRepeat` | `0` |
| `View/XueZhan/XueZhanMainUI.lua:130` | `ImodAnim` | `create` | `` |
| `View/XueZhan/XueZhanMainUI.lua:131` | `m_pBgAni` | `initAnimWithNameSync` | `bgAnim` |
| `View/XueZhan/XueZhanMainUI.lua:132` | `m_pBgAni` | `PlayActionRepeat` | `0` |
