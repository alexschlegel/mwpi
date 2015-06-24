function Init(mwpi)
% MWPI.Init
%
% Description: generate the sequence of v/w blocks, target shapes, and RSVP stream.
% blockType = 'V' or 'W' - whether the block tests vision or working memory
% wShape	= the shape shown in the prompt at the start of a block
% vShape	= the shape shown during a block (the target for V blocks)
% rShape	= the shape shown during the recall screen (== wShape in 50% of blocks)
% target	= whichever shape is correct for each block
% rsvp		= the RSVP stream for each block
% match		= logical, whether each entry of rsvp matches the target for that block
% rMatch	= logical, whether rShape matches wShape for each block
%
% Syntax: mwpi.Init
%
% Updated 2015-06-24

% param struct for blockdesign
param.wShape = 1:32;
param.vShape = 1:32;
param.rMatch = 0:1;
param.rsvpSeed = [0,0.1]; % 0 = 2 matches in block, 0.1 = 1 match
% there is a ~6% chance per block of having more than this number of
% matches, because the "nonmatching" shapes are selected randomly from the 
% complete set. This could be changed, but I think this way might be better
% becuase it is less predictable for the subject.

[mwpi.blockType,param] = blockdesign('VW',mwpi.nBlock/2,mwpi.maxRun,param);
mwpi.wShape = param.wShape;
mwpi.vShape = param.vShape;
mwpi.rMatch = param.rMatch;
mwpi.target = arrayfun(@(type,wshp,vshp) conditional(type == 'W',wshp,vshp),...
	mwpi.blockType, mwpi.wShape, mwpi.vShape);

rsvpNum = cell2mat(arrayfun(@(seed) arrayfun(@(offset) seed + offset,...
	reshape(randomize(0:0.2:0.8),1,1,[])), param.rsvpSeed,'uni',false));
% the RSVP stream
mwpi.rsvp = arrayfun(@(i) arrayfun(@(rsvpn,target) ...
	conditional(rsvpn < MWPI.Param('exp','matchFrac'), target, randi(32)),...
	rsvpNum(:,:,i), mwpi.target), 1:mwpi.RSVPLength,'uni',false);

% whether the target matches the rsvp stream
mwpi.match = arrayfun(@(i) mwpi.rsvp{i} == mwpi.target, ...
	1:mwpi.RSVPLength, 'uni',false);

mwpi.rsvp = cat(3,mwpi.rsvp{:});
mwpi.match = cat(3,mwpi.match{:});

% recall shape
cUnused = arrayfun(@(wShp) [1:wShp-1,wShp+1:32], mwpi.wShape, 'uni', false);

mwpi.rShape = cellfun(@(wShp, rMat, unused) conditional(rMat,wShp,unused(randi(31))), ...
	num2cell(mwpi.wShape), num2cell(mwpi.rMatch), cUnused);

% save
cellfun(@(field) mwpi.Experiment.Info.Set('mwpi',field,mwpi.(field)), fieldnames(mwpi));

end