function s = SubjectInfo(varargin)
% PercIm.SubjectInfo
%
% Description: compile a struct of subject info
%
% Syntax: s = PercIm.SubjectInfo(<options>)''
%
% In:
%   <options>:
%       subject:		(<all>) a cell of subject ids to include
%       exclude:		(<none>) a cell of subject ids to exclude
%       state:			('preprocess') the state of subjects to return. one of
%						the following:
%							all:		all subjects
%							fmri:		subjects with fmri sessions
%							preprocess:	preprocessed subjects
%
% Out:
%   s: the subject info struct
%
% Updated: 2016-04-14
% Copyright 2016 Ethan Blackwood, Alex Schlegel (schlegel@gmail.com). This
% work is licensed under a Creative Commons Attribution-NonCommercial-
% ShareAlike 3.0 Unported License. Adapted from GridOp by Alex Schlegel.

global strDirData;

opt	= ParseArgs(varargin,...
		'subject'		, {}			, ...
		'exclude'		, {}			, ...
		'state'			, 'preprocess'	  ...
		);

opt.exclude	= ForceCell(opt.exclude);
opt.state	= CheckInput(opt.state,'state',{'all','fmri','preprocess'});

status(sprintf('selected subject state: %s',opt.state));

%condition information
% BR = "blob round"
% BS = "blob spike"
% SC = "scribble cloud"
% SW = "scribble wave"

	s.class	= {'BR';'BS';'SC';'SW'};
		
    %remember, percept = "visual" and image = "working memory" / "cued"
	cScheme	= {'percept'; 'image'; 'image_uncued'};
	nScheme	= numel(cScheme);
    
%get the subject ids
	if isempty(opt.subject)
		cPathSubject	= FindFiles(strDirData,'^\w\w\w?\.mat$');
		
		cID	= cellfun(@PathGetFilePre,cPathSubject,'uni',false);
	else
		cID	= reshape(cellfun(@(id) regexprep(id,'\d{2}\w{3}\d{2}(\w{2,3})$','$1'),ForceCell(opt.subject),'uni',false),[],1);
	end
	
	%exclude
		cID	= setdiff(cID,opt.exclude);
	
	nSubject	= numel(cID);

	s.id	= cID;
    
%get some subject info
% 'ability' corresponds to the 'simD' calculated at start of simTest
	s.subject		= dealstruct('age','gender','handedness','ability',NaN(nSubject,1));
	s.subject.ability = num2cell(s.subject.ability);
    
    for kS=1:nSubject
		strPathSubject	= PathUnsplit(strDirData,cID{kS},'mat');
		x				= load(strPathSubject);
		
		s.subject.gender(kS)		= switch2(x.ifoSubject.gender,'f',0,'m',1,NaN);
		s.subject.handedness(kS)	= switch2(x.ifoSubject.handedness,'r',0,'l',1,NaN);
    end
    
%get the practice and fmri session paths    
	[s.code.practice,s.code.fmri,cPathPractice,cPathFMRI]	= deal(cell(nSubject,1));

	for kS=1:nSubject
		cPathSubject		= FindFiles(strDirData,['\d' s.id{kS} '\.mat$']);
		nSession			= numel(cPathSubject);
		tSession			= cellfun(@(f) ParseSessionCode(PathGetFilePre(f)),cPathSubject);
		[~,kSort]	= sort(tSession);
		
		if nSession>0
			cPathPractice{kS}	= cPathSubject{kSort(1)};
			s.code.practice{kS}	= PathGetFilePre(cPathPractice{kS});
			
			if nSession>1
				cPathFMRI{kS}	= cPathSubject{kSort(2)};
				s.code.fmri{kS}	= PathGetFilePre(cPathFMRI{kS});

				if nSession > 2
                    error([num2str(nSession) ' sessions found for subject ' s.id{kS} '.']);
				end
			end
		end
	end
	
%is the subject data preprocessed? TODO: figure out how to test for this.

%read the practice data (+ subject age)

	for kS=1:nSubject
		if ~isempty(cPathPractice{kS})
			x	= load(cPathPractice{kS});
			
			s.subject.age(kS)	= ConvertUnit(x.PTBIFO.experiment.start - x.PTBIFO.subject.dob,'ms','day')/365.25;
			
			% TODO: determine what other practice data we need
			
		end
	end
	
%read the fmri data
%--EDIT LINE--%
end
	