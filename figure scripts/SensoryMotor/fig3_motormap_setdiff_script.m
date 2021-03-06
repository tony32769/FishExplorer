% this script performs two sets of regression (second set with both tRes
% and lrRes), and calculates 'setdiff' in both directions, respectively. 
% i.e. A minus B, B minus A. These two anat plots are then concatenated. 

clear all; close all; clc


%% folder setup
isSaveFig = 1;
isPlotFig = 1;

outputDir = GetOutputDataDir;

        
ClusterIDs = [11,2]; % init; can overrride
prct_const = 2; % init; can overrride
range_fish = GetFishRange;% init; can overrride

caseflag = 4;
switch caseflag % NOTE: regressors hard-coded!
    case 1 % main
        isSetDiffnotIntersect = 1;
        is1RegInA = 0;
        M_isTrialRes = [0,1];
        M_reg_name{1} = 'motormap_tAvr_VS_tRes_motorseed2_setdiff';
        
    case 2 % suppl to case 1
        isSetDiffnotIntersect = 0;
        is1RegInA = 0;
        M_isTrialRes = [0,1];
        M_reg_name{1} = 'motormap_tAvr_VS_tRes_motorseed2_intunion';
        
    case 3 % not used
        isSetDiffnotIntersect = 1;
        is1RegInA = 1;
        M_isTrialRes = [1,1];
        M_reg_name{1} = 'motormap_lrAND_VS_lrtRes_motorseed2_setdiff';
%         M_reg_name{1} = 'motormap_lrtAvr_VS_lrtRes_motorseed2_setdiff';
              
%     case 4 % good for forward seed
%         isSetDiffnotIntersect = 1;
%         is1RegInA = 1;
%         M_isTrialRes = [0,0];
%         M_reg_name{1} = 'motormap_lrAvr_VS_lrRes_motorseed2_setdiff';  
        
    case 4 % may replace case 4 above, for revised draft
        isSetDiffnotIntersect = 1;
        is1RegInA = 1; 
        M_isTrialRes = [1,1];
        M_reg_name{1} = 'motormap_lrAvr_VS_lrRes_motorseed2-tRes_setdiff';
        
    case 5 % good for AHC/HBO flip? setdiff prob not worth it
        isSetDiffnotIntersect = 1;
        is1RegInA = 0; 
        M_isTrialRes = [0,1];
        M_reg_name{1} = 'motormap_df_VS_lrtRes_motorseed2_setdiff'; 
        
    case 6 % eye map! main
        isSetDiffnotIntersect = 1;
        is1RegInA = 0;
        M_isTrialRes = [0,1];
        M_reg_name{1} = 'eyemap_tAvr_VS_tRes_setdiff';
        
        ClusterIDs = [12,1]; % override
        prct_const = 0.5; % override
        range_fish = [1:8,11,12,14:17]; % skip 13, difficult 9,10,18
end

% stimrange = 2;

M_fishrange_im{1} = range_fish;
n_reg = 1;

i_set = 1;

%% init

hfig = figure;
InitializeAppData(hfig);
ResetDisplayParams(hfig);

setappdata(hfig,'isMotorseed',1);


%% run fish

M_thres_reg = zeros(3,18);
M_numTopCorr = zeros(1,18);
M_motorseedRegs = cell(1,18);
M_compareMotorCellNumber = zeros(2,18);

IM_full = cell(n_reg,18);
IM_AB = cell(n_reg,18);

%%
for i_fish = range_fish
    
    
    %% regression (in tRes), thresholding by % of cells (instead of corr thres)
    M_cIX = cell(1,2);
    M_gIX = cell(1,2);
    for i_itr = 1:2
        setappdata(hfig,'isTrialRes',M_isTrialRes(i_itr));

        [cIX_seed,gIX_seed,M,stim,behavior,M_0] = LoadSingleFishDefault(i_fish,hfig,ClusterIDs);

        switch caseflag
            case {1,2,6}
                if i_itr == 1 % isTrialRes = 0
                    C = FindClustermeans(gIX_seed,M);
                    Reg = GetTrialAvrLongTrace(hfig,C); % tAvr of motorseeds
                else % isTrialRes = 1
                    Reg = FindClustermeans(gIX_seed,M); % tRes of motorseeds
                end
                
            case 3 % not used
                if i_itr == 1
                    C = FindClustermeans(gIX_seed,M);
                    Reg = C(1,:).*C(2,:);%mean(C); % LR average, with tRes
                else
                    C = FindClustermeans(gIX_seed,M);
                    Reg = C-repmat(mean(C),2,1); % lr_res, with tRes
                end
                
            case 4 % for L/R
                if i_itr == 1
                    C = FindClustermeans(gIX_seed,M);
                    Reg = mean(C); % LR average
                else
                    C = FindClustermeans(gIX_seed,M);
                    Reg = C-repmat(mean(C),2,1); % lr_res
                end
                
            case 5
                if i_itr == 1
                    Reg = FindClustermeans(gIX_seed,M); % default, not tRes
                else
                    C = FindClustermeans(gIX_seed,M);
                    Reg = C-repmat(mean(C),2,1); % lr_res, with tRes
                end
        end

        %% compute correlation
        Corr = corr(Reg',M_0');
        
        % keep best regression only
        [Corr_rows,corr_max] = ConvertCorrToBestRegRows(Corr);
        
        % top 2 %
        nCells_total = size(M_0,1);
        [CIX,RegThres] = ChooseTopPercentOfFish(nCells_total,prct_const,Corr_rows);
        
        if i_itr == 1 && is1RegInA
            cIX = CIX{1};
            % get map color
            reg_thres = 0.25;
            gIX = MapXto1Dcolormap(corr_max(cIX),[reg_thres,1],64);
        else    
            %%
            cIX1 = CIX{1};
            cIX2 = CIX{2};
            
            % get map color
            reg_thres = 0.25;
            clrIX1 = MapXto1Dcolormap(corr_max(cIX1),[reg_thres,1],64);
            clrIX2 = MapXto1Dcolormap(corr_max(cIX2),[reg_thres,1],64);
            %     clrIX1 = MapXto1Dcolormap(corr_max(cIX1),[reg_thres1,1],64);
            %     clrIX2 = MapXto1Dcolormap(corr_max(cIX2),[reg_thres2,1],64);
            
            cIX = [cIX1;cIX2];

            clrIX = [clrIX1;clrIX2];
            gIX_offset = [ones(size(cIX1));2*ones(size(cIX2))];
            gIX = clrIX+(gIX_offset-1)*64;
            %     gIX = [clrIX1;64+clrIX2];
            numK = length(unique(gIX));
        end
        %% pool stats
        %     M_thres_reg(1,i_fish) = reg_thres1;
        %     M_thres_reg(2,i_fish) = reg_thres2;
        %     M_compareMotorCellNumber(1,i_fish) = length(cIX1);
        %     M_compareMotorCellNumber(2,i_fish) = length(cIX2);
        M_cIX{i_itr} = cIX;
        M_gIX{i_itr} = gIX;
        
    end % i_itr ~ comparison
    
    %% Section 1: make the setdiff/intersection plots
    
    %% make double colormap
    clr1 = [1,0,0];
    clr1_ = [0.5,0.4,0.4];
    %     clr1_ = [0.7,0.5,0.5];
    clr2 = [0,1,1];
    clr2_ = [0.4,0.5,0.5];
    %     clr2_ = [0.5,0.7,0.7];
    numC = 64;
    clrmap1 = Make1DColormap([clr1_;clr1],numC);
    clrmap2 = Make1DColormap([clr2_;clr2],numC);
    clrmap = [clrmap1;clrmap2];
    
    %%
    if isSetDiffnotIntersect
        [cIX,ix] = setdiff(M_cIX{1},M_cIX{2});
        gIX = M_gIX{1}(ix);
        %     [set2,ix2] = setdiff(CIX{2},CIX{1});
        %     cIX = [set1;set2];
        %     gIX = [GIX{1}(ix1);GIX{2}(ix2)];
        % make figure
        I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
        [h,im_full1] = DrawCellsOnAnat(I);
        close(h);
        
        [cIX,ix] = setdiff(M_cIX{2},M_cIX{1});
        gIX = M_gIX{2}(ix);
        % make figure
        I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
        [h,im_full2] = DrawCellsOnAnat(I);
        close(h);
        
        %% save figure
        border = ones(size(im_full1,1),20,3);
        IM_full{i_set,i_fish} = horzcat(im_full1,border,im_full2);
        
    else
        [cIX,ix] = intersect(M_cIX{1},M_cIX{2});
        gIX = M_gIX{1}(ix);
        %     [set2,ix2] = setdiff(CIX{2},CIX{1});
        %     cIX = [set1;set2];
        %     gIX = [GIX{1}(ix1);GIX{2}(ix2)];
        % make figure
        I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
        [h,im_full1] = DrawCellsOnAnat(I);
        close(h);
        
        [C,ia,ib] = union(M_cIX{1},M_cIX{2});
        cIX = [M_cIX{1}(ia);M_cIX{2}(ib)];
        gIX = [M_gIX{1}(ia);M_gIX{2}(ib)];
        % make figure
        I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
        [h,im_full2] = DrawCellsOnAnat(I);
        close(h);
        %% save figure        
        border = ones(size(im_full1,1),20,3);
        IM_full{i_set,i_fish} = horzcat(im_full1,border,im_full2);
        
    end
    
    %% Section 2: plot the two original sets (same as fig3_motormap_trialRes_lrRes_tiffstack.m)
    cIX = M_cIX{1};
    gIX = M_gIX{1};
    % make figure
    I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
    [h,im_full3] = DrawCellsOnAnat(I);
    close(h);
    
    cIX = M_cIX{2};
    gIX = M_gIX{2};
    % make figure
    I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
    [h,im_full4] = DrawCellsOnAnat(I);
    close(h);
    %% save figure
    border = ones(size(im_full3,1),20,3);
    IM_AB{i_set,i_fish} = horzcat(im_full3,border,im_full4);

end

%% draw color bars - to save???
figure
ax = axes('Position',[0.75,0.8,0.05,0.15],'Units','normalized');
DrawCustomColorbar(clrmap1,[reg_thres,1],2,ax);

ax = axes('Position',[0.9,0.8,0.05,0.15],'Units','normalized');
DrawCustomColorbar(clrmap2,[reg_thres,1],2,ax);

%% save as tiff stack
for i_set = 1:n_reg
    range_im = M_fishrange_im{i_set};
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_allfish.tiff']);
    IM = IM_full(i_set,range_im);
    
    SaveImToTiffStack(IM,tiffdir);
end

%% Average Plot
% M_k_scale = {1,1.5,1};
% M_k_contrast = {1.2,1.5,1.2};

% optional override::::
% M_fishrange_im{1} = [1,3,5:17];
% M_fishrange_im{1} = 8:17;% for OMR
for i_set = 1:n_reg;
    range_im = M_fishrange_im{i_set};%[1:3,5:7];%[1:3,5:18];
    cellarray = IM_full(i_set,range_im);
    
    % adjust params for visualization
    k_scale = 0.7;%1/1.5;%M_k_scale{i_set};
    k_contrast = 1.1;%M_k_contrast{i_set};
    
    [h_anat,im_avr] = AverageAnatPlot(cellarray,k_contrast,k_scale);
    
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_avr.tiff']);
    imwrite(im_avr, tiffdir, 'compression','none','writemode','overwrite');
end

%% original sets: save as tiff stack
for i_set = 1:n_reg
    range_im = M_fishrange_im{i_set};
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_AB_allfish.tiff']);
    IM = IM_AB(i_set,range_im);
    
    SaveImToTiffStack(IM,tiffdir);
end

%% original sets: Average Plot
% M_k_scale = {1,1.5,1};
% M_k_contrast = {1.2,1.5,1.2};

% optional override::::
% M_fishrange_im{1} = [1,3,5:17];
% M_fishrange_im{1} = 8:17;% for OMR
for i_set = 1:n_reg;
    range_im = M_fishrange_im{i_set};%[1:3,5:7];%[1:3,5:18];
    cellarray = IM_AB(i_set,range_im);
    
    % adjust params for visualization
    k_scale = 0.7;%1/1.5;%M_k_scale{i_set};
    k_contrast = 1.1;%M_k_contrast{i_set};
    
    [h_anat,im_avr] = AverageAnatPlot(cellarray,k_contrast,k_scale);
    
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_AB_avr.tiff']);
    imwrite(im_avr, tiffdir, 'compression','none','writemode','overwrite');
end

%%
if 0
    %% [for later] plot from tiff stack
    isPlotfromtiffstack = 0;
    
    if isPlotfromtiffstack
        IM_full = cell(n_reg,18);
        for i_set = 1:n_reg
            %% get tiff-stack path
            tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_allfish.tiff']);
            
            %% load
            
            for i_fish = 1:18
                im = double(imread(tiffdir,i_fish))./255;
                IM_full{i_set,i_fish} = im(317:1236,1:621,:);
            end
        end
    end
end

%%
% range_fish excludes Fish 4
% M_compareMotorCellNumber(:,4) = NaN;
% figure;bar(M_compareMotorCellNumber')
