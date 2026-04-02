#version 420

// original https://www.shadertoy.com/view/4ltGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANTIALIAS

float DE(vec3 p0){
    vec2 p = vec2(length(p0.xz), -p0.y);
    float a = .5;
    // 2-dimentional DE for hyperbola y=a/x
    float d = sqrt((p.x+p.y)*(p.x+p.y)-4.*(p.x*p.y-a))+.5;
    return (-p.x-p.y+d)/2.;
}

float softmod(float x, float w){
    x = mod(x, 2.);
#ifdef ANTIALIAS
    w /= resolution.y;
    return smoothstep(.5-w,.5+w,x)*(1.-smoothstep(1.5-w,1.5+w,x));
#else
    return floor(x);
#endif
}

void main(void)
{
    // Camera.
    float fov = 1.8, // it's not really FOV
          an = -.7 /*+ (mouse*resolution.xy.y / resolution.y - .5) * 3.*/;
    vec2 R = resolution.xy;
    vec2 U = gl_FragCoord.xy;
    U = (U - R/2.) / R.y;
    vec3 p = vec3(0., -.7/* + (mouse*resolution.xy.x / resolution.x - .5) * 6.*/, -1.),
         d = vec3(U * fov, 1.),
         p0 = p;
    d.yz *= mat2(cos(an),sin(an),
                -sin(an),cos(an));
    
    for (int i = 0; i < 64; ++i) p += d * DE(p);
    
    
    float fh = 3.5, // fog options.
          fs = 1.,
          f0 = 1.,
          gr = .9, // background color
          l = length(p.xz) /*- 1e5 + time*/, // uncomment for cool animation
          s = length(p-p0);
    
    float c1 = softmod(atan(p.z,p.x)/3.14159*32.+time*2., 12.*s);
    float c2 = softmod((l+p.y)*4., 6.*s);
    float c = l>.95 || l > 1e4 ? 1.
        : min(c1+c2,2.-c1-c2);
    glFragColor = vec4(c * gr * log((p.y+fh)*fs)/log((fh-f0)*fs));
}
