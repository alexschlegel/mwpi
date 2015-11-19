function [stim, stimYes, stimNo, distractors] = Stimulus(class, seed, level, varargin)
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
%				3 = stimulus.image.scribble.cloud
%				4 = stimulus.image.scribble.wave
%
%	seed:	A seed to generate the stimulus. Pass an empty array to
%			generate a seed with randseed2.
%
%	level:	A number between 0 and 1 (inclusive) indicating the level,
%			where 0 is easiest and 1 is hardest.
%	<options>:
%		feedback: (false) generate colored versions for positive and negative
%				   feedback, and return them in stimYes and stimNo.
%
%	 distractors: (false) generate 3 distractors similar to the original,
%					and return them as a 3x1 cell in distractors.
%
% Out:
%	   stim:	 The stimulus image
%	  stimYes:  If 'colors' is true, the positive feedback stimulus (else empty)
%	   stimNo:  If 'colors' is true, the negative feedback stimulus (else empty)
% distractors:  if 'distractors' is true, a 3x1 cell of distractor images (else empty)
%
% Updated: 2015-10-17

opt = ParseArgs(varargin, 'feedback', false, 'distractors', false);

if isempty(seed)
	seed = randseed2;
end

stimYes = [];
stimNo = [];
distractors = [];

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
		fGenerator = @stimulus.image.scribble.cloud;
	case 4
		fGenerator = @stimulus.image.scribble.wave;
	otherwise
		error('invalid stimulus class');
end

generator = fGenerator(...
	'd', level, ...
	'seed', seed, ...
	'background', colBack, ...
	'foreground', colStim ...
	);
stim = generator.generate;

if opt.feedback
	generatorYes = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'background', colBack, ...
		'foreground', colYes ...
		);
	stimYes = generatorYes.generate;
	
	generatorNo = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'background', colBack, ...
		'foreground', colNo ...
		);
	stimNo = generatorNo.generate;
end

if opt.distractors
	distractors = generator.distractor(3);
end