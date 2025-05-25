fs = 22050;  % Sampling rate must be ≥ 22 kHz
recObj = audiorecorder(fs, 16, 1);  % 16-bit mono

disp('Start speaking...');
recordblocking(recObj, 3);  % 3 sec record
disp('End of recording.');

y = getaudiodata(recObj);
audiowrite('myvoice.wav', y, fs);

