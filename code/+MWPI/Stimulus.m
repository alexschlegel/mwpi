function sStim = Stimulus(class, seed, level, size, varargin)
% MWPI.Stimulus
% 
% Description: generate a single MWPI Stimulus
%
% Syntax: MWPI.Stimulus(class, seed, level, size, <options>)
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
%
%	size: The size of the stimulus in pixels
%
%	<options>:
%		feedback: (false) generate colored versions for positive and negative
%				   feedback, and return them in sStim.yes and sStim.no.
%
%	 distractors: (false) generate 3 distractors similar to the original,
%					and return them as a 3x1 cell in sStim.distractors.
%
%	 small_large: (false) generate a larger and a smaller version of the
%				  stimulus (ratios are specified in MWPI.Param) and return
%				  in sStim.small and sStim.large.
%
% Out:
%	   sStim:	 A struct containing the base stimulus in sStim.base, and
%				 any variants in other fields as specified by the options.
%
% Updated: 2015-10-17

opt = ParseArgs(varargin, ...
	'feedback', false, ...
	'distractors', false, ...
	'small_large', false ...
	);

if isempty(seed)
	seed = randseed2;
end

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
	'size', size, ...
	'background', colBack, ...
	'foreground', colStim ...
	);
sStim.base = generator.generate;

if opt.feedback
	generatorYes = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'size', size, ...
		'background', colBack, ...
		'foreground', colYes ...
		);
	sStim.yes = generatorYes.generate;
	
	generatorNo = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'size', size, ...
		'background', colBack, ...
		'foreground', colNo ...
		);
	sStim.no = generatorNo.generate;
end

if opt.distractors
	sStim.distractors = generator.distractor(3);
end

if opt.small_large
	szSmall = round(size * MWPI.Param('fixation', 'shrinkMult'));
	szLarge = round(size * MWPI.Param('fixation', 'growMult'));
	
	generatorSmall = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'size', szSmall, ...
		'background', colBack, ...
		'foreground', colStim ...
		);
	sStim.small = generatorSmall.generate;
	
	generatorLarge = fGenerator(...
		'd', level, ...
		'seed', seed, ...
		'size', szLarge, ...
		'background', colBack, ...
		'foreground', colStim ...
		);
	sStim.large = generatorLarge.generate;
end

end