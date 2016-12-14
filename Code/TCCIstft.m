function sig = TCCIstft(spectrogram, params);
    [n, m] = size(spectrogram);
    %Com size(audio) em params, será q precisa calcular l?
    l = m * params(2) + n;

    binMax = floor(params(5) / params(9) * params(6));
    binMin = floor(params(4) / params(9) * params(6)) + 1;

    if(params(7) == 1)
        res = 2 .^ (0:3);
        sig = zeros(l, 4);
    else res = 1;
        sig = zeros(l, 1);
    endif

    % disp(size(sig));

    sigind = 1;

    for r = res

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
        else
            range = binMin:binMax;
        endif

        for j = 1:m
            sig((1:n) + params(2) * (j - 1), sigind) = sig((1:n) + params(2) * (j - 1), sigind) + real(ifft(spectrogram(:, j)));
        endfor
        
        ws = params(1) * r;
        switch (params(3))
            case 1  win = hanning (ws);
            case 2  win = hamming (ws);
            case 3  win = ones (1, ws);
        endswitch
        
        sig(:, sigind) = sig(:, sigind)/sum(win(min(range):params(2):max(range)));

        if(params(7) == 0) break; endif

        sigind++;
    endfor

    sig(:, 1) = sum(sig, 2);
    sig = sig(:, 1);

    % disp(size(sig));
    % sig(l - (n - params(2)) + 1 : l) = [];
    % disp(size(sig));
    % sig(1 : n - params(2)) = [];
    % disp(size(sig));

    %Perfect OA
    if(params(2) == params(1)/2)
        sig(l - (round(n/2) - params(2)) + 1 : l) = [];
        sig(1 : round(n/2) - params(2)) = [];
    endif

    clear -x sig
endfunction