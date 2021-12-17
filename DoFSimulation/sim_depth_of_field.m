% IM_IN: two-dimensional array of RGB values, double precision float, e.g.
% dbl(hgt,wid,3)
% DEPTH_IN          : two-dimensional array of grayscale, uint8, range 0..255
% FOCUS_DEPTH       : depth that is in perfect focus
% DEPTH_OF_FIELD    : difference in depth, inside which there is no blur

function im_out = sim_depth_of_field( im_in, depth_in, focus_depth, depth_of_field )

    sz = size( im_in );
    hgt = sz(1);
    wid = sz(2);

    % Compute a family of filtered images
    im_3 = movmean2(im_in, 3);
    im_5 = movmean2(im_in, 5);
    im_9 = movmean2(im_in, 9);
    im_17 = movmean2(im_in, 17);
    im_33 = movmean2(im_in, 33);
    im_65 = movmean2(im_in, 65);
    
    im_out = zeros(hgt,wid,3);
    
    for i=0:(hgt-1)
        for j=0:(wid-1)
            depth_cur = double(depth_in(i+1, j+1));

            blur_wid = int32(((depth_cur - focus_depth)/depth_of_field)^2);
            if (blur_wid == 0)
                blurred_pel = squeeze(im_in(i+1,j+1,:));
            else
                if (blur_wid < 2)
                    blurred_pel = squeeze(im_3(i+1,j+1,:));
                elseif (blur_wid < 4)
                    blurred_pel = squeeze(im_5(i+1,j+1,:));
                elseif (blur_wid < 8)
                    blurred_pel = squeeze(im_9(i+1,j+1,:));
                elseif (blur_wid < 16)
                    blurred_pel = squeeze(im_17(i+1,j+1,:));
                elseif (blur_wid < 32)
                    blurred_pel = squeeze(im_33(i+1,j+1,:));
                else
                    blurred_pel = squeeze(im_65(i+1,j+1,:));
                end
            end                     % end if blur != 0
            im_out(i+1,j+1,:) = blurred_pel;
        end                 % end for j
    end                     % end for i
end


                