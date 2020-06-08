function MRS_struct = SignalAveraging(MRS_struct, AllFramesFT, AllFramesFTrealign, ii, kk, vox)

% Initialize some variables/functions
MSEfun = @(a,b) sum((a - b).^2) / length(a);
experiment = {'A', 'B', 'C', 'D'};
if MRS_struct.p.HERMES
    n = 4;
else
    n = 2;
end

if MRS_struct.p.WeightedAveraging && ~strcmp(MRS_struct.p.vendor,'Siemens_rda')
    
    freqRange = MRS_struct.p.sw(ii)/MRS_struct.p.LarmorFreq(ii);
    freq = (MRS_struct.p.npoints(ii) + 1 - (1:MRS_struct.p.npoints(ii))) / MRS_struct.p.npoints(ii) * freqRange + 4.68 - freqRange/2;
    freqLim = freq <= 4.25 & freq >= 1.8;
    D = zeros(size(AllFramesFTrealign,2)/n);
    
    for ll = 1:n
        spec = ifft(ifftshift(AllFramesFTrealign(:,ll:n:end),1),[],1);
        spec = fftshift(fft(spec(1:MRS_struct.p.npoints(ii),:),[],1),1);
        for mm = 1:size(AllFramesFTrealign,2)/n
            D(mm,:) = feval(MSEfun, real(spec(freqLim,mm)), real(spec(freqLim,:)));
        end
        D(~D) = NaN;
        d = nanmedian(D);
        w = d.^-2 / sum(d.^-2);
        w = repmat(w, [size(AllFramesFTrealign,1) 1]);
        MRS_struct.spec.(vox{kk}).subspec.(experiment{ll})(ii,:) = sum(w .* AllFramesFTrealign(:,ll:n:end),2);
    end
    
else
    
    for ll = 1:n
        MRS_struct.spec.(vox{kk}).subspec.(experiment{ll})(ii,:) = mean(AllFramesFTrealign(:,ll:n:end),2);
    end
    
end

for jj = 1:length(MRS_struct.p.target)
    
    ON_ind  = find(MRS_struct.fids.ON_OFF(jj,1:n) == 1);
    OFF_ind = find(MRS_struct.fids.ON_OFF(jj,1:n) == 0);
    
    if MRS_struct.p.HERMES
        % ON
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).on(ii,:) = ...
            (MRS_struct.spec.(vox{kk}).subspec.(experiment{ON_ind(1)})(ii,:) + ...
            MRS_struct.spec.(vox{kk}).subspec.(experiment{ON_ind(2)})(ii,:)) / 2;
        % OFF
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).off(ii,:) = ...
            (MRS_struct.spec.(vox{kk}).subspec.(experiment{OFF_ind(1)})(ii,:) + ...
            MRS_struct.spec.(vox{kk}).subspec.(experiment{OFF_ind(2)})(ii,:)) / 2;
        % OFF_OFF
        OFF_OFF_ind = all(MRS_struct.fids.ON_OFF(:,1:n)' == 0,2);
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).off_off(ii,:) = ...
            MRS_struct.spec.(vox{kk}).subspec.(experiment{OFF_OFF_ind})(ii,:);
    else
        % ON
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).on(ii,:) = ...
            MRS_struct.spec.(vox{kk}).subspec.(experiment{ON_ind})(ii,:);
        % OFF
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).off(ii,:) = ...
            MRS_struct.spec.(vox{kk}).subspec.(experiment{OFF_ind})(ii,:);
    end
    
    % DIFF
    MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).diff(ii,:) = ...
        (MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).on(ii,:) - ...
        MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).off(ii,:)) / 2;
    
    % DIFF (unaligned)
    MRS_struct.spec.(vox{kk}).(MRS_struct.p.target{jj}).diff_noalign(ii,:) = ...
        (mean(AllFramesFT(:,MRS_struct.fids.ON_OFF(jj,:) == 1),2) - ...
        mean(AllFramesFT(:,MRS_struct.fids.ON_OFF(jj,:) == 0),2)) / 2;
    
end



