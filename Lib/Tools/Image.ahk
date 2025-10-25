#Requires AutoHotkey v2.0

; === Image Paths ===
global Minimize := "Images\minimizeButton.png" 
global Exitbutton := "Images\exitButton.png"
global Disconnected := "Images\disconnected.png"
global Import := "Images\import.png"
global Export := "Images\export.png"

;=== General FindText Text and Buttons ===
LobbySettings:="|<>*89$13.zTz7w0S0D273V3sEsQ8S0D07wTzTk"
ModeCancel:="|<>*134$70.zzzzzzzzzzzzzzzzzzzzzzzzwDzzzzzzzszz0DzzzzzzzXzs0TzzzzzzyDz01zzzzzzzszsDDzzzznz7XzVzw0k3w3k6DyDzU307U60Mzszw0A0A0kEXzXzkkkkkz72DyDz737X7w08zsTwQASATk1XzkMk0lsk33y7z01037X040MDy060ASC0M1Uzy1y8lsy7k73zzzzzzzzzzzzU"
Disconnect:="|<>*154$122.zznzzzzzzzzzzzzzzzzws7szzzzzzzzzzzzzDzzzC0TDzzzzzzzzzzzznzzznb3zzzzzzzzzzzzzwzzzwtwzzzzzzzzzzzzzzDzzzCT7DVy7kz8T8TkzV0S7sHblnUC0k7k3k3k7U060w0tyQsrXMswMwMstsrD7CCCTbCDlyDDDDDCTATnntXnblnkwzblnnnnU3Dww0NwtwQz3DtwQwwws0nzD06TCTDDwlyDDDDDCTwTnnzXnb3nbADXXnnnnXr3wQSsss1ws3UA1wwwww1s31UD0C1zD1y7kzDDDDkzVsS7sHU"
NextLevel:="|<>*113$31.0000000000000000S1s00TVy00MMVU0AAkk063MMA30wAzlUC7sQk73k2M1Vk1A0Ek0640MQ330A01Vk600ks33yMS1UvABUk0a6sQ0H6AD08z3wzwD0w7w0000000000E"
OpenChat:="|<>*154$30.zzzzzzzzzzw000Ds0007s0007s0007s0007s0007s7zs7s7zs7s0007s0007s0z07s1zU7s0007s0007s0007s0007s0007zs07zzy0Tzzz0zzzzVzzzznzzzzzzzU"
OpenLeaderboard:="|<>*107$11.zzTqTCQz7yDwTbCTBzTzk"
Spawn:="|<>*113$63.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw3zzzzzzzzz0Dzzzzzzzzs1zzzzzzzzz7TTzxvzizzsTk7U4QMU7z0S0M0V240zw1k1068FU3zs6C8kk0AQTzslk7701XXz7648ks0QQTs0k307V3XXz0C0Q0wMwQTy3lDl7nbXXzzyDzzzzzzzzzlzzzzzzzzzyDzzzzzzzzznzzzzzzzw"
NextText:="|<>*127$46.T7s000DX6Nk001zABX0006AkyAz77Mv1szzyzXw3XkCTA1k6C0EsU70Mk1U20QE3770S7lUA0S3sz70k1sDXwQ37z0S7lsA0s0s77ks13XkQTXkCTDXzzzzzzzzzzzzzzzs"
UnitExit:="|<>*141$18.zzzxzvszVkTVsD1w63y07z0DzUTzUTz0Ty0Dw47sC3sT1kTVsznzzzU"
UnitExistence :="|<>*91$66.btzzzzzzyDzXlzzzzzzyDzXlzzzzzzyDzXlzzzyzzyDbXlUS0UM3UC1XlUA0UE30A1XlW4EXl34AMXlX0sbXXC80XVX4MbXX6A1U3UA0bk30ARk7UC0bk3UA1sDUz8bw3kC1zzbyszzzzzzzzbw1zzzzzzzzby3zzzzzzzzzzjzzzzzzU"

;New UI
Teleports:="|<>*105$46.zy00Mzzzzk01Xzzzz002Dzzzy008zzzsTzzzrzy0zzzyDzsVzxwstz74N1V13wSFU040Dlt608MkzX4E1UX1y0844207w0kEMQEzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"
Story:="|<>*150$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU031s6DDzzzy1041k6QTzzzwznllbANzzzzszbbnCQ3zzzzkDCDaMwDzzzzsCQTA1szzzzzwQwyM3tzzzzyMtsEn7nzzzzw3ns3bDbzzzzwDbsDCTDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Raids:="|<>*150$44.zzzzzzzzzzzzzzz0zDn0w7k7lwk61wtsTAsbzCS3nD0zn74wnm1w1l7AwsD0M1nCDXn60An2Mwt7nA1UTCNwn1wDzzzzzzzzzzzzzzy"
Results:="|<>*145$71.007zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwD0svnT0CDzzk41UXYS0MDzzX8yD78zbXzzz6FyCCFzDXzzy0UQ4QXyT1zzw10y4t7wzVzzs2Dq9WDtxXzzlY10kA3nkDzzrA33kw3bkzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
NewUpgrade:="|<>*47$39.zzzzzzzzzzzzzzzzzzrzzAzzwzztVUF0Tz80003zs00U0TzW4603zznXzzzzywzzzU"
Defeat:="|<>*63$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzkzzzzzzzUDzz1zzztzzz07zy7zzzlzzy87zwTzzzXzzwSD1kC3sa1zzswQ10M3U83zzlwk30U60E7zzXlX776AMszzz7X0CC0NllzzyC6DwQTlXXzzw0QBssPU73zzs1s1lk3UC3zzk7w7bsDWS7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Victory:="|<>*103$71.zzzzzzzzzzzzzzzzzwzzzzzzzzwSD0zzzzzzzzsQQ3zzzzzzzzskMzzzzzzzzzlUlAXzzzzzzzV1681zzzzzzzU0AE3zzzzzzz0UMX7zzzzzzz11l77zzzzzzy73WCDzzzzzzwC74QTzzzzzzwQS8szzzzzzztwwnnzzzzzzzzzzzzzzzw"
Cleared:="|<>**50$66.00000000000DXs0000003zzyM0000006TkCM0000006N06M0000006M7CPz7zzzsyMDyT3wnAsRqMM6S1s30kD0MM6Q8k30V60MM2QQlX7XaAMAyQ0nnBU6STDyQTlXBXyAT064Rk3BXi0NU660s3Ak70MsT71wnAsBWNTvzzbzwTwzzU"
Retry:="|<>*115$29.000000000000000w20024+0047nzk9802EE09l0U2GW194ZY1zzmE0004U000600000000004"
Settings:="|<>*110$17.zzzzDzs7zX7zjTzSzwMzy7zyTzzzzzzk"
UnitManager:="|<>*108$56.zzzzzzzzzzzzzzzzzzyRwjjTzzzzbTvlXzzzztnkQ0zzzzyQ470032AEm5/k1G5+4w12Qw4UEVDWKbzF/6AHzzzzzzzXzzzzzzzzxzy"
UnitManagerDark:="|<>*53$31.zzzzzzzzzzwDUykQ7kS8C60D47U0703s03U1sFVm0yQqznTzzzzzzzzzz"
PortalSelection:="|<>*108$56.zzzzzzzzzzzzzzzzzzyRwjjTzzzzbTvlXzzzztnkQ0zzzzyQ470032AEm5/k1G5+4w12Qw4UEVDWKbzF/6AHzzzzzzzXzzzzzzzzxzy"
LobbyIcon:="|<>**50$11.TwX9SGwZ1/mLYX+"
AutoOff:="|<>*51$13.zzw1w0Q060301U0k0M0A060301k1w1zzw"
AutoOff2:="|<>*53$13.zzw1w0Q060301U0k0M0A060301U0s0y0zzy"

; Lastest Update
StorySelectButton:="|<>*119$37.0w70000n4U1k0kyLzY0EzDzn0A8aAEVz022Azzk10STzUSbXDztXMlrw"
StartButton:="|<>*121$25.00003s043y0735U6l2zzQW402wgdrtG4ty9WQzzzzzzzzz"
MaxUpgradeText:="|<>*120$55.zzzzzzzzzvrzxrzzzTslzwvzzzbw0zyQzzz3y02LC341V705Xm5+GZ/bUls0V8MVzwGyMsaAMzzzzwxTzzzzzzzzTzzzzzzzzzzzz"
RaidSelectButton:="|<>*120$29.00000S3U01a903a7mzwcTbztsFAMVs0EFbs0UDD0xD6TAP6CzzzzzzzzzzU"
DungeonSelectButton:="|<>*120$28.00000w6024MY0IVyTzO7tzswMaA3l2EbS492QwMqAHzzzzzzzzzs"
UnitManager:="|<>*121$67.zzzzzzzzzzzzzzzzzzzzzzwTjn3UTzzNzwDrtVwzzzjzyC1sEyMUA21XmJw8T9GIf2ZZ+y0DY92JVEslCxHr6lWGgTzzzzzzuzzyjzzzzzzzzzzzzzzzzzzzzzz"
AbilityManager:="|<>*118$65.zzzzzzzzzzz0Tznzv/xzjz3zzbzW7lzTz7zzDz4DXwTyMlWMw0S0UlwY+IZs0w1/9x+493m5t2GLz6AP7z9zlaDzxOzzzzzzzzzxvzzzzzzzzzzzzzzzzzzk"
IngameQuests:="|<>*90$9.zw1bA1jg1bA1zw"
ChoosePortal:="|<>*116$31.zzzzzzzzzzy3zzzy1zzzyAA833C001VX800Us6028y7NnCTzzzzzzzzzz"
ChoosePortalHighlighted:="|<>*127$35.000000D03w01V088023znzzcs0061HU0083X0GMk6U0olYhXDzjzMzzzzzU00000E"

;Portals (549, 230, 628, 249)
SummerLaguna:="|<>*127$70.zzzzzzzzDzzvzzzzzzzzzzziTzzzzzzwzzzlzzzzznzvzzyTzzzzzDzzzzwPFgP6Ay8KXWkA0000nkUE4/kl0E0DCEV24g86lgQww8EA3lVPKoPsEV2oDzzzzzzzybzzs"

; === Sun Jin Woo ===
Rebirth:="|<>*98$67.zzzzzzzzzzzzy3zsyDwtzzzz0TwT7wQzzzzU7yDzyCTzzzlW30F010zzzs08U800UDzzw10F43ln7zzy0U8W1stXzzz4FAF0wQlzzzW420WT2MzzznX70nDlCTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzVxzztzDzysTqUJYQHb5FRjsBO6iKnOeCrxEh3L/NVILPyUG1foA8q/Vzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
SecondRebirth:="|<>*98$60.zzzzzzzzzzzzzzzzzzzzzUTyTbwMzzzUDyTbwMzzzU7y3jw8bzzX4614003zzU4204483zzU8284QMlzzW8284QMlzzW8m04Q8lzzX4204S0lzzXa61YT0nzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzVxzzryzzrXh4gFWCwSLPVJgoqiu9bNU5gooas87NhJcoqiv1b/h6krmC4qTXzzzzzzzzzzzzzzzzzzzzU"

; === Boss Rush Bosses ===
Gilgamesh:="|<>*180$20.0000003rU0b/09nzyMVVUMMNo4mQZUrMMLTxw000U"

; === Upgrade Limits === (630, 375, 717, 385)
Upgrade0:="|<>*49$6.zvlZZUkzzU"
Upgrade1:="|<>*47$6.zztltsszzzU"
Upgrade2:="|<>*45$8.zzzCVcHYUM7zzs"
Upgrade3:="|<>*52$8.zyz6lCG1kTy"
Upgrade4:="|<>*54$9.zyAVg9kTXzw"
Upgrade5:="|<>*47$8.zyT3lg/klDy"
Upgrade6:="|<>*47$6.zzzlXVUkzzU"
Upgrade7:="|<>*41$10.zzzwBknmSNtDgzzzy"
Upgrade8:="|<>*69$8.zzz6VgK5mzy"
Upgrade9:="|<>*48$8.zwu6VAH1WTzzU"
Upgrade10:="|<>*43$11.zzzztq1c2MEk3Y7zzzs"
Upgrade11:="|<>*41$11.zzzr1Y2QYt3m7zzzw"
Upgrade12:="|<>*45$13.zzzzznj0n0Hn9s1w0zzzzy"
Upgrade13:="|<>*45$11.zzzztq1cWNYk3U7zzzs"
Upgrade14:="|<>*44$13.zzzyw341/0bU7nXzzzzw"

; === Nuke Wave Configuration ===
Wave20 := "|<>*84$16.zzzzzz6DsETY9zYbwGzUXzzzzzy"
Wave50 := "|<>*110$10.zz4M1WG1C5n7zs"

; === Boss Rush ===
BossRushEnter:="|<>*117$24.TUk0UFM0UTDzU001V003V907VB0rkTgzzzzzU"

; === Survival ===
SurvivalSelect:="|<>*115$28.00000w6024MY0IVyTzO7tzswMaA3l+GbS492QwsqAHzzzzzzzzzs"
