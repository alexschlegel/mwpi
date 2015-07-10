function PrepTextures(mwpi, kRun, kBlock)
% PrepTextures - prepare the textures for a single run of mwpi.
%	They should have already been opened by the calling function.
%	Textures:	'prompt'				== prompt screen
%				'task1' - 'task5'		== task (RSVP) screens 1-5
%				'taskYes1' - 'taskYes5' == task screens 1-5 after correct response
%				'taskNo1' - 'taskNo5'	== task screens 1-5 after incorrect response
%				'recall'				== recall screen
%				'recallYes'				== recall screen after correct response
%				'recallNo'				== recall screen after incorrect response
%
%	Syntax: mwpi.PrepTextures(kRun, kBlock)
%
%	Input:	kRun: the current run
%			kBlock: the current block
%
%	Updated: 2015-06-24

% verify run and block
if kRun > mwpi.maxRun
	error('Run out of range');
end

if kBlock > mwpi.nBlock
	error('Block out of range');
end

shw = mwpi.Experiment.Show;

% prompt screen
shw.Blank('window','prompt');
shw.Text(mwpi.blockType(kRun,kBlock),[0,MWPI.Param('size','textOffset')], 'window', 'prompt');
shw.Image(mwpi.stim{mwpi.wShape(kRun,kBlock)},...
	[0,MWPI.Param('size','offset')],MWPI.Param('size','stim'),'window','prompt');

% task screens
arrayfun(@MakeTaskScreens, 1:mwpi.RSVPLength);

% recall screen
shw.Blank('window','recall');
shw.Blank('window','recallYes');
shw.Blank('window','recallNo');

shw.Image(mwpi.stim{mwpi.rShape(kRun,kBlock)},[],...
			MWPI.Param('size','stim'),'window','recall');
shw.Image(mwpi.stimYes{mwpi.rShape(kRun,kBlock)},[],...
			MWPI.Param('size','stim'),'window','recallYes');
shw.Image(mwpi.stimNo{mwpi.rShape(kRun,kBlock)},[],...
			MWPI.Param('size','stim'),'window','recallNo');

shw.AddLog(['textures prepared for block ' num2str(kBlock)]);

%-----------------------------------------------------------------------%
	function MakeTaskScreens(kTrial)
		shw.Blank('window',['task' num2str(kTrial)]);
		shw.Blank('window',['taskYes' num2str(kTrial)]);
		shw.Blank('window',['taskNo' num2str(kTrial)]);
		
		% normal
		shw.Image(mwpi.stim{mwpi.rsvp(kRun,kBlock,kTrial)},[],...
			MWPI.Param('size','stim'),'window',['task' num2str(kTrial)]);
		shw.Image(mwpi.stim{mwpi.vShape(kRun,kBlock)}, [0,MWPI.Param('size','offset')],...
			MWPI.Param('size','stim'),'window',['task' num2str(kTrial)]);
		
		% correct
		shw.Image(mwpi.stimYes{mwpi.rsvp(kRun,kBlock,kTrial)},[],...
			MWPI.Param('size','stim'),'window',['taskYes' num2str(kTrial)]);
		shw.Image(mwpi.stim{mwpi.vShape(kRun,kBlock)}, [0,MWPI.Param('size','offset')],...
			MWPI.Param('size','stim'),'window',['taskYes' num2str(kTrial)]);
		
		% incorrect
		shw.Image(mwpi.stimNo{mwpi.rsvp(kRun,kBlock,kTrial)},[],...
			MWPI.Param('size','stim'),'window',['taskNo' num2str(kTrial)]);
		shw.Image(mwpi.stim{mwpi.vShape(kRun,kBlock)}, [0,MWPI.Param('size','offset')],...
			MWPI.Param('size','stim'),'window',['taskNo' num2str(kTrial)]);
	end
end