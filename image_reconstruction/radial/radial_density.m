function dcf = radial_density(traj)
%% Calculate simple Ram-Lak radial density function

% Get t
kdim=size(traj);

% 1D Ramlak
ram_lak=abs(linspace(-1,1,kdim(2)+1));ram_lak(end)=[];
ram_lak(end/2+1)=1/kdim(2);
dcf=repmat(ram_lak',[1 kdim(3:end)]);

disp('+Radial analytical density function is calculated.')
% END
end