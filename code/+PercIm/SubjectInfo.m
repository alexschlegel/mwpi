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
	s.path.session = struct('practice', {}, 'fmri', {});

	for kS=1:nSubject
		cPathSubject		= FindFiles(strDirData,['\d' s.id{kS} '\.mat$']);
		nSession			= numel(cPathSubject);
		tSession			= cellfun(@(f) ParseSessionCode(PathGetFilePre(f)),cPathSubject);
		[~,kSort]	= sort(tSession);

		if nSession>0
			s.path.session.practice{kS}	= cPathSubject{kSort(1)};
			s.code.practice{kS}	= PathGetFilePre(cPathPractice{kS});

			if nSession>1
				s.path.session.fmri{kS}	= cPathSubject{kSort(2)};
				s.code.fmri{kS}	= PathGetFilePre(cPathFMRI{kS});

				if nSession > 2
                    error([num2str(nSession) ' sessions found for subject ' s.id{kS} '.']);
				end
			end
		end
	end

%is the subject data preprocessed? TODO: figure out how to test for this.

%read the fmri data (+ subject age)

	for kS=1:nSubject
		if ~isempty(s.path.session.fmri{kS})
			x	= load(s.path.session.fmri{kS});

			s.subject.age(kS)	= ConvertUnit(x.PTBIFO.experiment.start - x.PTBIFO.subject.dob,'ms','day')/365.25;
			%--EDIT LINE--%
		end
	end

% more data paths
s.path.functional.raw	= cellfun(@(s) GetPathFunctional(strDirData,s,'run','all'),s.code.fmri,'uni',false);
s.path.functional.pp	= cellfun(@(s,raw) conditional(numel(raw)>0,GetPathFunctional(strDirData,s,'type','pp','run',(1:numel(raw))'),{}),s.code.fmri,s.path.functional.raw,'uni',false);
s.path.functional.cat	= cellfun(@(s) GetPathFunctional(strDirData,s,'type','cat'),s.code.fmri,'uni',false);
s.path.diffusion.raw	= cellfun(@(s) GetPathDTI(strDirData,s),s.code.fmri,'uni',false);
s.path.structural.raw	= cellfun(@(s) GetPathStructural(strDirData,s),s.code.fmri,'uni',false);

end
