module VehicleModels_plots

using NLOptControl
using VehicleModels
using Plots

include("NLOptControl_plots.jl")
using .NLOptControl_plots

export
      obstaclePlot,
      vehiclePlot,
      vtPlot,
      axLimsPlot,
      mainSim,
      mainSimPath,
      pSimPath

"""
# to visualize the current obstacle in the field
obstaclePlot(n,c)

# to run it after a single optimization
pp=obstaclePlot(n,r,s,c,1);

# to create a new plot
pp=obstaclePlot(n,r,s,c,idx);

# to add to an exsting position plot
pp=obstaclePlot(n,r,s,c,idx,pp;(:append=>true));
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
            plot!(pts, line=(s.lw1,0.7,:solid,:red),fill = (0, 0.7, :red),leg=true,label="Obstacles",leg=:bottomleft)
          else
            plot!(pts, line=(s.lw1,0.7,:solid,:red),fill = (0, 0.7, :red),leg=true,label="",leg=:bottomleft)
          end
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
      if isnan(n.XF_tol[1]); rg=1; else rg=n.XF_tol[1]; end[]
      pts = Plots.partialcircle(0,2π,100,rg);
      x, y = Plots.unzip(pts);
      x += c.g.x_ref;  y += c.g.y_ref;
      pts = collect(zip(x, y));
      plot!(pts, fill = (0, 0.7, :green),leg=true,label="Goal")
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
        if i==1
          plot!(pts, line=(s.lw1,0.7,:solid,:red),fill = (0, 0.7, :red),leg=true,label="Obstacles",leg=:bottomleft)
        else
          plot!(pts, line=(s.lw1,0.7,:solid,:red),fill = (0, 0.7, :red),leg=true,label="",leg=:bottomleft)
        end
      end
    end

    xaxis!(n.state.description[1]);
    yaxis!(n.state.description[2]);
    if s.MPC
      xlims!(minDF(r.dfs_plant,:x),maxDF(r.dfs_plant,:x));
      ylims!(minDF(r.dfs_plant,:y),maxDF(r.dfs_plant,:y));
    else
      xlims!(minDF(r.dfs,:x),maxDF(r.dfs,:x));
      ylims!(minDF(r.dfs,:y),maxDF(r.dfs,:y));
    end
    if !s.simulate savefig(string(r.results_dir,"/",n.state.name[1],"_vs_",n.state.name[2],".",s.format)); end
  end
  return pp
end
obstaclePlot(n,c)=obstaclePlot(n,1,1,c,1,;(:basic=>true))

"""
pp=vehiclePlot(n,r,s,c,idx);
pp=vehiclePlot(n,r,s,c,idx,pp;(:append=>true));
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 3/11/2017 \n
--------------------------------------------------------------------------------------\n
"""
function vehiclePlot(n,r,s,c,idx,args...;kwargs...)
  kw = Dict(kwargs);

  # check to see if user would like to add to an existing plot
  if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
  else; append = get(kw,:append,0);
  end
  if !append; pp=plot(0,leg=:false); else pp=args[1]; end

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
    X_v = r.dfs[idx][:x][end]  # vehicles are in the same spot at the begining
    Y_v = r.dfs[idx][:y][end]
    PSI_v = r.dfs[idx][:psi][end]-pi/2
  end

  P = [XQ;YQ];
  ct = cos(PSI_v);
  st = sin(PSI_v);
  R = [ct -st;st ct];
  P2 = R * P;
  scatter!((P2[1,:]+X_v,P2[2,:]+Y_v), markershape = :square, markercolor = :black, markersize = s.ms1, fill = (0, 1, :black),leg=true, grid=true,label="Vehicle")
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
  	t_vec=linspace(0,round(r.dfs[end][:t][end]/10)*10,s.L);
	else
    t_vec=linspace(0,max(5,round(r.dfs_plant[end][:t][end]/5)*5),s.L);
	end

	vt=plot(t_vec,Fz_min*ones(s.L,1),line=(s.lw2),label="min")

  if r.dfs[idx]!=nothing
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
  ylims!(ylims()[1]-500,ylims()[2]+100)
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

  if !s.MPC && r.dfs[idx]!=nothing
    t_vec=linspace(0,max(5,round(r.dfs[end][:t][end]/5)*5),s.L);
	else
    t_vec=linspace(0,max(5,round(r.dfs_plant[end][:t][end]/5)*5),s.L);
	end

  if r.dfs[idx]!=nothing
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
  plot!(size=(s.s1,s.s1));
  if !s.simulate savefig(string(r.results_dir,"axp.",s.format)) end
  return axp
end


"""
mainS=mainSim(n,r,s,c,pa,idx)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/11/2017, Last Modified: 3/27/2017 \n
--------------------------------------------------------------------------------------\n
"""
function mainSim(n,r,s,c,pa,idx)
  sap=statePlot(n,r,s,idx,6)
  longv=statePlot(n,r,s,idx,7)
  axp=axLimsPlot(n,r,s,pa,idx); # add nonlinear acceleration limits
  axp=statePlot(n,r,s,idx,8,axp;(:lims=>false),(:append=>true));
  #srp=controlPlot(n,r,s,r.eval_num,1)
  pp=statePlot(n,r,s,idx,1,2;(:lims=>false));
  pp=obstaclePlot(n,r,s,c,idx,pp;(:append=>true)); # add obstacles
  pp=vehiclePlot(n,r,s,c,idx,pp;(:append=>true)); # add the vehicle
  if s.MPC; tp=tPlot(n,r,s,idx); else; tp=plot(0,leg=:false); end
  vt=vtPlot(n,r,s,pa,c,idx)
  l = @layout [a{0.3w} [grid(2,2)
                        b{0.2h}]]
  mainS=plot(pp,sap,vt,longv,axp,tp,layout=l,size=(1800,1200));
  return mainS
end


"""
mainS=mainSimPath(n,r,s,c,pa,r.eval_num)
mainS=mainSimPath(n,r,s,c,pa,idx)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/28/2017, Last Modified: 3/28/2017 \n
--------------------------------------------------------------------------------------\n
"""
function mainSimPath(n,r,s,c,pa,idx)
  if c.m.model==:ThreeDOFv1
    sap=controlPlot(n,r,s,idx,1)
  elseif c.m.model==:ThreeDOFv2
    sap=statePlot(n,r,s,idx,6)
  end
  vp=statePlot(n,r,s,idx,3)
  rp=statePlot(n,r,s,idx,4)
  vt=vtPlot(n,r,s,pa,c,idx)
  pp=pSimPath(n,r,s,c,idx)
  if s.MPC; tp=tPlot(n,r,s,idx); else; tp=plot(0,leg=:false); end
  l = @layout [a{0.3w} [grid(2,2)
                        b{0.2h}]]
  mainS=plot(pp,sap,vt,rp,vp,tp,layout=l,size=(1800,1200));

  return mainS
end

"""

pp=trackPlot(r,s,c,idx);
pp=trackPlot(r,s,c,idx,pp;(:append=>true));
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/28/2017, Last Modified: 4/3/2017 \n
--------------------------------------------------------------------------------------\n
"""
function trackPlot(r,s,c,idx,args...;kwargs...)
  kw = Dict(kwargs);

  # check to see if user would like to add to an existing plot
  if !haskey(kw,:append); kw_ = Dict(:append => false); append = get(kw_,:append,0);
  else; append = get(kw,:append,0);
  end
  if !append; pp=plot(0,leg=:false); else pp=args[1]; end

  if c.t.func==:poly
    f(y)=c.t.a[1] + c.t.a[2]*y + c.t.a[3]*y^2 + c.t.a[4]*y^3 + c.t.a[5]*y^4;
    Y=c.t.Y;
    X=f.(Y);
  elseif c.t.func==:fourier
    ff(x)=c.t.a[1]*sin(c.t.b[1]*x+c.t.c[1]) + c.t.a[2]*sin(c.t.b[2]*x+c.t.c[2]) + c.t.a[3]*sin(c.t.b[3]*x+c.t.c[3]) + c.t.a[4]*sin(c.t.b[4]*x+c.t.c[4]) + c.t.a[5]*sin(c.t.b[5]*x+c.t.c[5]) + c.t.a[6]*sin(c.t.b[6]*x+c.t.c[6]) + c.t.a[7]*sin(c.t.b[7]*x+c.t.c[7]) + c.t.a[8]*sin(c.t.b[8]*x+c.t.c[8])+c.t.y0;
    #ff(x)=c.t.a[1]*sin(-c.t.b[1]*x+c.t.c[1]) + c.t.a[2]*sin(-c.t.b[2]*x+c.t.c[2]) + c.t.a[3]*sin(-c.t.b[3]*x+c.t.c[3]) + c.t.a[4]*sin(-c.t.b[4]*x+c.t.c[4]) + c.t.a[5]*sin(-c.t.b[5]*x+c.t.c[5]) + c.t.a[6]*sin(-c.t.b[6]*x+c.t.c[6]) + c.t.a[7]*sin(-c.t.b[7]*x+c.t.c[7]) + c.t.a[8]*sin(-c.t.b[8]*x+c.t.c[8])+c.t.y0;
    X=c.t.X;
    Y=ff.(X);
    plot(X,Y)
  end

  plot!(X,Y,label="Road",line=(s.lw1*2,:solid,:black))
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
  plot!(pts, line=(s.lw1,0.2,:solid,:yellow),fill = (0, 0.2, :yellow),leg=true,label="LiDAR Range")

  return pp
end
"""
pp=pSimPath(n,r,s,c,idx)
--------------------------------------------------------------------------------------\n
Author: Huckleberry Febbo, Graduate Student, University of Michigan
Date Create: 3/28/2017, Last Modified: 4/3/2017 \n
--------------------------------------------------------------------------------------\n
"""
function pSimPath(n,r,s,c,idx)
  pp=trackPlot(r,s,c,idx);
  pp=lidarPlot(r,s,c,idx,pp;(:append=>true));
  pp=statePlot(n,r,s,idx,1,2,pp;(:lims=>false),(:append=>true));
  pp=obstaclePlot(n,r,s,c,idx,pp;(:append=>true)); # obstacles
  pp=vehiclePlot(n,r,s,c,idx,pp;(:append=>true));  # vehicle
  if !s.simulate savefig(string(r.results_dir,"pp.",s.format)) end
  return pp
end

end # module