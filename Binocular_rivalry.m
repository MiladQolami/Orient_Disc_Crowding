%%%% This code was written by Milad Qolami %%%%%
%%%% Binocular rivalry task %%%%%%%%%
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
p.ScreenDistance = 50; % in centimeter
p.ScreenHeight = 19; % in centimeter
p.ScreenGamma = 2; % from monitor calibration
p.maxLuminance = 100; % from monitor calibration
p.ScreenBackground = 0.5;

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

[windowPtr p.ScreenRect] = PsychImaging( 'OpenWindow'  , scrnNum, p.ScreenBackground, [], [], [], stereoMode);

if ismember(stereoMode, [4, 5])
    % This uncommented bit of code would allow to exercise the
    % SetStereoSideBySideParameters() function, which allows to change
    % presentation parameters for dual-display / side-by-side stereo modes 4
    % and 5:
    % "Shrink display a bit to the center": SetStereoSideBySideParameters(windowPtr, [0.25, 0.25], [0.75, 0.5], [1, 0.25], [0.75, 0.5]);
    % Restore defaults: SetStereoSideBySideParameters(windowPtr, [0, 0], [1, 1], [1, 0], [1, 1]);
end

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(p.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ p.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor

% Get frame rate and set screen font
p.ScreenFrameRate = FrameRate(windowPtr);
 monitorFlipInterval =Screen('GetFlipInterval', windowPtr)
% get current frame rate
Screen( 'TextFont', windowPtr, 'Times' );
% set the font for the screen to Times
Screen( 'TextSize', windowPtr, 20); % set the font size
% for the screen to 24

%% %% Experiment module

% Specify general experiment parameters
p.randSeed      = ClockRandSeed;

% Specify the stimulus
p.stimSize      = 3;  % In visual angle
p.eccentricity  = 5;
p.stimDuration  = .5;
p.ISI           = 2;     % duration between response and next trial onset
p.contrast      = 1;
p.tf            = 1.5;     % Drifting temporal frequency in Hz
p.sf            = 1;   % Spatial frequency in cycles/degree

% Compute stimulus parameters
ppd     = pi/180 * p.ScreenDistance / p.ScreenHeight * p.ScreenRect(4);     % pixels per degree
nFrames = round(p.stimDuration * p.ScreenFrameRate);    % # stimulus frames
m       = 2 * round(p.stimSize * ppd / 2);    % horizontal and vertical stimulus size in pixels
e       = 2 * round(p.eccentricity * ppd / 2);  % stimulus eccentricity in pixel
sf      = p.sf / ppd;    % cycles per pixel
phasePerFrame = 360 * p.tf / p.ScreenFrameRate;     % phase drift per frame
E = [e 0;0 -e;-e 0;0 e];        % Creating Eccentricity matrix ( amount of displacement for x and y)

% Fixation cross
fixCrossDimPix          = 20;        % Here we set the size of the arms of our fixation cross
lineWidthPix            = 8;           % Width of the line in pixel
xCoords                 = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords                 = [0 0 -fixCrossDimPix fixCrossDimPix];
fixCross                = [xCoords; yCoords];       % Coordinates of fixation cross

% Initialize a table to set up experimental conditions
p.resLabel              = {'trialIndex' 'targetOrientation' 'stimuliPosition' 'respCorrect' 'respTime' };
% targetOrientation       = 20:10:70;    % Target orientation varies from 25 to 65 of step 2
% targetOrientation       = Shuffle(repmat(targetOrientation,1,repCond));  % create a vectro of orientation for all trials
% nTrials                 = length(targetOrientation);    % number of tirals
% distractorOrientation   = [35,55];    % Distractor orientation is either 35 or 55
% stimuliPositin          = [1 2 3 4];  % Stimulus positoin is in one the four cardinal directin in the visula field
% 
% % Initiate response table
% res                      = nan(nTrials, length(p.resLabel));     % matrix res is nTrials x 5 of NaN
% res(:, 1)                = 1 : nTrials;    % Label the trial type numbers from 1 to nTrials

% Generate the stimulus texture
text                    =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
                            m+2*m, m+2*m, [.5 .5 .5 .5],m,[],[],[],[]);
params                  = [0 sf p.contrast 0];  % Dfining parameters for the grating

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
Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
Screen('DrawingFinished', windowPtr);
t0      = Screen('Flip', windowPtr);
flag    = 0; % If 1, break the loop and escape

% Select left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 0);
% Draw left stim:
Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
Screen('DrawTexture', windowPtr, text, [], [xCenter+e-m, yCenter+e-m, xCenter+e+m yCenter+e+m],45, [], [],[], [], [], params);
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', windowPtr, 1);
Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
Screen('DrawTexture', windowPtr, text, [], [xCenter+e-m, yCenter+e-m, xCenter+e+m yCenter+e+m],30, [], [],...
    [], [], [], params);
Screen('DrawingFinished', windowPtr);
% Flip stim to display after p.ISI seconds from
% presentatio of fixation point
t1 = Screen('Flip', windowPtr,t0 + p.ISI);
for j = 2 : nFrames % For each of the next frames one by one
    params(1) = params(1) - phasePerFrame;
    % change phase
    % Select left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', windowPtr, 0);
    % Draw left stim:
    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
    Screen('DrawTexture', windowPtr, text, [], [xCenter+e-m, yCenter+e-m, xCenter+e+m yCenter+e+m],45, [], [],[], [], [], params);

    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', windowPtr, 1);
    Screen('DrawTexture', windowPtr, text, [], [xCenter+e-m, yCenter+e-m, xCenter+e+m yCenter+e+m],30, [], [],...
        [], [], [], params);
    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
    Screen('DrawingFinished', windowPtr);
    % each new computation occurs fast enough to show
    % all nFrames at the framerate
    Screen('SelectStereoDrawBuffer', windowPtr, 0);
    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
    Screen('SelectStereoDrawBuffer', windowPtr, 1);
    Screen('DrawLines', windowPtr, fixCross,lineWidthPix, [], [xCenter, yCenter]);
    Screen('DrawingFinished', windowPtr);
    Screen('Flip', windowPtr);
end