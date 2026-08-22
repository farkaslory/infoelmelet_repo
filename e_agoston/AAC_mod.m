clear;
inputFolderName = 'WiMax alist';% a file nevének a formátumának olyannak kell lennie, hogy:
%"*File neve* alist", ez azért kell hogy majd az output file lehessen ugyan ilyen néven, csupán az mat
outputFolderName = strrep(inputFolderName, 'alist', 'mat');
if ~exist(outputFolderName, 'dir')
    mkdir(outputFolderName);
end
fileList = dir(fullfile(inputFolderName, '*.alist.txt'));
folderSize = length(fileList);
for i = 1:folderSize
    % A file létrehozása:
    currentFileName = fileList(i).name;
    inputPath = fullfile(inputFolderName, currentFileName);
    [~,baseName,~] = fileparts(currentFileName);% itt leválasztjuk afile nevét, pl hogy wimax_0.75A
    baseName = strrep(baseName,'.alist','');
    outputPath = fullfile(outputFolderName, [char(baseName), '.mat']);

    %Ez az algo
    [H, N, M] = read_alist(inputPath); % jekk ehhez a read_alist() function
    cfgLDPCEnc = ldpcEncoderConfig(H);
    numframes = 1;
    cfgLDPCDec = ldpcDecoderConfig(H);
    n = N-M;
    BlockLengthHalf = N/2;
    K = 20; % Number of codewords to process
    LdpcErr_2=[];
    place=zeros(1,K);% Itt eredetileg az volt, hogy place zeros(1,20)
    % Pici módosításokat tettem a kódba.
    snr_range = 1:0.1:10;% Hogy ne legyen 2 órás a futás idő, ezt érdemes sok file esetén (2+) lejjebb venni.
    %Mehetne 2-3-tól, hogy ne legyen benne rossz(?)

        %ide a levinek a cucca, vagy egyéb algoritmus.
    
        %

    save(outputPath, 'BlockLengthHalf', 'n','K','LdpcErr_2', 'snr_range');
    fprintf("Mentve %s.mat\n", baseName);
    %ide lehet Plot-os fv.-eket ranki, vagy külön programot
end
function output=Code(InfBits,Params)
output = ldpcEncode(InfBits,Params);
end
function EstimatedInfBits=Decode(LogLikelihoodRation,Params)
maxnumiter = 10;
EstimatedInfBits = ldpcDecode(LogLikelihoodRation,Params,maxnumiter);
end