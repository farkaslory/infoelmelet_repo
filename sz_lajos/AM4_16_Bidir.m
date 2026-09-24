function [TurboErr, n, BlockLengthHalf, place] = AM4_16_Bidir(H, maxFrames, K, snrRange, calcPlace, mMid)
% AM4_16_Bidir  Ketiranyu (kozepen talalkozo) szukcessziv dekodolas, 4-QAM / 16-QAM.
%
% Az ADO pontosan ugyanaz, mint az AM4_16-ban:
%   blokk 1      : 4-QAM,  1. kodszo elso fele
%   blokk j+1    : 16-QAM, DURVA = (j+1). kodszo eleje, FINOM = j. kodszo vege   (j = 1..K-1)
%   blokk K+1    : 4-QAM,  K. kodszo masodik fele
%
% A VEVO ket vegerol indul es az mMid. kodszonal talalkozik:
%   ELORE  (j = 1 .. mMid-1): mint az AM4_16. A j. kodszot a (tisztitott) j. blokk
%          4-QAM-jabol + a (j+1). blokk FINOM bitjeibol dekodolom, majd a finom
%          reszt levonom a (j+1). blokkbol -> 4-QAM marad, zaj x 5/4.
%   HATRA  (j = K .. mMid+1): a j. kodszot a (tisztitott) (j+1). blokk 4-QAM-jabol
%          + a j. blokk DURVA bitjeibol dekodolom, majd a durva reszt levonom a
%          j. blokkbol -> a FINOM 4-QAM marad (a (j-1). kodszo vege), zaj x 5.
%   KOZEP  (j = mMid): mindket fele mar tisztitott 4-QAM, ezt dekodolom utoljara.
%
%% --- Alapertelmezett parameterek -----------------------------------------
if nargin < 5 || isempty(calcPlace), calcPlace = 0;        end
if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end
if nargin < 6 || isempty(mMid),      mMid      = floor(K/2) + 1; end

maxIter = 10;   % belief propagation iteracioszam

%% --- Kodolo / dekodolo konfiguracio -------------------------------------
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;
nSym            = BlockLengthHalf / 2;

if mod(BlockLength,4) ~= 0
    error('AM4_16_Bidir:blockLength', ...
        'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end
if K < 1
    error('AM4_16_Bidir:K','K legalabb 1 kell legyen.');
end
if mMid < 1 || mMid > K || mMid ~= round(mMid)
    error('AM4_16_Bidir:mMid','mMid egesz kell legyen 1 es K (%d) kozott.', K);
end

%% --- Konstellaciok (azonos az AM4_16-tal) --------------------------------
symOrd4  = buildSymOrder(4);
symOrd16 = buildSymOrder(16);

FINE_SCALE = 1/sqrt(10);   % finom resz: s/sqrt(10), durva resz: 2*s/sqrt(10)

% ELORE tisztitas (finom levonva, durva marad): 2/sqrt(10) -> 1/sqrt(2)
FWD_GAIN  = sqrt(5)/2;
FWD_NVFAC = 5/4;
% HATRA tisztitas (durva levonva, finom marad): 1/sqrt(10) -> 1/sqrt(2)
BWD_GAIN  = sqrt(5);
BWD_NVFAC = 5;

%% --- Elofoglalas --------------------------------------------------------
TurboErr = zeros(1, numel(snrRange));
if calcPlace
    place = zeros(1, K);
else
    place = [];
end

data        = cell(1, K);
half1IQ     = cell(1, K);
half2IQ     = cell(1, K);
decodedData = cell(1, K);

% Blokkonkenti zajvariancia-szorzo (K+1 blokk). Minden keretben ujrainditva;
% a tisztitas ezt frissiti, igy a kozepso kodszonal nem kell esetszetvalasztas.
nvFac = ones(1, K+1);

%% --- Fo ciklus ----------------------------------------------------------
for snr_idx = 1:numel(snrRange)
    snr = snrRange(snr_idx);
    N0  = 10^(-snr/10);

    error_count = zeros(1, maxFrames);

    for k_idx = 1:maxFrames
        %% ---- Adatgeneralas + LDPC kodolas + I/Q csoportositas ----------
        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw      = double(ldpcEncode(data{j}, cfgLDPCEnc));
            cD      = reshape(cw, [2 BlockLengthHalf])';
            half1IQ{j} = reshape(cD(:,1), [2 nSym])';
            half2IQ{j} = reshape(cD(:,2), [2 nSym])';
        end

        %% ---- ADO (valtozatlan) ----------------------------------------
        input = zeros((K+1)*nSym, 1);
        input(1:nSym) = qammod(idx4(half1IQ{1}), 4, symOrd4, 'UnitAveragePower', true);
        for j = 1:K-1
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(idx16(half1IQ{j+1}, half2IQ{j}), 16, symOrd16, 'UnitAveragePower', true);
        end
        input(nSym*K+1 : nSym*(K+1)) = qammod(idx4(half2IQ{K}), 4, symOrd4, 'UnitAveragePower', true);

        %% ---- CSATORNA -------------------------------------------------
        output = awgn(input, snr, 'measured');

        %% ---- VEVO -----------------------------------------------------
        nvFac(:) = 1;
        blk = @(b) (nSym*(b-1)+1 : nSym*b);    % a b. blokk indexei

        % ===== ELORE: j = 1 .. mMid-1 =====================================
        for j = 1:mMid-1
            % Elso fel: a j. blokk tisztitott (j=1-nel eredeti) 4-QAM-ja
            llrA = qamdemod(output(blk(j)), 4, symOrd4, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0*nvFac(j));

            % Masodik fel: a (j+1). blokk FINOM bitjei (durvara marginalizalva)
            yB   = output(blk(j+1));
            llrB = qamdemod(yB, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0*nvFac(j+1));
            llrB = reshape(llrB, 4, nSym);                 % sorok: cI, fI, cQ, fQ
            llrFine = reshape(llrB([2 4], :), [], 1);

            LlrActual = [llrA, llrFine]';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

            % TISZTITAS: finom resz levonasa a (j+1). blokkbol
            cDe = reencodeHalves(decodedData{j}, cfgLDPCEnc, BlockLengthHalf);
            fIQ = reshape(cDe(:,2), [2 nSym])';
            knownFine = ((1 - 2*fIQ(:,1)) + 1i*(1 - 2*fIQ(:,2))) * FINE_SCALE;

            output(blk(j+1)) = (yB - knownFine) * FWD_GAIN;
            nvFac(j+1)       = nvFac(j+1) * FWD_NVFAC;
        end

        % ===== HATRA: j = K .. mMid+1 =====================================
        for j = K:-1:mMid+1
            % Masodik fel: a (j+1). blokk tisztitott (j=K-nal eredeti) 4-QAM-ja
            llrB2 = qamdemod(output(blk(j+1)), 4, symOrd4, 'UnitAveragePower', true, ...
                             'OutputType', 'llr', 'NoiseVariance', N0*nvFac(j+1));

            % Elso fel: a j. blokk DURVA bitjei (finomra marginalizalva)
            yA   = output(blk(j));
            llrA = qamdemod(yA, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0*nvFac(j));
            llrA = reshape(llrA, 4, nSym);                 % sorok: cI, fI, cQ, fQ
            llrCoarse = reshape(llrA([1 3], :), [], 1);

            LlrActual = [llrCoarse, llrB2]';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

            % TISZTITAS: durva resz levonasa a j. blokkbol -> a (j-1). kodszo
            % vegenek finom 4-QAM-ja marad
            cDe = reencodeHalves(decodedData{j}, cfgLDPCEnc, BlockLengthHalf);
            cIQ = reshape(cDe(:,1), [2 nSym])';
            knownCoarse = 2 * ((1 - 2*cIQ(:,1)) + 1i*(1 - 2*cIQ(:,2))) * FINE_SCALE;

            output(blk(j)) = (yA - knownCoarse) * BWD_GAIN;
            nvFac(j)       = nvFac(j) * BWD_NVFAC;
        end

        % ===== KOZEP: j = mMid, mindket fele tiszta 4-QAM =================
        % Elso fel: mMid. blokk  (elorefele tisztitva, ha mMid > 1)
        % Masodik fel: (mMid+1). blokk (hatrafele tisztitva, ha mMid < K)
        llrA = qamdemod(output(blk(mMid)), 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', N0*nvFac(mMid));
        llrB = qamdemod(output(blk(mMid+1)), 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', N0*nvFac(mMid+1));
        LlrActual = [llrA, llrB]';
        decodedData{mMid} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

        %% ---- Hibaszamitas ---------------------------------------------
        ErrCount = zeros(1, K);
        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        error_count(k_idx) = sum(ErrCount) / K;

        if calcPlace && any(ErrCount ~= 0)
            [~, j_max] = max(ErrCount);
            place(j_max) = place(j_max) + 1;
        end
    end

    TurboErr(snr_idx) = mean(error_count) / n;
end

end % ===================== AM4_16_Bidir vege =============================


%% ########################################################################
%  SEGEDFUGGVENYEK
%% ########################################################################

function cDe = reencodeHalves(infBits, cfgEnc, BlockLengthHalf)
% Dekodolt adatbol ujrakodolt kodszo, [paratlan, paros] oszlopokra bontva.
    cwEst = double(ldpcEncode(infBits, cfgEnc));
    cDe   = reshape(cwEst, [2 BlockLengthHalf])';
end

function x = idx4(bitsIQ)
% Onallo 4-QAM szimbolumindex: x = 2*bI + bQ
    x = 2*bitsIQ(:,1) + bitsIQ(:,2);
end

function x = idx16(coarseIQ, fineIQ)
% Kombinalt 16-QAM szimbolumindex: x = 8*cI + 4*fI + 2*cQ + fQ
    x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + 2*coarseIQ(:,2) + fineIQ(:,2);
end

function symOrd = buildSymOrder(M)
% Azonos az AM4_16 buildSymOrder-evel (nem Gray cimkezes, ellenorizve).
    s = @(b) 1 - 2*b;
    labels = (0:M-1)';

    switch M
        case 4
            bI = bitget(labels, 2);  bQ = bitget(labels, 1);
            wanted = (s(bI) + 1i*s(bQ)) / sqrt(2);
        case 16
            cI = bitget(labels, 4);  fI = bitget(labels, 3);
            cQ = bitget(labels, 2);  fQ = bitget(labels, 1);
            wanted = ((2*s(cI) + s(fI)) + 1i*(2*s(cQ) + s(fQ))) / sqrt(10);
        otherwise
            error('AM4_16_Bidir:buildSymOrder','Csak M = 4 es M = 16 tamogatott.');
    end

    C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);

    pos = zeros(M,1);
    for x = 0:M-1
        [d, p] = min(abs(C0 - wanted(x+1)));
        if d > 1e-9
            error('AM4_16_Bidir:buildSymOrder', ...
                'A kivant konstellacios pont nem szerepel a qammod raccsan (M=%d).', M);
        end
        pos(x+1) = p;
    end
    if numel(unique(pos)) ~= M
        error('AM4_16_Bidir:buildSymOrder','A hozzarendeles nem bijektiv (M=%d).', M);
    end

    symOrd = zeros(1, M);
    symOrd(pos(:)') = 0:M-1;

    if maxdev(symOrd, M, wanted) > 1e-9
        symOrd = (pos - 1)';
        if maxdev(symOrd, M, wanted) > 1e-9
            error('AM4_16_Bidir:buildSymOrder', ...
                'Nem sikerult megfelelo symOrder-t talalni (M=%d).', M);
        end
    end
end

function d = maxdev(symOrd, M, wanted)
    chk = qammod((0:M-1)', M, symOrd, 'UnitAveragePower', true);
    d = max(abs(chk - wanted));
end
