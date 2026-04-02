#version 420

// original https://www.shadertoy.com/view/NdSyRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* src:
https://inspirnathan.com/posts/52-shadertoy-tutorial-part-6
Dodecahedron vertices: https://www.wolframalpha.com/input/?i=PolyhedronData%5B%22Dodecahedron%22%2C+%22VertexCoordinates%22%5D
courses of Maxime MARIA, my image synthesis professor, teaching in the Limoges University
*/
const float PI = 3.141592;

const float RAYMIN = 0.0;
const float RAYMAX = 100.0;
const int RAYSTEP = 255;
const float PREC_RAY = 0.001; //precision of the ray

const vec3 BACK_COLOR = vec3(0.6);
const vec3 LIGHT_POS = vec3(5., 2., 4.);
const float GI_SIM = 0.5; //global illumination simulation (between 0. and 1.)

const vec3 CENTER_ATOM = vec3(0., 0., -6.);
const vec3 COLOR_NEUTRON = vec3(0., 0., 0.7);
const vec3 COLOR_PROTON = vec3(0.7, 0., 0.);
const vec3 COLOR_ELECTRON = vec3(0., 0.7, 0.7);

/*return mat4 translation according to the vec3 vt*/
mat4 getMatT(vec3 vt){
    return mat4( vec4(1., 0., 0., 0.),
                 vec4(0., 1., 0., 0.),
                 vec4(0., 0., 1., 0.),
                 vec4(vt.x, vt.y, vt.z, 1.));
}

/*return mat4 scaling (homothetic) according to the vec3 vs*/
mat4 getMatS(vec3 vs){
    return mat4( vec4(vs.x, 0.,    0.,   0.),
                 vec4(0.,   vs.y,  0.,   0.),
                 vec4(0.,   0.,    vs.z, 0.),
                 vec4(0.,   0.,    0.,   1.));
}

mat4 getMatRotX(float a){
    return mat4( vec4(1., 0.,      0.,       0.),
                 vec4(0., cos(a),  sin(a),   0.),
                 vec4(0., -sin(a), cos(a),   0.),
                 vec4(0., 0.,      0.,       1.));
}

mat4 getMatRotY(float a){
    return mat4( vec4(cos(a),  0., sin(a), 0.),
                 vec4(0.,      1., 0.,     0.),
                 vec4(-sin(a), 0., cos(a), 0.),
                 vec4(0.,      0., 0.,     1.));
}

mat4 getMatRotZ(float a){
    return mat4( vec4(cos(a), sin(a),  0., 0.),
                 vec4(-sin(a), cos(a), 0., 0.),
                 vec4(0.,      0.,     1., 0.),
                 vec4(0.,      0.,     0., 1.));
}

vec4 dist_sphere(vec3 p, vec3 center, float r, vec3 color){
    return vec4(length(p - center) - r, color);
}

vec4 sdScene(vec3 p){
    //proton and neutron (core)
    float gap = 0.35;
    float size = 0.3;
    
    //center
    vec3 cp0 = (getMatT(CENTER_ATOM) * vec4(0., 0., 0., 1.)).xyz;
    
    //neutron
    float sa = PI/2.; //start angle
    mat4 Mtransform = getMatRotY(-time) * getMatRotX(time/2.) * getMatS(vec3(gap));
    
    /*creation of the center of the neutron and proton following a regular dodecahedron shape (see src below)*/
    vec3 cp1  = (Mtransform * vec4( -sqrt(0.2*(5.+2.*sqrt(5.))),        0.,                  0.5*sqrt(0.1*(5.-sqrt(5.))),        1.)).xyz + CENTER_ATOM;
    vec3 cp2  = (Mtransform * vec4( sqrt(0.2*(5.+2.*sqrt(5.))),         0.,                  -0.5*sqrt(0.1*(5.-sqrt(5.))),       1.)).xyz + CENTER_ATOM;
    vec3 cp3  = (Mtransform * vec4( -0.5*sqrt(0.1*(5.+sqrt(5.))),       0.25*(-3.-sqrt(5.)), 0.5*sqrt(0.1*(5.-sqrt(5.))),        1.)).xyz + CENTER_ATOM;
    vec3 cp4  = (Mtransform * vec4( -0.5*sqrt(0.1*(5.+sqrt(5.))),       0.25*(3.+sqrt(5.)),  0.5*sqrt(0.1*(5.-sqrt(5.))),        1.)).xyz + CENTER_ATOM;
    vec3 cp5  = (Mtransform * vec4( sqrt((5./8.)+(11./(8.*sqrt(5.)))),  0.25*(-1.-sqrt(5.)), 0.5*sqrt(0.1*(5.-sqrt(5.))),        1.)).xyz + CENTER_ATOM;
    vec3 cp6  = (Mtransform * vec4( sqrt((5./8.)+(11./(8.*sqrt(5.)))),  0.25*(1.+sqrt(5.)),  0.5*sqrt(0.1*(5.-sqrt(5.))),        1.)).xyz + CENTER_ATOM;
    vec3 cp7  = (Mtransform * vec4( -0.5*sqrt(0.1*(5.-sqrt(5.))),       0.25*(-1.-sqrt(5.)), sqrt((5./8.)+(11./(8.*sqrt(5.)))),  1.)).xyz + CENTER_ATOM;
    vec3 cp8  = (Mtransform * vec4( -0.5*sqrt(0.1*(5.-sqrt(5.))),       0.25*(1.+sqrt(5.)),  sqrt((5./8.)+(11./(8.*sqrt(5.)))),  1.)).xyz + CENTER_ATOM;
    vec3 cp9  = (Mtransform * vec4( -sqrt(0.25+(1./(2.*sqrt(5.)))),     -0.5,                -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 1.)).xyz + CENTER_ATOM;
    vec3 cp10 = (Mtransform * vec4( -sqrt(0.25+(1./(2.*sqrt(5.)))),     0.5,                 -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 1.)).xyz + CENTER_ATOM;
    vec3 cp11 = (Mtransform * vec4( sqrt(0.25+(1./(2.*sqrt(5.)))),      -0.5,                sqrt((5./8.)+(11./(8.*sqrt(5.)))),  1.)).xyz + CENTER_ATOM;
    vec3 cp12 = (Mtransform * vec4( sqrt(0.25+(1./(2.*sqrt(5.)))),      0.5,                 sqrt((5./8.)+(11./(8.*sqrt(5.)))),  1.)).xyz + CENTER_ATOM;
    vec3 cp13 = (Mtransform * vec4( sqrt(0.1*(5.+sqrt(5.))),            0.,                  -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 1.)).xyz + CENTER_ATOM;
    vec3 cp14 = (Mtransform * vec4( -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 0.25*(-1.-sqrt(5.)), -0.5*sqrt(0.1*(5.-sqrt(5.))),       1.)).xyz + CENTER_ATOM;
    vec3 cp15 = (Mtransform * vec4( -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 0.25*(1.+sqrt(5.)),  -0.5*sqrt(0.1*(5.-sqrt(5.))),       1.)).xyz + CENTER_ATOM;
    vec3 cp16 = (Mtransform * vec4( -sqrt(0.1*(5.+sqrt(5.))),           0.,                  sqrt((5./8.)+(11./(8.*sqrt(5.)))),  1.)).xyz + CENTER_ATOM;
    vec3 cp17 = (Mtransform * vec4( 0.5*sqrt(0.1*(5.-sqrt(5.))),        0.25*(-1.-sqrt(5.)), -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 1.)).xyz + CENTER_ATOM;
    vec3 cp18 = (Mtransform * vec4( 0.5*sqrt(0.1*(5.-sqrt(5.))),        0.25*(1.+sqrt(5.)),  -sqrt((5./8.)+(11./(8.*sqrt(5.)))), 1.)).xyz + CENTER_ATOM;
    vec3 cp19 = (Mtransform * vec4( 0.5*sqrt(0.1*(5.+sqrt(5.))),        0.25*(-3.-sqrt(5.)), -0.5*sqrt(0.1*(5.-sqrt(5.))),       1.)).xyz + CENTER_ATOM;
    vec3 cp20 = (Mtransform * vec4( 0.5*sqrt(0.1*(5.+sqrt(5.))),        0.25*(3.+sqrt(5.)),  -0.5*sqrt(0.1*(5.-sqrt(5.))),       1.)).xyz + CENTER_ATOM;
    
    
    //compute intersection of neutron
    //vec4 p0 = dist_sphere(p, cp0, size, color_neutron);
    //vec4 p0 = dist_sphere(p, cp0, 0.05, vec3(1., 1., 0.));
    vec4 p1 = dist_sphere(p, cp1, size, COLOR_PROTON);
    vec4 p2 = dist_sphere(p, cp2, size, COLOR_PROTON);
    vec4 p3 = dist_sphere(p, cp3, size, COLOR_PROTON);
    vec4 p4 = dist_sphere(p, cp4, size, COLOR_PROTON);
    vec4 p5 = dist_sphere(p, cp5, size, COLOR_PROTON);
    vec4 p6 = dist_sphere(p, cp6, size, COLOR_PROTON);
    vec4 p7 = dist_sphere(p, cp7, size, COLOR_PROTON);
    vec4 p8 = dist_sphere(p, cp8, size, COLOR_PROTON);
    vec4 p9 = dist_sphere(p, cp9, size, COLOR_PROTON);
    vec4 p10 = dist_sphere(p, cp10, size, COLOR_PROTON);
    vec4 p11 = dist_sphere(p, cp11, size, COLOR_NEUTRON);
    vec4 p12 = dist_sphere(p, cp12, size, COLOR_NEUTRON);
    vec4 p13 = dist_sphere(p, cp13, size, COLOR_NEUTRON);
    vec4 p14 = dist_sphere(p, cp14, size, COLOR_NEUTRON);
    vec4 p15 = dist_sphere(p, cp15, size, COLOR_NEUTRON);
    vec4 p16 = dist_sphere(p, cp16, size, COLOR_NEUTRON);
    vec4 p17 = dist_sphere(p, cp17, size, COLOR_NEUTRON);
    vec4 p18 = dist_sphere(p, cp18, size, COLOR_NEUTRON);
    vec4 p19 = dist_sphere(p, cp19, size, COLOR_NEUTRON);
    vec4 p20 = dist_sphere(p, cp20, size, COLOR_NEUTRON);
    
    
    //electrons
    float e_s1 = 8.; //electron speed layer 1
    float e_s2 = 4.; //electron speed layer 2
    float e_rl1 = 1.5; //electron radius to the center of layer 1
    float e_rl2 = 4.; //electron radius to the center of layer 2
    mat4 Mtransform_elayer1 = getMatRotY(time) * getMatS(vec3(e_rl1));
    mat4 Mtransform_elayer2 = getMatRotY(time) * getMatS(vec3(e_rl2));
    
    //layer 2
    float o1 = PI/8.; //orientation to the Y axis
    float shift1 = 0.;
    vec3 ce1 = (Mtransform_elayer2 * vec4(cos(time*e_s2+shift1),    sin(time*e_s2+shift1)*cos(o1),    sin(time*e_s2+shift1)*sin(o1), 1.)).xyz    + CENTER_ATOM;
    vec3 ce2 = (Mtransform_elayer2 * vec4(cos(time*e_s2+PI+shift1), sin(time*e_s2+PI+shift1)*cos(o1), sin(time*e_s2+PI+shift1)*sin(o1), 1.)).xyz + CENTER_ATOM;
    
    float o2 = o1 + PI/4.;
    float shift2 = o2;
    vec3 ce3 = (Mtransform_elayer2 * vec4(cos(time*e_s2+shift2),    sin(time*e_s2+shift2)*cos(o2),    sin(time*e_s2+shift2)*sin(o2), 1.)).xyz    + CENTER_ATOM;
    vec3 ce4 = (Mtransform_elayer2 * vec4(cos(time*e_s2+PI+shift2), sin(time*e_s2+PI+shift2)*cos(o2), sin(time*e_s2+PI+shift2)*sin(o2), 1.)).xyz + CENTER_ATOM;
    
    float o3 = o2 + PI/4.;
    float shift3 = o3;
    vec3 ce5 = (Mtransform_elayer2 * vec4(cos(time*e_s2+shift3),    sin(time*e_s2+shift3)*cos(o3),    sin(time*e_s2+shift3)*sin(o3), 1.)).xyz    + CENTER_ATOM;
    vec3 ce6 = (Mtransform_elayer2 * vec4(cos(time*e_s2+PI+shift3), sin(time*e_s2+PI+shift3)*cos(o3), sin(time*e_s2+PI+shift3)*sin(o3), 1.)).xyz + CENTER_ATOM;
    
    float o4 = o3 + PI/4.;
    float shift4 = o4;
    vec3 ce7 = (Mtransform_elayer2 * vec4(cos(time*e_s2+shift4),    sin(time*e_s2+shift4)*cos(o4),    sin(time*e_s2+shift4)*sin(o4), 1.)).xyz    + CENTER_ATOM;
    vec3 ce8 = (Mtransform_elayer2 * vec4(cos(time*e_s2+PI+shift4), sin(time*e_s2+PI+shift4)*cos(o4), sin(time*e_s2+PI+shift4)*sin(o4), 1.)).xyz + CENTER_ATOM;
    
    //layer 1
    float o5 = PI/6.;
    float shift5 = 0.;
    vec3 ce9 = (Mtransform_elayer1 * vec4(cos(time*e_s1+shift5),    sin(time*e_s1+shift5)*cos(o5),    sin(time*e_s1+shift5)*sin(o5), 1.)).xyz    + CENTER_ATOM;
    vec3 ce10 = (Mtransform_elayer1 * vec4(cos(time*e_s1+PI+shift5),sin(time*e_s1+PI+shift5)*cos(o5), sin(time*e_s1+PI+shift5)*sin(o5), 1.)).xyz + CENTER_ATOM;

    vec4 e1 = dist_sphere(p, ce1, 0.1, COLOR_ELECTRON);
    vec4 e2 = dist_sphere(p, ce2, 0.1, COLOR_ELECTRON);
    vec4 e3 = dist_sphere(p, ce3, 0.1, COLOR_ELECTRON);
    vec4 e4 = dist_sphere(p, ce4, 0.1, COLOR_ELECTRON);
    vec4 e5 = dist_sphere(p, ce5, 0.1, COLOR_ELECTRON);
    vec4 e6 = dist_sphere(p, ce6, 0.1, COLOR_ELECTRON);
    vec4 e7 = dist_sphere(p, ce7, 0.1, COLOR_ELECTRON);
    vec4 e8 = dist_sphere(p, ce8, 0.1, COLOR_ELECTRON);
    vec4 e9 = dist_sphere(p, ce9, 0.1, COLOR_ELECTRON);
    vec4 e10 = dist_sphere(p, ce10, 0.1, COLOR_ELECTRON);
    
    
    /*keep only le nearest element*/
    vec4 dc_final;
    dc_final = p1.x < p2.x ? p1 : p2;
    //dc_final = p0.x < dc_final.x ? p0 : dc_final;
    dc_final = p3.x < dc_final.x ? p3 : dc_final;
    dc_final = p4.x < dc_final.x ? p4 : dc_final;
    dc_final = p5.x < dc_final.x ? p5 : dc_final;
    dc_final = p6.x < dc_final.x ? p6 : dc_final;
    dc_final = p7.x < dc_final.x ? p7 : dc_final;
    dc_final = p8.x < dc_final.x ? p8 : dc_final;
    dc_final = p9.x < dc_final.x ? p9 : dc_final;
    dc_final = p10.x < dc_final.x ? p10 : dc_final;
    dc_final = p11.x < dc_final.x ? p11 : dc_final;
    dc_final = p12.x < dc_final.x ? p12 : dc_final;
    dc_final = p13.x < dc_final.x ? p13 : dc_final;
    dc_final = p14.x < dc_final.x ? p14 : dc_final;
    dc_final = p15.x < dc_final.x ? p15 : dc_final;
    dc_final = p16.x < dc_final.x ? p16 : dc_final;
    dc_final = p17.x < dc_final.x ? p17 : dc_final;
    dc_final = p18.x < dc_final.x ? p18 : dc_final;
    dc_final = p19.x < dc_final.x ? p19 : dc_final;
    dc_final = p20.x < dc_final.x ? p20 : dc_final;
    
    dc_final = e1.x < dc_final.x ? e1 : dc_final;
    dc_final = e2.x < dc_final.x ? e2 : dc_final;
    dc_final = e3.x < dc_final.x ? e3 : dc_final;
    dc_final = e4.x < dc_final.x ? e4 : dc_final;
    dc_final = e5.x < dc_final.x ? e5 : dc_final;
    dc_final = e6.x < dc_final.x ? e6 : dc_final;
    dc_final = e7.x < dc_final.x ? e7 : dc_final;
    dc_final = e8.x < dc_final.x ? e8 : dc_final;
    dc_final = e9.x < dc_final.x ? e9 : dc_final;
    dc_final = e10.x < dc_final.x ? e10 : dc_final;
    
    
    return dc_final;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
      e.xyy * sdScene(p + e.xyy).x +
      e.yyx * sdScene(p + e.yyx).x +
      e.yxy * sdScene(p + e.yxy).x +
      e.xxx * sdScene(p + e.xxx).x);
}

/*  ro: ray origin 
    rd: ray direction (normalized)*/
vec4 ray(vec3 ro, vec3 rd){
    vec3 p;
    float depth = RAYMIN;
    
    for(int i=0; i<RAYSTEP; i++){
        p = ro + depth*rd;
        vec4 vtmp = sdScene(p);
        float dist = vtmp.x;
        depth += dist;
        if(dist < PREC_RAY || depth > RAYMAX) return vec4(depth, vtmp.yzw);
    }
    return vec4(depth, BACK_COLOR);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    uv.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0., 0., 3.);
    vec3 rd = normalize(vec3(uv.x, uv.y, -1));
    vec4 vtmp = ray(ro, rd);
    float dist = vtmp.x;

    vec3 color_final = BACK_COLOR;
    if(dist < RAYMAX){
        vec3 difuse_color = vtmp.yzw;
        vec3 pi = ro + dist*rd;
        vec3 pi_normal = calcNormal(pi);
        
        vec3 lightdir = normalize(LIGHT_POS - pi);
        
        vec3 ambient_color = difuse_color*GI_SIM;
        vec3 difuse_lighting = clamp(dot(pi_normal, lightdir), 0., 1.) * difuse_color;
        
        float specular_dot = clamp(dot(reflect(lightdir, pi_normal), rd), 0., 1.);
        vec3 specular_lighting = pow(specular_dot, 10.) * vec3(1.);
        
        color_final = ambient_color + difuse_lighting + specular_lighting;
    }
    
    glFragColor = vec4(color_final, 1.);
}
