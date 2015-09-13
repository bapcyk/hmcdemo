// columns in CSV file
AX = 4; AY = 5; AZ = 6;

// ------------------------------------------------------
// Some functions
// ------------------------------------------------------
function [Iv,Tv] = simpsintegral(V, T)
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

// Shift signal after filtering (for plotting)
function VV = shift_filtered(V, varargin)
    VV = V;
    for ord = varargin
        // ord{:} - content of cell
        VV = cat(1, VV(ord:$), VV(1:ord-1));
    end
endfunction

// Normalization signal before and after
function N = normsig(Before, After)
    N = After * msd(Before)/msd(After);
endfunction

// ------------------------------------------------------
// Settings
// ------------------------------------------------------
FILE = 'c:/prj/hmcdemo/src/math/a3.csv'; // input file
AXIS = AZ; // what axis to process
Td = 0.1; // sampling period

// ------------------------------------------------------
// FIR filters setup
// ------------------------------------------------------
// acceleration first FIR
FIR0enable = 1;
FIR0ord = 16;
FIR0type = 'hp';
FIR0fc = 2;
FIR0fnyq = (1/Td)/2;
FIR0fn = FIR0fc/FIR0fnyq;
FIR0b = wfir(FIR0type, FIR0ord, [FIR0fn,-1], 'hm', []);
//[t,f,fr] = wfir(FIR0type, FIR0ord, [FIR0fn,-1], 'hm', []);
//[hm,fr] = frmag(t, FIR0ord);
//plot(fr, hm);

// acceleration second FIR
FIR1enable = 1;
FIR1ord = 16;
FIR1type = 'lp';
FIR1fc = 2.5;
FIR1fnyq = (1/Td)/2;
FIR1fn = FIR1fc/FIR1fnyq;
FIR1b = wfir(FIR1type, FIR1ord, [FIR1fn,-1], 'hm', []);

// speed
FIR2enable = 1;
FIR2ord = 16;
FIR2type = 'lp';
FIR2fc = 0.9;
FIR2fnyq = (1/Td)/2;
FIR2fn = FIR2fc/FIR2fnyq;
FIR2b = wfir(FIR2type, FIR2ord, [FIR2fn,-1], 'hm', []);

// distance
FIR3enable = 1;
FIR3ord = 16;
FIR3type = 'lp';
FIR3fc = 0.7;
FIR3fnyq = (1/Td)/2;
FIR3fn = FIR3fc/FIR3fnyq;
FIR3b = wfir(FIR3type, FIR3ord, [FIR3fn,-1], 'hm', []);


// ------------------------------------------------------
// Main program
// ------------------------------------------------------
data=evstr(read_csv(FILE, ';'));
nrows = length(data(:, 1));
AccRaw = data(:,AXIS) * 9.81;
Acc = AccRaw;
// times moments
AccT = 0:Td:Td*(length(Acc)-1);

if (FIR0enable == 1)
    Acc = filter(FIR0b, 1, Acc);
end
if (FIR1enable == 1)
    Acc = filter(FIR1b, 1, Acc);
end

//Acc = shift_filtered(Acc, FIR0ord*FIR0enable, FIR1ord*FIR1enable);
//AccK = stdev(AccRaw)/stdev(Acc);
//Acc = Acc * AccK;
//Acc = normsig(AccRaw, Acc);

[Speed, SpeedT] = simpsintegral(Acc', Td);

N = length(Speed);
SpeedRaw = Speed;

if (FIR2enable == 1)
    Speed = filter(FIR2b, 1, Speed);
end
//SpeedK = stdev(SpeedRaw)/stdev(Speed);
//Speed = SpeedK * Speed;
//Speed = normsig(SpeedRaw, Speed);

//Speed = shift_filtered(Speed, FIR2ord*FIR2enable);

[Dist, DistT] = simpsintegral(Speed', Td*2);
DistRaw = Dist;

if (FIR3enable == 1)
    Dist = filter(FIR3b, 1, Dist);
end

// distance in classic cinematic formula
DistClassicRaw = Acc' .* (AccT.^2) / 2;
DistClassic = AccRaw' .* (AccT.^2) / 2;

// ------------------------------------------------------
// Plotting
// ------------------------------------------------------
//figure(1);

subplot(4, 1, 1);
plot(AccT, AccRaw, AccT, Acc, 'r');
title('acceleration');

subplot(4, 1, 2);
plot(SpeedT, SpeedRaw, SpeedT, Speed, 'r');
title('speed');

subplot(4, 1, 3);
plot(DistT, DistRaw, DistT, Dist, 'r');
title('distance');

subplot(4, 1, 4);
plot(AccT, DistClassicRaw, AccT, DistClassic, 'r');
title('classic distance');
