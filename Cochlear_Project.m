
% Step 1: Load Input Audio 
[x, fs] = audioread('myvoice.wav');  
x = mean(x, 2);                         % Convert to mono
x = x / max(abs(x));                    % Normalize

%  Step 1: Apply Pre-Emphasis Filter 
b_pre = [1 -1];
a_pre = 1;
x_pre = filter(b_pre, a_pre, x);

% Step 2: Define Filter Bank Parameters 
N = 8;  % Number of channels
fc = [394 692 1064 1528 2109 2834 3740 4871];       % Center frequencies
BW = [265 331 413 516 645 805 1006 1257];           % Bandwidths
b_bpf = cell(N,1);
a_bpf = cell(N,1);

% Step 3: Design IIR Bandpass Filters 
for i = 1:N
    bw = BW(i);
    theta = 2*pi*fc(i)/fs;
    r = 1 - (bw/(fs/2));
    b_bpf{i} = [1 0 -1];
    a_bpf{i} = poly([r*exp(1j*theta), r*exp(-1j*theta)]);
end

% Plot Frequency Responses of All BPFs
figure;
for i = 1:N
    [h, w] = freqz(b_bpf{i}, a_bpf{i}, 1024, fs);
    plot(w, abs(h)); hold on;
end
title('Bandpass Filter Bank Responses'); xlabel('Frequency (Hz)'); ylabel('Magnitude');
legend(arrayfun(@(i) sprintf('Ch %d', i), 1:N, 'UniformOutput', false));

% Step 4: Envelope Extraction and Modulation 
env = cell(N,1);
reconstructed = zeros(size(x));
t = (0:length(x)-1)'/fs;

for i = 1:N
    % Bandpass filter each channel 
    y = filter(b_bpf{i}, a_bpf{i}, x_pre);
    
    % Full-wave rectification 
    y_mag = abs(y);

    % LPF smoothing (Butterworth) 
    [b_lpf, a_lpf] = butter(3, BW(i)/(2*fs), 'low');
    y_smooth = filter(b_lpf, a_lpf, y_mag);

    % DC Notch Filter 
    a_notch = 0.995;
    b_dc = 0.5*(1+a_notch) * [1 -1];
    a_dc = [1 -a_notch];
    y_env = filter(b_dc, a_dc, y_smooth);

    env{i} = y_env;

    % Envelope modulation with carrier 
    carrier = cos(2*pi*fc(i)*t);
    modulated = y_env .* carrier;

    % Accumulate channel output 
    reconstructed = reconstructed + modulated;
end

% Step 6: Normalize and Play Output 
reconstructed = reconstructed / max(abs(reconstructed));
sound(reconstructed, fs);
audiowrite('reconstructed_output.wav', reconstructed, fs);

% Step 7: Visualize
figure;
subplot(2,1,1);
spectrogram(x, 256, 200, 512, fs, 'yaxis');
title('Original Signal');

subplot(2,1,2);
spectrogram(reconstructed, 256, 200, 512, fs, 'yaxis');
title('Reconstructed Cochlear Simulation');
 
t = (0:length(x)-1)/fs;

figure;
subplot(2,1,1);
plot(t, x);
title('Original Audio Waveform');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot(t, reconstructed);
title('Cochlear Simulated Audio Waveform');
xlabel('Time (s)'); ylabel('Amplitude');
