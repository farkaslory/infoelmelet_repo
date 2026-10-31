nev='ieee_802_11ad_p42_n672_r081' %[output:12bec785]
fig = figure();
    ax = axes(fig); hold(ax, "on");
load([nev,'_Sync_16QAM'])
[vx, vy]   = filterValidPoints(snrRange, ber);
semilogy(vx,vy,'yo--');
set(ax, YScale="log");
load([nev,'_AM4_16'])
[vx, vy]   = filterValidPoints(snrRange, ber);
semilogy(vx,vy,'bo-');
load([nev,'_AM4_16_Bidir'])
[vx, vy]   = filterValidPoints(snrRange, ber);
semilogy(vx,vy,'go-');
load([nev,'_AM4_16_Gray']);
[vx, vy]   = filterValidPoints(snrRange, ber);
semilogy(vx,vy,'co-');
load([nev,'_AM4_16_Soft'])
[vx, vy]   = filterValidPoints(snrRange, ber);
semilogy(vx,vy,'mo-');
exportgraphics(fig, [nev,'.png'], Resolution=300);
close(fig);

function [vx, vy] = filterValidPoints(x, y)
mask = ~isnan(y) & ~isinf(y) & (y > 0);
vx = x(mask);
vy = y(mask);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[output:12bec785]
%   data: {"dataType":"textualVariable","outputData":{"name":"nev","value":"'ieee_802_11ad_p42_n672_r081'"}}
%---
