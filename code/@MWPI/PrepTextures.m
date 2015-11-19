function PrepTextures(mwpi, kRun, kBlock, level)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt1':		first of 2 wm prompts
%				'prompt2':		second of 2 wm prompts
%				'cue':			a number '1' or '2' on the screen,
%								cues the subject to remember prompt 1 or 2.								
%				'retention':	visual stim during retention period
%				'test':			wm test after retention
%				'testYes':		test in color indicating success
%				'testNo':		test in color indicating failure
%
%	Syntax: mwpi.PrepTextures(kRun, kBlock)
%
%	In:	kRun:   the current run
%		kBlock: the current block
%		level:	a nClass x 1 array of numbers in the range [0, 1]
%				indicating the difficulty level for each class
%
%	Updated: 2015-10-17

sParam = mwpi.sParam;

% verify block and run
if kBlock > size(sParam.cue, 2)
	error('Block out of range');
elseif kRun > size(sParam.cue, 1)
	error('Run out of range');
end

shw = mwpi.Experiment.Show;
cue    = sParam.cue(kRun, kBlock);

% make the arrow

shw.Blank('window', 'arrow');

szArrow	  = MWPI.Param('arrow', 'size');
rotArrow  = conditional(cue == 1, 0, 180);

shw.Image(mwpi.arrow, [], szArrow, rotArrow, 'window', 'arrow');

% generate some seeds manually, so we can avoid a repeat in the very unlikely
% case that one occurs
nSeed = 3;

bSeedsDone = false;
while ~bSeedsDone
	arrSeed = arrayfun(@(n) randseed2, 1:nSeed);
	if numel(unique(arrSeed)) == nSeed
		bSeedsDone = true;
	end
end

% make the stimulus textures

szStim  = MWPI.Param('stim', 'size');
offset  = MWPI.Param('stim', 'offset');

shw.Blank('window', 'stim');

lClass = sParam.lClass(kRun, kBlock);
[imPromptLeft, imYesLeft, imNoLeft, distractorsLeft] = MWPI.Stimulus(lClass, arrSeed(1), level(lClass), ...
	'feedback', cue == 1, 'distractors', cue == 1);
shw.Image(imPromptLeft, [-offset, 0], szStim, 'window', 'stim');

rClass = sParam.rClass(kRun, kBlock);
[imPromptRight, imYesRight, imNoRight, distractorsRight] = MWPI.Stimulus(rClass, arrSeed(2), level(rClass), ...
	'feedback', cue == 2, 'distractors', cue == 2);
shw.Image(imPromptRight, [offset, 0], szStim, 'window', 'stim');

vClass = sParam.vClass(kRun, kBlock);
imV = MWPI.Stimulus(vClass, arrSeed(3), level(vClass));
shw.Blank('window', 'retention');
shw.Image(imV, [], szStim, 'window', 'retention');

shw.Blank('window', 'test');
shw.Blank('window', 'testYes');
shw.Blank('window', 'testNo');

% test texture
offset = MWPI.Param('stim','offset');
kMatch = sParam.posMatch(kRun, kBlock);
positions = {[0,-offset], [offset, 0], [0,offset], [-offset, 0]};
posMatch = positions{kMatch};
posDistractors = positions(1:4 ~= kMatch);

if cue == 1
	imMatch = imPromptLeft;
	imMatchYes = imYesLeft;
	imMatchNo  = imNoLeft;
	distractors = distractorsLeft;
else
	imMatch = imPromptRight;
	imMatchYes = imYesRight;
	imMatchNo  = imNoRight;
	distractors = distractorsRight;
end

shw.Image(imMatch, posMatch, szStim, 'window', 'test');
shw.Image(imMatchYes, posMatch, szStim, 'window', 'testYes');
shw.Image(imMatchNo, posMatch, szStim, 'window', 'testNo');

% cellfun(@(texture) arrayfun(@(i) ...
% 	shw.Image(distractors{i}, posDistractors{i}, szStim, 'window', texture), ...
% 	1:3), {'test', 'testYes', 'testNo'});

% show distractors only on test screen
arrayfun(@(i) shw.Image(distractors{i}, posDistractors{i}, szStim, 'window', 'test'), 1:3);

end