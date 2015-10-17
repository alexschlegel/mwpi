function PrepTextures(mwpi, kRun, kBlock)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt1':		first of 2 wm prompts
%				'prompt2':		second of 2 wm prompts
%				'retention':	visual stim during retention period
%				'test'			wm test after retention
%				'testYes'		test in color indicating success
%				'testNo'		test in color indicating failure
%
%	Syntax: mwpi.PrepTextures(kRun, kBlock)
%
%	Input:	kRun:   the current run
%			kBlock: the current block
%
%	Updated: 2015-10-16

sParam = mwpi.sParam;

% verify block and run
if kBlock > size(sParam.cue, 2)
	error('Block out of range');
elseif kRun > size(sParam.cue, 1)
	error('Run out of range');
end

shw = mwpi.Experiment.Show;
stimSz = MWPI.Param('size','stim');

% generate some seeds manually, so we can avoid a repeat in the very unlikely
% case that one occurs

%--------------- EDIT LINE --------------------------------%
    
    shw.Image(cat(3,pStim,bStim), [], probeSz, 'window', 'probe');
    shw.Image(cat(3,pStimYes,bStim), [], probeSz, 'window', 'probeYes');
    shw.Image(cat(3,pStimNo,bStim), [], probeSz, 'window', 'probeNo');
end

end