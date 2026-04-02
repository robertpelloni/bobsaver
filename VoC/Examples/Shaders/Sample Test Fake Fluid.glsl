#version 420

// original https://www.shadertoy.com/view/4scBDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Sph (vec3 pos, float radius){
return length(pos)-radius;
}
float cyl (vec3 pos , vec2 h){
    vec2 d = abs (vec2(length(pos.xz),pos.y))-h;
    return min(max(d.x,d.y),0.0)+length(max(d,0.));
}
float cyl2 (vec3 pos , vec2 h){
    vec2 d = abs (vec2(length(pos.xz),pos.y))-h;
    return min(max(d.x,d.y),0.0)+length(max(d,0.))-0.15;
}
float plane (vec3 pos , vec4 n){
    return dot(pos,n.xyz)+n.w;}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
vec3 rep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}
vec4 map (vec3 pos){
vec4 scene = vec4(1.);
float s1 = Sph(pos,2.);
float s1bis = Sph(pos,2.15);
float s2 = cyl(pos+vec3(0.,-3.8,0.),vec2(2.,2.));
    float s2bis = cyl2(pos+vec3(0.,-3.8,0.),vec2(2,2));
float s3 = min(s1,s2);
    float s3bis = smin(s1bis,s2bis,0.5);
    float reg = smoothstep(0.75,0.6,fract(time*0.2));
 float s4 = distance(pos.y,mix(-10.,10.,fract(time*0.2)))-3.
     +(sin(pos.x*5.)+sin(pos.z*5.));   
    float s6 = length(pos.xz-vec2(0.))-2.;
    float s8 = distance(pos.xz,vec2(0.))-0.5;
    float s9 = smin (s3bis,s8,1.);
    float s7 = max (s4,s9);
    float s5 = min (s3,s7);
    float sepa = mix(0.,1.,smoothstep(0.,0.1,s2));
    float sepa2 = mix(0.,1.,smoothstep(0.,0.1,s7));
 scene = vec4(vec3(length(pos.xz)*0.5,sepa,sepa2),s5);
 
return scene;
}
vec3 getN (vec3 pos) {
    float e = 0.01;
    return normalize(vec3(map(pos+vec3(e,0,0)).w-map(pos-vec3(e,0,0)).w,
                          map(pos+vec3(0,e,0)).w-map(pos-vec3(0,e,0)).w,
                          map(pos+vec3(0,0,e)).w-map(pos-vec3(0,0,e)).w));}
float getShadow (vec3 pos, vec3 at, float k) {
    vec3 dir = normalize(at - pos);
    float maxt = length(at - pos);
    float f = 1.;
    float t =.001*1000.;
    for (float i = 0.; i <= 1.; i += 1./64.) {
        float dist = map(pos + dir * t).w;
        if (dist < .001) return 0.;
        f = min(f, k * dist / t);
        t += dist;
        if (t >= maxt) break;
    }
    return f;
}
float overlay(float base, float blend) {
    return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}
vec3 overlay(vec3 base, vec3 blend) {
    return vec3(overlay(base.r,blend.r),overlay(base.g,blend.g),overlay(base.b,blend.b));
}

void main(void)
{
     vec2 uv =1.-2.* gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    vec3 eye = vec3(0.,0.,-4.);
    vec3 ray = normalize(vec3(uv,1.));   
    vec3 pos = eye;
    float shade = 0.;
    for (int i=0; i<64;++i){
    float dist = map(pos).w;
    if(dist<0.001){
    shade = 1.-float(i)/64.;
    break;
    }
    pos += ray*dist;
    }
    vec3 lipos = vec3(-3.,-1.,-5.);
    vec3 lidir = normalize(lipos-pos);
    vec3 nor = getN(pos);
     float shadow =getShadow(pos, lipos, 64.)*clamp(dot(lidir,nor),0.,1.);
   float test =clamp( map(pos).w,0.,1.);
    float fres = 1.-clamp(-dot(nor,vec3(0.,0.,1.)),0.,1.);
float test2 =smoothstep(0.,1.,mix(map(pos).x,mix(map(pos).x,1.,step(0.,-nor.y)),
                                   map(pos).y));
    vec3 col1 = mix(clamp(mix(vec3(0.5,0.5,0.59),vec3(1.),(shadow*0.8)*test2)+
              (fres*0.4)-(clamp(-nor.y,0.,1.))*0.2*(1.-map(pos).y),0.,1.),
        mix(vec3(1.),vec3(0.5,0.5,0.59),distance(vec2(0.),uv*0.5)),test)
        *clamp(test2+vec3(0.42,0.42,0.45),0.,1.);
    vec3 col2 = (col1-0.5)*0.5+0.5+0.25; 
    float spec = pow(clamp(dot(nor,vec3(0.,0.,-1.)),0.,1.),200.);
    vec3 col3 = clamp(mix(vec3(1.,0.,1.),vec3(1.,0.5,1.),shadow)+fres*clamp
                      (-uv.y*2.+1.,0.,1.)+spec*0.5,0.,1.);
    vec3 col4 = mix (col3,col2,map(pos).z);
        vec2 uv2 = uv*nor.xy*3. ;
    float col5 =clamp(smoothstep(1.5,0.5,distance(vec2(0.),uv2))+0.3,0.,1.)*
        clamp(smoothstep(0.8,0.2,distance(vec2(0.),uv2))+0.5,0.,1.)*
        clamp(smoothstep(0.4,0.,distance(vec2(0.),uv2))+0.9,0.,1.); 
    vec3 col6 = overlay(col4,vec3(mix(mix(1.-col5,0.5,0.8),0.5,map(pos).z)));
   
    glFragColor = vec4(col6,1.);
    
}
