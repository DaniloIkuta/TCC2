%NSHS
function nshsSpec = TCCNshs(spectrogram, LTSpec, params, outPath, filename)
	[plotNshs, plotPartRem, weight] = ...
		textread("ConfigNshs.txt", "plotNshs = %f\n plotPartRem = %f\n weight = %f", 3, "commentstyle", "shell");

	binMax = floor(params(5) / params(9) * params(6));
	binMin = floor(params(4) / params(9) * params(6)) + 1;

	nshsSpec = zeros(size(spectrogram));

	%Acaba dividindo por 2
	%Faria alguma diferença se f = 0:binMax?
	%Provavelmente sim se binMin for > 20Hz...
	for f = binMin:binMax;
		Nf = floor(size(spectrogram, 1)*.5 / f);
		nshsSpec(f, :) = sum(weight.^((binMin:Nf)' - 1) .* spectrogram((binMin:Nf) * f, :), 1) ./ (sum(weight.^((binMin:Nf)' - 1)) + 1);
	endfor

	%plot, .wav
	nshsOutPath = char(cstrcat("NSHS(", num2str(weight), ")"));
	if(exist(strcat(outPath, nshsOutPath), "dir") != 7)
		mkdir(outPath, nshsOutPath);
	endif

	outPath = char(strcat(outPath, nshsOutPath, "/"));

	if(plotNshs == true && nargin() == 5)
		%NSHS
		nshsPlot = abs(nshsSpec(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-NSHS.png"));
		TCCPlotSpec(nshsPlot, params, saveName, 1);
		
		sig = TCCIstft(nshsSpec, params, params(9));
		audiowrite(strcat(outPath, filename, "-NSHS.wav"), sig, params(9));
	endif

	%Remocao parcial de instrumental
	nshsSpec(binMin:binMax, :) = nshsSpec(binMin:binMax, :) .* (LTSpec(binMin:binMax, :) > 0);

	%plot, .wav
	if(plotPartRem == true && nargin == 5)
		%Remocao parcial
		prPlot = abs(nshsSpec(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-NSHSPartRem.png"));
		TCCPlotSpec(prPlot, params, saveName, 1);

		sig = TCCIstft(nshsSpec, params, params(9));
		audiowrite(strcat(outPath, filename, "-NSHSPartRem.wav"), sig, params(9));
	endif

	clear -x nshsSpec
endfunction