function [stim, stimYes, stimNo] = Stimulus(class, seed, level, varargin)
% MWPI.Stimulus
% 
% Description: generate a single MWPI Stimulus
%
% Syntax: MWPI.Stimulus(class, seed, level, <options>)
%
% In:
%	class:	A number from 1 to 4 that determines what type of stimulus gets created:
%				1 = stimulus.image.blob.round
%				2 = stimulus.image.blob.spike
%				3 = ?
%				4 = ?
%	seed:	A seed to generate the stimulus. Pass an empty array to
%			generate a seed with randseed2.
%	level:	an integer indicating the difficulty level (see MWPI.Param
%			for valid range)
%	<options>:
%		feedback: (false) generate colored versions for positive and negative
%				   feedback, and return them in stimYes and stimNo.
%
% Out:
%	stim:	 The stimulus image
%	stimYes: If 'colors' is true, the positive feedback stimulus (else empty)
%	stimNo:  If 'colors' is true, the negative feedback stimulus (else empty)
%
% Updated: 2015-10-17

opt = ParseArgs(varargin, 'feedback', false);

if isempty(seed)
	seed = randseed2;
end

stimYes = [];
stimNo = [];

colBack = MWPI.Param('color','back');
colStim = MWPI.Param('color','fore');
colYes  = MWPI.Param('color','yes');
colNo   = MWPI.Param('color','no');

switch class
	case 1
		fGenerator = @stimulus.image.blob.round;
	case 2
		fGenerator = @stimulus.image.blob.spike;
	case 3
		fGenerator = []; %TODO
	case 4
		fGenerator = []; %TODO
	otherwise
		error('invalid stimulus class');
end

generator = fGenerator(...
	'n', level, ...
	'seed', seed, ...
	'background', colBack, ...
	'foreground', colStim ...
	);
stim = generator.generate;

if opt.feedback
	generatorYes = fGenerator(...
		'n', level, ...
		'seed', seed, ...
		'background', colBack, ...
		'foreground', colYes ...
		);
	stimYes = generatorYes.generate;
	
	generatorNo = fGenerator(...
		'n', level, ...
		'seed', seed, ...
		'background', colBack, ...
		'foreground', colNo ...
		);
	stimNo = generatorNo.generate;
end

end