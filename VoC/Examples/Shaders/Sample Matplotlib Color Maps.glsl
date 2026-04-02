#version 420

// original https://www.shadertoy.com/view/Nd3fR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
Grayscale is boring. Feel free to use these for your projects. 

I wanted more colormaps to choose from than Mattz functions. I had 
a cmap translator into textures, graphs, and csv laying around.
I added a simple scipy fitter to translate any cmap into poly6 
functions too. It doesn't work for all colormaps, but all the 
pretty ones work great. 

If you want to add a colormap thats not here you can use my
python code to make it yourself (https://pastebin.com/mf5GfGCc)

If you wonder how all the other colormaps look, see an 
incomplete list the matplotlib documentation 
(https://matplotlib.org/stable/tutorials/colors/colormaps.html)
or my graphs with everything (https://imgur.com/a/xfZlxlp).
*/

// makes afmhot colormap with polynimal 6
vec3 afmhot(float t) {
    const vec3 c0 = vec3(-0.020390,0.009557,0.018508);
    const vec3 c1 = vec3(3.108226,-0.106297,-1.105891);
    const vec3 c2 = vec3(-14.539061,-2.943057,14.548595);
    const vec3 c3 = vec3(71.394557,22.644423,-71.418400);
    const vec3 c4 = vec3(-152.022488,-31.024563,152.048692);
    const vec3 c5 = vec3(139.593599,12.411251,-139.604042);
    const vec3 c6 = vec3(-46.532952,-0.000874,46.532928);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes Blues_r colormap with polynimal 6
vec3 Blues_r(float t) {
    const vec3 c0 = vec3(0.042660,0.186181,0.409512);
    const vec3 c1 = vec3(-0.703712,1.094974,2.049478);
    const vec3 c2 = vec3(7.995725,-0.686110,-4.998203);
    const vec3 c3 = vec3(-24.421963,2.680736,7.532937);
    const vec3 c4 = vec3(47.519089,-4.615112,-5.126531);
    const vec3 c5 = vec3(-46.038418,2.606781,0.685560);
    const vec3 c6 = vec3(16.586546,-0.279280,0.447047);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes bone colormap with polynimal 6
vec3 bone(float t) {
    const vec3 c0 = vec3(-0.005007,-0.003054,0.004092);
    const vec3 c1 = vec3(1.098251,0.964561,0.971829);
    const vec3 c2 = vec3(-2.688698,-0.537516,2.444353);
    const vec3 c3 = vec3(12.667310,-0.657473,-8.158684);
    const vec3 c4 = vec3(-27.183124,8.398806,10.182004);
    const vec3 c5 = vec3(26.505377,-12.576925,-5.329155);
    const vec3 c6 = vec3(-9.395265,5.416416,0.883918);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes BuPu_r colormap with polynimal 6
vec3 BuPu_r(float t) {
    const vec3 c0 = vec3(0.290975,0.010073,0.283355);
    const vec3 c1 = vec3(2.284922,-0.278000,1.989093);
    const vec3 c2 = vec3(-6.399278,8.646163,-3.757712);
    const vec3 c3 = vec3(2.681161,-20.491129,4.065305);
    const vec3 c4 = vec3(12.990405,24.836197,0.365773);
    const vec3 c5 = vec3(-16.216830,-16.111779,-4.006291);
    const vec3 c6 = vec3(5.331023,4.380922,2.057249);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes cividis colormap with polynimal 6
vec3 cividis(float t) {
    const vec3 c0 = vec3(-0.008598,0.136152,0.291357);
    const vec3 c1 = vec3(-0.415049,0.639599,3.028812);
    const vec3 c2 = vec3(15.655097,0.392899,-22.640943);
    const vec3 c3 = vec3(-59.689584,-1.424169,75.666364);
    const vec3 c4 = vec3(103.509006,2.627500,-122.512551);
    const vec3 c5 = vec3(-84.086992,-2.156916,94.888003);
    const vec3 c6 = vec3(26.055600,0.691800,-28.537831);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes CMRmap colormap with polynimal 6
vec3 CMRmap(float t) {
    const vec3 c0 = vec3(-0.046981,0.001239,0.005501);
    const vec3 c1 = vec3(4.080583,1.192717,3.049337);
    const vec3 c2 = vec3(-38.877409,1.524425,20.200215);
    const vec3 c3 = vec3(189.038452,-32.746447,-140.774611);
    const vec3 c4 = vec3(-382.197327,95.587531,270.024592);
    const vec3 c5 = vec3(339.891791,-100.379096,-212.471161);
    const vec3 c6 = vec3(-110.928480,35.828481,60.985694);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes coolwarm colormap with polynimal 6
vec3 coolwarm(float t) {
    const vec3 c0 = vec3(0.227376,0.286898,0.752999);
    const vec3 c1 = vec3(1.204846,2.314886,1.563499);
    const vec3 c2 = vec3(0.102341,-7.369214,-1.860252);
    const vec3 c3 = vec3(2.218624,32.578457,-1.643751);
    const vec3 c4 = vec3(-5.076863,-75.374676,-3.704589);
    const vec3 c5 = vec3(1.336276,73.453060,9.595678);
    const vec3 c6 = vec3(0.694723,-25.863102,-4.558659);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes cubehelix colormap with polynimal 6
vec3 cubehelix(float t) {
    const vec3 c0 = vec3(-0.079465,0.040608,-0.009636);
    const vec3 c1 = vec3(6.121943,-1.666276,1.342651);
    const vec3 c2 = vec3(-61.373834,27.620334,19.280747);
    const vec3 c3 = vec3(240.127160,-93.314549,-154.494465);
    const vec3 c4 = vec3(-404.129586,133.012936,388.857101);
    const vec3 c5 = vec3(306.008802,-81.526778,-397.337219);
    const vec3 c6 = vec3(-85.633074,16.800478,143.433300);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes gist_earth colormap with polynimal 6
vec3 gist_earth(float t) {
    const vec3 c0 = vec3(-0.005626,-0.032771,0.229230);
    const vec3 c1 = vec3(0.628905,1.462908,4.617318);
    const vec3 c2 = vec3(3.960921,9.740478,-25.721645);
    const vec3 c3 = vec3(-32.735710,-53.470618,60.568598);
    const vec3 c4 = vec3(91.584783,109.398709,-74.866221);
    const vec3 c5 = vec3(-101.138314,-103.815111,48.418061);
    const vec3 c6 = vec3(38.745198,37.752237,-12.232828);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes hsv colormap with polynimal 6
vec3 hsv(float t) {
    const vec3 c0 = vec3(0.834511,-0.153764,-0.139860);
    const vec3 c1 = vec3(8.297883,13.629371,7.673034);
    const vec3 c2 = vec3(-80.602944,-80.577977,-90.865764);
    const vec3 c3 = vec3(245.028545,291.294154,390.181844);
    const vec3 c4 = vec3(-376.406597,-575.667879,-714.180803);
    const vec3 c5 = vec3(306.639709,538.472148,596.580595);
    const vec3 c6 = vec3(-102.934273,-187.108098,-189.286489);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes inferno colormap with polynimal 6
vec3 inferno(float t) {
    const vec3 c0 = vec3(0.000129,0.001094,-0.041044);
    const vec3 c1 = vec3(0.083266,0.574933,4.155398);
    const vec3 c2 = vec3(11.783686,-4.013093,-16.439814);
    const vec3 c3 = vec3(-42.246539,17.689298,45.210269);
    const vec3 c4 = vec3(78.087062,-33.838649,-83.264061);
    const vec3 c5 = vec3(-72.108852,32.950143,74.479447);
    const vec3 c6 = vec3(25.378501,-12.368929,-23.407604);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes jet colormap with polynimal 6
vec3 jet(float t) {
    const vec3 c0 = vec3(-0.071839,0.105300,0.510959);
    const vec3 c1 = vec3(3.434264,-5.856282,5.020179);
    const vec3 c2 = vec3(-35.088272,62.590515,-12.661725);
    const vec3 c3 = vec3(125.621078,-187.192678,8.399805);
    const vec3 c4 = vec3(-179.495111,277.458688,-26.089763);
    const vec3 c5 = vec3(113.825719,-218.486063,52.463600);
    const vec3 c6 = vec3(-27.714880,71.427477,-27.714893);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes jet colormap with polynimal 6
vec3 magma(float t) {
    const vec3 c0 = vec3(-0.002292,-0.001348,-0.011890);
    const vec3 c1 = vec3(0.234451,0.702427,2.497211);
    const vec3 c2 = vec3(8.459706,-3.649448,0.385699);
    const vec3 c3 = vec3(-28.029205,14.441378,-13.820938);
    const vec3 c4 = vec3(52.814176,-28.301374,13.021646);
    const vec3 c5 = vec3(-51.349945,29.406659,4.305315);
    const vec3 c6 = vec3(18.877608,-11.626687,-5.627010);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes ocean colormap with polynimal 6
vec3 ocean(float t) {
    const vec3 c0 = vec3(0.005727,0.451550,-0.000941);
    const vec3 c1 = vec3(-0.112625,1.079697,1.001170);
    const vec3 c2 = vec3(-0.930272,-28.415474,0.004744);
    const vec3 c3 = vec3(15.125713,109.226840,-0.011841);
    const vec3 c4 = vec3(-54.993643,-168.660130,0.012964);
    const vec3 c5 = vec3(74.155713,119.622305,-0.005110);
    const vec3 c6 = vec3(-32.297651,-32.297650,-0.000046);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes PuBu_r colormap with polynimal 6
vec3 PuBu_r(float t) {
    const vec3 c0 = vec3(-0.006363,0.212872,0.336555);
    const vec3 c1 = vec3(1.081919,1.510170,1.985891);
    const vec3 c2 = vec3(-14.783872,-6.062404,-2.068039);
    const vec3 c3 = vec3(71.020484,24.455925,-4.350981);
    const vec3 c4 = vec3(-127.620020,-46.977973,14.599012);
    const vec3 c5 = vec3(101.930678,41.789097,-14.293631);
    const vec3 c6 = vec3(-30.634205,-13.967854,4.778537);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes rainbow colormap with polynimal 6
vec3 rainbow(float t) {
    const vec3 c0 = vec3(0.503560,-0.002932,1.000009);
    const vec3 c1 = vec3(-1.294985,3.144463,0.001872);
    const vec3 c2 = vec3(-16.971202,0.031355,-1.232219);
    const vec3 c3 = vec3(97.134102,-5.180126,-0.029721);
    const vec3 c4 = vec3(-172.585487,-0.338714,0.316782);
    const vec3 c5 = vec3(131.971426,3.514534,-0.061568);
    const vec3 c6 = vec3(-37.784412,-1.171512,0.003376);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes PuRd_r colormap with polynimal 6
vec3 PuRd_r(float t) {
    const vec3 c0 = vec3(0.425808,-0.016400,0.108687);
    const vec3 c1 = vec3(0.317304,0.729767,2.091430);
    const vec3 c2 = vec3(13.496685,-7.880910,-14.132707);
    const vec3 c3 = vec3(-48.433187,38.030685,64.370712);
    const vec3 c4 = vec3(60.867293,-65.403385,-126.336402);
    const vec3 c5 = vec3(-28.305816,50.079623,111.580346);
    const vec3 c6 = vec3(2.578842,-14.582396,-36.726260);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes RdYlBu_r colormap with polynimal 6
vec3 RdYlBu_r(float t) {
    const vec3 c0 = vec3(0.207621,0.196195,0.618832);
    const vec3 c1 = vec3(-0.088125,3.196170,-0.353302);
    const vec3 c2 = vec3(8.261232,-8.366855,14.368787);
    const vec3 c3 = vec3(-2.922476,33.244294,-43.419173);
    const vec3 c4 = vec3(-34.085327,-74.476041,37.159352);
    const vec3 c5 = vec3(50.429790,67.145621,-1.750169);
    const vec3 c6 = vec3(-21.188828,-20.935464,-6.501427);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes Spectral_r colormap with polynimal 6
vec3 Spectral_r(float t) {
    const vec3 c0 = vec3(0.426208,0.275203,0.563277);
    const vec3 c1 = vec3(-5.321958,3.761848,5.477444);
    const vec3 c2 = vec3(42.422339,-15.057685,-57.232349);
    const vec3 c3 = vec3(-100.917716,57.029463,232.590601);
    const vec3 c4 = vec3(106.422535,-116.177338,-437.123306);
    const vec3 c5 = vec3(-48.460514,103.570154,378.807920);
    const vec3 c6 = vec3(6.016269,-33.393152,-122.850806);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes twilight colormap with polynimal 6
vec3 twilight(float t) {
    const vec3 c0 = vec3(0.996106,0.851653,0.940566);
    const vec3 c1 = vec3(-6.529620,-0.183448,-3.940750);
    const vec3 c2 = vec3(40.899579,-7.894242,38.569228);
    const vec3 c3 = vec3(-155.212979,4.404793,-167.925730);
    const vec3 c4 = vec3(296.687222,24.084913,315.087856);
    const vec3 c5 = vec3(-261.270519,-29.995422,-266.972991);
    const vec3 c6 = vec3(85.335349,9.602600,85.227117);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes twilight_shifted colormap with polynimal 6
vec3 twilight_shifted(float t) {
    const vec3 c0 = vec3(0.120488,0.047735,0.106111);
    const vec3 c1 = vec3(5.175161,0.597944,7.333840);
    const vec3 c2 = vec3(-47.426009,-0.862094,-49.143485);
    const vec3 c3 = vec3(197.225325,47.538667,194.773468);
    const vec3 c4 = vec3(-361.218441,-146.888121,-389.642741);
    const vec3 c5 = vec3(298.941929,151.947507,359.860766);
    const vec3 c6 = vec3(-92.697067,-52.312119,-123.143476);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes viridis colormap with polynimal 6
vec3 viridis(float t) {
    const vec3 c0 = vec3(0.274344,0.004462,0.331359);
    const vec3 c1 = vec3(0.108915,1.397291,1.388110);
    const vec3 c2 = vec3(-0.319631,0.243490,0.156419);
    const vec3 c3 = vec3(-4.629188,-5.882803,-19.646115);
    const vec3 c4 = vec3(6.181719,14.388598,57.442181);
    const vec3 c5 = vec3(4.876952,-13.955112,-66.125783);
    const vec3 c6 = vec3(-5.513165,4.709245,26.582180);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes YlGnGn_r colormap with polynimal 6
vec3 YlGnGn_r(float t) {
    const vec3 c0 = vec3(0.006153,0.269865,0.154795);
    const vec3 c1 = vec3(-0.563452,1.218061,0.825586);
    const vec3 c2 = vec3(7.296193,-2.560031,-5.402727);
    const vec3 c3 = vec3(-19.990101,12.478140,25.051507);
    const vec3 c4 = vec3(37.139815,-26.377692,-45.607642);
    const vec3 c5 = vec3(-35.072408,24.166247,36.357837);
    const vec3 c6 = vec3(12.187661,-8.203542,-10.475316);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes YlGnBu_r colormap with polynimal 6
vec3 YlGnBu_r(float t) {
    const vec3 c0 = vec3(0.016999,0.127718,0.329492);
    const vec3 c1 = vec3(1.571728,0.025897,2.853610);
    const vec3 c2 = vec3(-4.414197,5.924816,-11.635781);
    const vec3 c3 = vec3(-12.438137,-8.086194,34.584365);
    const vec3 c4 = vec3(67.131044,-2.929808,-58.635788);
    const vec3 c5 = vec3(-82.372983,11.898509,47.184502);
    const vec3 c6 = vec3(31.515446,-5.975157,-13.820580);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// makes YlGnBu_r colormap with polynimal 6
vec3 YlGnRd_r(float t) {
    const vec3 c0 = vec3(0.501291,0.002062,0.146180);
    const vec3 c1 = vec3(1.930635,-0.014549,0.382222);
    const vec3 c2 = vec3(0.252402,-2.449429,-6.385366);
    const vec3 c3 = vec3(-10.884918,30.497903,29.134150);
    const vec3 c4 = vec3(18.654329,-67.528678,-54.909286);
    const vec3 c5 = vec3(-12.193478,59.311181,49.311295);
    const vec3 c6 = vec3(2.736321,-18.828760,-16.894758);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float cmapCount = 25.;
    float x = floor(uv.x*cmapCount);    
    glFragColor = vec4(0, 0, 0, 1);
    
    if (x == 0.) {
        glFragColor.xyz = afmhot(uv.y);
    } else if (x == 1.) {
        glFragColor.xyz = Blues_r(uv.y);
    } else if (x == 2.) {
        glFragColor.xyz = bone(uv.y);
    } else if (x == 3.) {
        glFragColor.xyz = BuPu_r(uv.y);
    } else if (x == 4.) {
        glFragColor.xyz = cividis(uv.y);
    } else if (x == 5.) {
        glFragColor.xyz = CMRmap(uv.y);
    } else if (x == 6.) {
        glFragColor.xyz = coolwarm(uv.y);
    } else if (x == 7.) {
        glFragColor.xyz = cubehelix(uv.y);
    } else if (x == 8.) {
        glFragColor.xyz = gist_earth(uv.y);
    } else if (x == 9.) {
        glFragColor.xyz = hsv(uv.y);
    } else if (x == 10.) {
        glFragColor.xyz = inferno(uv.y);
    } else if (x == 11.) {
        glFragColor.xyz = jet(uv.y);
    } else if (x == 12.) {
        glFragColor.xyz = magma(uv.y);
    } else if (x == 13.) {
        glFragColor.xyz = ocean(uv.y);
    } else if (x == 14.) {
        glFragColor.xyz = PuBu_r(uv.y);
    } else if (x == 15.) {
        glFragColor.xyz = rainbow(uv.y);
    } else if (x == 16.) {
        glFragColor.xyz = PuRd_r(uv.y);
    } else if (x == 17.) {
        glFragColor.xyz = RdYlBu_r(uv.y);
    } else if (x == 18.) {
        glFragColor.xyz = Spectral_r(uv.y);
    } else if (x == 19.) {
        glFragColor.xyz = twilight(uv.y);
    } else if (x == 20.) {
        glFragColor.xyz = twilight_shifted(uv.y);
    } else if (x == 21.) {
        glFragColor.xyz = viridis(uv.y);
    } else if (x == 22.) {
        glFragColor.xyz = YlGnGn_r(uv.y);
    } else if (x == 23.) {
        glFragColor.xyz = YlGnBu_r(uv.y);
    } else if (x == 24.) {
        glFragColor.xyz = YlGnRd_r(uv.y);
    }   
}
