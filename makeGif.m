 h = figure;
filename = 'testAnimated.gif';
for n = 1:288:2880
plot(V_real(:,n))
pause(1)
drawnow
% Capture the plot as an image
frame = getframe(h);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);
% Write to the GIF File
if n == 1
imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
else
imwrite(imind,cm,filename,'gif','WriteMode','append');
end
end