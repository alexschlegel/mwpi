function [sStim, ifo] = Stimulus(class, seed, level, size, varargin)
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
%	  base_color: (MWPI.Param('color','fore')) the color of the base image
%
% Out:
%	   sStim:	 A struct containing the base stimulus in sStim.base, and
%				 any variants in other fields as specified by the options.
%		 ifo:	 A struct, with the same field names as sStim, containing
%				 information about each stimulus generated (the ifo.param
%				 value returned from the generator method)
%
% Updated: 2015-10-17

opt = ParseArgs(varargin, ...
	'feedback', false, ...
	'distractors', false, ...
	'small_large', false, ...
	'base_color', MWPI.Param('color', 'fore') ...
	);

if isempty(seed)
	seed = randseed2;
end

[sStim, ifo] = deal(dealstruct('base', 'yes', 'no', 'distractors', 'small',	'large', []));

colBack = MWPI.Param('color','back');
colStim = opt.base_color;
colYes  = MWPI.Param('color','yes');
colNo   = MWPI.Param('color','no');

% map level to acceptable d range
dmin = MWPI.Param('stim','dmin');
dmax = MWPI.Param('stim','dmax');
d = MapValue(level, 0, 1, dmin, dmax);

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
	'd', d, ...
	'seed', seed, ...
	'size', size, ...
	'background', colBack, ...
	'foreground', colStim ...
	);
[sStim.base, baseIfo] = generator.generate;
ifo.base = baseIfo.param;

if opt.feedback
	generatorYes = fGenerator(...
		'd', d, ...
		'seed', seed, ...
		'size', size, ...
		'background', colBack, ...
		'foreground', colYes ...
		);
	[sStim.yes, yesIfo] = generatorYes.generate;
	ifo.yes = yesIfo.param;
	
	generatorNo = fGenerator(...
		'd', d, ...
		'seed', seed, ...
		'size', size, ...
		'background', colBack, ...
		'foreground', colNo ...
		);
	[sStim.no, noIfo] = generatorNo.generate;
	ifo.no = noIfo.param;
end

if opt.distractors
	[sStim.distractors, distractorsIfo] = generator.distractor(3);
	ifo.distractors = vertcat(distractorsIfo.param);
end

if opt.small_large
	szSmall = round(size * MWPI.Param('fixation', 'shrinkMult'));
	szLarge = round(size * MWPI.Param('fixation', 'growMult'));
	
	generatorSmall = fGenerator(...
		'd', d, ...
		'seed', seed, ...
		'size', szSmall, ...
		'background', colBack, ...
		'foreground', colStim ...
		);
	[sStim.small, smallIfo] = generatorSmall.generate;
	ifo.small = smallIfo.param;
	
	generatorLarge = fGenerator(...
		'd', d, ...
		'seed', seed, ...
		'size', szLarge, ...
		'background', colBack, ...
		'foreground', colStim ...
		);
	[sStim.large, largeIfo] = generatorLarge.generate;
	ifo.large = largeIfo.param;
end

end