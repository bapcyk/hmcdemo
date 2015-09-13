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

// Leo Ticks method
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
            I = I_1 + h*(0.3584*y + 1.2832*y_1 + 0.3584*y_2);
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

function P = p(metr, V1, V0)
    select metr
        case 1
            P = sum(abs(V1 - V0));
        case 2
            P = sqrt(sum((V1 - V0)^2));
        case 3
            P = max(abs(V1 - V0));
    end
endfunction

// test
td = 0.1;
T = [0:td:2*%pi];
expr = 'sin(%pi*T) - cos(10*%pi*T) + cos(20*%pi*T)';
S = eval(expr);
I0 = integrate(expr, 'T', 0, T);
I1 = smintegral(S, td);
I2 = trintegral(S, td);
I3 = ltintegral(S, td);

Iorig = I0';
printf("SIMPSON: %f %f %f\n", p(1, I1, Iorig), p(2, I1, Iorig), p(3, I1, Iorig));
printf("TRAPEZOID: %f %f %f\n", p(1, I2, Iorig), p(2, I2, Iorig), p(3, I2, Iorig));
printf("LEO TICK: %f %f %f\n", p(1, I3, Iorig), p(2, I3, Iorig), p(3, I3, Iorig));

figure(1);
scf(1);
clf(1);
plot(T, I0, '+black', T, S, 'g', T, I1, 'b', T, I2, 'r', T, I3, 'cyan');
title('Test integration methods');
close(1);