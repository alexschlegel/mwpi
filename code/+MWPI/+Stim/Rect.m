function [im,b] = Rect(shp,rot,flip,varargin)
% MWPI.Stim.Rect
% 
% Description:	create a rect stimulus image
% 
% Syntax:	[im,b] = MWPI.Stim.Rect(shp,rot,flip,[col]=<default>,[s]=<default>)
% 
% In:
% 	shp		- the shape number
%	rot		- the number of 90 degree CW rotations (negative for CCW)
%	flip	- flip: 0 for none, 'h' for H flip, 'v' for V flip
%	[col]	- the color
%	[s]		- the size of the output image
% 
% Out:
% 	im	- the output image
%	b	- the binary image
% 
% Updated: 2015-07-28 for mwpi
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
[col,s]	= ParseArgs(varargin,MWPI.Param('color','fore'),MWPI.Param('size','stimpx'));

%the shape
	sf	= s*MWPI.Param('shape','rect_f');
	
	shp	= MWPI.Param('shape','rect',shp);
	b	= imresize(logical(shp),[sf sf],'nearest');
	b	= imPad(b,0,s,s);
%flip it
	switch flip
		case 0%nothing to do
		case 'h'%horizontal flip
			b	= fliplr(b);
		case 'v'%vertical flip
			b	= flipud(b);
	end
%rotate it
	b	= imrotate(b,-rot*90);

%RGB image
	colBack	= MWPI.Param('color','back');
	colFore	= col;
	col		= im2double([colBack; colFore]);
	
	im	= ind2rgb(uint8(b),col);
