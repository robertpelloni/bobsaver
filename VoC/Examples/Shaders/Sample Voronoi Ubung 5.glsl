#version 420

// original https://www.shadertoy.com/view/7lG3Wd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
This Voronoi Shader is based on:

1. An article by IQ: 
    https://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm
2. tomkh's drawing helped it click: 
    https://www.shadertoy.com/view/llG3zy
3.Shane's Rounded border shader:
    https://www.shadertoy.com/view/ll3GRM
*/

#define pi acos(-1.)
#define eps 8./resolution.y

#define maxPoints 16.
#define screenSize 4.

#define bg (0.5+0.5*sin(vec3(time,time*3.+403.,time*1.3+902.)))
#define fg (0.5+0.5*sin(vec3(-time*2.1,-time*0.9+403.,-time+902.)))

vec2 rnd2(vec2 id){
    return vec2(fract(sin(dot(id,vec2(14.27,74.97)))*54329.34),
           fract(sin(dot(id+912.35,vec2(49.27,102.74)))*54329.34));
}

mat2 rot(float a){
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

float smin2(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}

float point(vec2 uv, float r){
    return smoothstep(r+eps,r-eps,length(uv));
}

float ring(vec2 uv, float r){
    return smoothstep(eps+0.03, 0., abs(length(uv)-r+0.03));
}

float line(vec2 P, vec2 A, vec2 B, float r){
    vec2 PA = P-A;
    vec2 AB = B-A;
    //dot(AB,P-P3) = 0
    //dot(AB,P-AB*t)
    float t = clamp(dot(PA,AB)/dot(AB,AB),0.,1.);
    return smoothstep(r+eps,r-eps,length(PA-AB*t));
   
}

//we are in "not world/object space" 
//because we use length on vectors from vec2(0,0.)
//to get distances
vec4 voronoi(vec2 uv){

    vec2 st = fract(uv);
    vec2 stFL = floor(uv);
    vec2 d = vec2(10.);
    vec2 A, B=vec2(100.);
    
    vec2 mind;
    
    for(float i = -1.; i <= 1.; i++){
        for(float j = -1.; j <= 1.; j++){
        
        vec2 id = vec2(i,j);
        vec2 rndShift = rnd2(stFL+id);
        vec2 coords = id + 0.5+0.35*sin(pi*2.*(rndShift)+time) - st;
        
        float c = length(coords.xy);//max(abs(coords.x),abs(coords.y));
        
        if(c < d.x){
            d.x = c;
            d.y = rnd2(stFL+id).y;
            A = coords;
            }
        }
    }
    mind = d;
    
    d = vec2(10.);
    
    for(float i = -1.; i <= 1.; i++){
        for(float j = -1.; j <= 1.; j++){
        
        vec2 id = vec2(i,j);
        vec2 rndShift = rnd2(stFL+id);
        vec2 coords = id + 0.5+0.35*sin(pi*2.*(rndShift)+time) - st;
        
        float c = length(coords.xy);//max(abs(coords.x),abs(coords.y));
        
        if(length(A-coords) > 0.00){
            //d.x = c;
            //d.y = rnd2(stFL+id).y;
            B.x = smin2(B.x, dot( 0.5*(A+coords), 
                       normalize(coords-A) ), 0.2 );
            }
        }
    }
    B.y = B.x;
    return vec4(mind,0.5+0.5*(sin(pow(B*32.,vec2(1./2.)))));
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 light = vec3(1.,0.,2.);
    vec3 ldir = normalize(vec3(0.)-light);
    
    vec3 light2 = vec3(2.,1.,1.);
    vec3 ldir2 = normalize(vec3(0.)-light2);
    
    // Time varying pixel color
    //vec3(0.1,1.4,2.)
    uv*=3.;
    vec4 voronoXY = voronoi(uv);
    //float edges = smoothstep(0.00,0.01,abs(voronoXY.x-voronoXY.z));
    vec3 col = 0.5+0.5*sin(vec3(1., 2., 3.)/1.2+ voronoXY.y*pi*200.);
    col.zy *= rot(.1);
    
   // col = mix(col, vec3(voronoXY.y,0., voronoXY.y)/4., smoothstep(0.08,0.05,voronoXY.x));
  //  col += sin(voronoXY.x*40.);
    //col += vec3(fract(voronoXY.x*8.));
    //col = mix(col, vec3(0.), smoothstep(0.14,0.13,voronoXY.z));
   //col = mix(col, vec3(1.), smoothstep(0.05,0.,voronoXY.z));
   // col -= sin(voronoXY.z*90.)/10.;
    //col = mix(col, vec3(0.), 1.-smoothstep(0.5,0.4,voronoXY.x*1.));
    col = mix(col, vec3(.9,0.6,0.0), smoothstep(0.3,.5,voronoXY.z)*0.3 );
    // Output to screen
    
    vec3 n = vec3(
                  voronoi(uv-vec2(eps,0.)).x-voronoi(uv+vec2(eps,0.)).x,
                  voronoi(uv-vec2(eps,0.).yx).x-voronoi(uv+vec2(eps,0.).yx).x,
                  voronoi(uv-vec2(eps,0.)).z
                  -voronoi(uv+vec2(eps,0.).yy).z
                  );
         n = normalize(n);//smoothstep(vec3(-1.),vec3(1.),;
         
    float diff = max(dot(ldir,n),0.);
    
    float spec = pow( max(
                 dot( reflect(-ldir,n),vec3(0.,0.,1.)),0.),5.);
    col += diff*0.6+vec3(0.9,0.5,0.1)*spec;
    
    
    
    float diff2 = max(dot(ldir,n),0.);
    
    float spec2 = pow( max(
                 dot( reflect(-ldir2,n),vec3(0.,0.,1.)),0.),5.);
    col += diff2*0.8+vec3(0.1,0.5,0.9)*spec2;
    
    col = mix(col, vec3(0.), smoothstep(0.1,0.095,voronoXY.z));
    col = mix(col, vec3(1.,0.4,0.)/2., smoothstep(0.02,0.01,voronoXY.z));
    col += smoothstep(0.05,0.03,voronoXY.z)*(0.5+0.5*sin(voronoXY.z*10.))/1.5;
    
    col /= 1.5;
    col= pow(col, vec3(1.4));
    
    glFragColor = vec4(col,1.0);
}
