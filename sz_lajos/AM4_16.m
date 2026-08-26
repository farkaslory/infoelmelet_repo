function [TurboErr, n, BlockLengthHalf, place] = AM4_16(H, maxFrames, K, snrRange, calcPlace)
% AM4_16  Szimulacios mag az AAC lanchoz, 4-QAM / 16-QAM modulacioval.
%
% Az AM2_4 (BPSK/QPSK) parja: ugyanaz a lanc-logika, de tengelyenkent ket
% bittel, azaz 4-QAM es 16-QAM blokkokkal. A kulso kod LDPC, a dekodolas
% belief propagation (ldpcDecode), a kod a paritasellenorzo matrixaval van
% megadva -- nem oktalis generatorpolinommal + pattern-nel.
%
% Bemenetek:
%   H         - Paritasellenorzo matrix (ritka/sparse logikai matrix)
%   maxFrames - Szimulalt keretek szama SNR pontonkent   (alap: 1000)
%   K         - Kodolt blokkok (kodszavak) szama a lancban (alap: 20)
%   snrRange  - SNR tartomany vektor [dB]                (alap: 1:0.5:5)
%   calcPlace - (0/1) a 'place' hibaeloszlas-vektor szamitasa (alap: 0)
%
% Kimenetek:
%   TurboErr        - BER vektor, snrRange-el azonos hosszu
%   n               - Informacios bitek szama kodszavankent
%   BlockLengthHalf - Fel kodszohossz BITben (= BlockLength/2), ugyanaz a
%                     jelentes, mint az AM2_4-ben. A SZIMBOLUMok szama
%                     blokkonkent ennek a fele (nSym), mert itt tengelyenkent
%                     ket bit megy egy szimbolumba.
%   place           - Hibaeloszlas a lancban, [] ha calcPlace == 0
%
% Drop-in csere az AM2_4 helyett, pl. a batchSimu.m-ben:
%   [TurboErr,n,BlockLengthHalf,place] = AM4_16(H_sparse, maxFrames, K, snrRange, 1);
%
% FIGYELEM a kiertekelesnel: azonos SNR mellett ez a valtozat KETSZER annyi
% bitet visz at szimbolumonkent, mint az AM2_4. Az awgn 'measured' modban az
% SNR = Es/N0, ezert a ket gorbe kozvetlenul NEM hasonlithato ossze; fair
% osszevetesehez Eb/N0 = Es/N0 - 10*log10(bit/szimbolum) atszamitas kell.

%% --- Alapertelmezett parameterek (1..5 argumentum) -----------------------
if nargin < 5 || isempty(calcPlace), calcPlace = 0;        end
if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end

maxIter = 10;   % belief propagation iteracioszam (mint az AM2_4-ben)

%% --- Kodolo / dekodolo konfiguracio -------------------------------------
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;     % fel kodszo BITben (AM2_4-kompatibilis)
nSym            = BlockLengthHalf / 2; % SZIMBOLUM blokkonkent

if mod(BlockLength,4) ~= 0
    error('AM4_16:blockLength', ...
        ['A kodszohossz (%d) nem oszthato 4-gyel. A 4-QAM/16-QAM csoportositas ' ...
         'tengelyenkent 2 bitet igenyel, ezert BlockLength/4 egesz kell legyen.'], BlockLength);
end
if K < 1
    error('AM4_16:K','K legalabb 1 kell legyen.');
end

%% --- Konstellaciok: sajat (NEM Gray) cimkezes, ellenorzott symOrder-rel --
% A lanc mukodesenek felteteles: a finom bit hozzajarulasa MINDIG +-1 legyen,
% fuggetlenul a durva bittol -- kulonben a kivonashoz ismerni kellene a durva
% bitet, amit epp a kivonassal akarunk kinyerni. A qammod Gray-leképezese
% ezt megsertene, ezert sajat symOrder-t epitunk es le is ellenorizzuk.
symOrd4  = buildSymOrder(4);
symOrd16 = buildSymOrder(16);

% A finom resz hozzajarulasa a 16-QAM-ban, amit a tisztitaskor kivonunk.
% level = 2*s(coarse) + s(fine),  sym = (levelI + 1i*levelQ)/sqrt(10)
FINE_SCALE  = 1/sqrt(10);
% Visszaskalazas: a maradek amplitudoja 2/sqrt(10), egy onallo 4-QAM-e
% 1/sqrt(2)  ->  a hanyados sqrt(5)/2. A zaj ezzel 5/4-szeresre no.
CLEAN_GAIN  = sqrt(5)/2;
CLEAN_NVFAC = 5/4;

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

    % Teljes (komplex) zajvariancia egysegnyi atlagteljesitmenyu jelnel.
    % A qamdemod 'NoiseVariance'-a is ezt varja (nem a tengelyenkentit).
    N0 = 10^(-snr/10);

    error_count = zeros(1, maxFrames);

    for k_idx = 1:maxFrames
        %% ---- Adatgeneralas + LDPC kodolas + I/Q csoportositas ----------
        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw      = double(ldpcEncode(data{j}, cfgLDPCEnc));   % BlockLength x 1
            cD      = reshape(cw, [2 BlockLengthHalf])';         % oszlop1 = paratlan, oszlop2 = paros
            half1IQ{j} = reshape(cD(:,1), [2 nSym])';            % nSym x 2  (oszlop1 = I bit, oszlop2 = Q bit)
            half2IQ{j} = reshape(cD(:,2), [2 nSym])';
        end

        %% ---- ADO: 4-QAM | 16-QAM x (K-1) | 4-QAM ----------------------
        input = zeros((K+1)*nSym, 1);

        % 1. blokk: onallo 4-QAM, az 1. kodszo elso fele
        input(1:nSym) = qammod(idx4(half1IQ{1}), 4, symOrd4, 'UnitAveragePower', true);

        % 2..K. blokk: DURVA = (j+1). kodszo eleje, FINOM = j. kodszo vege
        for j = 1:K-1
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(idx16(half1IQ{j+1}, half2IQ{j}), 16, symOrd16, 'UnitAveragePower', true);
        end

        % Utolso blokk: onallo 4-QAM, a K. kodszo masodik fele
        input(nSym*K+1 : nSym*(K+1)) = qammod(idx4(half2IQ{K}), 4, symOrd4, 'UnitAveragePower', true);

        %% ---- CSATORNA -------------------------------------------------
        output = awgn(input, snr, 'measured');

        %% ---- VEVO: szukcessziv lanc-dekodolas --------------------------
        ErrCount = zeros(1, K);

        for j = 1:K-1
            % 1. fel: a j. blokk. j=1-nel erintetlen, kesobb a cleanBlock
            % mar visszaskalazta -- ilyenkor a zaj is 5/4-szeres.
            if j == 1
                nvA = N0;
            else
                nvA = N0 * CLEAN_NVFAC;
            end
            yA = output(nSym*(j-1)+1 : nSym*j);
            llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', nvA);   % [I;Q] szimbolumonkent

            % 2. fel: a finom bitek a MEG kombinalt 16-QAM blokkbol. A qamdemod
            % LLR-je szimbolumonkent [cI; fI; cQ; fQ], mindegyik a tobbire
            % marginalizalva -- a finom bitek LLR-je tehat a durva bitre
            % marginalizalt, pontosan ahogy kell.
            yB   = output(nSym*j+1 : nSym*(j+1));
            llrB = qamdemod(yB, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
            llrB = reshape(llrB, 4, nSym);              % sorok: cI, fI, cQ, fQ
            llrFine = reshape(llrB([2 4], :), [], 1);   % [fI; fQ] szimbolumonkent

            % OSSZEILLESZTES: a kodszo paratlan bitjei llrA-bol, a parosak
            % llrFine-bol. Innentol a ket ag RELATIV skalaja szamit, ezert
            % kellett a CLEAN_GAIN / CLEAN_NVFAC parost konzisztensen tartani.
            LlrActual = [llrA, llrFine]';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

            % TISZTITAS: a most dekodolt kodszo FINOM bitjeinek pontosan ismert
            % hozzajarulasat levonjuk, majd visszaskalazzuk 4-QAM amplitudora.
            cwEst = double(ldpcEncode(decodedData{j}, cfgLDPCEnc));
            cDe   = reshape(cwEst, [2 BlockLengthHalf])';
            fIQ   = reshape(cDe(:,2), [2 nSym])';
            knownFine = ((1 - 2*fIQ(:,1)) + 1i*(1 - 2*fIQ(:,2))) * FINE_SCALE;

            output(nSym*j+1 : nSym*(j+1)) = (yB - knownFine) * CLEAN_GAIN;
        end

        % Utolso kodszo: mindket fele mostanra tiszta 4-QAM.
        if K == 1
            nvA = N0;                 % K=1-nel nincs 16-QAM blokk, semmi nem lett tisztitva
        else
            nvA = N0 * CLEAN_NVFAC;   % a K. blokk atesett a cleanBlock-on
        end
        yA = output(nSym*(K-1)+1 : nSym*K);
        yB = output(nSym*K+1     : nSym*(K+1));
        llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', nvA);
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

end % ===================== AM4_16 vege ===================================


%% ########################################################################
%  SEGEDFUGGVENYEK
%% ########################################################################

function x = idx4(bitsIQ)
% Onallo 4-QAM szimbolumindex.  bitsIQ: nSym x 2 (oszlop1 = I bit, oszlop2 = Q bit)
% Cimke: x = 2*bI + bQ,  pont = (s(bI) + 1i*s(bQ))/sqrt(2),  s(b) = 1-2b
    x = 2*bitsIQ(:,1) + bitsIQ(:,2);
end

function x = idx16(coarseIQ, fineIQ)
% Kombinalt 16-QAM szimbolumindex.
% Cimke: x = 8*cI + 4*fI + 2*cQ + fQ
% Pont : ((2*s(cI) + s(fI)) + 1i*(2*s(cQ) + s(fQ)))/sqrt(10)
% A durva bit hozzajarulasa (+-2) mindig nagyobb a finomenal (+-1), ezert a
% durva bit valasztja ki a negyedet, fuggetlenul a finom bit ertekétol.
    x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + 2*coarseIQ(:,2) + fineIQ(:,2);
end

function symOrd = buildSymOrder(M)
% Olyan symOrder vektort ad vissza, amellyel a qammod/qamdemod a fenti
% (NEM Gray) cimkezest hasznalja. A vektort nem beegetjuk, hanem a kivant
% konstellaciohoz keressuk meg, es le is ellenorizzuk -- igy egy esetleges
% MATLAB-verziofuggo symOrder-szemantika hangosan elhasal, nem csendben
% rossz eredmenyt ad.
%
%   M = 4  : x = 2*bI + bQ            -> (s(bI) + 1i*s(bQ))/sqrt(2)
%   M = 16 : x = 8cI + 4fI + 2cQ + fQ -> ((2s(cI)+s(fI)) + 1i*(2s(cQ)+s(fQ)))/sqrt(10)

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
            error('AM4_16:buildSymOrder','Csak M = 4 es M = 16 tamogatott.');
    end

    % Referencia: identitas-permutacioval a qammod a sajat "racs" sorrendjet adja.
    C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);

    % Minden sajat cimkehez megkeressuk, melyik racspoziciora esik.
    pos = zeros(M,1);
    for x = 0:M-1
        [d, p] = min(abs(C0 - wanted(x+1)));
        if d > 1e-9
            error('AM4_16:buildSymOrder', ...
                'A kivant konstellacios pont nem szerepel a qammod raccsan (M=%d).', M);
        end
        pos(x+1) = p;
    end
    if numel(unique(pos)) ~= M
        error('AM4_16:buildSymOrder','A hozzarendeles nem bijektiv (M=%d).', M);
    end

    % 1. jelolt: symOrder(pozicio) = cimke   (dokumentalt szemantika)
    symOrd = zeros(1, M);
    symOrd(pos(:)') = 0:M-1;

    if maxdev(symOrd, M, wanted) > 1e-9
        % 2. jelolt: az inverz permutacio, ha a szemantika forditott lenne
        symOrd = (pos - 1)';
        if maxdev(symOrd, M, wanted) > 1e-9
            error('AM4_16:buildSymOrder', ...
                ['Nem sikerult olyan symOrder-t talalni, amellyel a qammod a kivant ' ...
                 '(nem Gray) cimkezest adja (M=%d). Ellenorizd a Communications Toolbox ' ...
                 'verziojat.'], M);
        end
    end
end

function d = maxdev(symOrd, M, wanted)
% A jelolt symOrder-rel eloallo konstellacio elterese a kivanttol.
    chk = qammod((0:M-1)', M, symOrd, 'UnitAveragePower', true);
    d = max(abs(chk - wanted));
end
