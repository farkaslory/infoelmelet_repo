trellis = poly2trellis(7,[115 147],147);
ErrP=[]
n=700

for snr=1:0.1:10
    hiba=zeros(1,20000);
    parfor k=1:20000
        data = randi([0 1],n,1);
        codedData = convenc(data,trellis);
        cD1=reshape(codedData,[2,n])';
        input1=bi2de(cD1,"left-msb");
        input = pskmod(input1,4,pi/4);
        %scatterplot(input)
        output = awgn(input,snr);
        %scatterplot(output1)
        output1 = pskdemod(output,4,pi/4,OutputType="llr");
        tbdepth = 60; % Traceback depth for Viterbi decoder
        decodedData = vitdec(output1,trellis,tbdepth,'trunc','unquant');
        hiba(k)=biterr(data,decodedData);
    end
    ErrP(end+1)=mean(hiba)/n;
    snr
end
semilogy(snr,ErrP)