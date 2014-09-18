sqrt = math.sqrt
cos  = math.cos
pi   = math.pi
abs  = math.abs
min  = math.min
-- refinement parameters
min_level = 0
max_level = min_level+3
output_prefix = "TPV28"
data_directory = "output"

-- connectivity info
connectivity = "brick"
brick =
{
  nx = 2*(6+10),
  ny = 2*(6+10),
  nz =   (5+11),
  periodic_x = 0,
  periodic_y = 0,
  periodic_z = 0,
}

-- set up the domain
Lx = 3
Ly = 3
Lz = 3

Cx = brick.nx/2
Cy = brick.ny/2
Cz = brick.nz

function connectivity_vertices(xin, yin, zin)
  x = Lx*(xin-Cx)
  y = Ly*(yin-Cy)
  z = Lz*(zin-Cz)

  -- if abs(y) < Ly then
  --   r1 = sqrt((x+10.5)^2 + 0*(z+7.5)^2)
  --   r2 = sqrt((x-10.5)^2 + 0*(z+7.5)^2)
  --   if r1 < 3 then
  --     f  = (-0.3*(1+cos(pi*r1/3)))
  --   elseif r2 < 3 then
  --     f  = (-0.3*(1+cos(pi*r2/3)))
  --   else
  --     f  = 0
  --   end

  --   y = y + f*(Ly-abs(y))/Ly
  -- end

  return x,y,z
end

function transform_nodes(x, y, z)
  if abs(y) < Ly then
    r1 = sqrt((x+10.5)^2 + (z+7.5)^2)
    r2 = sqrt((x-10.5)^2 + (z+7.5)^2)
    if r1 < 3 then
      f  = (-0.3*(1+cos(pi*r1/3)))
    elseif r2 < 3 then
      f  = (-0.3*(1+cos(pi*r2/3)))
    else
      f  = 0
    end

    y = y + f*(Ly-abs(y))/Ly
  end
  return x,y,z
end

function refinement_function(
  x0,y0,z0,x1,y1,z1,
  x2,y2,z2,x3,y3,z3,
  x4,y4,z4,x5,y5,z5,
  x6,y6,z6,x7,y7,z7,
  level, treeid)

  xa0 = abs(x0)
  xa1 = abs(x1)
  xa2 = abs(x2)
  xa3 = abs(x3)
  xmin = min( xa0,xa1)
  xmin = min(xmin,xa2)
  xmin = min(xmin,xa2)

  ya0 = abs(y0)
  ya1 = abs(y1)
  ya2 = abs(y2)
  ya3 = abs(y3)
  ymin = min( ya0,ya1)
  ymin = min(ymin,ya2)
  ymin = min(ymin,ya3)

  zmin = min(z0,z1,z2,z3)

  if level < min_level then
    return 1
  elseif level >= max_level then
    return 0
  elseif xmin <= 6*Lx and zmin >= -5*Lz and ymin <= Ly then
    return 1
  else
    return 0
  end
end

function element_order(
  x0,y0,z0,x1,y1,z1,
  x2,y2,z2,x3,y3,z3,
  x4,y4,z4,x5,y5,z5,
  x6,y6,z6,x7,y7,z7,
  level, treeid)

  N = 4

  return N
end

-- material properties
cs = 3.464
cp = 6
rho = 2.670
mu  = rho*cs^2
lam = rho*cp^2-2*mu

-- field conditions
S11 = 0
S22 = 0
S33 = 0
S12 = 0
S13 = 0
S23 = 0
v1  = 0
v2  = 0
v3  = 0

-- time stepper to use
lsrk_method  = "KC54"

tend   = 13
tout   = 1
tfout  = 0.1
tdisp  = 0.01
tstations  = 0.01
nerr   = 0

function time_step_parameters(dt)
  dt      = 0.5*dt
  nfoutput = math.ceil(tfout / dt)
  dt       = tfout / nfoutput

  noutput    = 1000000
  ndisp      = tdisp / dt
  nsteps     = tend / dt
  nstations  = tstations / dt

  return dt,nsteps, ndisp, noutput, nfoutput, nstations
end


-- friction stuff
-- NOTE: That our cooridinate system is rotated from SCEC,
--       X -> Same
--       Y -> SCEC:  Z
--       Z -> SCEC: -Y
function S12_nucleation(x,y,z,t)
  S12_0 = 29.38
  r = sqrt(x^2 + (z+7.5)^2)
  if r < 1.4 then
    S12_0 = S12_0 + 11.6
  elseif r < 2 then
    S12_0 = S12_0 + 5.8*(1+cos(pi*(r-1.4)/0.6))
  end

  return S12_0
end

fault_1 = {
  type   = "friction",
  tag    = "slip weakening",
  fs     =              0.677,
  fd     =              0.525,
  Dc     =              0.4,
  S11_0  =            -60, --SCEC:  S11
  S22_0  =            -60, --SCEC:  S33
  S33_0  =              0, --SCEC:  S22
  S12_0  = "S12_nucleation", --SCEC:  S13
  S13_0  =              0, --SCEC: -S12
  S23_0  =              0, --SCEC: -S23
}

fault_stations = {
  "faultst000dp075", 0.0, 0.0, -7.5,
}

bc_free = {
  type = "boundary",
  tag  = "free surface",
}

bc_nonreflect = {
  type = "boundary",
  tag  = "non-reflecting",
}

bc_rigid = {
  type = "boundary",
  tag  = "rigid wall",
}

glue_info = {
  bc_nonreflect,
  bc_free,
  bc_rigid,
  fault_1,
}

glueid_treeid_faceid = {
 4, 10796, 2,
 4, 10797, 2,
 4, 10852, 2,
 4, 10853, 2,
 4, 10860, 2,
 4, 10861, 2,
 4, 11016, 2,
 4, 11017, 2,
 4, 11020, 2,
 4, 11021, 2,
 4, 11048, 2,
 4, 11049, 2,
 4, 11052, 2,
 4, 11053, 2,
 4, 11072, 2,
 4, 11073, 2,
 4, 11076, 2,
 4, 11077, 2,
 4, 11080, 2,
 4, 11081, 2,
 4, 11084, 2,
 4, 11085, 2,
 4, 11104, 2,
 4, 11105, 2,
 4, 11108, 2,
 4, 11109, 2,
 4, 11112, 2,
 4, 11113, 2,
 4, 11116, 2,
 4, 11117, 2,
 4, 14372, 2,
 4, 14373, 2,
 4, 14380, 2,
 4, 14381, 2,
 4, 14436, 2,
 4, 14437, 2,
 4, 14592, 2,
 4, 14593, 2,
 4, 14596, 2,
 4, 14597, 2,
 4, 14600, 2,
 4, 14601, 2,
 4, 14604, 2,
 4, 14605, 2,
 4, 14624, 2,
 4, 14625, 2,
 4, 14628, 2,
 4, 14629, 2,
 4, 14632, 2,
 4, 14633, 2,
 4, 14636, 2,
 4, 14637, 2,
 4, 14656, 2,
 4, 14657, 2,
 4, 14660, 2,
 4, 14661, 2,
 4, 14688, 2,
 4, 14689, 2,
 4, 14692, 2,
 4, 14693, 2,
 4,  3774, 3,
 4,  3775, 3,
 4,  3830, 3,
 4,  3831, 3,
 4,  3838, 3,
 4,  3839, 3,
 4,  3994, 3,
 4,  3995, 3,
 4,  3998, 3,
 4,  3999, 3,
 4,  4026, 3,
 4,  4027, 3,
 4,  4030, 3,
 4,  4031, 3,
 4,  4050, 3,
 4,  4051, 3,
 4,  4054, 3,
 4,  4055, 3,
 4,  4058, 3,
 4,  4059, 3,
 4,  4062, 3,
 4,  4063, 3,
 4,  4082, 3,
 4,  4083, 3,
 4,  4086, 3,
 4,  4087, 3,
 4,  4090, 3,
 4,  4091, 3,
 4,  4094, 3,
 4,  4095, 3,
 4,  7350, 3,
 4,  7351, 3,
 4,  7358, 3,
 4,  7359, 3,
 4,  7414, 3,
 4,  7415, 3,
 4,  7570, 3,
 4,  7571, 3,
 4,  7574, 3,
 4,  7575, 3,
 4,  7578, 3,
 4,  7579, 3,
 4,  7582, 3,
 4,  7583, 3,
 4,  7602, 3,
 4,  7603, 3,
 4,  7606, 3,
 4,  7607, 3,
 4,  7610, 3,
 4,  7611, 3,
 4,  7614, 3,
 4,  7615, 3,
 4,  7634, 3,
 4,  7635, 3,
 4,  7638, 3,
 4,  7639, 3,
 4,  7666, 3,
 4,  7667, 3,
 4,  7670, 3,
 4,  7671, 3,
 2, 10532, 5,
 2, 10533, 5,
 2, 10534, 5,
 2, 10535, 5,
 2, 10540, 5,
 2, 10541, 5,
 2, 10542, 5,
 2, 10543, 5,
 2, 10548, 5,
 2, 10549, 5,
 2, 10550, 5,
 2, 10551, 5,
 2, 10556, 5,
 2, 10557, 5,
 2, 10558, 5,
 2, 10559, 5,
 2, 10596, 5,
 2, 10597, 5,
 2, 10598, 5,
 2, 10599, 5,
 2, 10604, 5,
 2, 10605, 5,
 2, 10606, 5,
 2, 10607, 5,
 2, 10612, 5,
 2, 10613, 5,
 2, 10614, 5,
 2, 10615, 5,
 2, 10620, 5,
 2, 10621, 5,
 2, 10622, 5,
 2, 10623, 5,
 2, 10660, 5,
 2, 10661, 5,
 2, 10662, 5,
 2, 10663, 5,
 2, 10668, 5,
 2, 10669, 5,
 2, 10670, 5,
 2, 10671, 5,
 2, 10676, 5,
 2, 10677, 5,
 2, 10678, 5,
 2, 10679, 5,
 2, 10684, 5,
 2, 10685, 5,
 2, 10686, 5,
 2, 10687, 5,
 2, 10724, 5,
 2, 10725, 5,
 2, 10726, 5,
 2, 10727, 5,
 2, 10732, 5,
 2, 10733, 5,
 2, 10734, 5,
 2, 10735, 5,
 2, 10740, 5,
 2, 10741, 5,
 2, 10742, 5,
 2, 10743, 5,
 2, 10748, 5,
 2, 10749, 5,
 2, 10750, 5,
 2, 10751, 5,
 2, 11044, 5,
 2, 11045, 5,
 2, 11046, 5,
 2, 11047, 5,
 2, 11052, 5,
 2, 11053, 5,
 2, 11054, 5,
 2, 11055, 5,
 2, 11060, 5,
 2, 11061, 5,
 2, 11062, 5,
 2, 11063, 5,
 2, 11068, 5,
 2, 11069, 5,
 2, 11070, 5,
 2, 11071, 5,
 2, 11108, 5,
 2, 11109, 5,
 2, 11110, 5,
 2, 11111, 5,
 2, 11116, 5,
 2, 11117, 5,
 2, 11118, 5,
 2, 11119, 5,
 2, 11124, 5,
 2, 11125, 5,
 2, 11126, 5,
 2, 11127, 5,
 2, 11132, 5,
 2, 11133, 5,
 2, 11134, 5,
 2, 11135, 5,
 2, 11172, 5,
 2, 11173, 5,
 2, 11174, 5,
 2, 11175, 5,
 2, 11180, 5,
 2, 11181, 5,
 2, 11182, 5,
 2, 11183, 5,
 2, 11188, 5,
 2, 11189, 5,
 2, 11190, 5,
 2, 11191, 5,
 2, 11196, 5,
 2, 11197, 5,
 2, 11198, 5,
 2, 11199, 5,
 2, 11236, 5,
 2, 11237, 5,
 2, 11238, 5,
 2, 11239, 5,
 2, 11244, 5,
 2, 11245, 5,
 2, 11246, 5,
 2, 11247, 5,
 2, 11252, 5,
 2, 11253, 5,
 2, 11254, 5,
 2, 11255, 5,
 2, 11260, 5,
 2, 11261, 5,
 2, 11262, 5,
 2, 11263, 5,
 2, 11556, 5,
 2, 11557, 5,
 2, 11558, 5,
 2, 11559, 5,
 2, 11564, 5,
 2, 11565, 5,
 2, 11566, 5,
 2, 11567, 5,
 2, 11572, 5,
 2, 11573, 5,
 2, 11574, 5,
 2, 11575, 5,
 2, 11580, 5,
 2, 11581, 5,
 2, 11582, 5,
 2, 11583, 5,
 2, 11620, 5,
 2, 11621, 5,
 2, 11622, 5,
 2, 11623, 5,
 2, 11628, 5,
 2, 11629, 5,
 2, 11630, 5,
 2, 11631, 5,
 2, 11636, 5,
 2, 11637, 5,
 2, 11638, 5,
 2, 11639, 5,
 2, 11644, 5,
 2, 11645, 5,
 2, 11646, 5,
 2, 11647, 5,
 2, 11684, 5,
 2, 11685, 5,
 2, 11686, 5,
 2, 11687, 5,
 2, 11692, 5,
 2, 11693, 5,
 2, 11694, 5,
 2, 11695, 5,
 2, 11700, 5,
 2, 11701, 5,
 2, 11702, 5,
 2, 11703, 5,
 2, 11708, 5,
 2, 11709, 5,
 2, 11710, 5,
 2, 11711, 5,
 2, 11748, 5,
 2, 11749, 5,
 2, 11750, 5,
 2, 11751, 5,
 2, 11756, 5,
 2, 11757, 5,
 2, 11758, 5,
 2, 11759, 5,
 2, 11764, 5,
 2, 11765, 5,
 2, 11766, 5,
 2, 11767, 5,
 2, 11772, 5,
 2, 11773, 5,
 2, 11774, 5,
 2, 11775, 5,
 2, 12068, 5,
 2, 12069, 5,
 2, 12070, 5,
 2, 12071, 5,
 2, 12076, 5,
 2, 12077, 5,
 2, 12078, 5,
 2, 12079, 5,
 2, 12084, 5,
 2, 12085, 5,
 2, 12086, 5,
 2, 12087, 5,
 2, 12092, 5,
 2, 12093, 5,
 2, 12094, 5,
 2, 12095, 5,
 2, 12132, 5,
 2, 12133, 5,
 2, 12134, 5,
 2, 12135, 5,
 2, 12140, 5,
 2, 12141, 5,
 2, 12142, 5,
 2, 12143, 5,
 2, 12148, 5,
 2, 12149, 5,
 2, 12150, 5,
 2, 12151, 5,
 2, 12156, 5,
 2, 12157, 5,
 2, 12158, 5,
 2, 12159, 5,
 2, 12196, 5,
 2, 12197, 5,
 2, 12198, 5,
 2, 12199, 5,
 2, 12204, 5,
 2, 12205, 5,
 2, 12206, 5,
 2, 12207, 5,
 2, 12212, 5,
 2, 12213, 5,
 2, 12214, 5,
 2, 12215, 5,
 2, 12220, 5,
 2, 12221, 5,
 2, 12222, 5,
 2, 12223, 5,
 2, 12260, 5,
 2, 12261, 5,
 2, 12262, 5,
 2, 12263, 5,
 2, 12268, 5,
 2, 12269, 5,
 2, 12270, 5,
 2, 12271, 5,
 2, 12276, 5,
 2, 12277, 5,
 2, 12278, 5,
 2, 12279, 5,
 2, 12284, 5,
 2, 12285, 5,
 2, 12286, 5,
 2, 12287, 5,
 2, 14628, 5,
 2, 14629, 5,
 2, 14630, 5,
 2, 14631, 5,
 2, 14636, 5,
 2, 14637, 5,
 2, 14638, 5,
 2, 14639, 5,
 2, 14644, 5,
 2, 14645, 5,
 2, 14646, 5,
 2, 14647, 5,
 2, 14652, 5,
 2, 14653, 5,
 2, 14654, 5,
 2, 14655, 5,
 2, 14692, 5,
 2, 14693, 5,
 2, 14694, 5,
 2, 14695, 5,
 2, 14700, 5,
 2, 14701, 5,
 2, 14702, 5,
 2, 14703, 5,
 2, 14708, 5,
 2, 14709, 5,
 2, 14710, 5,
 2, 14711, 5,
 2, 14716, 5,
 2, 14717, 5,
 2, 14718, 5,
 2, 14719, 5,
 2, 14756, 5,
 2, 14757, 5,
 2, 14758, 5,
 2, 14759, 5,
 2, 14764, 5,
 2, 14765, 5,
 2, 14766, 5,
 2, 14767, 5,
 2, 14772, 5,
 2, 14773, 5,
 2, 14774, 5,
 2, 14775, 5,
 2, 14780, 5,
 2, 14781, 5,
 2, 14782, 5,
 2, 14783, 5,
 2, 14820, 5,
 2, 14821, 5,
 2, 14822, 5,
 2, 14823, 5,
 2, 14828, 5,
 2, 14829, 5,
 2, 14830, 5,
 2, 14831, 5,
 2, 14836, 5,
 2, 14837, 5,
 2, 14838, 5,
 2, 14839, 5,
 2, 14844, 5,
 2, 14845, 5,
 2, 14846, 5,
 2, 14847, 5,
 2, 15140, 5,
 2, 15141, 5,
 2, 15142, 5,
 2, 15143, 5,
 2, 15148, 5,
 2, 15149, 5,
 2, 15150, 5,
 2, 15151, 5,
 2, 15156, 5,
 2, 15157, 5,
 2, 15158, 5,
 2, 15159, 5,
 2, 15164, 5,
 2, 15165, 5,
 2, 15166, 5,
 2, 15167, 5,
 2, 15204, 5,
 2, 15205, 5,
 2, 15206, 5,
 2, 15207, 5,
 2, 15212, 5,
 2, 15213, 5,
 2, 15214, 5,
 2, 15215, 5,
 2, 15220, 5,
 2, 15221, 5,
 2, 15222, 5,
 2, 15223, 5,
 2, 15228, 5,
 2, 15229, 5,
 2, 15230, 5,
 2, 15231, 5,
 2, 15268, 5,
 2, 15269, 5,
 2, 15270, 5,
 2, 15271, 5,
 2, 15276, 5,
 2, 15277, 5,
 2, 15278, 5,
 2, 15279, 5,
 2, 15284, 5,
 2, 15285, 5,
 2, 15286, 5,
 2, 15287, 5,
 2, 15292, 5,
 2, 15293, 5,
 2, 15294, 5,
 2, 15295, 5,
 2, 15332, 5,
 2, 15333, 5,
 2, 15334, 5,
 2, 15335, 5,
 2, 15340, 5,
 2, 15341, 5,
 2, 15342, 5,
 2, 15343, 5,
 2, 15348, 5,
 2, 15349, 5,
 2, 15350, 5,
 2, 15351, 5,
 2, 15356, 5,
 2, 15357, 5,
 2, 15358, 5,
 2, 15359, 5,
 2, 15652, 5,
 2, 15653, 5,
 2, 15654, 5,
 2, 15655, 5,
 2, 15660, 5,
 2, 15661, 5,
 2, 15662, 5,
 2, 15663, 5,
 2, 15668, 5,
 2, 15669, 5,
 2, 15670, 5,
 2, 15671, 5,
 2, 15676, 5,
 2, 15677, 5,
 2, 15678, 5,
 2, 15679, 5,
 2, 15716, 5,
 2, 15717, 5,
 2, 15718, 5,
 2, 15719, 5,
 2, 15724, 5,
 2, 15725, 5,
 2, 15726, 5,
 2, 15727, 5,
 2, 15732, 5,
 2, 15733, 5,
 2, 15734, 5,
 2, 15735, 5,
 2, 15740, 5,
 2, 15741, 5,
 2, 15742, 5,
 2, 15743, 5,
 2, 15780, 5,
 2, 15781, 5,
 2, 15782, 5,
 2, 15783, 5,
 2, 15788, 5,
 2, 15789, 5,
 2, 15790, 5,
 2, 15791, 5,
 2, 15796, 5,
 2, 15797, 5,
 2, 15798, 5,
 2, 15799, 5,
 2, 15804, 5,
 2, 15805, 5,
 2, 15806, 5,
 2, 15807, 5,
 2, 15844, 5,
 2, 15845, 5,
 2, 15846, 5,
 2, 15847, 5,
 2, 15852, 5,
 2, 15853, 5,
 2, 15854, 5,
 2, 15855, 5,
 2, 15860, 5,
 2, 15861, 5,
 2, 15862, 5,
 2, 15863, 5,
 2, 15868, 5,
 2, 15869, 5,
 2, 15870, 5,
 2, 15871, 5,
 2, 16164, 5,
 2, 16165, 5,
 2, 16166, 5,
 2, 16167, 5,
 2, 16172, 5,
 2, 16173, 5,
 2, 16174, 5,
 2, 16175, 5,
 2, 16180, 5,
 2, 16181, 5,
 2, 16182, 5,
 2, 16183, 5,
 2, 16188, 5,
 2, 16189, 5,
 2, 16190, 5,
 2, 16191, 5,
 2, 16228, 5,
 2, 16229, 5,
 2, 16230, 5,
 2, 16231, 5,
 2, 16236, 5,
 2, 16237, 5,
 2, 16238, 5,
 2, 16239, 5,
 2, 16244, 5,
 2, 16245, 5,
 2, 16246, 5,
 2, 16247, 5,
 2, 16252, 5,
 2, 16253, 5,
 2, 16254, 5,
 2, 16255, 5,
 2, 16292, 5,
 2, 16293, 5,
 2, 16294, 5,
 2, 16295, 5,
 2, 16300, 5,
 2, 16301, 5,
 2, 16302, 5,
 2, 16303, 5,
 2, 16308, 5,
 2, 16309, 5,
 2, 16310, 5,
 2, 16311, 5,
 2, 16316, 5,
 2, 16317, 5,
 2, 16318, 5,
 2, 16319, 5,
 2, 16356, 5,
 2, 16357, 5,
 2, 16358, 5,
 2, 16359, 5,
 2, 16364, 5,
 2, 16365, 5,
 2, 16366, 5,
 2, 16367, 5,
 2, 16372, 5,
 2, 16373, 5,
 2, 16374, 5,
 2, 16375, 5,
 2, 16380, 5,
 2, 16381, 5,
 2, 16382, 5,
 2, 16383, 5,
 2, 2340 , 5,
 2, 2341 , 5,
 2, 2342 , 5,
 2, 2343 , 5,
 2, 2348 , 5,
 2, 2349 , 5,
 2, 2350 , 5,
 2, 2351 , 5,
 2, 2356 , 5,
 2, 2357 , 5,
 2, 2358 , 5,
 2, 2359 , 5,
 2, 2364 , 5,
 2, 2365 , 5,
 2, 2366 , 5,
 2, 2367 , 5,
 2, 2404 , 5,
 2, 2405 , 5,
 2, 2406 , 5,
 2, 2407 , 5,
 2, 2412 , 5,
 2, 2413 , 5,
 2, 2414 , 5,
 2, 2415 , 5,
 2, 2420 , 5,
 2, 2421 , 5,
 2, 2422 , 5,
 2, 2423 , 5,
 2, 2428 , 5,
 2, 2429 , 5,
 2, 2430 , 5,
 2, 2431 , 5,
 2, 2468 , 5,
 2, 2469 , 5,
 2, 2470 , 5,
 2, 2471 , 5,
 2, 2476 , 5,
 2, 2477 , 5,
 2, 2478 , 5,
 2, 2479 , 5,
 2, 2484 , 5,
 2, 2485 , 5,
 2, 2486 , 5,
 2, 2487 , 5,
 2, 2492 , 5,
 2, 2493 , 5,
 2, 2494 , 5,
 2, 2495 , 5,
 2, 2532 , 5,
 2, 2533 , 5,
 2, 2534 , 5,
 2, 2535 , 5,
 2, 2540 , 5,
 2, 2541 , 5,
 2, 2542 , 5,
 2, 2543 , 5,
 2, 2548 , 5,
 2, 2549 , 5,
 2, 2550 , 5,
 2, 2551 , 5,
 2, 2556 , 5,
 2, 2557 , 5,
 2, 2558 , 5,
 2, 2559 , 5,
 2, 2852 , 5,
 2, 2853 , 5,
 2, 2854 , 5,
 2, 2855 , 5,
 2, 2860 , 5,
 2, 2861 , 5,
 2, 2862 , 5,
 2, 2863 , 5,
 2, 2868 , 5,
 2, 2869 , 5,
 2, 2870 , 5,
 2, 2871 , 5,
 2, 2876 , 5,
 2, 2877 , 5,
 2, 2878 , 5,
 2, 2879 , 5,
 2, 2916 , 5,
 2, 2917 , 5,
 2, 2918 , 5,
 2, 2919 , 5,
 2, 2924 , 5,
 2, 2925 , 5,
 2, 2926 , 5,
 2, 2927 , 5,
 2, 2932 , 5,
 2, 2933 , 5,
 2, 2934 , 5,
 2, 2935 , 5,
 2, 2940 , 5,
 2, 2941 , 5,
 2, 2942 , 5,
 2, 2943 , 5,
 2, 2980 , 5,
 2, 2981 , 5,
 2, 2982 , 5,
 2, 2983 , 5,
 2, 2988 , 5,
 2, 2989 , 5,
 2, 2990 , 5,
 2, 2991 , 5,
 2, 2996 , 5,
 2, 2997 , 5,
 2, 2998 , 5,
 2, 2999 , 5,
 2, 3004 , 5,
 2, 3005 , 5,
 2, 3006 , 5,
 2, 3007 , 5,
 2, 3044 , 5,
 2, 3045 , 5,
 2, 3046 , 5,
 2, 3047 , 5,
 2, 3052 , 5,
 2, 3053 , 5,
 2, 3054 , 5,
 2, 3055 , 5,
 2, 3060 , 5,
 2, 3061 , 5,
 2, 3062 , 5,
 2, 3063 , 5,
 2, 3068 , 5,
 2, 3069 , 5,
 2, 3070 , 5,
 2, 3071 , 5,
 2, 3364 , 5,
 2, 3365 , 5,
 2, 3366 , 5,
 2, 3367 , 5,
 2, 3372 , 5,
 2, 3373 , 5,
 2, 3374 , 5,
 2, 3375 , 5,
 2, 3380 , 5,
 2, 3381 , 5,
 2, 3382 , 5,
 2, 3383 , 5,
 2, 3388 , 5,
 2, 3389 , 5,
 2, 3390 , 5,
 2, 3391 , 5,
 2, 3428 , 5,
 2, 3429 , 5,
 2, 3430 , 5,
 2, 3431 , 5,
 2, 3436 , 5,
 2, 3437 , 5,
 2, 3438 , 5,
 2, 3439 , 5,
 2, 3444 , 5,
 2, 3445 , 5,
 2, 3446 , 5,
 2, 3447 , 5,
 2, 3452 , 5,
 2, 3453 , 5,
 2, 3454 , 5,
 2, 3455 , 5,
 2, 3492 , 5,
 2, 3493 , 5,
 2, 3494 , 5,
 2, 3495 , 5,
 2, 3500 , 5,
 2, 3501 , 5,
 2, 3502 , 5,
 2, 3503 , 5,
 2, 3508 , 5,
 2, 3509 , 5,
 2, 3510 , 5,
 2, 3511 , 5,
 2, 3516 , 5,
 2, 3517 , 5,
 2, 3518 , 5,
 2, 3519 , 5,
 2, 3556 , 5,
 2, 3557 , 5,
 2, 3558 , 5,
 2, 3559 , 5,
 2, 3564 , 5,
 2, 3565 , 5,
 2, 3566 , 5,
 2, 3567 , 5,
 2, 3572 , 5,
 2, 3573 , 5,
 2, 3574 , 5,
 2, 3575 , 5,
 2, 3580 , 5,
 2, 3581 , 5,
 2, 3582 , 5,
 2, 3583 , 5,
 2, 3876 , 5,
 2, 3877 , 5,
 2, 3878 , 5,
 2, 3879 , 5,
 2, 3884 , 5,
 2, 3885 , 5,
 2, 3886 , 5,
 2, 3887 , 5,
 2, 3892 , 5,
 2, 3893 , 5,
 2, 3894 , 5,
 2, 3895 , 5,
 2, 3900 , 5,
 2, 3901 , 5,
 2, 3902 , 5,
 2, 3903 , 5,
 2, 3940 , 5,
 2, 3941 , 5,
 2, 3942 , 5,
 2, 3943 , 5,
 2, 3948 , 5,
 2, 3949 , 5,
 2, 3950 , 5,
 2, 3951 , 5,
 2, 3956 , 5,
 2, 3957 , 5,
 2, 3958 , 5,
 2, 3959 , 5,
 2, 3964 , 5,
 2, 3965 , 5,
 2, 3966 , 5,
 2, 3967 , 5,
 2, 4004 , 5,
 2, 4005 , 5,
 2, 4006 , 5,
 2, 4007 , 5,
 2, 4012 , 5,
 2, 4013 , 5,
 2, 4014 , 5,
 2, 4015 , 5,
 2, 4020 , 5,
 2, 4021 , 5,
 2, 4022 , 5,
 2, 4023 , 5,
 2, 4028 , 5,
 2, 4029 , 5,
 2, 4030 , 5,
 2, 4031 , 5,
 2, 4068 , 5,
 2, 4069 , 5,
 2, 4070 , 5,
 2, 4071 , 5,
 2, 4076 , 5,
 2, 4077 , 5,
 2, 4078 , 5,
 2, 4079 , 5,
 2, 4084 , 5,
 2, 4085 , 5,
 2, 4086 , 5,
 2, 4087 , 5,
 2, 4092 , 5,
 2, 4093 , 5,
 2, 4094 , 5,
 2, 4095 , 5,
 2, 6436 , 5,
 2, 6437 , 5,
 2, 6438 , 5,
 2, 6439 , 5,
 2, 6444 , 5,
 2, 6445 , 5,
 2, 6446 , 5,
 2, 6447 , 5,
 2, 6452 , 5,
 2, 6453 , 5,
 2, 6454 , 5,
 2, 6455 , 5,
 2, 6460 , 5,
 2, 6461 , 5,
 2, 6462 , 5,
 2, 6463 , 5,
 2, 6500 , 5,
 2, 6501 , 5,
 2, 6502 , 5,
 2, 6503 , 5,
 2, 6508 , 5,
 2, 6509 , 5,
 2, 6510 , 5,
 2, 6511 , 5,
 2, 6516 , 5,
 2, 6517 , 5,
 2, 6518 , 5,
 2, 6519 , 5,
 2, 6524 , 5,
 2, 6525 , 5,
 2, 6526 , 5,
 2, 6527 , 5,
 2, 6564 , 5,
 2, 6565 , 5,
 2, 6566 , 5,
 2, 6567 , 5,
 2, 6572 , 5,
 2, 6573 , 5,
 2, 6574 , 5,
 2, 6575 , 5,
 2, 6580 , 5,
 2, 6581 , 5,
 2, 6582 , 5,
 2, 6583 , 5,
 2, 6588 , 5,
 2, 6589 , 5,
 2, 6590 , 5,
 2, 6591 , 5,
 2, 6628 , 5,
 2, 6629 , 5,
 2, 6630 , 5,
 2, 6631 , 5,
 2, 6636 , 5,
 2, 6637 , 5,
 2, 6638 , 5,
 2, 6639 , 5,
 2, 6644 , 5,
 2, 6645 , 5,
 2, 6646 , 5,
 2, 6647 , 5,
 2, 6652 , 5,
 2, 6653 , 5,
 2, 6654 , 5,
 2, 6655 , 5,
 2, 6948 , 5,
 2, 6949 , 5,
 2, 6950 , 5,
 2, 6951 , 5,
 2, 6956 , 5,
 2, 6957 , 5,
 2, 6958 , 5,
 2, 6959 , 5,
 2, 6964 , 5,
 2, 6965 , 5,
 2, 6966 , 5,
 2, 6967 , 5,
 2, 6972 , 5,
 2, 6973 , 5,
 2, 6974 , 5,
 2, 6975 , 5,
 2, 7012 , 5,
 2, 7013 , 5,
 2, 7014 , 5,
 2, 7015 , 5,
 2, 7020 , 5,
 2, 7021 , 5,
 2, 7022 , 5,
 2, 7023 , 5,
 2, 7028 , 5,
 2, 7029 , 5,
 2, 7030 , 5,
 2, 7031 , 5,
 2, 7036 , 5,
 2, 7037 , 5,
 2, 7038 , 5,
 2, 7039 , 5,
 2, 7076 , 5,
 2, 7077 , 5,
 2, 7078 , 5,
 2, 7079 , 5,
 2, 7084 , 5,
 2, 7085 , 5,
 2, 7086 , 5,
 2, 7087 , 5,
 2, 7092 , 5,
 2, 7093 , 5,
 2, 7094 , 5,
 2, 7095 , 5,
 2, 7100 , 5,
 2, 7101 , 5,
 2, 7102 , 5,
 2, 7103 , 5,
 2, 7140 , 5,
 2, 7141 , 5,
 2, 7142 , 5,
 2, 7143 , 5,
 2, 7148 , 5,
 2, 7149 , 5,
 2, 7150 , 5,
 2, 7151 , 5,
 2, 7156 , 5,
 2, 7157 , 5,
 2, 7158 , 5,
 2, 7159 , 5,
 2, 7164 , 5,
 2, 7165 , 5,
 2, 7166 , 5,
 2, 7167 , 5,
 2, 7460 , 5,
 2, 7461 , 5,
 2, 7462 , 5,
 2, 7463 , 5,
 2, 7468 , 5,
 2, 7469 , 5,
 2, 7470 , 5,
 2, 7471 , 5,
 2, 7476 , 5,
 2, 7477 , 5,
 2, 7478 , 5,
 2, 7479 , 5,
 2, 7484 , 5,
 2, 7485 , 5,
 2, 7486 , 5,
 2, 7487 , 5,
 2, 7524 , 5,
 2, 7525 , 5,
 2, 7526 , 5,
 2, 7527 , 5,
 2, 7532 , 5,
 2, 7533 , 5,
 2, 7534 , 5,
 2, 7535 , 5,
 2, 7540 , 5,
 2, 7541 , 5,
 2, 7542 , 5,
 2, 7543 , 5,
 2, 7548 , 5,
 2, 7549 , 5,
 2, 7550 , 5,
 2, 7551 , 5,
 2, 7588 , 5,
 2, 7589 , 5,
 2, 7590 , 5,
 2, 7591 , 5,
 2, 7596 , 5,
 2, 7597 , 5,
 2, 7598 , 5,
 2, 7599 , 5,
 2, 7604 , 5,
 2, 7605 , 5,
 2, 7606 , 5,
 2, 7607 , 5,
 2, 7612 , 5,
 2, 7613 , 5,
 2, 7614 , 5,
 2, 7615 , 5,
 2, 7652 , 5,
 2, 7653 , 5,
 2, 7654 , 5,
 2, 7655 , 5,
 2, 7660 , 5,
 2, 7661 , 5,
 2, 7662 , 5,
 2, 7663 , 5,
 2, 7668 , 5,
 2, 7669 , 5,
 2, 7670 , 5,
 2, 7671 , 5,
 2, 7676 , 5,
 2, 7677 , 5,
 2, 7678 , 5,
 2, 7679 , 5,
 2, 7972 , 5,
 2, 7973 , 5,
 2, 7974 , 5,
 2, 7975 , 5,
 2, 7980 , 5,
 2, 7981 , 5,
 2, 7982 , 5,
 2, 7983 , 5,
 2, 7988 , 5,
 2, 7989 , 5,
 2, 7990 , 5,
 2, 7991 , 5,
 2, 7996 , 5,
 2, 7997 , 5,
 2, 7998 , 5,
 2, 7999 , 5,
 2, 8036 , 5,
 2, 8037 , 5,
 2, 8038 , 5,
 2, 8039 , 5,
 2, 8044 , 5,
 2, 8045 , 5,
 2, 8046 , 5,
 2, 8047 , 5,
 2, 8052 , 5,
 2, 8053 , 5,
 2, 8054 , 5,
 2, 8055 , 5,
 2, 8060 , 5,
 2, 8061 , 5,
 2, 8062 , 5,
 2, 8063 , 5,
 2, 8100 , 5,
 2, 8101 , 5,
 2, 8102 , 5,
 2, 8103 , 5,
 2, 8108 , 5,
 2, 8109 , 5,
 2, 8110 , 5,
 2, 8111 , 5,
 2, 8116 , 5,
 2, 8117 , 5,
 2, 8118 , 5,
 2, 8119 , 5,
 2, 8124 , 5,
 2, 8125 , 5,
 2, 8126 , 5,
 2, 8127 , 5,
 2, 8164 , 5,
 2, 8165 , 5,
 2, 8166 , 5,
 2, 8167 , 5,
 2, 8172 , 5,
 2, 8173 , 5,
 2, 8174 , 5,
 2, 8175 , 5,
 2, 8180 , 5,
 2, 8181 , 5,
 2, 8182 , 5,
 2, 8183 , 5,
 2, 8188 , 5,
 2, 8189 , 5,
 2, 8190 , 5,
 2, 8191 , 5,
}
