clear all
close all

im_in       = imread( 'out_99.bmp' );
im_in       = double(im_in) / 255.0;        % convert to range 0.0 to 1.0, double

[depth_in, cmap]    = imread( 'out_99_depth.bmp' );
RGB = ind2rgb(depth_in, cmap);
depth_in2    = RGB( :, :, 1 );          % convert to gray
depth_in2 = (depth_in2 * 255);

depth_in2 = uint8(depth_in2);

num=1;
x1 = min(depth_in2(:));
x2 = max(depth_in2(:));
diff = (x2 - x1) / 6;
%x = linspace(min(depth_in2(:)),max(depth_in2(:)),6.0);
%diff = x(2) - x(1);
for i=x1:diff:x2
    subplot(2,3,num)
    im_out = sim_depth_of_field( im_in, depth_in2, double(i), 4.0 );

    imshow(im_out);
    drawnow;
    num = num + 1;
end
