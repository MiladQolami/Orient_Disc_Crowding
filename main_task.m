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
% Finishes the setup phase for imaging pipeline creates an onscreen window, performs all remaining
% configuration steps

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
%% Experimental Module
%specify general experiment parameters
p.nTrialsPerBlock = 14; % 14 trials/block; we show the
% reference luminance in the beginning of each block

nBlocks = 2; % number of blocks
nTrials = p.nTrialsPerBlock * nBlocks;
% Total number of trials

p.randSeed = ClockRandSeed;
% use clock to set random number generator

% Specify the stimulus
p.stimSize = 6; % diameter of the test stimulus
                % disk size in visual angle

p.stimDuration = 0.2; % stimulus display duration in seconds

p.luminance = [1 11 21 31 41 51 61];
% 7 luminance levels in cd/m^2

p.refLuminance = 25; % reference luminance; shown once
                     % every 14 trials
p.maxLuminance = max(p.luminance); % reference luminance

p.ISI = 0.5; % interval (secs) between response
             % and next trial 

% Compute stimulus parameters
grayLevels = p.luminance / p.maxLuminance;
refGrayLevel = p.refLuminance / p.maxLuminance;
ppd = pi/180 * p.ScreenDistance / p.ScreenHeight *...
    p.ScreenRect(4); % compute pixels per degree

m = round(p.stimSize * ppd); % stimulus size in pixels

stimRect = CenterRect([0 0 1 1] * m, p.ScreenRect);
% center within ScreenRect

nLevels = numel(p.luminance); % number of conditions from
                               % number of p.luminance

KbName('UnifyKeyNames'); % set up keyboard functions to use
                         % the same labels on different
                         % computer platforms

% Initialize a table to set up experimental conditions
p.recLabel = {'trialIndex' 'luminanceIndex' ...
'reportedLuminance' };
rec = nan(nTrials, length(p.recLabel));
% matrix rec is nTrials x 3 of NaN

rec(:, 1) = 1 : nTrials; % set trial numbers from 1 to nTrials

luminanceIndex = repmat((1 : nLevels),p.nTrialsPerBlock/nLevels, nBlocks);
% set the luminance index 1 to 7 repeatedly into
% matrix using repmat (replicate array)

luminanceIndex = Shuffle(luminanceIndex,1);
% shuffle each block (column) of matrix

rec(:, 2) = luminanceIndex(:); % randomized (shuffled) luminance indexes
                               % into rec(:,2)

% Prioritize display to optimize display timing
Priority(MaxPriority(windowPtr));

% Start experiment with instructions
str = sprintf(['Input the perceived intensity of the disk ' ...
'for each trial.\n\n' 'Press Backspace or ' ...
'Delete to remove the last input.\n\n' ...
'Press Enter to finish your input.\n\n\n' ...
'Press SPACE to start the experiment.' ]);

DrawFormattedText(windowPtr, str, 'center', 'center', 1);
% Draw Instruction text string centered in window
% onto frame buffer

Screen( 'Flip', windowPtr); % flip the text image into  active buffer

KbWait;; % wait till space bar is pressed

Secs = Screen('Flip', windowPtr); % flip the background image
% into active buffer

p.start = datestr(now); % record start time

% Instruction for trial and reference intensity
trialInstruction = 'The perceived intensity of the disk is' ;
refInstruction = ['This is the reference with an intensity of ' ...
    '10.\n\nPress SPACE to proceed']  ;

% Run nTrials trials
for i = 1 : nTrials
    % Show the reference luminance once every 14 trials
    if mod(i, p.nTrialsPerBlock) == 1
        Screen('FillOval', windowPtr, refGrayLevel, stimRect);
        % make stimulus disk
        
        t0 = Screen('Flip', windowPtr, Secs + p.ISI);
        % show disk & return current time

        Screen('Flip', windowPtr, t0 + p.stimDuration);
        % turn off the disk after p.stimDuration secs

        DrawFormattedText(windowPtr, refInstruction, ...
        'center', 'center', 1);
        Screen('Flip', windowPtr);
        % show reference instruction text
        [secs keycode ] = KbWait();
        % wait for SPACE response
        if strcmp(KbName(keycode), 'esc'), break; end
        %if response is <escape> , then stop experiment
        Secs = Screen('Flip', windowPtr);
        % turn off text by flipping to background image
    end
    Screen('FillOval', windowPtr, grayLevels(rec(i, 2)), ...
    stimRect); % make stimulus disk

    t0 = Screen( 'Flip', windowPtr, Secs + p.ISI);
    % show disk & return current time
    Screen( 'Flip', windowPtr, t0 + p.stimDuration);
    % turn off the disk after p.stimDuration

    num = GetEchoNumber(windowPtr, trialInstruction, ...
    p.ScreenRect(3) / 2 - 200, p.ScreenRect(4) / 2, 1, ...
    p.ScreenBackground, -1);
    % read a number response from the keyboard while
    % displaying the trial instruction
    Secs = Screen( 'Flip', windowPtr);
    % turn off trial instruction
    if ~isempty(num), rec(i, 3) = num; end
    % check the response, and record it
end
sca;
p.finish = datestr(now); % record the finish time
save MagnitudeEstimation_rst.mat rec p; % save the results