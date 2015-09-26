function Mapping(mwpi,varargin)
% MWPI.Mapping
% 
% Description:	show the stimulus and operation mappings
% 
% Syntax:	mwpi.Mapping(<options>)
%
% In:
%	<options>:
%		wait:	(true) true to wait for user input before returning
%		window:	('main') window to show the mapping
% 
% Updated: 2015-08-10 for mwpi
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'wait'	, true,	  ...
		'window', 'main'  ...
		);

%get the stimuli
	cStim	= arrayfun(@(k) MWPI.Stim.Stimulus(k,'map',mwpi.figMap),(1:4)','uni',false);

%open a texture
%	sTexture	= switch2(mwpi.Experiment.Info.Get('go','session'),1,800,2,1000);
	sTexture = 1000;
	mwpi.Experiment.Window.OpenTexture('mapping',[sTexture sTexture]);
%show the stimuli
	mwpi.Experiment.Show.Text('<size:1><color:marigold>shapes</color></size>',[0 -3.5],'window','mapping');
	
	strStim	= MWPI.Param('prompt','stimulus');
	
	for k=1:4
		mwpi.Experiment.Show.Image(cStim{k},[4*(k-1)-6 -1.75],2.5,'window','mapping');
		mwpi.Experiment.Show.Text(['<size:1><style:normal>' strStim(k) '</style></size>'],[4*(k-1)-6 0.5],'window','mapping');
	end

%show the operations
	mwpi.Experiment.Show.Text('<size:1><color:marigold>operations</color></size>',[0 2.25],'window','mapping');
	
	strOp	= MWPI.Param('prompt','operation');
	
	for k=1:4
		mwpi.Experiment.Show.Image(mwpi.op{mwpi.opMap(k)},[4*(k-1)-6 4],2.5,'window','mapping');
		mwpi.Experiment.Show.Text(['<size:1><style:normal>' strOp(k) '</style></size>'],[4*(k-1)-6 6.25],'window','mapping');
	end

%show the instructions screen
	if opt.wait
		fResponse	= [];
		strPrompt	= [];
	else
		fResponse	= false;
		strPrompt	= ' ';
	end
	
	mwpi.Experiment.Show.Instructions('',...
					'figure'	, 'mapping'	, ...
					'fresponse'	, fResponse	, ...
					'prompt'	, strPrompt	, ...
					'window'	, opt.window  ...
					);

%remove the texture
	mwpi.Experiment.Window.CloseTexture('mapping');
	
