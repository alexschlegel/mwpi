function ShowPrompt(mwpi,sRun,kBlock,varargin)
% ShowPrompt
% 
% Description:	show the trial prompt screen
% 
% Syntax:	mwpi.ShowPrompt(sRun,kBlock,<options>)
% 
% In:
%	sRun	- the run parameter struct
% 	kBlock	- the block number
%	<options>:
%		window:	     ('main') the name of the window on which to show the prompt
%		transparent: (false)  whether the background is transparent
%							  (i.e. whether to not blank the screen first)
% 
% Updated: 2015-08-20 for mwpi
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'window'		, 'main',   ...
		'transparent'	, false		...
		);

%get the shape and operation order	
	locInput	= sRun.promptLoc(kBlock);
    
	shp	= sRun.promptFig(:,kBlock);    
	op = sRun.promptOp(:,kBlock);
    
%blank the screen
	if ~opt.transparent
		mwpi.Experiment.Show.Blank('fixation',false,'window',opt.window);
	end
%show the prompts
	mStimulus	= MWPI.Param('prompt','stimulus');
	mOperation	= MWPI.Param('prompt','operation');
	
	chrPrompt		= mStimulus(shp);
	chrOperation	= mOperation(op);

	dPrompt	= MWPI.Param('prompt','distance');
	
	xPrompt	= dPrompt*[-1 0 1 0];
	yPrompt	= dPrompt*[0 -1 0 1] + 0.25;
	
	strSize	= num2str(MWPI.Param('prompt','text'));
	colPmt  = MWPI.Param('prompt','color');
	
	for kP=1:4
		mwpi.Experiment.Show.Text( ...
		['<size:' strSize '><color:' colPmt '>' chrPrompt(kP) chrOperation(kP) '</color></size>'], ...
		[xPrompt(kP) yPrompt(kP)],'window',opt.window);
	end
%show the arrow
	im	= imrotate(mwpi.arrow,(1-locInput)*90);
	
	mwpi.Experiment.Show.Image(im,[],MWPI.Param('prompt','arrow'),'window',opt.window);
end