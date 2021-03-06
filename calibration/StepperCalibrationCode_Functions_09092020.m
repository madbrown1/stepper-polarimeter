% Stepper Calibration Code
% Authors: Lisa Li, James Heath, Kira Hart
% Last Updated: 2020/08/25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Clear variables
tic
clear all; close all;clc;
nSteps = 64; %StepperCal = 64, RGB950 = 40
LambdaList = linspace(450,740,30);
nLambda = length(LambdaList);

%image size. Needs to be more robust.
testimsz_1 = 1500;
testimsz_2 = 1500;
ROI = 5;

%Calibration file path
calibrationFilePath = 'Y:\Measurements\Dichroic_Analysis\air-01-Sep-2020.h5';
testFilePath = '\\765-polarizer.optics.arizona.edu\stepper\Stepper Polarimeter\Stepper Software Rebuild\TestData\Dichroic_Analysis\dichroic-45-07-Sep-2020.h5';

for ii = 1:length(LambdaList) %for loading all lambda(s)
%Get h5 reference data
    Lambda = LambdaList(ii);
    refVecs(ii,:) = NormalizedReferenceData(calibrationFilePath,Lambda,nSteps);

%Grab measured data from h5 file
    meandata(ii,:,:,:) = ReadCalImages(calibrationFilePath,Lambda,refVecs,nSteps); %needs to use dark field correction code at some point

end

%Find the max
mx = max(meandata,[],'all');

%%
clc;
%Get amount of pixels
PixelCount = length(meandata(1,1,:));

%meandataVecs = reshape(meandata,1,64,10,10);


%Get a function for fitting the values
%Get spectrum data for "lambda colored" plots
% sRGB = spectrumRGB(Lambda, '1964_FULL');
% cRGB(:) = [sRGB(:,1) sRGB(:,2) sRGB(:,3)]; %Colors for graphing

%AirCalRoutine_MKedit2(Amp,PSG_delta,PSG_theta,PSA_delta,PSA_theta,PSA_LP,nSteps)
func = @(fitvals, inpvals) AirCalRoutine_MKeditLSQ(fitvals(1:PixelCount*nLambda),fitvals(PixelCount*nLambda+1:PixelCount*nLambda+nLambda),fitvals(PixelCount*nLambda+1+nLambda),fitvals(PixelCount*nLambda+2+nLambda:PixelCount*nLambda+1+2*nLambda),fitvals(PixelCount*nLambda+2+2*nLambda),fitvals(PixelCount*nLambda+3+2*nLambda),inpvals);

%Set bounds and known values, likely not optimal ask Meredith
% lb = [Amp ];
% ub = [3*mx*ones(1,PixelCount) pi*ones(1,PixelCount) pi*ones(1,PixelCount)];
lb = [mx*zeros(1,PixelCount*nLambda) -pi*ones(1,nLambda) -pi/2 -pi*ones(1,nLambda) -pi/2 -pi/2];
ub = [3*mx*ones(1,PixelCount*nLambda) pi*ones(1,nLambda) pi/2 pi*ones(1,nLambda) pi/2 pi/2];


%Input vector
% inpvec = [PixelCount, nSteps, ThetaMotorGen, ThetaMotorAna];

%Starting fit guess
% fitguess = [2*mx*ones([1,PixelCount]), 2*pi/3*ones([1,PixelCount]), 2*pi/3*ones([1,PixelCount])];, 2*pi/3, 0, 2*pi/3, 0, 0
fitguess = [2*mx*ones([1,PixelCount*nLambda]), 2*pi/3*ones(1,nLambda), 0, 2*pi/3*ones(1,nLambda), 0, 0];
%%
%Least squares curve fitting and storing into caldata
[fits,resnorm,res] = lsqcurvefit(func, fitguess, nSteps, meandata,lb,ub);
caldata(:)=fits(:);
%%
%RMSE of data
for ii = 1:nLambda
RMSE_var(ii) = std(res(ii,:)); %will need to fix size (1 x nLambda)
end
%Grab caldata for tables, plotting, and psgMM/psaMM
%Create table in radians
Amp = caldata(1:PixelCount*nLambda);
dg_rad = caldata(PixelCount*nLambda+1:PixelCount*nLambda+nLambda); %change range
DelRad_g = caldata(PixelCount*nLambda+1+nLambda);
da_rad = caldata(PixelCount*nLambda+2+nLambda:PixelCount*nLambda+1+2*nLambda); %change range
DelRad_a = caldata(PixelCount*nLambda+2+2*nLambda);
LP_Rad = caldata(PixelCount*nLambda+3+2*nLambda);

%plot lambda vs del_a and del_g
%plot Amplitude vs meas# for nLambda
%print Theta_LP,PSA,PSG


ThetaMotorGen = (0:nSteps-1)*2*pi/nSteps; 
%%
figure(1)
plot(LambdaList,dg_rad)
title('\delta_{g} radians');
figure(2)
plot(LambdaList,da_rad)
title('\delta_{a} radians');
figure(3)
errorbar(LambdaList,RMSE_var);
title('RMSE vs Lambda');
%%
%Plot Data
hold on;
plot(ThetaMotorGen,mean(squeeze(meandata(13,:,:,:)),[2,3]),'*r'); 
Irrad = AirCalRoutine_MKeditLSQ(Amp,dg_rad,DelRad_g,da_rad,DelRad_a,LP_Rad, 629);

%Plot fit
plot(0:0.01:2*pi,mean(squeeze(Irrad(13,:,:,:)),[2,3]));%,'color',cRGB);
title(['Lambda =  ' num2str(LambdaList(13))]);
xlabel('PSG Rotation (Radians)')
ylabel('Camera Counts')

%Create table in degrees
dg_deg = dg_rad.*180/pi;
DelDeg_g = DelRad_g.*180/pi;
da_deg = da_rad.*180/pi;
DelDeg_a = DelRad_a.*180/pi;
LP_Deg = LP_Rad.*180/pi;

toc
%%
Avg_Amplitude = mean(Amp,'all');
RMSE = RMSE_var;


T = table(LambdaList,Avg_Amplitude,dg_rad, DelRad_g, da_rad, DelRad_a, LP_Rad, RMSE)

% Avg_delta_g = mean(dg_deg,'all');
% Avg_Theta_g = mean(DelDeg_g,'all');
% Avg_delta_a = mean(da_deg,'all');
% Avg_Theta_a = mean(DelDeg_a,'all');
% Avg_LP_Theta = mean(LP_Deg,'all');

T = table(LambdaList,Avg_Amplitude,dg_deg, DelDeg_g, da_deg, DelDeg_a, LP_Deg, RMSE)
% 
% figure(2)
% imagesc(reshape(Amp,5,5));colormap(gca,'parula');hcb1=colorbar;
% sgtitle(['Amplitude ' num2str(Lambda) 'nm'])
%%
%Creating W Matrix
tic
[~,W] = AirCalRoutine_MKedit2(Amp,dg_rad,DelRad_g,da_rad,DelRad_a,LP_Rad,nSteps);
toc
%% Generate Mueller Matrices
Lambda = 450;


refVecsImgs = NormalizedReferenceData(testFilePath, Lambda, nSteps);
% [imgdata, ROIimg] = ReadDataImages(testFilePath, Lambda,refVecsImgs,nSteps);
[imgdata, ROIimg] = ReadDataImagesNoRef(testFilePath, Lambda,nSteps);
% save('dichroic_575_45','imgdata','ROIimg');
f = msgbox('Operation Completed');
%%
load handel
sound(y,Fs)
%%
temp = reshape(Amp(:),30,5,5);

%%

tic
% nLambda=length(Lambda);
M = zeros(nLambda,16,1500*1500);
for n = 1:nLambda
    Winv = pinv(squeeze(W(n,:,:)));
    M(n,:,:) = Winv*(reshape(imgdata(:,:,:),nSteps,1500*1500)./repmat(Amp(:)',[nSteps 1]));
end

toc
%% .h5 ROI image1
mmVecs = CreateMuellerMatrix(Amp,W,nLambda,ROI,ROIimg,nSteps);
%% Normalize MM
for ii = 1:16
    NormMMVecs(ii,:,:) = squeeze(mmVecs(ii,:,:))./squeeze(mmVecs(1,:,:));
end

%% Create averaged scalar MM (Table form)
AvgMMTable(mmVecs,450,LambdaList)

%% Display image MMs
DisplayMM(mmVecs,nLambda,LambdaList)


%% Display Normalized MM
DisplayNormMM(mmVecs,LambdaList,nLambda)

%% MM transmission curves 

TransmissionMMPlot(LambdaList,mmVecs)
%% M_xy setup for easier calculations
Label = ['Dichroic 45' char(176)];

for n = 1:nLambda
    Label = ['Dichroic 45' char(176)];
    WL = num2str(Lambda);

    M_00(n,:,:)= squeeze(mmVecs(n,1,:,:));
    M_01(n,:,:)= squeeze(mmVecs(n,2,:,:));
    M_02(n,:,:)= squeeze(mmVecs(n,3,:,:));
    M_03(n,:,:)= squeeze(mmVecs(n,4,:,:));
    M_10(n,:,:)= squeeze(mmVecs(n,5,:,:));
    M_11(n,:,:)= squeeze(mmVecs(n,6,:,:));
    M_12(n,:,:)= squeeze(mmVecs(n,7,:,:));
    M_13(n,:,:)= squeeze(mmVecs(n,8,:,:));
    M_20(n,:,:)= squeeze(mmVecs(n,9,:,:));
    M_21(n,:,:)= squeeze(mmVecs(n,10,:,:));
    M_22(n,:,:)= squeeze(mmVecs(n,11,:,:));
    M_23(n,:,:)= squeeze(mmVecs(n,12,:,:));
    M_30(n,:,:)= squeeze(mmVecs(n,13,:,:)); 
    M_31(n,:,:)= squeeze(mmVecs(n,14,:,:));
    M_32(n,:,:)= squeeze(mmVecs(n,15,:,:));
    M_33(n,:,:)= squeeze(mmVecs(n,16,:,:));
end

M_00(M_00 == 0) = NaN;

%% Diattenuation
DiattenuationMM(mmVecs,LambdaList,nLambda,Label)
%% Linear Diattenuation
LinDiattenuationMM(mmVecs,LambdaList,nLambda,Label)

%% Polarizance
Polarizance(mmVecs, LambdaList, nLambda, Label)
%% Retardation Map

tic
close all;

delta = acos(((M_00 + M_11 + M_22 + M_33)/2)-1);
del_H = delta/(2*sin(delta))*(M_23 - M_32);
del_45 = delta/(2*sin(delta))*(M_31 - M_13);
del_R = delta/(2*sin(delta))*(M_12 - M_21);

del_H = 0.5*(M_23 - M_32);
del_45 = 0.5*(M_31 - M_13);
del_R = 0.5*(M_12 - M_21);


%Equation(s) 6.32 from page 173 of Russell's book. Only works for halfwave
%retarder!
% del_H = pi*(sqrt((squeeze(mmVecs(5,:,:))+1)./2));
% del_H = pi*(sqrt((M_10 + 1)./2));
% % del_45 = pi*(sign(squeeze(mmVecs(6,:,:)).*sqrt((squeeze(mmVecs(10,:,:))+1)/2)));
% del_45 = pi*(sign(M_11.*sqrt((M_21 + 1)/2)));
% % del_R = pi*(sign(squeeze(mmVecs(7,:,:)).*sqrt((squeeze(mmVecs(16,:,:))+1)/2)));
% del_R = pi*(sign(M_12.*sqrt((M_33+1)/2)));
% 
% %Equation 6.27 from page 171 of Russell's book
delta_check = sqrt(del_H.^2 + del_45.^2 + del_R.^2);
edges = linspace(-1,1,200);
%Plot retardance
a=subplot(2,2,1)
histogram(delta_check,'BinEdges',edges);
title('\delta')
b=subplot(2,2,2)
histogram(del_H,'BinEdges',edges);
title('\delta_H')
c=subplot(2,2,3)
histogram(del_45,'BinEdges',edges);
title('\delta_{45}')
loc = subplot(2,2,4)
d = get(loc, 'Position');
histogram(del_R,'BinEdges',edges);
title('\delta_R')
% sgtitle([Label WL ' Retardance Maps'])
toc

%% Depolarization Index
DepolIndex(mmVecs, LambdaList, nLambda, Label)
