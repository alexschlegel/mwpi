function [im,b] = Stimulus(index,colFore,colBack)
% MWPI.Stim.Stimulus
% 
% Description:	render a stimulus
% 
% Syntax:	[im,b] = MWPI.Stim.Stimulus(shp,colFore,colBack)
% 
% In:
%	index	- the stimulus index (0:31)
%				* bits 3-4 = shape
%				* bits 1-2 = rotation (num of 90 degree CW rotations)
%				* bit 0 = horizontal flip (yes or no)
%	colFore - foreground color (RGB)
%	colBack - background color (RGB)
%
% Out:
% 	im	- the stimulus image
%	b	- the stimulus mask
% 
% Updated: 2015-05-30 for MWPI
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

% calculate parameters
shp = floor(index/8);
rot = mod(floor(index/2),4);
flip = conditional(mod(index, 2),'h',0);

switch shp
	case 0%R1
		[im,b]	= MWPI.Stim.Rect(1,rot,flip,colFore,colBack);
	case 1%R2
		[im,b]	= MWPI.Stim.Rect(2,rot,flip,colFore,colBack);
	case 2%P1
		[im,b]	= MWPI.Stim.Polar(1,rot,flip,colFore,colBack);
	case 3%P2
		[im,b]	= MWPI.Stim.Polar(2,rot,flip,colFore,colBack);
	otherwise
		error('wtf?');
end
