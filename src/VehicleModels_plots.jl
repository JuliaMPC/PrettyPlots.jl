module VehicleModels_plots

using NLOptControl
using VehicleModels
using Plots

include("NLOptControl_plots.jl")
using .NLOptControl_plots

export
      obstaclePlot,
      trackPlot,
      mainSim,
      posterP,
      posPlot,
      vtPlot

"""
# to visualize the current obstacle in the field
obstaclePlot(n,c)

# to run it after a single optimization
pp=obstaclePlot(n,r,s,c,1);

# to create a new plot
pp=obstaclePlot(n,r,s,c,idx);

# to add to an exsting position plot
pp=obstaclePlot(n,r,s,c,idx,pp;(:append=>true));

# posterPlot
pp=obstaclePlot(n,r,s,c,ii,pp;(:append=>true),(:posterPlot=>true)); # add obstacles

--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 4/3/2017 \n
--------------------------------------------------------------------------------------\n
"""

function obstaclePlot(n,r,s,c,idx,args...;kwargs...)
  kw = Dict(kwargs);

  # check to see if is a basic plot
  if !haskey(kw,:basic); kw_ = Dict(:basic => false); basic = get(kw_,:basic,0);
  else; basic=get(kw,:basic,0);
  end

  # check to see if is a poster plot
  if !haskey(kw,:posterPlot); kw_ = Dict(:posterPlot=>false); posterPlot= get(kw_,:posterPlot,0);
  else; posterPlot=get(kw,:posterPlot,0);
  end

  # check to see if user wants to reduce the size of the markers TODO get ride of this eventually
  if !haskey(kw,:smallMarkers);smallMarkers=false;
  else;smallMarkers=get(kw,:smallMarkers,0);
  end


  if basic
    s=Settings();
    pp=plot(0,leg=:false)
    if !isempty(c.o.A)
      for i in 1:length(c.o.A)
          # create an ellipse
          pts = Plots.partialcircle(0,2π,100,c.o.A[i])
          x, y = Plots.unzip(pts)
          tc=0;
          x += c.o.X0[i] + c.o.s_x[i]*tc;
          y = c.o.B[i]/c.o.A[i]*y + c.o.Y0[i] + c.o.s_y[i]*tc;
          pts = collect(zip(x, y))
          if i==1
            scatter!((c.o.X0[i],c.o.Y0[i]),marker=(:circle,:red,s.ms2,1),label="Obstacles")
          end
          plot!(pts,line=(s.lw1,0.0,:solid,:red),fill=(0, 1, :red),leg=true,label="")
      end
    end
  else
    # check to see if user would like to add to an existing plot
    if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
    else; append = get(kw,:append,0);
    end
    if !append; pp=plot(0,leg=:false); else pp=args[1]; end

    # plot the goal; assuming same in x and y
    if c.g.name!=:NA
      if isnan(n.XF_tol[1]); rg=1; else rg=n.XF_tol[1]; end
      if !posterPlot || idx ==r.eval_num
        pts = Plots.partialcircle(0,2π,100,rg);
        x, y = Plots.unzip(pts);
        x += c.g.x_ref;  y += c.g.y_ref;
        pts = collect(zip(x, y));
        if !smallMarkers  #TODO get ride of this-> will not be a legend for this case
          scatter!((c.g.x_ref,c.g.y_ref),marker=(:circle,:green,s.ms2,1.0),label="Goal")
        end
        plot!(pts,line=(s.lw1,1,:solid,:green),fill=(0,1,:green),leg=true,label="")
      end
    end

    if c.o.name!=:NA
      for i in 1:length(c.o.A)
        # create an ellipse
        pts = Plots.partialcircle(0,2π,100,c.o.A[i])
        x, y = Plots.unzip(pts)
        if s.MPC
          x += c.o.X0[i] + c.o.s_x[i]*r.dfs_plant[idx][:t][end];
          y = c.o.B[i]/c.o.A[i]*y + c.o.Y0[i] + c.o.s_y[i]*r.dfs_plant[idx][:t][end];
        else
          if r.dfs[idx]!=nothing
            tc=r.dfs[idx][:t][end];
          else
            tc=0;
            warn("\n Obstacles set to inital condition for current frame!! \n")
          end
          x += c.o.X0[i] + c.o.s_x[i]*tc;
          y = c.o.B[i]/c.o.A[i]*y + c.o.Y0[i] + c.o.s_y[i]*tc;
        end
        pts = collect(zip(x, y))
        X=c.o.X0[i] + c.o.s_x[i]*r.dfs_plant[idx][:t][end]
        Y=c.o.Y0[i] + c.o.s_y[i]*r.dfs_plant[idx][:t][end];
        if posterPlot
          shade=idx/r.eval_num;
          if idx==r.eval_num && i==4  # NOTE either the obstacles increase in size or we do not get a legend, so this is a fix for now ! -> making it an obstacle that does not appear on the plot at that time
            plot!(pts,line=(s.lw1,shade,:solid,:red),fill=(0,shade,:red),leg=true,label="Obstacles")
          else
            plot!(pts,line=(s.lw1,0.0,:solid,:red),fill=(0,shade,:red),leg=true,label="")
          end
          annotate!(X,Y,text(string(idx*c.m.tex,"s"),10,:black,:center))
        else
          if i==1 &&!smallMarkers
            scatter!((X,Y),marker=(:circle,:red,s.ms2,1.0),label="Obstacles")
          end
          plot!(pts,line=(s.lw1,0.0,:solid,:red),fill=(0,1.0,:red),leg=true,label="")
        end
      end
    end

    xaxis!(n.state.description[1]);
    yaxis!(n.state.description[2]);
    if !s.simulate savefig(string(r.results_dir,"/",n.state.name[1],"_vs_",n.state.name[2],".",s.format)); end
  end
  return pp
end

obstaclePlot(n,c)=obstaclePlot(n,1,1,c,1,;(:basic=>true))

#=
using Plots
import Images
#ENV["PYTHONPATH"]="/home/febbo/.julia/v0.5/Conda/deps/usr/bin/python"
img=Images.load(Pkg.dir("PrettyPlots/src/humvee.png"));
plot(img)
=#
"""
pp=vehiclePlot(n,r,s,c,idx);
pp=vehiclePlot(n,r,s,c,idx,pp;(:append=>true));
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 4/4/2017 \n
--------------------------------------------------------------------------------------\n
"""
function vehiclePlot(n,r,s,c,idx,args...;kwargs...)
  kw = Dict(kwargs);

  # check to see if user wants to zoom
  if !haskey(kw,:zoom); kw_=Dict(:zoom => false); zoom=get(kw_,:zoom,0);
  else; zoom=get(kw,:zoom,0);
  end

  # check to see if user would like to add to an existing plot
  if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
  else; append = get(kw,:append,0);
  end
  if !append; pp=plot(0,leg=:false); else pp=args[1]; end

  # check to see if is a poster plot
  if !haskey(kw,:posterPlot); kw_ = Dict(:posterPlot=>false); posterPlot=get(kw_,:posterPlot,0);
  else; posterPlot=get(kw,:posterPlot,0);
  end

  # check to see if we want to set the limits to the position constraints
  if !haskey(kw,:setLims);setLims=false;
  else;setLims=get(kw,:setLims,0);
  end

  # check to see if user wants to reduce the size of the markers TODO get ride of this eventually
  if !haskey(kw,:smallMarkers);smallMarkers=false;
  else;smallMarkers=get(kw,:smallMarkers,0);
  end

  # contants
  w=1.9; #width TODO move these to vehicle parameters
  h=3.3; #height
  XQ = [-w/2 w/2 w/2 -w/2 -w/2];
  YQ = [h/2 h/2 -h/2 -h/2 h/2];

  # plot the vehicle
  if s.MPC
    X_v = r.dfs_plant[idx][:x][end]  # using the end of the simulated data from the vehicle model
    Y_v = r.dfs_plant[idx][:y][end]
    PSI_v = r.dfs_plant[idx][:psi][end]-pi/2
  else
    X_v = r.dfs[idx][:x][1] # start at begining
    Y_v = r.dfs[idx][:y][1]
    PSI_v = r.dfs[idx][:psi][1]-pi/2
  end

  P = [XQ;YQ];
  ct = cos(PSI_v);
  st = sin(PSI_v);
  R = [ct -st;st ct];
  P2 = R * P;
  if !posterPlot || idx==r.eval_num
    if !smallMarkers # for legend
      scatter!((X_v,Y_v),marker=(:black,:rect,s.ms1,0.8,stroke(3,:black)), grid=true,label="Vehicle")
    end
  end
  scatter!((P2[1,:]+X_v,P2[2,:]+Y_v),ms=0,fill=(0,1,:black),leg=true,grid=true,label="")
  #scatter!((P2[1,:]+X_v,P2[2,:]+Y_v),fill=(0,1,:black),leg=true,grid=true,label="")

  if !zoom && !setLims
    if s.MPC  # TODO push this to a higher level
      xL=minDF(r.dfs_plant,:x);xU=maxDF(r.dfs_plant,:x);
      yL=minDF(r.dfs_plant,:y);yU=maxDF(r.dfs_plant,:y);
    else
      xL=minDF(r.dfs,:x);xU=maxDF(r.dfs,:x);
      yL=minDF(r.dfs,:y);yU=maxDF(r.dfs,:y);
    end
      dx=xU-xL;dy=yU-yL; # axis equal
      if dx>dy; yU=yL+dx; else xU=xL+dy; end
      xlims!(xL,xU);
      ylims!(yL,yU);
  else
    xlims!(X_v-20.,X_v+80.);
    ylims!(Y_v-50.,Y_v+50.);
  end

  if posterPlot
    t=idx*c.m.tex;
    annotate!(X_v,Y_v-4,text(string("t=",t," s"),10,:black,:center))
  end

  if setLims || posterPlot
    xlims!(c.m.Xlims[1],c.m.Xlims[2]);
    ylims!(c.m.Ylims[1],c.m.Ylims[2]);
  end

  if !s.simulate; savefig(string(r.results_dir,"x_vs_y",".",s.format)); end
  return pp
end
"""
vt=vtPlot(n,r,s,pa,c,idx)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 3/11/2017 \n
--------------------------------------------------------------------------------------\n
"""
function vtPlot(n::NLOpt,r::Result,s::Settings,pa::VehicleModels.Vpara,c,idx::Int64)
	@unpack_Vpara pa

  if !s.MPC && r.dfs[idx]!=nothing
    t_vec=linspace(0.0,max(5,ceil(r.dfs[end][:t][end]/1)*1),s.L);
  else
    t_vec=linspace(0,max(5,ceil(r.dfs_plant[end][:t][end]/1)*1),s.L);
  end

	vt=plot(t_vec,Fz_min*ones(s.L,1),line=(s.lw2),label="min")

  if r.dfs[idx]!=nothing && !s.plantOnly
    V=r.dfs[idx][:v];R=r.dfs[idx][:r];SA=r.dfs[idx][:sa];
    if c.m.model!=:ThreeDOFv1
      Ax=r.dfs[idx][:ax]; U=r.dfs[idx][:ux];
    else # constain speed (the model is not optimizing speed)
      U=c.m.UX*ones(length(V)); Ax=zeros(length(V));
    end
    plot!(r.dfs[idx][:t],@FZ_RL(),w=s.lw1,label="RL-mpc");
    plot!(r.dfs[idx][:t],@FZ_RR(),w=s.lw1,label="RR-mpc");
  end
  if s.MPC
    temp = [r.dfs_plant[jj][:v] for jj in 1:idx]; # V
    V=[idx for tempM in temp for idx=tempM];

    if c.m.model!=:ThreeDOFv1
      temp = [r.dfs_plant[jj][:ux] for jj in 1:idx]; # ux
      U=[idx for tempM in temp for idx=tempM];

      temp = [r.dfs_plant[jj][:ax] for jj in 1:idx]; # ax
      Ax=[idx for tempM in temp for idx=tempM];
    else # constain speed ( the model is not optimizing speed)
      U=c.m.UX*ones(length(V)); Ax=zeros(length(V));
    end

    temp = [r.dfs_plant[jj][:r] for jj in 1:idx]; # r
    R=[idx for tempM in temp for idx=tempM];

    temp = [r.dfs_plant[jj][:sa] for jj in 1:idx]; # sa
    SA=[idx for tempM in temp for idx=tempM];

    # time
    temp = [r.dfs_plant[jj][:t] for jj in 1:idx];
    time=[idx for tempM in temp for idx=tempM];

    plot!(time,@FZ_RL(),w=s.lw2,label="RL-plant");
    plot!(time,@FZ_RR(),w=s.lw2,label="RR-plant");
  end
  plot!(size=(s.s1,s.s1));
	adjust_axis(xlims(),ylims());
  xlims!(t_vec[1],t_vec[end]);
  ylims!(500,12000)
	title!("Vertical Tire Forces"); yaxis!("Force (N)"); xaxis!("time (s)")
	if !s.simulate savefig(string(r.results_dir,"vt.",s.format)) end
  return vt
end

"""
axp=axLimsPlot(n,r,s,pa,idx)
axp=axLimsPlot(n,r,s,pa,idx,axp;(:append=>true))
# this plot adds the nonlinear limits on acceleration to the plot
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 3/11/2017 \n
--------------------------------------------------------------------------------------\n
"""
function axLimsPlot(n::NLOpt,r::Result,s::Settings,pa::VehicleModels.Vpara,idx::Int64,args...;kwargs...)
  kw = Dict(kwargs);
  if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
  else; append = get(kw,:append,0);
  end
  if !append; axp=plot(0,leg=:false); else axp=args[1]; end

  @unpack_Vpara pa

  if !s.MPC && r.dfs[idx]!=nothing && !s.plantOnly
    t_vec=linspace(0.0,max(5,ceil(r.dfs[end][:t][end]/1)*1),s.L);
  else
    t_vec=linspace(0,max(5,ceil(r.dfs_plant[end][:t][end]/1)*1),s.L);
  end

  if r.dfs[idx]!=nothing && !s.plantOnly
    U = r.dfs[idx][:ux]
    plot!(r.dfs[idx][:t],@Ax_min(),w=s.lw1,label="min-mpc");
    plot!(r.dfs[idx][:t],@Ax_max(),w=s.lw1,label="max-mpc");
  end
  if s.MPC
    temp = [r.dfs_plant[jj][:ux] for jj in 1:idx]; # ux
    U=[idx for tempM in temp for idx=tempM];

    # time
    temp = [r.dfs_plant[jj][:t] for jj in 1:idx];
    time=[idx for tempM in temp for idx=tempM];

    plot!(time,@Ax_min(),w=s.lw2,label="min-plant");
    plot!(time,@Ax_max(),w=s.lw2,label="max-plant");
  end
  ylims!(-5,2)
  plot!(size=(s.s1,s.s1));
  if !s.simulate savefig(string(r.results_dir,"axp.",s.format)) end
  return axp
end


"""
# to visualize the current track in the field
trackPlot(c)

pp=trackPlot(c,pp;(:append=>true));
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/28/2017, Last Modified: 5/1/2017 \n
--------------------------------------------------------------------------------------\n
"""
function trackPlot(c,args...;kwargs...)
  kw = Dict(kwargs);
  s=Settings();

  # check to see if user would like to add to an existing plot
  if !haskey(kw,:append); append=false;
  else; append = get(kw,:append,0);
  end

  # check to see if user wants to reduce the size of the markers TODO get ride of this eventually
  if !haskey(kw,:smallMarkers);smallMarkers=false;
  else;smallMarkers=get(kw,:smallMarkers,0);
  end

  if !append; pp=plot(0,leg=:false); else pp=args[1]; end

  if c.t.func==:poly
    f(y)=c.t.a[1] + c.t.a[2]*y + c.t.a[3]*y^2 + c.t.a[4]*y^3 + c.t.a[5]*y^4;
    Y=c.t.Y;
    X=f.(Y);
  elseif c.t.func==:fourier
    ff(x)=c.t.a[1]*sin(c.t.b[1]*x+c.t.c[1]) + c.t.a[2]*sin(c.t.b[2]*x+c.t.c[2]) + c.t.a[3]*sin(c.t.b[3]*x+c.t.c[3]) + c.t.a[4]*sin(c.t.b[4]*x+c.t.c[4]) + c.t.a[5]*sin(c.t.b[5]*x+c.t.c[5]) + c.t.a[6]*sin(c.t.b[6]*x+c.t.c[6]) + c.t.a[7]*sin(c.t.b[7]*x+c.t.c[7]) + c.t.a[8]*sin(c.t.b[8]*x+c.t.c[8])+c.t.y0;
    X=c.t.X;
    Y=ff.(X);
  end

  if !smallMarkers; L=s.lw1*10; else L=s.lw1; end

  plot!(X,Y,label="Road",line=(L,0.3,:solid,:black))
  return pp
end

"""

pp=lidarPlot(r,s,c,idx);
pp=lidarPlot(r,s,c,idx,pp;(:append=>true));
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 4/3/2017, Last Modified: 4/3/2017 \n
--------------------------------------------------------------------------------------\n
"""
function lidarPlot(r,s,c,idx,args...;kwargs...)
  kw = Dict(kwargs);

  # check to see if user would like to add to an existing plot
  if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
  else; append = get(kw,:append,0);
  end
  if !append; pp=plot(0,leg=:false); else pp=args[1]; end

  # plot the LiDAR
  if s.MPC
    X_v = r.dfs_plant[idx][:x][1]  # using the begining of the simulated data from the vehicle model
    Y_v = r.dfs_plant[idx][:y][1]
    PSI_v = r.dfs_plant[idx][:psi][1]-pi/2
  else
    X_v = r.dfs[idx][:x][1]
    Y_v = r.dfs[idx][:y][1]
    PSI_v = r.dfs[idx][:psi][1]-pi/2
  end

  pts = Plots.partialcircle(PSI_v-pi,PSI_v+pi,50,c.m.Lr);
  x, y = Plots.unzip(pts);
  x += X_v;  y += Y_v;
  pts = collect(zip(x, y));
  plot!(pts, line=(s.lw1,0.2,:solid,:yellow),fill=(0, 0.2,:yellow),leg=true,label="LiDAR Range")
  return pp
end
"""
# to plot the second solution
pp=posPlot(n,r,s,c,2)
pp=posPlot(n,r,s,c,idx)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/28/2017, Last Modified: 5/1/2017 \n
--------------------------------------------------------------------------------------\n
"""
function posPlot(n,r,s,c,idx;kwargs...)
  kw = Dict(kwargs);
  if !haskey(kw,:zoom); zoom=false;
  else; zoom=get(kw,:zoom,0);
  end
  # check to see if we want to set the limits to the position constraints
  if !haskey(kw,:setLims);setLims=false;
  else;setLims=get(kw,:setLims,0);
  end

  # check to see if user wants to reduce the size of the markers TODO get ride of this eventually
  if !haskey(kw,:smallMarkers);smallMarkers=false;
  else;smallMarkers=get(kw,:smallMarkers,0);
  end

  if !isempty(c.t.X); pp=trackPlot(c;(:smallMarkers=>smallMarkers)); else pp=plot(0,leg=:false); end  # track
  if !isempty(c.m.Lr); pp=lidarPlot(r,s,c,idx,pp;(:append=>true)); end  # lidar

  pp=statePlot(n,r,s,idx,1,2,pp;(:lims=>false),(:append=>true)); # vehicle trajectory
  pp=obstaclePlot(n,r,s,c,idx,pp;(:append=>true),(:smallMarkers=>smallMarkers));               # obstacles
  pp=vehiclePlot(n,r,s,c,idx,pp;(:append=>true),(:zoom=>zoom),(:setLims=>setLims),(:smallMarkers=>smallMarkers));  # vehicle

  if !s.simulate savefig(string(r.results_dir,"pp.",s.format)) end
  return pp
end

"""
main=mainPlot(n,r,s,c,pa,idx;kwargs...)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 5/1/2017 \n
--------------------------------------------------------------------------------------\n
"""
function mainPlot(n,r,s,c,pa,idx;kwargs...)
  kw = Dict(kwargs);
  if !haskey(kw,:mode);error("select a mode for the simulation \n")
  else; mode=get(kw,:mode,0);
  end

  if mode==:path1
    sap=statePlot(n,r,s,idx,6)
    vp=statePlot(n,r,s,idx,3)
    rp=statePlot(n,r,s,idx,4)
    vt=vtPlot(n,r,s,pa,c,idx)
    pp=posPlot(n,r,s,c,idx)
    pz=posPlot(n,r,s,c,idx;(:zoom=>true))
    if s.MPC; tp=tPlot(n,r,s,idx); else; tp=plot(0,leg=:false); end
    l = @layout [a{0.3w} [grid(2,2)
                          b{0.2h}]]
    mainS=plot(pp,sap,vt,pz,rp,tp,layout=l,size=(s.s1,s.s2));
  elseif mode==:path2
    sap=statePlot(n,r,s,idx,6);plot!(leg=:topleft)
    vp=statePlot(n,r,s,idx,3);plot!(leg=:topleft)
    vt=vtPlot(n,r,s,pa,c,idx);plot!(leg=:bottomleft)
    pz=posPlot(n,r,s,c,idx;(:zoom=>true));plot!(leg=:topleft)
    if s.MPC; tp=tPlot(n,r,s,idx);plot!(leg=:topright) else; tp=plot(0,leg=:false);plot!(leg=:topright) end
    l=@layout([a{0.6w} [b;c]; d{0.17h}])
    mainS=plot(pz,vt,sap,tp,layout=l,size=(s.s1,s.s2));
  elseif mode==:path3
    sap=statePlot(n,r,s,idx,6);plot!(leg=:topleft)
    vp=statePlot(n,r,s,idx,3);plot!(leg=:topleft)
    vt=vtPlot(n,r,s,pa,c,idx);plot!(leg=:bottomleft)
    pp=posPlot(n,r,s,c,idx;(:setLims=>true),(:smallMarkers=>true));plot!(leg=false);
    pz=posPlot(n,r,s,c,idx;(:zoom=>true));plot!(leg=:topleft)
    if s.MPC; tp=tPlot(n,r,s,idx);plot!(leg=:topright) else; tp=plot(0,leg=:false);plot!(leg=:topright) end
    l=@layout([[a;
                b{0.2h}] [c;d;e]])
    mainS=plot(pz,pp,vt,sap,tp,layout=l,size=(s.s1,s.s2));
  elseif mode==:open1
    sap=statePlot(n,r,s,idx,6);plot!(leg=:topleft)
    longv=statePlot(n,r,s,idx,7);plot!(leg=:topleft)
    axp=axLimsPlot(n,r,s,pa,idx);# add nonlinear acceleration limits
    axp=statePlot(n,r,s,idx,8,axp;(:lims=>false),(:append=>true));plot!(leg=:bottomright);
    pp=posPlot(n,r,s,c,idx;(:setLims=>true));plot!(leg=:topright);
    if s.MPC; tp=tPlot(n,r,s,idx); else; tp=plot(0,leg=:false); end
    vt=vtPlot(n,r,s,pa,c,idx)
    l = @layout [a{0.5w} [grid(2,2)
                          b{0.2h}]]
    mainS=plot(pp,sap,vt,longv,axp,tp,layout=l,size=(s.s1,s.s2));
  end

  return mainS
end


"""
mainSim(n,r,s,c,pa;(:mode=>:open1))
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 4/13/2017, Last Modified: 5/1/2017 \n
--------------------------------------------------------------------------------------\n
"""

function mainSim(n,r,s,c,pa;kwargs...)
  kw = Dict(kwargs);
  if !haskey(kw,:mode);error("select a mode for the simulation \n")
  else; mode=get(kw,:mode,0);
  end

  if r.eval_num>2;
     anim = @animate for idx in 1:length(r.dfs)
       mainPlot(n,r,s,c,pa,idx;(:mode=>mode))
    end
    cd(r.results_dir)
      gif(anim,"mainSim.gif",fps=Int(ceil(1/n.mpc.tex)));
      run(`ffmpeg -f gif -i mainSim.gif RESULT.mp4`)
    cd(r.main_dir)
  else
    warn("the evaluation number was not greater than 2. Cannot make animation. Plotting a static plot.")
    s=Settings(;save=true,MPC=false,simulate=false,format=:png);
    mainPlot(n,r,s,c,pa,2;(:mode=>mode))
  end
  nothing
end

"""

--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 4/13/2017, Last Modified: 5/1/2017 \n
--------------------------------------------------------------------------------------\n
"""

function pSim(n,r,s,c)
  anim = @animate for ii in 1:length(r.dfs)
    posPlot(n,r,s,c,ii);
  end
  gif(anim, string(r.results_dir,"posSim.gif"), fps=Int(ceil(1/n.mpc.tex)) );
  nothing
end


"""

--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 4/13/2017, Last Modified: 4/13/2017 \n
--------------------------------------------------------------------------------------\n
"""

function pSimGR(n,r,s,c)
  ENV["GKS_WSTYPE"]="mov"
  gr(show=true)
  for ii in 1:length(r.dfs)
    posPlot(n,r,s,c,ii);
  end
end

"""
default(guidefont = font(17), tickfont = font(15), legendfont = font(12), titlefont = font(20))
s=Settings(;save=true,MPC=true,simulate=false,format=:png,plantOnly=true);
posterP(n,r,s,c,pa)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 4/13/2017, Last Modified: 4/13/2017 \n
--------------------------------------------------------------------------------------\n
"""

function posterP(n,r,s,c,pa)

  # static plots for each frame
  idx=r.eval_num;
  sap=statePlot(n,r,s,idx,6)
  longv=statePlot(n,r,s,idx,7)
  axp=axLimsPlot(n,r,s,pa,idx); # add nonlinear acceleration limits
  axp=statePlot(n,r,s,idx,8,axp;(:lims=>false),(:append=>true));
  pp=statePlot(n,r,s,idx,1,2;(:lims=>false));
  if s.MPC; tp=tPlot(n,r,s,idx); else; tp=plot(0,leg=:false); end
  vt=vtPlot(n,r,s,pa,c,idx)

  # dynamic plots ( maybe only update every 5 frames or so)
  v=Vector(1:5:r.eval_num); if v[end]!=r.eval_num; append!(v,r.eval_num); end
  for ii in v
    if ii==1
      st1=1;st2=2;
      # values
  		temp = [r.dfs_plant[jj][n.state.name[st1]] for jj in 1:r.eval_num];
  		vals1=[idx for tempM in temp for idx=tempM];

  		# values
  		temp = [r.dfs_plant[jj][n.state.name[st2]] for jj in 1:r.eval_num];
  		vals2=[idx for tempM in temp for idx=tempM];

  		pp=plot(vals1,vals2,w=s.lw2,label="Vehicle Trajectory");

      pp=obstaclePlot(n,r,s,c,ii,pp;(:append=>true),(:posterPlot=>true)); # add obstacles
      pp=vehiclePlot(n,r,s,c,ii,pp;(:append=>true),(:posterPlot=>true));  # add the vehicle
    else
      pp=obstaclePlot(n,r,s,c,ii,pp;(:append=>true),(:posterPlot=>true));  # add obstacles
      pp=vehiclePlot(n,r,s,c,ii,pp;(:append=>true),(:posterPlot=>true));  # add the vehicle
    end
  end
  l = @layout [a{0.5w} [grid(2,2)
                        b{0.2h}]]
  poster=plot(pp,sap,vt,longv,axp,tp,layout=l,size=(s.s1,s.s2));
  savefig(string(r.results_dir,"poster",".",s.format));
  nothing
end


end # module
