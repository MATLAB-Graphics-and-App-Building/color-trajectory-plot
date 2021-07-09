function [x, y, c] = randomWalk
% randomWalk Generate a random walk across a space
% [x, y, c] = randomWalk() Generate a random walk across a 2D area that is
% 200 x 200 in area, along with a color vector that indicates a rate based
% on proximity to a randomly calculated hot spot.

% Copyright 2020-2021 The MathWorks, Inc.

% Maximum distance in x and y allowed from [0 0].
w = 100;

% Number of points to generate.
n = 20000;

% [x y dx dy ddx ddy]
xy = NaN(n,6);
xy(1,:) = [0 0 randn(1,4)];

% Dampening of the velocity.
d = 0.7;

% Update matrix
m = [1 0 1 0 1/2 0;
    0 1 0 1 0 1/2
    0 0 d 0 1 0;
    0 0 0 d 0 1
    0 0 0 0 1 0
    0 0 0 0 0 1];

for s = 2:n
    % Calculate the next location, velocity, and accelaration.
    xy(s,:) = xy(s-1,:) * m';
    
    % Bounce off the walls without losing any velocity.
    bounce = abs(xy(s,1:2))>w;
    xy(s,bounce) = sign(xy(s,bounce)).*(2*w-abs(xy(s,bounce)));
    xy(s,[false false bounce]) = -xy(s,[false false bounce]);
    
    % Randomly choose the accelaration for the next iteration.
    xy(s,5:6) = randn(1,2);
end

% Extract the x and y position from the output.
x = xy(:,1);
y = xy(:,2);

% Pick a random "hot spot"
h = rand(1,2)*200-100;
s = rand(1,2)*10+10;
c = exp(-(([x y]-h).^2)/(2*s.^2));

end
