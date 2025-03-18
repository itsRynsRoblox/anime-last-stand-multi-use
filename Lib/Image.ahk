#Requires AutoHotkey v2.0

;GUI
global Minimize := "Images\minimizeButton.png" 
global Exitbutton := "Images\exitButton.png" 

;FindText Text and Buttons
AreaText:="|<>*109$36.szzzzzszyzzzkM8A27mM842LU8k0W7U8k8X770sA07DZwC27zzzzzzzzzzzzU"
ModeCancel:="|<>*134$70.zzzzzzzzzzzzzzzzzzzzzzzzwDzzzzzzzszz0DzzzzzzzXzs0TzzzzzzyDz01zzzzzzzszsDDzzzznz7XzVzw0k3w3k6DyDzU307U60Mzszw0A0A0kEXzXzkkkkkz72DyDz737X7w08zsTwQASATk1XzkMk0lsk33y7z01037X040MDy060ASC0M1Uzy1y8lsy7k73zzzzzzzzzzzzU"
AutoOff:="|<>*80$27.zzzzzzzzzzzzzzzzzzzzzzzzzzzzVsXzk64Ty8F7zXU0TwS03zXmMzyQH7zk6Mzz1nbzzzzzzzzzzzzzzzzzzzzzzzU"
Disconnect:="|<>*154$122.zznzzzzzzzzzzzzzzzzws7szzzzzzzzzzzzzDzzzC0TDzzzzzzzzzzzznzzznb3zzzzzzzzzzzzzwzzzwtwzzzzzzzzzzzzzzDzzzCT7DVy7kz8T8TkzV0S7sHblnUC0k7k3k3k7U060w0tyQsrXMswMwMstsrD7CCCTbCDlyDDDDDCTATnntXnblnkwzblnnnnU3Dww0NwtwQz3DtwQwwws0nzD06TCTDDwlyDDDDDCTwTnnzXnb3nbADXXnnnnXr3wQSsss1ws3UA1wwwww1s31UD0C1zD1y7kzDDDDkzVsS7sHU"
NextLevel:="|<>*113$31.0000000000000000S1s00TVy00MMVU0AAkk063MMA30wAzlUC7sQk73k2M1Vk1A0Ek0640MQ330A01Vk600ks33yMS1UvABUk0a6sQ0H6AD08z3wzwD0w7w0000000000E"
LobbyText:="|<>*135$54.600408000DU0T0y000Rk0vVr000Mk0lVX000Mk0lVX000MlyltXlswMrzlzXzxzMy3l7WDDXMw0k3U67Xss0k1U333ssMElVX37sswFkXVU7sswFkXVkDssMEVV3kDs80k1U3sTsA1k3U7sTwC3l7WDsTzzzzzzzszzzzzzzzkzzzzzzzzlzzzzzzzzlzzzzzzzzzzzzzzzzzzzU"
LobbyText2:="|<>*114$69.3y0000000000zw00y000000A1k07s000001U301X000000A0AzAQswzbQ1VVzzXzjzzzsAS70s37b4MXVXkk20MsM306AQA0E3730M0lU1XXVssMT22A0M0QT737ssNU103XssMn73AQATwD236MsNXlU3UM0Mn73AS60S3U36MsNXts7sy4sn7bDvzznyzzyTzkyDDwDVzjVwwU"
OpenChat:="|<>*154$30.zzzzzzzzzzw000Ds0007s0007s0007s0007s0007s7zs7s7zs7s0007s0007s0z07s1zU7s0007s0007s0007s0007s0007zs07zzy0Tzzz0zzzzVzzzznzzzzzzzU"
Spawn:="|<>*113$63.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw3zzzzzzzzz0Dzzzzzzzzs1zzzzzzzzz7TTzxvzizzsTk7U4QMU7z0S0M0V240zw1k1068FU3zs6C8kk0AQTzslk7701XXz7648ks0QQTs0k307V3XXz0C0Q0wMwQTy3lDl7nbXXzzyDzzzzzzzzzlzzzzzzzzzyDzzzzzzzzznzzzzzzzw"
NextText:="|<>*127$46.T7s000DX6Nk001zABX0006AkyAz77Mv1szzyzXw3XkCTA1k6C0EsU70Mk1U20QE3770S7lUA0S3sz70k1sDXwQ37z0S7lsA0s0s77ks13XkQTXkCTDXzzzzzzzzzzzzzzzs"
UnitExit:="|<>*141$18.zzzxzvszVkTVsD1w63y07z0DzUTzUTz0Ty0Dw47sC3sT1kTVsznzzzU"
UnitExistence :="|<>*91$66.btzzzzzzyDzXlzzzzzzyDzXlzzzzzzyDzXlzzzyzzyDbXlUS0UM3UC1XlUA0UE30A1XlW4EXl34AMXlX0sbXXC80XVX4MbXX6A1U3UA0bk30ARk7UC0bk3UA1sDUz8bw3kC1zzbyszzzzzzzzbw1zzzzzzzzby3zzzzzzzzzzjzzzzzzU"

StoryPillar:="|<>*99$58.0000000000004080000000000000000000000000000000000100000000060001U0000M07zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz00001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000003zzw000000Tzzk000000zzz0000003zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw0000007zzk000000Tzz0000001zzw000U"
RaidPillar:="|<>*104$71.000000E0000000000zzk0003zzk0Dzzz03zszzx0TzzwHzzkTzzs0Tk1zzz0Tzzk0003zzszzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw0000zzzU00000001zzzU00000003zzzU00000007zzy00000000Dzzw00000000TzzU00000000zzz000000001zzy000000003zzw000000007zzs00000000Dzzk0001"

CentralCity:="|<>*88$302.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz01zzzzzzzzzzzzzzzzzzzzzzzzzs00003zzzzzzzzzzzzzzzzz007zzzzzzzzzzzzzzzzzzzzzzzzs00000TzzzzzzzzzzzzzzzzU00Tzzzzzzzzzzzzzzzzzzzzzzzy000003zzzzzzzzzzzzzzzzk003zzzzzzzzzzzzzzzzzzzzzzzzU00000zzzzzzzzzzzzzzzzs000zzzzzzzzzzzzzzzzzzzzzzzzs00000Dzzzzzzzzzzzzzzzw0007zzzzzzzzzzzzzzzzzzzzzzzy000003zzzzzzzzzzzzzzzz0001zzzzzzzzzzzzzzzzzzzzzzzzU00001zzzzzzzzzzzzzzzzU000zzzzzzzzzzzzzzzzzzzzzzzzy00001zzzzzzzzzzzzzzzzs0T0Tzzzzzzzzzzzzzzzzzzzzzzzzzz07zzzzzzzzzzzzzzzzzy0Ds7zzzzzzzzzzzzzzzzzzzzzzzzzzk1zzzzzzzzzzzzzzzzzzU3zbzzzzzzzw3zznzzzzDz7zzDzzzzw0Tzzs7zzbzzzyTzzzzzs0zzzs3U7zzs07zkDw7z0z0zzUTzzzz07zzk0DzUTsDy1y0s1zy0Dzzw0k0Tzs00Tk3y0zk7UDzk3zzzzk1zzk00zU7w1zUD0A07zU0zzz0003zw003w0TU7s0k1zw0zzzzw0Tzs007s0z0Dk1k000zs01zzk000Ty000T07k1y0A0Ty0Dzzzz07zw000y0DU3w0Q0007z001zw0003z0003k1w0D0303zU3zzzzk1zy0007U3s0S070000zk003z0000zU000Q0D03k1s0Tk0zzzzw0Tz0000s0S07U3k000Dy000Dk0007s0007U3U0w0S07w0Tzzzz07zk000D0701s0w0001zk001w0001w0000s0s060Dk0y07zzzzk1zs0001k1k0A0T0000Ty000T00k0D01s0D0601U3w0DU3zzzzw0Ty03s0S0A0307k0A03zs003k0z03k1zU3k10080zU1k0zzzzz07zU3z07U200E1w0Dk0zzk00w0Ts0s0Ts0Q00000Tw0A0Tzzzzk1zk0zk0s00000z07y0Dzzk0707y0C0Dz07U00007z0307zzzzw0Tw0Ty0D00000Dk1zU3zzzU1k1zU3U3zk1s00003zs001zzzzz07z07zU3k00007w0Ts0zzzw0Q0Tw0s0zw0T00000zy000zzzzzk1zk1zs0y00001z07z0DsTz0707z0C0Dz07k0000Dzk00Dzzzzw0Tw0Ty0DU0000Tk1zk3w3zk1k1zk3k1zU3y00007zy007zzzzz07zU3z07w0000Dw0Tw0y0Dw0Q0Tw0w0Dk0zU0A01zzU01zzzzzk1zs0TU1z00E03z07z0D01y0D07z0D00k0Ds0300zzw00zzzzzw0Ty01U0Tk0601zk1zk3k0003k1zk3s0007z01k0Dzz00Dzzzzz07zk000Dy03U0Tw0Tw0y0000w0Tw0y0001zk0S03zzs07zzzzzk1zw0003zU0w07z07z0DU000T07z0Dk000zy07U1zzz01zzzzzw0TzU001zw0D03zk1zk3w0007k1zk3y000DzU3s0Tzzk0Tzzzzz07zw000Tz07k0zw0Tw0zU003w0Tw0zU007zs0z0Dzzy0Dzzzzzk1zz000Dzk1y0Tz07z0Dw001z07z0Dy003zz0Dk3zzz03zzzzzw0zzw00Dzy0TU7zk1zk3zk01zs3zk3zk03zzk7y1zzzk1zzzzzz0DzzU07zzUDw3zy0zw0zz01zz1zy1zz03zzz3zkzzzs0Tzzzzzs7zzy07zzy7zVzzkTzUTzzzzzzzzzzzzzzzzzzzzzzy0Dzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz03zzzzzzzzzzzzzzzzzzzzzzzzzs"

;New UI
Teleports:="|<>*105$46.zy00Mzzzzk01Xzzzz002Dzzzy008zzzsTzzzrzy0zzzyDzsVzxwstz74N1V13wSFU040Dlt608MkzX4E1UX1y0844207w0kEMQEzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"
Story:="|<>*150$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU031s6DDzzzy1041k6QTzzzwznllbANzzzzszbbnCQ3zzzzkDCDaMwDzzzzsCQTA1szzzzzwQwyM3tzzzzyMtsEn7nzzzzw3ns3bDbzzzzwDbsDCTDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Raids:="|<>*150$44.zzzzzzzzzzzzzzz0zDn0w7k7lwk61wtsTAsbzCS3nD0zn74wnm1w1l7AwsD0M1nCDXn60An2Mwt7nA1UTCNwn1wDzzzzzzzzzzzzzzy"
BaseHealth:="|<>*72$70.zzzzzzzzzzzzk0000000000A00000000000k0000000000200000000000800000000000U0000000000200000000000800000000000U0000000000300000000000C00000000000w00000000003zzzzzzzzzzzs"
Results:="|<>*145$71.007zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwD0svnT0CDzzk41UXYS0MDzzX8yD78zbXzzz6FyCCFzDXzzy0UQ4QXyT1zzw10y4t7wzVzzs2Dq9WDtxXzzlY10kA3nkDzzrA33kw3bkzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
NewUpgrade:="|<>*47$39.zzzzzzzzzzzzzzzzzzrzzAzzwzztVUF0Tz80003zs00U0TzW4603zznXzzzzywzzzU"
NewMaxUpgaded:="|<>*87$71.0000000000000000000000000000000000000000000000000tk0Rk003U002QE14E009U004Mzy8zzznw0081zwFzzy7s00E00MUM008s00U0Fl20800kDzD0Xk12E03zzyS2Ll34lX7zzzzzzySDzzzzzzzzzwwzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Defeat:="|<>*63$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzkzzzzzzzUDzz1zzztzzz07zy7zzzlzzy87zwTzzzXzzwSD1kC3sa1zzswQ10M3U83zzlwk30U60E7zzXlX776AMszzz7X0CC0NllzzyC6DwQTlXXzzw0QBssPU73zzs1s1lk3UC3zzk7w7bsDWS7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Victory:="|<>*103$71.zzzzzzzzzzzzzzzzzwzzzzzzzzwSD0zzzzzzzzsQQ3zzzzzzzzskMzzzzzzzzzlUlAXzzzzzzzV1681zzzzzzzU0AE3zzzzzzz0UMX7zzzzzzz11l77zzzzzzy73WCDzzzzzzwC74QTzzzzzzwQS8szzzzzzztwwnnzzzzzzzzzzzzzzzw"
Cleared:="|<>**50$66.00000000000DXs0000003zzyM0000006TkCM0000006N06M0000006M7CPz7zzzsyMDyT3wnAsRqMM6S1s30kD0MM6Q8k30V60MM2QQlX7XaAMAyQ0nnBU6STDyQTlXBXyAT064Rk3BXi0NU660s3Ak70MsT71wnAsBWNTvzzbzwTwzzU"

Retry:="|<>*115$29.000000000000000w20024+0047nzk9802EE09l0U2GW194ZY1zzmE0004U000600000000004"
Settings:="|<>*110$17.zzzzDzs7zX7zjTzSzwMzy7zyTzzzzzzk"
UnitManager:="|<>*130$62.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzyPwjCTzzzzzaTvl7zzzzztUEQ14AMl7yOEj058IdHzkY9nUG124zwNGQt4gMlDzzzzzzzyDzzzzzzzzzbzzzzzzzzzzzzzzzzzzzzzzy"
PortalSelection:="|<>*104$76.0000000000000Tk0000001Uw031U000000/2E0M3zzzrzzzjt036241VkkE4M7zws0046100F0TzlU00EM403Y1zzUM00Vkk0CM7zz1gtb737YtVEDzzzzzzyzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"



