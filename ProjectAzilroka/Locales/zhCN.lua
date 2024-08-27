-- Chinese localization file for zhCN.
local ACL = LibStub('AceLocale-3.0'):NewLocale('ProjectAzilroka', 'zhCN')
if not ACL then return end

-- Misc
ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."] = "你设置的一个选项将只对这个角色生效，改变这个设置需要重载界面"
ACL['Controls AddOns in this package'] = "控制这个插件的功能"
ACL["Frame doesn't exist: "] = "框体不存在"
ACL["%s and then %s"] = true
ACL['Up'] = true
ACL['Down'] = true
ACL['Left'] = true
ACL['Right'] = true
ACL["This setting requires that you reload your User Interface."] = true
ACL['BACKGROUND'] = true
ACL['LOW'] = true
ACL['MEDIUM'] = true
ACL['HIGH'] = true
ACL['DIALOG'] = true
ACL['FULLSCREEN'] = true
ACL['FULLSCREEN_DIALOG'] = true
ACL['TOOLTIP'] = true

-- Apps/Games
ACL['App'] = true
ACL['Call of Duty 4'] = true
ACL['Call of Duty Cold War'] = true
ACL['Call of Duty Modern Warfare'] = true
ACL['Call of Duty Modern Warfare 2'] = true
ACL['Destiny 2'] = "命运 2"
ACL['Diablo 3'] = "暗黑破坏神 3"
ACL['Hearthstone'] = "炉石传说"
ACL['Hero of the Storm'] = "风暴英雄"
ACL['Starcraft'] = "星际争霸"
ACL['Starcraft 2'] = "星际争霸 2"
ACL['Mobile'] = "移动设备"
ACL['Overwatch'] = "守望先锋"

-- Misc
ACL['Authors:'] = "作者: "
ACL['Blizzard'] = "暴雪"
ACL['Default'] = true
ACL['Enable'] = true
ACL['Font Size'] = true
ACL['General'] = "一般"

-- AddOns
ACL['AddOns'] = "功能"
ACL['Cooldown Text'] = true
ACL['Adjust Cooldown Settings.'] = "调整冷却设置."
ACL['BigButtons'] = "农场辅助按钮"
ACL['A farm tool for Sunsong Ranch.'] = "日歌农场辅助工具"
ACL['Provides a Custom DataBroker Bar'] = "创建一个自定义数据条"
ACL['Dragon Overlay'] = "精英头像金龙"
ACL['Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'] = "在首领、稀有、精英、稀有精英头像上显示金龙模型"
ACL['Enhanced Friends List'] = "增强好友列表"
ACL['Provides Friends List Customization'] = "提供好友列表自定义"
ACL['Enhanced Shadows'] = "增强阴影"
ACL['Adds options for registered shadows'] = "为注册的阴影提供自定义选项"
ACL['Faster Loot'] = "快速拾取"
ACL['Increases auto loot speed near instantaneous.'] = "加速自动拾取速度"
ACL['Manage Friends List with Groups'] = "分组管理好友"
ACL['Confirms Loot for Solo/Groups (Need/Greed)'] = "自动确认拾取 (需求 / 贪婪)"
ACL['MovableFrames'] = "窗口移动"
ACL['Make Blizzard Frames Movable'] = "让大部分暴雪窗体可移动"
ACL['Audio for Quest Progress & Completions.'] = "任务完成时的音效"
ACL['Adds Reputation into Quest Log & Quest Frame.'] = "将声望奖励加入任务日志界面"
ACL['Square Minimap Buttons / Bar'] = "小地图按钮收纳"
ACL['Minimap Button Bar / Minimap Button Skinning'] = "小地图按钮收纳及美化"
ACL['stAddOnManager'] = "插件管理"
ACL['A simple and minimalistic addon to disable/enabled addons without logging out.'] = "轻量级插件管理器"
ACL['Audio for Target Sounds.'] = "选择目标时的音效"
ACL['Shows Experience Bars for Party / Battle.net Friends'] = true
ACL['Minimalistic Auras / Buffs / Procs / Cooldowns'] = true
ACL['Enhanced Pet Battle UI'] = true
ACL['An enhanced UI for pet battles'] = true

-- Cooldown Text
ACL['Display cooldown text on anything with the cooldown spiral.'] = '显示技能冷却时间'
ACL['Reverse Toggle'] = '反向启用'
ACL['Reverse Toggle will enable Cooldown Text on this module when the global setting is disabled and disable them when the global setting is enabled.'] = '反向启用将在全局冷却关闭时在此模块启用冷却文字, 全局冷却启用时此模块关闭冷却文字'
ACL['Force Hide Blizzard Text'] = '强制隐藏暴雪冷却文字'
ACL["This option will force hide Blizzard's cooldown text if it is enabled at [Interface > ActionBars > Show Numbers on Cooldown]."] = '这个选项将强制隐藏系统设置中的暴雪冷却文字'
ACL['Text Threshold'] = '文字阈值'
ACL['This will override the global cooldown settings.'] = '这个选项将覆盖全局冷却设置'
ACL['MM:SS Threshold'] = '分:秒 阈值'
ACL['Threshold (in seconds) before text is shown in the MM:SS format. Set to -1 to never change to this format.'] = '小于此选项(秒)的冷却将显示为 分:秒 格式, 设置为-1时为禁用此阈值'
ACL['HH:MM Threshold'] = '时:分 阈值'
ACL['Threshold (in minutes) before text is shown in the HH:MM format. Set to -1 to never change to this format.'] = '小于此选项(分)的冷却将显示为 时:分 格式, 设置为-1时为禁用此阈值'
ACL['Color Override'] = '颜色覆盖'
ACL['Low Threshold'] = '阈值时间'
ACL['Threshold before text turns red and is in decimal form. Set to -1 for it to never turn red'] = '小于此选项(秒)的冷却数字将会变为红色并显示为小数模式, 设置为-1时为禁用此阈值'
ACL['Threshold Colors'] = '阈值颜色'
ACL['Expiring'] = '即将冷却完毕'
ACL['Color when the text is about to expire'] = '即将冷却完毕的数字颜色'
ACL['Seconds'] = '秒'
ACL['Color when the text is in the seconds format.'] = '以秒显示的文字颜色'
ACL['Minutes'] = '分'
ACL['Color when the text is in the minutes format.'] = '以分显示的文字颜色'
ACL['Hours'] = '时'
ACL['Color when the text is in the hours format.'] = '以小时显示的文字颜色'
ACL['Days'] = '天'
ACL['Color when the text is in the days format.'] = '以天显示的文字颜色'
ACL['MM:SS'] = '分:秒'
ACL['HH:MM'] = '时:分'
ACL['Time Indicator Colors'] = '时间指示器颜色'
ACL['Use Indicator Color'] = '使用指示器颜色'
ACL['Fonts'] = '字体'
ACL['Text Font Size'] = '字体大小'
ACL['COLORS'] = '颜色'
ACL['Global'] = '全局'

-- BigButtons
ACL['Drop Farm Tools'] = "丢弃农场工具"
ACL['Farm Tool Size'] = "农场工具大小"
ACL['Seed Size'] = "种子大小"

-- BrokerLDB
ACL['MouseOver'] = "鼠标划过显示"
ACL['Panel Height'] = "面板高度"
ACL['Panel Width'] = "面板宽度"
ACL['Show Icon'] = "显示图标"
ACL['Show Text'] = "显示文字"

-- Dragon Overlay
ACL['Anchor Point'] = "定位点"
ACL['Class Icon'] = "职业图标"
ACL['Class Icon Points'] = "职业图标位置"
ACL['Dragon Points'] = "金龙位置"
ACL['Elite'] = "精英"
ACL['Flip Dragon'] = "反转金龙"
ACL['Frame Level'] = "框体图层"
ACL['Frame Strata'] = "框体层级"
ACL['Image Credits:'] = "图像版权: "
ACL['Rare'] = "稀有"
ACL['Rare Elite'] = "稀有精英"
ACL['Relative Frame'] = "依附框体"
ACL['Relative Point'] = "依附位置"
ACL['World Boss'] = "世界首领"
ACL['X Offset'] = "X 偏移"
ACL['Y Offset'] = "Y 偏移"

-- Enhanced Friends List
ACL['Name Font'] = "姓名字体"
ACL['The font that the RealID / Character Name / Level uses.'] = "实名 / 战网昵称 / 角色名称 / 等级 使用的字体"
ACL['Name Font Size'] = "姓名字体大小"
ACL['The font size that the RealID / Character Name / Level uses.'] = "实名 / 战网昵称 / 角色名称 / 等级 使用的字体大小"
ACL['Name Font Flag'] = "姓名字体轮廓"
ACL['The font flag that the RealID / Character Name / Level uses.'] = "实名 / 战网昵称 / 角色名称 / 等级 使用的字体轮廓"
ACL['Info Font'] = "信息字体"
ACL['The font that the Zone / Server uses.'] = "区域 / 服务器 使用的字体"
ACL['Info Font Size'] = "信息字体大小"
ACL['The font size that the Zone / Server uses.'] = "区域 / 服务器 使用的字体大小"
ACL['Info Font Outline'] = "信息字体轮廓"
ACL['The font flag that the Zone / Server uses.'] = "区域 / 服务器 使用的字体轮廓"
ACL['Level by Difficulty'] = "根据等级染色"
ACL['Status Icon Pack'] = "状态图标"
ACL['Different Status Icons.'] = "不同的状态图标"
ACL['Game Icons'] = "游戏图标"
ACL['Game Icon Preview'] = "游戏图标预览"
ACL['Show Level'] = "显示等级"
ACL['Status Icon Preview'] = "状态图标预览"
ACL[' Icon'] = " 图标"
ACL['Name Settings'] = true
ACL['Info Settings'] = true
ACL['Show Status Background'] = true
ACL['Show Status Highlight'] = true
ACL['Icon Settings'] = true
ACL['Game Icon Pack'] = true

-- Enhanced Pet Battle UI
ACL["3D Portraits"] = true
ACL["Add More Detailed Info if BreedInfo is available."] = true
ACL["Add Pet Level Breakdown if BreedInfo is available."] = true
ACL["Additional options for pet battles: Enhanced tooltips, portraits, fonts and more"] = true
ACL["Breed Format"] = true
ACL["Enhance Tooltip"] = true
ACL["Experience Format"] = true
ACL["Font Flag"] = true
ACL["Grow the frames upwards"] = true
ACL["Grow the frames from bottom for first pet upwards"] = true
ACL["Health Format"] = true
ACL["Health/Experience Text Offset"] = true
ACL["Health Threshold"] = true
ACL["Hide Blizzard"] = true
ACL["Hide the Blizzard Pet Frames during battles"] = true
ACL["Level Breakdown"] = true
ACL["Name Format"] = true
ACL["Place team auras on the bottom of the last pet shown (or top if Grow upwards is selected)"] = true
ACL["Power Format"] = true
ACL["Speed Format"] = true
ACL["StatusBar Texture"] = true
ACL["Team Aura On Bottom"] = true
ACL["Use oUF for the pet frames"] = true
ACL["Use PetTracker Icon"] = true
ACL["Use PetTracker Icon instead of Breed ID"] = true
ACL["Use the new PBUF library by Nihilistzsche included with ProjectAzilroka to create new pet frames using the oUF unitframe template system."] = true
ACL["Use the 3D pet model instead of a texture for the pet icons"] = true
ACL["When the current health of any pet in your journal is under this percentage after a trainer battle, show the revive bar."] = true
ACL["Wild Health Threshold"] = true
ACL["When the current health of any pet in your journal is under this percentage after a wild pet battle, show the revive bar."] = true

-- Enhanced Shadows
ACL['Color by Class'] = "根据职业染色"
ACL['Shadow Color'] = "阴影颜色"
ACL['Size'] = "大小"

-- iFilger -
ACL['Buffs'] = true
ACL['Cooldowns'] = true
ACL['ItemCooldowns'] = true
ACL['Procs'] = true
ACL['Enhancements'] = true
ACL['RaidDebuffs'] = true
ACL['TargetDebuffs'] = true
ACL['FocusBuffs'] = true
ACL['FocusDebuffs'] = true
ACL['Number Per Row'] = true
ACL['Growth Direction'] = true
ACL['Filter by List'] = true
ACL['Stack Count'] = true
ACL['StatusBar'] = true
ACL['Follow Cooldown Text Color'] = true
ACL['Follow Cooldown Text Colors (Expiring / Seconds)'] = true
ACL['Font Flag'] = true
ACL['Filters'] = true

-- Loot Confirm
ACL['Auto Confirm'] = "自动确认"
ACL['Automatically click OK on BOP items'] = "当拾取【拾取绑定】物品时自动点击确定"
ACL['Auto Greed'] = "自动贪婪"
ACL['Automatically greed'] = "自动点击贪婪"
ACL['Auto Disenchant'] = "自动分解"
ACL['Automatically disenchant'] = "自动点击分解"
ACL['Auto-roll based on a given level'] = true
ACL['This will auto-roll if you are above the given level if: You cannot equip the item being rolled on, or the ilevel of your equipped item is higher than the item being rolled on or you have an heirloom equipped in that slot'] = true
ACL['Level to start auto-rolling from'] = true

-- MasterExperience
ACL["Disabled"] = true
ACL["Max Level"] = true
ACL['Lvl'] = true
ACL['Experience'] = true
ACL["XP:"] = true
ACL["Remaining:"] = true
ACL["Bars"] = true
ACL['Quest'] = true
ACL["Quest Log XP:"] = true
ACL['Rested'] = true
ACL["Rested:"] = true
ACL['Party'] = true
ACL['BattleNet'] = true
ACL['Width'] = true
ACL['Height'] = true
ACL['Colors'] = true
ACL['Color By Class'] = true

-- Mouseover Auras
ACL['Auras for your mouseover target'] = '鼠标指向目标显示光环'
ACL['Spacing'] = true

-- MovableFrames
ACL['Permanent Moving'] = "永久移动"
ACL['Reset Moving'] = "重置位置"

-- OzCooldowns
ACL['Enable'] = '启用'
ACL['Enabled'] = '启用'
ACL['Main Options'] = '主要选项'
ACL['Masque Support'] = '支持 Masque 皮肤'
ACL['Sort by Current Duration'] = '按当前剩余排序'
ACL['Suppress Duration Threshold'] = '显示时间阈值'
ACL['Ignore Duration Threshold'] = '忽略时间阈值'
ACL['Duration in Seconds'] = '单位秒'
ACL['Buff Timer'] = '增益计时'
ACL['Update Speed'] = '更新速度'
ACL['Icons'] = '图标'
ACL['Vertical'] = '垂直'
ACL['Tooltips'] = '鼠标提示'
ACL['Announce on Click'] = '点击通告'
ACL['Spacing'] = '间隔'
ACL['Stacks/Charges Font'] = '堆叠/充能字体'
ACL['Stacks/Charges Font Size'] = '堆叠/充能字体大小'
ACL['Stacks/Charges Font Flag'] = '堆叠/充能字体轮廓'
ACL['Status Bar'] = '状态条'
ACL['Gradient'] = '渐变'
ACL['Texture Color'] = '材质颜色'
ACL['Spell ID: '] = '法术ID: '
ACL['My %s will be off cooldown in %s'] = '法术 %s 将在 %s 后就绪'


-- QuestSounds
ACL['Sound by LSM'] = true
ACL['Sound by SoundID'] = true
ACL['Use Sound ID'] = true
ACL['Quest Complete Sound ID'] = true
ACL['Quest Complete'] = true
ACL['Objective Complete Sound ID'] = true
ACL['Objective Complete'] = true
ACL['Objective Progress Sound ID'] = true
ACL['Objective Progress'] = true
ACL['Throttle'] = true
ACL['Ambience'] = true
ACL['Channel'] = true
ACL['Dialog'] = true
ACL['Master'] = true
ACL['SFX'] = true

-- Reminder(AuraReminder)
ACL['Sound'] = true
ACL['Sound that will play when you have a warning icon displayed.'] = true
ACL['Select Group'] = true
ACL['Select Filter'] = true
ACL['None'] = true
ACL['Filter Control'] = true
ACL['New Filter Name'] = true
ACL['New Filter Type'] = true
ACL['Spell'] = true
ACL['Weapon'] = true
ACL['Cooldown'] = true
ACL['Add Filter'] = true
ACL['Remove Filter'] = true
ACL['Filter Type'] = true
ACL['Change this if you want the Reminder module to check for weapon enchants, setting this will cause it to ignore any spells listed.'] = true
ACL['Conditions'] = true
ACL['Inside Raid/Party'] = true
ACL['Inside BG/Arena'] = true
ACL['Combat'] = true
ACL['Filter Conditions'] = true
ACL['Level Requirement'] = true
ACL['Level requirement for the icon to be able to display. 0 for disabled.'] = true
ACL['Personal Buffs'] = true
ACL['Only check if the buff is coming from you.'] = true
ACL['Reverse Check'] = true
ACL['Instead of hiding the frame when you have the buff, show the frame when you have the buff.'] = true
ACL['Strict Filter'] = true
ACL['This ensures you can only see spells that you actually know. You may want to uncheck this option if you are trying to monitor a spell that is not directly clickable out of your spellbook.'] = true
ACL['Disable Sound'] = true
ACL['Cooldown Conditions'] = true
ACL['Spell ID'] = true
ACL['Show On Cooldown'] = true
ACL['Cooldown Alpha'] = true
ACL['Spells'] = true
ACL['New ID'] = true
ACL['Remove ID'] = true
ACL['Negate Spells'] = true
ACL['Any'] = true
ACL['Role'] = true
ACL['You must be a certain role for the icon to appear.'] = true
ACL['Tank'] = true
ACL['Damage'] = true
ACL['Healer'] = true
ACL['Talent Tree'] = true
ACL['You must be using a certain talent tree for the icon to show.'] = true
ACL['Tree Exception'] = true
ACL['Set a talent tree to not follow the reverse check.'] = true
ACL['Class'] = true

-- Reputation Reward
ACL['Show All Reputation'] = true

-- SquareMinimapButtons
ACL['Bar MouseOver'] = "鼠标划过显示"
ACL['Buttons Per Row'] = "每行按钮数"
ACL['Button Spacing'] = "按钮间隙"
ACL['Enable Bar'] = "启用按钮条"
ACL['Hide Garrison'] = "隐藏要塞"
ACL['Icon Size'] = "图标大小"
ACL['Minimap Buttons / Bar'] = "小地图 按钮 / 条"
ACL['Move Garrison Icon'] = "收纳要塞图标"
ACL['Move Mail Icon'] = "收纳邮件图标"
ACL['Move Tracker Icon'] = "收纳追踪图标"
ACL['Move Queue Status Icon'] = "收纳任务状态图标"
ACL['Square Minimap Buttons'] = true
ACL['Bar Backdrop'] = true
ACL['Blizzard'] = true
ACL['Move Game Time Frame'] = true
ACL['Reverse Direction'] = true
ACL['Shadows'] = true
ACL['Visibility'] = true

-- stAddOnManager
ACL['# Shown AddOns'] = "# 显示插件"
ACL['Are you sure you want to delete %s?'] = "是否确定删除 %s ?"
ACL['Button Height'] = "按钮高度"
ACL['Button Width'] = "按钮宽度"
ACL['Cancel'] = "取消"
ACL['Character Select'] = "角色选择"
ACL['Class Color Check Texture'] = "选择框职业色"
ACL['Create'] = "创建"
ACL['Delete'] = "删除"
ACL['Enable All'] = "启用所有"
ACL['Enable Required AddOns'] = "启用依赖插件"
ACL['Enter a name for your AddOn Profile:'] = "输入插件方案名称: "
ACL['Enter a name for your new Addon Profile:'] = "输入新插件方案名称: "
ACL['Disable All'] = "禁用所有"
ACL['Font'] = "字体"
ACL['Font Outline'] = "字体轮廓"
ACL['Frame Width'] = "框体宽度"
ACL['New Profile'] = "新方案"
ACL['Overwrite'] = "覆盖"
ACL['Profiles'] = "方案"
ACL['Reload'] = "重载"
ACL['Required'] = "依赖"
ACL['Search'] = "搜索"
ACL['Texture'] = "材质"
ACL['There is already a profile named %s. Do you want to overwrite it?'] = "已有名为 %s 的方案, 是否覆盖?"
ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'] = "这将启用所有所选插件所依赖的插件"
ACL['Update'] = "更新"

-- Torghast Buffs
ACL["Index"] = true
ACL["Name"] = true
ACL['Masque Support'] = true
ACL["Set the size of the individual auras."] = true
ACL["The direction the auras will grow and then the direction they will grow after they reach the wrap after limit."] = true
ACL["Wrap After"] = true
ACL["Begin a new row or column after this many auras."] = true
ACL["Max Wraps"] = true
ACL["Limit the number of rows or columns."] = true
ACL["Horizontal Spacing"] = true
ACL["Vertical Spacing"] = true
ACL["Sort Method"] = true
ACL["Defines how the group is sorted."] = true
ACL["Sort Direction"] = true
ACL["Defines the sort order of the selected sort method."] = true
ACL["Ascending"] = true
ACL["Descending"] = true
ACL["Growth Direction"] = true