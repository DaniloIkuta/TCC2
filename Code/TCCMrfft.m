% MR-FFT
function [spectrogram, params, outPath] = TCCMrfft(audio, outPath, filename, sampleRate, preset)
	%Carregar configs
	if(preset == 0)
		[winSize, hopSize, bins, winType, plot, minF, maxF] = ...
			textread("ConfigMrfft.txt", "winSize = %f\n hopSize = %f\n bins = %f\n winType = %f\n plot = %f\n minF = %f\n maxF = %f", 7, "commentstyle", "shell");
	else
		[winSize, hopSize, bins, winType, plot, minF, maxF] = ...
			textread(strcat("ConfigMrfft", num2str(preset), ".txt"), "winSize = %f\n hopSize = %f\n bins = %f\n winType = %f\n plot = %f\n minF = %f\n maxF = %f", 7, "commentstyle", "shell");
	endif

	if(maxF > sampleRate/2)
		printf("maxF excedendo sampleRate/2. Alterando maxF para %d\n", sampleRate/2);
		maxF = sampleRate/2;
	endif

	%zero-pad
	zpFrames = ceil((winSize - hopSize + size(audio, 1)) / hopSize);
	audio = [zeros(winSize - hopSize, 1); audio; zeros(zpFrames * hopSize - size(audio, 1), 1)];

	params = [winSize/8, hopSize, winType, minF, maxF, bins, 1, size(audio, 1), sampleRate];

	%MR-FFT
	binMax = floor(maxF / sampleRate * bins);
	binMin = floor(minF / sampleRate * bins) + 1;

	buffer = zeros(bins/hopSize, binMax + bins/hopSize);
	spectrogram = zeros(bins, zpFrames);

	coefs = zeros(1, winSize/2);
	switch (winType)
       	case 1
       		coefs(1) = coefs(2) = .5;
       	case 2 
       		coefs(1) = .54;
       		coefs(2) = .46;
    endswitch

	for r = 2 .^ (0:3)
		winSize = r * hopSize;

		for l = 0 : zpFrames - 1;

			c = mod(l, bins/hopSize);

			%FFT
			xc = zeros(bins, 1);
			xc(c * hopSize + 1 : (c+1) * hopSize) = audio(1 + l * hopSize : (l+1) * hopSize);
			Xc = fft(xc, bins);
			Xc(1:binMin) = 0;
			buffer(c + 1, :) = Xc(1:binMax + bins/hopSize);
			% buffer(c + 1, :) = Xc(binMin:binMax + bins/hopSize);

			%Sum
			Xr = zeros(1, binMax + bins/hopSize);
			cInd = c+1;
			if(l >= r-1)
				for i = 1:r
					Xr = Xr + buffer(cInd, :);
					if(cInd == 1)
						cInd = bins/hopSize;
					else
						cInd = cInd - 1;
					endif
				endfor

				%Twiddle
				Xr = Xr .* exp(1i * 2 * pi * (1:binMax + bins/hopSize) * (c-r+1) * hopSize/bins);

				%Window
    			Xr(binMin:binMax) = coefs(1) * Xr(binMin:binMax) - coefs(2) / 2 * ([conj(fliplr(Xr(2:r * bins/winSize + 1))) Xr(binMin:binMax - r * bins/winSize)] + Xr(r * bins / winSize + 0 : (size(Xr, 2) - binMin)));

    			switch(r)
    				case 8
    					% range = binMin:floor(binMax/4);
    					range = binMin:floor(630 / sampleRate * bins);
    				case 4
    					% range = floor(binMax/4) + 1 : floor(binMax/2);
    					range = floor(630 / sampleRate * bins) + 1 : floor(1480 / sampleRate * bins);
    				case 2
    					% range = floor(binMax/2) + 1 : floor(3*binMax/4);
    					range = floor(1480 / sampleRate * bins) + 1 : floor(3150 / sampleRate * bins);
    				case 1
    					% range = floor(3*binMax/4) + 1 : binMax;
    					range = floor(3150 / sampleRate * bins) + 1 : binMax;
    			endswitch

    			% spectrogram(range, l+1) = abs(Xr(range))';
    			spectrogram(range, l+1) = (Xr(range)') / r;
    			% spectrogram(range, l+1) = Xr(range - binMin + 1)';
			endif
		endfor
	endfor

	spectrogram(1:binMin, :) = 0;
	spectrogram(binMax+1 : size(spectrogram, 1), :) = 0;

	% spectrogram = cat(1, spectrogram, flipud(spectrogram));

	%Potencial forma de normalizar a amplitude das resoluções?
	% spectrogram = spectrogram / max(spectrogram(:));

	mrfftOutPath = char(cstrcat("MRFFT(", num2str(winSize), " ", num2str(hopSize), " ", num2str(bins), " ", num2str(winType), " ", num2str(minF), " ", num2str(maxF), ")"));
	mkdir(outPath, mrfftOutPath);
	outPath = char(strcat(outPath, mrfftOutPath, "/"));

	%Plot de espectrograma(opcional)
	if(plot == true)
		specPlot = abs(spectrogram(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-MRFFT.png"));
		TCCPlotSpec(specPlot, params, saveName, 1);

		sig = TCCIstft(spectrogram, params, sampleRate);
		audiowrite(strcat(outPath, filename, "-MRFFT.wav"), sig, sampleRate);
	endif

	clear -x spectrogram params outPath
endfunction