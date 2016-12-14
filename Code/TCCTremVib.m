%Estimativa de tremolo e vibrato
function [LTSpectrogram, HTSpectrogram] = TCCTremVib(spectrogram, fpk, apk, params, outPath, filename)
	[plotTV, plotLH, tVibL, tVibH, tTremL, tTremH, minPeak] = ...
		textread("ConfigTremoloVibrato.txt", "plotTV = %f\n plotLH = %f\n threshVibL = %f\n threshVibH = %f\n threshTremL = %f\n threshTremH = %f\n minPeak = %f", 7, "commentstyle", "shell");

	% output_precision(20, "local");

	binMax = floor(params(5) / params(9) * params(6));
	binMin = floor(params(4) / params(9) * params(6)) + 1;

	% fpk = abs(fpk);
	% apk = abs(apk);

	dF = zeros(binMax, size(spectrogram, 2));
	dA = zeros(binMax, size(spectrogram, 2));

	%mf em hZ
	mf = ((binMin - .5):(binMax + .5)) / size(spectrogram, 1) * params(9);

	%Remoção de picos curtos
	offset = floor(minPeak * params(9) / params(1)) - 1;
	k = binMin:binMax;
	for l = 2:(size(spectrogram, 2) - offset)
		apk(k, l) = apk(k, l) .* all(apk(k, (l:l+offset)), 2);
	endfor

	%disp("Identificacao");
	if(params(7) == 1) res = 2 .^ (3:-1:0);
	else res = 1;
	endif

	for r = res
		dt = 0;

		%Range entre chaves
		if(params(7) == 2)
			switch(r)
    			case 8
    				range = [binMin:floor(630 / params(9) * size(spectrogram, 1))];
    			case 4
    				range = [floor(630 / params(9) * size(spectrogram, 1)) + 1 : floor(1480 / params(9) * size(spectrogram, 1))];
    				dt = 1;
    			case 2
    				range = [floor(1480 / params(9) * size(spectrogram, 1)) + 1 : floor(3150 / params(9) * size(spectrogram, 1))];
    				dt = 3;
    			case 1
    				range = [floor(3150 / params(9) * size(spectrogram, 1)) + 1 : binMax];
    				dt = 7;
    		endswitch
    	else
    		range = [binMin:binMax];
		endif

		dFrel = dArel = zeros(range, 5);

		for l = 1:(dt+1):(size(spectrogram, 2) - dt)
			for f = 4:8
				%dFrel, dArel (com Apk e Fpk)
				dFrel(range, f-3) = abs(sum((fpk(range, l:(l+dt)) - mf(range - binMin + 1)') .* exp((-2i*pi * f * range') * ((l:(l+dt)) ./(dt+1))), 2) .* (fpk(range, l) > 0) ./ (mf(range - binMin + 1) * (dt+1))');
				% dFrel(range, f-3) = abs(sum((fpk(range, l:(l+dt)) - mf(range - binMin + 1)') .* exp((-2i*pi * f * range') * ((l:(l+dt)) ./(dt+1))), 2) .* (apk(range, l) > 0) ./ (mf(range - binMin + 1) * (dt+1))');
				dArel(range, f-3) = abs(sum((apk(range, l:(l+dt)) - mf(range - binMin + 1)') .* exp((-2i*pi * f * range') * ((l:(l+dt)) ./(dt+1))), 2) .* (apk(range, l) > 0) ./ (mf(range - binMin + 1) * (dt+1))');
			endfor

			%df, da
			dF(range, l:(l+dt)) += max(dFrel(range, :), [], 2);
			dA(range, l:(l+dt)) += max(dArel(range, :), [], 2);
		endfor

		if(params(7) == 0) break; endif
	endfor

	LTSpectrogram(binMin:binMax, :) = spectrogram(binMin:binMax, :) .* (((dF(binMin:binMax, :) >= tVibL) + (dA(binMin:binMax, :) >= tTremL)) > 0);
	HTSpectrogram(binMin:binMax, :) = spectrogram(binMin:binMax, :) .* (((dF(binMin:binMax, :) >= tVibH) + (dA(binMin:binMax, :) >= tTremH)) > 0);

	tvOutPath = char(cstrcat("TV(", num2str(tVibL), " ", num2str(tVibH), " ", num2str(tTremL), " ", num2str(tTremH), " ", num2str(minPeak), ")"));

	if(exist(strcat(char(outPath, tvOutPath)), "dir") != 7)
		mkdir(outPath, tvOutPath);
	endif
	outPath = char(strcat(outPath, tvOutPath, "/"));

	%plots, .wavs
	if(plotTV == true && nargin() == 6)
		%dF(Vib)
		dFPlot = abs(dF(binMin:binMax, :));
		if(params(7) == 0)
			dFPlot = dFPlot(1:round(size(dFPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-Vib.png"));
		TCCPlotSpec(dFPlot, params, saveName, 2);

		sig = TCCIstft(dF, params, params(9));
		audiowrite(strcat(outPath, filename, "-Vib.wav"), sig, params(9));

		%dA(Trem)
		dAPlot = abs(dA(binMin:binMax, :));
		if(params(7) == 0)
			dAPlot = dAPlot(1:round(size(dAPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-Trem.png"));
		TCCPlotSpec(dAPlot, params, saveName, 2);

		sig = TCCIstft(dA, params, params(9));
		audiowrite(strcat(outPath, filename, "-Trem.wav"), sig, params(9));
	endif

	if(plotLH == true && nargin == 6)
		%LT
		LTPlot = abs(LTSpectrogram(binMin:binMax, :));
		if(params(7) == 0)
			LTPlot = LTPlot(1:round(size(LTPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-LTSpec.png"));
		TCCPlotSpec(LTPlot, params, saveName, 2);

		sig = TCCIstft(LTSpectrogram, params, params(9));
		audiowrite(strcat(outPath, filename, "-LTSpec.wav"), sig, params(9));

		%HT
		HTPlot = abs(HTSpectrogram(binMin:binMax, :));
		if(params(7) == 0)
			HTPlot = HTPlot(1:round(size(HTPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-HTSpec.png"));
		TCCPlotSpec(HTPlot, params, saveName, 2);

		sig = TCCIstft(HTSpectrogram, params, params(9));
		audiowrite(strcat(outPath, filename, "-HTSpec.wav"), sig, params(9));
	endif

	clear -x HTSpectrogram LTSpectrogram
endfunction