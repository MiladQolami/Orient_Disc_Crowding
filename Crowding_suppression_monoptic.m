cd('C:\toolbox\Psychtoolbox')
SetupPsychtoolbox
%%
%%%%%%%%%%%%%% Orientation Discrimination under Crowding and interocular suppression %%%%%%%%%%%
% This code was written by Milad Qolami
clc;
clear;
close all;
%% Inputs
% Specify saving directory
savedir = uigetdir('Where to save data');
SubjectID = input('Inter subject ID:');
DominantEye = input("Which Eye is dominant (either 'Right' or 'Left'?) : ","s");
while ~any(strcmp(DominantEye,{'Right','Left'}))
    DominantEye = input("Which Eye is dominant (either 'Right' or 'Left'?) : ","s");
end
%% Display setup module
scrnNum     = max(Screen('Screens'));

CR.ScreenDistance = 50; % in centimeter
CR.ScreenHeight = 19; % in centimeter
CR.ScreenGamma = 2; % from monitor calibration
CR.maxLuminance = 100; % from monitor calibration
CR.ScreenBackground = 0.5;

% Open the display window, set up lookup table, and hide the  mouse cursor
if exist('onCleanup', 'class'), oC_Obj = onCleanup(@()sca); end
% close any pre-existing PTB Screen window

% Prepare setup of imaging pipeline for onscreen window.
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

[windowPtr,CR.ScreenRect] = PsychImaging( 'OpenWindow'  , scrnNum, CR.ScreenBackground, [], [], []);

% Enable alpha-blending
Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(CR.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ CR.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor

% Get frame rate and set screen font
CR.ScreenFrameRate = FrameRate(windowPtr);
monitorFlipInterval = Screen('GetFlipInterval', windowPtr);
% get current frame rate
Screen( 'TextSize', windowPtr, 30); % set the font size
% for the screen to 24
%% Experiment module

% Specify general experiment parameters
CR.randSeed             = ClockRandSeed;
CR.stimSize             = 1.3;              % In visual angle
CR.stimDistance         = 1.8;              % Distance from target to flankers
CR.eccentricity         = 4;                % Eccentricity of stimuli
CR.stimDuration         = 0.200;            % Stimulus Duration
CR.ISI                  = 1;                % Time between response and next trial onset
CR.contrast             = 1;                % Contrast of gratings
CR.sf                   = 4;                % Spatial frequency in cycles/degree
CR.numCrowd             = 6;                % Number of crowding stimuli
CR.repCond              = 30;               % number of repetition for each condition, this specifies number of trials
CR.FrameSquareSizeAngle = 16;               % Size of the fusional frame square in anlge


% Compute stimulus parameters
ppd           = pi/180 * CR.ScreenDistance / CR.ScreenHeight * CR.ScreenRect(4);     % Pixels per degree
m             = 2 * round(CR.stimSize * ppd / 2);                                    % Horizontal and vertical stimulus size in pixels
d             = 2 * round(CR.stimDistance * ppd / 2);                                % Stimuli distance in pixel
e             = 2 * round(CR.eccentricity * ppd / 2);                                % Stimulus eccentricity in pixel
sf            = CR.sf / ppd;                                                         % Cycles per pixel
E             = [e,e];                                                              % Creating Eccentricity vector (center of a rectangle where the stimuli will be presented)
FrameSquareSizePixel = 2 * round(CR.FrameSquareSizeAngle * ppd / 2);                 % Size of the fusional frame square in pixel
beep = MakeBeep(400,1);        % Make a beep to indicate break time

% Nonuis cross (central fusion lock)
fixCrossSize            = 0.4;                                   % Size of each arm in visual angle
fixCrossDimPix          = 2 * round(fixCrossSize * ppd / 2);
lineWidthPix            = 6;                                     % Width of the line in pixel
xCoords                 = [-fixCrossDimPix fixCrossDimPix 0 0];  % X coordination of linse
yCoords                 = [0 0 -fixCrossDimPix fixCrossDimPix];               % Y coordinates of upper half of vertical arms (presented to left eye)
fixCross                = [xCoords; yCoords];                % Coordinates of fixation cross

% Create a frame square as peripheral fusion lock
FrameSquareSizePixels = [0 0 FrameSquareSizePixel FrameSquareSizePixel]; % A base fram square
FrameSquarePosition   = CenterRectOnPointd(FrameSquareSizePixels, xCenter, yCenter); % Center it where we want
penWidthPixels        = 6;  % Pen width for the frames

% Generate the stimulus texture
radius           = m/2;                   % radius of disc edge
sigma            = 10;                    % smoothing sigma in pixel
useAlpha         = true;                  % use alpha channel for smoothing?
smoothMethod     = 1;                     % smoothing method: cosine (0) or smoothstep (1) or inverse smoothstep (2)
text             =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
                     m, m, [.5 .5 .5 .5],radius,[],sigma,useAlpha,smoothMethod);
params           = [0 sf CR.contrast 0];  % Dfining parameters for the grating

% Stimuli position
StimPosition = [xCenter yCenter] + E;
CR.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
CR.crowdingLocs = VisualCrowder(StimPosition,CR.numCrowd, d ,m);


% Initialize a table to initialize
CR.resLabel              = {'trialIndex' 'targetOrientation' 'respCorrect' 'respTime' 'catchTrial' };
StimRange                = logspace(log10(1),log10(15),7);
StimLevels               = [90 - StimRange, 90 + StimRange,90];    % Target orientation varies from 25 to 65 of step 2
targetOrientation        = Shuffle(repmat(StimLevels,1,CR.repCond));  % create a vectro of orientation for all trials
nTrials                  = length(targetOrientation);    % number of tirals
distractorOrientation    = [80,100];    % Distractor orientation is either 35 or 55
catchTrial               = Shuffle([zeros(round(2*nTrials/3),1) ;ones(round(nTrials/3),1)]); % if one, it is a catch trial
Response                 = nan(nTrials, length(CR.resLabel));     % matrix res is nTrials x 5 of NaN
Response(:, 1)           = 1 : nTrials;    % Label the trial type numbers from 1 to nTrials


% Prioritize display to optimize display timing
Priority(MaxPriority(windowPtr));


% Start experiment with instructions
WaitSecs(.4);
str = sprintf('Press a key to start' );
DrawFormattedText(windowPtr, str, 'center', 'center', 1);  % Draw instruction text string centered in window in mirror inverse
Screen( 'Flip', windowPtr);
KbName('UnifyKeyNames');
RestrictKeysForKbCheck([37,38,39,40,32,27]); % Restrict keys to few onse
KbWait;

Screen('DrawLines', windowPtr, fixCross,lineWidthPix, 0, [xCenter, yCenter]);
Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
t0       = Screen('Flip', windowPtr,[],1); % Flip and get flip time to present first stimuli after CR.ISI
flag     = 0;                              % If 1, break the loop and escape
secs     = 0;                              % initiate 'secs' variable, presenting time of stimuli if no response key was pressed
CR.start = datestr(now);                   % record finish time

for trial_i = 1:nTrials
    % if flag is 1 break the loop and escape the task
    if flag
        break
    end
    if trial_i == round(nTrials/2) % Stop when reaching to half of the trials
        Snd("Play",beep);
        secs = KbWait;
    end
    % Create a matrix of orientation for distractor and for
    % target(random)
    orient_vect = [repmat(distractorOrientation,1,CR.numCrowd/2) targetOrientation(trial_i)];
    Response(trial_i,2) = orient_vect(end);
    params(1) = 360 * rand; % set initial phase randomly

    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, 0, [xCenter, yCenter]);
    Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);

    if catchTrial(trial_i) == 1 % if it is a catch trial make distractors disappear
        Response(trial_i,5) = 1;
        params(3) = 0;
        Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs],orient_vect(1:end-1), [], [],...
            [], [], [], params');
    elseif catchTrial(trial_i) == 0
        Response(trial_i,5) = 0;
        params(3) = 1;
        Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs],orient_vect(1:end-1), [], [],...
            [], [], [], params');
    end

    params(3) = 1; % reset the value of contrast for target
    Screen('DrawTextures', windowPtr, text, [], CR.targetLocs',orient_vect(end), [], [],...
        [], [], [], params');

    % this part indicates when to present stimuli if response
    % if a response key was pressed in the last trial
    if any(secs)   % When a key was pressed
        t1 = Screen('Flip', windowPtr,secs + CR.ISI);
    else        % when subject did not respond
        t1 = Screen('Flip', windowPtr,t0 + CR.ISI);
    end

    WaitSecs(CR.stimDuration);

    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, 0, [xCenter, yCenter]);
    Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
    Screen('Flip', windowPtr);
    WiatTime = 5;       % Wait for response
    while KbCheck; end  % To make sure all keys are released
    TrialEnd = GetSecs;
    while GetSecs < TrialEnd + WiatTime
        [keyIsDown1, secs, keyCode]= KbCheck;
        if keyIsDown1    % if key is pressed it's response or space or escape; do proper action
            % correct resposnse
            if (Response(trial_i,2) >= 90 && strcmp(KbName(keyCode),'DownArrow')) || ((Response(trial_i,2) <= 90 && strcmp(KbName(keyCode), 'UpArrow')))
                Response(trial_i,3) = 1;
                Response(trial_i,4) = secs - TrialEnd;
                Beeper;
                break
                % incoreccet response
            elseif (Response(trial_i,2) >=  90 && strcmp(KbName(keyCode),'UpArrow')) || ((Response(trial_i,2) <= 90 && strcmp(KbName(keyCode), 'DownArrow')))
                Response(trial_i,3) = 0;
                Response(trial_i,4) = secs - TrialEnd;
                break
                % space is pressed iether for some rest or for
                % terminating the task
            elseif strcmp(KbName(keyCode), 'space')
                Trial_count = sprintf([num2str(trial_i) ' of ' num2str(nTrials) ' trials ']);
                DrawFormattedText(windowPtr, Trial_count,[],[], 1);
                Screen('DrawLines', windowPtr, fixCross,lineWidthPix, 1, [xCenter, yCenter]);
                Screen('FrameRect', windowPtr, 0, FrameSquarePosition, penWidthPixels);
                % Draw instruction text string centered in window
                Screen( 'Flip', windowPtr);
                WaitSecs(.2);

                [keyIsDown, ~, keyCode] = KbCheck; % make sure all keys are rleased
                % wait for either space for resume or
                % escape for terminating the task
                while ~keyIsDown
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if strcmp(KbName(keyCode), 'space')
                        break
                    elseif strcmp(KbName(keyCode), 'ESCAPE')
                        flag = 1;
                        break
                    end
                end % end of inside while loop
            end

        elseif ~keyIsDown1   % if no keys is put a place holder in response table and detemine next trial presentation
            Response(trial_i,3) = 99;
            Response(trial_i,4) = 99;
            t0 = t1 + WiatTime;
            secs = 0 ;
        end
        if flag,break,end % break outside while loop because we don't want to wait for WaitTime
    end
    fprintf("Trial number is %i \n",nTrials)
    % If flag is 1 which means 'escape' was pressed end
    % session
end

        
CR.finish = datestr(now); % record finish time
filename = strcat('Crowding_Monoptic', num2str(SubjectID),'_' ,DominantEye);
save (fullfile(savedir,filename),'Response', 'CR'); % save the results
sca;
%% System Reinstatement Module
Priority(0); % restore priority
