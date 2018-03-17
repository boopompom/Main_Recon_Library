%% Demonstration script
clear all;close all;clc

%% Readers & Writers
% Get k-space data from lab/raw
kdata=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw');

% Get images from par/rec
%images=reader_reconframe_par_rec('/local_scratch/tbruijne/WorkingData/4DLung/Scan2/ha_27112017_1534304_8_1_wip_t_t1_4d_tfeV4.rec');

% Extract PPE parameters (from reconframe object)
[kdata,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw');
ppe_pars=reader_reconframe_ppe_pars(MR);

% Write data to dicom
MR.Perform;
writeDicomFromMRecon(MR,MR.Data,'..\Main_Recon_Library\');

%% NUFFT toolboxes used with a 3D goldenangle dataset
% Radial k-space trajectory (\./ not \../)
[~,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw');
kdim=size(MR.Data);
ppe_pars=reader_reconframe_ppe_pars(MR);

% Trajectory & density
traj=radial_trajectory(kdim(1:2),ppe_pars.goldenangle);
dcf=radial_density(traj);

% FFT in z
MR.Data=ifft(MR.Data,[],3);

% Radial phase correction
radial_phase_correction_zero(MR.Data);

% Initialize Fessler 2D nufft operator
F2D=FG2D(traj,[kdim(1:2) 1]);

% Do the Fessler gridding
for z=1:size(MR.Data,3)
    for c=1:1%size(MR.Data,4)
        Fessler2D(:,:,z,c)=F2D'*(MR.Data(:,:,z,c).*dcf);
        disp(['Coil / Z = ',num2str(c),' ',num2str(z)])
    end    
end
close all;figure,imshow3(abs(Fessler2D(:,:,5:28,1)),[],[4 6])

% Do the Greengard gridding
G2D=GG2D(traj,[kdim(1:2) 1]);

% Do the Greengard gridding
for z=1:size(MR.Data,3)
    for c=1:1%size(MR.Data,4)
        Greengard2D(:,:,z,c)=G2D'*(MR.Data(:,:,z,c).*dcf);
        disp(['Coil / Z = ',num2str(c),' ',num2str(z)])
    end    
end
figure,imshow3(abs(Greengard2D(:,:,5:28,1)),[],[4 6])

% Reload data for 3D NUFFT
[~,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw');
kdim=size(MR.Data);
ppe_pars=reader_reconframe_ppe_pars(MR);
traj=radial_trajectory(kdim(1:3),ppe_pars.goldenangle);
dcf=radial_density(traj);
radial_phase_correction_zero(MR.Data);

% Initialize Fessler 3D nufft operator
F3D=FG3D(traj,[kdim(1:3) 1]);
for c=1:1%size(MR.Data,4)
    Fessler3D(:,:,:,c)=F3D'*(MR.Data(:,:,:,c).*dcf);
end
close all;figure,imshow3(abs(Fessler3D(:,:,5:28,1)),[],[4 6])

% 3D Greengard gridding
G3D=GG3D(traj,[kdim(1:3) 1]);
for c=1:1%size(MR.Data,4)
    Greengard3D(:,:,:,c)=G3D'*(MR.Data(:,:,:,c).*dcf);
end
figure,imshow3(abs(Greengard3D(:,:,5:28,1)),[],[4 6])

%% Coil sensitivity map estimation (espirit and openadapt)
[~,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw');
kdim=size(MR.Data);
ppe_pars=reader_reconframe_ppe_pars(MR);
traj=radial_trajectory(kdim(1:2),ppe_pars.goldenangle);
dcf=radial_density(traj);
radial_phase_correction_zero(MR.Data);
MR.Data=ifft(MR.Data,[],3);

% Create low-res images using a k-space mask
lr=5; % 5 times lower resolution
mask=radial_lowres_mask(kdim(1:2),lr);
F2D=FG2D(traj,[kdim(1:2) 1]);
for z=1:size(MR.Data,3)
    for c=1:size(MR.Data,4)
        Fessler2D_LR(:,:,z,c)=F2D'*(MR.Data(:,:,z,c).*dcf.*mask);
        disp(['Coil / Z = ',num2str(c),' ',num2str(z)])
    end    
end
close all;figure,imshow3(abs(Fessler2D_LR(:,:,5:28,1)),[],[4 6])

% Openadapt 2D
for z=1:size(MR.Data,3)
    CSM_opd_2D(:,:,:,z)=openadapt(Fessler2D_LR(:,:,z,:));
    disp(['Z = ',num2str(z)])
end
figure,imshow3(abs(CSM_opd_2D(:,:,15,:)),[],[2 6])

% Openadapt 3D
CSM_opd_3D=openadapt(Fessler2D_LR);
figure,imshow3(abs(CSM_opd_3D(:,:,15,:)),[],[2 6])

% ESPIRiT 2D (either matlab-based (slow) or bart-based (fast)
for z=15:15%1:size(MR.Data,3)
    csm(:,:,z,:)=espirit(Fessler2D_LR(:,:,z,:));
end

%% Iterative density estimation code (only 3D)
[kspace_data,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw',1,1);
kdim=size(kspace_data);
traj=radial_trajectory(kdim(1:3),1);
dcf=iterative_dcf_estimation(traj);
radial_phase_correction_zero(kspace_data);

% Initialize Fessler 3D nufft operator
F3D=FG3D(traj,[kdim(1:3) 1]);
for c=1:1%size(MR.Data,4)
    Fessler3D(:,:,:,c)=F3D'*(kspace_data(:,:,:,c).*dcf);
end

%% Estimate respiratory signal from multi-channel k-space data + motion weighted reconstruction
[kspace_data,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw',1,1);
kdim=size(kspace_data);
traj=radial_trajectory(kdim(1:2),1);
dcf=radial_density(traj);
kspace_data=ifft(kspace_data,[],3);
radial_phase_correction_zero(kspace_data);

% Estimation respiratory motion signal from multichannel data
respiration=radial_3D_estimate_motion(kspace_data);

% Get soft-weights
recon_matrix_size=round(max(traj(:)));
soft_weights=mrriddle_respiratory_filter(respiration,recon_matrix_size);

% Apply motion-weighted reconstruction
F2D=FG2D(traj,[kdim(1:2) 1]);
for z=1:size(kspace_data,3)
    for c=1:size(kspace_data,4)
        Fessler2D_SW(:,:,z,c)=F2D'*(kspace_data(:,:,z,c).*dcf.*repmat(soft_weights,[kdim(1) 1]));
        disp(['Coil / Z = ',num2str(c),' ',num2str(z)])
    end    
end
close all;figure,imshow3(abs(Fessler2D_SW(:,:,5:28,1)),[],[4 6])

%% 4D (x,y,z,resp) reconstruction
[kspace_data,MR]=reader_reconframe_lab_raw('../Data/bs_06122016_1607476_2_2_wip4dga1pfnoexperiment1senseV4.raw',1,1);
kdim=size(kspace_data);
traj=radial_trajectory(kdim(1:2),1);
dcf=radial_density(traj);
kspace_data=ifft(kspace_data,[],3);
radial_phase_correction_zero(kspace_data);
respiration=radial_3D_estimate_motion(kspace_data);

% Define number of phases and do phase-binning
n_phases=4;
respiratory_bin_idx=respiratory_binning(respiration,n_phases);

% Use the binning to transform the data matrices
[kspace_data,traj,dcf]=respiratory_data_transform(kspace_data,traj,dcf,respiratory_bin_idx,n_phases);

% Fourier transform on new matrices
kdim=size(kspace_data);
F2D=FG2D(traj,kdim);
Recon_4D=F2D'*(kspace_data.*repmat(dcf,[1 1 kdim(3) kdim(4)]));
slicer(squeeze(Recon_4D(:,:,19,:,:)))