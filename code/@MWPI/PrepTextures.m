function seedCuedFig = PrepTextures(mwpi, sParam, kRun, kBlock, d, arrAbility)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'stim':			4 prompt stimuli, two with frames
%				'frame':		one frame remains as the cue								
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
if kBlock > size(sParam.cClass, 2)
	error('Block out of range');
elseif kRun > size(sParam.cClass, 1)
	error('Run out of range');
end

shw			 = mwpi.Experiment.Show;
promptClass  = sParam.promptClass(kRun, kBlock, :);
posCued      = sParam.posCued(kRun, kBlock);
posUncued	 = sParam.posUncued(kRun, kBlock);

% generate some seeds manually, so we can avoid a repeat in the very unlikely
% case that one occurs
nSeed = 5;

bSeedsDone = false;
while ~bSeedsDone
	arrSeed = arrayfun(@(n) randseed2, 1:nSeed);
	if numel(unique(arrSeed)) == nSeed
		bSeedsDone = true;
	end
end

seedCuedFig = arrSeed(posCued);

% make the stimulus textures

szStimVA  = MWPI.Param('stim', 'size');
szStimPX  = round(mwpi.Experiment.Window.va2px(szStimVA));
offset  = MWPI.Param('stim', 'offset');

shw.Blank('window', 'stim');

cOffset = {[0,-offset], [offset, 0], [0, offset], [-offset, 0]};

sStim = struct(...
	'base',			cell(4,1), ...
	'yes',			cell(4,1), ...
	'no',			cell(4,1), ...
	'distractors',	cell(4,1), ...
	'small',		cell(4,1), ...
	'large',		cell(4,1)  ...
	);

for kPos = 1:4
	bCue = posCued == kPos;
	bFrame = bCue || posUncued == kPos;
	
	kClass = promptClass(kPos);
	level = conditional(bCue, d, arrAbility(kClass));
	sStim(kPos) = MWPI.Stimulus(kClass, arrSeed(kPos), level, szStimPX, ...
		'feedback', bCue, 'distractors', bCue);
	
	shw.Image(sStim(kPos).base, cOffset{kPos}, 'border', bFrame, 'window', 'stim');
end

% frame (cue)
shw.Blank('window', 'frame');
shw.Rectangle(MWPI.Param('color','back'), szStimVA, cOffset{posCued}, ...
	'border', true, 'window', 'frame');

% retention period
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
kMatch = sParam.posMatch(kRun, kBlock);
posMatch = cOffset{kMatch};
posDistractors = cOffset(1:4 ~= kMatch);

stimTest = sStim(posCued);

shw.Image(stimTest.base, posMatch, 'window', 'test');
shw.Image(stimTest.yes,  posMatch, 'window', 'testYes');
shw.Image(stimTest.no,   posMatch, 'window', 'testNo');

% show distractors only on test screen
arrayfun(@(i) shw.Image(stimTest.distractors{i}, posDistractors{i}, 'window', 'test'), 1:3);

end