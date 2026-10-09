function [TurboErr, n, BlockLengthHalf, place] = AM4_16_Gray(H, maxFrames, K, snrRange, calcPlace)
% AM4_16_Gray  Az AM4_16 lanc GRAY cimkezesu 16-QAM-mal.
%
% Az ADO szerkezete pontosan az AM4_16-e:
%   blokk 1      : 4-QAM,  1. kodszo elso fele
%   blokk j+1    : 16-QAM, DURVA = (j+1). kodszo eleje, FINOM = j. kodszo vege
%   blokk K+1    : 4-QAM,  K. kodszo masodik fele
% Egyetlen kulonbseg a 16-QAM cimkezese: a beepitett qammod(...,'gray').
% A cimke ugyanaz (x = 8*cI + 4*fI + 2*cQ + fQ), a MATLAB Gray-pontja:
%   I = -s(cI) * (2 + s(fI)),   Q = s(cQ) * (2 + s(fQ))   (/sqrt(10))
% A durva bit az elojel (az I tengelyen forditott polaritassal: cI = 0 a
% negativ oldal), a finom bit azt mondja meg, kulso (0) vagy belso (1) pont.
% Ezt a fuggveny indulaskor ellenorzi (checkGray16).
%
% A VEVO emiatt mashogy "tisztit": Gray mellett f hozzajarulasa c-tol fugg,
% ezert NEM vonhato le. Helyette FELTETELES DEMAPPING: a mar dekodolt f
% ismereteben a durva bitre csak a ket f-fel konzisztens jelolt marad,
%   x0 = +-(2+s(f))/sqrt(10),  x1 = -x0,
% es a ket pont LLR-je tengelyenkent (sigma^2 = N0/2):
%   L(cQ) =  4*(2+s(fQ))/(sqrt(10)*N0) * imag(y)
%   L(cI) = -4*(2+s(fI))/(sqrt(10)*N0) * real(y)   (forditott I-polaritas)
% A kuszob mindig 0, f csak az LLR nagysagat skalazza.
%
% Be- es kimenetek: azonosak az AM4_16-tal.
%   H, maxFrames (1000), K (20), snrRange (1:0.5:5), calcPlace (0)
%   TurboErr, n, BlockLengthHalf, place
%
% Drop-in csere, pl.:
%   [TurboErr,n,BlockLengthHalf,place] = AM4_16_Gray(H_sparse, maxFrames, K, snrRange, 1);

%% --- Alapertelmezett parameterek ----------------------------------------
if nargin < 5 || isempty(calcPlace), calcPlace = 0;        end
if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end

maxIter = 10;   % belief propagation iteracioszam (mint az AM4_16-ban)

%% --- Kodolo / dekodolo konfiguracio -------------------------------------
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;     % fel kodszo BITben (AM2_4-kompatibilis)
nSym            = BlockLengthHalf / 2; % SZIMBOLUM blokkonkent

if mod(BlockLength,4) ~= 0
    error('AM4_16_Gray:blockLength', ...
        'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end
if K < 1
    error('AM4_16_Gray:K','K legalabb 1 kell legyen.');
end

%% --- Konstellaciok ------------------------------------------------------
symOrd4  = 'gray';    % beepitett 4-QAM (mod es demod ugyanazzal -> konzisztens)
symOrd16 = 'gray';    % beepitett Gray 16-QAM
checkGray16();        % a coarseLlrGivenFine erre a pontkiosztasra epul

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

%% --- Fo ciklus ----------------------------------------------------------
for snr_idx = 1:numel(snrRange)
    snr = snrRange(snr_idx);
    N0  = 10^(-snr/10);          % teljes komplex zajvariancia (mint az AM4_16-ban)

    error_count = zeros(1, maxFrames);

    for k_idx = 1:maxFrames
        %% ---- Adatgeneralas + LDPC kodolas + I/Q csoportositas ----------
        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw      = double(ldpcEncode(data{j}, cfgLDPCEnc));
            cD      = reshape(cw, [2 BlockLengthHalf])';         % oszlop1 = paratlan, oszlop2 = paros
            half1IQ{j} = reshape(cD(:,1), [2 nSym])';            % nSym x 2 (oszlop1 = I bit, oszlop2 = Q bit)
            half2IQ{j} = reshape(cD(:,2), [2 nSym])';
        end

        %% ---- ADO: 4-QAM | 16-QAM x (K-1) | 4-QAM (valtozatlan) ---------
        input = zeros((K+1)*nSym, 1);
        input(1:nSym) = qammod(idx4(half1IQ{1}), 4, symOrd4, 'UnitAveragePower', true);
        for j = 1:K-1
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(idx16(half1IQ{j+1}, half2IQ{j}), 16, symOrd16, 'UnitAveragePower', true);
        end
        input(nSym*K+1 : nSym*(K+1)) = qammod(idx4(half2IQ{K}), 4, symOrd4, 'UnitAveragePower', true);

        %% ---- CSATORNA -------------------------------------------------
        output = awgn(input, snr, 'measured');

        %% ---- VEVO: szukcessziv lanc-dekodolas --------------------------
        ErrCount = zeros(1, K);
        fIQprev  = [];               % az elozo kodszo FINOM bitjei (nSym x 2), ujrakodolva

        for j = 1:K-1
            % 1. fel: a j. blokk.
            %   j = 1 : onallo 4-QAM, sima qamdemod.
            %   j > 1 : 16-QAM, a (j-1). kodszo f bitjei mar ismertek ->
            %           felteteles demapping a durva bitre (nincs kivonas).
            yA = output(nSym*(j-1)+1 : nSym*j);
            if j == 1
                llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                                'OutputType', 'llr', 'NoiseVariance', N0);   % [I;Q] szimbolumonkent
            else
                llrA = coarseLlrGivenFine(yA, fIQprev, N0);
            end

            % 2. fel: a FINOM bitek a meg kombinalt 16-QAM blokkbol,
            % a durva bitre marginalizalva (qamdemod pontos LLR).
            yB   = output(nSym*j+1 : nSym*(j+1));
            llrB = qamdemod(yB, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
            llrB = reshape(llrB, 4, nSym);              % sorok: cI, fI, cQ, fQ
            llrFine = reshape(llrB([2 4], :), [], 1);   % [fI; fQ] szimbolumonkent

            % OSSZEILLESZTES es dekodolas (mint az AM4_16-ban)
            LlrActual = [llrA, llrFine]';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

            % UJRAKODOLAS: a j. kodszo finom bitjei a (j+1). blokkban.
            % Itt NEM modositjuk az output-ot, csak eltaroljuk f-et a kovetkezo
            % korre.
            cwEst   = double(ldpcEncode(decodedData{j}, cfgLDPCEnc));
            cDe     = reshape(cwEst, [2 BlockLengthHalf])';
            fIQprev = reshape(cDe(:,2), [2 nSym])';
        end

        % Utolso kodszo: elso fele a K. blokkbol (16-QAM, ha K > 1),
        % masodik fele a K+1. blokk onallo 4-QAM-jabol.
        yA = output(nSym*(K-1)+1 : nSym*K);
        yB = output(nSym*K+1     : nSym*(K+1));
        if K == 1
            llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
        else
            llrA = coarseLlrGivenFine(yA, fIQprev, N0);
        end
        llrB = qamdemod(yB, 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', N0);
        LlrActual = [llrA, llrB]';
        decodedData{K} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

        %% ---- Hibaszamitas ---------------------------------------------
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

end % ===================== AM4_16_Gray vege ==============================


%% ########################################################################
%  SEGEDFUGGVENYEK
%% ########################################################################

function llr = coarseLlrGivenFine(y, fIQ, N0)
% Durva bitek LLR-je egy Gray 16-QAM blokkbol, ha a finom bitek ismertek.
%   y   : nSym x 1 komplex vett jel (UnitAveragePower skalan)
%   fIQ : nSym x 2 ismert finom bitek (oszlop1 = fI, oszlop2 = fQ)
%   N0  : teljes komplex zajvariancia, tengelyenkent sigma^2 = N0/2
% Pontkiosztas (qammod 'gray'): I = -s(cI)(2+s(fI)), Q = s(cQ)(2+s(fQ)).
% Kimenet: [cI; cQ] szimbolumonkent, oszlopvektorban -- ugyanabban a
% sorrendben, ahogy a 4-QAM qamdemod adja, igy kozvetlenul behelyettesitheto.
% Elojel-konvencio: pozitiv LLR = 0 bit (mint a qamdemod / ldpcDecode).
    s  = @(b) 1 - 2*b;
    aI = (2 + s(fIQ(:,1))) / sqrt(10);       % |x| az I tengelyen: 3 vagy 1 (/sqrt10)
    aQ = (2 + s(fIQ(:,2))) / sqrt(10);
    % L = (x0-x1)/sigma^2 * (y - m),  m = 0, sigma^2 = N0/2
    % Q: x0 = +aQ, x1 = -aQ.   I: cI = 0 a negativ oldal -> x0 = -aI, x1 = +aI.
    LI = -(2*aI) ./ (N0/2) .* real(y);
    LQ =  (2*aQ) ./ (N0/2) .* imag(y);
    llr = reshape([LI, LQ].', [], 1);
end

function x = idx4(bitsIQ)
% Onallo 4-QAM szimbolumindex: x = 2*bI + bQ
    x = 2*bitsIQ(:,1) + bitsIQ(:,2);
end

function x = idx16(coarseIQ, fineIQ)
% Kombinalt 16-QAM szimbolumindex (ugyanaz a cimke, mint az AM4_16-ban):
%   x = 8*cI + 4*fI + 2*cQ + fQ
% A pont viszont a qammod Gray-pontja: (-s(cI)(2+s(fI)) + 1i*s(cQ)(2+s(fQ)))/sqrt(10)
    x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + 2*coarseIQ(:,2) + fineIQ(:,2);
end

function checkGray16()
% Ellenorzi, hogy a qammod(...,'gray') a coarseLlrGivenFine altal feltetelezett
% pontkiosztast adja. Ha egy MATLAB-verzio mast adna, hangosan elhasal.
    s  = @(b) 1 - 2*b;
    L  = (0:15)';
    cI = bitget(L,4); fI = bitget(L,3); cQ = bitget(L,2); fQ = bitget(L,1);
    expected = (-s(cI).*(2 + s(fI)) + 1i*s(cQ).*(2 + s(fQ))) / sqrt(10);
    got = qammod(L, 16, 'gray', 'UnitAveragePower', true);
    if max(abs(got - expected)) > 1e-9
        error('AM4_16_Gray:grayMap', ...
            ['A qammod Gray-kiosztasa elter a vartatol; a coarseLlrGivenFine ' ...
             'elojeleit/sorrendjet igazitani kell.']);
    end
end
