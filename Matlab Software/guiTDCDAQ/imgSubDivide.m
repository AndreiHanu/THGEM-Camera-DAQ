% Use the Open File Dialog
[filename, pathname] = uigetfile('*.out', 'Pick the image file: ');
% Check For Selected Files
if isequal(pathname,0)
    disp('No Data Files Were Selected !!')
else
    imageRaw = dlmread(filename,'\t');
    [imgX imgY] = size(imageRaw);

    startX = 0;
    startY = 0;

    endX = imgX - 1;
    endY = imgY - 1;

    curX = startX;
    curY = startY;

    addrX = curX;
    addrY = curY;

    pixDiv = 1;

    cntX = 0; 
    cntY = 0;
    subPixelCount = 0;

    imageSmall=zeros((endX - startX + 1)/pixDiv,(endY - startY + 1)/pixDiv);
    imgSmallX = 1;
    imgSmallY = 1;
    imgSmallEndX = (endX - startX + 1)/pixDiv+1;

    while (curY <= endY)
        % Grab Image Data
        subPixelCount = subPixelCount + imageRaw(curX + cntX + 1,curY + cntY + 1);

        % Increment SubPixel X
        cntX = cntX + 1;

        % Check SubPixel X Boundary
        if (cntX == pixDiv)
            cntX = 0;
            cntY = cntY + 1;
        end

        % Check SubPixel Y Boundary
        if (cntY == pixDiv)
            % Reset SubPixel Counters
            cntY = 0;        
            % Increment Current X
            curX = curX + pixDiv;
            % Gather Image Data
            imageSmall(imgSmallX,imgSmallY) = subPixelCount;
            imgSmallX = imgSmallX + 1;
            if (imgSmallX == imgSmallEndX)
                imgSmallX = 1; 
                imgSmallY = imgSmallY + 1;
            end
            % Reset Sub Pixel Count
            subPixelCount = 0;
        end

         % Increment Current Pixel Location
        if (curX > endX)
            curX = startX;
            curY = curY + pixDiv;
        end
    end

    % Plot Image
    imagesc(imageSmall,[0 15])
    colormap(gray)
    set(gca,'ydir','normal')
    set(gca,'XAxisLocation','top')

    % Export to EPS/PDF
    set(gcf, 'PaperPositionMode', 'auto');
    print([filename '.pdf'], '-dpdf');
end

