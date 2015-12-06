function seedCuedFig = PrepTextures(mwpi, sParam, kRun, kBlock, d, arrAbility)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'stim':			2 prompts, side by side
%				'arrow':		an arrow pointing left or right, cuing the
%								subject to remember one prompt or the other.								
%				'retention':	visual stim during retention period
%				'retentionLg':  retention period stim increased in size
%				'retentionSm':	retention period stim decreased in size
%				'test':			wm test after retention
%				'testYes':		test in color indicating success
%				'testNo':		test in color indicating failure
%
%	Syntax: mwpi.PrepTextures(kRun, kBlock)
%
%	In:	sParam:		the parameter struct (see MWPI.CalcParams)
%		kRun:		the current run
%		kBlock:		the current block
%		d:			the difficulty of the wm / test stimulus for this block
%		arrAbility:	a nClass x 1 array of ability estimates in the range [0, 1]
%					that determin the difficulty level for each class for
%					stimuli other than the wm / test stimulus
%
%	Out: seedCuedFig: the seed used to generate the cued prompt figure
%					  (i.e. the WM figure)
%
%	Updated: 2015-10-17

% verify block and run
if kBlock > size(sParam.cue, 2)
	error('Block out of range');
elseif kRun > size(sParam.cue, 1)
	error('Run out of range');
end

shw	 = mwpi.Experiment.Show;
cue  = sParam.cue(kRun, kBlock);

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

seedCuedFig = arrSeed(cue);

% make the stimulus textures

szStimVA  = MWPI.Param('stim', 'size');
szStimPX  = round(mwpi.Experiment.Window.va2px(szStimVA));
offset  = MWPI.Param('stim', 'offset');

shw.Blank('window', 'stim');

lClass = sParam.lClass(kRun, kBlock);
lLevel = conditional(cue == 1, d, arrAbility(lClass));
stimLeft = MWPI.Stimulus(lClass, arrSeed(1), lLevel, szStimPX, ...
	'feedback', cue == 1, 'distractors', cue == 1);

shw.Image(stimLeft.base, [-offset, 0], 'window', 'stim');


rClass = sParam.rClass(kRun, kBlock);
rLevel = conditional(cue == 2, d, arrAbility(rClass));
stimRight = MWPI.Stimulus(rClass, arrSeed(2), rLevel, szStimPX, ...
	'feedback', cue == 2, 'distractors', cue == 2);

shw.Image(stimRight.base, [offset, 0], 'window', 'stim');


vClass = sParam.vClass(kRun, kBlock);
stimV = MWPI.Stimulus(vClass, arrSeed(3), arrAbility(vClass), szStimPX, ...
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