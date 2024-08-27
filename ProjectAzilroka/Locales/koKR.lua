-- Korean localization file for koKR.
local ACL = LibStub('AceLocale-3.0'):NewLocale('ProjectAzilroka', 'koKR')
if not ACL then return end

-- Init
ACL["%s and then %s"] = "%s 이후 %s"
ACL["Up"] = "위로"
ACL["Down"] ="아래로"
ACL["Left"] ="왼쪽"
ACL["Right"] ="오른쪽"
ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."] = "변경한 설정은 이 캐릭터 만을 적용 변경합니다. 변경한 이 설정은 사용자 프로필을 변경해도 영향을받지 않습니다. 설정을 적용 하려면하려면 사용자 인터페이스를 다시 로드해야 합니다."
ACL["This setting requires that you reload your User Interface."] = "이 설정을 변경하려면 사용자 인터페이스를 다시 로드해야 합니다."
ACL['BACKGROUND'] = '배경'
ACL['LOW'] = '낮음'
ACL['MEDIUM'] = '중간'
ACL['HIGH'] = '높음'
ACL['DIALOG'] = '채팅'
ACL['FULLSCREEN'] = '전체화면'
ACL['FULLSCREEN_DIALOG'] = '전체 외침'
ACL['TOOLTIP'] = '툴팁'

-- Apps/Games - 친구 관리 관련 (블리자드 게임 목록) --
ACL['App'] = '앱'
ACL['Call of Duty 4'] = '콜 오브 듀티 4'
ACL['Call of Duty Cold War'] = '콜 오브 듀티 콜드 워'
ACL['Call of Duty Modern Warfare'] = '콜 오브 듀티: 모던 워페어'
ACL['Call of Duty Modern Warfare 2'] = '콜 오브 듀티: 모던 워페어 2'
ACL['Destiny 2'] = '데스티니 2'
ACL['Diablo 3'] = '디아블로 3'
ACL['Hearthstone'] = '하스스톤'
ACL['Hero of the Storm'] = '히어로즈 오브 더 스톰'
ACL['Starcraft'] = '스타크래프트'
ACL['Starcraft 2'] = '스타크래프트 2'
ACL['Mobile'] = '모바일'
ACL['Overwatch'] = '오버워치'
	
-- Misc - 기타/일반
ACL['AddOns'] = true
ACL['Authors:'] = '제작자 :'
ACL['Blizzard'] = true
ACL['Default'] = '기본값'
ACL['Enable'] = '사용'
ACL['Font Size'] = '글꼴 크기'
ACL['General'] = '일반'

-- BigButtons - 농장 도우미
ACL['BigButtons'] = '큰 버튼'
ACL['A farm tool for Sunsong Ranch.'] = '태양 노래 농장을 위한 도구 및 씨앗 크기 툴을 제공'
ACL['Drop Farm Tools'] = '농장 수확 도구'
ACL['Farm Tool Size'] = '농장 도구 크기'
ACL['Seed Size'] = '씨앗 크기'

-- BrokerLDB - 브로커 LDB
ACL['Provides a Custom DataBroker Bar'] = '마우스오버, 너비 및 높이와 같은 사용자 지정 옵션이있는 DataBroker 막대를 제공.'
ACL['Font Settings'] = '글꼴 설정'
ACL['MouseOver'] = '마우스오버'
ACL['Panel Height'] = '패널 높이'
ACL['Panel Width'] = '패널 너비'
ACL['Show Icon'] = '아이콘 표시'
ACL['Show Text'] = '문자 표시'

-- Cooldown Text - 버프/디버프 알람
ACL['Cooldown Text'] = true
ACL['Adjust Cooldown Settings.'] = "[재사용 대기시간] 설정을 조정합니다."
ACL["Reverse Toggle"] = "반대로 보여줌"
ACL["Reverse Toggle will enable Cooldown Text on this module when the global setting is disabled and disable them when the global setting is enabled."] = "설정내용이 있으면 안보이고, 없을대 화면에 보여줌"
ACL["Force Hide Blizzard Text"] = "블리자드 문자 강제 숨김"
ACL["This option will force hide Blizzard's cooldown text if it is enabled at [Interface > ActionBars > Show Numbers on Cooldown]."] = "이 옵션은 [Esc >인터페이스 설정 >행동 단축바 >재사용대기시간 숫자 보이기]에서 사용할 경우 블리자드의 재사용 대기시간 문자를 강제로 숨김."
ACL["Text Threshold"] = "글자 표시 변경점"
ACL["This will override the global cooldown settings."] = "일반적 재사용 대기시간 설정을 무시합니다."
ACL["MM:SS Threshold"] = "분:초 변경값"
ACL["Threshold (in seconds) before text is shown in the MM:SS format. Set to -1 to never change to this format."] = "[분:초] 형식으로 표시되기 전의 변경값(초)입니다.|n|n-1로 입력하면 이 기능을 사용하지 않습니다."
ACL["HH:MM Threshold"] = "시:분 변경값"
ACL["Threshold (in minutes) before text is shown in the HH:MM format. Set to -1 to never change to this format."] = "[시:분] 형식으로 표시되기 전의 변경값(분)입니다.|n|n-1로 입력하면 이 기능을 사용하지 않습니다."
ACL["Fonts"] = "글꽆"
ACL["Color Override"] = "색상 재정의"
ACL["Low Threshold"] = "초읽기 시작 시점"
ACL["Threshold before text turns red and is in decimal form. Set to -1 for it to never turn red"] = "입력값 이하로 시간이 내려가면 시간이 빨간색 소숫점 단위 초읽기 형태로 표시됩니다.|n|n-1로 입력하면 이 기능을 사용하지 않습니다."
ACL["Threshold Colors"] = "변경값 색상"
ACL["Expiring"] = "초읽기 색상"
ACL["Color when the text is about to expire"] = "버튼에 배치된 행동의 재사용 대기시간이 [초읽기] 상태일 경우 글자색"
ACL["Seconds"] = "초 단위 색상"
ACL["Color when the text is in the seconds format."] = "버튼에 배치된 행동의 재사용 대기시간이 [초] 단위일 경우 글자색"
ACL["Minutes"] = "분 단위 색상"
ACL["Color when the text is in the minutes format."] = "버튼에 배치된 행동의 재사용 대기시간이 [분] 단위일 경우 글자색"
ACL["Hours"] = "시간 단위 색상"
ACL["Color when the text is in the hours format."] = "버튼에 배치된 행동의 재사용 대기시간이 [시간] 단위일 경우 글자색"
ACL["HH:MM"] = "[시:분]"
ACL["MM:SS"] = "[분:초]"
ACL["Time Indicator Colors"] = "시간 표시기 색상"
ACL["Use Indicator Color"] = "색상 표시기 사용"
ACL["Days"] = "일 단위 색상"
ACL["Color when the text is in the days format."] = "버튼에 배치된 행동의 재사용 대기시간이 일 단위일 경우 글자색"
ACL["COLORS"] = "색상"
ACL["Display cooldown text on anything with the cooldown spiral."] = "재사용 대기시간을 가진 모든 것에 시간을 표시합니다."
ACL["Global"] = "일반"

-- Dragon Overlay - 정예 관련 용 무늬 표시
ACL['Dragon Overlay'] = '정예 마크 표시기'
ACL['Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'] = '보스,엘리트,레어 및 레어 엘리트의 용무늬 마크를 제공'
ACL['Anchor Point'] = '기준점'
ACL['Class Icon'] = '클래식 아이콘'
ACL['Class Icon Points'] = '클래스 아이콘 포인트'
ACL['Dragon Points'] = '드래곤 포인트'
ACL['Dragons'] = '드래곤'
ACL['Elite'] = '엘리트(정예)'
ACL['Flip Dragon'] = '드래곤 좌우반전'
ACL['Frame Level'] = '프레임 레벨'
ACL['Frame Strata'] = '프레임 지층'
ACL['Image Credits:'] = '이미지 제공:'
ACL['Preview'] = '미리보기'
ACL['Rare'] = '희귀'
ACL['Rare Elite'] = '희귀 엘리트(정예)'
ACL['Relative Frame'] = '비교 프레임'
ACL['Relative Point'] = '비교 포인트'
ACL['World Boss'] = '월드 보스'
ACL['X Offset'] = 'X 간격'
ACL['Y Offset'] = 'Y 간격'

-- Enhanced Friends List - 향상된 친구 목록 관리
ACL['Enhanced Friends List'] = '고급 친구 관리'
ACL['Provides Friends List Customization'] = '이미 등록 된 그림자에 대한 옵션 추가 : 색상, 크기, 클래스 별 색상'
ACL['Name Font'] = '이름 글꼴'
ACL['The font that the RealID / Character Name / Level uses.'] = '[실명ID/케릭터이름/레벨]에서 사용하는 글꼴.'
ACL['Name Font Size'] = '글꼴 크기'
ACL['The font size that the RealID / Character Name / Level uses.'] = '[실명ID/케릭터이름/레벨]에서 사용하는 글꼴 크기.'
ACL['Name Font Flag'] = '글꼴 외곽선'
ACL['The font flag that the RealID / Character Name / Level uses.'] = '[실명ID/케릭터이름/레벨]에서 사용하는 글꼴 외곽선.'
ACL['Info Font'] = '정보 글꼴'
ACL['The font that the Zone / Server uses.'] = '[위치/서버]가 사용하는 글꼴.'
ACL['Info Font Size'] = '정보 글꼴 크기'
ACL['The font size that the Zone / Server uses.'] = '[위치/서버]가 사용하는 글꼴 크기.'
ACL['Info Font Outline'] = '정보 글꼴 외곽선'
ACL['The font flag that the Zone / Server uses.'] = '[위치/서버]가 사용하는 외곽선 글꼴.'
ACL['Name Settings'] = '이름 세팅 - 배틀태그이름/케릭이름/레벨'
ACL['Icon Settings'] = '아이콘 세팅'
ACL['Info Settings'] = '정보 세팅 - 게임/서버/던전/위치'
ACL['Show Status Background'] = '배경 상태 표시'
ACL['Show Status Highlight'] = '강조 빛남 표시'
ACL['Level by Difficulty'] = '난이도 별'
ACL['Status Icon Pack'] = '상태 아이콘 팩'
ACL['Different Status Icons.'] = '각종 상태 아이콘.'
ACL['Game Icons'] = '게임 아이콘'
ACL['Game Icon Pack'] = '게임 아이콘 팩'
ACL['Game Icon Preview'] = '게임 아이콘 미리보기'
ACL['Show Level'] = '레벨 표시'
ACL['Status Icon Preview'] = '내상태 아이콘 미리보기'
ACL[' Icon'] = ' 아이콘'
ACL['Name Settings'] = true
ACL['Info Settings'] = true
ACL['Show Status Background'] = true
ACL['Show Status Highlight'] = true
ACL['Icon Settings'] = true
ACL['Game Icon Pack'] = true

-- Enhanced Pet Battle UI - 향상된 팻 배틀 UI
ACL['Enhanced Pet Battle UI'] = true
ACL['An enhanced UI for pet battles'] = true
ACL["3D Portraits"] = "3D 초상화"
ACL["Add More Detailed Info if BreedInfo is available."] = "번식 정보가 있으면 더 자세한 정보를 추가하십시오."
ACL["Add Pet Level Breakdown if BreedInfo is available."] = "종 정보를 사용할 수 있는 경우 애완동물 레벨 분류를 추가합니다."
ACL["Additional options for pet battles: Enhanced tooltips, portraits, fonts and more"] = "애완동물 대전을 위한 추가 옵션 : 향상된 툴팁, 초상화, 글꼴 등"
ACL["Breed Format"] = "번식 형식"
ACL["Enhance Tooltip"] = "향상된 툴팁"
ACL["Experience Format"] = "XP 형석"
ACL["Font Flag"] = "외곽선 글꼴"
ACL["Grow the frames upwards"] = "프레임을 위쪽으로 늘리기"
ACL["Grow the frames from bottom for first pet upwards"] = "첫 번째 애완 동물을 위해 프레임을 아래에서 위로 늘립니다."
ACL["Health Format"] = "체력 형식"
ACL["Health/Experience Text Offset"] = "체력/경험치 간격"
ACL["Health Threshold"] = "체력 상태표시 변경값"
ACL["Hide Blizzard"] = "블리자드 숨기기"
ACL["Hide the Blizzard Pet Frames during battles"] = "전투 중 블리자드 애완 동물 프레임 숨기기"
ACL["Level Breakdown"] = "레벨 분석"
ACL["Name Format"] = "이름 형식"
ACL["Place team auras on the bottom of the last pet shown (or top if Grow upwards is selected)"] = "마지막으로 선택된 팀 구성팀을 하단에 표시,(또는 위쪽으로 선택된 경우 위에)"
ACL["Power Format"] = "자원 형식"
ACL["Speed Format"] = "속도 형식"
ACL["StatusBar Texture"] = "상태표시 바 문자"
ACL["Team Aura On Bottom"] = "하단의 팀 표시"
ACL["Use oUF for the pet frames"] = "애완 동물 프레임에 oUF 사용"
ACL["Use PetTracker Icon"] = "애완동물 아이콘 사용"
ACL["Use PetTracker Icon instead of Breed ID"] = "능력정보 대신 애완동물 아이콘 사용"
ACL["Use the new PBUF library by Nihilistzsche included with ProjectAzilroka to create new pet frames using the oUF unitframe template system."] = "ProjectAzilroka에 포함된 *Nihilistzsche의 새로운 PBUF 라이브러리를 사용하여 oUF 단위 프레임 템플릿 시스템을 사용하여 새로운 애완 동물 프레임을 만듭니다.\n*남부 캘리포니아에 살고있는 장애인 프로그래머"
ACL["Use the 3D pet model instead of a texture for the pet icons"] = "애완 동물 아이콘에 문자 대신 3D 애완 동물 모델을 사용."
ACL["When the current health of any pet in your journal is under this percentage after a trainer battle, show the revive bar."] = "배틀 훈련 후 당신의 일지에 있는 애완동물의 현재 건강이 설정값(%)이하일 때, 회복바를 표시합니다."
ACL["Wild Health Threshold"] = "야생 체력 상태표시 변경값"
ACL["When the current health of any pet in your journal is under this percentage after a wild pet battle, show the revive bar."] = "애완동물 대전 후 당신의 일지에 있는 애완동물의 현재 건강이 설정값(%)이하일 때, 회복바를 표시합니다."

-- Enhanced Shadows - 강화된 그림자 기능
ACL['Enhanced Shadows'] = '향상된 그림자 기능'
ACL['Adds options for registered shadows'] = '이미 등록 된 그림자에 대한 옵션 추가 : 색상,크기,클래스 별 색상.'
ACL['Color by Class'] = '직업 별 색상'
ACL['Shadow Color'] = '그림자 색상'
ACL['Size'] = '크기'

-- Faster Loot - 빠른 루팅
ACL['Faster Loot'] = '더 빠른 전리품'
ACL['Increases auto loot speed near instantaneous.'] = '순간에 가까운 자동 전리품 속도 증가.'

-- iFilger -
ACL['Minimalistic Auras / Buffs / Procs / Cooldowns'] = '[오라/버프/발동효과/재사용대기시간]을 불필요한 소유를 없애고,단순,간단명료하게 표현'
ACL['Buffs'] = '버프'
ACL['Cooldowns'] = true
ACL['ItemCooldowns'] = '아이탬재사용대기시간'
ACL['Procs'] = '발동효과'
ACL['Enhancements'] = '소모성강화[독,오일 등]'
ACL['RaidDebuffs'] = '레이드 디버프'
ACL['TargetDebuffs'] = '대상 디버프'
ACL['FocusBuffs'] = '주시 버프'
ACL['FocusDebuffs'] = '주시 디버프'
ACL['Number Per Row'] = '한줄에 표시수'
ACL['Growth Direction'] = '나열 방향'
ACL['Filter by List'] = '목록으로 필터링'
ACL['Stack Count'] = '중첩 표시'
ACL['StatusBar'] = '상태표시 바'
ACL['Follow Cooldown Text Color'] = '재사용 대기시간 문자 색상 따르기'
ACL['Follow Cooldown Text Colors (Expiring / Seconds)'] = '재사용 대기시간 문자색 따르기(만료 시간/초)'
ACL['Font Flag'] = '글꼴 외곽선'
ACL['Filters'] = true

-- Loot Confirm - 루팅 관련 자동화기능
ACL['Confirms Loot for Solo/Groups (Need/Greed)'] = '솔로/그룹 전리품 확인 (입찰/차비)'
ACL['Automatically click OK on BOP items'] = '획귀 아이템 자동으로 확인을 클릭.'
ACL['Auto Greed'] = '자동 차비'
ACL['Automatically greed'] = '자동으로 차비 선택'
ACL['Auto Disenchant'] = '자동 마력추출'
ACL['Automatically disenchant'] = '자동으로 마력추출 선택'
ACL['Auto-roll based on a given level'] = true
ACL['If Disenchant and Greed is selected. It will always try to Disenchant first.'] = '마력추출 과 차비가 모두 선택된 경우. 항상 마력추출를 먼저 시도합니다.'
ACL['This will auto-roll if you are above the given level if: You cannot equip the item being rolled on, or the ilevel of your equipped item is higher than the item being rolled on or you have an heirloom equipped in that slot'] = true

-- MasterExperience - 마스터 경험치
ACL['Shows Experience Bars for Party / Battle.net Friends'] = '파티 /Battle.net 친구를위한 경험치 표시'
ACL["Disabled"] = "사용안함"
ACL["Max Level"] = "최대 레벨"
ACL['Lvl'] = '레벨1'
ACL['Experience'] = "경험치"
ACL["XP:"] = true
ACL["Remaining:"] = "남은 시간 :"
ACL["Bars"] = "바"
ACL['Quest'] = '퀘스트'
ACL["Quest Log XP:"] = "퀘스트 완료시 XP:"
ACL['Rested'] = "휴식"
ACL["Rested:"] = "휴식경험치:"
ACL['Party'] = '파티'
ACL['BattleNet'] = '배틀넷'
ACL['Width'] = '너비'
ACL['Height'] = '높이'
ACL['Colors'] = "색상"
ACL['Color By Class'] = '직업 색상'

-- Mouseover Auras - 마우스 오버시 버프 상황 표시
ACL['Auras for your mouseover target'] = '마우스 오버 대상에 대한 버프 정보'

-- MovableFrames - 프레임 이동
ACL['Movable Frames'] = '프레임 이동'
ACL['Make Blizzard Frames Movable'] = '블리자드 프레임을 이동 가능하게 만들기 (예 : 캐릭터 프레임, 친구 목록, 길드 프레임)'
ACL['Permanent Moving'] = '완전한 이동 (해당프레임 체크 해제 시 프레임을 다시 호출할 때 제자리에서 시작 됨)'
ACL['Reset Moving'] = '이동 초기화'

-- OzCooldowns - 심플한 재사용 대기시간 표시기
ACL['Minimalistic Cooldowns'] = "단순함을 추구하는 재사용 대기시간 표시기"
ACL["My %s will be off cooldown in %s"] = "%s 쿨타임중! %s후에 사용가능!."
ACL['Masque Support'] = '마스크 지원'
ACL['Sort by Current Duration'] = '현재 기간으로 정렬'
ACL['Suppress Duration Threshold'] = '지속 시간 변경점 억제'
ACL['Duration in Seconds'] = '지속 시간(초)'
ACL['Ignore Duration Threshold'] = '변경 시점 무시'
ACL['Update Speed'] = '업데이트 속도'
ACL['Icons'] = '아이콘'
ACL['Vertical'] = '세로'
ACL['Tooltips'] = '툴팁'
ACL['Announce on Click'] = '클릭시 알림'
ACL['Spacing'] = '간격'
ACL['Stacks/Charges Font'] = '스택/충전 글꼴 크기'
ACL['Stacks/Charges Font Size'] = '스택/충전 글꼴 크기'
ACL['Stacks/Charges Font Flag'] = '스택/충전 글꼴 태두리'
ACL['Status Bar'] = '상태 바'
ACL['Enabled'] = '활성화'
ACL['Texture'] = '질감(Texture)'
ACL['Gradient'] = '그라데이션 효과(Gradation)'
ACL['Texture Color'] = '질감 색상' 

-- QuestSounds - 퀘스트 진행.완료 소리
ACL['Audio for Quest Progress & Completions.'] = '퀘스트 진행 상황 및 완료를 위한 오디오 기능.'
ACL['Sound by LSM'] = '꾸임 소리 선택'
ACL['Sound by SoundID'] = '사운드ID 로 소리 선택'
ACL['Use Sound ID'] = '사운드ID 사용'
ACL['Quest Complete Sound ID'] = '퀘스트 완료 사운드 ID'
ACL['Quest Complete'] = '퀘스트 완료 사운드'
ACL['Objective Complete Sound ID'] = '목표 완료 사운드 ID'
ACL['Objective Complete'] = '목표 완료 사운드'
ACL['Objective Progress Sound ID'] = '목표 진행률 사운드 ID'
ACL['Objective Progress'] = '목표 진행률 사운드'
ACL['Throttle'] = true
ACL['Ambience'] = true
ACL['Channel'] = true
ACL['Dialog'] = true
ACL['Master'] = true
ACL['SFX'] = true

-- Reminder(AuraReminder) - 버프 알리 
ACL['Reminder for Buffs / Debuffs'] = '버프 / 디버프에 대한 알림'
ACL['Sound'] = '사운드'
ACL['Sound that will play when you have a warning icon displayed.'] = '경고 아이콘이 표시 될 때 재생되는 소리.'
ACL['Select Group'] = '그룹 선택'
ACL['Select Filter'] = '필터 선택'
ACL['None'] = '없음'
ACL['Filter Control'] = '필터 제어'
ACL['New Filter Name'] = '새 필터 이름'
ACL['New Filter Type'] = '새 필터 유형'
ACL['Spell'] = '주문'
ACL['Weapon'] = '무기'
ACL['Cooldown'] = '재사용 대기시간'
ACL['Add Filter'] = '필터 추가'
ACL['Remove Filter'] = '필터 제거'
ACL['Filter Type'] = '필터 유형'
ACL['Change this if you want the Reminder module to check for weapon enchants, setting this will cause it to ignore any spells listed.'] = '알림 모듈에서 무기 강화를 확인하려는 경우, 이 옵션을 변경 하면 나열된 주문을 무시하게 됩니다.'
ACL['Conditions'] = '조건(주위 상황)'
ACL['Inside Raid/Party'] = '인던,레이드/파티'
ACL['Inside BG/Arena'] = '전장/투기장'
ACL['Combat'] = '전투중'
ACL['Filter Conditions'] = '필터 조건'
ACL['Level Requirement'] = '레벨 요구 사항'
ACL['Level requirement for the icon to be able to display. 0 for disabled.'] = '아이콘을 표시할 수 있는 수준 요구 사항입니다. (0 경우 비활성화)'
ACL['Personal Buffs'] = '개인 버프'
ACL['Only check if the buff is coming from you.'] = '버프가 당신에게 있는지만 확인.'
ACL['Reverse Check'] = '반대로 체크'
ACL['Instead of hiding the frame when you have the buff, show the frame when you have the buff.'] = '버프가 !있을때! 알림을 표시.'
ACL['Strict Filter'] = '엄격한 필터'
ACL['This ensures you can only see spells that you actually know. You may want to uncheck this option if you are trying to monitor a spell that is not directly clickable out of your spellbook.'] = '선텍 하면 실제로 알고있는 주문만볼 수 있습니다. 마법책에서 직접 볼수 없는 주문을 확인하려는 경우, 이 옵션을 선택 해제.'
ACL['Disable Sound'] = '사운드 사용안함'
ACL['Cooldown Conditions'] = '재사용 대기시간 조건'
ACL['Spell ID'] = '주문 ID'
ACL['Show On Cooldown'] = '재사용 대기시간 보기'
ACL['Cooldown Alpha'] = true
ACL['Spells'] = '주문들'
ACL['New ID'] = '새로운 ID'
ACL['Remove ID'] = 'ID 삭제'
ACL['Negate Spells'] = '주문 무효화'
ACL['Any'] = '어떤'
ACL['Role'] = '[직업]역활'
ACL['You must be a certain role for the icon to appear.'] = '아이콘이 나타나려면 특정 역할이어야 합니다.'
ACL['Tank'] = '탱커'
ACL['Damage'] = '딜러'
ACL['Healer'] = '힐러'
ACL['Talent Tree'] = '특성 트리'
ACL['You must be using a certain talent tree for the icon to show.'] = '특정 특성트리를 타야만 아이콘이 보여짐.'
ACL['Tree Exception'] = '예외 트리'
ACL['Set a talent tree to not follow the reverse check.'] = '역활 확인을 구분하지 않는 특성 트리를 선택.'

-- Reputation Reward - 평판 보상
ACL['Adds Reputation into Quest Log & Quest Frame.'] = '퀘스트 로그 및 퀘스트 프레임에 평판을 추가합니다.'
ACL['Show All Reputation'] = '모든 평판 보기'

-- SquareMinimapButtons - 사각 미니맵 버튼
ACL['Minimap Button Bar / Minimap Button Skinning'] = '미니맵 버튼 바 / 미니맵 버튼 스킨'
ACL['Square Minimap Buttons'] = '사각 미니맵 버튼'
ACL['Bar Backdrop'] = '검정 배경'
ACL['Bar MouseOver'] = '마우스 오버 보이기'
ACL['Button Spacing'] = '아이콘 주변 여백'
ACL['Buttons Per Row'] = '한줄 최대 버튼 수'
ACL['Blizzard'] = 'Blizzard - 변경시 리로드후 적용 "/Reload or /RL" '
ACL['Enable Bar'] = '바 크기/여백 조정'
ACL['Hide Garrison'] = '아이콘 모음 숨기기'
ACL['Icon Size'] = '아이콘 크기'
ACL['Minimap Buttons / Bar'] = '미니맵 버튼 / 바'
ACL['Move Garrison Icon'] = '이이콘 모음 이동'
ACL['Move Game Time Frame'] = '게임 시간 프레임 이동'
ACL['Move Mail Icon'] = '메일 아이콘 이동'
ACL['Move Tracker Icon'] = '추적기 아이콘 이동'
ACL['Move Queue Status Icon'] = '대기열 상태 아이콘 이동'
ACL['Reverse Direction'] = '배열 역순 보이기'
ACL['Shadows'] = '그림자 효과'
ACL['Visibility'] = '표시 자동전화 조건'

-- stAddOnManager - 실시간 에드온 On/Off 지원
ACL['stAddOnManager'] = 'st에드온 메니저'
ACL['A simple and minimalistic addon to disable/enabled addons without logging out.'] = '로그 아웃하지 않고 애드온을 활성화/비활성화 할수 있게 하는 가벼운 애드온.'
ACL['# Shown AddOns'] = '# 표시된 애드온'
ACL['Are you sure you want to delete %s?'] = '%s을(를) 삭제 하시겠습니까?'
ACL['Button Height'] = '버튼 높이'
ACL['Button Width'] = '버튼 너비'
ACL['Cancel'] = '취소'
ACL['Character Select'] = '캐릭터 선택'
ACL['Class Color Check Texture'] = '클래스 색상 체크 텍스처'
ACL['Create'] = '창조'
ACL['Delete'] = '삭제'
ACL['Enable All'] = '모두 사용'
ACL['Enable Required AddOns'] = '필수 애드온 활성화'
ACL['Enter a name for your AddOn Profile:'] = '애드온 프로필 이름 입력 :'
ACL['Enter a name for your new Addon Profile:'] =  '새 애드온 프로필 이름 입력 :'
ACL['Disabled: '] = '비활성화 됨 : '
ACL['Disable All'] = '모두 사용안함'
ACL['Font'] = '글꼴'
ACL['Font Outline'] = '글꼴 외곽선'
ACL['Frame Width'] = '프레임 너비'
ACL['Missing: '] = '누락:'
ACL['New Profile'] = '새 프로필'
ACL['Overwrite'] = '덮어 쓰기'
ACL['Profiles'] = '프로필'
ACL['Reload'] = '리로드'
ACL['Required'] = '필수'
ACL['Search'] = '검색'
ACL['There is already a profile named %s. Do you want to overwrite it?'] = '같은 이름에 [% s] 프로필이 있습니다. 덮어 쓰시겠습니까?'
ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'] = '그러면 선택한 애드온에 대한 모든 "필수" 애드온을 활성화 합니다..'
ACL['Update'] = '업데이트'

-- TargetSounds - 타겟 지정 사운드 지원
ACL['Audio for Target Sounds.'] = '타겟 선택 하면, 사운드를 출력.'

-- Torghast Buffs - 토르가스트 버프
ACL['Torghast Buffs'] = '토르가스트 버프'
ACL["Index"] = "색인"
ACL["Name"] = "이름" 
ACL['Masque Support'] = '마스크 지원'
ACL["Set the size of the individual auras."] = "버프 크기를 개별 설정합니다."
ACL["The direction the auras will grow and then the direction they will grow after they reach the wrap after limit."] = "버프가 성장하는 방향과 제한 랩에 도달한 후 성장하는 방향입니다."
ACL["Wrap After"] = true
ACL["Begin a new row or column after this many auras."] = true
ACL["Max Wraps"] = "최대 령 능력"
ACL["Limit the number of rows or columns."] = "행 또는 열의 수를 제한합니다."
ACL["Horizontal Spacing"] = "수평 간격"
ACL["Vertical Spacing"] = "수직 간격"
ACL["Sort Method"] = "정렬 방법"
ACL["Defines how the group is sorted."] = "그룹 정렬 방법을 정의합니다."
ACL["Sort Direction"] = "정렬 방향"
ACL["Defines the sort order of the selected sort method."] = "선택한 정렬 방법의 정렬 순서를 정의합니다."
ACL["Ascending"] = "오름차순"
ACL["Descending"] = "내림차순"
ACL["Growth Direction"] = true
