function Init(mwpi)
% MWPI.Init
%
% Description: Generate and save the parameters for each block of the experiment.
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

% generate mappings
% figure
figMap = mwpi.Experiment.Subject.Get('map_stim');
if isempty(figMap)
    figMap = randomize((1:4)');
    mwpi.Experiment.Subject.Set('map_stim',figMap);
end

% operation
opMap = mwpi.Experiment.Subject.Get('map_op');
if isempty(opMap)
    opMap = randomize((1:4)');
    mwpi.Experiment.Subject.Set('map_op',opMap);
end

% from gridop
%load some images
	strDirImage	= DirAppend(mwpi.Experiment.File.GetDirectory('code'),'@MWPI','image');
	
	strPathArrow	= PathUnsplit(strDirImage,'arrow','bmp');
	mwpi.arrow		= ind2rgb(uint8(~imread(strPathArrow)),[MWPI.Param('color','back');MWPI.Param('color','fore')]);
	
	cOp		= {'cw';'ccw';'h';'v'};
	cPathOp	= cellfun(@(op) PathUnsplit(strDirImage,op,'bmp'),cOp,'uni',false);
	mwpi.op	= cellfun(@(f) ind2rgb(uint8(~imread(f)),[MWPI.Param('color','back');MWPI.Param('color','fore')]),cPathOp,'uni',false);
%set the initial reward
	mwpi.reward	= MWPI.Param('reward','base');


end