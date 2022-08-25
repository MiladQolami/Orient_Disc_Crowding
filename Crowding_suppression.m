% cd('C:\toolbox\Psychtoolbox')
% SetupPsychtoolbox
%%
%%%%%%%%%%%%%% Orientation Discrimination Task under Crowding %%%%%%%%%%%
% This code was written by Milad Qolami
clc;
clear;
close all;
% Inputs
SubjectID = input('Inter subject ID:');
DominantEye = input("Which Eye is dominant (either 'right' or 'left'? : ","s");
while ~any(strcmp(DominantEye,{'right','left'}))
    DominantEye = input("Which Eye is dominant (either 'right' or 'left'? : ","s");
end

BinocularCond = input("Which binocular condition? (either 'binocular' or 'monoocular'):","s");
while ~any(strcmp(BinocularCond,{'binocular','monoocular'}))
    BinocularCond = input("Which binocular condition? (either 'binocular' or 'monoocular'):","s");
end
%% Display setup module
% Define display parameters
scrnNum     = max(Screen('Screens'));
stereoMode  = 4; % Define the mode for stereodisply

% Windows-Hack: If mode 4 or 5 is requested, we select screen zero
% as target screen: This will open a window that spans multiple
% monitors on multi-display setups, which is usually what one wants
% for this mode.
if IsWin && (stereoMode==4 || stereoMode==5)
    scrnNum = 0;
end
% Dual display dual-window stereo requested?
if stereoMode == 10
    % Yes. Do we have at least two separate displays for both views?
    if length(Screen('Screens')) < 2
        error('Sorry, for stereoMode 10 you''ll need at least 2 separate display screens in non-mirrored mode.');
    end

    if ~IsWin
        % Assign left-eye view (the master window) to main display:
        scrnNum = 0;
    else
        % Assign left-eye view (the master window) to main display:
        scrnNum = 1;
    end
end
if stereoMode == 10
    % In dual-window, dual-display mode, we open the slave window on
    % the secondary screen:
    if IsWin
        slaveScreen = 2;
    else
        slaveScreen = 1;
    end
    % The 2nd window for output of the right-eye view should be
    % opened on 'slaveScreen':
    PsychImaging('AddTask', 'General', 'DualWindowStereo', slaveScreen);
end
CR.ScreenDistance = 50; % in centimeter
CR.ScreenHeight = 19; % in centimeter
CR.ScreenGamma = 2.2; % from monitor calibration
CR.maxLuminance = 100; % from monitor calibration
CR.ScreenBackground = 0.5;

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

[windowPtr CR.ScreenRect] = PsychImaging( 'OpenWindow'  , scrnNum, CR.ScreenBackground, [], [], [], stereoMode);

% Enable alpha-blending
Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

if ismember(stereoMode, [4, 5])
    % This uncommented bit of code would allow to exercise the
    % SetStereoSideBySideParameters() function, which allows to change
    % presentation parameters for dual-display / side-by-side stereo modes 4
    % and 5:
    % "Shrink display a bit to the center": SetStereoSideBySideParameters(windowPtr, [0.25, 0.25], [0.75, 0.5], [1, 0.25], [0.75, 0.5]);
    % Restore defaults: SetStereoSideBySideParameters(windowPtr, [0, 0], [1, 1], [1, 0], [1, 1]);
end

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(CR.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ CR.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor

% Get frame rate and set screen font
CR.ScreenFrameRate = FrameRate(windowPtr);
monitorFlipInterval =Screen('GetFlipInterval', windowPtr)
% get current frame rate
Screen( 'TextSize', windowPtr, 20); % set the font size
% for the screen to 24
%% Experiment module

% Specify general experiment parameters
repCond         = 3;   % number of repetition for each conditin, this determines number ot trials
CR.randSeed      = ClockRandSeed;

% Specify the stimulus
CR.stimSize      = 2;  % In visual angle
CR.stimDistance  = 3;
CR.eccentricity  = 4.8;
CR.stimDuration  = 5;
CR.ISI           = 1;     % duration between response and next trial onset
CR.contrast      = 1;
CR.tf            = 2;     % Drifting temporal frequency in Hz
CR.sf            = 4;   % Spatial frequency in cycles/degree
numCrowd        = 6;     % number of crowding stimuli


% Compute stimulus parameters
ppd     = pi/180 * CR.ScreenDistance / CR.ScreenHeight * CR.ScreenRect(4);     % pixels per degree
nFrames = round(CR.stimDuration * CR.ScreenFrameRate);    % # stimulus frames
m       = 2 * round(CR.stimSize * ppd / 2);    % horizontal and vertical stimulus size in pixels
d       = 2 * round(CR.stimDistance * ppd / 2); % stimulus distance in pixel
e       = 2 * round(CR.eccentricity * ppd / 2);  % stimulus eccentricity in pixel
sf      = CR.sf / ppd;    % cycles per pixel
phasePerFrame = 360 * CR.tf / CR.ScreenFrameRate;     % phase drift per frame
E = [e 0;0 -e;-e 0;0 e];        % Creating Eccentricity matrix ( amount of displacement for x and y)

% Nonuis cross
fixCrossSize            = .4;                             % size of each arm in visual angle
fixCrossDimPix          = 2 * round(fixCrossSize * ppd / 2);      
lineWidthPix            = 6;                             % Width of the line in pixel
xCoords                 = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoordsUp               = [0 0 -fixCrossDimPix 0];
yCoordsDown             = [0 0 0 fixCrossDimPix];
fixCrossLeft            = [xCoords; yCoordsUp];         % Coordinates of fixation cross
fixCrossRight           = [xCoords; yCoordsDown];       % Coordinates of fixation cross

% Initialize a table to set up experimental conditions
CR.resLabel              = {'trialIndex' 'targetOrientation' 'stimuliPosition' 'respCorrect' 'respTime' };
targetOrientation       = 20:10:70;    % Target orientation varies from 25 to 65 of step 2
targetOrientation       = Shuffle(repmat(targetOrientation,1,repCond));  % create a vectro of orientation for all trials
nTrials                 = length(targetOrientation);    % number of tirals
distractorOrientation   = [35,55];    % Distractor orientation is either 35 or 55
stimuliPositin          = [1 2 3 4];  % Stimulus positoin is in one the four cardinal directin in the visula field

% Initiate response table
res                      = nan(nTrials, length(CR.resLabel));     % matrix res is nTrials x 5 of NaN
res(:, 1)                = 1 : nTrials;    % Label the trial type numbers from 1 to nTrials

% Generate the stimulus texture
radius = m/2;   % radius of disc edge
% smoothing sigma in pixel
sigma = 10;
% use alpha channel for smoothing?
useAlpha = true;
% smoothing method: cosine (0) or smoothstep (1) or inverse smoothstep (2)
smoothMethod = 1;
text                    =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
    m, m, [.5 .5 .5 .5],radius,[],sigma,useAlpha,smoothMethod);
params                  = [0 sf CR.contrast 0];  % Dfining parameters for the grating

% Prioritize display to optimize display timing
Priority(MaxPriority(windowPtr));

% Start experiment with instructions
str                     = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );

DrawFormattedText(windowPtr, str, 'center', 'center', 1);
% Draw instruction text string centered in window

Screen( 'Flip', windowPtr);
% flip the text image into active buffer
KbName('UnifyKeyNames');
RestrictKeysForKbCheck([39,37,32,27]);
KbWait;

% Select left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 0);
% Draw left stim:
Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
Screen('DrawingFinished', windowPtr);
t0      = Screen('Flip', windowPtr,[],1);
flag    = 0; % If 1, break the loop and escape
secs = 0; % initiate 'secs' variable, presenting time of stimuli if no response key was pressed
switch BinocularCond
    case 'monoocular'
        switch DominantEye
            case 'right'
                for trial_i = 1:nTrials
                    % if flag is 1 break the loop and escape the task
                    if flag
                        break
                    end
                    % Create a matrix of orientation for distractor and for
                    % target(random)
                    orient_vect = [repmat(distractorOrientation,1,numCrowd/2) targetOrientation(trial_i)];
                    res(trial_i,2) = orient_vect(end);
                    % pick a random stimulus posiontion
                    stimulusPosition = stimuliPositin(randi(4,1));
                    res(trial_i,3) = stimulusPosition;
                    % Applying eccentircity
                    StimPosition = [xCenter yCenter] + E(stimulusPosition,:);
                    CR.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
                    CR.crowdingLocs = VisualCrowder(StimPosition,numCrowd, d ,m);
                    params(1) = 360 * rand; % set initial phase randomly
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    % Draw left stim:
                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs CR.targetLocs'],orient_vect, [], [],...
                        [], [], [], params');
                    Screen('DrawingFinished', windowPtr);

                    % this part indicates when present stimuli if response
                    % key is pressed or not 
                    if any(secs)
                        t1 = Screen('Flip', windowPtr,secs + CR.ISI);
                    else
                        t1 = Screen('Flip', windowPtr,t0 + CR.ISI);
                    end

                    WaitSecs(CR.stimDuration);
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawingFinished', windowPtr);
                    Screen('Flip', windowPtr);
                    WiatTime = 5;       % Wait for response
                    while KbCheck; end % To make sure all keys are released
                    TrialEnd = GetSecs;
                    while GetSecs < TrialEnd + WiatTime
                        [keyIsDown1 secs keyCode]= KbCheck;
                        if keyIsDown1    % if key is pressed it's response or space or escape; do proper action
                            % correct resposnse
                            if (res(trial_i,2) >= 45 && strcmp(KbName(keyCode),'RightArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'LeftArrow')))
                                res(trial_i,4) = 1;
                                res(trial_i,5) = secs - TrialEnd;
                                Beeper;break
                                % incoreccet response
                            elseif (res(trial_i,2) >=  45 && strcmp(KbName(keyCode),'LeftArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'RightArrow')))
                                res(trial_i,4) = 0;
                                res(trial_i,5) = secs - TrialEnd;
                                break
                                % space is pressed iether for some rest or for
                                % terminating the task
                            elseif strcmp(KbName(keyCode), 'space')
                                str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
                                DrawFormattedText(windowPtr, str, 'center', 'center', 1);
                                % Draw instruction text string centered in window
                                Screen( 'Flip', windowPtr);
                                WaitSecs(1);
                                [keyIsDown, ~, keyCode] = KbCheck; % make sure all keys are rleased
                                % wait for either space for resume or
                                % escape for terminating the task
                                while ~keyIsDown
                                    [stopButton, ~, keyCode] = KbCheck;
                                    if strcmp(KbName(keyCode), 'space')
                                        break
                                    elseif strcmp(KbName(keyCode), 'ESCAPE')
                                        flag = 1;
                                        break
                                    end
                                end % end of inside while loop
                            end
                            res(trial_i,4) = 99;
                            res(trial_i,5) = 99;
                            t0 = secs;
                        elseif ~keyIsDown1
                            secs = 0;
                            t0 = t1 + WiatTime;
                        end
                        if flag,break,end % break outside while loop because we don't want to wait for WaitTime
                    end
                    fprintf("Trial number is %i \n",nTrials)
                    % If flag is 1 which means 'escape' was pressed end
                    % session
                end
            case 'left'
                for trial_i = 1:nTrials
                    if flag
                        break
                    end
                    flag = 0; % For escaping session
                    orient_vect = [repmat(distractorOrientation,1,numCrowd/2) targetOrientation(trial_i)];
                    res(trial_i,2) = orient_vect(end);
                    % pick a random stimulus posiontion
                    stimulusPosition = stimuliPositin(randi(4,1));
                    res(trial_i,3) = stimulusPosition;
                    % Applying eccentircity
                    StimPosition = [xCenter yCenter] + E(stimulusPosition,:);
                    CR.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
                    CR.crowdingLocs = VisualCrowder(StimPosition,numCrowd, d ,m);
                    params(1) = 360 * rand; % set initial phase randomly
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs CR.targetLocs'],orient_vect, [], [],...
                        [], [], [], params');
                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawingFinished', windowPtr);
                    if any(secs)
                        t1 = Screen('Flip', windowPtr,secs + CR.ISI);
                    else
                        t1 = Screen('Flip', windowPtr,t0 + CR.ISI);
                    end
                    WaitSecs(CR.stimDuration);
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawingFinished', windowPtr);
                    Screen('Flip', windowPtr);
                    WiatTime = 5;       % Wait for response
                    while KbCheck; end % To make sure all keys are released
                    TrialEnd = GetSecs;
                    while GetSecs < TrialEnd + WiatTime
                        [keyIsDown1 secs keyCode]= KbCheck;
                        if keyIsDown1
                            if (res(trial_i,2) >= 45 && strcmp(KbName(keyCode),'RightArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'LeftArrow')))
                                res(trial_i,4) = 1;
                                res(trial_i,5) = secs - TrialEnd;
                                Beeper;break
                            elseif (res(trial_i,2) >=  45 && strcmp(KbName(keyCode),'LeftArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'RightArrow')))
                                res(trial_i,4) = 0;
                                res(trial_i,5) = secs - TrialEnd;
                                break
                            elseif strcmp(KbName(keyCode), 'space')
                                str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
                                DrawFormattedText(windowPtr, str, 'center', 'center', 1);
                                % Draw instruction text string centered in window
                                Screen( 'Flip', windowPtr);
                                WaitSecs(2);
                                [keyIsDown, ~, keyCode] = KbCheck;
                                while ~keyIsDown
                                    [stopButton, ~, keyCode] = KbCheck;
                                    if strcmp(KbName(keyCode), 'space')
                                        break
                                    elseif strcmp(KbName(keyCode), 'ESCAPE')
                                        flag = 1;
                                        break
                                    end
                                end
                            end
                            res(trial_i,4) = 99;
                            res(trial_i,5) = 99;
                            
                        end
                        if flag,break,end
                    end
                    fprintf("Trial number is %i \n",nTrials)
                    % If flag is 1 which means 'escape' was pressed end
                    % session
                end
        end
    case 'binocular'
        switch DominantEye
            case 'right'
                for trial_i = 1:nTrials
                    if flag
                        break
                    end
                    flag = 0; % For escaping session
                    orient_vect = [repmat(distractorOrientation,1,numCrowd/2) targetOrientation(trial_i)];
                    res(trial_i,2) = orient_vect(end);
                    % pick a random stimulus posiontion
                    stimulusPosition = stimuliPositin(randi(4,1));
                    res(trial_i,3) = stimulusPosition;
                    % Applying eccentircity
                    StimPosition = [xCenter yCenter] + E(stimulusPosition,:);
                    CR.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
                    CR.crowdingLocs = VisualCrowder(StimPosition,numCrowd, d ,m);
                    params(1) = 360 * rand; % set initial phase randomly
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs],orient_vect(1:end-1), [], [],...
                        [], [], [], params');
                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.targetLocs'],orient_vect(end), [], [],...
                        [], [], [], params');
                    Screen('DrawingFinished', windowPtr);
                   if any(secs)
                        t1 = Screen('Flip', windowPtr,secs + CR.ISI);
                    else
                        t1 = Screen('Flip', windowPtr,t0 + CR.ISI);
                    end
                    WaitSecs(CR.stimDuration);
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawingFinished', windowPtr);
                    Screen('Flip', windowPtr);
                    WiatTime = 5;       % Wait for response
                    while KbCheck; end % To make sure all keys are released
                    TrialEnd = GetSecs;
                    while GetSecs < TrialEnd + WiatTime
                        [keyIsDown secs keyCode]= KbCheck;
                        if keyIsDown
                            if (res(trial_i,2) >= 45 && strcmp(KbName(keyCode),'RightArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'LeftArrow')))
                                res(trial_i,4) = 1;
                                res(trial_i,5) = secs - TrialEnd;
                                Beeper;break
                            elseif (res(trial_i,2) >=  45 && strcmp(KbName(keyCode),'LeftArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'RightArrow')))
                                res(trial_i,4) = 0;
                                res(trial_i,5) = secs - TrialEnd;
                                break
                            elseif strcmp(KbName(keyCode), 'space')
                                str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
                                DrawFormattedText(windowPtr, str, 'center', 'center', 1);
                                % Draw instruction text string centered in window
                                Screen( 'Flip', windowPtr);
                                WaitSecs(2);
                                [keyIsDown, ~, keyCode] = KbCheck;
                                while ~keyIsDown
                                    [stopButton, ~, keyCode] = KbCheck;
                                    if strcmp(KbName(keyCode), 'space')
                                        break
                                    elseif strcmp(KbName(keyCode), 'ESCAPE')
                                        flag = 1;
                                        break
                                    end
                                end
                            end
                            res(trial_i,4) = 99;
                            res(trial_i,5) = 99;
                        end
                        if flag,break,end
                    end
                    fprintf("Trial number is %i \n",nTrials)
                    % If flag is 1 which means 'escape' was pressed end
                    % session
                end
            case 'left'
                for trial_i = 1:nTrials
                    if flag
                        break
                    end
                    flag = 0; % For escaping session
                    % Get orientation of sinewave for each trial from
                    % response table
                    orient_vect = [repmat(distractorOrientation,1,numCrowd/2) targetOrientation(trial_i)];
                    res(trial_i,2) = orient_vect(end);
                    % pick a random stimulus posiontion
                    stimulusPosition = stimuliPositin(randi(4,1));
                    res(trial_i,3) = stimulusPosition;
                    % Applying eccentircity
                    StimPosition = [xCenter yCenter] + E(stimulusPosition,:);
                    CR.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
                    CR.crowdingLocs = VisualCrowder(StimPosition,numCrowd, d ,m);
                    params(1) = 360 * rand; % set initial phase randomly
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.targetLocs'],orient_vect(end), [], [],...
                        [], [], [], params');
                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawTextures', windowPtr, text, [], [CR.crowdingLocs],orient_vect(1:end-1), [], [],...
                        [], [], [], params');
                    Screen('DrawingFinished', windowPtr);
                    if any(secs)
                        t1 = Screen('Flip', windowPtr,secs + CR.ISI);
                    else
                        t1 = Screen('Flip', windowPtr,t0 + CR.ISI);
                    end
                    WaitSecs(CR.stimDuration);
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, [], [xCenter, yCenter]);
                    Screen('DrawingFinished', windowPtr);
                    Screen('Flip', windowPtr);
                    WiatTime = 5;       % Wait for response
                    while KbCheck; end % To make sure all keys are released
                    TrialEnd = GetSecs;
                    while GetSecs < TrialEnd + WiatTime
                        [keyIsDown secs keyCode]= KbCheck;
                        if keyIsDown
                            if (res(trial_i,2) >= 45 && strcmp(KbName(keyCode),'RightArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'LeftArrow')))
                                res(trial_i,4) = 1;
                                res(trial_i,5) = secs - TrialEnd;
                                Beeper;break
                            elseif (res(trial_i,2) >=  45 && strcmp(KbName(keyCode),'LeftArrow')) || ((res(trial_i,2) <= 45 && strcmp(KbName(keyCode), 'RightArrow')))
                                res(trial_i,4) = 0;
                                res(trial_i,5) = secs - TrialEnd;
                                break
                            elseif strcmp(KbName(keyCode), 'space')
                                str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
                                DrawFormattedText(windowPtr, str, 'center', 'center', 1);
                                % Draw instruction text string centered in window
                                Screen( 'Flip', windowPtr);
                                WaitSecs(2);
                                [keyIsDown, ~, keyCode] = KbCheck;
                                while ~keyIsDown
                                    [stopButton, ~, keyCode] = KbCheck;
                                    if strcmp(KbName(keyCode), 'space')
                                        break
                                    elseif strcmp(KbName(keyCode), 'ESCAPE')
                                        flag = 1;
                                        break
                                    end
                                end
                            end
                            res(trial_i,4) = 99;
                            res(trial_i,5) = 99;
                        end
                        if flag,break,end
                    end
                    fprintf("Trial number is %i \n",nTrials)
                    % If flag is 1 which means 'escape' was pressed end
                    % session
                end
        end
end
CR.finish = datestr(now); % record finish time
% save DriftingSinewave_rst.mat rec p; % save the results
% sca;
%% System Reinstatement Module
Priority(0); % restore priority
sca; % close display window and textures,
% and restore the original color lookup table