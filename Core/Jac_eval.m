function Jac = Jac_eval(t,conc,param)
% function Jac = Jac_eval(t,conc,param)
% HERE BE DRAGONS
% Calculates the Jacobian of the chemical ODEs used in the dydt_eval function.
% For info on inputs, see dydt_eval.m.
% OUTPUT is the Jacobian matrix dF/dy, which has dimensions of nSp x nSp.
%   Rows correspond to each set of equations for a species.
%   Columns correspond to each species.
% For more info on how it is used, see the odeset help.
%
% 20120723 GMW
% 20180320 GMW Added Gaussian dispersion option.

%%%%%BREAKOUT PARAMETERS%%%%%
k           = param{1};
f           = param{2};
iG          = param{3};
iRO2        = param{4};
iHold       = param{5};
kdil        = param{6};
tgauss      = param{7};
conc_bkgd   = param{8};
IntTime     = param{9};
Verbose     = param{10};
Family        = param{11};

[nRx,nSp] = size(f);

conc = conc'; %ODE solver feeds this in as 1 row for each species

%%%%%CALCULATE JACOBIAN MATRIX%%%%%

conc(:,2) = sum(conc(:,iRO2),2); %sum RO2

% partial derivatives for 1st-order reactions
% f = k*x*y, then df/dx = k*y
DratesDy1 = k.*conc(:,iG(:,2));
DratesDy2 = k.*conc(:,iG(:,1));

% distribute derivatives
% one row for each reaction
% one column for each species
Rxindex = [1:nRx 1:nRx]; 
Spindex = [iG(:,1)' iG(:,2)'];
DratesDy = sparse(Rxindex,Spindex,[DratesDy1 DratesDy2],nRx,nSp);

% correct second-order reactions
% f = k*x*x, then df/dx = 2*k*x
i2 = find(iG(:,1)==iG(:,2));
DratesDy(i2,iG(i2,1)) = 2*DratesDy(i2,iG(i2,1));

% calculate Jacobian
% f is matrix of stoichiometric coefficients for each species & reaction, dim = nRx x nSp
% matrix multiplication sums up over all reactions for each species
% Units are /s
Jac = f'*DratesDy;

% add dilution (first-order)
if ~isinf(tgauss),  dilrate = 1./(tgauss + 2*t); %gaussian dispersion
else,               dilrate = kdil;              %1st-order dilution
end
idg = sub2ind([nSp nSp],3:nSp,3:nSp); %get diagonal indices
Jac(idg) = Jac(idg) - dilrate;

% fixed species
% derivative of a constant is 0
Jac(iHold,:) = 0;

% family conservation
% For algebreic family member, derivative is 1 (or scale) for all family members, 0 otherwise
Fnames = fieldnames(Family);
for i = 1:length(Fnames)
    j = Family.(Fnames{i}).index;
    [~,m] = min(conc(:,j)); %use member with smallest concentration
    Jac(j(m),:) = 0; %wipe conserved species
    Jac(j(m),j) = Family.(Fnames{i}).scale;
end


