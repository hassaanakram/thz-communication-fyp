figure('Name', 'THZ SINR Coverage at varying thz densities and constant power of -3dB or 27dBm. Lambda mmwave is 1x lambda mbs');
load('SINRCoverage.mat');
x = 10.*log10(logspace(-3, 1, 500));
for i= 1 : 5
    data = SINRCoverage(1, i, 2, 3, :, 3);
    data = squeeze(data);
    plot(x, data);
    hold on
end
thz = linspace(2,40,5);
leg = [];

for i = 1 : 5
leg = [leg, sprintf("%.2f", thz(i))];
end
legend(leg);
xlabel("SIMR Threshold dBm");
ylabel("Coverage");