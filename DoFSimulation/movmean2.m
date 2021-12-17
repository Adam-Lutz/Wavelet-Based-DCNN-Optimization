function im_out = movmean2( im_in, N )
    tmp     = movmean(im_in, N, 1);
    im_out  = movmean(tmp,   N, 2);
end
