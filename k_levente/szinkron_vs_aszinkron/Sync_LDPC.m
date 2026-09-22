function [Ldpc_ErrP, n, BlockLengthHalf] = Sync_LDPC(H, maxFrames, snrRange, bitsPerSymbol)
% SYNC_LDPC Szinkron referencia átvitel választható modulációval (QPSK vagy 16-QAM)
%
% Bemenetek:
%   H             - Paritásellenőrző mátrix (sparse logical)
%   maxFrames     - Keretek száma SNR pontonként (alapértelmezett: 200)
%   snrRange      - SNR vektor [dB] (alapértelmezett: 2:0.5:8)
%   bitsPerSymbol - Szimbólumonkénti bitek száma: 
%                     2 -> QPSK  (AM2-4 összehasonlításhoz)
%                     4 -> 16-QAM (AM4-16 összehasonlításhoz)

    if nargin < 4 || isempty(bitsPerSymbol), bitsPerSymbol = 2; end
    if nargin < 3 || isempty(snrRange),      snrRange      = 1:0.5:6; end
    if nargin < 2 || isempty(maxFrames),     maxFrames     = 20000; end

    if bitsPerSymbol ~= 2 && bitsPerSymbol ~= 4
        error('Sync_LDPC:invalidModulation', 'Csak bitsPerSymbol = 2 (QPSK) vagy 4 (16-QAM) támogatott!');
    end

    cfgLDPCEnc = ldpcEncoderConfig(H);
    cfgLDPCDec = ldpcDecoderConfig(H);

    n           = cfgLDPCEnc.NumInformationBits;
    BlockLength = cfgLDPCDec.BlockLength;
    BlockLengthHalf = BlockLength / 2;
    maxnumiter  = 10;

    if mod(BlockLength, bitsPerSymbol) ~= 0
        error('Sync_LDPC:invalidBitLength', ...
            'A kódszóhossz (%d) nem osztható bitsPerSymbol-lal (%d)!', BlockLength, bitsPerSymbol);
    end

    nSym = BlockLength / bitsPerSymbol;
    Ldpc_ErrP = zeros(1, length(snrRange));

    % --- 1. ÁG: QPSK MODULÁCIÓ (2 bit/szimbólum) ---
    if bitsPerSymbol == 2
        for s_idx = 1:length(snrRange)
            snr = snrRange(s_idx);
            hiba = zeros(1, maxFrames);

            parfor k = 1:maxFrames
                data = randi([0 1], n, 1, 'int8');
                codedData = ldpcEncode(data, cfgLDPCEnc);

                cPairs = reshape(codedData, [2, nSym])';
                symIdx = bi2de(cPairs, "left-msb");
                tx = pskmod(symIdx, 4, pi/4);

                rx = awgn(tx, snr, 'measured');
                llr = pskdemod(rx, 4, pi/4, OutputType="llr");

                decodedData = ldpcDecode(llr, cfgLDPCDec, maxnumiter);
                hiba(k) = biterr(data, decodedData);
            end

            Ldpc_ErrP(s_idx) = mean(hiba) / n;
        end

    % --- 2. ÁG: 16-QAM MODULÁCIÓ (4 bit/szimbólum) ---
    else
        for s_idx = 1:length(snrRange)
            snr = snrRange(s_idx);
            N0  = 10^(-snr / 10);
            hiba = zeros(1, maxFrames);

            parfor k = 1:maxFrames
                data = randi([0 1], n, 1, 'int8');
                codedData = ldpcEncode(data, cfgLDPCEnc);

                cQuads = reshape(codedData, [4, nSym])';
                symIdx = bi2de(cQuads, "left-msb");
                tx = qammod(symIdx, 16, 'UnitAveragePower', true);

                rx = awgn(tx, snr, 'measured');
                llr = qamdemod(rx, 16, 'UnitAveragePower', true, ...
                               'OutputType', 'approxllr', 'NoiseVariance', N0);

                decodedData = ldpcDecode(llr, cfgLDPCDec, maxnumiter);
                hiba(k) = biterr(data, decodedData);
            end

            Ldpc_ErrP(s_idx) = mean(hiba) / n;
        end
    end
end