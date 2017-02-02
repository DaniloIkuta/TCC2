%Identificação de senoidais
function [insF, aPeak] = TCCSinId(spectrogram, params)
	binMax = floor(params(5) / params(9) * params(6));
	binMin = floor(params(4) / params(9) * params(6)) + 1;

	%phase vocoder
	N = size(spectrogram, 1);
	princarg = zeros(binMax, size(spectrogram, 2));
	kappa = zeros(binMax, size(spectrogram, 2));

	%Avanço esperado de fase p/cada bin
	phEspAdv = zeros(1, binMax);
	phEspAdv((binMin + 1):binMax) = (2*pi * params(2)) ./ (N ./ ((binMin + 1):binMax));
	% phEspAdv(binMin:binMax) = phEspAdv(binMin:binMax) - 2*pi * round(phEspAdv(binMin:binMax)/(2*pi));

	ph = angle(spectrogram(:, 1));

	%Coluna de seguranca
	spectrogram = [spectrogram, zeros(N, 1)];

	ncol = 1;
	for t = (0:size(spectrogram, 2) - 2)
		cols(binMin:binMax, :) = spectrogram(binMin:binMax, t + [1 2]);
		tf = t - floor(t);

		smag(binMin:binMax) = (1 - tf) * abs(cols(binMin:binMax, 1)) + tf * (abs(cols(binMin:binMax, 2)));

		%Avanço de fase
		phAdv(binMin:binMax) = angle(cols(binMin:binMax, 2) - angle(cols(binMin:binMax, 1))) - phEspAdv(binMin:binMax)';
		%Arredondamento para -pi:pi
		phAdv(binMin:binMax) = phAdv(binMin:binMax) - 2*pi * round(phAdv(binMin:binMax)/(2*pi));

		princarg(binMin:binMax) = mod(ph(binMin:binMax), -2*pi) + pi;

		% princarg(binMin:binMax, ncol) = smag(binMin:binMax)' .* exp(j*ph(binMin:binMax));
		%princarg(:, ncol) = phAdv;

		%is it right?
		% kappa(binMin:binMax, ncol) = princarg(round(abs(ph(binMin:binMax)' + phEspAdv(binMin:binMax) + phAdv(binMin:binMax) - ph(binMin:binMax)' - (2*pi * params(2) * (binMin:binMax) / N)))+1)' * N / (2*pi * params(2));
		% kappa(binMin:binMax, ncol) = princarg(round(phAdv(binMin:binMax)))' * N / (2*pi * params(2));
		kappa(binMin:binMax, ncol) = N/(2*pi*params(2)) * princarg(floor(abs(phAdv(binMin:binMax) - ph(binMin:binMax)' - (2*pi*params(2)*(binMin:binMax)/N)))+1);

		%Acumulador
		ph(binMin:binMax) = ph(binMin:binMax)' + phEspAdv(binMin:binMax) + phAdv(binMin:binMax);
		ph(binMin:binMax) = ph(binMin:binMax) - 2*pi * round(ph(binMin:binMax)/(2*pi));

		ncol++;
	endfor

	%Bin offset
	% kappa = princarg * N / (2*pi * params(2));
	kappa = [zeros(binMax, 1), kappa];

	%Freq. instantanea
	insF = aPeak = zeros(size(spectrogram));

	%picos
	wHann = zeros(1, size(spectrogram, 2));

	if(params(7) == 1) res = 2 .^ (0:3);
	else res = 1;
	endif

	for r = res
		M = r * params(1);

		if(params(7) == 1)
			switch(r)
    			case 8
    				range = binMin:floor(630 / params(9) * size(spectrogram, 1));
    			case 4
    				range = floor(630 / params(9) * size(spectrogram, 1)) : floor(1480 / params(9) * size(spectrogram, 1));
    			case 2
    				range = floor(1480 / params(9) * size(spectrogram, 1)) : floor(3150 / params(9) * size(spectrogram, 1));
    			case 1
    				range = floor(3150 / params(9) * size(spectrogram, 1)) : binMax;
    		endswitch
    	else
    		range = binMin:binMax;
		endif

		insF(range, :) = (kappa(range, :) + range') * (params(9) / N) .* (abs(kappa(range, :)) < (.7 * (r + 1)));
		
    	for k = range
    		wHann(:) = sinc(M / N * pi * abs(kappa(k, :))) / (2 * (1 - (M / N * abs(kappa(k, :))) .^ 2));

			l = 2:(size(spectrogram, 2) -1);
			% aPeak(k, l) = (abs(spectrogram(k, l)) ./ (2 * wHann(round(abs(N/M .* kappa(k, l))) + 1)) .* (abs(kappa(k, l)) < (.7 * (r + 1))));
			aPeak(k, l) = (abs(spectrogram(k, l)) ./ (2 * wHann(round(abs(N/M .* kappa(k, l))) + 1)));
    	endfor

    	if(params(7) == 0) break; endif
	endfor

	% Weighted Criterion
	rangeF = (binMin + 1):(binMax - 1);
	rangeT = 2:(size(spectrogram, 2) - 1);

	aPeak(rangeF, rangeT) = aPeak(rangeF, rangeT) .* ((aPeak(rangeF, rangeT) >= (abs(kappa(rangeF, rangeT) - kappa(rangeF + 1, rangeT) - 1) .* (abs(spectrogram(rangeF + 1, rangeT)) / .4))) & ...
		(aPeak(rangeF, rangeT) >= (abs(kappa(rangeF, rangeT) - kappa(rangeF - 1, rangeT) + 1) .* (abs(spectrogram(rangeF-1, rangeT)) / .4))));

	%Remove coluna de seguranca
	% insF(:, 1) = [];
	% aPeak(:, 1) = [];

	%Plot?
	% insFPlot = abs(insF(binMin:binMax, :));
	% saveName = char(strcat("../Output/", "insF.png"));
	% TCCPlotSpec(insFPlot, params, saveName, 2);
	% aPeakPlot = abs(aPeak(binMin:binMax, :));
	% saveName = char(strcat("../Output/", "aPeak.png"));
	% TCCPlotSpec(aPeakPlot, params, saveName, 2);
	% kappaPlot = abs(kappa(binMin:binMax, :));
	% saveName = char(strcat("../Output/", "kappa.png"));
	% TCCPlotSpec(kappaPlot, params, saveName, 2);

	clear -x insF aPeak
endfunction