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
%		level:	an integer indicating the difficulty level (see MWPI.Param
%				for valid range)
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
bMatch = sParam.bTestMatch(kRun, kBlock);
cue    = sParam.cue(kRun, kBlock);

% make the cue

shw.Blank('window', 'cue');

strCue		= num2str(cue);
strSzCue	= num2str(MWPI.Param('cue', 'size'));
posCue		= MWPI.Param('cue', 'pos');

shw.Text(['<size:' strSzCue '>' strCue '</size>'], posCue, 'window', 'cue');

% generate some seeds manually, so we can avoid a repeat in the very unlikely
% case that one occurs
nSeed = conditional(bMatch, 3, 4);

bSeedsDone = false;
while ~bSeedsDone
	arrSeed = arrayfun(@(n) randseed2, 1:nSeed);
	if numel(unique(arrSeed)) == nSeed
		bSeedsDone = true;
	end
end

% make the stimulus textures

szStim  = MWPI.Param('stim', 'size');

prompt1Class = sParam.prompt1Class(kRun, kBlock);
[imPrompt1, imYes1, imNo1] = MWPI.Stimulus(prompt1Class, arrSeed(1), level, ...
	'feedback', bMatch & cue == 1);
shw.Blank('window', 'prompt1');
shw.Image(imPrompt1, [], szStim, 'window', 'prompt1');

prompt2Class = sParam.prompt2Class(kRun, kBlock);
[imPrompt2, imYes2, imNo2] = MWPI.Stimulus(prompt2Class, arrSeed(2), level, ...
	'feedback', bMatch & cue == 2);
shw.Blank('window', 'prompt2');
shw.Image(imPrompt2, [], szStim, 'window', 'prompt2');

vClass = sParam.vClass(kRun, kBlock);
imV = MWPI.Stimulus(vClass, arrSeed(3), level);
shw.Blank('window', 'retention');
shw.Image(imV, [], szStim, 'window', 'retention');

shw.Blank('window', 'test');
shw.Blank('window', 'testYes');
shw.Blank('window', 'testNo');

if bMatch % use the prompted stimulus for the test
	if cue == 1
		shw.Image(imPrompt1, [], szStim, 'window', 'test');
		shw.Image(imYes1, [], szStim, 'window', 'testYes');
		shw.Image(imNo1, [], szStim, 'window', 'testNo');
	else
		shw.Image(imPrompt2, [], szStim, 'window', 'test');
		shw.Image(imYes2, [], szStim, 'window', 'testYes');
		shw.Image(imNo2, [], szStim, 'window', 'testNo');
	end
else % generate a new stimulus for the test
	testClass = conditional(cue == 1, prompt1Class, prompt2Class);
	[imTest, imTestYes, imTestNo] = MWPI.Stimulus(testClass, arrSeed(4), level, ...
		'feedback', true);
	shw.Image(imTest, [], szStim, 'window', 'test');
	shw.Image(imTestYes, [], szStim, 'window', 'testYes');
	shw.Image(imTestNo, [], szStim, 'window', 'testNo');
end

end