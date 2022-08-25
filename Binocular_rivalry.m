%%%% This code was written by Milad Qolami %%%%%
%%%% Binocular combination task %%%%%%%%%
clc;
clear;
close all;
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
BC.ScreenDistance = 50; % in centimeter
BC.ScreenHeight = 19; % in centimeter
BC.ScreenGamma = 2; % from monitor calibration
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

if ismember(stereoMode, [4, 5])
    % This uncommented bit of code would allow to exercise the
    % SetStereoSideBySideParameters() function, which allows to change
    % presentation parameters for dual-display / side-by-side stereo modes 4
    % and 5:
    % "Shrink display a bit to the center": SetStereoSideBySideParameters(windowPtr, [0.25, 0.25], [0.75, 0.5], [1, 0.25], [0.75, 0.5]);
    % Restore defaults: SetStereoSideBySideParameters(windowPtr, [0, 0], [1, 1], [1, 0], [1, 1]);
end

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(BC.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ BC.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor

% Get frame rate and set screen font
BC.ScreenFrameRate = FrameRate(windowPtr);
monitorFlipInterval =Screen('GetFlipInterval', windowPtr)
% get current frame rate
Screen( 'TextFont', windowPtr, 'Times' );
% set the font for the screen to Times
Screen( 'TextSize', windowPtr, 20); % set the font size
% for the screen to 24

%% %% Experiment module

% Specify general experiment parameters
BC.randSeed      = ClockRandSeed;

% Specify the stimulus
BC.stimSize      = 2;       % In visual angle
BC.eccentricity  = 5;
BC.stimDuration  = 5;
BC.ISI           = 2;       % duration between response and next trial onset
BC.contrast      = 1;
BC.tf            = 1.5;     % Drifting temporal frequency in Hz
BC.sf            = 4;       % Spatial frequency in cycles/degree
nTrials          = 6;       % Must be even
% Compute stimulus parameters
ppd     = pi/180 * BC.ScreenDistance / BC.ScreenHeight * BC.ScreenRect(4);     % pixels per degree
nFrames = round(BC.stimDuration * BC.ScreenFrameRate);    % # stimulus frames
m       = 2 * round(BC.stimSize * ppd / 2);    % horizontal and vertical stimulus size in pixels
e       = 2 * round(BC.eccentricity * ppd / 2);  % stimulus eccentricity in pixel
sf      = BC.sf / ppd;    % cycles per pixel
phasePerFrame = 360 * BC.tf / BC.ScreenFrameRate;     % phase drift per frame
E = [e 0;0 -e;-e 0;0 e];        % Creating Eccentricity matrix ( amount of displacement for x and y)

% Nonuis cross
fixCrossDimPix          = 25;        % Here we set the size of the arms of our fixation cross
lineWidthPix            = 8;           % Width of the line in pixel
xCoords                 = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoordsUp               = [0 0 -fixCrossDimPix 0];
yCoordsDown             = [0 0 0 fixCrossDimPix];
fixCrossLeft            = [xCoords; yCoordsUp];       % Coordinates of fixation cross
fixCrossRight           = [xCoords; yCoordsDown];       % Coordinates of fixation cross

StimulusPosition        = [xCenter+e-m-50, yCenter+e-m-50, xCenter+e+m+50 yCenter+e+m+50];
% Initialize a table to set up experimental conditions
BC.resLabel              = {'trialIndex' 'LeftEyeOrientation' 'RightEyeOrientation' 'ResponseOrientataion' 'ResponseTime' }; % 37 is left,38 is up and 39 is right
Response                 = nan(nTrials, length(BC.resLabel));     % matrix res is nTrials x 5 of NaN
Orientations             = [repmat([35 55],nTrials/2,1);repmat([55 35],nTrials/2,1)]; % Orientatin of grating presented to left and right eye
Response(:,2:3)                = Orientations(Shuffle(1:nTrials),:)

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
params                  = [0 sf BC.contrast 0];  % Dfining parameters for the grating

% Prioritize display to optimize display timing
Priority(MaxPriority(windowPtr));

% Start experiment with instructions
str                     = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );

DrawFormattedText(windowPtr, str, 'center', 'center', 1);
% Draw instruction text string centered in window

Screen( 'Flip', windowPtr);
% flip the text image into active buffer
KbName('UnifyKeyNames');
RestrictKeysForKbCheck([39,38,37,32,27]);
KbWait;

% Select left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 0);
% Draw left stim:
Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, 0, [xCenter, yCenter]);
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
Screen('DrawingFinished', windowPtr);
t0      = Screen('Flip', windowPtr);
flag    = 0; % If 1, break the loop and escape
secs = 0; % initiate 'secs' variable, presenting time of stimuli if no response key was pressed

for trial_i = 1:nTrials
    % if flag is 1 break the loop and escape the task
    if flag
        break
    end
    % Select left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', windowPtr, 0);
    % Draw left stim:
    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix,0, [xCenter, yCenter]);
    Screen('DrawTexture', windowPtr, text, [], StimulusPosition, Response(trial_i,2), [], [],[], [], [], params);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', windowPtr, 1);
    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
    Screen('DrawTexture', windowPtr, text, [], StimulusPosition, Response(trial_i,3), [], [],...
        [], [], [], params);
    Screen('DrawingFinished', windowPtr);
    % this part indicates when present stimuli if response
    % key is pressed or not
    if any(secs)
        t1 = Screen('Flip', windowPtr,secs + BC.ISI);
    else
        t1 = Screen('Flip', windowPtr,t0 + BC.ISI);
    end
    WaitSecs(BC.stimDuration);
    Screen('Flip',windowPtr);
    % Select left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', windowPtr, 0);
    % Draw left stim:
    Screen('DrawLines', windowPtr, fixCrossLeft,lineWidthPix, 0, [xCenter, yCenter]);
    Screen('SelectStereoDrawBuffer', windowPtr, 1);
    Screen('DrawLines', windowPtr, fixCrossRight,lineWidthPix, 0, [xCenter, yCenter]);
    Screen('DrawingFinished', windowPtr);
    Screen('Flip', windowPtr);

    WiatTime = 5;       % Wait for response
    while KbCheck; end % To make sure all keys are released
    TrialEnd = GetSecs;
    while GetSecs < TrialEnd + WiatTime
        [keyIsDown1 secs keyCode]= KbCheck;
        if keyIsDown1    % if key is pressed it's response or space or escape; do proper action
            % correct resposnse
            if ismember(KbName(KbName(keyCode)),[37 38 39])
                Response(trial_i,4) = KbName(KbName(keyCode));
                Beeper;break
                
                % If space is pressed iether for some rest or for
                % terminating the task
            elseif strcmp(KbName(keyCode), 'space')
                str = sprintf('Left/Right arrow keys for orientation.\n\n Press SPACE to start.'  );
                DrawFormattedText(windowPtr, str, 'center', 'center', 1);
                % Draw instruction text string centered in window
                Screen( 'Flip', windowPtr);
                WaitSecs(.5);
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
            t0 = secs;
        elseif ~keyIsDown1
            secs = 0;
            t0 = t1 + WiatTime;
        end
        if flag,break,end % break outside while loop because we don't want to wait for WaitTime
    end
end
sca;