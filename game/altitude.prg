program altitude  ;

global

int LevelCounter;
int TimeCounter;
int ReLoad;
int FireShield;
int FireShield2;
int GlobalPlayer1X;
int GlobalPlayer1Y;
int GlobalPlayer2X;
int GlobalPlayer2Y;
int Player1Alive;
int Player2Alive;
int Thruster;
int Thruster2;
int AntiGravity;
int AntiGravity2;
int ReverseGravity;
int ReverseGravity2;
int Player1Score;
int Player2Score;
int SelectedOption;
int SelectedLevel;
int WaitForSelection;
int WaitCounter;
int Sound;
int LevelFinished;
int GameOver;
int Lives;
int ContinuePlay;
int HighScore;

int MenuMusic;
int BackgroundMusic;

int VoiceAntiGravity;
int VoiceArcade;
int VoiceCongratulations;
int VoiceFireShield;
int VoiceLevel1;
int VoiceLevel2;
int VoiceLevel3;
int VoiceLevel4;
int VoiceLevel5;
int VoiceLevel6;
int VoiceLevel7;
int VoicePlayer1Win;
int VoicePlayer2Win;
int VoiceReverseGravity;
int VoiceSoundOn;
int VoiceThruster;
int VoiceTraining;
int VoiceTwoPlayerArcade;
int VoiceTwoPlayerBattle;
int VoiceGameOver;

int SoundCrystal;
int SoundExplosion;
int SoundSelect;
int SoundThrusterSound;

begin

load("score.dat",HighScore);

load_fpg("altitude.fpg");

MenuMusic=load_song("alt1.mod");
BackgroundMusic=load_song("alt2.mod");

VoiceAntiGravity=load_wav("antigravity.wav");
VoiceArcade=load_wav("arcade.wav");
VoiceCongratulations=load_wav("congratulations.wav");
VoiceFireShield=load_wav("fireshield.wav");
VoiceLevel1=load_wav("level1.wav");
VoiceLevel2=load_wav("level2.wav");
VoiceLevel3=load_wav("level3.wav");
VoiceLevel4=load_wav("level4.wav");
VoiceLevel5=load_wav("level5.wav");
VoiceLevel6=load_wav("level6.wav");
VoiceLevel7=load_wav("level7.wav");
VoicePlayer1Win=load_wav("player1win.wav");
VoicePlayer2Win=load_wav("player2win.wav");
VoiceReverseGravity=load_wav("reversegravity.wav");
VoiceSoundOn=load_wav("soundon.wav");
VoiceThruster=load_wav("thruster.wav");
VoiceTraining=load_wav("training.wav");
VoiceTwoPlayerArcade=load_wav("twoplayerarcade.wav");
VoiceTwoPlayerBattle=load_wav("twoplayerbattle.wav");
VoiceGameOver=load_wav("gameover.wav");

SoundCrystal=load_wav("crystal.wav");
SoundExplosion=load_wav("explosion.wav");
SoundSelect=load_wav("select.wav");
SoundThrusterSound=load_wav("thrustersound.wav");

Full_Screen=true;
set_mode(320,240,8);
Sound=1;

loop

ReverseGravity=0;
ReverseGravity2=0;
AntiGravity=0;
AntiGravity2=0;
Thruster=0;
Thruster2=0;
FireShield=0;
FireShield2=0;

if (ContinuePlay==0)

stop_song();
if (Sound==1)
  play_song(MenuMusic,-1);
  set_song_volume(100);
end

SelectedOption=1;
SelectedLevel=0;
WaitForSelection=0;
LevelFinished=0;
GameOver=0;
Player1Score=0;
Player2Score=0;
ReLoad=0;
Lives=5;

write(0,5,230,0,"HighScore : ");
write(0,215,230,0,"Made by Imerion");
write_int(0,80,230,0,&HighScore);
DisplayTitle(96);
MenuOption(72);

loop

if (key(_left) and WaitForSelection==0)
   WaitCounter=1;
   repeat
   frame;
   WaitCounter=WaitCounter+1;
   until (WaitCounter==30)
   
   WaitForSelection=1;
   SelectedOption=SelectedOption-1;
end

if (key(_right) and WaitForSelection==0)
   WaitCounter=1;
   repeat
   frame;
   WaitCounter=WaitCounter+1;
   until (WaitCounter==30)

   WaitForSelection=1;
   SelectedOption=SelectedOption+1;
end


if (SelectedOption==8)
  SelectedOption=1;
end
if (SelectedOption==0)
  SelectedOption=7;
end

if (SelectedOption==1 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(72);
end
if (SelectedOption==2 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(73);
end
if (SelectedOption==3 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(74);
end
if (SelectedOption==4 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(98);
end
if (SelectedOption==5 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(75);
end
if (SelectedOption==6 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(102);
end
if (SelectedOption==7 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(76);
end

if (key(_enter))
   if (Sound==1)
     play_wav(SoundSelect,0);
   end

  if (SelectedOption==1)
    if (Sound==1)
      play_wav(VoiceArcade,0);
    end
    signal (type MenuOption, s_kill);
    ZoomMenu(72);
    break;
  end
  
  if (SelectedOption==2)
    if (Sound==1)
      play_wav(VoiceTraining,0);
    end
    signal (type MenuOption, s_kill);
    ZoomMenu(73);
    break;
  end
  
  if (SelectedOption==3)
    if (Sound==1)
      play_wav(VoiceTwoPlayerBattle,0);
    end
    signal (type MenuOption, s_kill);
    ZoomMenu(74);
    break;
  end

  if (SelectedOption==4)
    if (Sound==1)
      play_wav(VoiceTwoPlayerBattle,0);
    end
    signal (type MenuOption, s_kill);
    ZoomMenu(98);
    break;
  end

  if (SelectedOption==5)
    signal (type MenuOption, s_kill);
    ZoomMenu(75);
    if (Sound==1)
      Sound=0;
      stop_song();
      SoundMenuOption(88);
      WaitForSelection=0;
    elseif (Sound==0)
      Sound=1;
      if (Sound==1)
        play_song(MenuMusic,-1);
        set_song_volume(100);
      end
      if (Sound==1)
        play_wav(VoiceSoundOn,0);
      end
      SoundMenuOption(87);
      WaitForSelection=0;
    end
      MenuOption(75);
  end
  
  if (SelectedOption==6)
    signal (type MenuOption, s_kill);
    ZoomMenu(102);
    WaitCounter=1;
    repeat
      frame;
      WaitCounter=WaitCounter+1;
    until (WaitCounter==15)

    RedPowerUp(75,0,-3,3,2,90);
    GreenPowerUp(100,0,-3,3,2,90);
    BluePowerUp(125,0,-3,3,2,90);
    YellowPowerUp(150,0,-3,3,2,90);
    RedPoint(175,0,-3,3,2,90);
    GreenPoint(200,0,-3,3,2,90);
    write(0,160,75,0,"Fire Shield");
    write(0,160,100,0,"Anti Gravity");
    write(0,160,125,0,"Reverse Gravity");
    write(0,160,150,0,"Thruster");
    write(0,160,175,0,"1000 Points");
    write(0,160,200,0,"10000 Points");
    frame;
    loop
      frame;
      if (key(_enter)) break; end
    end
    
    signal (type RedPowerUp, s_kill);
    signal (type BluePowerUp, s_kill);
    signal (type YellowPowerUp, s_kill);
    signal (type GreenPowerUp, s_kill);
    signal (type RedPoint, s_kill);
    signal (type GreenPoint, s_kill);
    signal (type PowerUpLight, s_kill);

    delete_text(0);
    write(0,5,230,0,"HighScore : ");
    write(0,215,230,0,"Made by Imerion");
    write_int(0,80,230,0,&HighScore);
    WaitForSelection=0;
    MenuOption(102);
    
  end
  
  if (SelectedOption==7)
    signal (type MenuOption, s_kill);
    ZoomMenu(76);
      WaitCounter=1;
      repeat
      frame;
      WaitCounter=WaitCounter+1;
      until (WaitCounter==15)
    exit("Quit",0);
  end
  
  WaitCounter=1;
  repeat
  frame;
  WaitCounter=WaitCounter+1;
  until (WaitCounter==30)
end

frame;
end

WaitCounter=1;
repeat
frame;
WaitCounter=WaitCounter+1;
until (WaitCounter==10)


if (SelectedOption==2 or SelectedOption==3)

SelectedLevel=1;
signal (type MenuOption, s_kill);
MenuOption(89);

loop

if (key(_left) and WaitForSelection==0)
   WaitCounter=1;
   repeat
   frame;
   WaitCounter=WaitCounter+1;
   until (WaitCounter==30)

   WaitForSelection=1;
   SelectedLevel=SelectedLevel-1;
end

if (key(_right) and WaitForSelection==0)
   WaitCounter=1;
   repeat
   frame;
   WaitCounter=WaitCounter+1;
   until (WaitCounter==30)

   WaitForSelection=1;
   SelectedLevel=SelectedLevel+1;
end


if (SelectedLevel==8)
  SelectedLevel=1;
end
if (SelectedLevel==0)
  SelectedLevel=7;
end

if (SelectedLevel==1 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(89);
end
if (SelectedLevel==2 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(90);
end
if (SelectedLevel==3 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(91);
end
if (SelectedLevel==4 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(92);
end
if (SelectedLevel==5 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(93);
end
if (SelectedLevel==6 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(94);
end
if (SelectedLevel==7 and WaitForSelection==1)
  WaitForSelection=0;
  MenuOption(95);
end

if (key(_enter))

  if (SelectedLevel==1)
    signal (type MenuOption, s_kill);
    ZoomMenu(89);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==2)
    signal (type MenuOption, s_kill);
    ZoomMenu(90);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==3)
    signal (type MenuOption, s_kill);
    ZoomMenu(91);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==4)
    signal (type MenuOption, s_kill);
    ZoomMenu(92);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==5)
    signal (type MenuOption, s_kill);
    ZoomMenu(93);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==6)
    signal (type MenuOption, s_kill);
    ZoomMenu(94);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end
  if (SelectedLevel==7)
    signal (type MenuOption, s_kill);
    ZoomMenu(95);
    WaitCounter=1;
    repeat
    frame;
    WaitCounter=WaitCounter+1;
    until (WaitCounter==15)
    break;
  end



  WaitCounter=1;
  repeat
  frame;
  WaitCounter=WaitCounter+1;
  until (WaitCounter==30)
end

frame;
end
end

end   //ContinueEnd

stop_song();
if (Sound==1)
  play_song(BackgroundMusic,-1);
  set_song_volume(100);
end
delete_text(0);


if (SelectedOption==2)

let_me_alone();
Player1Alive=1;
Player1(7, -7,2,1,1,0); //MaxUp, MaxDown, SpeedUp, SpeedDown, ShipType
ActiveGround(16,3, 12,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 12,2);
ActiveGround(16,3, 227,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 227,2);
BkGround(2, 2, 115,3); // Graph, ScrollSpeed, y, z
BkGround2(2,2,115,3);
Player1Score=0;
if (SelectedLevel==1) LevelOneControl(); end
if (SelectedLevel==2) LevelTwoControl(); end
if (SelectedLevel==3) LevelSixControl(); end
if (SelectedLevel==4) LevelFourControl(); end
if (SelectedLevel==5) LevelFiveControl(); end
if (SelectedLevel==6) LevelThreeControl(); end
if (SelectedLevel==7) LevelSevenControl(); end

repeat
if (Player1Alive==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
if (LevelFinished==1 or LevelFinished==2 or LevelFinished==3 or LevelFinished==4 or LevelFinished==5 or LevelFinished==6)
LevelFinished=7;
end

frame;
until (LevelFinished==7 or GameOver==1)
let_me_alone();

end




if (SelectedOption==3)

let_me_alone();
Player1Alive=1;
Player2Alive=1;
Player1(7, -7,2,1,1,0); //MaxUp, MaxDown, SpeedUp, SpeedDown, ShipType
Player2(7, -7,2,1,77,0);
ActiveGround(16,3, 12,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 12,2);
ActiveGround(16,3, 227,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 227,2);
BkGround(2, 2, 115,3); // Graph, ScrollSpeed, y, z
BkGround2(2,2,115,3);
Player1Score=0;
Player2Score=0;
if (SelectedLevel==1) LevelOneControl(); end
if (SelectedLevel==2) LevelTwoControl(); end
if (SelectedLevel==3) LevelSixControl(); end
if (SelectedLevel==4) LevelFourControl(); end
if (SelectedLevel==5) LevelFiveControl(); end
if (SelectedLevel==6) LevelThreeControl(); end
if (SelectedLevel==7) LevelSevenControl(); end

repeat
if (Player1Alive==0 and Player2Alive==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
if (LevelFinished==1 or LevelFinished==2 or LevelFinished==3 or LevelFinished==4 or LevelFinished==5 or LevelFinished==6)
  LevelFinished=7;
end

frame;
until (LevelFinished==7 or GameOver==1)
let_me_alone();

end



if (SelectedOption==1)

if (ContinuePlay==0) SelectedLevel=1; end
let_me_alone();
Player1Alive=1;
Player1(7, -7,2,1,1,0); //MaxUp, MaxDown, SpeedUp, SpeedDown, ShipType
ActiveGround(16,3, 12,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 12,2);
ActiveGround(16,3, 227,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 227,2);
BkGround(2, 2, 115,3); // Graph, ScrollSpeed, y, z
BkGround2(2,2,115,3);
LifeCounter1();
LifeCounter2();
LifeCounter3();
LifeCounter4();
LifeCounter5();
Player1Score=0;

if (ContinuePlay==0 or LevelFinished==0) ZoomMenu(89); end
if (ContinuePlay==0 or LevelFinished==0) LevelOneControl(); end

repeat
  if (Player1Alive==0 and GameOver==0)
    WaitCounter=1;
    repeat
      frame;
      WaitCounter=WaitCounter+1;
    until (WaitCounter==25)
    let_me_alone();
    GameOver=1;
  end
frame;
until (LevelFinished=>1 or GameOver==1)
if (GameOver==0 and LevelFinished==1)
  ZoomMenu(90);
  LevelTwoControl();
end

repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished=>2 or GameOver==1)

if (GameOver==0 and LevelFinished==2)
  ZoomMenu(91);
  LevelSixControl();
end

repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished=>3 or GameOver==1)
if (GameOver==0 and LevelFinished==3)
  ZoomMenu(92);
  LevelFourControl();
end
repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished=>4 or GameOver==1)
if (GameOver==0 and LevelFinished==4)
  ZoomMenu(93);
  LevelFiveControl();
end
repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished=>5 or GameOver==1)
if (GameOver==0 and LevelFinished==5)
  ZoomMenu(94);
  LevelThreeControl();
end
repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished=>6 or GameOver==1)
if (GameOver==0 and LevelFinished==6)
  ZoomMenu(95);
  LevelSevenControl();
end
repeat
if (Player1Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==7 or GameOver==1)
end




if (SelectedOption==4)

SelectedLevel=1;
let_me_alone();
Player1Alive=1;
Player2Alive=1;
Player1(7, -7,2,1,1,0); //MaxUp, MaxDown, SpeedUp, SpeedDown, ShipType
Player2(7, -7,2,1,77,0);
ActiveGround(16,3, 12,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 12,2);
ActiveGround(16,3, 227,2); // Graph, ScrollSpeed, y, z
ActiveGround2(16,3, 227,2);
BkGround(2, 2, 115,3); // Graph, ScrollSpeed, y, z
BkGround2(2,2,115,3);
Player1Score=0;
Player2Score=0;
LevelOneControl();

repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==1 or GameOver==1)
if (GameOver==0)
  ZoomMenu(90);
  LevelTwoControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==2 or GameOver==1)
if (GameOver==0)
  ZoomMenu(91);
  LevelSixControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==3 or GameOver==1)
if (GameOver==0)
  ZoomMenu(92);
  LevelFourControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==4 or GameOver==1)
if (GameOver==0)
  ZoomMenu(93);
  LevelFiveControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==5 or GameOver==1)
if (GameOver==0)
  ZoomMenu(94);
  LevelThreeControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==6 or GameOver==1)
if (GameOver==0)
  ZoomMenu(95);
  LevelSevenControl();
end
repeat
if (Player1Alive==0 and Player2Alive==0 and GameOver==0)
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==25)
  let_me_alone();
  GameOver=1;
end
frame;
until (LevelFinished==7 or GameOver==1)
end


delete_text(0);

if (SelectedOption==1 and GameOver==1 and Lives>0)
  Lives=Lives-1;
  GameOver=0;
  ContinuePlay=1;
end

if (Lives==0)
  ContinuePlay=0;
  GameOver=1;
end


if (GameOver==1)
DisplayTitle(96);
Message(100);
stop_song();
if (Sound==1)
  play_song(MenuMusic,-1);
  set_song_volume(100);
end
if (Sound==1)
  play_wav(VoiceGameOver,0);
end
repeat
  frame;
until (key(_enter))
Message(99);
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==20)

  write(0,115,117,0,"P1 : ");
  write_int(0,145,117,0,&Player1Score);
  if (SelectedOption==4 or SelectedOption==3)

     if (Player1Score>Player2Score)
       if (Sound==1)
         play_wav(VoicePlayer1Win,0);
       end
     end
     if (Player2Score>Player1Score)
      if (Sound==1)
        play_wav(VoicePlayer2Win,0);
      end
    end
    
    write(0,115,129,0,"P2 : ");
    write_int(0,145,129,0,&Player2Score);
  end
repeat
  frame;
until (key(_enter))

end



if (LevelFinished==7)
DisplayTitle(96);
Message(97);
stop_song();
if (Sound==1)
  play_song(MenuMusic,-1);
  set_song_volume(100);
end
if (Sound==1)
  play_wav(VoiceCongratulations,0);
end
repeat
  frame;
until (key(_enter))
Message(99);
  WaitCounter=1;
  repeat
    frame;
    WaitCounter=WaitCounter+1;
  until (WaitCounter==20)

  write(0,115,117,0,"P1 : ");
  write_int(0,145,117,0,&Player1Score);
  if (SelectedOption==4 or SelectedOption==3)
  
     if (Player1Score>Player2Score)
       if (Sound==1)
         play_wav(VoicePlayer1Win,0);
       end
     end
     if (Player2Score>Player1Score)
      if (Sound==1)
        play_wav(VoicePlayer2Win,0);
      end
    end

     write(0,115,129,0,"P2 : ");
    write_int(0,145,129,0,&Player2Score);
  end
repeat
  frame;
until (key(_enter))

end

if (Player1Score>HighScore)
  HighScore=Player1Score;
  save("score.dat",HighScore);
end
if (Player2Score>HighScore)
  HighScore=Player2Score;
  save("score.dat",HighScore);
end

delete_text(0);
WaitCounter=1;
repeat
  frame;
  WaitCounter=WaitCounter+1;
until (WaitCounter==10)


end
end






process Player1(MaxUp, MaxDown, SpeedUp, SpeedDown,ShipType,flags);
private
wait;
DownForce;

begin
z=1;
x=40;
y=100;
graph=ShipType;

write(0,215,1,0,"Score : ");
write_int(0,265,1,0,&Player1Score);

loop

if (ReverseGravity==0)
  if (key(_up) or key(_backspace))
    DownForce=Downforce-SpeedUp;
  end
end

if (AntiGravity==1)
  if (key(_down) or key(_tab))
    DownForce=DownForce+SpeedUp;
  end
end

if (ReverseGravity==1)
  if (key(_down) or key(_tab))
    DownForce=DownForce+SpeedUp;
  end
end

if (AntiGravity==0 and ReverseGravity==0)
  DownForce=DownForce+SpeedDown;
end

if (ReverseGravity==1)
  DownForce=DownForce-SpeedDown;
end




if (DownForce>MaxUp) DownForce=MaxUp; end
if (DownForce<MaxDown) DownForce=MaxDown; end

if (DownForce==0) graph=1; end
if (DownForce==1 or DownForce==2) graph=23; end
if (DownForce==3 or DownForce==4) graph=24; end
if (DownForce==5 or DownForce==6) graph=25; end
if (DownForce==7) graph=26; end
if (DownForce==-1 or DownForce==-2) graph=27; end
if (DownForce==-3 or DownForce==-4) graph=28; end
if (DownForce==-5 or DownForce==-6) graph=29; end
if (DownForce==-7) graph=30; end

y=y+DownForce/2;

if (AntiGravity==1)
  if (DownForce>0) DownForce=DownForce-1;end
  if (DownForce<0) DownForce=DownForce+1;end
end


if (Thruster==1)

  if (key(_right))
     if (Sound==1)
       play_wav(SoundThrusterSound,0);
     end
    x=x+2;
  end

  x=x-1;

  if (x<40) x=x+1; end
  if (x>80) x=x-2; end

end

GlobalPlayer1X=x;
GlobalPlayer1Y=y;



if(collision(type ActiveGround));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type ActiveGround2));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle1));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle2));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle3));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle4));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle5));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle6));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle7));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle8));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle9));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type Obstacle10));
  Explode(x,y);
  Player1Alive=0;
  return;
end

if (FireShield==0)

if(collision(type FirePillarUp));
  Explode(x,y);
  Player1Alive=0;
  return;
end
if(collision(type FirePillarDown));
  Explode(x,y);
  Player1Alive=0;
  return;
end

end

if(collision(type RedPowerUp));
  if (Sound==1)
    play_wav(VoiceFireShield,0);
  end
  FireShieldControl(x,y,1);
  ZoomDisplay(56);
  signal (type RedPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type YellowPowerUp));
  if (Sound==1)
    play_wav(VoiceThruster,0);
  end
  ThrusterControl(1);
  ZoomDisplay(58);
  signal (type YellowPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type GreenPowerUp));
  if (Sound==1)
    play_wav(VoiceAntiGravity,0);
  end
  AntiGravityControl(1);
  ZoomDisplay(55);
  signal (type GreenPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type BluePowerUp));
  if (Sound==1)
    play_wav(VoiceReverseGravity,0);
  end
  ReverseGravityControl(1);
  ZoomDisplay(57);
  signal (type BluePowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end


smoke(x,y);
Player1Score=Player1Score+1;

frame;

end
end




process Player2(MaxUp, MaxDown, SpeedUp, SpeedDown,ShipType,flags);
private
wait;
DownForce;


begin
z=1;
x=40;
y=150;
graph=ShipType;

write(0,215,12,0,"Score : ");
write_int(0,265,12,0,&Player2Score);

loop

if (ReverseGravity2==0)
  if (key(_z))
    DownForce=Downforce-SpeedUp;
  end
end

if (AntiGravity2==1)
  if (key(_x))
    DownForce=DownForce+SpeedUp;
  end
end

if (ReverseGravity2==1)
  if (key(_x))
    DownForce=DownForce+SpeedUp;
  end
end

if (AntiGravity2==0 and ReverseGravity2==0)
  DownForce=DownForce+SpeedDown;
end

if (ReverseGravity2==1)
  DownForce=DownForce-SpeedDown;
end




if (DownForce>MaxUp) DownForce=MaxUp; end
if (DownForce<MaxDown) DownForce=MaxDown; end

if (DownForce==0) graph=77; end
if (DownForce==1 or DownForce==2) graph=78; end
if (DownForce==3 or DownForce==4) graph=79; end
if (DownForce==5 or DownForce==6) graph=80; end
if (DownForce==7) graph=81; end
if (DownForce==-1 or DownForce==-2) graph=82; end
if (DownForce==-3 or DownForce==-4) graph=83; end
if (DownForce==-5 or DownForce==-6) graph=84; end
if (DownForce==-7) graph=85; end

y=y+DownForce/2;

if (AntiGravity2==1)
  if (DownForce>0) DownForce=DownForce-1;end
  if (DownForce<0) DownForce=DownForce+1;end
end


if (Thruster2==1)

  if (key(_alt))
     if (Sound==1)
       play_wav(SoundThrusterSound,0);
     end
    x=x+4;
  end

  x=x-2;

  if (x<40) x=x+2; end
  if (x>80) x=x-4; end

end

GlobalPlayer2X=x;
GlobalPlayer2Y=y;



if(collision(type ActiveGround));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type ActiveGround2));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle1));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle2));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle3));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle4));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle5));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle6));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle7));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle8));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle9));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type Obstacle10));
  Explode(x,y);
  Player2Alive=0;
  return;
end

if (FireShield2==0)

if(collision(type FirePillarUp));
  Explode(x,y);
  Player2Alive=0;
  return;
end
if(collision(type FirePillarDown));
  Explode(x,y);
  Player2Alive=0;
  return;
end

end

if(collision(type RedPowerUp));
  if (Sound==1)
    play_wav(VoiceFireShield,0);
  end
  FireShieldControl(x,y,2);
  ZoomDisplay(56);
  signal (type RedPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type YellowPowerUp));
  if (Sound==1)
    play_wav(VoiceThruster,0);
  end
  ThrusterControl(2);
  ZoomDisplay(58);
  signal (type YellowPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type GreenPowerUp));
  if (Sound==1)
    play_wav(VoiceAntiGravity,0);
  end
  AntiGravityControl(2);
  ZoomDisplay(55);
  signal (type GreenPowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end

if(collision(type BluePowerUp));
  if (Sound==1)
    play_wav(VoiceReverseGravity,0);
  end
  ReverseGravityControl(2);
  ZoomDisplay(57);
  signal (type BluePowerUp, s_kill);
  signal (type PowerUpLight, s_kill);
end


smoke(x,y);
Player2Score=Player2Score+1;

frame;

end
end





process ActiveGround(graph, ScrollSpeed, y,z);
begin
z=3;
x=480;

loop

x=x-ScrollSpeed;

if (x==-159) x=480; end


frame;

end
end

process ActiveGround2(graph, ScrollSpeed, y,z);
begin
z=3;
x=160;
loop

x=x-ScrollSpeed;

if (x==-158) x=480; end
if (x==-159) x=480; end

frame;

end
end



process BkGround(graph, ScrollSpeed, y,z);
begin
z=6;
x=480;
loop

x=x-ScrollSpeed;
if (x==-160) x=480; end

frame;

end
end

process BkGround2(graph, ScrollSpeed, y,z);
begin
z=6;
x=160;
loop

x=x-ScrollSpeed;
if (x==-160) x=480; end


frame;

end
end



process Explode(x,y);
private
int Animation=0;

begin
size=150;
z=0;

if (Sound==1)
  play_wav(SoundExplosion,0);
end

repeat

 Animation=Animation+1;
 graph=2+Animation;
 frame;

until (Animation==13)
end


process smoke(x,y);
private
int Animation=0;

begin
z=1;
x=x-16;
y=y-4;
flags=4;

repeat

 x=x-5;
 Animation=Animation+1;
 graph=16+Animation;
 frame;

until (Animation==5)
end



process Obstacle1(y,ScrollSpeed);    // Vertical

begin
x=345;
graph=22;
z=4;

repeat
  x=x-ScrollSpeed;
  frame;
until (x==-25)
end



process Obstacle2(y,ScrollSpeed);    //Horizontal, middle

begin
x=395;
graph=22;
z=4;
angle=90000;

repeat
  x=x-ScrollSpeed;
  frame;
until (x==-50)
end



process Obstacle3(y,RotateSpeed, RotateDirection,ScrollSpeed, graph);    //Rotating

begin
x=395;
z=4;
angle=90000;

repeat
  x=x-ScrollSpeed;
  if (RotateDirection==1) angle=angle-RotateSpeed; end
  if (RotateDirection==2) angle=angle+RotateSpeed; end
  frame;
until (x==-50)
end


process Obstacle4(ScrollSpeed);      // Bottom Cannon

begin
x=345;
y=215;
graph=33;
z=3;

repeat
  x=x-ScrollSpeed;
  
  if (x==327) RedLightUp(x,y,ScrollSpeed); end
  if (x==327) FirePillarUp(x,y,ScrollSpeed); end
  if (x==177) RedLightUp(x,y,ScrollSpeed); end
  if (x==177) FirePillarUp(x,y,ScrollSpeed); end
  
  frame;
until (x==-50)
end



process Obstacle5(y,ScrollSpeed,TopRange,MinRange,UporDown);    // Vertical, moving
private
Range;
VerticalMove;

begin
x=345;
graph=22;
z=4;
Range=0;
VerticalMove=UporDown;

repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
until (x==-25)
end


process Obstacle6(ScrollSpeed);      // Top Cannon

begin
x=345;
y=30;
graph=35;
z=3;

repeat
  x=x-ScrollSpeed;

  if (x==327) RedLightDown(x,y,ScrollSpeed); end
  if (x==327) FirePillarDown(x,y,ScrollSpeed); end
  if (x==177) RedLightDown(x,y,ScrollSpeed); end
  if (x==177) FirePillarDown(x,y,ScrollSpeed); end

  frame;
until (x==-50)
end



process Obstacle7(y,ScrollSpeed);    //Cord
private
Animation=0;

begin
x=370;
z=5;

repeat
  Animation=Animation+1;
  if (Animation==4)
    Animation=1;
  end
  graph=60+Animation;
  if (rand(1,100)<10)
    Spark(x,y+32,ScrollSpeed);
  end
  x=x-ScrollSpeed;
  frame;
until (x==-25)
end



process Obstacle8(y,ScrollSpeed,RotateSpeed, RotateDirection, UporDown,TopRange,MinRange);    //RotatingFire
private
Animation=0;
Range;
VerticalMove;

begin
x=395;
z=5;
graph=67;
angle=90000;
Range=0;
VerticalMove=UporDown;
repeat


  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  if (RotateDirection==1) angle=angle-RotateSpeed; end
  if (RotateDirection==2) angle=angle+RotateSpeed; end
  frame;
until (x==-75)
end



process Obstacle9(y,ScrollSpeed);    // Vertical

begin
x=345;
graph=68;
z=4;

repeat
  x=x-ScrollSpeed;
  frame;
until (x==-25)
end



process Obstacle10(y,RotateSpeed, RotateDirection,ScrollSpeed);    //Rotating

begin
x=420;
z=5;
angle=90000;
graph=69;


repeat
  x=x-ScrollSpeed;
  if (RotateDirection==1) angle=angle-RotateSpeed; end
  if (RotateDirection==2) angle=angle+RotateSpeed; end
  frame;
until (x==-100)
end



process Spark(x,y,ScrollSpeed);
private
CreateSparks=0;
begin
flags=4;
graph=64;
repeat
  frame;
  Sparks(x+rand(-4,4),y,64+rand(1,2));
  CreateSparks=CreateSparks+1;
  x=x-ScrollSpeed;
until (CreateSparks==10)
end


process Sparks(x,y,graph);
private
Counter;
begin
alpha=250;
repeat
  frame;
  y=y+2;
  Counter=Counter+1;
  alpha=251-Counter*25;
until (Counter==10);
end
  

process RedLightUp(x,y,ScrollSpeed);

begin
y=312;
graph=31;
flags=4;
z=5;
x=x+1;

repeat
y=y-5;
x=x-ScrollSpeed;
frame;

until (y==-140)
end



process FirePillarUp(x,y,ScrollSpeed);

begin
y=315;
graph=32;
z=4;
x=x+1;

repeat
y=y-5;
x=x-ScrollSpeed;
frame;

until (y==-75)
end



process RedLightDown(x,y,ScrollSpeed);

begin
y=-80;
graph=31;
flags=4;
z=5;
x=x+2;

repeat
y=y+5;
x=x-ScrollSpeed;
frame;

until (y==312)
end



process FirePillarDown(x,y,ScrollSpeed);

begin
y=-75;
graph=32;
z=4;
x=x+2;

repeat
y=y+5;
x=x-ScrollSpeed;

frame;

until (y==315)
end



process GreenPowerUp(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;

begin
graph=37;
z=4;
Range=0;
VerticalMove=UporDown;
PowerUpLight(x,y,ScrollSpeed,2,TopRange,MinRange,UporDown);
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
until (x==-10)
end



process RedPowerUp(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;

begin
graph=38;
z=4;
Range=0;
VerticalMove=UporDown;
PowerUpLight(x,y,ScrollSpeed,3,TopRange,MinRange,UporDown);
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
until (x==-10)
end



process BluePowerUp(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;

begin
graph=36;
z=4;
Range=0;
VerticalMove=UporDown;
PowerUpLight(x,y,ScrollSpeed,1,TopRange,MinRange,UporDown);
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
until (x==-10)
end




process YellowPowerUp(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;

begin
graph=39;
z=4;
Range=0;
VerticalMove=UporDown;
PowerUpLight(x,y,ScrollSpeed,4,TopRange,MinRange,UporDown);
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
until (x==-10)
end



process RedPoint(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;
begin
graph=54;
z=4;
Range=0;
VerticalMove=UporDown;
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
  
  if(collision(type Player1));
    if (Sound==1)
      play_wav(SoundCrystal,0);
    end
    Player1Score=Player1Score+1000;
    DisplayScore(x,y,59);
    return;
  end
  if(collision(type Player2));
    if (Sound==1)
      play_wav(SoundCrystal,0);
    end
    Player2Score=Player2Score+1000;
    DisplayScore(x,y,59);
    return;
  end

until (x==-10)
end



process GreenPoint(y,ScrollSpeed, TopRange, MinRange, UporDown,x)

private
Range;
VerticalMove;

begin
graph=53;
z=4;
Range=0;
VerticalMove=UporDown;
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end

  x=x-ScrollSpeed;
  frame;
  
  if(collision(type Player1));
    if (Sound==1)
      play_wav(SoundCrystal,0);
    end
    Player1Score=Player1Score+10000;
    DisplayScore(x,y,60);
    return;
  end
  if(collision(type Player2));
    if (Sound==1)
      play_wav(SoundCrystal,0);
    end
    Player2Score=Player2Score+10000;
    DisplayScore(x,y,60);
    return;
  end
  
until (x==-10)
end



process PowerUpLight(x,y,ScrollSpeed,LightColor, TopRange, MinRange, UporDown)
private
Range;
VerticalMove;

begin
if (LightColor==1) graph=40; end
if (LightColor==2) graph=41; end
if (LightColor==3) graph=42; end
if (LightColor==4) graph=43; end
flags=4;
Range=0;
VerticalMove=UporDown;
z=5;
repeat
  if (VerticalMove==1)
    y=y+1;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-1;
    Range=Range-1;
  end
  if (Range==TopRange) VerticalMove=1; end
  if (Range==MinRange) VerticalMove=2; end
  x=x-ScrollSpeed;
  frame;
until (x==-10)
end



process FireShieldControl(x,y,Player);
private
FireShieldTime=250;
Animation=0;

begin
z=0;
graph=44;
flags=4;
if (Player==1);
  CountDownLine(1,51);
  FireShield=1;
end
if (Player==2);
  CountDownLine(2,51);
  FireShield2=1;
end
repeat
if (Player==1);
  x=GlobalPlayer1X;
  y=GlobalPlayer1Y;
end
if (Player==2);
  x=GlobalPlayer2X;
  y=GlobalPlayer2Y;
end

if (Player==1 and Player1Alive==0) return; end
if (Player==2 and Player2Alive==0) return; end


FireShieldTime=FireShieldTime-1;
Animation=Animation+1;
if (Animation==4) Animation=0; end
graph=44+Animation;
frame;
until (FireShieldTime==0);
if (Player==1);
  FireShield=0;
end
if (Player==2);
  FireShield2=0;
end
end



process ThrusterControl(Player);
private
ThrusterControlTime=250;

begin
if (Player==1);
  CountDownLine(1,52);
end
if (Player==2);
  CountDownLine(2,52);
end
if (Player==1);
  Thruster=1;
end
if (Player==2);
  Thruster2=1;
end

repeat
frame;
ThrusterControlTime=ThrusterControlTime-1;

until (ThrusterControlTime==0)
if (Player==1);
  Thruster=1;
end
if (Player==2);
  Thruster2=1;
end
end



process AntiGravityControl(Player);
private
AntiGravityControlTime=250;

begin
if (Player==1);
  AntiGravity=1;
  CountDownLine(1,50);
end
if (Player==2);
  AntiGravity2=1;
  CountDownLine(2,50);
end

repeat
frame;
AntiGravityControlTime=AntiGravityControlTime-1;

until (AntiGravityControlTime==0)
if (Player==1);
  AntiGravity=0;
end
if (Player==2);
  AntiGravity2=0;
end
end



process ReverseGravityControl(Player);
private
ReverseGravityControlTime=250;

begin
if (Player==1);
  CountDownLine(1,49);
end
if (Player==2);
  CountDownLine(2,49);
end
if (Player==1);
  ReverseGravity=1;
end
if (Player==2);
  ReverseGravity2=1;
end
repeat
frame;
ReverseGravityControlTime=ReverseGravityControlTime-1;

until (ReverseGravityControlTime==0)
if (Player==1);
  ReverseGravity=0;
end
if (Player==2);
  ReverseGravity2=0;
end
end



process CountDownLine(Player, graph);
private
RemainingTime=250;

begin
x=125;
if (Player==1) y=2; end
if (Player==2) y=7; end

repeat

if (Player==1 and Player1Alive==0) return; end
if (Player==2 and Player2Alive==0) return; end

RemainingTime=RemainingTime-1;
x=x-1;
frame;

until (RemainingTime==0);
end




process ZoomDisplay(graph);
private
int Counter;
begin
z=0;
x=160;
y=100;
repeat
Counter=Counter+10;
size=50+Counter;
alpha=251-Counter;

frame;
until (Counter==150)
end



process DisplayScore(x,y,graph)
private
int Counter;
begin
//flags=4;
repeat
y=y-Counter;
Counter=Counter+1;
alpha=250-Counter*10;
frame;
until (Counter==10)
end



process LevelOneControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end

if (LevelCounter==3 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==8 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==15 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==18 and TimeCounter==0);
  RedPowerUp(100,3,-25,25,2,330);
end
if (LevelCounter==23 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==27 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==30 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==37 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==47 and TimeCounter==0);
  GreenPowerUp(120,3,-25,25,1,330);
end
if (LevelCounter==50 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==55 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==60 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==73 and TimeCounter==0);
  BluePowerUp(120,3,-25,25,1,330);
end
if (LevelCounter==75 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle5(100,3,-15,15,1);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==85 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==99 and TimeCounter==0);
  YellowPowerUp(120,3,-25,25,1,330);
end
if (LevelCounter==101 and TimeCounter==0);
  Obstacle5(90,3,-15,15,1);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==106 and TimeCounter==0);
  Obstacle5(110,3,-15,15,1);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==111 and TimeCounter==0);
  Obstacle5(90,3,-15,15,1);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==115 and TimeCounter==0);
  RedPoint(95,3,-25,25,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==120 and TimeCounter==0);
  GreenPoint(95,3,-25,25,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end

frame;

until (LevelCounter==130)
LevelFinished=1;
end




process LevelTwoControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==5 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==10 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==12 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==17 and TimeCounter==0);
  Obstacle3(75,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==23 and TimeCounter==0);
  Obstacle3(165,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==29 and TimeCounter==0);
  Obstacle3(75,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==32 and TimeCounter==0);
  GreenPowerUp(145,3,-20,20,1,330);
end
if (LevelCounter==36 and TimeCounter==0);
  Obstacle3(165,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==42 and TimeCounter==0);
  Obstacle3(75,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==44 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==47 and TimeCounter==0);
  Obstacle3(165,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==53 and TimeCounter==0);
  Obstacle3(75,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==59 and TimeCounter==0);
  Obstacle3(105,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==60 and TimeCounter==0);
  RedPoint(180,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==65 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle3(105,500,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==71 and TimeCounter==0);
  RedPoint(180,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==75 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==86 and TimeCounter==0);
  Obstacle3(165,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==92 and TimeCounter==0);
  Obstacle3(165,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==98 and TimeCounter==0);
  Obstacle3(165,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==86 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==92 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==104 and TimeCounter==0);
  Obstacle3(75,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==110 and TimeCounter==0);
  Obstacle3(165,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==116 and TimeCounter==0);
  Obstacle3(75,700,2,3,34);  //Y, RotateSpeed, RotateDirection, ScrollSpeed, Graph
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==110 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end
if (LevelCounter==116 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);  //Y, ScrollSpeed, TopRange,MinRange, Up or Down
end


frame;

until (LevelCounter==140)
LevelFinished=2;
end




process LevelThreeControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==3 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==12 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==9 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==14 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==18 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==21 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==24 and TimeCounter==0);
  Obstacle1(195,3);
end
if (LevelCounter==28 and TimeCounter==0);
  Obstacle2(115,3);
end
if (LevelCounter==31 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);
end
if (LevelCounter==31 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==26 and TimeCounter==0);
  RedPowerUp(75,3,-50,50,1,330);
end
if (LevelCounter==33 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle2(115,3);
end
if (LevelCounter==37 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);
end
if (LevelCounter==37 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==40 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==42 and TimeCounter==0);
  Obstacle2(115,3);
end
if (LevelCounter==38 and TimeCounter==0);
  RedPowerUp(165,3,-10,10,1,330);
end
if (LevelCounter==45 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);
end
if (LevelCounter==45 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==50 and TimeCounter==0);
  Obstacle1(25,3);
end
if (LevelCounter==50 and TimeCounter==0);
  Obstacle1(215,3);
end
if (LevelCounter==55 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==57 and TimeCounter==0);
  Obstacle1(10,3);
end
if (LevelCounter==57 and TimeCounter==0);
  Obstacle1(175,3);
end
if (LevelCounter==58 and TimeCounter==0);
  GreenPoint(100,3,-10,10,1,330);
end
if (LevelCounter==63 and TimeCounter==0);
  Obstacle6(3);
end

if (LevelCounter==66 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==66 and TimeCounter==0);
  Obstacle1(250,3);
end
if (LevelCounter==68 and TimeCounter==0);
  GreenPoint(150,3,-10,10,1,330);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==74 and TimeCounter==0);
  Obstacle3(25,700,2,3,34);
end
if (LevelCounter==74 and TimeCounter==0);
  Obstacle3(215,700,2,3,34);
end
if (LevelCounter==75 and TimeCounter==0);
  GreenPoint(125,3,-10,10,1,330);
end
if (LevelCounter==79 and TimeCounter==0);
  Obstacle1(25,3);
end
if (LevelCounter==79 and TimeCounter==0);
  Obstacle1(215,3);
end
if (LevelCounter==80 and TimeCounter==0);
  BluePowerUp(120,3,-10,10,1,330);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==89 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==91 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==95 and TimeCounter==0);
  Obstacle2(115,3);
end
if (LevelCounter==95 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);
end
if (LevelCounter==95 and TimeCounter==0);
  GreenPoint(165,3,-10,10,1,330);
end


frame;

until (LevelCounter==120)
LevelFinished=3;
end




process LevelFourControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==3 and TimeCounter==0);
  Obstacle3(65,100,2,3,22);
end
if (LevelCounter==3 and TimeCounter==0);
  Obstacle3(165,100,2,3,22);
end
if (LevelCounter==7 and TimeCounter==0);
  Obstacle3(30,100,2,3,22);
end
if (LevelCounter==7 and TimeCounter==0);
  Obstacle3(130,100,2,3,22);
end
if (LevelCounter==8 and TimeCounter==0);
  Obstacle1(200,3);
end
if (LevelCounter==12 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==16 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==18 and TimeCounter==0);
  RedPoint(60,3,-10,10,1,330);
end
if (LevelCounter==20 and TimeCounter==0);
  Obstacle1(170,3);
end
if (LevelCounter==22 and TimeCounter==0);
  Obstacle3(30,100,1,3,22);
end
if (LevelCounter==22 and TimeCounter==0);
  Obstacle3(130,100,1,3,22);
end
if (LevelCounter==26 and TimeCounter==0);
  Obstacle3(65,100,1,3,22);
end
if (LevelCounter==26 and TimeCounter==0);
  Obstacle3(165,100,1,3,22);
end
if (LevelCounter==30 and TimeCounter==0);
  Obstacle3(65,100,2,3,22);
end
if (LevelCounter==30 and TimeCounter==0);
  Obstacle3(165,100,2,3,22);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle3(65,100,1,3,22);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle3(165,100,1,3,22);
end
if (LevelCounter==40 and TimeCounter==0);
  BluePowerUp(120,3,-10,10,1,330);
end
if (LevelCounter==43 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==46 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==51 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle3(115,100,2,3,22);
end
if (LevelCounter==58 and TimeCounter==0);
  Obstacle3(25,100,1,3,22);
end
if (LevelCounter==58 and TimeCounter==0);
  Obstacle3(115,100,1,3,22);
end
if (LevelCounter==56 and TimeCounter==0);
  RedPoint(65,3,-10,10,1,330);
end
if (LevelCounter==57 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==60 and TimeCounter==0);
  RedPoint(165,3,-10,10,1,330);
end
if (LevelCounter==65 and TimeCounter==0);
  YellowPowerUp(110,3,-10,10,1,330);
end
if (LevelCounter==68 and TimeCounter==0);
  Obstacle3(75,100,1,3,22);
end
if (LevelCounter==68 and TimeCounter==0);
  Obstacle3(165,100,2,3,22);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle1(10,3);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle1(230,3);
end
if (LevelCounter==76 and TimeCounter==0);
  Obstacle3(75,100,2,3,22);
end
if (LevelCounter==76 and TimeCounter==0);
  Obstacle3(180,100,2,3,22);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(35,200,2,3,22);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(140,200,2,3,22);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle3(20,100,1,3,22);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle3(120,100,1,3,22);
end


frame;

until (LevelCounter==110)
LevelFinished=4;
end




process LevelFiveControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==3 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==3 and TimeCounter==0);
  Obstacle1(185,3);
end
if (LevelCounter==8 and TimeCounter==0);
  Obstacle1(65,3);
end
if (LevelCounter==12 and TimeCounter==0);
  Obstacle2(80,3);
end
if (LevelCounter==12 and TimeCounter==0);
  Obstacle7(115,3);
end
if (LevelCounter==13 and TimeCounter==0);
  GreenPoint(45,3,-5,5,1,330);
end
if (LevelCounter==14 and TimeCounter==0);
  GreenPoint(45,3,-5,5,1,330);
end
if (LevelCounter==15 and TimeCounter==0);
  GreenPoint(45,3,-5,5,1,330);
end
if (LevelCounter==16 and TimeCounter==0);
  GreenPoint(45,3,-5,5,1,330);
end
if (LevelCounter==19 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==21 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==24 and TimeCounter==0);
  Obstacle1(185,3);
end
if (LevelCounter==27 and TimeCounter==0);
  Obstacle2(100,3);
end
if (LevelCounter==27 and TimeCounter==0);
  Obstacle7(135,3);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle2(100,3);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle7(40,3);
end
if (LevelCounter==38 and TimeCounter==0);
  Obstacle2(175,3);
end
if (LevelCounter==38 and TimeCounter==0);
  Obstacle7(30,3);
end
if (LevelCounter==43 and TimeCounter==0);
  Obstacle3(75,1000,2,3,34);
end
if (LevelCounter==47 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==51 and TimeCounter==0);
  GreenPoint(70,3,-20,20,1,330);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==55 and TimeCounter==0);
  Obstacle2(110,3);
end
if (LevelCounter==63 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==64 and TimeCounter==0);
  Obstacle1(185,3);
end
if (LevelCounter==68 and TimeCounter==0);
  Obstacle1(50,3);
end
if (LevelCounter==69 and TimeCounter==0);
  RedPoint(150,3,-10,10,1,330);
end
if (LevelCounter==72 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==73 and TimeCounter==0);
  Obstacle1(185,3);
end
if (LevelCounter==75 and TimeCounter==0);
  Obstacle3(75,1000,2,3,34);
end
if (LevelCounter==81 and TimeCounter==0);
  Obstacle3(165,1000,2,3,34);
end
if (LevelCounter==81 and TimeCounter==0);
  Obstacle7(40,3);
end
if (LevelCounter==85 and TimeCounter==0);
  Obstacle2(125,3);
end
if (LevelCounter==90 and TimeCounter==0);
  Obstacle7(55,3);
end


frame;

until (LevelCounter==110)
LevelFinished=5;
end




process LevelSixControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==3 and TimeCounter==0);
  Obstacle8(105,3,1000,2,1,-50,50);
end

if (LevelCounter==10 and TimeCounter==0);
  Obstacle9(45,3);
end
if (LevelCounter==10 and TimeCounter==0);
  Obstacle9(120,3);
end
if (LevelCounter==10 and TimeCounter==0);
  Obstacle9(195,3);
end
if (LevelCounter==15 and TimeCounter==0);
  Obstacle9(60,3);
end
if (LevelCounter==15 and TimeCounter==0);
  Obstacle9(160,3);
end
if (LevelCounter==20 and TimeCounter==0);
  Obstacle9(45,3);
end
if (LevelCounter==20 and TimeCounter==0);
  Obstacle9(120,3);
end
if (LevelCounter==20 and TimeCounter==0);
  Obstacle9(195,3);
end
if (LevelCounter==23 and TimeCounter==0);
  Obstacle8(105,3,1000,2,1,-50,50);
end
if (LevelCounter==26 and TimeCounter==0);
  Obstacle8(105,3,1000,2,1,-10,10);
end
if (LevelCounter==28 and TimeCounter==0);
  Obstacle7(55,3);
end
if (LevelCounter==30 and TimeCounter==0);
  Obstacle8(100,3,1000,2,2,-50,50);
end
if (LevelCounter==25 and TimeCounter==0);
  RedPoint(160,3,-10,10,1,330);
end
if (LevelCounter==27 and TimeCounter==0);
  RedPoint(160,3,-10,10,1,330);
end
if (LevelCounter==32 and TimeCounter==0);
  Obstacle4(3);
end
if (LevelCounter==36 and TimeCounter==0);
  Obstacle5(60,3,-50,50,1);
end
if (LevelCounter==40 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==40 and TimeCounter==0);
  Obstacle7(155,3);
end
if (LevelCounter==42 and TimeCounter==0);
  GreenPowerUp(55,3,-10,10,1,330);
end
if (LevelCounter==48 and TimeCounter==0);
  Obstacle9(45,3);
end
if (LevelCounter==48 and TimeCounter==0);
  Obstacle9(120,3);
end
if (LevelCounter==48 and TimeCounter==0);
  Obstacle9(195,3);
end
if (LevelCounter==52 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle9(45,3);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle9(120,3);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle9(195,3);
end
if (LevelCounter==58 and TimeCounter==0);
  Obstacle6(3);
end
if (LevelCounter==60 and TimeCounter==0);
  Obstacle1(180,3);
end
if (LevelCounter==60 and TimeCounter==0);
  Obstacle7(45,3);
end
if (LevelCounter==62 and TimeCounter==0);
  Obstacle8(100,3,1000,2,2,-50,50);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==75 and TimeCounter==0);
  Obstacle9(205,3);
end
if (LevelCounter==75 and TimeCounter==0);
  Obstacle9(35,3);
end
if (LevelCounter==72 and TimeCounter==0);
  GreenPoint(55,3,-10,10,1,330);
end
if (LevelCounter==72 and TimeCounter==0);
  RedPoint(155,3,-10,10,1,330);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(50,100,1,3,22);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(175,100,2,3,22);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle2(70,3);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle2(155,3);
end
if (LevelCounter==89 and TimeCounter==0);
  Obstacle9(75,3);
end
if (LevelCounter==89 and TimeCounter==0);
  Obstacle9(150,3);
end
if (LevelCounter==90 and TimeCounter==0);
  Obstacle8(50,3,1000,1,1,-5,5);
end
if (LevelCounter==90 and TimeCounter==0);
  Obstacle8(170,3,1000,2,2,-5,5);
end


frame;

until (LevelCounter==110)
LevelFinished=6;
end




process LevelSevenControl();

begin
LevelCounter=1;
TimeCounter=1;

repeat

TimeCounter=TimeCounter+1;
if (TimeCounter==9);
  TimeCounter=0;
  LevelCounter=LevelCounter+1;
end


if (LevelCounter==3 and TimeCounter==0);
  Obstacle10(125,5300,1,3);
end
if (LevelCounter==6 and TimeCounter==0);
  Obstacle1(75,3);
end
if (LevelCounter==10 and TimeCounter==0);
  Obstacle9(110,3);
end
if (LevelCounter==15 and TimeCounter==0);
  Obstacle1(165,3);
end
if (LevelCounter==17 and TimeCounter==0);
  YellowPowerUp(70,3,-10,10,1,330);
end
if (LevelCounter==12 and TimeCounter==0);
  Obstacle10(125,5100,1,3);
end
if (LevelCounter==16 and TimeCounter==0);
  Obstacle10(105,5100,1,3);
end
if (LevelCounter==20 and TimeCounter==0);
  Obstacle10(105,5100,1,3);
end
if (LevelCounter==19 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==27 and TimeCounter==0);
  Obstacle2(50,3);
end
if (LevelCounter==27 and TimeCounter==0);
  Obstacle2(175,3);
end
if (LevelCounter==25 and TimeCounter==0);
  Obstacle10(50,5100,2,3);
end
if (LevelCounter==25 and TimeCounter==0);
  Obstacle10(175,5100,1,3);
end
if (LevelCounter==33 and TimeCounter==0);
  Obstacle2(105,3);
end
if (LevelCounter==34 and TimeCounter==0);
  Obstacle10(105,5000,1,3);
end
if (LevelCounter==36 and TimeCounter==0);
  RedPoint(60,3,-10,10,1,330);
end

if (LevelCounter==40 and TimeCounter==0);
  Obstacle10(45,5000,1,3);
end
if (LevelCounter==40 and TimeCounter==0);
  Obstacle10(180,5000,2,3);
end
if (LevelCounter==42 and TimeCounter==0);
  Obstacle3(50,100,1,3,22);
end
if (LevelCounter==42 and TimeCounter==0);
  Obstacle3(175,100,2,3,22);
end
if (LevelCounter==46 and TimeCounter==0);
  Obstacle3(45,100,1,3,22);
end
if (LevelCounter==46 and TimeCounter==0);
  Obstacle3(180,100,2,3,22);
end
if (LevelCounter==44 and TimeCounter==0);
  Obstacle10(40,5000,1,3);
end
if (LevelCounter==44 and TimeCounter==0);
  Obstacle10(185,5000,2,3);
end
if (LevelCounter==50 and TimeCounter==0);
  GreenPowerUp(110,3,-10,10,1,330);
end
if (LevelCounter==52 and TimeCounter==0);
  Obstacle10(50,5000,1,3);
end
if (LevelCounter==54 and TimeCounter==0);
  Obstacle10(75,5000,2,3);
end
if (LevelCounter==56 and TimeCounter==0);
  Obstacle10(100,5000,1,3);
end
if (LevelCounter==62 and TimeCounter==0);
  Obstacle10(150,5000,1,3);
end
if (LevelCounter==66 and TimeCounter==0);
  Obstacle10(75,5000,1,3);
end
if (LevelCounter==70 and TimeCounter==0);
  Obstacle10(125,5000,1,3);
end

if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(50,100,1,3,22);
end
if (LevelCounter==80 and TimeCounter==0);
  Obstacle3(175,100,2,3,22);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle2(70,3);
end
if (LevelCounter==84 and TimeCounter==0);
  Obstacle2(155,3);
end
if (LevelCounter==78 and TimeCounter==0);
  Obstacle10(70,5000,2,3);
end
if (LevelCounter==78 and TimeCounter==0);
  Obstacle10(160,5000,1,3);
end
if (LevelCounter==89 and TimeCounter==0);
  Obstacle9(75,3);
end
if (LevelCounter==89 and TimeCounter==0);
  Obstacle9(150,3);
end
if (LevelCounter==90 and TimeCounter==0);
  Obstacle8(50,3,1000,1,1,-5,5);
end
if (LevelCounter==90 and TimeCounter==0);
  Obstacle8(170,3,1000,2,2,-5,5);
end

if (LevelCounter==96 and TimeCounter==0);
  RedPoint(50,3,-10,10,1,330);
end
if (LevelCounter==96 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);
end
if (LevelCounter==96 and TimeCounter==0);
  RedPoint(100,3,-10,10,1,330);
end
if (LevelCounter==96 and TimeCounter==0);
  RedPoint(125,3,-10,10,1,330);
end
if (LevelCounter==96 and TimeCounter==0);
  RedPoint(150,3,-10,10,1,330);
end
if (LevelCounter==96 and TimeCounter==0);
  RedPoint(175,3,-10,10,1,330);
end

if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(50,3,-10,10,1,330);
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(100,3,-10,10,1,330);
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(125,3,-10,10,1,330);
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(150,3,-10,10,1,330);
end
if (LevelCounter==98 and TimeCounter==0);
  GreenPoint(175,3,-10,10,1,330);
end

if (LevelCounter==100 and TimeCounter==0);
  RedPoint(50,3,-10,10,1,330);
end
if (LevelCounter==100 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);
end
if (LevelCounter==100 and TimeCounter==0);
  RedPoint(100,3,-10,10,1,330);
end
if (LevelCounter==100 and TimeCounter==0);
  RedPoint(125,3,-10,10,1,330);
end
if (LevelCounter==100 and TimeCounter==0);
  RedPoint(150,3,-10,10,1,330);
end
if (LevelCounter==100 and TimeCounter==0);
  RedPoint(175,3,-10,10,1,330);
end

if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(50,3,-10,10,1,330);
end
if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(75,3,-10,10,1,330);
end
if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(100,3,-10,10,1,330);
end
if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(125,3,-10,10,1,330);
end
if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(150,3,-10,10,1,330);
end
if (LevelCounter==102 and TimeCounter==0);
  GreenPoint(175,3,-10,10,1,330);
end

if (LevelCounter==104 and TimeCounter==0);
  RedPoint(50,3,-10,10,1,330);
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(75,3,-10,10,1,330);
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(100,3,-10,10,1,330);
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(125,3,-10,10,1,330);
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(150,3,-10,10,1,330);
end
if (LevelCounter==104 and TimeCounter==0);
  RedPoint(175,3,-10,10,1,330);
end


frame;

until (LevelCounter==130)
LevelFinished=7;
end




process DisplayTitle(graph)
begin
x=160;
y=120;
z=6;
loop
frame;
end
end



process MenuOption(graph)
private
VerticalMove=1;
Range=0;
begin
x=160;
y=270;
z=1;

repeat
frame;
y=y-10;

until (y==120)

loop

  if (VerticalMove==1)
    y=y+2;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-2;
    Range=Range-1;
  end
  if (Range==-8) VerticalMove=1; end
  if (Range==8) VerticalMove=2; end

  if (key(_left))
    break;
  end
  if (key(_right))
    break;
  end

frame;
end

repeat
frame;
y=y+10;

until (y==270)


end




process SoundMenuOption(graph)
private
VerticalMove=1;
Range=0;
begin
x=-50;
y=185;
z=1;

repeat
frame;
x=x+10;

  if (VerticalMove==1)
    y=y+2;
    Range=Range+1;
  end
  if (VerticalMove==2)
    y=y-2;
    Range=Range-1;
  end
  if (Range==-8) VerticalMove=1; end
  if (Range==8) VerticalMove=2; end

until (x==370)

end



process ZoomMenu(graph);
private
int Counter;
begin
z=0;
x=160;
y=120;
repeat
Counter=Counter+10;
size=50+Counter;
alpha=251-Counter;

frame;
until (Counter==150)
end





process Message(graph)

begin
x=160;
y=270;
z=1;

repeat
frame;
y=y-10;

until (y==120)

loop

  if (key(_enter))
    break;
  end

frame;
end

repeat
frame;
y=y+10;

until (y==270)

end




process LifeCounter1();
begin
graph=101;
x=15;
y=230;

loop
  if (Lives==0)
    return;
  end
  frame;

end
end

process LifeCounter2();
begin
graph=101;
x=40;
y=230;

loop
  if (Lives==1 or Lives==0)
    return;
  end
  frame;

end
end

process LifeCounter3();
begin
graph=101;
x=65;
y=230;

loop
  if (Lives==2 or Lives==1 or Lives==0)
    return;
  end
  frame;

end
end

process LifeCounter4();
begin
graph=101;
x=90;
y=230;

loop
  if (Lives==3 or Lives==2 or Lives==1 or Lives==0)
    return;
  end
  frame;

end
end

process LifeCounter5();
begin
graph=101;
x=115;
y=230;

loop
  if (Lives==4 or Lives==3 or Lives==2 or Lives==1 or Lives==0)
    return;
  end
  frame;

end
end
