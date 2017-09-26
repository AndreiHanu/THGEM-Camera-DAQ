minY = 424;
maxY = 598;
xStats = zeros(maxY-minY+1,2);
cnt = 0;
for i=minY:1:maxY
    cnt = cnt + 1;
    bins = (0:1:1023)';
    count = imgTDCDAQ_20130305_09_48(i,:)';

    % Define Fit Options    
    fo_ = fitoptions('method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt');

    % Starting Guess
    A1_guess = sum(count);
    x0_guess = mean(find(count == max(count)));
    s1_guess = std(count);

    st_ = [A1_guess x0_guess s1_guess];
    set(fo_,'Startpoint',st_);

    % Define Fit (Gaussian)
    ft_ = fittype('A1/(s1*(2*pi())^0.5)*exp(-0.5*(x-x0)^2/s1^2)' ,...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'A1', 'x0', 's1'});

    % Fit this model using new data
    [cf_,gof_] = fit(bins,count,ft_,fo_);

    % Print Statistics
    fprintf('\nUsing 3*sigma statistics\n')
    fprintf('Peak: %f\n',cf_.x0)    
    fprintf('Std Dev: %f\n',3*cf_.s1)  
    fprintf('FWHM: %f\n',2.35*cf_.s1)

    % Add Peak Information
    xStats(cnt,1) = cf_.x0;
    xStats(cnt,2) = 2.35*cf_.s1;
end