pkg load signal;

FILE = 'c:/prj/hmcdemo/src/math/a2.csv';
XCOL = 4; YCOL = 5; ZCOL = 6;
Td = 0.1; % sampling period
h_d = Td / 3; % for Simpson's rule

% ------------------------------------------------------
% Some functions
% ------------------------------------------------------

% Align vector V with length N to 3 (cut tail if needed)
function [NewN, NewV] = align3(N, V)
    NewN = N - mod(N, 3);
    NewV = V(1:NewN);
end

% Integrate vector V with sampling period Td
function [Iv,Tv] = simpsintegral(V, Td)
    VV = reshape(V, 3, size(V)(1)/3);
    h = Td/3.0;
    Td2 = 2.0*Td;
    I = 0;
    T = 0;
    Iv = [0];
    Tv = [0];
    for y = VV
        I = I + h*(y(1) + 4*y(2) + y(3));
        Iv(end + 1) = I;
        T = T + Td2;
        Tv(end + 1) = T;
    end
end

% Shift signal after filtering (for plotting)
function VV = shift_filtered(V, varargin)
    VV = V;
    for ord = varargin
        % ord{:} - content of cell
        VV = shift(VV, -ord{:}/2);
    end
end

% |H(z)| TODO not equals to gain (obtained via std())
function H = Hmodule(h, f, fs)
    h = h';
    %w = 2*pi*f/fs;
    w = 2*pi*f;
    args = -pi*[0:w:w*(numel(h)-1)];
    H = sum(h.*cos(args)) ^ 2 + sum(h.*sin(args)) ^ 2;
end

% ------------------------------------------------------
% Main program
% ------------------------------------------------------

% for FIR1 filter
% acceleration
FIR0enable = 0;
FIR0ord = 16;
FIR0fc = 2.5;
FIR0fnyq = (1/Td)/2;
FIR0fn = FIR0fc/FIR0fnyq;
FIR0b = fir1(FIR0ord, FIR0fn, 'high'); %, blackman(FIR0ord+1));

% acceleration
FIR1enable = 1;
FIR1ord = 10;
FIR1fc = 0.7;
FIR1fnyq = (1/Td)/2;
FIR1fn = FIR1fc/FIR1fnyq;
FIR1b = fir1(FIR1ord, FIR1fn, 'low', 'scale'); %, blackman(FIR1ord+1));
Hm = Hmodule(FIR1b, 0.00001, 1/Td)
%20*log10(Hm)
%Hm = Hmodule(FIR1b, 0.001, 1/Td)
%20*log10(Hm)
%sum(FIR1b .^ 2)
%XXX=nthroot(1/(Hm ^ 2) - 1, 2*FIR1ord)
%freqz(FIR1b); pause();

% speed
FIR2enable = 1;
FIR2ord = 16;
FIR2fc = 0.5;
FIR2fnyq = (1/Td)/2;
FIR2fn = FIR2fc/FIR2fnyq;
FIR2b = fir1(FIR2ord, FIR2fn, 'high', 'scale'); %, blackman(FIR2ord+1));

% distance
FIR3enable = 0;
FIR3ord = 16;
FIR3fc = 0.7;
FIR3fnyq = (1/Td)/2;
FIR3fn = FIR3fc/FIR3fnyq;
FIR3b = fir1(FIR3ord, FIR3fn, 'high', 'scale'); %, blackman(FIR3ord+1));


% Load data
data = dlmread(FILE, ';');
nrows = size(data(:, 4))(1);
[_, Ax] = align3(nrows, data(:, XCOL) * 9.81); % to m/s^2
[_, Ay] = align3(nrows, data(:, YCOL) * 9.81); % to m/s^2
[_, Az] = align3(nrows, data(:, ZCOL) * 9.81); % to m/s^2

% Simps, in Scilab = 0.0309014:
%   data=read_csv('c:/prj/hmcdemo/src/a.csv', ';')
%   intsplin(0:0.1:0.1*192,evstr(data(:,4)))

AccRaw = Az; % what axis
% filtering: no, -1 1st sample, FIR...
Acc = AccRaw;
%Acc = AccRaw - mean(AccRaw);
%Acc = AccRaw - AccRaw(1); % - this is solution!!!

% a coeffs are 1 (WHY???). Possible to use fftfilt(FIR1b, AccRaw)
% TODO shift parameter depends on FIR order (ord/2 ?)
AccP0 = std(Acc);
if (FIR0enable == 1)
    Acc = filter(FIR0b, 1, Acc);
end

if (FIR1enable == 1)
    Acc = filter(FIR1b, 1, Acc);
end
Acc = shift_filtered(Acc, FIR0ord*FIR0enable, FIR1ord*FIR1enable);
AccP1 = std(Acc);
%AccP0/AccP1
%20*log10(1/sqrt(sum((FIR1b .- mean(FIR1b)) .^ 2)/FIR1ord))
%K=sqrt(1/sum(FIR1b .^ 2))
%-20*log10(var(FIR1b))
K = AccP0/AccP1
Acc = Acc * AccP0/AccP1; % normalize Acc after filtering

[Speed, SpeedT] = simpsintegral(Acc, Td); % TODO Td*2????

N = size(Speed)(2);
[_, Speed] = align3(N, Speed);
[_, SpeedT] = align3(N, SpeedT);
SpeedRaw = Speed;
SpeedP0 = std(Speed);

if (FIR2enable == 1)
    Speed = filter(FIR2b, 1, Speed);
end

Speed = shift_filtered(Speed, FIR2ord*FIR2enable);
SpeedP1 = std(Speed);
Speed = Speed * SpeedP0/SpeedP1; % normalize speed after filtering

[Dist, DistT] = simpsintegral(Speed', Td*2); % TODO Td*4????
DistRaw = Dist;
DistP0 = std(Dist);

if (FIR3enable == 1)
    Dist = filter(FIR3b, 1, Dist);
end

Dist = shift_filtered(Dist, FIR3ord*FIR3enable);
DistP1 = std(Dist);
Dist = Dist * DistP0/DistP1; % normalize dist after filtering


% ------------------------------------------------------
% Plotting
% ------------------------------------------------------
n = size(Acc)(1)-1;
AccT = 0:Td:Td*n;

figure(1);

subplot(3, 1, 1);
%plotyy(AccT, AccRaw, AccT, Acc);
plot(AccT, AccRaw, AccT, Acc, 'r');
title('Acc');

subplot(3, 1, 2);
plot(SpeedT, SpeedRaw, SpeedT, Speed, 'r');
title('Speed');

subplot(3, 1, 3);
plot(DistT, DistRaw, DistT, Dist, 'r');
title('Dist');

printf('Acceleration: %f(%.1f s) m/s^2 ... %f(%.1f s) m/s^2\n',
    Acc(1), AccT(1), Acc(end), AccT(end));
printf('Speed: %f(%.1f s) m/s ... %f(%.1f s) m/s\n',
    Speed(1), SpeedT(1), Speed(end), SpeedT(end));
printf('Distance: %f(%.1f s) m ... %f(%.1f s) m = %.1f m\n',
    Dist(1), DistT(1), Dist(end), DistT(end), range(Dist));

pause();
