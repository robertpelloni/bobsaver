#version 420

// original https://www.shadertoy.com/view/3d3cDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// volume noise test

vec3 erot(vec3 p, vec3 ax, float ro)
{
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float WaveletNoise(vec3 p, float z, float k) {
    // https://www.shadertoy.com/view/wsBfzK
    float d=0.,s=1.,m=0., a;
    for(float i=0.; i<3.; i++) {
        vec3 q = p*s, g=fract(floor(q)*vec3(123.34,233.53,314.15));
        g += dot(g, g+23.234);
        a = fract(g.x*g.y)*1e3 +z*(mod(g.x+g.y, 2.)-1.); // add vorticity
        q = (fract(q)-.5);
        q = erot(q, normalize(tan(g+.1)), a);
        d += sin(q.x*10.+z)*smoothstep(.25, .0, dot(q,q))/s;
        p = erot(p,normalize(vec3(-1,1,0)),atan(sqrt(2.)))+i; //rotate along the magic angle
        m += 1./s;
        s *= k; 
    }
    return d/m;
}

#define brightness -7.7
#define saturation 0.9

void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
    uv.y*=resolution.y/resolution.x;
    vec3 dir=vec3(uv*0.8,2.);
    float time=time*0.04;

    //rotation
    vec2  mm = mouse*resolution.xy.xy/resolution.xy;
    float a1=0.5+(mm.x*0.5);
    float a2=0.8+(mm.y*0.5);
    
    mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
    mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
    dir.xz*=rot1;
    dir.xy*=rot2;
    vec3 from=vec3(1.,.5,.75);
    from+=vec3(time*1.8,time,-5.);
    from.xz*=rot1;
    from.xy*=rot2;
    
    // volumetric
    float s=0.1;
    float fade=1.;
    vec3 v=vec3(0.);
    for (int r=0; r<50; r++)
    {
        vec3 p=from+s*dir*.5;
        vec3 p2 = p*4.0;
        float a = WaveletNoise(p2, 0.0, 1.9)*2.0 - 1.0;
        a *= a * a;
        v += vec3(s, s*s, s*s*s*s)* a * brightness * fade;
        fade *= 0.925;
        s += 0.032;
    }
    v=mix(vec3(length(v)),v,saturation);
    glFragColor = vec4(v.gbr*.01,1.);    
    
}
