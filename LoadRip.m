function rip = LoadRip(ripPath)
% =========================================================================
%                          LoadRip
% =========================================================================
% DESCRIPTION:  Quick verification if SWR (ripples) were detected on the
%               current data.
%
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     
%    __________________________________________________________________
%
%       ripPath             Path where SWR.mat is or
%                           where processed files can be found
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       rip                 Ripples variables from SWR.mat             
%
% =========================================================================
% VERSIONS
%   2021-01 - Written by SL
%
% =========================================================================
% SEE CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
% =========================================================================

cd(ripPath)
try
    rip = load('SWR.mat');
catch
    disp('New ripples data not found!')
    disp('---------------------------')
    prompt = {'Scoring method (ob or accelero)', ...
              'Are there stimulations ? (yes=1; No=0)'};
    dlgtitle = 'Parameters for ripples detection';
    definput = {'ob','1'};
    dims = [1 40; 1 40];
    param = inputdlg(prompt,dlgtitle,dims,definput);
    scoring = param{1,1};
    switch param{2,1}
        case '1'
            stim=1;
        case '0'
            stim=0;
    end
    
    % launching detection
    disp('Thank you. Launching detection.')
    CreateRipplesSleep('scoring',scoring, 'recompute',1,'stim',stim);
    rip = load('SWR.mat');
end