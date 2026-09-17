function [Ldpc_ErrP, n, BlockLengthHalf] = Sync_LDPC_16(H, maxFrames, snrRange)
% SYNC_LDPC Szinkron referencia átvitel QPSK modulációval és LDPC/BP dekódolással.
%
% Bemenetek:
%   H         - Paritásellenőrző mátrix (sparse logical)
%   maxFrames - Keretek száma SNR pontonként (alapértelmezett: 1000)
%   snrRange  - SNR vektor [dB]             (alapértelmezett: 2:0.5:8)
%
% Kimenetek:
%   Ldpc_ErrP       - Átlagos bithibaarány (BER) vektor
%   n               - Információs bitek száma blokkonként
%   BlockLengthHalf - Fél kódszóhossz bitben

if nargin < 3 || isempty(snrRange),  snrRange  = 2:0.5:8; end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;    end

cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength / 2;
maxnumiter      = 10; % Belief Propagation iterációszám (megegyezik az AM2_4-gyel)

Ldpc_ErrP = zeros(1, length(snrRange));

for s_idx = 1:length(snrRange)
    snr = snrRange(s_idx);
    hiba = zeros(1, maxFrames);
    N0 = 10^(-snr/10);

    parfor k = 1:maxFrames
        data = randi([0 1], n, 1, 'int8');
        codedData = ldpcEncode(data, cfgLDPCEnc);

        % Független QPSK szimbólumok képzése (2 bit / szimbólum)
        cD1 = reshape(codedData, 4, [])';
        input1 = bi2de(cD1, "left-msb");
        input = qammod(input1, 16, "UnitAveragePower",true);

        output = awgn(input, snr, 'measured');
        output1 = qamdemod(output, 16,'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);

        decodedData = ldpcDecode(output1, cfgLDPCDec, maxnumiter);
        hiba(k) = biterr(data, decodedData);
    end

    Ldpc_ErrP(s_idx) = mean(hiba) / n;
end
end