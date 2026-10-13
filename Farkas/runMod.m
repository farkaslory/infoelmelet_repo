function res = runMod(funcName, H, opts)
% RUNMOD Univerzális modulációs szimuláció indító
%
% Bemenetek:
%   funcName - A futtatandó moduláció neve: "AM2_4", "AM4_16", "Sync_LDPC", "Sync_LDPC_16"
%   H        - Paritásellenőrző mátrix
%   opts     - Opcionális szimulációs paraméterek (Name=Value)

arguments
    funcName               (1,1) string
    H                      (:,:) {mustBeNumericOrLogical}
    opts.maxFrames         (1,1) double = 1000
    opts.snrRange          (1,:) double = 1:0.5:6
    opts.K                 (1,1) double = 20
    opts.calcPlace         (1,1) double = 1
    opts.bitsPerSymbol     (1,1) double = 2
end

% Ellenőrzés: létezik-e a hivatkozott fájl a környezetben
targetFunc = str2func(funcName);

fprintf("  -> [%s] szimuláció indítása...\n", funcName);

% Dinamikus dispatch a célszignatúrák szerint
switch funcName
    case "Sync_Ldpc"
        [ber, n, bl] = targetFunc(H, opts.K*opts.maxFrames, opts.snrRange);
        place = [];

    case "Sync_LDPC_16"
        [ber, n, bl] = targetFunc(H, opts.K*opts.maxFrames, opts.snrRange);
        place = [];

    otherwise
        [ber, n, bl, place] = targetFunc(H, opts.maxFrames, opts.K, opts.snrRange);
end

% Egységesített eredménystruktúra összeállítása
res = struct();
res.funcName        = funcName;
res.ber             = ber;
res.n               = n;
res.BlockLength     = bl;
res.place           = place;
res.snrRange        = opts.snrRange;
res.maxFrames       = opts.maxFrames;
res.K               = opts.K;
end