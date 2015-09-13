ord = 16;
r = 0.09;
nfc1 = 0.05; nfc2 = 0.4;
hn=eqfir(ord, [0 nfc1; nfc1+r nfc2-r; nfc2 0.5], [0 1 0], [1 1 1]);
[hm,fr]=frmag(hn,256);
plot(fr,hm);
