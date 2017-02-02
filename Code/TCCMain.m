#! /usr/local/bin/octave -qfH --no-gui
%Main

%Load packages
pkg load control
pkg load signal

beep_on_error(true);
ignore_function_time_stamp("all");

%Carrega configs
[samplesPath, outPath, spectrogramMethod, voiceDetection, melodyExtraction, audioList] = ...
	textread("ConfigMain.txt", "samplesPath = %s\n outPath = %s\n spectrogramMethod = %s\n voiceDetection = %s\n melodyExtraction = %s\n audioList = %f", 6, "commentstyle", "shell");

samplesPath = samplesPath{1};
outPath(1) = outPath{1};

%Obter nome do áudio
if(audioList > 0)
	filenames = textread(strcat("AudioList", num2str(audioList), ".txt"), "%s\n", "delimiter", "\n", "commentstyle", "shell");
else
	filenames = textread("AudioList.txt", "%s\n", "delimiter", "\n", "commentstyle", "shell");
endif

for i = 1:size(filenames, 1)
	disp(filenames{i});

	mkdir(char(outPath(1)), filenames{i});
	outPath(i+1) = strcat(char(outPath(1)), filenames{i}, "/");

	try
		%Abrir áudio
		[origAudio, sampleRate] = audioread(strcat(samplesPath, filenames{i}, ".wav"));

		%Chamada de funções
		%Espectrograma
		if(strcmp(spectrogramMethod, "STFT") == 1)
			disp("STFT")
			[spectrogram, specParams, specOutPath] = TCCStft(origAudio, char(outPath(i+1)), filenames{i}, sampleRate, 0);

		elseif(strcmp(spectrogramMethod, "MR-FFT") == 1)
			disp("MR-FFT");
			[spectrogram, specParams, specOutPath] = TCCMrfft(origAudio, char(outPath(i+1)), filenames{i}, sampleRate, 0);

		else
			display("Nenhuma opção de espectrograma selecionado, encerrando programa.");
			quit();
		endif

		%zero-pad
		% zpFrames = ceil((specParams(1) - specParams(2) + size(origAudio, 1)) / specParams(2));
		% origAudio = [zeros(specParams(1) - specParams(2), 1); origAudio; zeros(zpFrames * specParams(2) - size(origAudio, 1), 1)];

		%Detecção de voz
		if(strcmp(voiceDetection, "TV") == 1)
			disp("Identificacao de senoides");
			[fpk, apk] = TCCSinId(spectrogram, specParams);
			disp("Estimativa de Tremolo/Vibrato");
			[LTSpectrogram, HTSpectrogram, tvOutPath] = TCCTremVib(spectrogram, fpk, apk, specParams, char(specOutPath), filenames{i}, 0);
			disp("NSHS");
			[nshsSpec, nshsOutPath] = TCCNshs(spectrogram, LTSpectrogram, specParams, char(tvOutPath), filenames{i}, 0);
			disp("Trend");
			[stSpectrogram, stOutPath] = TCCSingTrend(spectrogram, nshsSpec, HTSpectrogram, specParams, char(nshsOutPath), filenames{i}, 0);
		else
			disp("Nenhum método de detecção de vocal selecionado.");
		endif

		%Melodia
		if(strcmp(melodyExtraction, "REPET-SIM") == 1)
			disp("Matrizes de Similaridade");
			if(strcmp(voiceDetection, "TV") == 1)
				[bg, repetOutPath] = TCCRepetSim(spectrogram - stSpectrogram, size(origAudio), specParams, filenames{i}, char(stOutPath), 0);
			else
				[bg, repetOutPath] = TCCRepetSim(spectrogram, size(origAudio), specParams, filenames{i}, char(specOutPath), 0);
			endif

		%Verificar magnitude de melodia!
		elseif(strcmp(melodyExtraction, "ESI-DP") == 1)
			disp("ESI Extraction");

			if(strcmp(voiceDetection, "TV") != 1)
				disp("Identificacao de senoides");
				[fpk, ~] = TCCSinId(spectrogram, specParams);
				[melody, esiOutPath] = TCCEsiPE(spectrogram, fpk, specParams, char(specOutPath), filenames{i}, size(origAudio), 0);
			else
				spectrogram = stSpectrogram;
				[melody, esiOutPath] = TCCEsiPE(spectrogram, fpk, specParams, char(stOutPath), filenames{i}, size(origAudio), 0);
			endif
		else
			display("Nenhuma opção de extração de melodia selecionado.");
		endif

		clear -x samplesPath outPath spectrogramMethod voiceDetection melodyExtraction filenames

	catch erro
		beep();
		disp(erro.message);
		disp(erro.identifier);
		for errInd = 1:size(erro.stack, 1)
			disp(erro.stack(errInd));
		endfor
	end_try_catch

	printf("\n");
endfor