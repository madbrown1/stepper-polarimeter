%create HDF5 dataset

%writefilepath
fp = 'D:\Measurements\Dichroic_Analysis\';
date = date();
starttime = datestr(now);

usernotes = 'taken by khart ; dichroic at 0 degrees,matches exposures and wacelenths from air measurement taken sept 1 ';
fn = 'dichroic-0';
name = strcat(fp,fn,'-',date,'.h5');

num_meas = 64;

%set up measurement loop
for i = 1:31 
    wavelength=waves(i);
    exposure = exposures(i);
    framesPerTrigger = 3;
    homeMotor(xps)
    wavelengthSweep(name,wavelength,exposure ,vid,num_meas, COMmono,COMdmm, xps, framesPerTrigger)    
end

endtime = datestr(now);

[PSA, PSG] = generate_PSAG_angles(num_meas);

%write attibutes to directory
 h5writeatt(name,'/images/','start_time', starttime);
 h5writeatt(name,'/images/','end_time', endtime);
 h5writeatt(name,'/images/','user_notes', usernotes);
 h5writeatt(name,'/images/','PSG_positions', PSG); 
 h5writeatt(name,'/images/','PSA_positions', PSA); 

% close ports 
fclose('all');
close all
clc
instrreset
