%STFT
function [spectrogram, params, outPath] = TCCStft (audio, outPath, filename, sampleRate, preset)
	%Carregar configs
	if(preset == 0)
		[winSize, hopSize, bins, winType, plot, minF, maxF] = ...
			textread("ConfigStft.txt", "winSize = %f\n hopSize = %f\n bins = %f\n winType = %f\n plot = %f\n minF = %f\n maxF = %f", 7, "commentstyle", "shell");
	else
		[winSize, hopSize, bins, winType, plot, minF, maxF] = ...
			textread(strcat("ConfigStft", num2str(preset), ".txt"), "winSize = %f\n hopSize = %f\n bins = %f\n winType = %f\n plot = %f\n minF = %f\n maxF = %f", 7, "commentstyle", "shell");
	endif

	if(maxF > sampleRate/2)
		printf("maxF excedendo sampleRate/2. Alterando maxF para %d\n", sampleRate/2);
		maxF = sampleRate/2;
	endif
	
	%zero-pad
	zpFrames = ceil((winSize - hopSize + size(audio, 1)) / hopSize);
	audio = [zeros(winSize - hopSize, 1); audio; zeros(zpFrames * hopSize - size(audio, 1), 1)];

	%Win
	switch (winType)
        case 1  win = hanning (winSize);
        case 2  win = hamming (winSize);
        case 3  win = ones (winSize, 1);
    endswitch

	%Função padrão do octave
	spectrogram = zeros(winSize, zpFrames);
	[spectrogram, params] = stft(audio, winSize, hopSize, bins, winType);
	spectrogram = spectrogram(1:bins, :);

	%Via fft
	% for j = 1:zpFrames
		% spectrogram(:, j) = fft(audio(1:winSize) + hopSize * (j-1) .* win);
	% endfor

	params = [params, minF, maxF, bins, 0, size(audio, 1), sampleRate];
	% params = [winSize, hopSize, winType, minF, maxF, bins, 0];

	%Cortar frequencias
	binMin = floor(minF/sampleRate * bins) + 1;
	binMax = floor(maxF/sampleRate * bins);

	spectrogram(1:(binMin-1), :) = 0;
	spectrogram((binMax+1):bins, :) = 0;

	stftOutPath = char(cstrcat("STFT(", num2str(winSize), " ", num2str(hopSize), " ", num2str(bins), " ", num2str(winType), " ", num2str(minF), " ", num2str(maxF), ")"));
	mkdir(outPath, stftOutPath);
	outPath = char(strcat(outPath, stftOutPath, "/"));
	
	%Plot de espectrograma(opcional)
	if(plot == true) 
		specPlot = abs(spectrogram(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-STFT.png"));
		TCCPlotSpec(specPlot, params, saveName, 1);

		sig = TCCIstft(spectrogram, params);
		audiowrite(strcat(outPath, filename, "-STFT.wav"), sig, sampleRate);
	endif

	clear -x spectrogram params outPath
endfunction