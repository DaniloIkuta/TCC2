function sig = TCCIstft(spectrogram, params);
    [n, m] = size(spectrogram);
    %Com size(audio) em params, será q precisa calcular l?
    l = m * params(2) + n;

    binMax = floor(params(5) / params(9) * params(6));
    binMin = floor(params(4) / params(9) * params(6)) + 1;

    if(params(7) == 1) res = 2 .^ (0:3);
        sig = zeros(l, 4);
        sigind = 1;
    else res = 1;
        % sig = zeros(l, 1);
    endif

    for r = res
    	ws = params(1) * r;
        switch (params(3))
            case 1  win = hanning (ws);
            case 2  win = hamming (ws);
            case 3  win = ones (ws, 1);
        endswitch

        if(params(7) == 1)
            switch(r)
                case 8
                    range = binMin:floor(630 / params(9) * params(6));
                case 4
                    range = floor(630 / params(9) * params(6)) : floor(1480 / params(9) * params(6));
                case 2
                    range = floor(1480 / params(9) * params(6)) : floor(3150 / params(9) * params(6));
                case 1
                    range = floor(3150 / params(9) * params(6)) : binMax;
            endswitch

            z = spectrogram;
            z(1 : (min(range) - 1), :) = 0;
            z((max(range) + 1) : size(spectrogram, 1), :) = 0;

            for j = 1:m
                sig((1:n) + params(2) * (j - 1), sigind) = sig((1:n) + params(2) * (j - 1), sigind) + real(ifft(z(1:n, j)));
            endfor

            sig(:, sigind) = sig(:, sigind)/sum(win(1:params(2):params(1)));

            % audiowrite(strcat(num2str(sigind), ".wav"), sig, params(9));

            sigind++;

        else
            % range = 1:size(spectrogram);
            spectrogram = cat(1, spectrogram, flipud(spectrogram));
            z = real(ifft(spectrogram)) / r;
            st = fix((size(win, 1) - params(2)) / 2);
            z = z(st + 1:st + params(2), :);
            win = win(st + 1:st + params(2));

            for i = 1:columns(z)
                z(:, i) ./= win;
            endfor

            sig = reshape(z, params(2) * size(z, 2), 1);

            break;
        endif

        % for j = 1:m
        %     % sig((1:n) + params(2) * (j - 1), sigind) = sig((1:n) + params(2) * (j - 1), sigind) + real(ifft(spectrogram(:, j)));
        %     sig(range + params(2) * (j - 1), sigind) = sig(range + params(2) * (j - 1), sigind) + real(ifft(spectrogram(range, j)));
        % endfor

        % sig(:, sigind) = reshape(z, params(2) * size(z, 2), 1);
        % sig(:, sigind) = sig(:, sigind)/(sum(win(min(range):params(2):max(range))) + 1);
    endfor

    if(params(7) == 1)
        sig(:, 1) = sum(sig, 2);
        sig = sig(:, 1);
    endif

    % disp(size(sig));
    % sig(l - (n - params(2)) + 1 : l) = [];
    % disp(size(sig));
    % sig(1 : n - params(2)) = [];
    % disp(size(sig));

    %Perfect OA
    % if(params(2) == params(1)/2)
    %     sig(l - (round(n/2) - params(2)) + 1 : l) = [];
    %     sig(1 : round(n/2) - params(2)) = [];
    % endif

    clear -x sig
endfunction

% z = real (ifft (y));
%   st = fix ((w_size-inc) / 2);
%   z = z(st+1:st+inc, :);
%   w_coeff = w_coeff(st+1:st+inc);

%   nc = columns (z);
%   for i = 1:nc
%     z(:, i) ./= w_coeff;
%   endfor

%   x = reshape (z, inc * nc, 1);