function Init(mwpi)
% MWPI.Init
%
% Description: set up the experiment
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

% generate mappings
    % figure
    mwpi.figMap = mwpi.Experiment.Subject.Get('map_stim');
    if isempty(mwpi.figMap)
        mwpi.figMap = randomize((1:4)');
        mwpi.Experiment.Subject.Set('map_stim',mwpi.figMap);
    end

    % operation
    mwpi.opMap = mwpi.Experiment.Subject.Get('map_op');
    if isempty(mwpi.opMap)
        mwpi.opMap = randomize((1:4)');
        mwpi.Experiment.Subject.Set('map_op',mwpi.opMap);
    end

% define keys
    mwpi.Experiment.Input.Set('response', MWPI.Param('key','response'));
    mwpi.Experiment.Input.Set('match', MWPI.Param('key','match'));
    mwpi.Experiment.Input.Set('noMatch', MWPI.Param('key','noMatch'));

% from gridop
%load some images
	strDirImage	= DirAppend(mwpi.Experiment.File.GetDirectory('code'),'@MWPI','image');
	
	strPathArrow	= PathUnsplit(strDirImage,'arrow','bmp');
	colArrowBack	= MWPI.Param('color','arrowBack');
	colArrowBack	= uint8(reshape(colArrowBack,1,1,[]));
	colArrowFore	= mwpi.Experiment.Color.Get(MWPI.Param('prompt','color'));
	colArrowFore	= reshape(colArrowFore,1,1,[]);
	bArrow			= ~imread(strPathArrow);
	mwpi.arrow		= arrayfun(@(arw) conditional(arw,colArrowFore,colArrowBack),...
						bArrow, 'uni',false);
	mwpi.arrow		= cell2mat(mwpi.arrow);
	
	cOp		= {'cw';'ccw';'h';'v'};
	cPathOp	= cellfun(@(op) PathUnsplit(strDirImage,op,'bmp'),cOp,'uni',false);
	mwpi.op	= cellfun(@(f) ind2rgb(uint8(~imread(f)),[MWPI.Param('color','back');MWPI.Param('color','fore')]),cPathOp,'uni',false);

%set the reward
    % check if we're resuming an existing session
    mwpi.reward = mwpi.Experiment.Info.Get('mwpi','reward');
    
    if isempty(mwpi.reward)
        mwpi.reward	= MWPI.Param('reward','base');
        mwpi.Experiment.Info.Set('mwpi','reward',mwpi.reward);
    end

mwpi.Experiment.AddLog('initialized experiment');

end