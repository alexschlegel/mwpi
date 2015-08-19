function [im,b] = Stimulus(shp,varargin)
% MWPI.Stim.Stimulus
% 
% Description:	render a stimulus
% 
% Syntax:	[im,b] = MWPI.Stim.Stimulus(shp,<options>)
% 
% In:
%	shp		- the stimulus shape (1:4)
%	<options>:
%		map:		([1;3;2;4]) a 4x1 array specifying a mapping from (1:4) to
%					the actual stimulus, ordered as (R1,R2,P1,P2)
%		rotation:	(0) the stimulus rotation (0:3) (number of 90 degree CW rotations
%		flip:		(0) the stimulus flip ([0 'h' 'v'])
%       color:      (MWPI.Param('color','fore')) the color of the output image (RGB)
% 
% Out:
% 	im	- the stimulus image
%	b	- the stimulus mask
% 
% Updated: 2015-07-28 for mwpi
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'map'		, [1;3;2;4]	, ...
		'rotation'	, 0			, ...
		'flip'		, 0			, ...
        'color'     , MWPI.Param('color','fore') ...
		);

switch opt.map(shp)
	case 1 %R1
		[im,b]	= MWPI.Stim.Rect(1,opt.rotation,opt.flip,opt.color);
	case 2 %R2
		[im,b]	= MWPI.Stim.Rect(2,opt.rotation,opt.flip,opt.color);
	case 3 %P1
		[im,b]	= MWPI.Stim.Polar(1,opt.rotation,opt.flip,opt.color);
	case 4 %P2
		[im,b]	= MWPI.Stim.Polar(2,opt.rotation,opt.flip,opt.color);
	otherwise
		error('wtf?');
end
