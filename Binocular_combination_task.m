%%%% This code was written by Milad Qolami %%%%%
%%%% Binocular combination task %%%%%%%%%
% cd('C:\toolbox\Psychtoolbox')
% SetupPsychtoolbox
%%
clc;
clear;
close all;

%% Inputs
% Select a folder to save results there
savedir = uigetdir('Where to save data');

SubjectID = input('Inter subject ID:');
DominantEye = input("Which Eye is dominant (either 'Right' or 'Left'?) : ","s");
while ~any(strcmp(DominantEye,{'Right','Left'}))
    DominantEye = input("Which Eye is dominant (either 'Right' or 'Left'?) : ","s");
end
%% Display setup module
% Define display parameters
scrnNum     = max(Screen('Screens'));
stereoMode  = 4; % Define the mode for stereodisply
BC.ScreenDistance = 50; % in centimeter
BC.ScreenHeight = 19; % in centimeter
BC.ScreenGamma = 2.2; % from monitor calibration
BC.maxLuminance = 100; % from monitor calibration
BC.ScreenBackground = 0.5;

% Open the display window, set up lookup table, and hide the  mouse cursor
if exist('onCleanup', 'class'), oC_Obj = onCleanup(@()sca); end
% close any pre-existing PTB Screen window

% Prepare setup of imaging pipeline for onscreen window.

% Check that Psychtoolbox is properly installed, switch to unified KbName's
% across operating systems, and switch color range to normalized 0 - 1 range:
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
PsychImaging( 'PrepareConfiguration'); % First step in starting  pipeline
PsychImaging( 'AddTask', 'General','FloatingPoint32BitIfPossible' );
% set up a 32-bit floatingpoint framebuffer


PsychImaging( 'AddTask', 'General','NormalizedHighresColorRange' );
% normalize the color range ([0, 1] corresponds to [min, max])

PsychImaging('AddTask', 'General', 'EnablePseudoGrayOutput' );
% enable high gray level resolution output with bitstealing

PsychImaging( 'AddTask' , 'FinalFormatting','DisplayColorCorrection' , 'SimpleGamma' );
% setup Gamma correction method using simple power  function for all color channels

[windowPtr BC.ScreenRect] = PsychImaging( 'OpenWindow'  , scrnNum, BC.ScreenBackground, [], [], [], stereoMode);

% Enable alpha-blending
Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(BC.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ BC.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor

% Get frame rate and set screen font
BC.ScreenFrameRate = FrameRate(windowPtr);
monitorFlipInterval =Screen('GetFlipInterval', windowPtr)
% get current frame rate
Screen( 'TextSize', windowPtr, 15); % set the font size
% for the screen to 24

%% %% Experiment module

% Specify general experiment parameters
BC.randSeed      = ClockRandSeed;

% Specify the stimulus
BC.stimSize      = 3.3;      % In visual angle
BC.eccentricity  = 5;      % Stimulus eccentricity
BC.ISI           = 2;        % Interstimulus interval
BC.contrast      = 1;
BC.sf            = 2;       % Spatial frequency in cycles/degree
nTrials          = 2;       % Must be even
trialLength      = 10;      % Duration of a trial in secs
FrameSquareSizeAngle = 18;     % Size of the fusional frame square in anlge

% Compute stimulus parameters
ppd     = pi/180 * BC.ScreenDistance / BC.ScreenHeight * BC.ScreenRect(4);     % pixels per degree
m       = 2 * round(BC.stimSize * ppd / 2);    % horizontal and vertical stimulus size in pixels
e       = 2 * round(BC.eccentricity * ppd / 2);  % stimulus eccentricity in pixel
sf      = BC.sf / ppd;    % cycles per pixel
FrameSquareSizePixel = 2 * round(FrameSquareSizeAngle * ppd / 2);% Size of the fusional frame square in pixel


% Nonuis cross (central fusion lock)
fixCrossSize            = 0.4;                                   % Size of each arm in visual angle
fixCrossDimPix          = 2 * round(fixCrossSize * ppd / 2);    
lineWidthPix            = 6;                                     % Width of the line in pixel
xCoords                 = [-fixCrossDimPix fixCrossDimPix 0 0];  % X coordination of linse
yCoordsUp               = [0 0 -fixCrossDimPix 0];               % Y coordinates of upper half of vertical arms (presented to left eye)
yCoordsDown             = [0 0 0 fixCrossDimPix];                % Y coordinates of lower half of vertical arms (presented to right eye)
fixCrossLeft            = [xCoords; yCoordsUp];                  % Coordinates of fixation cross
fixCrossRight           = [xCoords; yCoordsDown];                % Coordinates of fixation cross


% Create a frame square as peripheral fusion lock
FrameSquareSizePixels = [0 0 FrameSquareSizePixel FrameSquareSizePixel]; % A base fram square
FrameSquarePosition   = CenterRectOnPointd(FrameSquareSizePixels, xCenter, yCenter); % Center it where we want
penWidthPixels        = 6;  % Pen width for the frames


% Initialize a table to set up experimental conditions
BC.resLabel            = {'trialIndex' 'LeftEyeOrientation' 'RightEyeOrientation' 'ResponseOrientataion' 'ResponseTime' }; % 37 is left,38 is up and 39 is right
Response               = cell(nTrials, length(BC.resLabel));     % matrix res is nTrials x 5 of NaN
Orientations           = [repmat([80 110],nTrials/2,1);repmat([110 80],nTrials/2,1)]; % Orientatin of grating presented to left and right eye
Orientations           = Orientations(Shuffle(1:nTrials),:);
for i=1:nTrials
    Response{i,1}          = 1:nTrials;
    Response{i,2}          = Orientations(i,1);
    Response{i,3}          = Orientations(i,2);
end


% Generate the stimulus texture
radius           = m/2;                   % radius of disc edge
sigma            = 10;                    % smoothing sigma in pixel
useAlpha         = true;                  % use alpha channel for smoothing?
smoothMethod     = 1;                     % smoothing method: cosine (0) or smoothstep (1) or inverse smoothstep (2)
text             =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
                    m, m, [.5 .5 .5 .5],radius,[],sigma,useAlpha,smoothMethod);
params           = [0 sf CR.contrast 0];  % Dfining parameters for the grating

% Prioritize display to optimize display timing
Priority(MaxPriority(windowPtr));

% Alignment task
% Select left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 0);
% Draw left stim:
Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, 0, [xCenter, yCenter]);
Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
Screen('DrawingFinished', windowPtr);
Screen('Flip', windowPtr);
KbWait;
WaitSecs(.2);

% Start experiment with instructions
str = sprintf('Press a key to starat'  );
DrawFormattedText(windowPtr, str, 'center', 'center',1, [], 1);
Screen( 'Flip', windowPtr);

KbName('UnifyKeyNames');
RestrictKeysForKbCheck([37,38,39,40,32,27]);
KbWait;

Screen('SelectStereoDrawBuffer', windowPtr, 0);
Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, 0, [xCenter, yCenter]);
Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
Screen('DrawingFinished', windowPtr);
t0      = Screen('Flip', windowPtr);
flag    = 0; % If 1, break the loop and escape
secs = 0; % initiate 'secs' variable, presenting time of stimuli if no response key was pressed

for trial_i = 1:nTrials
    trialStart = GetSecs;
    pressDurs = []; % initialize a vector for press durations during a tril
    params(1) = 360 * rand; % set initial phase randomly

    while GetSecs < trialStart +trialLength
        % record keyboard pressed and duration
        Screen('SelectStereoDrawBuffer', windowPtr, 0);
        Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix,0, [xCenter, yCenter]);
        Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
        Screen('DrawTexture', windowPtr, text, [], StimulusPosition, Response{trial_i,2}, [], [],[], [], [], params);
        Screen('SelectStereoDrawBuffer', windowPtr, 1);
        Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
        Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
        Screen('DrawTexture', windowPtr, text, [], StimulusPosition, Response{trial_i,3}, [], [],...
            [], [], [], params);
        Screen('DrawingFinished', windowPtr);
        Screen('Flip', windowPtr,t0 + BC.ISI);
        [pressTime, pressedKey]   = KbWait([],[],trialStart +trialLength);
        releaseTime               = KbReleaseWait([],trialStart +trialLength);
        pressDur                  = releaseTime - pressTime;
        Response{trial_i,4}       = [Response{trial_i,4} pressDur]; % appending duration of key presses to resposne cell
        Response{trial_i,5}       = [Response{trial_i,5} KbName(KbName(pressedKey))];
    end

    WaitSecs(2);
    KbWait;
    WaitSecs(BC.ISI)
end
sca;

% Save results
filename = strcat('BinCom', num2str(SubjectID), '_' ,DominantEye);
save (fullfile(savedir,filename),'Response', 'CR'); % save the results
sca;
    
%     WaitSecs(BC.stimDuration);
%     Screen('Flip',windowPtr);
%     % Select left-eye image buffer for drawing:
%     Screen('SelectStereoDrawBuffer', windowPtr, 0);
%     % Draw left stim:
%     Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, 0, [xCenter, yCenter]);
%     Screen('SelectStereoDrawBuffer', windowPtr, 1);
%     Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
%     Screen('DrawingFinished', windowPtr);
%     Screen('Flip', windowPtr);
% 
%     while KbCheck; end % To make sure all keys are released
%     TrialEnd = GetSecs;
%     while GetSecs < TrialEnd + WiatTime
%         [keyIsDown1 secs keyCode]= KbCheck;
%         if keyIsDown1    % if key is pressed it's response or space or escape; do proper action
%             % correct resposnse
%             if ismember(KbName(KbName(keyCode)),[37 38 39])
%                 Response(trial_i,4) = KbName(KbName(keyCode));
%                 Beeper;break
%                 
%                 % If space is pressed iether for some rest or for
%                 % terminating the task
%             elseif strcmp(KbName(keyCode), 'space')
%                 str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
%                 DrawFormattedText(windowPtr, str, 'center', 'center', 1);
%                 % Draw instruction text string centered in window
%                 Screen( 'Flip', windowPtr);
%                 WaitSecs(.2);
%                 [keyIsDown, ~, keyCode] = KbCheck; % make sure all keys are rleased
%                 % wait for either space for resume or
%                 % escape for terminating the task
%                 while ~keyIsDown
%                     [stopButton, ~, keyCode] = KbCheck;
%                     if strcmp(KbName(keyCode), 'space')
%                         break
%                     elseif strcmp(KbName(keyCode), 'ESCAPE')
%                         flag = 1;
%                         break
%                     end
%                 end % end of inside while loop
%             end
%             t0 = secs;
%         elseif ~keyIsDown1
%             secs = 0;
%             t0 = t1 + WiatTime;
%         end
%         if flag,break,end % break outside while loop because we don't want to wait for WaitTime
%     end
% end

