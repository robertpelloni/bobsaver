#version 420

// original https://www.shadertoy.com/view/fdB3WW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCTAVES 5
#define SIZE 0.75

float hash12(vec2 p) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}

float smoother(float f){
    return f * f * f * (f * (f * 6. - 15.) + 10.);;
}

// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);    
    vec3 u = f*f*(3.0-2.0*f);
    
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
    float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
    float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
    b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
    d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
}

float fbm(vec3 p, int oct)
{
    float r = 0.0;
    float w = 1.0, s = 1.0;
    float d = 0.0;
    for (int i=0; i<oct; i++)
    {
        w *= 0.9-r*.35;
        s *= 2.0;
        r += w * abs(-1.+ 2. *noise_3(s * p + dot(vec3(d,0.25,0.),p+r*d)));
        d +=w;
    }
    float noise = -1.+2.*r/d;
    noise = smoother(noise*noise);
    return p.x>noise?1.-noise:noise;
}

void main(void)
{
    // Normalized pixel&mouse coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 mouse = (2.*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
    
    // Get noises
    vec3 np = vec3(uv,mouse.y+time*.05)*SIZE;//mouse*resolution.xy.y/resolution.y +time*.05
    vec2 offset = vec2(1.0/resolution.y,0.);
    
    float cnt = fbm(np, OCTAVES);
    vec3 norm = vec3(fbm(np+offset.xyy,OCTAVES)-cnt,fbm(np+offset.yxy,OCTAVES)-cnt, 0.05);
    norm = normalize(norm);
     
    // Lighting and Rendering 
    vec3 lit = normalize(vec3(mouse,.9)-vec3(uv,.5));
    vec3 cam = normalize(vec3(uv,0.)-vec3(0.,0.,1.));
    float refl = pow(max(0.,dot(cam,reflect(lit, norm))),20.);
    vec3 col = vec3(dot(lit,norm) * mix(vec3(1.,0.75,0.02),vec3(0.5,0.8,1.0), cnt)+refl);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
