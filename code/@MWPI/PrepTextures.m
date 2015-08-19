function PrepTextures(mwpi, sRun, kBlock)
% PrepTextures - prepare the textures for a single block of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt'				== prompt screen
%				'task'          		== screen with visual stimulus (before probe)
%               'probe'                 == task screen plus probe figure (only if this is
%                                          a probe block)
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

if kBlock > mwpi.nBlock
	error('Block out of range');
end

shw = mwpi.Experiment.Show;

% prompt screen
shw.Blank('window','prompt');


end