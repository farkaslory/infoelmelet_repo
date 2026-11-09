function [Ldpc_ErrP, n, BlockLength, place] = Sync_LDPC_16_V2(H, maxFrames, K, snrRange)
% SYNC_LDPC Szinkron referencia átvitel QPSK modulációval és LDPC/BP dekódolással.
%
% Bemenetek:
%   H         - Paritásellenőrző mátrix (sparse logical)
%   maxFrames - Keretek száma SNR pontonként (alapértelmezett: 20000)
%   snrRange  - SNR vektor [dB]             (alapértelmezett: 5:25)
%
% Kimenetek:
%   Ldpc_ErrP       - Átlagos bithibaarány (BER) vektor
%   n               - Információs bitek száma blokkonként
%   BlockLengthHalf - Fél kódszóhossz bitben

if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end


cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = cfgLDPCDec.BlockLength / 2;
nSym            = BlockLengthHalf / 2; 
maxnumiter      = 10; % Belief Propagation iterációszám (megegyezik az AM2_4-gyel)

Ldpc_ErrP = zeros(1, length(snrRange));

for s_idx = 1:length(snrRange)
    snr = snrRange(s_idx);
    hiba = zeros(1, maxFrames);
    N0 = 10^(-snr/10);

    parfor k = 1:maxFrames
        data        = cell(1, K);
        cw          = cell(1, K);
        decodedData = cell(1, K);
        rng(k);
        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw{j}      = double(ldpcEncode(data{j}, cfgLDPCEnc));
        end

        input = zeros(K*nSym, 1);
        % Független QPSK szimbólumok képzése (4 bit / szimbólum)
        for j = 0:K-1
            cD1 = reshape(cw{j+1}, 4, [])';
            input1 = bi2de(cD1, "left-msb");
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(input1, 16, "UnitAveragePower",true);
        end

        output = awgn(input, snr, 'measured',2830459031+k);
        ErrCount = zeros(1, K);

        for j = 1:K
            yA = output(nSym*(j-1)+1 : nSym*j);
            outputllr = qamdemod(yA, 16,'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
            decodedData{j} = ldpcDecode(outputllr, cfgLDPCDec, maxnumiter);
        end

        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        hiba(k) = sum(ErrCount) / K;
    end
    Ldpc_ErrP(s_idx) = mean(hiba) / n;
    place=[];
end
end