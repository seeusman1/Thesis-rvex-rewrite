%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Computer Engineering Lab - Style file for Master thesis -Ver 1.00   %
%   Standard report class for CARDIR                                    %
%   Author: Wiebe Cnossen                                               %
%   Date:   April 3 1995                                                %
%   Documentation: ~wiebe/public/latex2e                                %   
%-----------------------------------------------------------------------%
%   Modified by BL Dang                                                 %
%   CE style file - Ver 1.10                                             %
%   Date: April 12 2003                                                 %
%   1.  Change the layout of the title page                             %    
%   2.  Change the layout of the front page - An abstract part          %    
%       (should be about 10-15 lines) and signatures part (a committee  %
%       can have up to 7 member)                                        %                                         
%   3.  Move the Chapters' Title higher                                 %
%   4.  Remove the Copyright footer                                     %
%   5.  Fix the page numbering error with Lists of Figures and Tables   %
%   6.  Using IEEE bib style     
%   7.  Two advisors supported.                                         %
%-----------------------------------------------------------------------%
%   CE style file - Ver 1.11                                            %
%   1.  New enviroment - \nonumchapter for Acknowledgements page        %
%   2.  Add the "Thankyou" environment                                  % 
%-----------------------------------------------------------------------%
%   Modified by Yunfei Wu                                               %
%   CE style file - Ver 1.20                                            %
%   Date: July 07  2003                                                 %
%   1.   Delete Laboratory in the thesis title pape                     %                      
%   2.   Change the layout of the front paper                           %
%          - Add "Committee Members" before the committee lists         %
%          - Delete the line for signiture                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ce}
              [1995/03/31 v2.0W
 Cardit LaTeX document class]   
%\typeout{Style file cardit.sty ; Produced 1995/03/22 by Wiebe Cnossen}
\newcommand{\@ptsize}{}
\newif\if@restonecol
\newif\if@titlepage
\@titlepagetrue
\newif\if@openright
\newif\if@openbib
\@openbibfalse
\DeclareOption{a4paper}
   {\setlength\paperheight {297mm}%
    \setlength\paperwidth  {210mm}}
\DeclareOption{a5paper}
   {\setlength\paperheight {210mm}%
    \setlength\paperwidth  {148mm}}
\DeclareOption{b5paper}
   {\setlength\paperheight {250mm}%
    \setlength\paperwidth  {176mm}}
\DeclareOption{letterpaper}
   {\setlength\paperheight {11in}%
    \setlength\paperwidth  {8.5in}}
\DeclareOption{legalpaper}
   {\setlength\paperheight {14in}%
    \setlength\paperwidth  {8.5in}}
\DeclareOption{executivepaper}
   {\setlength\paperheight {10.5in}%
    \setlength\paperwidth  {7.25in}}
\DeclareOption{landscape}
   {\setlength\@tempdima   {\paperheight}%
    \setlength\paperheight {\paperwidth}%
    \setlength\paperwidth  {\@tempdima}}
%% Hack by Wiebe coming up!
\newcommand{\scaling}{}
\DeclareOption{10pt}{\renewcommand{\@ptsize}{0}\renewcommand{\scaling}{1000}}
\DeclareOption{11pt}{\renewcommand{\@ptsize}{1}\renewcommand{\scaling}{1100}}
\DeclareOption{12pt}{\renewcommand{\@ptsize}{2}\renewcommand{\scaling}{1200}}
\DeclareOption{oneside}{\@twosidefalse \@mparswitchfalse}
\DeclareOption{twoside}{\@twosidetrue  \@mparswitchtrue}
\DeclareOption{draft}{\setlength\overfullrule{5pt}}
\DeclareOption{final}{\setlength\overfullrule{0pt}}
\DeclareOption{titlepage}{\@titlepagetrue}
\DeclareOption{notitlepage}{\@titlepagefalse}
\DeclareOption{openright}{\@openrighttrue}
\DeclareOption{openany}{\@openrightfalse}
\DeclareOption{onecolumn}{\@twocolumnfalse}
\DeclareOption{twocolumn}{\@twocolumntrue}
\DeclareOption{leqno}{\input{leqno.clo}}
\DeclareOption{fleqn}{\input{fleqn.clo}}
\DeclareOption{openbib}{\@openbibtrue}
\ExecuteOptions{a4paper,11pt,oneside,onecolumn,final,openany}
\ProcessOptions
\input{size1\@ptsize.clo}
\setlength\lineskip{1\p@}
\setlength\normallineskip{1\p@}
\renewcommand{\baselinestretch}{}
\setlength\parskip{0\p@ \@plus \p@}
\@lowpenalty   51
\@medpenalty  151
\@highpenalty 301
\setcounter{topnumber}{2}
\renewcommand{\topfraction}{.7}
\setcounter{bottomnumber}{1}
\renewcommand{\bottomfraction}{.3}
\setcounter{totalnumber}{3}
\renewcommand{\textfraction}{.2}
\renewcommand{\floatpagefraction}{.5}
\setcounter{dbltopnumber}{2}
\renewcommand{\dbltopfraction}{.7}
\renewcommand{\dblfloatpagefraction}{.5}
\long\def\comment#1{}
%---------------------------------------------------------------------%
%                     Define new variables                            %    
%---------------------------------------------------------------------%

%\def\signature#1#2{{\shortstack \parbox[t]{1in}{\smash{#1}\vskip11pt}\\
%\hfill \parbox[t]{1in}{\smash{#2}}}

\def\signature#1#2{\parbox[t]{1in}{\smash{#1}\vskip11pt} 
\hfill \parbox[t]{2.5in}{\shortstack{\small{#2}}}} 


%{\shortstack{\vrule width 3in height 0.4pt\\\small#2}}}

\def\firstadvisor#1{\gdef\@firstadvisor{#1}}
\def\secondadvisor#1{\gdef\@secondadvisor{#1}\second@advisortrue}
\def\chairperson#1{\gdef\@chairperson{#1}\chair@persontrue}
\def\firstmember#1{\gdef\@firstmember{#1}\first@membertrue}
\def\secondmember#1{\gdef\@secondmember{#1}\second@membertrue}
\def\thirdmember#1{\gdef\@thirdmember{#1}\third@membertrue}
\def\fourthmember#1{\gdef\@fourthmember{#1}\fourth@membertrue}


\def\@firstadvisor{}\def\@secondadvisor{}\def\@chairperson{}\def\@firstmember{}\def\@secondmember{}
\def\@thirdmember{}\def\@fourthmember{}

% New if constructs:    Default conditions:
\newif\ifchair@person     \chair@personfalse
\newif\ifsecond@advisor   \second@advisorfalse
\newif\iffirst@member   \first@memberfalse
\newif\ifsecond@member   \second@memberfalse
\newif\ifthird@member   \third@memberfalse
\newif\iffourth@member  \fourth@memberfalse
\newif\ifdedic@tion     \dedic@tionfalse

%---------------------------------------------------------------------%   
%    Macro for inserting Supervisor, Advisor and mentors' signature   %
%---------------------------------------------------------------------%

\def\signaturepage{%
%   \begin{flushright} 
   \begin{quotation}          
       \ifsecond@advisor
       
            \ifsecond@member
                \def\sigskip{\vskip0.1in plus 0.2in minus 0.1in}
                \def\beginskip{\vskip0.1in plus 0.2in minus 0.1in}
            \else
                \def\sigskip{\vskip0.1in plus 0.1in}
                \def\beginskip{\vskip0.1in plus 0.1in}
            \fi
            
            \beginskip   
                         
            \signature{\bf Advisor:}{\@firstadvisor} \\
            \sigskip \signature{\bf Advisor:}{\@secondadvisor} \\
        
        \ifchair@person
                \sigskip \signature{\bf Chairperson:}{\@chairperson} \\
        \fi
                
            \iffirst@member
                \sigskip \signature{\bf Member:}{\@firstmember} \\ 
            \fi

            \ifsecond@member
                \sigskip \signature{\bf Member:}{\@secondmember} \\
            \fi
        
            \ifthird@member
                \sigskip \signature{\bf Member:}{\@thirdmember} \\
             \fi

            \iffourth@member
                \sigskip \signature{\bf Member:}{\@fourthmember} \\
            \fi
    
       \else
            \ifthird@member
                \def\sigskip{\vskip0.1in plus 0.2in minus 0.1in}
                \def\beginskip{\vskip0.1in plus 0.2in minus 0.1in}
            \else
                \def\sigskip{\vskip0.1in plus 0.1in}
                \def\beginskip{\vskip0.1in plus 0.1in}
            \fi
                \beginskip                       
                
            \signature{\bf Advisor:}{\@firstadvisor} \\  
        \ifchair@person
                \sigskip \signature{\bf Chairperson:}{\@chairperson} \\
        \fi
        
            \iffirst@member
                \sigskip \signature{\bf Member:}{\@firstmember} \\
            \fi

            \ifsecond@member
                \sigskip \signature{\bf Member:}{\@secondmember} \\
            \fi
        
            \ifthird@member
                \sigskip \signature{\bf Member:}{\@thirdmember} \\
             \fi

            \iffourth@member
                \sigskip \signature{\bf Member:}{\@fourthmember} \\
            \fi
    
       \fi                    
    \end{quotation}
%       \end{flushright}
    %\vfill\newpage\setcounter{page}{3} 
    }
    
%-------------------------------------------------------------------%
%                       Thank you page                              %        
%-------------------------------------------------------------------%
\def\dedicate#1{\dedic@tiontrue\gdef\dedication@text{#1}}

\def\thankyou{
\ifdedic@tion
        \newpage\begin{center}\Large\em\null\vskip 2in
        \dedication@text
        \vfill\end{center}
\fi   
}
\newenvironment{dedication}{\newpage\begin{center}\Large\em\null\vskip1in}%
{\vfill\end{center}}
     
\if@twoside
  \def\ps@headings{%
      \let\@oddfoot\@empty\let\@evenfoot\@empty
      \def\@evenhead{\thepage\hfil\slshape\leftmark}%
      \def\@oddhead{{\slshape\rightmark}\hfil\thepage}%
      \let\@mkboth\markboth
    \def\chaptermark##1{%
      \markboth {\uppercase{%
        \ifnum \c@secnumdepth >\m@ne
            \@chapapp\ \thechapter. \ %
        \fi
        ##1}}{}}%
    \def\sectionmark##1{%
      \markright {\uppercase{%
        \ifnum \c@secnumdepth >\z@
          \thesection. \ %
        \fi
        ##1}}}}
\else
  \def\ps@headings{%
    \let\@oddfoot\@empty
    \def\@oddhead{{\slshape\rightmark}\hfil\thepage}%
    \let\@mkboth\markboth
    \def\chaptermark##1{%
      \markright {\uppercase{%
        \ifnum \c@secnumdepth >\m@ne
            \@chapapp\ \thechapter. \ %
        \fi
        ##1}}}}
\fi
\def\ps@myheadings{%
    \let\@oddfoot\@empty\let\@evenfoot\@empty
    \def\@evenhead{\thepage\hfil\slshape\leftmark}%
    \def\@oddhead{{\slshape\rightmark}\hfil\thepage}%
    \let\@mkboth\@gobbletwo
    \let\chaptermark\@gobble
    \let\sectionmark\@gobble
    }


\comment{              %Comment out this part
\if@titlepage
  \newcommand{\maketitle}{\begin{titlepage}%
  \let\footnotesize\small
  \let\footnoterule\relax
  \null\vfil
  \vskip 60\p@
  \begin{center}%
    {\LARGE \@title \par}%
    \vskip 3em%
    {\large
     \lineskip .75em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
      \vskip 1.5em%
    {\large \@date \par}%       % Set date in \large size.
  \end{center}\par
  \@thanks
  \vfil\null
  \end{titlepage}%
  \setcounter{footnote}{0}%
  \let\thanks\relax\let\maketitle\relax
  \gdef\@thanks{}\gdef\@author{}\gdef\@title{}}
\else
\newcommand{\maketitle}{\par
  \begingroup
    \renewcommand{\thefootnote}{\fnsymbol{footnote}}%
    \def\@makefnmark{\hbox to\z@{$\m@th^{\@thefnmark}$\hss}}%
    \long\def\@makefntext##1{\parindent 1em\noindent
            \hbox to1.8em{\hss$\m@th^{\@thefnmark}$}##1}%
    \if@twocolumn
      \ifnum \col@number=\@ne
        \@maketitle
      \else
        \twocolumn[\@maketitle]%
      \fi
    \else
      \newpage
      \global\@topnum\z@   % Prevents figures from going at top of page.
      \@maketitle
    \fi
    \thispagestyle{plain}\@thanks
  \endgroup
  \setcounter{footnote}{0}%
  \let\thanks\relax
  \let\maketitle\relax\let\@maketitle\relax
  \gdef\@thanks{}\gdef\@author{}\gdef\@title{}}
\def\@maketitle{%
  \newpage
  \null
  \vskip 2em%
  \begin{center}%
    {\large \@title \par}%
    \vskip 1.5em%
    {\large
      \lineskip .5em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
    \vskip 1em%
    {\large \@date}%
  \end{center}%
  \par
  \vskip 1.5em}
\fi  
}           %End of comment
%-----------------------------------------------------------------  

%-----------------------------------------------------------------
\newcommand*{\chaptermark}[1]{}
\setcounter{secnumdepth}{2}
\newcounter {part}
\newcounter {chapter}
\newcounter {section}[chapter]
\newcounter {subsection}[section]
\newcounter {subsubsection}[subsection]
\newcounter {paragraph}[subsubsection]
\newcounter {subparagraph}[paragraph]
\renewcommand{\thepart}         {\Roman{part}}
\renewcommand{\thechapter}      {\arabic{chapter}}
\renewcommand{\thesection}      {\thechapter.\arabic{section}}
\renewcommand{\thesubsection}   {\thesection.\arabic{subsection}}
\renewcommand{\thesubsubsection}{\thesubsection .\arabic{subsubsection}}
\renewcommand{\theparagraph}    {\thesubsubsection.\arabic{paragraph}}
\renewcommand{\thesubparagraph} {\theparagraph.\arabic{subparagraph}}

%----------------------------------------------------------------------------%
%                               Chapters' Entry                              %
%----------------------------------------------------------------------------%
\newcommand{\@chapapp}{\chaptername}
\newcommand{\part}{\cleardoublepage
                 \thispagestyle{plain}%
                 \if@twocolumn
                     \onecolumn
                     \@tempswatrue
                   \else
                     \@tempswafalse
                 \fi
                 \hbox{}\vfil
                 \secdef\@part\@spart}

\def\@part[#1]#2{%
    \ifnum \c@secnumdepth >-2\relax
      \refstepcounter{part}%
      \addcontentsline{toc}{part}{\thepart\hspace{1em}#1}%
    \else
      \addcontentsline{toc}{part}{#1}%
    \fi
    \markboth{}{}
    {\centering
     \interlinepenalty \@M
     \reset@font
     \ifnum \c@secnumdepth >-2\relax
       \huge\bfseries \partname~\thepart
       \par
       \vskip 10\p@  %20 -10
     \fi
     \Huge \bfseries #2\par}%
    \@endpart}
\def\@spart#1{%
    {\centering
     \interlinepenalty \@M
     \reset@font
     \Huge \bfseries #1\par}%
    \@endpart}
\def\@endpart{\vfil\newpage
              \if@twoside
                \hbox{}%
                \thispagestyle{empty}%
                \newpage
              \fi
              \if@tempswa
                \twocolumn
              \fi}
              
\newcommand{\chapter}{\if@twoside\cleardoublepage\else\clearpage\fi
                    \thispagestyle{plain}%
                    \global\@topnum\z@
                    \@afterindentfalse
                    \secdef\@chapter\@schapter}
%-------------------------------------------------------------------------%
%                       Chapter's style                                   %
%-------------------------------------------------------------------------%

\def\@chapter[#1]#2{     
                         \ifnum \c@secnumdepth >\m@ne
                         \refstepcounter{chapter}%
                         \typeout{\@chapapp\space\thechapter.}%
                         \addcontentsline{toc}{chapter}%
                                   {\protect\numberline{\thechapter}#1}%
                    \else
                      \addcontentsline{toc}{chapter}{#1}%
                    \fi
                    \chaptermark{#1}%
                    \addtocontents{lof}{\protect\addvspace{10\p@}}%
                    \addtocontents{lot}{\protect\addvspace{10\p@}}%
                    \if@twocolumn
                      \@topnewpage[\@makechapterhead{#2}]%
                    \else
                      \topmargin -0.2in          %Change the whole document
                      \@makechapterhead{#2}%
                      \@afterheading
                    \fi}

%------------------------------------------------------------------------%
\def\nonumchapter#1{%
    \chapter*{#1}
    \addcontentsline{toc}{chapter}{#1}}

%------------------------------------------------------------------------%

%\def\@makechapterhead#1{%
%  \vspace*{50\p@}%
%  {\parindent \z@ \raggedright \reset@font
%    \ifnum \c@secnumdepth >\m@ne
%        \huge\bfseries \@chapapp{} \thechapter
%        \par\nobreak
%        \vskip 20\p@
%    \fi
%    \interlinepenalty\@M
%    \Huge \bfseries #1\par\nobreak
%    \vskip 40\p@
%  }}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Begin of Wiebe's stuff %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newfont{\cmbxfont}{cmbx10}                 %change from cmbx100 - cmbx10
\font\cmbxfont = cmbx10 scaled 10000
\newcommand{\chapnumfont}{\cmbxfont}

\newlength{\chapterskip}
\setlength{\chapterskip}{1.5cm}             %Change from 4cm -1.5cm: Spacing from the title to the paragraph
\newlength{\orgchapterskip}
\setlength{\orgchapterskip}{\chapterskip}

%---------------------------------------------------------%
%            Chapter's head - big chapter number          %
%---------------------------------------------------------%

\def\@makechapterhead#1{ 
        %\topmargin -0.5in
        \vspace*{-1.5cm} %{3cm}     %Move the chapter's head upward
        {
        \parindent 0pt
        \begin{minipage}[b]{11cm}\raggedright  
        \Huge #1
        \end{minipage}
        \hfill
        {\chapnumfont \thechapter}
        \\
        \rule{\textwidth}{1.5pt} \par \nobreak
        \vskip \chapterskip
        }}

\newlength{\schapterheadskip}
\setlength{\schapterheadskip}{0cm} %{4.7cm}

\def\@makeschapterhead#1{ 
        %\topmargin -0.5in    
        \vspace*{-1.5cm} %{\schapterheadskip}   %Move the chapter's head upward
        {
        \parindent 0pt
        \begin{minipage}[b]{11cm}\raggedright  
        \Huge #1
        \end{minipage}
        \\
        \rule{\textwidth}{1.5pt} \par \nobreak
        \vskip \chapterskip
        }}
%---------------------------------------------------------%

\def\abstracthead#1{\gdef\@abstracthead{#1}}
 
\gdef\@abstracthead{0cm}

\def\@makeabstracthead#1{
    {\parindent 0pt
    \begin{center}
    {\huge \@title \par} \vskip 1em
    {\LARGE \@subtitle \par}
    \end{center}
    \vspace*{3cm}
    \vspace*{-\@abstracthead}
    {
    \parindent 0pt
    \begin{minipage}[b]{11cm}\raggedright
    \Huge #1
    \end{minipage}
    \\
    \rule{\textwidth}{1.5pt} \par \nobreak
    \vskip \chapterskip}}}
 
\def\subtitle#1{\gdef\@subtitle{#1}}

\gdef\@subtitle{\nul}

\def\extitle#1{\gdef\@extitle{#1}}

\gdef\@extitle{\nul}

\def\nul{\rule{0cm}{0cm}}

%-------------------------------------------------------------------%
%                         TITLE PAGE                                %
%-------------------------------------------------------------------%
\def\@REPTYPE{MASTER OF SCIENCE}
\def\@MAJOR{COMPUTER ENGINEERING}
\def\@CITY{}
\def\@COUNTRY{}

\def\maketitle{\begin{titlepage}

\topmargin -0.5in
\hoffset 0.5in   \footskip 0pt
\addtolength{\textheight}{2cm} 

\let\footnotesize\small \let\footnoterule\relax \setcounter{page}{0}
\null

\begin{center}
{\huge \@title \par}
{\LARGE \@subtitle \par} 
\rule{\textwidth}{1.5pt} \par \nobreak
%$\:\underline{~~~~ \mbox{\rule{0in}{0.16in} \hspace{5in}}}\:$ \\
\vskip 3em
{\large THESIS}
\vskip 2.8em
{\large submitted in partial fulfillment of the \\
requirements for the degree of }
\vskip 2.4em
{\large \@REPTYPE}
\vskip 1.3em
in
\vskip 1.4em
{\large \@MAJOR}
\vskip 1.3em
by

\vskip 2em {\large \lineskip .75em
\begin{tabular}[t]{c}
\@author \\
born in \@CITY{\city}, \@COUNTRY{\country}
\end{tabular}\par

\vskip 4.5cm
%\begin{flushleft}
%\underline {\small This work was performed in:}
%\end{flushleft}

\begin{minipage}[t]{15cm} \begin{center} 
\raggedright \large \@date
\end{center} \end{minipage}} \end{center} \vfill
\@thanks
\null
\end{titlepage}
\setcounter{footnote}{0} \let\thanks\relax
%\gdef\@thanks{}\gdef\@author{}\gdef\@title{}
\let\maketitle\relax}

%-------------------------------------------------------------------%

%\def\abstract{\titlepage
%\null\vfil
%\begin{center}
%{\bf Abstract}
%\end{center}}
%\def\endabstract{\par\vfil\null\endtitlepage}

\mark{{}{}} 

\def\abstractskip#1{\addtolength{\chapterskip}{-#1}}

\def\abstract{\if@twoside\cleardoublepage\else\clearpage\fi
    \thispagestyle{plain} \global\@topnum\z@
    \@afterindentfalse \secdef\@abstract\@noabstract}

\def\@abstract[#1]#2{\addcontentsline{toc}{chapter}{ABSTRACT}
\@makeabstracthead{Abstract}\@afterheading
\setlength{\chapterskip}{\orgchapterskip}}

\def\@noabstract#1{
\addtolength{\schapterheadskip}{-\@abstracthead}
\@makeschapterhead{#1}\@afterheading
\addtolength{\schapterheadskip}{\@abstracthead}
\setlength{\chapterskip}{\orgchapterskip}}

\font\math= cmbsy10 scaled \scaling
\font\sym = msam10 scaled \scaling

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End of Wiebe's stuff %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

\def\@schapter#1{\if@twocolumn
                   \@topnewpage[\@makeschapterhead{#1}]%
                 \else
                   \@makeschapterhead{#1}%
                   \@afterheading
                 \fi}
%\def\@makeschapterhead#1{%
%  \vspace*{50\p@}%
%  {\parindent \z@ \raggedright
%    \reset@font
%    \interlinepenalty\@M
%    \Huge \bfseries  #1\par\nobreak
%    \vskip 40\p@
%  }}
\newcommand{\section}{\@startsection {section}{1}{\z@}%
                                   {-3.5ex \@plus -1ex \@minus -.2ex}%
                                   {2.3ex \@plus.2ex}%
                                   {\reset@font\Large\bfseries}}
\newcommand{\subsection}{\@startsection{subsection}{2}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\reset@font\large\bfseries}}
\newcommand{\subsubsection}{\@startsection{subsubsection}{3}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\reset@font\normalsize\bfseries}}
\newcommand{\paragraph}{\@startsection{paragraph}{4}{\z@}%
                                    {3.25ex \@plus1ex \@minus.2ex}%
                                    {-1em}%
                                    {\reset@font\normalsize\bfseries}}
\newcommand{\subparagraph}{\@startsection{subparagraph}{5}{\parindent}%
                                       {3.25ex \@plus1ex \@minus .2ex}%
                                       {-1em}%
                                      {\reset@font\normalsize\bfseries}}
\if@twocolumn
  \setlength\leftmargini  {2em}
\else
  \setlength\leftmargini  {2.5em}
\fi
\setlength\leftmarginii  {2.2em}
\setlength\leftmarginiii {1.87em}
\setlength\leftmarginiv  {1.7em}
\if@twocolumn
  \setlength\leftmarginv  {.5em}
  \setlength\leftmarginvi {.5em}
\else
  \setlength\leftmarginv  {1em}
  \setlength\leftmarginvi {1em}
\fi
\setlength\leftmargin    {\leftmargini}
\setlength  \labelsep  {.5em}
\setlength  \labelwidth{\leftmargini}
\addtolength\labelwidth{-\labelsep}
\@beginparpenalty -\@lowpenalty
\@endparpenalty   -\@lowpenalty
\@itempenalty     -\@lowpenalty
\renewcommand{\theenumi}{\arabic{enumi}}
\renewcommand{\theenumii}{\alph{enumii}}
\renewcommand{\theenumiii}{\roman{enumiii}}
\renewcommand{\theenumiv}{\Alph{enumiv}}
\newcommand{\labelenumi}{\theenumi.}
\newcommand{\labelenumii}{(\theenumii)}
\newcommand{\labelenumiii}{\theenumiii.}
\newcommand{\labelenumiv}{\theenumiv.}
\renewcommand{\p@enumii}{\theenumi}
\renewcommand{\p@enumiii}{\theenumi(\theenumii)}
\renewcommand{\p@enumiv}{\p@enumiii\theenumiii}
\newcommand{\labelitemi}{$\m@th\bullet$}
\newcommand{\labelitemii}{\normalfont\bfseries --}
\newcommand{\labelitemiii}{$\m@th\ast$}
\newcommand{\labelitemiv}{$\m@th\cdot$}
\newenvironment{description}
               {\list{}{\labelwidth\z@ \itemindent-\leftmargin
                        \let\makelabel\descriptionlabel}}
               {\endlist}
\newcommand{\descriptionlabel}[1]{\hspace\labelsep
                                \normalfont\bfseries #1}
\if@titlepage
%  \newenvironment{abstract}{%
%      \titlepage
%      \null\vfil
%      \begin{center}
%        \bfseries \abstractname
%      \end{center}}
%     {\par\vfil\null\endtitlepage}
\else
  \newenvironment{abstract}{%
%      \if@twocolumn
%        \section*{\abstractname}%
%      \else
%        \small
%        \begin{center}%
%          {\bfseries \abstractname\vspace{-.5em}\vspace{\z@}}%
%        \end{center}%
%        \quotation
%      \fi}
      {\if@twocolumn\else\endquotation\fi}
\fi
\newenvironment{verse}
               {\let\\=\@centercr
                \list{}{\itemsep      \z@
                        \itemindent   -1.5em%
                        \listparindent\itemindent
                        \rightmargin  \leftmargin
                        \advance\leftmargin 1.5em}%
                \item[]}
               {\endlist}
\newenvironment{quotation}
               {\list{}{\listparindent 1.5em%
                        \itemindent    \listparindent
                        \rightmargin   \leftmargin
                        \parsep        \z@ \@plus\p@}%
                \item[]}
               {\endlist}
\newenvironment{quote}
               {\list{}{\rightmargin\leftmargin}%
                \item[]}
               {\endlist}
\newenvironment{titlepage}
    {%
      \if@twocolumn
        \@restonecoltrue\onecolumn
      \else
        \@restonecolfalse\newpage
      \fi
      \thispagestyle{empty}%
      \if@compatibility
        \setcounter{page}{0}
      \else
        \setcounter{page}{1}%
      \fi}%
    {\if@restonecol\twocolumn \else \newpage \fi
      \setcounter{page}{1}%
    }
\newcommand{\appendix}{\par
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \renewcommand{\@chapapp}{\appendixname}%
  \renewcommand{\thechapter}{\Alph{chapter}}}
\setlength\arraycolsep{5\p@}
\setlength\tabcolsep{6\p@}
\setlength\arrayrulewidth{.4\p@}
\setlength\doublerulesep{2\p@}
\setlength\tabbingsep{\labelsep}
\skip\@mpfootins = \skip\footins
\setlength\fboxsep{3\p@}
\setlength\fboxrule{.4\p@}
\@addtoreset{equation}{chapter}
\renewcommand{\theequation}{\thechapter.\arabic{equation}}
\newcounter{figure}[chapter]
\renewcommand{\thefigure}{\thechapter.\@arabic\c@figure}
\def\fps@figure{tbp}
\def\ftype@figure{1}
\def\ext@figure{lof}
\def\fnum@figure{\figurename~\thefigure}
\newenvironment{figure}
               {\@float{figure}}
               {\end@float}
\newenvironment{figure*}
               {\@dblfloat{figure}}
               {\end@dblfloat}
\newcounter{table}[chapter]
\renewcommand{\thetable}{\thechapter.\@arabic\c@table}
\def\fps@table{tbp}
\def\ftype@table{2}
\def\ext@table{lot}
\def\fnum@table{\tablename~\thetable}
\newenvironment{table}
               {\@float{table}}
               {\end@float}
\newenvironment{table*}
               {\@dblfloat{table}}
               {\end@dblfloat}
\newlength\abovecaptionskip
\newlength\belowcaptionskip
\setlength\abovecaptionskip{10\p@}
\setlength\belowcaptionskip{0\p@}
\long\def\@makecaption#1#2{%
  \vskip\abovecaptionskip
  \sbox\@tempboxa{#1: #2}%
  \ifdim \wd\@tempboxa >\hsize
    #1: #2\par
  \else
    \global \@minipagefalse
    \hbox to\hsize{\hfil\box\@tempboxa\hfil}%
  \fi
  \vskip\belowcaptionskip}
\DeclareOldFontCommand{\rm}{\normalfont\rmfamily}{\mathrm}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\DeclareOldFontCommand{\tt}{\normalfont\ttfamily}{\mathtt}
\DeclareOldFontCommand{\bf}{\normalfont\bfseries}{\mathbf}
\DeclareOldFontCommand{\it}{\normalfont\itshape}{\mathit}
\DeclareOldFontCommand{\sl}{\normalfont\slshape}{\@nomath\sl}
\DeclareOldFontCommand{\sc}{\normalfont\scshape}{\@nomath\sc}
\DeclareRobustCommand*{\cal}{\@fontswitch{\relax}{\mathcal}}
\DeclareRobustCommand*{\mit}{\@fontswitch{\relax}{\mathnormal}}
\newcommand{\@pnumwidth}{1.55em}
\newcommand{\@tocrmarg} {2.55em}
\newcommand{\@dotsep}{4.5}
\setcounter{tocdepth}{2}

\newcommand{\tableofcontents}{%
    \if@twocolumn
      \@restonecoltrue\onecolumn
    \else
      \@restonecolfalse
    \fi
    \chapter*{\contentsname
        \@mkboth{\uppercase{\contentsname}}{\uppercase{\contentsname}}}%
    \@starttoc{toc}%
    \if@restonecol\twocolumn\fi
    }

\newcommand*{\l@part}[2]{%
  \ifnum \c@tocdepth >-2\relax
    \addpenalty{-\@highpenalty}%
    \addvspace{2.25em \@plus\p@}%
    \begingroup
      \setlength\@tempdima{3em}%
      \parindent \z@ \rightskip \@pnumwidth
      \parfillskip -\@pnumwidth
      {\leavevmode
       \large \bfseries #1\hfil \hbox to\@pnumwidth{\hss #2}}\par
       \nobreak
         \global\@nobreaktrue
         \everypar{\global\@nobreakfalse\everypar{}}
    \endgroup
  \fi}
\newcommand*{\l@chapter}[2]{%
  \ifnum \c@tocdepth >\m@ne
    \addpenalty{-\@highpenalty}%
    \vskip 1.0em \@plus\p@
    \setlength\@tempdima{1.5em}%
    \begingroup
      \parindent \z@ \rightskip \@pnumwidth
      \parfillskip -\@pnumwidth
      \leavevmode \bfseries
      \advance\leftskip\@tempdima
      \hskip -\leftskip
      #1\nobreak\hfil \nobreak\hbox to\@pnumwidth{\hss #2}\par
      \penalty\@highpenalty
    \endgroup
  \fi}
\newcommand*{\l@section}      {\@dottedtocline{1}{1.5em}{2.3em}}
\newcommand*{\l@subsection}   {\@dottedtocline{2}{3.8em}{3.2em}}
\newcommand*{\l@subsubsection}{\@dottedtocline{3}{7.0em}{4.1em}}
\newcommand*{\l@paragraph}    {\@dottedtocline{4}{10em}{5em}}
\newcommand*{\l@subparagraph} {\@dottedtocline{5}{12em}{6em}}

\newcommand{\listoffigures}{%
    \if@twocolumn
      \@restonecoltrue\onecolumn
    \else
      \@restonecolfalse
    \fi
    \chapter*{\listfigurename
      \@mkboth{\uppercase{\listfigurename}}%
              {\uppercase{\listfigurename}}}%
    \@starttoc{lof}%
    \if@restonecol\twocolumn\fi
    }
\newcommand*{\l@figure}{\@dottedtocline{1}{1.5em}{3.0em}}

\newcommand{\listoftables}{%
    \if@twocolumn
      \@restonecoltrue\onecolumn
    \else
      \@restonecolfalse
    \fi
    \chapter*{\listtablename
      \@mkboth{\uppercase{\listtablename}}{\uppercase{\listtablename}}}%
    \@starttoc{lot}%
    \if@restonecol\twocolumn\fi
    }
\let\l@table\l@figure
\newdimen\bibindent
\bibindent=1.5em
\newenvironment{thebibliography}[1]
     {\chapter*{\bibname
        \@mkboth{\uppercase{\bibname}}{\uppercase{\bibname}}}%
      \list{\@biblabel{\arabic{enumiv}}}%
           {\settowidth\labelwidth{\@biblabel{#1}}%
            \leftmargin\labelwidth
            \advance\leftmargin\labelsep
            \if@openbib
              \advance\leftmargin\bibindent
              \itemindent -\bibindent
              \listparindent \itemindent
              \parsep \z@
            \fi
            \usecounter{enumiv}%
            \let\p@enumiv\@empty
            \renewcommand{\theenumiv}{\arabic{enumiv}}}%
      \if@openbib
        \renewcommand{\newblock}{\par}
      \else
        \renewcommand{\newblock}{\hskip .11em \@plus.33em \@minus.07em}%
      \fi
      \sloppy\clubpenalty4000\widowpenalty4000%
      \sfcode`\.=\@m}
     {\def\@noitemerr
       {\@latex@warning{Empty `thebibliography' environment}}%
      \endlist}
\newcommand{\newblock}{}
\newenvironment{theindex}
               {\if@twocolumn
                  \@restonecolfalse
                \else
                  \@restonecoltrue
                \fi
                \columnseprule \z@
                \columnsep 35\p@
                \twocolumn[\@makeschapterhead{\indexname}]%
                \@mkboth{\uppercase{\indexname}}%
                        {\uppercase{\indexname}}%
                \thispagestyle{plain}\parindent\z@
                \parskip\z@ \@plus .3\p@\relax
                \let\item\@idxitem}
               {\if@restonecol\onecolumn\else\clearpage\fi}
\newcommand{\@idxitem}  {\par\hangindent 40\p@}
\newcommand{\subitem}   {\par\hangindent 40\p@ \hspace*{20\p@}}
\newcommand{\subsubitem}{\par\hangindent 40\p@ \hspace*{30\p@}}
\newcommand{\indexspace}{\par \vskip 10\p@ \@plus5\p@ \@minus3\p@\relax}
\renewcommand{\footnoterule}{%
  \kern-3\p@
  \hrule width .4\columnwidth
  \kern 2.6\p@}
\@addtoreset{footnote}{chapter}
\long\def\@makefntext#1{%
    \parindent 1em%
    \noindent
    \hbox to 1.8em{\hss\@makefnmark}#1}
\newcommand{\contentsname}{Contents}
\newcommand{\listfigurename}{List of Figures}
\newcommand{\listtablename}{List of Tables}
\newcommand{\bibname}{Bibliography}
\newcommand{\indexname}{Index}
\newcommand{\figurename}{Figure}
\newcommand{\tablename}{Table}
\newcommand{\partname}{Part}
\newcommand{\chaptername}{Chapter}
\newcommand{\appendixname}{Appendix}
\newcommand{\abstractname}{Abstract}
\newcommand{\today}{\ifcase\month\or
  January\or February\or March\or April\or May\or June\or
  July\or August\or September\or October\or November\or December\fi
  \space\number\day, \number\year}
\setlength\columnsep{10\p@}
\setlength\columnseprule{0\p@}
\pagestyle{plain}
\pagenumbering{arabic}      % Arabic page numbers
\if@twoside
\else
  \raggedbottom
\fi
\if@twocolumn
  \twocolumn
  \sloppy
  \flushbottom
\else
  \onecolumn
\fi
%\endinput
%% 
%% End of file `report.cls'.

% first fix a LaTeX bug
%
\makeatletter
\def\footnotemark{\@ifnextchar[{\@xfootnotemark
   }{\stepcounter{\@mpfn}\xdef\@thefnmark{\thempfn}\@footnotemark}}

\def\@xfootnotemark[#1]{\begingroup \csname c@\@mpfn\endcsname #1\relax
   \xdef\@thefnmark{\thempfn}\@footnotemark\endgroup}

\newtheorem{corollary}{Corollary}[chapter]
\newtheorem{definition}{Definition}[chapter]
\newtheorem{lemma}{Lemma}[chapter]
\newtheorem{remark}{Remark}[chapter]
\newtheorem{property}{Property}[chapter]
\newtheorem{theorem}{Theorem}[chapter]
\newtheorem{example}{Example}[chapter]

\newcommand{\ra}{$\rightarrow$}
\newcommand{\ti}{$\sim$}
\newcommand{\bs}{$\backslash$}
\newcommand{\aco}{$\{$}
\newcommand{\acs}{$\}$}

%super and subscripts in normal text 
\newcommand{\sups}[1]{$^{\mbox{\scriptsize #1}}$}  % sup is already used
\newcommand{\sub}[1]{$_{\mbox{\scriptsize #1}}$}   %  as math-function

%regularly used mathematical standard functions
\newcommand{\card}{\mbox{\rm card}}

% list commands
\newcommand{\be}{\begin{enumerate}}
\newcommand{\ee}{\end{enumerate}}
\newcommand{\bi}{\begin{itemize}}
\newcommand{\ei}{\end{itemize}}
\newcommand{\bd}{\begin{description}}
\newcommand{\ed}{\end{description}}

% tables
\newcommand{\btab}{\begin{table}}
\newcommand{\etab}{\end{table}}
\newcommand{\bt}{\begin{tabular}}
\newcommand{\et}{\end{tabular}}
 
% tabbing
\newcommand{\btb}{\begin{tabbing}}
\newcommand{\etb}{\end{tabbing}}

% center
\newcommand{\bc}{\begin{center}}
\newcommand{\ec}{\end{center}}
\newcommand{\ct}[1]{\begin{center} #1 \end{center}}
 
%verse
\newcommand{\bv}{\begin{verse}}
\newcommand{\ev}{\end{verse}}

% footnotes
\newcommand{\fm}[1]{\footnotemark[#1]}
 
% equations and definitions
\newcommand{\ba}{\begin{eqnarray*}}
\newcommand{\ea}{\end{eqnarray*}}
\newcommand{\beq}{\begin{equation}}
\newcommand{\eeq}{\end{equation}}
\newcommand{\bdf}{\begin{definition}}
\newcommand{\edf}{\end{definition}}

% sections
\newcommand{\sn}[1]{\section{#1}}
\newcommand{\ssn}[1]{\subsection{#1}}
\newcommand{\sssn}[1]{\subsubsection{#1}}
\newcommand{\ssssn}[1]{\paragraph{#1}}

% figures
\newcommand{\bfig}{\begin{figure}}
\newcommand{\Bfig}{\begin{figure*}}
\newcommand{\efig}{\end{figure}}
\newcommand{\Efig}{\end{figure*}}

 
%postscript figures
\newcommand{\newfig}[1]{
\centerline{\psfig{file=#1}}
}
\newcommand{\newfigh}[2]{
\centerline{\psfig{file=#1,width=#2}}
}
\newcommand{\newfigv}[2]{
\centerline{\psfig{file=#1,height=#2}}
}

% kantlijn opmerkingen:
\setlength{\marginparsep}{.1cm}
\setlength{\marginparwidth}{1.75cm}
\newcommand{\myremark}[1] {\marginpar{\em \tiny #1} }

\parsep 0pt
\setlength{\textheight}{8.5in}
\setlength{\textwidth}{5.8in}
\setlength{\oddsidemargin}{0.55in}
\setlength{\evensidemargin}{-0.1in}
\setlength{\topmargin}{+0.25cm}
\setlength{\columnsep}{0.5cm}
\setlength{\itemsep}{0cm}   %separation between items = parsep+itemsep

%numbering of subsubsections, but not in contents
\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{2}
% maximum number of floats:
\setcounter{topnumber}{2}
%\setcounter{bottomnumber}{2}
%\setcounter{totalnumber}{2}

\renewcommand{\topfraction}{.99}
\renewcommand{\bottomfraction}{.99}
\renewcommand{\textfraction}{.02}
\renewcommand{\floatpagefraction}{0.9}

\makeatletter
\def\footnotemark{\@ifnextchar[{\@xfootnotemark
   }{\stepcounter{\@mpfn}\xdef\@thefnmark{\thempfn}\@footnotemark}}

\def\@xfootnotemark[#1]{\begingroup \csname c@\@mpfn\endcsname #1\relax
   \xdef\@thefnmark{\thempfn}\@footnotemark\endgroup}

%\def\@docopyright

\gdef\@docopyright{\copyright \the\year\ \INSTITUTE}

\def\docopyright{\gdef\@docopyright{\copyright \the\year\ \INSTITUTE}}

\def\dontcopyright{\gdef\@docopyright{\nul}}

\def\setcopyright#1{\gdef\@docopyright{\copyright \the\year\ #1}}

% add private pagestyle
\def\ps@private{
   \makeatletter
     \setlength{\headheight}{20pt}
%    \setlength{\headsep}{35pt}

%-----------------------------------------------------------------------%
%       Header stuff                                                    %     
%-----------------------------------------------------------------------%
   \def\@oddhead{\parbox{\textwidth}
      {{\sl \rightmark} \hfill \thepage \newline
       % \vskip 0.02cm
               \rule[\baselineskip]{\textwidth}{0.5pt}
      }}
   \def\@evenhead{\parbox{\textwidth}
      {
      \thepage \hfill {\sl \leftmark} \newline
      %\vskip 0.02cm
               \rule[\baselineskip]{\textwidth}{0.5pt}
      }}
%-----------------------------------------------------------------------%
%       Comment out the footer (copyright)                              %     
%-----------------------------------------------------------------------%
    \def\@oddfoot{\hfill \footnotesize build \input{version.txt}}
    \def\@evenfoot{\hfill \footnotesize build \input{version.txt}}
%   \def\@oddfoot{\hfill \footnotesize \@docopyright}
%   \def\@evenfoot{\footnotesize \@docopyright \hfill}
%   \def\@oddfoot{\hfill \footnotesize \copyright \the\year\ \INSTITUTE}
%   \def\@evenfoot{\footnotesize \copyright \the\year\ \INSTITUTE \hfill}
}
\makeatother

% add DUT data

\newcommand{\ADDR}{P.O. Box 5031, NL-2600 GA Delft,\\ The Netherlands}
\newcommand{\DEP}{Department of Electrical Engineering}
\newcommand{\INSTITUTE}{Delft University of Technology}
\newcommand{\LAB}{Computer Engineering}
\newcommand{\FAC}{Faculty of Electrical Engineering, Mathematics and Computer Science}
\newcommand{\PLACE}{Delft, The Netherlands}
\newcommand{\LABADD}{Mekelweg 4,\\2628 CD Delft\\ The Netherlands}
\newcommand{\WEB}{http://ce.et.tudelft.nl/}
\newcommand{\SUP}{Prof.\ Dr.\ Ir.\ A.~J.\ van de Goor}


%  Macro for dropping and enlarging the first letter(s) of a paragraph.
%  Macro written by David G. Cantor
%  Modified for use with LaTeX by Dominik Wujastyk, February 17, 1988
%  Modified for use on DUT by Wiebe Cnossen, August 10, 1994

%  Font definition
\font\largefont= cmr17 scaled \magstep4               %
%  Actual drop macro
\def\drop#1#2{{\noindent
    \setbox0\hbox{\largefont #1}\setbox1\hbox{0}\setbox2\hbox{(}%
    \count0=\ht0\advance\count0 by\dp0\count1\baselineskip
    \advance\count0 by-\ht1\advance\count0by\ht2
    \dimen1=.5ex\advance\count0by\dimen1\divide\count0 by\count1
    \advance\count0 by1\dimen0\wd0
    \advance\dimen0 by.25em\dimen1=\ht0\advance\dimen1 by-\ht1
    \global\hangindent\dimen0\global\hangafter-\count0
    \hskip-\dimen0\setbox0\hbox to\dimen0{\raise-\dimen1\box0\hss}%
    \dp0=0in\ht0=0in\box0}\hspace{-0.2em}{\bf #2}}

%Macro for approval item
\def\appro#1{
\vspace*{5mm}

\noindent
\rule{9cm}{0.5mm}
\hspace*{1cm}
\rule{3cm}{0.5mm}
\\#1\\
}

%\newlength{\tmpsize}
%\setlength{\tmpsize}{\evensidemargin}
%\def\quasioneside{
%   \setlength{\oddsidemargin}{\evensidemargin}
%}
%\def\quasitwoside{
%   \setlength{\oddsidemargin}{\tmpsize}
%}

\def\quasioneside{
    \setlength{\evensidemargin}{0.225in}
    \setlength{\oddsidemargin}{0.225in}
}

\def\quasitwoside{
    \setlength{\evensidemargin}{-0.1in}
    \setlength{\oddsidemargin}{0.55in}
}

\def\draft{\special{!userdict begin /bop-hook{gsave 150 100 translate 52.3
    rotate /Times-Roman findfont 216 scalefont setfont 0 0 moveto
    0.990 setgray (DRAFT) show grestore}def end}}

\font\bibfont= cmr12

\def\ruler#1{\rule{\textwidth}{#1}}

\def\clearsinglepage{\clearpage}

\sloppy

%\def\lefthyphenmin{1}
%\def\righthyphenmin{1}
