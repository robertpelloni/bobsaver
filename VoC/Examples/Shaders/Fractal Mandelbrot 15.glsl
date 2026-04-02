#version 420

// original https://www.shadertoy.com/view/fdyXDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void rotate(inout vec2 p,float angle,vec2 rotationOrigin)
{
    p -= rotationOrigin;
    p *= mat2(cos(angle),-sin(angle),sin(angle),cos(angle));
    p += rotationOrigin;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    float modtime = sin(time/10.+4.71238)*15.+15.;
    float tcubed = modtime*modtime*modtime;
    
    vec2 zv = vec2(0.729, 0.14);
    vec2 uv = (gl_FragCoord.xy)/resolution.xy / vec2(resolution.y / resolution.x, 1.) - vec2(0.5, 0);
    rotate(uv, length(uv)*(modtime/15.), vec2(0., 0.));
    rotate(uv, modtime, vec2(0.5,0.5));
    uv = vec2((uv.x-zv.x)/(tcubed+1.)+zv.x, (uv.y-zv.y)/(tcubed+1.)+zv.y);

    vec2 mbv = vec2((uv.x*2.47-2.), (uv.y*2.24-1.12));
    vec2 v = vec2(0);
    int iter = 0;
    int maxiter = int(modtime*10.+100.);
    
    while(v.x*v.x + v.y*v.y <= 4. && iter < maxiter){
        float xtemp = v.x*v.x - v.y*v.y + mbv.x;
        v = vec2(xtemp, 2.*v.x*v.y + mbv.y);
        iter++;
    }
    
    vec3 col = vec3(hsv2rgb(vec3(float(iter)/200.+modtime+0.66, 1., 1.)));
    //if(iter == maxiter) col = vec3(0);

    //col = vec3(fract(uv.xy*17.), col.b);
    
    glFragColor = vec4(col,1.0);
}
