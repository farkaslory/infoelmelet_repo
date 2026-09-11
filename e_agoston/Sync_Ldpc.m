function [BlockLengthHalf, n, LdpcErr_2] = Sync_Ldpc(H, snr_range, numTrials)
% SYNC_LDPC  Egyfelhasznalos (nem szuperponalt), szinkron QPSK-s LDPC
% BER-szimulacio, parfor-ral parhuzamositva.
%
% Bemenet:
%   H         - parity-check matrix (mar "encoder-ready", pl. make_h_encodable utan)
%   snr_range - a lefuttatando SNR-ertekek (dB), pl. 2:0.5:8
%   numTrials - (opcionalis) probak szama SNR-ertekenkent, alapertelmezett 20000
%a
% Kimenet:
%   BlockLengthHalf - a H matrix N kodszohosszanak fele (QPSK szimbolumok szama / kodszo)
%   n               - az adott kodnak az infobit hossza (N-M)
%   LdpcErr_2       - BER-ertekek vektora, snr_range-nek megfelelo sorrendben
%
% Hasznalat a fo scriptben (a H mar make_h_encodable-on atesett valtozat legyen):
%   K = 1; % ebben a semaban nincs tobbszoros szuperpozicio, csak dokumentacios celra tartjuk meg
%   [BlockLengthHalf, n, LdpcErr_2] = Sync_Ldpc(H, snr_range);
%   save(outputPath, 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range');

if nargin < 2 || isempty(snr_range)
    snr_range = 2:0.5:8;     
end
if nargin < 3 || isempty(numTrials)
    numTrials = 20000;
end

%% LDPC encoder/decoder elokeszitese
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);
n = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength / 2;

%% Parhuzamos pool inditasa (ha meg nincs futo)
% FONTOS: ha ezt a fuggvenyt tobbszor hivod meg egymas utan (pl.
% fajlonkent egyszer a fo ciklusban), a sima parpool(15) minden hivaskor
% ujra probalna nyitni a poolt, ami hibat dobna, ha mar van egy nyitva.
% Ezert csak akkor nyitunk ujat, ha meg egy sincs.
if isempty(gcp('nocreate'))
    parpool(8); % Hany peldanyban fusson parhuzamosan: magok szama - 1 az ajanlott
end

%% LDPC szimulacio SNR-enkent
LdpcErr_2 = [];
for snr = snr_range
    errCounts = zeros(1, numTrials);
    parfor k = 1:numTrials
        data = randi([0 1], n, 1);
        codedData = ldpcEncode(data, cfgLDPCEnc);
        cD1 = reshape(codedData, [2, BlockLengthHalf])';   % FONTOS: n helyett BlockLengthHalf!
        input1 = bi2de(cD1, "left-msb");
        input = pskmod(input1, 4, pi/4);
        output = awgn(input, snr);
        output1 = pskdemod(output, 4, pi/4, OutputType="llr");
        maxnumiter = 10; % Number of Iteration for the belief-propagation decoder
        decodedData = ldpcDecode(output1, cfgLDPCDec, maxnumiter);
        errCounts(k) = biterr(data, decodedData);
    end
    LdpcErr_2(end+1) = mean(errCounts) / n;
    snr
end
end