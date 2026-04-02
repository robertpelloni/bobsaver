#version 420

// original https://www.shadertoy.com/view/slG3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////////////////////////////////////////////////
//              ...  Dark Energy ...                     ////
/////////////////////////////////////////////////////////////
// Brasil/Amazonas/Manaus
// Created by Rodrigo Cal (twitter: @rmmcal)
// - Published: 2021/11
// https://www.shadertoy.com/view/slG3WR
//
/////////////////////////////////////////////////////////////
//-----------------------------------------------------------

// https://www.shadertoy.com/view/4ddXW4
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*12345.54321);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    //float n = p.x + fract((p.y+.54321)*57.0) + fract((113.0+.98765)*p.z);

    float n = p.x + (p.y)*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
  
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); 
    return f;
}
//////////////////////////////////////////

vec3 hsv2rgb(float v){
    return abs(fract(v + vec3(3, 2, 1) / 3.) - .5) * 6. - 1.;
}

// by iq. http://iquilezles.org/www/articles/smin/smin.htm
float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(a, b, h) + k * h * (1.0 - h);
}

float dist(vec3 p) {
    float d = (fbm(p*1.0)-.4)*2.;
    float d2 = length(p.xy ) - .2;
    d = smax(d, -d2, 2.0);
    return d;
}
mat2 rotate(float x){
    float c = cos(x);
    float s = sin(x);
    return mat2(c,s,-s,c);
}
  
vec3 getNormal(vec3 p)
{
    vec2 d = vec2(0., 0.01);
    float x = dist(p-d.yxx);
    float y = dist(p-d.xyx);
    float z = dist(p-d.xxy);
    return normalize(vec3(x,y,z)-dist(p));
}

void main(void)
{
    vec4 c1 = vec4(0.0);//texture(iChannel0,gl_FragCoord.xy/resolution.xy);
    vec4 c = vec4(0.0);//texture(iChannel0,gl_FragCoord.xy/resolution.xy,0.4);
   
    glFragColor = vec4(c.rgb, 1.0);
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pc = (uv-.5)*vec2(1, resolution.y/resolution.x);
    float    t = 0.;
    vec3 p = vec3(0,0.,-10);
   
    p.z += time*2.1;
    vec3 ps = p;
   
    vec3 d = normalize(vec3(pc,1.0));
    vec3 cb ;
    float len = 128.0;
    float hm =  1.0;
    vec3 bloom ;
    for (int i = 0 ; i < int(len); i++)
    {
        float h =  dist(p);
        //float h2 =  dist(p+d*h);
        //h = (h + h2) /4.0;
        
        if (h <= 0.0)
          break;
        h = max(.0,h);
        hm = min(hm,h);
        bloom += (clamp(hsv2rgb(h*2.), 0.0, 1.0)*2.+.5) * hm * (length(p.xy )+1.0 );
        t+=h;
        p += d*h;
        
        cb += vec3(1)*h;
    }
    
    float k = len*6.5;
    c *= 0.0;
    
    vec3 pn = max(getNormal(p),0.0);
    
    c +=  .2 * pow(pn.z,64.0)*(sin(time*.2)*.5+.5);
   
    c -= smoothstep(82.5,.0, abs( p.z - ps.z + fract(time*.05)*900.0-750.0));
    c += vec4( log(bloom)/3.0, 1.);
    
    c = c / (cos(time)*.5+2.-c);
    c = clamp(c, 0.0, 1.0);
    c = c / (cos(time)*.5+1.5-c);
    glFragColor = c;
    
    vec3 pb = p;
    pb.xy *= rotate(atan(pb.x,pb.y)*3.0+length(pb.xy)*14.0-time*5.0);
    float intensity = noise(pb+vec3(time));
    glFragColor = glFragColor+ (intensity*.1*(1.-(cos(time)*.5+.5)));
 
}
