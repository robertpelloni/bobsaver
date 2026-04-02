#version 420

// original https://www.shadertoy.com/view/tlGXWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Pore Torus
// By PauloFalcao
//
// A very simple test generated in materialmaker in 1 minute
// MaterialMaker is a nodebased shader maker to make texture, but with some custom nodes, 
// created directly in the tool, it's possible to make complex stuff like raymarching :)

mat2 rot(float r){
  float s=sin(r);float c=cos(r);
  return mat2(c,-s,s,c);
}

float wave3d_constant(float x) {
    return 1.0;
}

float wave3d_sine(float x) {
    return 0.5-0.5*cos(3.14159265359*2.0*x);
}

float wave3d_triangle(float x) {
    x = fract(x);
    return min(2.0*x, 2.0-2.0*x);
}

float wave3d_sawtooth(float x) {
    return fract(x);
}

float wave3d_square(float x) {
    return (fract(x) < 0.5) ? 0.0 : 1.0;
}

float wave3d_bounce(float x) {
    x = 2.0*(fract(x)-0.5);
    return sqrt(1.0-x*x);
}

float mix3d_mul(float x, float y, float z) {
    return x*y*z;
}

float mix3d_add(float x, float y, float z) {
    return min(x+y+z, 1.0);
}

float mix3d_max(float x, float y, float z) {
    return max(max(x, y), z);
}

float mix_min(float x, float y, float z) {
    return min(min(x, y), z);
}

float mix3d_xor(float x, float y, float z) {
    float xy = min(x+y, 2.0-x-y);
    return min(xy+z, 2.0-xy-z);
}

float mix3d_pow(float x, float y, float z) {
    return pow(pow(x, y), z);
}vec4 o354278_p_SkyColor_gradient_fct(float x) {
  if (x < 0.000000000) {
    return vec4(0.793357015,0.864655972,0.979166985,1.000000000);
  } else if (x < 0.118182000) {
    return mix(mix(vec4(0.510612011,0.698400021,1.000000000,1.000000000), vec4(0.287342012,0.329521000,0.557291985,1.000000000), (x-0.118182000)/0.293416000), mix(vec4(0.793357015,0.864655972,0.979166985,1.000000000), vec4(0.510612011,0.698400021,1.000000000,1.000000000), (x-0.000000000)/0.118182000), 1.0-0.5*(x-0.000000000)/0.118182000);
  } else if (x < 0.411598000) {
    return 0.5*(mix(vec4(0.510612011,0.698400021,1.000000000,1.000000000), vec4(0.287342012,0.329521000,0.557291985,1.000000000), (x-0.118182000)/0.293416000) + mix(mix(vec4(0.793357015,0.864655972,0.979166985,1.000000000), vec4(0.510612011,0.698400021,1.000000000,1.000000000), (x-0.000000000)/0.118182000), mix(vec4(0.287342012,0.329521000,0.557291985,1.000000000), vec4(0.171140000,0.209502995,0.416667014,1.000000000), (x-0.411598000)/0.533857000), 0.5-0.5*cos(3.14159265359*(x-0.118182000)/0.293416000)));
  } else if (x < 0.945455000) {
    return mix(mix(vec4(0.510612011,0.698400021,1.000000000,1.000000000), vec4(0.287342012,0.329521000,0.557291985,1.000000000), (x-0.118182000)/0.293416000), mix(vec4(0.287342012,0.329521000,0.557291985,1.000000000), vec4(0.171140000,0.209502995,0.416667014,1.000000000), (x-0.411598000)/0.533857000), 0.5+0.5*(x-0.411598000)/0.533857000);
  }
  return vec4(0.171140000,0.209502995,0.416667014,1.000000000);
}
float o354282_input_in1(vec3 p) {
vec2 o354281_0_q = vec2(length((p).xz)-0.610000000,(p).y);
float o354281_0_1_sdf3d = length(o354281_0_q)-0.360000000;

return o354281_0_1_sdf3d;
}
vec3 normal_o354282(vec3 p) {
    float d = o354282_input_in1(p);
    vec2 e = vec2(.001,0);
    vec3 n = d - vec3(
        o354282_input_in1(p-vec3(e.xyy)),
        o354282_input_in1(p-vec3(e.yxy)),
        o354282_input_in1(p-vec3(e.yyx)));
    return normalize(n);
}

float o354283_fct(vec3 uv) {
    return mix3d_mul(wave3d_sine(8.000000000*uv.x), wave3d_sine(8.000000000*uv.y), wave3d_sine(8.000000000*uv.z));
}float o354278_input_sdf_a(vec3 p) {
vec3 o354283_0_1_color3d = vec3(o354283_fct(((p)).xyz));

vec3 n=normal_o354282((p));
float o354282_0_in = o354282_input_in1((p)+((n*(o354283_0_1_color3d-0.5))*0.134000000));float o354282_0_1_sdf3d = max(o354282_input_in1((p))-0.134000000,o354282_0_in/((0.134000000+0.2)*10.0));

return o354282_0_1_sdf3d;
}
vec4 o354284_p_g_gradient_fct(float x) {
  if (x < 0.000000000) {
    return vec4(1.000000000,0.906248987,0.000000000,1.000000000);
  } else if (x < 0.079855277) {
    return mix(mix(vec4(1.000000000,0.468750000,0.000000000,1.000000000), vec4(0.000000000,0.000000000,1.000000000,1.000000000), (x-0.079855277)/0.343188719), mix(vec4(1.000000000,0.906248987,0.000000000,1.000000000), vec4(1.000000000,0.468750000,0.000000000,1.000000000), (x-0.000000000)/0.079855277), 1.0-0.5*(x-0.000000000)/0.079855277);
  } else if (x < 0.423043997) {
    return 0.5*(mix(vec4(1.000000000,0.468750000,0.000000000,1.000000000), vec4(0.000000000,0.000000000,1.000000000,1.000000000), (x-0.079855277)/0.343188719) + mix(mix(vec4(1.000000000,0.906248987,0.000000000,1.000000000), vec4(1.000000000,0.468750000,0.000000000,1.000000000), (x-0.000000000)/0.079855277), mix(vec4(0.000000000,0.000000000,1.000000000,1.000000000), vec4(0.000000000,0.000000000,0.000000000,1.000000000), (x-0.423043997)/0.576956003), 0.5-0.5*cos(3.14159265359*(x-0.079855277)/0.343188719)));
  } else if (x < 1.000000000) {
    return mix(mix(vec4(1.000000000,0.468750000,0.000000000,1.000000000), vec4(0.000000000,0.000000000,1.000000000,1.000000000), (x-0.079855277)/0.343188719), mix(vec4(0.000000000,0.000000000,1.000000000,1.000000000), vec4(0.000000000,0.000000000,0.000000000,1.000000000), (x-0.423043997)/0.576956003), 0.5+0.5*(x-0.423043997)/0.576956003);
  }
  return vec4(0.000000000,0.000000000,0.000000000,1.000000000);
}
vec3 o354278_input_tex3d_a(vec3 p) {
p.xz*=rot(time*0.5);
vec3 o354283_0_1_color3d = vec3(o354283_fct(((p)).xyz));
vec3 o354284_0_1_color3d = o354284_p_g_gradient_fct(dot(o354283_0_1_color3d, vec3(1.0))/3.0).rgb;

return o354284_0_1_color3d;
}
float o354278_input_sdf_b(vec3 p) {

return ((p)).y+1.0;
}
vec3 o354278_input_tex3d_b(vec3 p) {

return (vec3(mod(floor(((p)).x)+floor(((p)).z),2.0))*0.25+0.5);
}
vec2 input_o354278(vec3 p) {
    p.xz*=rot(time*0.5);
    float sdfa=o354278_input_sdf_a(p);
    float sdfb=o354278_input_sdf_b(p);
    if (sdfa<sdfb) {
      return vec2(sdfa,0.0);
    } else {
      return vec2(sdfb,1.0);
    }
}

vec3 normal_o354278(vec3 p) {
    float d = input_o354278(p).x;
    vec2 e = vec2(.001,0);
    vec3 n = d - vec3(
        input_o354278(p-vec3(e.xyy)).x,
        input_o354278(p-vec3(e.yxy)).x,
        input_o354278(p-vec3(e.yyx)).x);
    return normalize(n);
}

void march_o354278(out float d,out vec3 p,out vec2 dS, vec3 ro, vec3 rd){
    for (int i=0; i < 500; i++) {
        p = ro + rd*d;
        dS = input_o354278(p);
        d += dS.x;
        if (d > 50.0 || abs(dS.x) < 0.0001) break;
    }
}

//from https://www.shadertoy.com/view/lsKcDD
float calcAO_o354278( in vec3 pos, in vec3 nor ){
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ){
        float h = 0.001 + 0.15*float(i)/4.0;
        float d = input_o354278( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.98;
    }
    return clamp( 1.0 - 1.6*occ, 0.0, 1.0 );    
}

//from https://www.shadertoy.com/view/lsKcDD
float calcSoftshadow_o354278( in vec3 ro, in vec3 rd, in float mint, in float tmax){
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    for( int i=0; i<32; i++ ){
        float h = input_o354278( ro + rd*t ).x;
        res = min( res, 10.0*h/t );
        t += h;
        if( res<0.0001 || t>tmax ) break;  
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 raymarch_o354278(vec2 uv) {
    vec3 cam=vec3(1.250000000+sin(time*0.25)*0.5,1.400000000+cos(time*0.2)*0.5,1.500000000);
    vec3 lookat=vec3(0.000000000,0.000000000,0.000000000);
    vec3 ray=normalize(lookat-cam);
    vec3 cX=normalize(cross(vec3(0.0,-1.0,0.0),ray));
    vec3 cY=normalize(cross(cX,ray));
    vec3 rd = normalize(ray*1.000000000+cX*uv.x+cY*uv.y);
    vec3 ro = cam;
    
    float d=0.;
    vec3 p=vec3(0);
    vec2 dS=vec2(0);
    march_o354278(d,p,dS,ro,rd);
    
    vec3 color=vec3(0.0);
    vec3 objColor=(dS.y<0.5)?o354278_input_tex3d_a(p):o354278_input_tex3d_b(p);
    float fog=max(1.0-(d/50.0),0.0);
    vec3 light=normalize(vec3(0.950000000,1.200000000,0.400000000));
    if (d<50.0) {
        vec3 n=normal_o354278(p);
        float l=clamp(dot(-light,-n),0.0,1.0);
        float r=clamp(dot(reflect(rd,-n),light),0.0,1.0);
        float cAO=calcAO_o354278(p,n);
        float shadow=calcSoftshadow_o354278(p,light,0.05,5.0);
        color=min(vec3(max(shadow,0.200000000)),max(l,0.200000000))*max(cAO,0.200000000)*objColor+pow(r,200.000000000)*0.850000000;
    } else {
        color=o354278_p_SkyColor_gradient_fct(rd.y).xyz;
    }
    return color*(fog)+o354278_p_SkyColor_gradient_fct(rd.y).xyz*(1.0-fog);
}

void main(void) {
vec2 UV = gl_FragCoord.xy/resolution.xy-0.5;
UV.x*=resolution.x/resolution.y;
vec4 o354278_0_d = vec4(raymarch_o354278((UV)),1.0);

vec4 o354278_0_1_rgba = o354278_0_d*1.3;
glFragColor = o354278_0_1_rgba;
}

