function Runner_Runner()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% A simple game by Nicholas Kraemer and Arjun Kalburgi
% press space to jump escape to quit and enter to restart if you're dead
% enjoy!
%
% Aknoweldgements:
% music tracks 'jumpshot', 'Come and Find Me' and 'We're the Resistors'
% done by Eric Skiff: http://ericskiff.com/music/
% under the creative commons attribution liscence: 
% http://creativecommons.org/licenses/by/2.0/ca/
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%initialize screen
[background,background_map,hero,baddies,blue,black] = setup();

colormap(background_map);
global GMSTATE;
GMSTATE = struct('key','NULL','running',true,'dead',false,'high_score_entered',false,...
    'button_down',false,'spawn_countdown',0,'current_time',cputime);

%time variables
old_time = GMSTATE.current_time;
delta_time = 0;

%score variables
score = 0;
score_text = '';
name = '';

%message text
message  = '';

%start screen
[hero baddies] = reset(hero,background,baddies,blue,black);

%main loop
while (GMSTATE.running)
    %keep track of time
    old_time = GMSTATE.current_time;
    GMSTATE.current_time = cputime;
    delta_time = GMSTATE.current_time-old_time;
    
    %render things
    render(hero,background,baddies,score_text,message);
    %update game for next frame
    [hero,baddies,score,message,name,score_text] = update(hero,baddies,delta_time,score,name,blue,black,background);
    %play music
    music(0);
    
end

%cleanup
close_window();
end

%colision detection
function[hit] = collision(obj1,obj2)

hit = false;
%is the left x edge or right x edge of obj2 within obj1?
if ((obj2.xpos > obj1.xpos && obj2.xpos<(obj1.xpos+obj1.xlength) ||...
        ((obj2.xpos+obj2.xlength)>obj1.xpos && (obj2.xpos+obj2.xlength)<(obj1.xpos+obj1.xlength))))
    %check y values
    if((obj2.ypos > obj1.ypos && obj2.ypos<(obj1.ypos+obj1.ylength) ||...
            ((obj2.ypos+obj2.ylength)>obj1.ypos && (obj2.ypos+obj2.ylength)<(obj1.ypos+obj1.ylength))))
        hit = true;
    end
end
end

%update world
function [hero,baddies,score,message,name,score_text] = update(hero,baddies,delta_time,score,name,blue,black,background,score_text)
global GMSTATE

%update score
score_text = sprintf('SCORE: %d',score);

if GMSTATE.dead == false %move normally if not dead
    %move hero
    hero = hero.move(delta_time);
    %move baddies
    for i = 1:length(baddies)
        %check if they've gone off screen
        if (baddies(i).xpos+baddies(i).xlength)< 0
            baddies(i) = reset_baddy(baddies(i),blue,black);
            score = score+10;
        end
        baddies(i) = baddies(i).move(delta_time);
    end
    
    %decrease spawn_countdown
    GMSTATE.spawn_countdown = GMSTATE.spawn_countdown - delta_time;
    %add a new baddy
    if GMSTATE.spawn_countdown < 0
        GMSTATE.spawn_countdown = 10+2*length(baddies);
        baddies(length(baddies)+1) = Box(100,40+10*i,4,5,[-17-2*i 0],blue,1);
    end
    
    %is the hero hit?
    for i = 1:length(baddies)
        hit = collision(hero,baddies(i));
        if hit
            GMSTATE.dead = true; %you die
        end
    end
    
    message = '';
    
else %dead
    [hero,baddies,score,message,name] = dead_update(hero,baddies,score,name,blue,black,background,score_text);
end

%quit?
if strcmp(GMSTATE.key,'escape')
    GMSTATE.running = false;
end

end

%reset baddies
function [baddy] = reset_baddy (baddy,blue,black)
baddy.xpos = 100;
baddy.ypos = (100-baddy.ylength)*rand();
baddy.velocity(1) = -10-20*rand();
baddy.velocity(2) = baddy.velocity(1)*rand();
baddy.type = ceil(2*rand());
switch baddy.type
    case 1
        baddy.image = blue;
    case 2
        baddy.image = black;
end
end

%do this if you're dead
function[hero,baddies,score,message,name] = dead_update(hero,baddies,score,name,blue,black,background,score_text)
global GMSTATE
name_done = false;

%display death message
message = sprintf('Game Over.');
[name_list high_score_list] = high_score_rw(2);

if GMSTATE.high_score_entered == true %display end screen
    message = sprintf('%s\npress any key to continue\n\nHIGHSCORES:',message);
    %display high score
    high_score_chart = '';
    for i = 1:length(name_list)
        high_score_chart = sprintf('%s%s: %5.0f\n',high_score_chart,name_list{i},high_score_list(i));
    end
    message = sprintf('%s\n%s',message,high_score_chart);
    
else %gather new high score if you have one
    if score>high_score_list(5)
        %you have a high score!
        %input name
        if ~strcmp(GMSTATE.key,'NULL') && GMSTATE.button_down == false && name_done == false
            if strcmp(GMSTATE.key,'return') && length(name) == 3 %done name
                name_done = true;
                GMSTATE.button_down = true;
                
            elseif strcmp(GMSTATE.key,'backspace')&&~isempty(name) %backspace
                name = name(1:(length(name)-1));
                GMSTATE.button_down = true;
                
            elseif length(GMSTATE.key) == 1 && length(name)<3 %add a letter
                name = sprintf('%s%s',name,GMSTATE.key);
                name = upper(name); %capitalize name for aesthetics
                GMSTATE.button_down = true;
            end
        end
        message = sprintf('%s\n\nHigh Score!\nenter your initials: %s',message,name);
        if name_done == true
            %save high score table
            high_score_rw(1,name,score);
            %clear name
            name = '';
            GMSTATE.high_score_entered = true;
        end
    else
        %no high score for you
        GMSTATE.high_score_entered = true;
    end
end
%reset if enter is pressed
if ~strcmp(GMSTATE.key,'NULL') && GMSTATE.high_score_entered && GMSTATE.button_down == false
    GMSTATE.button_down = true;
    [hero baddies] = reset(hero,background,baddies,blue,black);
    score = 0;
end
end

%load or save high score
function [name_list,high_score_list] = high_score_rw(rw,name,score)

switch rw
    case 1 %save to a file
        if nargin == 3 %check that you have all the variables necessary
            input = importdata('high_score.mat');
            name_list = input.name_list;
            high_score_list = input.high_score_list;
            shuffled = false;
            %modify the list
            for i = 1:length(high_score_list)
                if score>high_score_list(i) && shuffled == false
                    %shuffle list down
                    for ii = (length(high_score_list)-1):-1:i
                        high_score_list(ii+1) = high_score_list(ii);
                        name_list{ii+1} = name_list{ii};
                    end
                    %add new value
                    high_score_list(i) = score;
                    name_list{i} = name;
                    shuffled = true;
                end
            end
            %actually save the data
            save 'high_score.mat' name_list high_score_list
        end
        
    case 2 %load a file
        input = importdata('high_score.mat');
        name_list = input.name_list;
        high_score_list = input.high_score_list;
end

end

%draw things
function [] = render(hero,background,baddies,score_text,message)

clf; %wipe current figure window clean
hold on;
image([0 100],[100 0], background);
image([hero.xpos (hero.xpos+hero.xlength)],[(hero.ypos+hero.ylength) hero.ypos],hero.image);
for i = 1:length(baddies)
    image([baddies(1,i).xpos (baddies(1,i).xpos+baddies(1,i).xlength)],[(baddies(1,i).ypos+baddies(1,i).ylength) baddies(1,i).ypos],baddies(1,i).image);
end

%text
%score
text(70,90,score_text,'Color', [1 1 0],'FontSize',20,'FontWeight','bold');
%message
text(50,60,message,'Color',[1 0 0],'FontSize',20,'FontWeight','bold','HorizontalAlignment','center');

axis([0,100,0,100]); %scale
axis off;
set(gca,'ydir','normal')
drawnow;
end

%play music
function [] = music(track)
global GMSTATE
global MUSIC_BOX

%if track is 0, decide which to play
if track ==0
    if GMSTATE.dead
        track = 2;
    else
        track = 1;
    end
end

switch track
    case 1 %alive music
        stop(MUSIC_BOX.start_music);
        play(MUSIC_BOX.alive_music);
        
    case 2 %dead music
        stop(MUSIC_BOX.alive_music);
        play(MUSIC_BOX.dead_music);
        
    case 3 %start music
        stop(MUSIC_BOX.dead_music);
        play(MUSIC_BOX.start_music);
end
end

%intro/reset screen
function [hero baddies] = reset(hero,background,baddies,blue,black)
global GMSTATE;
screen_on = true;

%reset
hero.ypos = 5; %reset hero
%reset list of baddies
baddies = baddies(1:2);
for i = 1:length(baddies) %reset baddies
    baddies(i) = reset_baddy(baddies(i),blue,black);
end
score_text = '';

%display screen before user presses a button
while screen_on
    %keep track of time
    GMSTATE.current_time = cputime;
    
    message = sprintf('Runner Runner\na game by Nicholas and Arjun\n\n press spacebar to move and avoid the bad guys\npress any key to start');
    render(hero,background,baddies,score_text,message);
    if strcmp(GMSTATE.key,'escape')
        GMSTATE.running = false;
        screen_on = false;
    elseif ~strcmp(GMSTATE.key,'NULL')&&GMSTATE.button_down ==false
        screen_on = false;
    end
    music(3);
end
%reset some gamestate variables
GMSTATE.dead = false;
GMSTATE.high_score_entered = false;
GMSTATE.key = 'NULL';
end
  
%set up initial screen
function[background,background_map,hero,baddies,blue,black] = setup()
%cleanup
clc;clear;
%create figure
scrsz = get(0, 'ScreenSize');
screen = figure('Position', [scrsz(3)/8 scrsz(4)/8 3*scrsz(3)/4 3*scrsz(4)/4],...
    'MenuBar', 'none', 'Color', 'black', 'name', 'Runner Runner','Resize', 'off',...
    'keypressfcn',@keypress, 'KeyReleaseFcn',@keyrelease,'CloseRequestFcn',@close_window);
%load images
[background,background_map] = imread('Background.png');
character = imread('jumpingman.png');
black = imread('black.png');
blue = imread('blue.png');

%create hero
hero = Box(5,5,7,12,[0 0],character,0);
%create baddies list
for i = 1:2
    baddies(1,i) = Box(100,40+10*i,4,5,[-17-2*i 0],blue,1);
end

%load sounds
[alive_music, alive_musicFS] = wavread('Jumpshot.wav');
[dead_music, dead_musicFS] = wavread('Come_and_Find_Me.wav');
[start_music,start_musicFS] = wavread('Were the Resistors.wav');


%audioplayer
alive_music = audioplayer(alive_music,alive_musicFS,8);
dead_music = audioplayer(dead_music,dead_musicFS,8);
start_music = audioplayer(start_music,start_musicFS,8);
global MUSIC_BOX 
MUSIC_BOX = struct('alive_music',alive_music,'dead_music',dead_music,'start_music',start_music);
end

%do things if a key is pressed
function keypress(varargin)
global GMSTATE;
GMSTATE.key = get(gcbf, 'CurrentKey');
end

% do if key is released
function keyrelease(varargin)
global GMSTATE;
GMSTATE.key = 'NULL';
GMSTATE.button_down = false;
end

%do if 'x' is clicked
function close_window(varargin)
global GMSTATE
global MUSIC_BOX

GMSTATE.running = false;
stop(MUSIC_BOX.alive_music);
stop(MUSIC_BOX.dead_music);
stop(MUSIC_BOX.start_music);

%matlab stuff
if isempty(gcbf)
    if length(dbstack) == 1
        warning(message('MATLAB:closereq:ObsoleteUsage'));
    end
    close('force');
else
    delete(gcbf);
end
end