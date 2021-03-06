function batch_dense_green2(fgreen,data,fsave)

% DMM 08/2011
%
% Make Green functions for multiple inversion nodes
%
% IN:
% 
% fgreen ~ Name of Green function file computed in EDGRN
% data ~ Structure containing the data and metadata
% fsave ~ Filename for Green functions matrix (absolute path)

%Paths where EDGRN GFs are stored
pathgf='/diego-local/scripts/Fortran/ED/grnfcts'
%Path where data is stored
pathdata='/diego-local/Research/Data/Toki'
cd(pathdata)
%Compute GF derivatives?
derivflag=0;
dGF=2000;  

% % Make inversion nodes
% %[longrid latgrid zgrid]=textread('fault.xyz','%f%f%f');
% %[longrid latgrid zgrid]=textread('slab1.0.xyz','%f%f%f');
% [longrid latgrid zgrid]=textread('slab1.0small.xyz','%f%f%f');
% longrid=longrid';
% latgrid=latgrid';
% zgrid=zgrid;
% zgrid=-zgrid';
% % i=find(longrid>134 & longrid<180);
% % zgrid=zgrid(i);
% % latgrid=latgrid(i);
% % longrid=longrid(i);
% % i=find(latgrid>40 & latgrid<44);
% % i=find(zgrid>150);
% % zgrid=zgrid(i);
% % latgrid=latgrid(i);
% % longrid=longrid(i);
% display('Creating grid on plate interface...')
% ________________

% % % Prism around epicentre
% [longrid latgrid zgrid]=makegrid(-115.28,32.192,10e3,0.1,0.1,2e3,14,14,10);
% %[longrid latgrid zgrid]=makegrid(144.00,42.2,35e3,0.2,0.2,3e3,14,14,10);
% % [longrid latgrid zgrid]=makegrid(143.84,42.21,27e3,0.3,0.3,3e3,0,0,0)
% % [longrid latgrid zgrid]=makegrid(142.969,38.321,20e3,0.2,0.2,3e3,1,1,1);
% [longrid latgrid zgrid]=makegrid(142,38,30e3,0.25,0.25,2.5e3,20,20,20);
% %[longrid latgrid zgrid]=makegrid(-100,16.5,20e3,0.2,0.2,2e3,16,16,16ongrid latgrid zgrid]=makegrid(37,138,50e3,0.01,0.01,1e3,1500,1500,100);
% i=find(zgrid<150e3);
% longrid=longrid(i);
% latgrid=latgrid(i);
% zgrid=zgrid(i);
% display('Creating prism grid around origin...')
% ____________

% Single sources
% % Toki
% longrid=[143.84]; 
% latgrid=[42.21];
% zgrid=[28e3];
% %Escenario2011
% latgrid= 16.5900;
% longrid= -99.0400;
% zgrid= 17.8200e3;
% % % El May
% % % longrid=[-115.37];
% % % latgrid=[32.35];
% % % zgrid=[8e3];
% % % Tohoku
% longrid=143.11;
% latgrid=37.92;
% zgrid=19.5e3;
% display('No grid created, single point inversion...')
% _____________

% Multiple point sources
% longrid=[141.5 141.75 142.00 142.25 142.50 142.75 143.00 143.25 143.50 143.75 144.0]; 
% latgrid=[34.75 35.5 36.00 36.75 37.25 38.00 38.75 39.50 40.00 40.50 41.25];
% % zgrid=[20e3 20e3 20e3 20e3 20e3 20e3 20e3 20e3 20e3 20e3 20e3];
% N=50;
% longrid=linspace(141.5,144,N);
% latgrid=linspace(34.75,41.25,N);
% zgrid=linspace(20e3,20e3,N);

% Large scale griding
lat=(35:0.2:48);
lon=(139:0.2:149);
z=(10e3:2e3:60e3);
Nz=max(size(z));
Nlon=max(size(lon));
Nlat=max(size(lat));
zgrid=repmat(z,Nlat*Nlon,1);
zgrid=reshape(zgrid,Nlat*Nlon*Nz,1);
longrid=repmat(lon,Nlat,1);
longrid=reshape(longrid,Nlat*Nlon,1);
longrid=repmat(longrid,Nz,1);
latgrid=repmat(lat',Nlon*Nz,1);
        


%No. of nodes
N=max(size(longrid));
%N=size(longrid,1);
%Station coordiantes
load(data)
%Select some data
%coseis=tohoku_clean;
% i=find(coseis.process==1);  %Useful data
i=1:1:size(coseis.T,1);
lat=coseis.lat(i)';
lon=coseis.lon(i)';

%Initalize
G=zeros(max(size(i))*3,5);
%Loop over inversion nodes and compute GFs
cd(pathgf)
%figure
%hold on
for j=1:N
    tic
    display(['Node ' num2str(j) ' of ' num2str(N) ' ...'])
    late = latgrid(j);
    lone = longrid(j);
    depth = zgrid(j);
    %Define current node as origin and compute (x,y) coords of stations (in
    %metres)
    %Get station info
    [dist,az] = distance(late,lone,lat,lon);
    dist=deg2km(dist)*1000;
    az=-az+90;
    az=deg2rad(az);
    [e n]=pol2cart(az,dist);
    x=n;
    y=e;
    az=atan2(y,x);
    %scatter(y,x)
    %MAKE KERNEL MATRIX __________________
    % 1.- G(i,j,k)
    [GZ1 GR1 GT1 GZ2 GR2 GT2 GZ3 GR3 GZ4 GR4 GT4 GZ5 GR5 GT5] =makegreen(fgreen,x',y',depth);
    R=buildrotmat(az,1,1);
    
    %Prepare inversion matrices
    display('Preparing matrices for inversion...')
    k=1;
    for i=1:size(GR1,1)
        %Vertical component of Gram matrix
        Gt(k,1)=GZ1(i);
        Gt(k,2)=GZ2(i);
        Gt(k,3)=GZ3(i);
        Gt(k,4)=GZ4(i);
        Gt(k,5)=GZ5(i);
        %Radial component of Gram matrix
        Gt(k+1,1)=GR1(i);
        Gt(k+1,2)=GR2(i);
        Gt(k+1,3)=GR3(i);
        Gt(k+1,4)=GR4(i);
        Gt(k+1,5)=GR5(i);
        %Tangential component of Gram matrix
        Gt(k+2,1)=GT1(i);
        Gt(k+2,2)=GT2(i);
        Gt(k+2,3)=0;
        Gt(k+2,4)=GT4(i);
        Gt(k+2,5)=GT5(i);
        k=k+3;
    end
    %Rotate to xyz
    G=R*Gt;
    cd(pathdata)
    cd denseGF
    save([fsave 'GF_' num2str(j)],'G','-ascii')
    cd(pathgf)
    toc
end
cd(pathdata)
cd denseGF
grid=vertcat(longrid,vertcat(latgrid,zgrid));
save([fsave '_grid'],'grid')