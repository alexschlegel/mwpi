function im = Mapping(map_stim, map_op)
% MWPI.Stim.Mapping
% 
% Description:	construct a mapping image for the specified subject
% 
% Syntax:	im = MWPI.Stim.Mapping(map_stim, map_op)
%
% In:		map_stim: mapping of cues (A-D) to stimuli (R1, R2, P1, P2)
%			map_op:	  mapping of cues (1-4) to operations (CW, CCW, H, V)
% 
% Updated: 2015-07-28 for mwpi
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

s	= MWPI.Param('size','stimpx');
pad	= 20;

%stimuli
	[~,bStim]	= arrayfun(@(k) MWPI.Stim.Stimulus(k,'map',map_stim),(1:4)','uni',false);
	bStim			= cellfun(@(b) imPad(b,0,s+pad,s+pad),bStim,'uni',false);
%operations
	cOp		= {'cw';'ccw';'h';'v'};
	cOp		= cOp(map_op);
	
	strDirImage	= DirAppend(strDirBase,'code','@MWPI','image');
	cPathOp	= cellfun(@(op) PathUnsplit(strDirImage,op,'bmp'),cOp,'uni',false);
	bOp		= cellfun(@(f) imPad(~imread(f),0,s+pad,s+pad),cPathOp,'uni',false);
	
im	= repmat(double(~ImageGrid([bStim bOp]')),[1 1 3]);
im	= im(2:end-1,2:end-1,:);
