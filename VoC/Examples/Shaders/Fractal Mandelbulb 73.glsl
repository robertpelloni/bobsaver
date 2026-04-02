#version 420

// original https://www.shadertoy.com/view/DdVcWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* by DarthNOdlehS */
#define DOSXPI 6.283185307 
#define NUM_ITERS 99        // number interations
#define D_MIN 0.0001        // distance min 0.0001
#define D_MAX 100.0            // distance max 100.0
#define CONTROL 1.0
#define M_EXP  12.0

float _z_pos = -2.0;

vec3 hsv_to_rgb(vec3 hsv){
    float hue_col = 6.0 * fract(hsv.x); 
    float r = -1.0 + abs(hue_col - 3.0);
    float g =  2.0 - abs(hue_col - 2.0);
    float b =  2.0 - abs(hue_col - 4.0);
    vec3 rgb = clamp(vec3(r, g, b),0.0,1.0);     //hue
    rgb = mix(vec3(1.0), rgb, hsv.y);             //saturation
    return rgb * hsv.z;                         //value
}

vec2 rotation(float argo, float prima, float secua){
    float s = sin(argo);
    float c = cos(argo);
    return vec2(prima * c + secua * s, -prima * s + secua * c);
}

float distance_to_mb( vec3 r3d ){     // BULB z ^ M
    r3d.xy = rotation(DOSXPI*sin(time*0.03),r3d.x, r3d.y);
    r3d.yz = rotation(DOSXPI*cos(time*0.03),r3d.y, r3d.z);
    float mxthe, mxphi, rexpm, sinthe, radius;
    vec3 zn = r3d;
    float df = 1.0;

    for( int i = 0; i < 10; i++ ){
        radius = length( zn );
        if( radius > 2.0 )    
            break;                
        mxthe = M_EXP*atan( length( zn.xy ), zn.z ); // M x theta
        mxphi = M_EXP*atan( zn.y, zn.x );             // M x phi
        rexpm = pow(radius,M_EXP);                     // r ^ M
        sinthe=sin(mxthe); 
        zn = rexpm * vec3(sinthe * cos(mxphi), sinthe * sin(mxphi), cos(mxthe)) + r3d;  
        df = M_EXP * pow(radius, M_EXP-1.0) * df + CONTROL; 
    }
    return 0.5 * log(radius) * radius / df;            // final distance aprox
}
vec2 ray_marching_plus(vec3 p_ini, vec3 u_raymar_dir){    
    float deep=0.0;
    float delta=0.0;
    int i;
    for(i=0; i<NUM_ITERS; i++){
        delta = distance_to_mb(p_ini + deep * u_raymar_dir);
        if ( delta < D_MIN) 
            break;         
        deep += delta;
    }
    return vec2(deep, i);  
}

void main(void) {
    vec2 uv =  (gl_FragCoord.xy-0.5*resolution.xy)/resolution.yy;  
    vec3 p_ini=vec3(0.0, 0.0, _z_pos + 0.7* sin(time*0.3));  // camera pos
    vec3 u_raymar_dir = normalize(vec3(uv.x, uv.y ,1.0));     //ray marching direction
    vec2 deepi = ray_marching_plus(p_ini, u_raymar_dir);
    vec3 pos3d = p_ini + deepi.x * u_raymar_dir;    
    vec3 col =hsv_to_rgb(vec3(0.1 - length(pos3d), 0.8, 10.0/deepi.y)); 
    glFragColor = vec4(col,1.0);
}
