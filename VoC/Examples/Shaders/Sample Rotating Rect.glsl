#version 420

// original https://www.shadertoy.com/view/wdfBWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 32.
 
vec2 rot(vec2 v, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c)*v;
}
 
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}
 
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
}
 
vec4 rect(vec2 uv, vec2 pos, vec2 dim, vec3 col){
    
    if ((uv.x>=pos.x && uv.x<=pos.x+dim.x) && (uv.y>=pos.y && uv.y<=pos.y+dim.y)) {
        return vec4(col,1.0);
    }
    return vec4(0.);
}

void main(void)
{
  vec2 p = gl_FragCoord.xy / resolution.xy - 0.5;
  p.x *= resolution.x / resolution.y;

    vec4 color=vec4(0.);
    float dx=1./N;
    float dy=1./N;
    for(float t=0.;t<=1.;t+=(1./N))
    {
        float xi=N*t*dx;
        float yi=N*t*dy;
        float ddx=1.-xi*2.0;
        float ddy=1.-yi*2.0;
        //float an=noise(vec2(t*4.,time*4.));
        //vec2 r=rot(p,an);
        vec2 r=rot(p,1.4*sin(time+t*4.));
        color+=rect(r,vec2(-0.5+xi,-0.5+yi),vec2(ddx,ddy),vec3(t));
    }
    
    
    color=sqrt(color*0.2);
    
    glFragColor = vec4( vec3( color ), 1.0 );
 
}
