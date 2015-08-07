% mex command is given by: 

function Test_Parameters(type)
if nargin == 0
    type = 2;
end


mex CXXFLAGS="\$CXXFLAGS -std=c++11 -O3 -lgopm" TC.cpp Cortical_Column.cpp Thalamic_Column.cpp

% Path to fieltrip preprocessing function
if(isempty(strfind(path, '/nfshome/schellen/Documents/MATLAB/Tools/fieldtrip/preproc')))
    addpath('~/Documents/MATLAB/Tools/fieldtrip/preproc');
end

% Path to helper function
if(isempty(strfind(path, '/nfshome/schellen/Documents/MATLAB/Tools/boundedline')))
    addpath('~/Documents/MATLAB/Tools/boundedline');
end

if type == 1    
    Param_Cortex        = [4.7;         % sigma_e
                           1.33;        % g_KNa
                           120E-3];     % dphi
                       
    Param_Thalamus      = [0.051;       % g_h
                           0.024];      % g_LK  
                       
    fn_data = '/nfshome/schellen/Documents/MATLAB/TC_model/Data/SO_Average_N3';
    Model_Range_ERP = [-75, -45]; 
    Model_Range_FSP = [-0.25, 1.25]; 
    Data_Range_ERP  = [-75, 35]; 
    Data_Range_FSP  = [2, 5]; 
    xRange          = -0.5:0.25:1.5;
else    
    Param_Cortex        = [6;          % sigma_e
                           2.0;         % g_KNa
                           120E-3];     % dphi
                       
    Param_Thalamus      = [0.051;       % g_h
                           0.0205];       % g_LK
                       
    fn_data = '/nfshome/schellen/Documents/MATLAB/TC_model/Data/SO_Average_N3';
    Model_Range_ERP = [-75, -45]; 
    Model_Range_FSP = [-0.25, 1.25]; 
    Data_Range_ERP  = [-75, 35]; 
    Data_Range_FSP  = [2, 5]; 
    xRange          = -0.5:0.25:1.5;
end
                        
Connectivity            = [ 2.5;        % N_et
                            2.5;        % N_er
                            15;          % N_te
                            15];        % N_ti   
                        
load(fn_data);

% stimulation parameters
% first number is the mode of stimulation
% 0 == none
% 1 == semi-periodic
% 2 == phase dependend
    
var_stim    = [ 0;          % mode of stimulation
                40;         % strength of the stimulus              in Hz (spikes per second)
                100;       	% duration of the stimulus              in ms
                5;          % time between stimulation events       in s  (ISI)
                0;          % range of ISI                          in s  [ISI-range,ISI+range]  
                3;          % Number of stimuli per event
                1050;        % time between stimuli within a event   in ms         
                450];       % time until stimuli after minimum      in ms

T       	= 300;           % duration of the simulation

[Ve, Vi, Vt, Vr] = TC(T, Param_Cortex, Param_Thalamus, Connectivity, var_stim);
Fs          = length(Ve)/T;


Ve_low      = ft_preproc_bandpassfilter(Ve, Fs, [0.25,4], 513,  'fir') + mean(Ve);
Ve_FSP      = ft_preproc_hilbert(ft_preproc_bandpassfilter(Ve, Fs, [12, 15], 513, 'fir'), 'abs').^2;

% Search for peaks
[~, x_SO]   = findpeaks(-Ve_low, 'MINPEAKHEIGHT', 68, 'MINPEAKDISTANCE', 0.2*Fs);

% Remove those events, that are too close to begin/end
x_SO        = x_SO(x_SO<(T-2)*Fs); 
x_SO        = x_SO(x_SO>    2*Fs);
x_SO        = x_SO-3; % fix a different min position wrt data   

% Set the variables 
N_Stim      = length(x_SO);
Range_ERP   = [-0.5, 1.5];
time_event  = linspace(Range_ERP(1), Range_ERP(2), (Range_ERP(2)-Range_ERP(1))*Fs);
Events      = zeros(length(time_event), N_Stim);
Events_FSP  = zeros(length(time_event), N_Stim);

% Segmentation
for i=1:N_Stim
    Events(:,i)     =  Ve    ((x_SO(i)+Range_ERP(1)*Fs)+1:(x_SO(i)+Range_ERP(2)*Fs));
    Events_FSP(:,i) =  Ve_FSP((x_SO(i)+Range_ERP(1)*Fs)+1:(x_SO(i)+Range_ERP(2)*Fs));
end

mean_ERP_model= mean(Events,    2); %#ok<*NASGU>
mean_FSP_model= mean(Events_FSP,2);
sd_ERP_model  = std (Events,    0, 2);
sd_FSP_model  = std (Events_FSP,0, 2);

% Define handle for plotting
BL_model =@(y,x) boundedline(y,x(:,1), x(:,2), 'alpha', 'transparency', 0.1, 'r');
BL_data  =@(y,x) boundedline(y,x(:,1), x(:,2), 'alpha', 'transparency', 0.1, 'black');

% Option array for set
Option_Name = { 'ylim';
                'ytick';
                'yticklabel';
                'ycolor';
                'xtick'}';
            
Option_Model_ERP = {Model_Range_ERP;
                    linspace(Model_Range_ERP(1), Model_Range_ERP(2), 5);
                    linspace(Model_Range_ERP(1), Model_Range_ERP(2), 5);
                    'black';
                    xRange}'; %#ok<*NBRAK>

Option_Data_ERP  = {Data_Range_ERP;
                    linspace(Data_Range_ERP(1), Data_Range_ERP(2), 5);
                    linspace(Data_Range_ERP(1), Data_Range_ERP(2), 5);
                    'black';
                    xRange}';

Option_Model_FSP = {Model_Range_FSP;
                    linspace(Model_Range_FSP(1), Model_Range_FSP(2), 5);
                    linspace(Model_Range_FSP(1), Model_Range_FSP(2), 5);
                    'black';
                    xRange}';

Option_Data_FSP  = {Data_Range_FSP;
                    linspace(Data_Range_FSP(1), Data_Range_FSP(2), 5);
                    linspace(Data_Range_FSP(1), Data_Range_FSP(2), 5);
                    'black';
                    xRange}';
                
figure(1)
subplot(411)
plot(linspace(0,30,3000),Ve(101:3100));
title(['Ve with a mean of :',num2str(mean(Ve))]);
subplot(412)
plot(linspace(0,30,3000),Vi(101:3100));
title(['Vi with a mean of :',num2str(mean(Vi))]);
subplot(413)
plot(linspace(0,30,3000),Vt(101:3100));
title(['Vt with a mean of :',num2str(mean(Vt))]);
subplot(414)
plot(linspace(0,30,3000),Vr(101:3100));
title(['Vr with a mean of :',num2str(mean(Vr))]);
                
% Create figure
figure(2)
clf
subplot(211)
[AX1, ~, ~] = plotyy(time_events,[mean_SO_data, sem_SO_data],time_events,[mean_ERP_model, sd_ERP_model], BL_data, BL_model);
set(AX1(1), Option_Name, Option_Data_ERP);
set(AX1(2), Option_Name, Option_Model_ERP);
ylabel(AX1(1),'EEG [$\mu$V]');
ylabel(AX1(2),'$V_{e}$ [mV]');
title([num2str(N_Stim), ' Events'])
subplot(212)
[AX1, ~, ~] = plotyy(time_events,[mean_FSP_data, sem_FSP_data],time_events,[mean_FSP_model, sd_FSP_model], BL_data, BL_model);
set(AX1(1), Option_Name, Option_Data_FSP);
set(AX1(2), Option_Name, Option_Model_FSP);
ylabel(AX1(1),'FSP data [a.u.]');
ylabel(AX1(2),'$FSP model$ [a.u.]');
title([num2str(N_Stim), ' Events'])
end