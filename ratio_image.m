function ratio_image

clear all
close all

global img1 img2 img3 im

% Initializing parameters
log_size = 10;          % Specifiy size of log filter
log_sigma = 0.5;        % Specify standard deviation of log filter
Pixel_threshold = 20;   % Specify number of pixels to remove small objects (less than the value specified)
Pixel_connectivity = 8; % Specify the connectivity of the pixels
color_map = 'jet';      % Specify the color scheme to be used for ROI image

% Setting the path to the codes in MATLAB
CodesLocation = pwd;
addpath(CodesLocation);

% Read all the tif files from their respective folders
DataFolder = uigetdir('C:\','Select the Data Folder'); predir = DataFolder;
DataCh1 = sprintf('%s\\Ch1',DataFolder);
DataCh2 = sprintf('%s\\Ch2',DataFolder);
DataCh3 = sprintf('%s\\tau',DataFolder);

filePattern1 = fullfile(DataCh1, '*.tif');
txtFiles1 = dir(filePattern1);

filePattern2 = fullfile(DataCh2, '*.tif');
txtFiles2 = dir(filePattern2);

filePattern3 = fullfile(DataCh3, '*.tif');
txtFiles3 = dir(filePattern3);

% Loop between all images (some images can be stacks) one at a time
for filen = 1:length(txtFiles1)
    % Read file from Channel 1
    baseFileName1 = txtFiles1(filen).name;
    ImageName1 = fullfile(DataCh1, baseFileName1);
    fprintf(1, 'Now reading %s\n', ImageName1);

    InfoImage1=imfinfo(ImageName1);
    mImage1=InfoImage1(1).Width;
    nImage1=InfoImage1(1).Height;
    NumberImages=length(InfoImage1); % Number of images in stack for Image1
    img1=zeros(nImage1,mImage1,NumberImages,'single'); % Stores the stack
    
    % Read file from Channel 2
    baseFileName2 = txtFiles2(filen).name;
    ImageName2 = fullfile(DataCh2, baseFileName2);
    fprintf(1, 'Now reading %s\n', ImageName2);

    InfoImage2=imfinfo(ImageName2);
    mImage2=InfoImage2(1).Width;
    nImage2=InfoImage2(1).Height;
    NumberImages=length(InfoImage2); % Number of images in stack for Image2
    img2=zeros(nImage2,mImage2,NumberImages,'single'); % Stores the stack

    % Read file from Channel 3
    baseFileName3 = txtFiles3(filen).name;
    ImageName3 = fullfile(DataCh3, baseFileName3);
    fprintf(1, 'Now reading %s\n', ImageName3);
    
    InfoImage3=imfinfo(ImageName3);
    mImage3=InfoImage3(1).Width;
    nImage3=InfoImage3(1).Height;
    NumberImages=length(InfoImage3);  % Number of images in stack for Image3
    img3=zeros(nImage3,mImage3,NumberImages,'single'); % Stores the stack

    % Loop between per image stack
    SubImageTotal = 0;
    for ni=1:NumberImages 
        img1(:,:,ni)=imread(ImageName1,'Index',ni,'Info',InfoImage1);
        img2(:,:,ni)=imread(ImageName2,'Index',ni,'Info',InfoImage2);
        img3(:,:,ni)=imread(ImageName3,'Index',ni,'Info',InfoImage3);
       
        % Change images from uint to double precision
        im(ni).double_img1 = double(img1(:,:,ni)); % im structure stores one image from the stack of Ch1 determined by ni
        im(ni).double_img2 = double(img2(:,:,ni)); % im structure stores one image from the stack of Ch2 determined by ni
        im(ni).double_img3 = double(img3(:,:,ni)); % im structure stores one image from the stack of Ch3 determined by ni
        
        im(ni).mean_img2 = mean(mean(im(ni).double_img2)); % Compute mean of image from stack of Ch2 
    
        % Check to include the image only if there is a mean intensity of
        % greater than or equal to 7 otherwise move to the next image
        if im(ni).mean_img2 >= 7
            im(ni).origfig1 = figure();
            imagesc(im(ni).double_img1) % Display the image from stack of Ch1
            colormap gray % Converted to gray scale
            axis tight; axis equal; axis off % Axis of the displayed image made tight, equal and turned off
                    
            im(ni).origfig2 = figure(); 
            imagesc(im(ni).double_img2) % Display the image from stack of Ch2
            colormap gray % Converted to gray scale
            axis tight; axis equal; axis off % Axis of the displayed image made tight, equal and turned off
                    
            im(ni).origfig3 = figure();
            imagesc(im(ni).double_img3) % Display the image from stack of Ch3
            colormap gray % Converted to gray scale
            axis tight; axis equal; axis off % Axis of the displayed image made tight, equal and turned off
                    
            SubImageTotal = 1+SubImageTotal;
            
            % Calculate the ratio of image from stack in Ch1 to Ch2
            im(ni).ratio_img = im(ni).double_img1./im(ni).double_img2; 

            % Making a binary image mask from Ch2. Only those pixels get a
            % value of 1 that have an intensity value of greater than or
            % equal to the mean intensity value for Ch2 image
            im(ni).mask_img2(1:256,1:256) = 0;   % Change 256 to general for any sized image
            im(ni).mask_img2 = im(ni).double_img2 >= im(ni).mean_img2;
%             for i = 1:256   
%                 for j = 1:256
%                     if im(ni).double_img2(i,j) >= im(ni).mean_img2
%                         im(ni).mask_img2(i,j) = 1;
%                     end
%                 end
%             end
% figure()
% imagesc(mask_img2)
% colormap gray

            % Design a log filter (10 by 10 and sigma of 0.5)
            im(ni).logfilter=fspecial('log',log_size,log_sigma);
% figure()
% mesh(logfilter)
            
            % Applying log filter to the Ch2 image
            im(ni).filt_img2=imfilter(im(ni).double_img2,im(ni).logfilter);
% figure()
% imagesc(filt_img2)
% colormap gray
            
            % Multiplying the masked image with the filtered image to throw
            % away pixels that were below mean intenisty of ch2 image
            im(ni).filtered_img2 = im(ni).mask_img2.*im(ni).filt_img2;
% figure()
% imagesc(filtered_img2)
% colormap gray
            
            % Find a threshold of the image using Otsu threshold of
            % the filtered image from above
            im(ni).graylevel = graythresh(im(ni).filtered_img2(7:end-6,7:end-6)); % 6 pixels at the borders are not included
            im(ni).bw_img2 = im2bw(im(ni).filtered_img2(7:end-6,7:end-6),im(ni).graylevel); % Thresholded image converted to binary
% figure()
% imshow(im(ni).bw_img2)
            
            % All small regions are removed using bwareaopen function
            im(ni).BW1 = bwareaopen(im(ni).bw_img2, Pixel_threshold, Pixel_connectivity);
% figure()
% imshow(im(ni).BW1)          

            [im(ni).L, im(ni).num] = bwlabel(im(ni).BW1, 4);                             
%             for n = 1:im(ni).num
                im(ni).stats1 = regionprops(im(ni).L, im(ni).double_img1(7:end-6,7:end-6),'MinIntensity');
                im(ni).stats2 = regionprops(im(ni).L, im(ni).double_img2(7:end-6,7:end-6),'MinIntensity');
                im(ni).stats3 = regionprops(im(ni).L, im(ni).double_img3(7:end-6,7:end-6),'MinIntensity');                        
%             end
        
            flag = 0;
            im(ni).newL = im(ni).L;
            for s = 1:length(im(ni).stats1)
                if im(ni).stats3(s).MinIntensity == 0
                    [im(ni).r,im(ni).c] = find(im(ni).L == s);
                    for nrc = 1:length(im(ni).r)
                        im(ni).newL(im(ni).r(nrc),im(ni).c(nrc)) = 0;
                    end                        
                    flag = flag + 1;
                else
                    [im(ni).r,im(ni).c] = find(im(ni).L == s);
                    for nrc = 1:length(im(ni).r)
                        im(ni).newL(im(ni).r(nrc),im(ni).c(nrc)) = im(ni).L(im(ni).r(nrc),im(ni).c(nrc)) - flag;
                    end
                end 
            end
            
            colormap_string = sprintf('%s',color_map);
            im(ni).RGB = label2rgb(im(ni).newL,colormap_string,'k','shuffle');
            im(ni).RGBfig = figure();
            imagesc(im(ni).RGB)
            axis equal; axis tight; axis off
            hold on
            
%             for newn = 1:im(ni).newnum
                im(ni).newstats1 = regionprops(im(ni).newL, im(ni).double_img1(7:end-6,7:end-6), 'MeanIntensity', 'Area','Centroid','Extrema');
                im(ni).newstats2 = regionprops(im(ni).newL, im(ni).double_img2(7:end-6,7:end-6), 'MeanIntensity', 'Area','Centroid','Extrema');
                im(ni).newstats3 = regionprops(im(ni).newL, im(ni).double_img3(7:end-6,7:end-6), 'MeanIntensity', 'Area','Centroid','Extrema');                        
%             end                
               
            for news = 1:length(im(ni).newstats1)
                im(ni).stats(news).MeanIntensity = im(ni).newstats1(news).MeanIntensity/im(ni).newstats2(news).MeanIntensity;
                im(ni).Ratio_MeanIntensity(news,1) = im(ni).stats(news).MeanIntensity;
                im(ni).img2_MeanIntensity(news,1) = im(ni).newstats2(news).MeanIntensity;
                im(ni).img1_MeanIntensity(news,1) = im(ni).newstats1(news).MeanIntensity;
                im(ni).img3_MeanIntensity(news,1) = im(ni).newstats3(news).MeanIntensity;
                im(ni).SubImageNo(news,1) = SubImageTotal;  
                
                text(im(ni).newstats2(news).Extrema(8,1),im(ni).newstats2(news).Extrema(8,2),num2str(news),'BackgroundColor','w','color','r','Fontsize',5)
            end
            hold off
        
            im(ni).RegionNo = 1:length(im(ni).newstats1);      
        
%         hist_x = 10;
%         figure()
%         hist(im(ni).Ratio_MeanIntensity,hist_x)
% 
%         figure()
%         hist(im(ni).img2_MeanIntensity,hist_x)
% 
%         figure()
%         hist(im(ni).img1_MeanIntensity,hist_x)
               
            mainim(filen).Titles = sprintf(' SubImageNumber Region Ch1MeanIntensity Ch2MeanIntensity RatioMeanIntensity TauMeanIntensity');
            mainim(filen).Measurements = [im(ni).SubImageNo im(ni).RegionNo' im(ni).img1_MeanIntensity im(ni).img2_MeanIntensity im(ni).Ratio_MeanIntensity im(ni).img3_MeanIntensity];
            mainim(filen).ImageNameSlash1 = max(strfind(ImageName1,'\'));
            mainim(filen).ImageNameUnderscore1 = max(strfind(ImageName1,'_'));
            mainim(filen).ImageNameSlash2 = max(strfind(ImageName2,'\'));
            mainim(filen).ImageNameSlash3 = max(strfind(ImageName3,'\'));
            filename = sprintf('Measurements_Img%s',ImageName1(mainim(filen).ImageNameSlash1+1:mainim(filen).ImageNameUnderscore1-1));
            origfigname1 = sprintf('Original_SubImg%d_Img%s',ni,ImageName1(mainim(filen).ImageNameSlash1+1:end));
            RGBfigname = sprintf('ROI_SubImg%d_Img%s',ni,ImageName2(mainim(filen).ImageNameSlash2+1:end));
            origfigname2 = sprintf('Original_SubImg%d_Img%s',ni,ImageName2(mainim(filen).ImageNameSlash2+1:end));        
            origfigname3 = sprintf('Original_SubImg%d_Img%s',ni,ImageName3(mainim(filen).ImageNameSlash3+1:end));
            cd(predir)
            if ni == 1
                flagstr=writestr(filename,mainim(filen).Titles,'overwrite');
                flagdat=writedat(filename,mainim(filen).Measurements,'append');
            else
                flagdat=writedat(filename,mainim(filen).Measurements,'append');
            end
            saveas(im(ni).origfig1,origfigname1);
            saveas(im(ni).RGBfig,RGBfigname);
            saveas(im(ni).origfig2,origfigname2);
            saveas(im(ni).origfig3,origfigname3);
            close(im(ni).origfig1); close(im(ni).origfig2); close(im(ni).origfig3); close(im(ni).RGBfig); 
        end
    end
    clear im
end
fprintf('Congratulations! The Analysis is over - You did it!!');