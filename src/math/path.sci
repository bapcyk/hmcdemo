// ------------------------------------------------------
// Macros
// ------------------------------------------------------
G = 9.81; // gravity constant
// columns in CSV file
AX = 4; AY = 5; AZ = 6;
// disabling filter usage is order==0
NOFILT = 0;
// Supported filters
WFIR = 'WFIR';
EQFIR = 'EQFIR';
FFILT = 'FFILT';
// Supported integration methods
TRI = 'TRAPEZOID';
SMI = 'SIMPSON';
LTI = 'LEO_TICK';
NOI = '--';

// ------------------------------------------------------
// Some functions
// ------------------------------------------------------
// Simpson's rule integral
function [Iv,Tv] = smintegral(V, T)
    h = T/3;
    I = 0;
    y_2 = 0;
    y_1 = 0;
    i = 0;
    Iv = [];
    Tv = [];
    for y = V
        if i<=1,
            I = 0;
        elseif 0==modulo(i,2),
            I = I + h*(y_2 + 4*y_1 + y);
        end
        Iv($+1) = I;
        Tv($+1) = h*i;
        y_2 = y_1;
        y_1 = y;
        i = i+1;
    end
endfunction

// trapezoid integration
function [Iv,Tv] = trintegral(V, T)
    h = T;
    I = 0;
    y_1 = 0;
    i = 0;
    Iv = [];
    Tv = [];
    for y = V
        if i<1,
            I = 0;
        else
            I = I + h*(y_1 + y)/2;
        end
        Iv($+1) = I;
        Tv($+1) = h*i;
        y_1 = y;
        i = i+1;
    end
endfunction

// Leo Tick integral
function [Iv,Tv] = ltintegral(V, T)
    h = T/2;
    I_2 = 0;
    I_1 = 0;
    I = 0;
    y_2 = 0;
    y_1 = 0;
    i = 0;
    Iv = [];
    Tv = [];
    for y = V
        if i<=1,
            I = 0;
        else
            I = I_2 + h*(0.3584*y + 1.2832*y_1 + 0.3584*y_2); // FIXME I_2 ?
        end
        Iv($+1) = I;
        Tv($+1) = h*i;
        I_2 = I_1;
        I_1 = I;
        y_2 = y_1;
        y_1 = y;
        i = i+1;
    end
endfunction

// Classical method of velocity and path definition
function [V,P] = classvp(A, T)
    v0 = 0; v1 = 0;
    a0 = 0; a1 = 0;
    p0 = 0; p1 = 0;
    V = [v0]; P = [p0];
    i = 1;
    while i < length(A),
        a1 = A(i); t = T(i);
        v1 = v0 + t*a0 + t*(a1-a0)/2;
        p1 = p0 + t*v0 + t*(v1-v0)/2;
        a0 = a1;
        v0 = v1;
        p0 = p1;
        V($+1) = v1;
        P($+1) = p1;
        i = i + 1;
    end
endfunction

// General integration method
function [Iv,Tv] = do_integral(alg, V, T)
    select alg
        case TRI
            [Iv,Tv] = trintegral(V, T);
        case SMI
            [Iv,Tv] = smintegral(V, T);
        case LTI
            [Iv,Tv] = ltintegral(V, T);
        case NOI
            Iv = V';
            Tv = [0:T:T*(length(V)-1)];
    end
endfunction

// Shift signal after filtering (for plotting)
function VV = shift_filtered(V, n)
    if n == 0,
        VV = V;
    else
        VV = cat(1, V(n:$), V(1:n-1));
    end
endfunction

// normalized frequency
function W = cfreq(f, fs)
    nyq = fs/2;
    W = f/nyq;
endfunction

// create filter structure, fc1,fc2 - cut freqs (Hz).
// Ex. of H(z) plot:
//   F=create_filter(33, 10, 0.7, 2, 0.085); [m,f] = frmag(F.wft, 256); plot(f,m);
function F = create_my_filter(ord, fs, fc1, fc2, func, r)
    [nrets, nargs] = argn(0);
    if nargs < 5, func = WFIR; end
    if nargs < 6, r = 0.09; end

    nfc1 = cfreq(fc1, fs); nfc2 = cfreq(fc2, fs);

    if ord == 0,
        F.wft = [];
        F.ord = ord;
        F.fc1 = fc1;
        F.fc2 = fc2;
        F.nfc1 = nfc1;
        F.nfc2 = nfc2;
        F.func = func;
        return;
    end

    select func
        case WFIR
            [F.wft, F.wfm, F.fr] = wfir('bp', ord, [nfc1 nfc2], 'hm', []);
        case EQFIR
            F.wft = eqfir(ord, [0 nfc1; nfc1+r nfc2-r; nfc2 0.5], [0 1 0], [1 1 1]);
        case FFILT
            F.wft = ffilt('bp', ord, nfc1, nfc2);
    end
    F.ord = ord;
    F.fc1 = fc1;
    F.fc2 = fc2;
    F.nfc1 = nfc1;
    F.nfc2 = nfc2;
    F.func = func;
endfunction

// plot H(z) of created filters
function plot_my_filters(varargin)
    nvalids = 0;
    for F = varargin,
        if length(F.wft) ~= 0,
            nvalids = nvalids + 1;
        end
    end
    
    if nvalids == 0,
        return;
    end

    figure(2);
    scf(2);
    clf(2);
    i = 1;
    for F = varargin,
        if length(F.wft) ~= 0,
            subplot(nvalids, 1, i);
            //[m,f] = frmag(F.wft, 256);
            //plot(f, m);
            p = poly(F.wft, 'z', 'coeff');
            h = horner(p, 1/%z);
            l = syslin('d', h);
            bode(l);
            i = i + 1;
        end
    end
    close(2);
endfunction

// filtering of signal by created filter
function FS = do_my_filter(F, S)
    if length(F.wft)==0,
        FS = S;
    else
        if length(S)==0,
            error("S should be not empty");
        end
        FS = filter(F.wft, 1, S);
    end
endfunction

// print filter settings
function print_my_filter(F)
    printf('%s filter: ord=%d, fc1=%.2fHz[%.2f], fc2=%.2fHz[%.2f]\n', F.func, F.ord, F.fc1, F.nfc1, F.fc2, F.nfc2);
endfunction

// ------------------------------------------------------
// Settings
// ------------------------------------------------------
SIMULATE = 0; // simulate input data with sin...
FILE = 'c:/prj/hmcdemo/src/math/a3.csv'; // input file
AXIS = AZ; // what axis to process
Td = 0.1; // sampling period
Fs = 1/Td; // sampling freq
INTR = TRI; // integration method

// ------------------------------------------------------
// FIR filters setup
// ------------------------------------------------------
// acceleration first FIR
Ord = 33;
//FLT0 = create_my_filter(Ord, Fs, 0.5, 0.9, EQFIR, 0.01);
//FLT1 = create_my_filter(Ord, Fs, 0.7, 1.5, EQFIR, 0.05);
//FLT2 = create_my_filter(Ord, Fs, 0.1, 0.9, EQFIR, 0.05);
FLT0 = create_my_filter(Ord, Fs, 0.1, 0.7, WFIR);
FLT1 = create_my_filter(0, Fs, 0.1, 0.9, WFIR);
FLT2 = create_my_filter(Ord, Fs, 0.1, 0.9, WFIR);

// ------------------------------------------------------
// Main program
// ------------------------------------------------------
if SIMULATE == 0,
    data=evstr(read_csv(FILE, ';'));
    AccRaw = data(:,AXIS) * G;
    Acc = AccRaw;
    // times moments
    AccT = 0:Td:Td*(length(Acc)-1);
else
    AccT = [0:0.1:30];
    //AccRaw = sin(2*%pi*AccT);// + AccT + rand(1:length(AccT), 'normal');
    AccRaw = sin(%pi*AccT) - cos(20*%pi*AccT);
    AccRaw = AccRaw';
    Acc = AccRaw;
end

// Process data
Acc = do_my_filter(FLT0, Acc);
[Speed, SpeedT] = do_integral(LTI, Acc', Td);
N = length(Speed);
SpeedRaw = Speed;
Speed = do_my_filter(FLT1, Speed);
[Dist, DistT] = do_integral(LTI, Speed', Td); //XXX Td*2 for SMI
DistRaw = Dist;
Dist = do_my_filter(FLT2, Dist);

[SpeedClassicRaw, DistClassicRaw] = classvp(AccRaw, AccT);
[SpeedClassic, DistClassic] = classvp(Acc, AccT);

// ------------------------------------------------------
// Plotting
// ------------------------------------------------------
plot_my_filters(FLT0, FLT1, FLT2);

figure(1);
scf(1);
clf(1);
subplot(4, 1, 1);
plot(AccT, AccRaw, AccT, shift_filtered(Acc, FLT0.ord/2), 'r');
title('acceleration');

subplot(4, 1, 2);
plot(SpeedT, SpeedRaw, SpeedT, shift_filtered(Speed, FLT1.ord/2), 'r');
title('speed');

subplot(4, 1, 3);
plot(DistT, DistRaw, DistT, shift_filtered(Dist, FLT2.ord/2), 'r');
title('distance');

subplot(4, 1, 4);
plot(AccT, DistClassicRaw, AccT, DistClassic, 'r');
title('classic distance');
close(1);

// ------------------------------------------------------
// Some statistics
// ------------------------------------------------------
print_my_filter(FLT0);
print_my_filter(FLT1);
print_my_filter(FLT2);
printf('Integration method: %s\n', INTR);
printf('\nDistClassicRaw: %.2fm .. %.2fm, $=%.2fm\n', min(DistClassicRaw), max(DistClassicRaw), DistClassicRaw($));
printf('DistClassic: %.2fm .. %.2fm, $=%.2fm\n', min(DistClassic), max(DistClassic), DistClassic($));
printf('DistRaw: %.2fm .. %.2fm, $=%.2fm\n', min(DistRaw), max(DistRaw), DistRaw($));
printf('Dist: %.2fm .. %.2fm, $=%.2fm\n', min(Dist), max(Dist), Dist($));
