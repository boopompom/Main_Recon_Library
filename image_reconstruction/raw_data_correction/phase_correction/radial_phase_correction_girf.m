function kspace_data =radial_phase_correction_girf(kspace_data,goldenangle,kdim,girf_phase)

kdim=c12d(kdim);
kdim_data=c12d(size(kspace_data));
cp=kdim(1)/2+1;
girf_phase=cell2mat(girf_phase);
phase_error_mtx=zeros(size(kspace_data));

% Get radial angles for uniform (rev) or golden angle
if goldenangle > 0
    d_ang=(pi/(((1+sqrt(5))/2)+goldenangle-1));
else
    d_ang=pi/(kdim(2));
end
rad_ang=0:d_ang:d_ang*(kdim(2)-1);

% Line reversal for uniform
if goldenangle == 0
    rad_ang(2:2:end)=rad_ang(2:2:end)+pi;
    rad_ang=mod(rad_ang,2*pi);
end

% Deal with stack-of-stars partition direction
if kdim(3) > 1
        if mod(kdim(3),2)==0 % is_odd
            kz=linspace(-1,1,kdim(3)+1);kz(end)=[];
        else
            kz=linspace(-1,1,kdim(3));
        end
else
    kz=zeros(1,kdim_data(3));
end

% Loop over partitions and determine phase error
for p=1:prod(kdim_data(4:end))
    tmp=repmat(girf_phase(:,1),[1 kdim(2) kdim_data(3)]).*repmat(cos(rad_ang),[kdim(1) 1 kdim_data(3)])+...
    repmat(girf_phase(:,2),[1 kdim(2) kdim_data(3)]).*repmat(sin(rad_ang),[kdim(1) 1 kdim_data(3)])+...
    repmat(girf_phase(:,3),[1 kdim(2) kdim_data(3)]).*repmat(permute(kz,[1 3 2]),[kdim(1) kdim(2) 1]);    
    phase_error_mtx(:,:,:,p)=exp(1j*1.2*tmp);  % Currently need this correction factor
end

% Apply correction to kspace_data
cph_pre=mean(matrix_to_vec(var(angle(kspace_data(cp,:,:)),[],2)));
kspace_data=kspace_data.*phase_error_mtx;
cph_post=mean(matrix_to_vec(var(angle(kspace_data(cp,:,:)),[],2)));
disp('+Radial girf based phase correction.')
disp(['     Mean variance of k0 phase changed from: ',num2str(cph_pre),' -> ',num2str(cph_post)])
% END
end