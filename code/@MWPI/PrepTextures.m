function PrepTextures(mwpi, sRun, kBlock)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt'				== prompt screen
%				'task'          		== screen with visual stimulus (before probe)
%               'probe'                 == task screen plus probe figure (only if this is
%                                          a probe block, otherwise same as task)
%               'probeYes'              == same as probe, but with a green probe
%               'probeNo'               == same as probe, but with a red probe
%
%	Syntax: mwpi.PrepTextures(sRun, kBlock)
%
%	Input:	sRun: the struct of parameters for the current run
%			kBlock: the current block
%
%	Updated: 2015-06-24

% verify block

if kBlock > numel(sRun.bProbe)
	error('Block out of range');
end

shw = mwpi.Experiment.Show;
stimSz = MWPI.Param('size','stim');
probeSz = MWPI.Param('size','probe');

% task screen
shw.Blank('window','task');

[vRot, vFlip] = MWPI.Operate(sRun.vOp(kBlock), 'map', mwpi.opMap, 'initflip', 'h');
vStim = MWPI.Stim.Stimulus(sRun.vFig(kBlock), 'map', mwpi.figMap, ...
    'rotation', vRot, 'flip', vFlip);

shw.Image(vStim, [], stimSz, 'window', 'task');

% prompt screen
% start with task screen
shw.Texture('task','window','prompt');
mwpi.ShowPrompt(sRun, kBlock, 'window','prompt','transparent',true);

% copy task screen to probe windows
shw.Texture('task', 'window', 'probe');
shw.Texture('task', 'window', 'probeYes');
shw.Texture('task', 'window', 'probeNo');

if sRun.bProbe(kBlock)
    
    % probe screens    
   initflip = conditional(sRun.bProbeHFlip(kBlock), 'h', 0);
    [pRot, pFlip] = MWPI.Operate(sRun.pOp(kBlock), 'map', mwpi.opMap, 'initflip', initflip);
    
    [pStim, bStim] = MWPI.Stim.Stimulus(sRun.pFig(kBlock), 'map', mwpi.figMap, ...
        'rotation', pRot, 'flip', pFlip, 'color', MWPI.Param('color','probe'));
    pStimYes = MWPI.Stim.Stimulus(sRun.pFig(kBlock), 'map', mwpi.figMap, ...
        'rotation', pRot, 'flip', pFlip, 'color', MWPI.Param('color','yes'));
    pStimNo = MWPI.Stim.Stimulus(sRun.pFig(kBlock), 'map', mwpi.figMap, ...
        'rotation', pRot, 'flip', pFlip, 'color', MWPI.Param('color','no'));
    
    shw.Image(cat(3,pStim,bStim), [], probeSz, 'window', 'probe');
    shw.Image(cat(3,pStimYes,bStim), [], probeSz, 'window', 'probeYes');
    shw.Image(cat(3,pStimNo,bStim), [], probeSz, 'window', 'probeNo');
end

end