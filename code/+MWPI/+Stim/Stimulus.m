function [im,indHFlip,indVFlip,indRRot,indLRot] = Stimulus(index,colFore,colBack)
% MWPI.Stim.Stimulus
% 
% Description:	render a stimulus
% 
% Syntax:	[im,] = MWPI.Stim.Stimulus(index,colFore,colBack)
% 
% In:
%	index	- the stimulus index (1:32)
%               Encoding: for the 5-bit integer n-1:
%				* bits 3-4 = shape (rect1,rect2,pol1,pol2)
%				* bits 1-2 = rotation (num of 90 degree CW rotations)
%				* bit 0 = horizontal flip (yes or no)
%	colFore - foreground color (RGB)
%	colBack - background color (RGB)
%
% Out:
% 	im	- the stimulus image
%   indHFlip - the index of the stimulus flipped horizontally
%   indVFlip - the index of the stimulus flipped vertically
%   indRRot - the index of the stimulus rotated to the right
%   indLRot - the index of the stimulus rotated to the left
%   
% 
% Updated: 2015-06-18 for MWPI
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

% calculate parameters
zIndex = index-1; % zero-based index
shp = floor(zIndex/8);
rot = mod(floor(zIndex/2),4);
flip = conditional(mod(zIndex, 2),'h',0);

switch shp
	case 0%R1
		im	= MWPI.Stim.Rect(1,rot,flip,colFore,colBack);
	case 1%R2
		im	= MWPI.Stim.Rect(2,rot,flip,colFore,colBack);
	case 2%P1
		im	= MWPI.Stim.Polar(1,rot,flip,colFore,colBack);
	case 3%P2
		im	= MWPI.Stim.Polar(2,rot,flip,colFore,colBack);
	otherwise
		error('wtf?');
end

indHFlip = bitxor(zIndex, 1) + 1;
indVFlip = bitxor(zIndex, 5) + 1;
indRRot = shp*8 + mod(rot+1,4)*2 + (flip == 'h') + 1;
indLRot = shp*8 + mod(rot-1,4)*2 + (flip == 'h') + 1;

end
