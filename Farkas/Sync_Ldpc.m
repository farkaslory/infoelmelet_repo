H = dvbs2ldpc(1/2);
cfgLDPCEnc = ldpcEncoderConfig(H);
numframes = 1;
cfgLDPCDec = ldpcDecoderConfig(H);
n = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength/2;trellis = poly2trellis(7,[115 147],147);
Ldpc_ErrP=[]
for snr=1:0.1:10
    hiba=zeros(1,20000);
    parfor k=1:20000
        data = randi([0 1],n,1);
        codedData = ldpcEncode(data,cfgLDPCEnc);
        cD1=reshape(codedData,[2,n])';
        input1=bi2de(cD1,"left-msb");
        input = pskmod(input1,4,pi/4);
        %scatterplot(input)
        output = awgn(input,snr);
        %scatterplot(output1)
        output1 = pskdemod(output,4,pi/4,OutputType="llr");
        maxnumiter = 10; % Number of Iteration for the belief-propagation decoder
        decodedData = ldpcDecode(output1,cfgLDPCDec,maxnumiter);
        hiba(k)=biterr(data,decodedData);
    end
    Ldpc_ErrP(end+1)=mean(hiba)/n;
    snr
end
semilogy(1:0.1:10,Ldpc_ErrP)