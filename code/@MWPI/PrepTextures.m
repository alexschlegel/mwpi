function ifo = PrepTextures(mwpi, sParam, d, arrAbility)
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
%	In:	sParam:		the parameter struct for this block (see MWPI.CalcParams)
%		d:			the difficulty of the wm / test stimulus for this block
%		arrAbility:	a nClass x 1 array of ability estimates in the range [0, 1]
%					that determine the difficulty level for each class for
%					stimuli other than the wm / test stimulus
% Out:
%	ifo:	A struct of information about the stimuli generated for each
%			stage. All 4x1 fields contain information about figures
%			on the screen in the order: [top; right; bottom; left]
%
%		ifo.prompt: 4x1 *cell of structs*, info on prompt screen figures
%		ifo.cued:   info on cued prompt screen figure (points to element of ifo.prompt)
%		ifo.uncued: info on prompt screen figure that is framed, but not
%					cued (points to element of ifo.prompt)
%		ifo.visual: info on visual/retention period figure
%		ifo.test:   4x1 struct array, info on test screen figures
%
%	Updated: 2016-01-29

shw	= mwpi.Experiment.Show;

% make the stimulus textures

szStimVA  = MWPI.Param('stim', 'size');
szStimPX  = round(mwpi.Experiment.Window.va2px(szStimVA));
offset  = MWPI.Param('stim', 'offset');

shw.Blank('window', 'stim');

cOffset = {[0,-offset], [offset, 0], [0, offset], [-offset, 0]};

[sStim, sIfo] = deal(struct(...
	'base',			cell(4,1), ...
	'yes',			cell(4,1), ...
	'no',			cell(4,1), ...
	'distractors',	cell(4,1), ...
	'small',		cell(4,1), ...
	'large',		cell(4,1)  ...
	));

for kPos = 1:4
	bCued   = sParam.posCued == kPos;
	bUncued = sParam.posUncued == kPos;
	bFrame = bCued || bUncued;
	
	kClass = sParam.promptClass(kPos);
	level = conditional(bCued, d, arrAbility(kClass));
	[sStim(kPos), sIfo(kPos)] = MWPI.Stimulus(kClass, sParam.seed(kPos), level, szStimPX, ...
		'feedback', bCued, 'distractors', bCued);
	ifo.prompt{kPos,1} = sIfo(kPos).base;
	
	shw.Image(sStim(kPos).base, cOffset{kPos}, 'border', bFrame, 'window', 'stim');
end

ifo.cued   = ifo.prompt{sParam.posCued};
ifo.uncued = ifo.prompt{sParam.posUncued};

% frame (cue)
shw.Blank('window', 'frame');
shw.Rectangle(MWPI.Param('color','back'), szStimVA, cOffset{sParam.posCued}, ...
	'border', true, 'window', 'frame');

% retention period
vClass = sParam.vClass;
[stimV, ifoV] = MWPI.Stimulus(vClass, sParam.seed(end), arrAbility(vClass), szStimPX, ...
	'small_large', true);
ifo.visual = ifoV.base;

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
kMatch = sParam.posMatch;
posMatch = cOffset{kMatch};
posDistractors = cOffset(1:4 ~= kMatch);

ifo.test(kMatch,1)         = ifo.cued;
ifo.test((1:4)' ~= kMatch) = sIfo(sParam.posCued).distractors;

stimTest = sStim(sParam.posCued);

shw.Image(stimTest.base, posMatch, 'window', 'test');
shw.Image(stimTest.yes,  posMatch, 'window', 'testYes');
shw.Image(stimTest.no,   posMatch, 'window', 'testNo');

% show distractors only on test screen
arrayfun(@(i) shw.Image(stimTest.distractors{i}, posDistractors{i}, 'window', 'test'), 1:3);

end