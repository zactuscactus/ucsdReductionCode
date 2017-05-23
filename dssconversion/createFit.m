function [fitresult, gof] = createFit(x2, y)
%CREATEFIT(X2,Y)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : x2
%      Y Output: y
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 28-Mar-2013 23:05:29


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( x2, y );

% Set up fittype and options.
ft = fittype( 'a*cos(b*(x-c) + d)+e', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( ft );
opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.Lower = [-Inf -Inf -Inf -Inf -Inf];
opts.StartPoint = [600 2.5 0.5 0.5688 0];
opts.Upper = [Inf Inf Inf Inf Inf];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
legend( h, 'y vs. x2', 'untitled fit 1', 'Location', 'NorthEast' );
% Label axes
xlabel( 'x2' );
ylabel( 'y' );
grid on

