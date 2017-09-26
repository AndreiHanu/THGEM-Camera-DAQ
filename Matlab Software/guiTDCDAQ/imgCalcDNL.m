
% Use the Open File Dialog
[filename, pathname] = uigetfile('*.out', 'Pick the image file: ');
% Check For Selected Files
if isequal(pathname,0)
    disp('No Data Files Were Selected !!')
else
    % Read Image File
    imageRaw = dlmread(filename,'\t');
    [imgX imgY] = size(imageRaw);
    
    % Plot Original Image
    figure
    imagesc(imageRaw,[0 255])
    colormap(gray)
    set(gca,'ydir','normal')    
    %set(gca,'XAxisLocation','top')
    
    % Export to EPS/PDF
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');
    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    print([filename '.pdf'], '-dpdf');
    
    % Zero X & Y Counts Matrix
    channels = 1:1:imgX;
    dnlX = uint32(zeros(1,imgX));
    dnlY = uint32(zeros(1,imgY));
    
    % Sum X-Direction
    for i = 1:1:imgX
        dnlX(i) = sum(imageRaw(:,i));
    end
        
    figure
    plot(dnlX)
    xlim([0 imgX])
    xlabel('Channel')
    ylabel('Counts')
    % Export to EPS/PDF
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');
    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    print([filename '.dnlX' '.pdf'], '-dpdf');
    
    % Sum Y-Direction
    for i = 1:1:imgY
        dnlY(i) = sum(imageRaw(i,:));
    end  
    
    figure  
    plot(dnlY)
    xlim([0 imgY])
    xlabel('Channel')
    ylabel('Counts')
    % Export to EPS/PDF
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');
    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    print([filename '.dnlY' '.pdf'], '-dpdf');
    
    % X-DNL with Gaussian Fit
    figure
    hold on
    bins = (0:200:max(double(dnlX)))';
    histX = hist(double(dnlX),bins);
    bar(bins,histX);
    
    % Define Fit Options    
    fo_ = fitoptions('method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt');

    % Starting Guess
    A1_guess = sum(dnlX);
    x0_guess = bins(find(histX == max(histX)));
    s1_guess = 100;

    st_ = [A1_guess x0_guess s1_guess];
    set(fo_,'Startpoint',st_);
    
    % Define Fit (Gaussian)
    ft_ = fittype('A1/(s1*(2*pi())^0.5)*exp(-0.5*(x-x0)^2/s1^2)' ,...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'A1', 'x0', 's1'});
 
    % Fit this model using new data
    [cf_,gof_] = fit(bins,histX',ft_,fo_);
    
    % Add text
    hText   = text(75000, 100, ...
    sprintf('Mean: %0.0f\nFWHM: %0.0f\nDNL: %0.2f%%', ...
    cf_.x0, 2.35*cf_.s1, 2.35*cf_.s1/cf_.x0*100));
    
    % Plot Fit    
    plot(cf_,'fit',0.95);
    legend('off')
    
    xlim([(cf_.x0 - 3*2.35*cf_.s1) (cf_.x0 + 3*2.35*cf_.s1)])
    xlabel('Counts')
    ylabel('Frequency')
    % Export to EPS/PDF
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');
    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    print([filename '.histX' '.pdf'], '-dpdf');
    
    % Y-DNL with Gaussian Fit
    figure
    hold on
    bins = (0:200:max(double(dnlY)))';
    histY = hist(double(dnlY),bins);
    bar(bins,histY);
    
    % Define Fit Options    
    fo_ = fitoptions('method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt');

    % Starting Guess
    A1_guess = sum(dnlY);
    x0_guess = mean(bins(find(histY == max(histY))));
    s1_guess = 100;

    st_ = [A1_guess x0_guess s1_guess];
    set(fo_,'Startpoint',st_);
    
    % Define Fit (Gaussian)
    ft_ = fittype('A1/(s1*(2*pi())^0.5)*exp(-0.5*(x-x0)^2/s1^2)' ,...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'A1', 'x0', 's1'});
 
    % Fit this model using new data
    [cf_,gof_] = fit(bins,histY',ft_,fo_);
    
    % Add text
    hText   = text(75000, 100, ...
    sprintf('Mean: %0.0f\nFWHM: %0.0f\nDNL: %0.2f%%', ...
    cf_.x0, 2.35*cf_.s1, 2.35*cf_.s1/cf_.x0*100));
    
    % Plot Fit    
    plot(cf_,'fit',0.95);
    legend('off')
    
    xlim([(cf_.x0 - 3*2.35*cf_.s1) (cf_.x0 + 3*2.35*cf_.s1)])
    xlabel('Counts')
    ylabel('Frequency')
    % Export to EPS/PDF
    %set(gcf, 'PaperPositionMode', 'auto'); 
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');
    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    print([filename '.histY' '.pdf'], '-dpdf');
    
end



