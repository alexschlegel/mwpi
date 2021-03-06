function s = ClassificationInfo(varargin)
% PercIm.ClassificationInfo
%
% Description: load information about fMRI runs needed for classification
% analyses. Based on mwlearn's GO.BehavioralResults.
%
% Syntax: s = ClassificationInfo(<options>)
%
% In:
%	<options>:
%		session:	(<all>) a session code or cell of session codes
%
%		ifo:		(PercIm.SubjectInfo) precalculated subject info struct
%
%		offset:		(0) number of TRs to offset the start of each chunk
%					from the start of a block (not including 1 TR for the
%					hemodynamic response function).
%
%		maxlen:		(4) max number of TRs included in each chunk. Will be
%					less than this if the number of TRs per block is less
%					than offset + maxlen.
%
%   fixation_threshold: (0.85) the minimum mean fixation task accuracy per run required
%          to include a run in the correct results.
%
%		fcorrect:   (<no correction>) the handle to a function that
%					performs manual corrections to the labels and chunks of
%					each run. An fcorrect function is specified as follows:
%
%					Syntax: [targetOut, eventOut] = fcorrect(session, run, targetIn, eventIn)
%
%						session:	the session code
%						run:		the run number
%						targetIn:	a target array that has not been manually corrected
%						targetOut:  the corrected version of targetIn
%						eventIn:	an event matrix that has not been manually corrected
%						eventOut:	the corrected version of eventIn,
%									or empty array if eventIn was empty.
%
% Out:
%	s:	a struct of classification info
%
% Updated: 2016-10-03
% Copyright 2016 Alex Schlegel (schlegel@gmail.com) and Ethan Blackwood.
% This work is licensed under a Creative Commons Attribution-NonCommercial-
% ShareAlike 3.0 Unported License.

global strDirData;

%parse the inputs
	opt	= ParseArgs(varargin,...
			'session'			, []					, ...
			'ifo'				, []					, ...
			'offset'			, 0						, ...
			'maxlen'			, 4						, ...
			'fixation_threshold', 0.85, ...
			'fcorrect'			, @(s,r,t,e) deal(t,e)	  ...
			);

	if isempty(opt.ifo)
		opt.ifo = PercIm.SubjectInfo;
	end

	if isempty(opt.session)
		cSession	= opt.ifo.code.fmri;
	else
		cSession	= ForceCell(opt.session);
	end
	
	cPathSession = cellfun(@(sess) PathUnsplit(strDirData, sess, 'mat'), cSession, 'uni', false);
	
	
	% temporarily remove research dir from path to deal with crashing issue in R2017a
	strDirLib = PathSplit(which('PrepPI'));
	strDirResearch = DirAppend(strDirLib, 'research');
	rmpath(strDirResearch);
	warning('off','MATLAB:load:classNotFound');
	warning('off','MATLAB:dispatcher:UnresolvedFunctionHandle');
	
	cPTBIFO = cellfun(@(path) conditional(FileExists(path), ...
							  getfield(load(path), 'PTBIFO'), []), ...
							  cPathSession, 'uni', false);
						  
	% put it back
	addpath(strDirResearch);
	warning('on','MATLAB:load:classNotFound');
	warning('on','MATLAB:dispatcher:UnresolvedFunctionHandle');

	cResult	= cellfunprogress(@(sSession) LoadInfo(sSession,opt),cPTBIFO,...
 							'label'	, 'loading mwpi classification info'	, ...
 							'uni'	, false									  ...
 							);

%restructure the results
	s	= restruct(cell2mat(cResult), 'array', true);
end
%--------------------------------------------------------------------------%

function [sResult, bError] = LoadInfo(sSession, opt)

	bError = false;
	cScheme = opt.ifo.cScheme;

	if ~isempty(sSession)

		PIParam = MWPI.Param;

		%%% Part 1: per-block parameters and results %%%

		% get stimulus ids and bCorrects, which are all in the same place %

		% matrix of field names vs. what they're called in the struct
		cField = [ [cScheme; 'testCorrect'], {
											'vClass'
											'cClass'
											'ucClass'
											'bCorrect'
										}
				 ];
		nField = size(cField,1);

		sRes = sSession.mwpi.run;

		sBlock = struct;
		for kF=1:nField
			strFieldIn	= cField{kF,2};
			strFieldOut	= cField{kF,1};

			x = arrayfun(@(run) [run.res.(strFieldIn)], sRes, 'uni',false);
			x = vertcat(x{:});

			sBlock.(strFieldOut) = x;
		end

    % add fixation task average accuracy (per-run mean)
    sBlock.fixationAcc = repmat([sRes.meanFracFixationCorrect]',1,numel(sRes(1).res));
    sBlock.correct = sBlock.testCorrect & (sBlock.fixationAcc >= opt.fixation_threshold);

		% response time %
		% stored values are already relative to test screen, in units of TR
		x	= arrayfun(@(run) arrayfun(@(block) block.test.tResponse, ...
			run.res, 'uni', false), sRes', 'uni', false);

		% replace empty response times with NaNs.
		x	= cellfun(@(cx) cellfun(@(x) unless(x,{NaN}),cx,'uni',false),x,'uni',false);

		% unpack cells
		tResponse  = cellfun(@(cx) cellfun(@(x) x{1}, cx),x,'uni',false);
		tResponse  = vertcat(tResponse{:});

		% convert to ms
		TR = PIParam.trTime;
		sBlock.rt = TR * tResponse;


		%%% Part 2: per-TR target and chunk information %%%

		% block2target parameters
		HRF			= 1;
		BlockOffset = opt.offset;
		BlockSub	= opt.maxlen;

		% timings
		durBlock	= PIParam.exp.block.retention.time;

		durRest		= PIParam.exp.block.test.time		+ ...
					  PIParam.exp.block.feedback.time	+ ...
					  PIParam.exp.rest.time				+ ...
					  PIParam.exp.block.prompt.time;

		durPre		= PIParam.exp.rest.time			+ ...
					  PIParam.exp.block.prompt.time	- ...
					  durRest;

		durPost		= PIParam.exp.block.test.time		+ ...
					  PIParam.exp.block.feedback.time	+ ...
					  PIParam.exp.post.time				- ...
					  durRest;

		durRun		= PIParam.exp.run.time;

		% construct attributes
		sAttr = struct;
		nScheme = numel(cScheme);
		cCondition = opt.ifo.cClass;
		nCondition = numel(cCondition);
		cConditionCI	= [repmat({'Blank'},[nCondition 1]); cCondition];

		for kS=1:nScheme
			strScheme = cScheme{kS};

			nRun			= size(sBlock.(strScheme),1);

			% all blocks
				[cTarget,cEvent]	= deal(cell(nRun,1));
				for kR=1:nRun

					block		= sBlock.(strScheme)(kR,:);

					% target cell
					cTarget{kR} = block2target(block, durBlock, ...
						durRest, cCondition, durPre, durPost, ...
						'hrf',			HRF,			...
						'block_offset',	BlockOffset,	...
						'block_sub',	BlockSub		...
						);

					% event matrix
					if kS==1
						cEvent{kR}	= block2event(block,durBlock,durRest,durPre,durPost);
					end

					% manual corrections
					strSession = sSession.session.name;
					[cTarget{kR}, cEvent{kR}] = opt.fcorrect(strSession, kR, cTarget{kR}, cEvent{kR});
				end

				sAttr.target.(strScheme).all = vertcat(cTarget{:});

				if kS==1
					event		= eventcat(cEvent,durRun);
					nEvent		= size(event,1);
					durRunTotal	= durRun*nRun;

					event(:,1)	= 1:nEvent;
					event(:,2)	= event(:,2) + HRF + BlockOffset;
					event(:,3)	= BlockSub;
					ev			= event2ev(event,durRunTotal);

					sAttr.chunk.all	= sum(ev.*repmat(1:nEvent,[durRunTotal 1]),2);
				end

			% just correct blocks
				[cTarget,cEvent]	= deal(cell(nRun,1));
				for kR=1:nRun

					block		= sBlock.(strScheme)(kR,:);
					correct		= sBlock.correct(kR,:);
					blockCI		= block + nCondition*correct;

					% target cell
					cTarget{kR} = block2target(blockCI, durBlock, ...
						durRest, cConditionCI, durPre, durPost, ...
						'hrf',			HRF,			...
						'block_offset',	BlockOffset,	...
						'block_sub',	BlockSub		...
						);

					% event matrix
					if kS==1
						cEvent{kR}	= block2event(blockCI,durBlock,durRest,durPre,durPost);
					end

					% manual corrections
					[cTarget{kR}, cEvent{kR}] = opt.fcorrect(strSession, kR, cTarget{kR}, cEvent{kR});
				end

				sAttr.target.(strScheme).correct = vertcat(cTarget{:});

				if kS==1
					event = eventcat(cEvent,durRun);
					% remove incorrect events
					event(event(:,1)<=nCondition,:) = [];

					nEvent		= size(event,1);
					durRunTotal	= durRun*nRun;

					event(:,1)	= 1:nEvent;
					event(:,2)	= event(:,2) + HRF + BlockOffset;
					event(:,3)	= BlockSub;
					ev			= event2ev(event,durRunTotal);

					sAttr.chunk.correct	= sum(ev.*repmat(1:nEvent,[durRunTotal 1]),2);
				end
		end

		sResult = struct(...
			'block'	, sBlock	, ...
			'attr'	, sAttr		  ...
			);

	else % data file for the session not found.
		bError = true;
		% return empty struct
		sResult = struct(...
			'block'	,	dealstruct(cScheme{:},'correct','rt',[]), ...
			'attr'	,	struct(...
				'target'	,	dealstruct(cScheme{:},dealstruct('all','correct',[])), ...
				'chunk'		,	dealstruct('all','correct',[]) ...
				) ...
			);
	end
end
