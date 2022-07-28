% cd('C:\toolbox\Psychtoolbox')
% SetupPsychtoolbox
%%
%%%%%%%%%%%%%% Orientation Discrimination Task under Crowding %%%%%%%%%%%

% This code was written by Milad Qolami 7/9/2022
clc;
clear;
close all;
%% Display setup module
% Define display parameters
whichScreen = max(Screen('screens' ));
p.ScreenDistance = 50; % in centimeter
p.ScreenHeight = 19; % in centimeter
p.ScreenGamma = 2; % from monitor calibration
p.maxLuminance = 100; % from monitor calibration
p.ScreenBackground = 0.5;

% Open the display window, set up lookup table, and hide the  mouse cursor
if exist('onCleanup', 'class'), oC_Obj = onCleanup(@()sca); end
% close any pre-existing PTB Screen window

Screen('Preference', 'SkipSyncTests', 1)
% Prepare setup of imaging pipeline for onscreen window.
PsychImaging( 'PrepareConfiguration'); % First step in starting  pipeline
PsychImaging( 'AddTask', 'General','FloatingPoint32BitIfPossible' );
% set up a 32-bit floatingpoint framebuffer

PsychImaging( 'AddTask', 'General','NormalizedHighresColorRange' );
% normalize the color range ([0, 1] corresponds to [min, max])

PsychImaging('AddTask', 'General', 'EnablePseudoGrayOutput' );
% enable high gray level resolution output with bitstealing

PsychImaging( 'AddTask' , 'FinalFormatting','DisplayColorCorrection' , 'SimpleGamma' );
% setup Gamma correction method using simple power  function for all color channels

[windowPtr p.ScreenRect] = PsychImaging( 'OpenWindow'  , whichScreen, p.ScreenBackground);

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter] = RectCenter(p.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ p.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor
ShowCursor

% Get frame rate and set screen font
p.ScreenFrameRate = FrameRate(windowPtr);
% get current frame rate
Screen( 'TextFont', windowPtr, 'Times' );
% set the font for the screen to Times
Screen( 'TextSize', windowPtr, 24); % set the font size
                                    % for the screen to 24
%% Experiment module 

% Specify general experiment parameters
nTrials = 2;   
p.randSeed = ClockRandSeed;     

% Specify the stimulus
p.stimSize = 4;    
p.stimDuration = 0.250; 
p.ISI = 0.5;    % duration between response and next trial onset
p.contrast = 0.2;   
p.tf = 4;   % Drifting temporal frequency in Hz
p.sf = 4;   % Spatial frequency in cycles/degree
numCrowd = 4; % number of crowding stimuli

% Compute stimulus parameters
ppd = pi/180 * p.ScreenDistance / p.ScreenHeight * p.ScreenRect(4);     % pixels per degree
nFrames = round(p.stimDuration * p.ScreenFrameRate);    % # stimulus frames
m = 2 * round(p.stimSize * ppd / 2);    % horizontal and vertical
                                        % stimulus size in pixels
p.stimLocFellow = [xCenter yCenter xCenter+100 yCenter+100] % Stimulus location for fellow eye

% Make stimuli coordinates
allAppertures = nan(4,4)
for i = 1: numCrowd
    
p.stimLocFellow = [xCenter+(xCenter/2)-m/2 yCenter-m/2 xCenter+(xCenter/2)+m/2 yCenter+m/2]


sf = p.sf / ppd;    % cycles per pixel
phasePerFrame = 360 * p.tf / p.ScreenFrameRate;     % phase drift per frame
fixRect = CenterRect([0 0 1 1] * 8, p.ScreenRect);   % 8 x 8 fixation

params = [0 sf p.contrast 0];  

% generating stimulus
text =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
    m, m, [.5 .5 .5 .5],50,.5,[],[],[]);
Screen('DrawTexture', windowPtr, text, [], p.stimLocFellow, 45, [], [],...
[], [], [], [90, sf, 1, 0]);
Screen('Flip',windowPtr)















% 
% KbName('UnifyKeyNames'); % set up keyboard functions to use
%                          % the same labels on different
%                          % computer platforms
% 
% % Initialize a table to set up experimental conditions
% p.recLabel = {'trialIndex' 'motionDirection' 'respCorrect' 'respTime' };
% 
% rec = nan(nTrials, length(p.recLabel));
% % matrix rec is nTrials x 4 of NaN
% 
% rec(:, 1) = 1 : nTrials;    % label the trial type numbers from 1 to nTrials
% rec(:, 2) = -1;     % -1 for left motion direction
% rec(1 : nTrials/2, 2) = 1 ;     % half of the trials set to +1 for right motion Direction
% 
% rec(:, 2) = Shuffle(rec(:, 2));     % randomize motion direction over trials
% 
% % Prioritize display to optimize display timing
% Priority(MaxPriority(windowPtr));
% 
% % Start experiment with instructions
% str = sprintf('Left/Right arrow keys for direction.\n\n Press SPACE to start.'  );
% 
% DrawFormattedText(windowPtr, str, 'center', 'center', 1);
% % Draw instruction text string centered in window
% 
% Screen( 'Flip', windowPtr);
% % flip the text image into active buffer
% 
% KbWait;
% RestrictKeysForKbCheck([39,37,32,27]);
% 
% Screen( 'FillOval', windowPtr, 0, fixRect);      % create fixation box as black (0)
% Secs = Screen('Flip', windowPtr);    % flip the fixation image into active buffer
% 
% p.start = datestr(now);    % record start time
% 
% % Run nTrials trials
% for i = 1 : nTrials
%     params(1) = 360 * rand; % set initial phase randomly
%     Screen('DrawTexture', windowPtr,tex, [], [], 0, ...
%     [], [], [], [], [], params);
%     % call to draw or compute the texture pointed to by tex
%     % with texture parameters of the initial phase, the
%     % spatial frequency, the contrast, and fillers required
%     % for 4 required auxiliary parameters
% 
%     t0 = Screen('Flip', windowPtr, Secs + p.ISI);
%     % initiate first frame after p.ISI secs
% 
%     for j = 2 : nFrames % For each of the next frames one by one
%         params(1) = params(1) - phasePerFrame * rec(i, 2);
%         % change phase
%         Screen('DrawTexture', windowPtr, tex, [], [], 0,...
%         [], [], [], [], [], params);
%         % call to draw/compute the next frame
%         Screen('Flip', windowPtr); % show frame
%         % each new computation occurs fast enough to show
%         % all nFrames at the framerate
%     end
%     Screen('FillOval', windowPtr, 1, fixRect);
%     % black fixation for response interval
% 
%     Screen('Flip', windowPtr);
%     KbWait;
%     [keyIsDown, time_secs1, keyCode, deltaSecs] = KbCheck;
% 
% 
%     if strcmp(KbName(keyCode), 'esc'), break; end
%     % stop the trial sequence if keypress = <esc>
% 
%     respCorrect = strcmp(keyCode, 'right') == (rec(i, 2) == 1) | strcmp(keyCode, 'left') == (rec(i, 2) == -1) ;
%     % compute if correct or incorrect
% 
%     rec(i, 3 : 4) = [respCorrect time_secs1-t0];
%     % record correctness and RT in rec
% 
%     if rec(i, 3), Beeper; end % beep if correct
% end
% p.finish = datestr(now); % record finish time
% % Save Results
% save DriftingSinewave_rst.mat rec p; % save the results
% sca;
% %% System Reinstatement Module
% Priority(0); % restore priority
% sca; % close display window and textures,
% % and restore the original color lookup table
% 
