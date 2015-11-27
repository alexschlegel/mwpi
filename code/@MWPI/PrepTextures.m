function PrepTextures(mwpi, sParam, kRun, kBlock, level)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt1':		first of 2 wm prompts
%				'prompt2':		second of 2 wm prompts
%				'cue':			a number '1' or '2' on the screen,
%								cues the subject to remember prompt 1 or 2.								
%				'retention':	visual stim during retention period
%				'retentionLg':  retention period stim increased in size
%				'retentionSm':	retention period stim decreased in size
%				'test':			wm test after retention
%				'testYes':		test in color indicating success
%				'testNo':		test in color indicating failure
%
%	Syntax: mwpi.PrepTextures(kRun, kBlock)
%
%	In:	sParam: the parameter struct (see MWPI.CalcParams)
%		kRun:   the current run
%		kBlock: the current block
%		level:	a nClass x 1 array of numbers in the range [0, 1]
%				indicating the difficulty level for each class
%
%	Updated: 2015-10-17

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

szStimVA  = MWPI.Param('stim', 'size');
szStimPX  = round(mwpi.Experiment.Window.va2px(szStimVA));
offset  = MWPI.Param('stim', 'offset');

shw.Blank('window', 'stim');

lClass = sParam.lClass(kRun, kBlock);
stimLeft = MWPI.Stimulus(lClass, arrSeed(1), level(lClass), szStimPX, ...
	'feedback', cue == 1, 'distractors', cue == 1);

shw.Image(stimLeft.base, [-offset, 0], 'window', 'stim');


rClass = sParam.rClass(kRun, kBlock);
stimRight = MWPI.Stimulus(rClass, arrSeed(2), level(rClass), szStimPX, ...
	'feedback', cue == 2, 'distractors', cue == 2);

shw.Image(stimRight.base, [offset, 0], 'window', 'stim');


vClass = sParam.vClass(kRun, kBlock);
stimV = MWPI.Stimulus(vClass, arrSeed(3), level(vClass), szStimPX, ...
	'small_large', true);

shw.Blank('window', 'retention');
shw.Image(stimV.base, 'window', 'retention');

shw.Blank('window', 'retentionLg');
shw.Image(stimV.large, 'window', 'retentionLg');

shw.Blank('window', 'retentionSm');
shw.Image(stimV.small, 'window', 'retentionSm');

shw.Blank('window', 'test');
shw.Blank('window', 'testYes');
shw.Blank('window', 'testNo');

% test texture
offset = MWPI.Param('stim','offset');
kMatch = sParam.posMatch(kRun, kBlock);
positions = {[0,-offset], [offset, 0], [0,offset], [-offset, 0]};
posMatch = positions{kMatch};
posDistractors = positions(1:4 ~= kMatch);

stimTest = conditional(cue == 1, stimLeft, stimRight);

shw.Image(stimTest.base, posMatch, 'window', 'test');
shw.Image(stimTest.yes,  posMatch, 'window', 'testYes');
shw.Image(stimTest.no,   posMatch, 'window', 'testNo');

% show distractors only on test screen
arrayfun(@(i) shw.Image(stimTest.distractors{i}, posDistractors{i}, 'window', 'test'), 1:3);

end