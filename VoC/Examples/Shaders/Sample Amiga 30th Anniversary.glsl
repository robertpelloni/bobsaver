#version 420

// pellicus 2015-07-01 Shadertoy
// My AMIGA's 30th anniversary contribution.

// started from iq primitives.
// switched to a pure raytracing approach
// added the text title borrowing code from https://www.shadertoy.com/view/Mt2GWD
//
// This is my first shadertoy.com production :D
// so veeery far to be considered a well written and optimized code :D.
// Heavly inspired from http://meatfighter.com/juggler/ and totally rebuilt on GLSL.

// This is the Amiga Juggler , a raytracing animation by Eric Graham 86/87 ... yes,
// 28 years ago!. I think this is one of the most inspiring piece
// of digital art made on Amiga after all :D.
// I desired to see it in real time since I've seen it
// on my Amiga, tons of years ago, It was provided as a playback of a precalculated movie.

// I'll try to post a little more about this shader on my new blog next days
//  www.ereticus.com
// a site where I , @pellicus, will rant some heresies ;) and ideas about graphic stuff, shaders,
// raytracing and alternative rendering techs, engine3ds, unity plugins, and stuff like
// that looking at videogames
// and multimedia productions perspective.

// Thanks you all for watching. :D
// Genoa (Italy), 1 july 2015
// Dario Pelella (@pellicus or dario.pelella on FB)

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ===============================================================
// VECTOR TEXT TITLE  ============================================
// ===============================================================
vec2 g_pen;
vec4 g_out_color;

void tris(vec2 a, vec2 c,vec2 b)
{
    vec2 pa = g_pen-a;
    bool si = (b.x-a.x)*pa.y-(b.y-a.y)*pa.x > 0.0;
    vec2 ca= c-a;
    if ((ca.x)*pa.y-(ca.y)*pa.x > 0.0 == si) return;
    vec2 cb=c-b;
    if (cb.x*(g_pen.y-b.y)-cb.y*(g_pen.x-b.x) > 0.0 != si) return;
    g_out_color = vec4(1,1,1,1);
}

void vector_text()
{
    vec2 uv=vec2(4.5,0.5);
       uv=g_pen;
    vec2 off =vec2(.5,2.0);
    
     off= abs(uv-vec2(0.125000,0.125000)) - vec2(0.125000); 
    if( off.x <= 00.0 || off.y <=  00.0)
    { tris(vec2(0.207,0.005),vec2(0.210,0.010),vec2(0.133,0.006));tris(vec2(0.090,0.005),vec2(0.095,0.012),vec2(0.005,0.005));tris(vec2(0.095,0.012),vec2(0.000,0.011),vec2(0.005,0.005));tris(vec2(0.210,0.010),vec2(0.129,0.012),vec2(0.133,0.006));tris(vec2(0.095,0.012),vec2(0.002,0.016),vec2(0.000,0.011));tris(vec2(0.210,0.010),vec2(0.205,0.017),vec2(0.129,0.012));tris(vec2(0.095,0.012),vec2(0.090,0.017),vec2(0.002,0.016));tris(vec2(0.205,0.017),vec2(0.136,0.018),vec2(0.129,0.012));tris(vec2(0.205,0.017),vec2(0.196,0.019),vec2(0.136,0.018));
        tris(vec2(0.090,0.017),vec2(0.078,0.020),vec2(0.002,0.016));tris(vec2(0.196,0.019),vec2(0.148,0.021),vec2(0.136,0.018));tris(vec2(0.196,0.019),vec2(0.181,0.026),vec2(0.148,0.021));tris(vec2(0.078,0.020),vec2(0.021,0.026),vec2(0.002,0.016));tris(vec2(0.181,0.026),vec2(0.155,0.029),vec2(0.148,0.021));tris(vec2(0.078,0.020),vec2(0.071,0.035),vec2(0.021,0.026));tris(vec2(0.071,0.035),vec2(0.072,0.072),vec2(0.021,0.026));tris(vec2(0.072,0.072),vec2(0.072,0.086),vec2(0.021,0.026));tris(vec2(0.131,0.072),vec2(0.072,0.086),vec2(0.072,0.072));
        tris(vec2(0.122,0.086),vec2(0.131,0.072),vec2(0.075,0.154));tris(vec2(0.131,0.072),vec2(0.122,0.086),vec2(0.072,0.086));tris(vec2(0.072,0.086),vec2(0.075,0.154),vec2(0.021,0.026));tris(vec2(0.181,0.026),vec2(0.131,0.072),vec2(0.155,0.029));tris(vec2(0.054,0.205),vec2(0.131,0.072),vec2(0.181,0.026));tris(vec2(0.075,0.154),vec2(0.032,0.203),vec2(0.021,0.026));tris(vec2(0.131,0.072),vec2(0.054,0.205),vec2(0.075,0.154));tris(vec2(0.075,0.154),vec2(0.054,0.205),vec2(0.032,0.203));tris(vec2(0.054,0.205),vec2(0.042,0.209),vec2(0.032,0.203));
        tris(vec2(0.287,0.000),vec2(0.230,0.008),vec2(0.258,0.002));tris(vec2(0.287,0.000),vec2(0.333,0.008),vec2(0.230,0.008));tris(vec2(0.275,0.089),vec2(0.272,0.094),vec2(0.173,0.094));tris(vec2(0.275,0.089),vec2(0.173,0.094),vec2(0.171,0.090));tris(vec2(0.275,0.089),vec2(0.171,0.090),vec2(0.177,0.083));tris(vec2(0.269,0.083),vec2(0.275,0.089),vec2(0.177,0.083));tris(vec2(0.258,0.081),vec2(0.269,0.083),vec2(0.177,0.083));tris(vec2(0.258,0.081),vec2(0.177,0.083),vec2(0.190,0.080));tris(vec2(0.252,0.071),vec2(0.258,0.081),vec2(0.190,0.080));
        tris(vec2(0.252,0.071),vec2(0.190,0.080),vec2(0.202,0.061));tris(vec2(0.268,0.018),vec2(0.252,0.071),vec2(0.202,0.061));tris(vec2(0.268,0.018),vec2(0.202,0.061),vec2(0.215,0.016));tris(vec2(0.268,0.018),vec2(0.215,0.016),vec2(0.230,0.008));tris(vec2(0.295,0.017),vec2(0.268,0.018),vec2(0.230,0.008));tris(vec2(0.295,0.017),vec2(0.230,0.008),vec2(0.333,0.008));tris(vec2(0.196,0.156),vec2(0.181,0.158),vec2(0.189,0.153));tris(vec2(0.196,0.156),vec2(0.197,0.170),vec2(0.181,0.158));tris(vec2(0.197,0.170),vec2(0.175,0.175),vec2(0.181,0.158));
        tris(vec2(0.197,0.170),vec2(0.198,0.189),vec2(0.175,0.175));tris(vec2(0.198,0.189),vec2(0.168,0.196),vec2(0.175,0.175));tris(vec2(0.287,0.191),vec2(0.212,0.193),vec2(0.258,0.181));tris(vec2(0.212,0.193),vec2(0.168,0.196),vec2(0.198,0.189));tris(vec2(0.287,0.191),vec2(0.168,0.196),vec2(0.212,0.193));tris(vec2(0.287,0.191),vec2(0.178,0.203),vec2(0.168,0.196));tris(vec2(0.287,0.191),vec2(0.208,0.207),vec2(0.178,0.203));
    }
    if(g_out_color.a>0.0)return;
    off= abs(uv-vec2(0.375000,0.125000)) - vec2(0.125000); if( off.x <= 0.0 || off.y <=  0.0)
    { tris(vec2(0.287,0.000),vec2(0.230,0.008),vec2(0.258,0.002));tris(vec2(0.287,0.000),vec2(0.333,0.008),vec2(0.230,0.008));
        tris(vec2(0.275,0.089),vec2(0.272,0.094),vec2(0.173,0.094));tris(vec2(0.275,0.089),vec2(0.173,0.094),vec2(0.171,0.090));tris(vec2(0.275,0.089),vec2(0.171,0.090),vec2(0.177,0.083));tris(vec2(0.269,0.083),vec2(0.275,0.089),vec2(0.177,0.083));tris(vec2(0.258,0.081),vec2(0.269,0.083),vec2(0.177,0.083));tris(vec2(0.258,0.081),vec2(0.177,0.083),vec2(0.190,0.080));tris(vec2(0.252,0.071),vec2(0.258,0.081),vec2(0.190,0.080));tris(vec2(0.252,0.071),vec2(0.190,0.080),vec2(0.202,0.061));tris(vec2(0.268,0.018),vec2(0.252,0.071),vec2(0.202,0.061));
        tris(vec2(0.268,0.018),vec2(0.202,0.061),vec2(0.215,0.016));tris(vec2(0.268,0.018),vec2(0.215,0.016),vec2(0.230,0.008));tris(vec2(0.295,0.017),vec2(0.268,0.018),vec2(0.230,0.008));tris(vec2(0.295,0.017),vec2(0.230,0.008),vec2(0.333,0.008));tris(vec2(0.333,0.008),vec2(0.319,0.030),vec2(0.295,0.017));tris(vec2(0.333,0.008),vec2(0.370,0.034),vec2(0.319,0.030));tris(vec2(0.370,0.034),vec2(0.332,0.071),vec2(0.319,0.030));tris(vec2(0.370,0.034),vec2(0.386,0.077),vec2(0.332,0.071));tris(vec2(0.386,0.077),vec2(0.322,0.116),vec2(0.332,0.071));
        tris(vec2(0.386,0.077),vec2(0.356,0.148),vec2(0.322,0.116));tris(vec2(0.356,0.148),vec2(0.297,0.154),vec2(0.322,0.116));tris(vec2(0.356,0.148),vec2(0.258,0.181),vec2(0.297,0.154));tris(vec2(0.356,0.148),vec2(0.287,0.191),vec2(0.258,0.181));tris(vec2(0.287,0.191),vec2(0.212,0.193),vec2(0.258,0.181));tris(vec2(0.287,0.191),vec2(0.168,0.196),vec2(0.212,0.193));tris(vec2(0.287,0.191),vec2(0.178,0.203),vec2(0.168,0.196));tris(vec2(0.287,0.191),vec2(0.208,0.207),vec2(0.178,0.203));tris(vec2(0.510,0.005),vec2(0.512,0.010),vec2(0.415,0.006));
        tris(vec2(0.512,0.010),vec2(0.409,0.012),vec2(0.415,0.006));tris(vec2(0.512,0.010),vec2(0.506,0.016),vec2(0.409,0.012));tris(vec2(0.506,0.016),vec2(0.414,0.018),vec2(0.409,0.012));tris(vec2(0.506,0.016),vec2(0.496,0.019),vec2(0.414,0.018));tris(vec2(0.496,0.019),vec2(0.425,0.019),vec2(0.414,0.018));tris(vec2(0.496,0.019),vec2(0.484,0.027),vec2(0.425,0.019));tris(vec2(0.484,0.027),vec2(0.431,0.029),vec2(0.425,0.019));tris(vec2(0.484,0.027),vec2(0.439,0.183),vec2(0.431,0.029));tris(vec2(0.439,0.183),vec2(0.387,0.182),vec2(0.431,0.029));
        tris(vec2(0.439,0.183),vec2(0.451,0.188),vec2(0.387,0.182));tris(vec2(0.451,0.188),vec2(0.370,0.190),vec2(0.387,0.182));tris(vec2(0.451,0.188),vec2(0.460,0.194),vec2(0.370,0.190));tris(vec2(0.460,0.194),vec2(0.362,0.195),vec2(0.370,0.190));tris(vec2(0.460,0.194),vec2(0.452,0.202),vec2(0.362,0.195));tris(vec2(0.452,0.202),vec2(0.368,0.202),vec2(0.362,0.195));tris(vec2(0.556,0.200),vec2(0.487,0.200),vec2(0.489,0.193));tris(vec2(0.510,0.183),vec2(0.556,0.200),vec2(0.489,0.193));
    }
    if(g_out_color.a>0.0)return;
    off= abs(uv-vec2(0.625000,0.125000)) - vec2(0.125000); if( off.x <= 0.0 || off.y <=  0.0)
    { tris(vec2(0.510,0.005),vec2(0.512,0.010),vec2(0.415,0.006));
        tris(vec2(0.512,0.010),vec2(0.409,0.012),vec2(0.415,0.006));tris(vec2(0.512,0.010),vec2(0.506,0.016),vec2(0.409,0.012));tris(vec2(0.506,0.016),vec2(0.414,0.018),vec2(0.409,0.012));tris(vec2(0.506,0.016),vec2(0.496,0.019),vec2(0.414,0.018));tris(vec2(0.686,0.011),vec2(0.666,0.012),vec2(0.678,0.007));tris(vec2(0.626,0.006),vec2(0.628,0.011),vec2(0.531,0.006));tris(vec2(0.782,0.007),vec2(0.784,0.011),vec2(0.711,0.006));tris(vec2(0.628,0.011),vec2(0.527,0.011),vec2(0.531,0.006));tris(vec2(0.784,0.011),vec2(0.708,0.012),vec2(0.711,0.006));
        tris(vec2(0.784,0.011),vec2(0.781,0.017),vec2(0.708,0.012));tris(vec2(0.628,0.011),vec2(0.533,0.018),vec2(0.527,0.011));tris(vec2(0.628,0.011),vec2(0.622,0.018),vec2(0.533,0.018));tris(vec2(0.781,0.017),vec2(0.714,0.018),vec2(0.708,0.012));tris(vec2(0.622,0.018),vec2(0.611,0.019),vec2(0.533,0.018));tris(vec2(0.611,0.019),vec2(0.543,0.020),vec2(0.533,0.018));tris(vec2(0.781,0.017),vec2(0.727,0.020),vec2(0.714,0.018));tris(vec2(0.686,0.011),vec2(0.688,0.021),vec2(0.666,0.012));tris(vec2(0.781,0.017),vec2(0.758,0.026),vec2(0.727,0.020));
        tris(vec2(0.611,0.019),vec2(0.600,0.029),vec2(0.543,0.020));tris(vec2(0.600,0.029),vec2(0.548,0.030),vec2(0.543,0.020));tris(vec2(0.758,0.026),vec2(0.734,0.032),vec2(0.727,0.020));tris(vec2(0.758,0.026),vec2(0.691,0.160),vec2(0.734,0.032));tris(vec2(0.600,0.029),vec2(0.565,0.161),vec2(0.548,0.030));tris(vec2(0.565,0.161),vec2(0.510,0.183),vec2(0.548,0.030));tris(vec2(0.556,0.200),vec2(0.487,0.200),vec2(0.489,0.193));tris(vec2(0.510,0.183),vec2(0.556,0.200),vec2(0.489,0.193));tris(vec2(0.565,0.161),vec2(0.556,0.200),vec2(0.510,0.183));
        tris(vec2(0.640,0.073),vec2(0.556,0.200),vec2(0.565,0.161));tris(vec2(0.640,0.073),vec2(0.565,0.161),vec2(0.666,0.012));tris(vec2(0.688,0.021),vec2(0.640,0.073),vec2(0.666,0.012));tris(vec2(0.688,0.021),vec2(0.691,0.160),vec2(0.640,0.073));tris(vec2(0.758,0.026),vec2(0.700,0.182),vec2(0.691,0.160));tris(vec2(0.691,0.160),vec2(0.644,0.199),vec2(0.640,0.073));tris(vec2(0.700,0.182),vec2(0.644,0.199),vec2(0.691,0.160));tris(vec2(0.700,0.182),vec2(0.723,0.196),vec2(0.644,0.199));tris(vec2(0.723,0.196),vec2(0.719,0.202),vec2(0.644,0.199));
        
    }
    if(g_out_color.a>0.0)return;
    off= abs(uv-vec2(0.875000,0.125000)) - vec2(0.125000); if( off.x <= 0.0 || off.y <=  0.0)
    { tris(vec2(0.782,0.007),vec2(0.784,0.011),vec2(0.711,0.006));tris(vec2(0.784,0.011),vec2(0.708,0.012),vec2(0.711,0.006));tris(vec2(0.784,0.011),vec2(0.781,0.017),vec2(0.708,0.012));tris(vec2(0.781,0.017),vec2(0.714,0.018),vec2(0.708,0.012));tris(vec2(0.781,0.017),vec2(0.727,0.020),vec2(0.714,0.018));tris(vec2(0.781,0.017),vec2(0.758,0.026),vec2(0.727,0.020));tris(vec2(0.758,0.026),vec2(0.734,0.032),vec2(0.727,0.020));tris(vec2(0.758,0.026),vec2(0.691,0.160),vec2(0.734,0.032));tris(vec2(0.758,0.026),vec2(0.700,0.182),vec2(0.691,0.160));
        tris(vec2(0.998,0.006),vec2(1.000,0.010),vec2(0.923,0.007));tris(vec2(0.881,0.005),vec2(0.886,0.012),vec2(0.796,0.005));tris(vec2(0.886,0.012),vec2(0.790,0.012),vec2(0.796,0.005));tris(vec2(1.000,0.010),vec2(0.920,0.012),vec2(0.923,0.007));tris(vec2(0.886,0.012),vec2(0.793,0.016),vec2(0.790,0.012));tris(vec2(1.000,0.010),vec2(0.995,0.017),vec2(0.920,0.012));tris(vec2(0.886,0.012),vec2(0.881,0.018),vec2(0.793,0.016));tris(vec2(0.995,0.017),vec2(0.926,0.018),vec2(0.920,0.012));tris(vec2(0.995,0.017),vec2(0.986,0.019),vec2(0.926,0.018));
        tris(vec2(0.881,0.018),vec2(0.868,0.020),vec2(0.793,0.016));tris(vec2(0.986,0.019),vec2(0.939,0.021),vec2(0.926,0.018));tris(vec2(0.986,0.019),vec2(0.972,0.026),vec2(0.939,0.021));tris(vec2(0.868,0.020),vec2(0.811,0.027),vec2(0.793,0.016));tris(vec2(0.972,0.026),vec2(0.945,0.030),vec2(0.939,0.021));tris(vec2(0.868,0.020),vec2(0.861,0.035),vec2(0.811,0.027));tris(vec2(0.861,0.035),vec2(0.863,0.073),vec2(0.811,0.027));tris(vec2(0.972,0.026),vec2(0.922,0.073),vec2(0.945,0.030));tris(vec2(0.863,0.073),vec2(0.863,0.086),vec2(0.811,0.027));
        tris(vec2(0.922,0.073),vec2(0.863,0.086),vec2(0.863,0.073));tris(vec2(0.922,0.073),vec2(0.912,0.086),vec2(0.863,0.086));tris(vec2(0.972,0.026),vec2(0.912,0.086),vec2(0.922,0.073));tris(vec2(0.863,0.086),vec2(0.865,0.154),vec2(0.811,0.027));tris(vec2(0.972,0.026),vec2(0.865,0.154),vec2(0.912,0.086));tris(vec2(0.865,0.154),vec2(0.822,0.204),vec2(0.811,0.027));tris(vec2(0.972,0.026),vec2(0.844,0.205),vec2(0.865,0.154));tris(vec2(0.865,0.154),vec2(0.844,0.205),vec2(0.822,0.204));tris(vec2(0.844,0.205),vec2(0.833,0.209),vec2(0.822,0.204));
        
    }
   
}
#define PI 3.1415926536

const vec2 res = vec2(800.0,600.0);
const mat3 mRot = mat3(0.9553, -0.2955, 0.0, 0.2955, 0.9553, 0.0, 0.0, 0.0, 1.0);
const vec3 ro = vec3(0.0,0.0,-4.0);

const vec3 cRed = vec3(1.0,0.0,0.0);
const vec3 cWhite = vec3(1.0);
const vec3 cGrey = vec3(0.66);
const vec3 cPurple = vec3(0.51,0.29,0.51);

const float maxx = 0.378;

void main()
{
    vec2 q = gl_FragCoord.xy/resolution.xy;

  
   g_pen = gl_FragCoord.xy/resolution.xy;
    float asp = resolution.y/resolution.x;
    vec2 uvR = floor(g_pen*res);
    g_pen*=vec2(1.0,1.2*asp);
    g_pen.x = 0.0+(1.0-g_pen.x);
   g_pen.y=g_pen.y-0.0-(0.2*abs(sin(time)*2.8));
    g_out_color = vec4(1.0,1.0,1.0,0.0);
    
    //  if(distance(g_pen,vec2(1,1))<0.01)g_out_color =vec4(1,0,0,1.0);
    
  
   
    
    vector_text();
    
    
    vec2 uv = uvR/res + vec2(-0.466+0.2*sin(time),-0.53);
    
    vec3 rd = normalize(vec3((uv)*vec2(2.0,2.0*asp),1.0));
    
    float b = dot(rd,ro);
    float t1 = b*b-15.0;
    float t = -b-sqrt(t1);
    vec3 nor = normalize(ro+rd*t)*mRot;
    vec2 tuv = floor(vec2(atan(nor.x,nor.z)/PI+((floor((time)*60.0)/60.0)*0.5),acos(nor.y)/PI)*8.0);
    glFragColor = vec4(mix(glFragColor.rgb,mix(cRed,cWhite,clamp(mod(tuv.x+tuv.y,2.0),0.0,1.0)),1.0-step(t1,0.0)),1.0);
    glFragColor.rgb =mix(glFragColor.rgb,g_out_color.rgb,g_out_color.a);
}
