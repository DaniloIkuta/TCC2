#! /usr/local/bin/octave -qfH --no-gui
%Main

%Load packages
pkg load control
pkg load signal

beep_on_error(true);
ignore_function_time_stamp("all");

%Carrega configs
[samplesPath, outPath, spectrogramMethod, voiceDetection, melodyExtraction, saveBackground, saveVocal, saveMelody, audioList] = ...
	textread("ConfigMain.txt", "samplesPath = %s\n outPath = %s\n spectrogramMethod = %s\n voiceDetection = %s\n melodyExtraction = %s\n saveBackground = %f\n saveVocal = %f\n saveMelody = %f\n audioList = %f", 9, "commentstyle", "shell");

samplesPath = samplesPath{1};
outPath = outPath{1};

if(exist(strcat(char(outPath, "Final Results")), "dir") != 7 && (saveMelody == 1 || saveVocal == 1 || saveBackground == 1))
	mkdir(outPath, "Final Results/");
endif

%Obter nome do áudio
if(audioList > 0)
	filenames = textread(strcat("AudioList", num2str(audioList), ".txt"), "%s\n", "delimiter", "\n", "commentstyle", "shell");
else
	filenames = textread("AudioList.txt", "%s\n", "delimiter", "\n", "commentstyle", "shell");
endif

for i = 1:size(filenames, 1)
	disp(filenames{i});

	try
		%Abrir áudio
		[origAudio, sampleRate] = audioread(strcat(samplesPath, filenames{i}, ".wav"));

		%Chamada de funções
		%Espectrograma
		if(strcmp(spectrogramMethod, "STFT") == 1)
			disp("STFT")
			[spectrogram, specParams] = TCCStft(origAudio, outPath, filenames{i}, sampleRate);

		elseif(strcmp(spectrogramMethod, "MR-FFT") == 1)
			disp("MR-FFT");
			[spectrogram, specParams] = TCCMrfft(origAudio, outPath, filenames{i}, sampleRate);

		else
			display("Nenhuma opção de espectrograma selecionado, encerrando programa.");
			quit();
		endif

		%zero-pad
		zpFrames = ceil((specParams(1) - specParams(2) + size(origAudio, 1)) / specParams(2));
		origAudio = [zeros(specParams(1) - specParams(2), 1); origAudio; zeros(zpFrames * specParams(2) - size(origAudio, 1), 1)];

		%Detecção de voz
		if(strcmp(voiceDetection, "TV") == 1)
			disp("Identificacao de senoides");
			[fpk, apk] = TCCSinId(spectrogram, specParams);
			disp("Estimativa de Tremolo/Vibrato");
			[LTSpectrogram, HTSpectrogram] = TCCTremVib(spectrogram, fpk, apk, specParams, outPath, filenames{i});
			disp("NSHS");
			nshsSpec = TCCNshs(spectrogram, LTSpectrogram, specParams, outPath, filenames{i});
			disp("Trend");
			stSpectrogram = TCCSingTrend(spectrogram, nshsSpec, HTSpectrogram, specParams, outPath, filenames{i});

			vocal = TCCIstft(stSpectrogram, specParams, sampleRate);
			vocal = vocal(1:size(origAudio));

			if(saveVocal == 1)
				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Vocal.wav"), vocal, sampleRate);
			endif

			if(saveBackground == 1)
				vocalMin = -min(vocal);
				origAudioMin = -min(origAudio);

				vocalNorm = (vocal + vocalMin) / (max(vocal) + vocalMin);
				origAudioNorm = (origAudio + origAudioMin) / (max(origAudio) + origAudioMin);

				inst = ((origAudioNorm - vocalNorm) * (max(origAudio)) + origAudioMin) - origAudioMin;

				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Inst.wav"), inst, sampleRate);
			endif
		else
			disp("Nenhum método de detecção de vocal selecionado.");
		endif

		%Melodia
		if(strcmp(melodyExtraction, "REPET-SIM") == 1)
			disp("Matrizes de Similaridade");
			if(strcmp(voiceDetection, "TV") == 1)
				bg = TCCRepetSim(spectrogram - stSpectrogram, size(origAudio), specParams, filenames{i}, outPath);
			else
				bg = TCCRepetSim(spectrogram, size(origAudio), specParams, filenames{i}, outPath);
			endif

			if(saveBackground == 1)
				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Background.wav"), bg, sampleRate);
			endif

			if(saveMelody == 1)
				bgMin = -min(bg);
				origAudioMin = -min(origAudio);

				bgNorm = (bg + bgMin) / (max(bg) + bgMin);
				origAudioNorm = (origAudio + origAudioMin) / (max(origAudio) + origAudioMin);

				melody = ((origAudioNorm - bgNorm) * (max(origAudio)) + origAudioMin) - origAudioMin;

				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Melody.wav"), melody, sampleRate);
			endif

		%Verificar magnitude de melodia!
		elseif(strcmp(melodyExtraction, "ESI-DP") == 1)
			if(strcmp(voiceDetection, "TV") != 1)
				disp("Identificacao de senoides");
				[fpk, ~] = TCCSinId(spectrogram, specParams);
				spectrogram = stSpectrogram;
			endif

			disp("ESI Extraction");
			melody = TCCEsiPE(spectrogram, fpk, specParams, outPath, filenames{i}, size(origAudio));

			if(saveBackground == 1)
				melMin = -min(melody);
				origAudioMin = -min(origAudio);

				melNorm = (melody + melMin) / (max(melody) + melMin);
				origAudioNorm = (origAudio + origAudioMin) / (max(origAudio) + origAudioMin);

				bg = ((origAudioNorm - melNorm) * (max(origAudio)) + origAudioMin) - origAudioMin;

				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Background.wav"), bg, sampleRate);
			endif

			if(saveMelody == 1)
				audiowrite(strcat(outPath, "/Final Results/", filenames{i}, "-Melody.wav"), melody, sampleRate);
			endif
		else
			display("Nenhuma opção de extração de melodia selecionado.");
		endif

		clear -x samplesPath outPath spectrogramMethod voiceDetection melodyExtraction saveBackground saveMelody saveVocal filenames

	catch erro
		beep();
		disp(erro.message);
		% printf("ERRO: arquivo %s não encontrado!\n", filenames{i});
	end_try_catch

	printf("\n");
endfor