#version 420

// original https://www.shadertoy.com/view/ttySWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Generated using MaterialMaker
https://rodzilla.itch.io/material-maker
+ custom nodes (inc Raymarching) by PauloFalcão
(see https://twitter.com/paulofalcao/status/1235913934516912135?s=20)

Manual additions to generated shader code for aspect ratio + animation
*/

float rand(vec2 x) {
    return fract(cos(dot(x, vec2(13.9898, 8.141))) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(vec2(dot(x, vec2(13.9898, 8.141)),
                          dot(x, vec2(3.4562, 17.398)))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(vec3(dot(x, vec2(13.9898, 8.141)),
                          dot(x, vec2(3.4562, 17.398)),
                          dot(x, vec2(13.254, 5.867)))) * 43758.5453);
}

// From http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
    vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rotate3d(vec3 p, vec3 a) {
    vec3 rv;
    float c;
    float s;
    c = cos(a.x);
    s = sin(a.x);
    rv.x = p.x;
    rv.y = p.y*c+p.z*s;
    rv.z = -p.y*s+p.z*c;
    c = cos(a.y);
    s = sin(a.y);
    p.x = rv.x*c+rv.z*s;
    p.y = rv.y;
    p.z = -rv.x*s+rv.z*c;
    c = cos(a.z);
    s = sin(a.z);
    rv.x = p.x*c+p.y*s;
    rv.y = -p.x*s+p.y*c;
    rv.z = p.z;
    return rv;
}
vec2 sdf3dc_union(vec2 a, vec2 b) {
    return vec2(min(a.x, b.x), mix(b.y, a.y, step(a.x, b.x)));
}
vec2 sdf3dc_sub(vec2 a, vec2 b) {
    return vec2(max(-a.x, b.x), a.y);
}
vec2 sdf3dc_inter(vec2 a, vec2 b) {
    return vec2(max(a.x, b.x), mix(a.y, b.y, step(a.x, b.x)));
}
vec4 o5489_p_SkyColor_gradient_fct(float x) {
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
float o5489_input_sdf_a(vec3 p) {
float r = 360.*time;
float o403273_0_1_sdf3d = length(((p)))-0.250000000;
vec2 o19319_0_q = vec2(length((rotate3d(((p)), -vec3(r, 39.000000000, 9.000000000)*0.01745329251)).xy)-0.450000000,(rotate3d(((p)), -vec3(r, 39.000000000, 9.000000000)*0.01745329251)).z);
float o19319_0_1_sdf3d = length(o19319_0_q)-0.030000000;
vec2 o176921_0_1_sdf3dc = vec2(o19319_0_1_sdf3d, 0.0);
vec2 o964145_0_1_sdf3dc = sdf3dc_union(vec2(o403273_0_1_sdf3d, 0.0), o176921_0_1_sdf3dc);

return (o964145_0_1_sdf3dc).x;
}
vec4 o278313_p_gradient_gradient_fct(float x) {
  if (x < 0.000000000) {
    return vec4(1.000000000,0.000000000,0.000000000,1.000000000);
  } else if (x < 0.254545000) {
    return mix(vec4(1.000000000,0.000000000,0.000000000,1.000000000), vec4(1.000000000,0.968750000,0.000000000,1.000000000), ((x-0.000000000)/0.254545000));
  } else if (x < 0.527273000) {
    return mix(vec4(1.000000000,0.968750000,0.000000000,1.000000000), vec4(0.000000000,1.000000000,0.125000000,1.000000000), ((x-0.254545000)/0.272728000));
  } else if (x < 0.772727000) {
    return mix(vec4(0.000000000,1.000000000,0.125000000,1.000000000), vec4(0.000000000,0.062500000,1.000000000,1.000000000), ((x-0.527273000)/0.245454000));
  } else if (x < 1.000000000) {
    return mix(vec4(0.000000000,0.062500000,1.000000000,1.000000000), vec4(0.843750000,0.000000000,1.000000000,1.000000000), ((x-0.772727000)/0.227273000));
  }
  return vec4(0.843750000,0.000000000,1.000000000,1.000000000);
}
vec3 o5489_input_tex3d_a(vec3 p) {
vec4 o278313_0_0_rgba = o278313_p_gradient_gradient_fct(((((p).xy+vec2(0.5)))).x);
vec3 o279673_0_1_tex3d = ((o278313_0_0_rgba).rgb);

return (o279673_0_1_tex3d).xyz;
}
float o5489_input_sdf_b(vec3 p) {

return ((p)).y+1.0;
}
vec3 o5489_input_tex3d_b(vec3 p) {

return (vec3(mod(floor(((p)).x)+floor(((p)).z),2.0))*0.25+0.5);
}
vec2 input_o5489(vec3 p) {
    float sdfa=o5489_input_sdf_a(p);
    float sdfb=o5489_input_sdf_b(p);
    if (sdfa<sdfb) {
      return vec2(sdfa,0.0);
    } else {
      return vec2(sdfb,1.0);
    }
}

vec3 normal_o5489(vec3 p) {
    float d = input_o5489(p).x;
    vec2 e = vec2(.001,0);
    vec3 n = d - vec3(
        input_o5489(p-vec3(e.xyy)).x,
        input_o5489(p-vec3(e.yxy)).x,
        input_o5489(p-vec3(e.yyx)).x);
    return normalize(n);
}

void march_o5489(out float d,out vec3 p,out vec2 dS, vec3 ro, vec3 rd){
    for (int i=0; i < 500; i++) {
        p = ro + rd*d;
        dS = input_o5489(p);
        d += dS.x;
        if (d > 50.0 || abs(dS.x) < 0.0001) break;
    }
}

//from https://www.shadertoy.com/view/lsKcDD
float calcAO_o5489( in vec3 pos, in vec3 nor ){
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ){
        float h = 0.001 + 0.15*float(i)/4.0;
        float d = input_o5489( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.98;
    }
    return clamp( 1.0 - 1.6*occ, 0.0, 1.0 );    
}

//from https://www.shadertoy.com/view/lsKcDD
float calcSoftshadow_o5489( in vec3 ro, in vec3 rd, in float mint, in float tmax){
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    for( int i=0; i<32; i++ ){
        float h = input_o5489( ro + rd*t ).x;
        res = min( res, 10.0*h/t );
        t += h;
        if( res<0.0001 || t>tmax ) break;  
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 raymarch_o5489(vec2 uv) {
    uv-=0.5;
    vec3 cam=vec3(sin(time)*1.200000000,0.700000000+sin(time*.3),cos(time)*1.800000000);
    vec3 lookat=vec3(0.000000000,0.000000000,0.000000000);
    vec3 ray=normalize(lookat-cam);
    vec3 cX=normalize(cross(vec3(0.0,1.0,0.0),ray));
    vec3 cY=normalize(cross(cX,ray));
    vec3 rd = normalize(ray*1.300000000+cX*uv.x+cY*uv.y);
    vec3 ro = cam;
    
    float d=0.;
    vec3 p=vec3(0);
    vec2 dS=vec2(0);
    march_o5489(d,p,dS,ro,rd);
    
    vec3 color=vec3(0.0);
    vec3 objColor=(dS.y<0.5)?o5489_input_tex3d_a(p):o5489_input_tex3d_b(p);
    float fog=max(1.0-(d/50.0),0.0);
    vec3 light=normalize(vec3(0.950000000,1.200000000,0.450000000));
    if (d<50.0) {
        vec3 n=normal_o5489(p);
        float l=clamp(dot(-light,-n),0.0,1.0);
        float r=clamp(dot(reflect(rd,-n),light),0.0,1.0);
        float cAO=calcAO_o5489(p,n);
        float shadow=calcSoftshadow_o5489(p,light,0.05,5.0);
        color=min(vec3(max(shadow,0.360000000)),max(l,0.360000000))*max(cAO,0.360000000)*objColor+pow(r,200.000000000)*0.850000000;
    } else {
        color=o5489_p_SkyColor_gradient_fct(rd.y).xyz;
    }
    return color*(fog)+o5489_p_SkyColor_gradient_fct(rd.y).xyz*(1.0-fog);
}

void main(void) {
vec2 UV = gl_FragCoord.xy/min(resolution.x,resolution.y);
UV -= .5*(resolution.xy/min(resolution.x,resolution.y)-1.);
UV.y = 1.0-UV.y;
vec4 o5489_0_d = vec4(raymarch_o5489((UV)),1.0);

vec4 o5489_0_1_rgba = o5489_0_d*1.3;
glFragColor = o5489_0_1_rgba;
}
