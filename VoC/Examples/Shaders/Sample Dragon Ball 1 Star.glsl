#version 420

// original https://www.shadertoy.com/view/XtyGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

vec2 rotate(vec2 p, float a)
{
    return mat2( cos(a), -sin(a), sin(a), cos(a) ) * p;
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

float fbm( vec2 p )
{
    float f = 0.0;

    f += 0.50000*noise( p ); p = m*p*2.02;
    f += 0.25000*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;

    return f/0.90;
}

float sdStar5(in vec2 p, in float r, in float rf)
{
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x,k1.y);
    p.x = abs(p.x);
    p -= 2.0*max(dot(k1,p),0.0)*k1;
    p -= 2.0*max(dot(k2,p),0.0)*k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf*vec2(-k1.y,k1.x) - vec2(0,1);
    float h = clamp( dot(p,ba)/dot(ba,ba), 0.0, r );
    return length(p-ba*h) * sign(p.y*ba.x-p.x*ba.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.0 - 1.0; 
    uv.x *= resolution.x / resolution.y;
    
    float r = length(uv);
    
    //bckg
    vec3 col = mix(vec3(1.,0.2,0.0), vec3(0.7,0.15,0.0), fbm((uv+time*0.3)*.5));
    
    
    //dark red border
    float t = smoothstep(0.8, 0.82, r);
    col = mix(vec3(0.8, 0.,0.), col, t);
    
    //yellow
    t = smoothstep(0.79, 0.8, r);
    vec3 noisedCol = mix(vec3(0.9,0.85,0.5), vec3(1.,0.9,0.5), fbm(uv));
    col = mix(noisedCol, col, t);
    
    //orange shadow
    t = smoothstep(0.75, 0.79, r);
    col = mix(vec3(0.85,0.37,0.0), col, t);
    
    //yellow highlight
    if(r<0.79)
    {
        float offsetedR = length(uv+vec2(0.2,-0.15));
        t = smoothstep(0.4, 1.5, offsetedR);
        t *= fbm(uv*0.3+vec2(time*0.5))*3.4; 
        col = mix(vec3(0.98,0.9,0.2), col, t);
    }
    
    //star
    noisedCol = mix(vec3(0.95,0.5,0.2), vec3(1.,0.5,0.2), fbm(uv*4.+vec2(0.2,0.7)));
    col = mix(col, noisedCol, smoothstep(0.1,0.,sdStar5(uv*vec2(8.,8.5)-vec2(0.,0.4), 2., .4)));
    
    //white highlights
    vec2 h1uv = ((uv+vec2(0.55-pow(uv.y,2.)*0.7,0.14))*vec2(1.7-uv.y*2.0,0.65));
    float offsetedR = length(h1uv);
    t = smoothstep(0.3, 0.25, offsetedR + fbm((uv+vec2(2.))*3.)*0.1);
    col = mix(col, vec3(1., 1., 0.9), t);
    
    h1uv = ((uv+vec2(0.35,-0.3))*vec2(10.,5.));
    offsetedR = length(h1uv);
    t = smoothstep(0.3, 0.1, offsetedR + fbm((uv+vec2(2.))*40.)*0.1);
    col = mix(col, vec3(1., 1., 0.9), t);
    
    h1uv = ((uv+vec2(0.25,-0.45))*vec2(2.,4.));
    offsetedR = length(h1uv);
    t = smoothstep(0.3, 0.2, offsetedR + fbm((uv+1.)*7.)*0.2);
    col = mix(col, vec3(1., 1., 0.9), t);
    
    vec2 rotuv = rotate(uv+vec2(-0.32,0.67), 0.49);
    h1uv = rotuv*vec2(1.8,9.);
    offsetedR = length(h1uv);
    t = smoothstep(0.24, 0.2, offsetedR + fbm((uv+2.)*10.)*0.1);
    col = mix(col, vec3(1., 1., 0.9), t);
    
    rotuv = rotate(uv+vec2(-0.53,0.52), 0.76);
    h1uv = rotuv*vec2(1.6,9.);
    offsetedR = length(h1uv);
    t = smoothstep(0.24, 0.2, offsetedR + fbm((uv+2.)*10.)*0.1);
    col = mix(col, vec3(1., 1., 0.9), t);
    
    
    col = pow(col,vec3(2.2));
    glFragColor = vec4(col,1.0);
}
