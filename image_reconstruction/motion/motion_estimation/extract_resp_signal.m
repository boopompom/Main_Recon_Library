function respiration = extract_resp_signal(kc,method)
% Process self-navigation data to pass it to the coilclustering function
%
% Version 20180122

nav=abs(permute(kc,[2 1 3]));
[nz,ntviews,nc] = size(nav);

% Normalize all projections from all receivers 
for c=1:nc
    for t=1:ntviews
        % Normalize
        maxprof = max(nav(:,t,c));
        minprof = min(nav(:,t,c));
        nav(:,t,c) = (nav(:,t,c)-minprof)./(maxprof-minprof);
    end    
end

nav=permute(nav,[2 1 3]); % [dyn z coil]

%% Moving average method 
if strcmpi(method,'maf')
    % Note this can be any method, this is a very simple one.
    
    % Get mean navigator
    avg_nav=squeeze(median(nav,1));
    
    % Calculate distance from the mean for each projections
    d=[];F=@(xx)(ifftshift(fft(fftshift(xx))));
    for c=1:nc
        for t=1:ntviews
            tmp=angle(F(abs(avg_nav(:,c)))'.*conj(F(abs(squeeze(nav(t,:,c))))));
            %subplot(211);plot(squeeze(nav(t,:,c)));subplot(212);plot(tmp);pause();
            supp=round(numel(tmp)/2)-1:ceil(numel(tmp)/2)+1;
            slope=tmp(supp(3))-tmp(supp(1))/2;
            d(t,c)=slope*(nz/4)/(2*pi);
        end
    end
    
    % Filter angular dependency
    %d=angular_dependency_filter(d);
    d=moving_average_filter(d,8);
end

%% PCA method
if strcmpi(method,'pca')
    kk=1;
    for c=1:nc
        tmp=permute(nav(:,:,c),[2 3 1]);
        tmp=abs(reshape(tmp,[size(tmp,1)*size(tmp,2),ntviews])');
        covariance=cov(tmp);
        [tmp2, V]=eig(covariance);
        V=diag(V);
        [~, rindices]=sort(-1*V);
        V=V(rindices);
        tmp2=tmp2(:,rindices);
        PC=(tmp2' * tmp')';
        
        % Take the first two principal components from each coil element.
        for jj=1:2
            tmp3=smooth(PC(:,jj),6,'lowess'); % do some moving average smoothing
            tmp3=PC(:,jj);
            %Normalize the signal for display
            %tmp3=tmp3-min(tmp3(:));
            %tmp3=tmp3./max(tmp3(:));
            d(:,kk)=tmp3;
            kk=kk+1;
        end
    end
end

%% Do coil clusting to find the respiratory motion signal
% Function obtained from Tao Zhang (http://web.stanford.edu/~tzhang08/software.html)
thresh=0.95;
[respiration, ~]=coilClustering(d,thresh);


% END
end


