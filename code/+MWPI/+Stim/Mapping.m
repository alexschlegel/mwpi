function im = Mapping(id)
% GO.Stim.Mapping
% 
% Description:	construct a mapping image for the specified subject
% 
% Syntax:	im = GO.Stim.Mapping(id)
% 
% Updated: 2013-09-19
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirBase

strPathSubject	= PathUnsplit(DirAppend(strDirBase,'data'),id,'mat');

ifo	= getfield(load(strPathSubject),'ifoSubject');

s	= GO.Param('size','stim');
pad	= 20;

%stimuli
	[imStim,bStim]	= arrayfun(@(k) GO.Stim.Stimulus(k,'map',ifo.map_stim),(1:4)','uni',false);
	bStim			= cellfun(@(b) imPad(b,0,s+pad,s+pad),bStim,'uni',false);
%operations
	cOp		= {'cw';'ccw';'h';'v'};
	cOp		= cOp(ifo.map_op);
	
	strDirImage	= DirAppend(strDirBase,'code','@GridOp','image');
	cPathOp	= cellfun(@(op) PathUnsplit(strDirImage,op,'bmp'),cOp,'uni',false);
	bOp		= cellfun(@(f) imPad(~imread(f),0,s+pad,s+pad),cPathOp,'uni',false);
	
im	= repmat(double(~ImageGrid([bStim bOp]')),[1 1 3]);
im	= im(2:end-1,2:end-1,:);
