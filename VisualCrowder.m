function coordLoc = VisualCrowder(crowdedStim,n,distance,size)
% This function computes location of crowding stimuli

% crowdedStim = is 1x2 vector of center stimulus lacatoin [x y] in pixel
% n = is an integer number of crowding stimuli
% distance = distance from visual stimuli at center in visual angle
% crowderLoc = is 4xn matrix contianing coordinates of crowding stimuli
% size = is floater an is the size of stimulus

% initialize theta

theta = [];
for i = 1:n
    theta(i) = 2*pi/n * (i - 1);
end

coordCenter = [distance*cos(theta)', distance*sin(theta)'];
coordCenter(:,1) = coordCenter(:,1) + crowdedStim(1);
coordCenter(:,2) = coordCenter(:,2) + crowdedStim(2);

coordLoc = coordCenter';
coordLoc = [coordLoc;coordLoc]
for j=1:4
   if  j<3 
       coordLoc(j,:) = coordLoc(j,:) - size/2
   else
       coordLoc(j,:) = coordLoc(j,:) + size/2
   end
end

% plot(coordCenter(:,1),coordCenter(:,2),'ro','MarkerSize',15,'MarkerFaceColor','r')
% hold on
% ezpolar(@(x)5);
% axis equal


end

