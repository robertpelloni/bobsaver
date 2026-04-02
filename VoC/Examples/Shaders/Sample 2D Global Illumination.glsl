#version 420

// original https://www.shadertoy.com/view/3ssXRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 12.
#define MinDistance 0.01
#define Samples 60.

mat2 r2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float hash(float seed)
{
    return fract(sin(seed)*43758.5453 );
}

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
        vec2(12.9898,78.233)))*
        43758.5453123);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}    

// from iq
float sdBox(vec2 p, vec2 b) {
    vec2 r = abs(p) - b;
    return min(max(r.x, r.y),0.) + length(max(r,vec2(0,0)));
    //vec2 d = abs(p) - b;
      //return length(max(d,0.0));
}  

// Smooth min function from IQ
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 lightColor = vec3(0);
float light(vec2 p) {
    lightColor = vec3(.6,.8,1.);
    float box = sdBox(p - vec2(1.,0), vec2(.2));
    float circle = sdCircle(p + vec2(1.,0), .2);
    if(box > circle) lightColor = vec3(1,.9,.8);
    return smin(box, circle, 1.);
}  

float centerBox(vec2 p) {
    p *= r2(time);
    float box = sdBox(p, vec2(.3)); 
    box = max(box, -sdCircle(p - vec2(0,.5), .49) + cos(time) * .02);
    box = max(box, -sdCircle(p - vec2(0,-.5), .49) + cos(time) * .02);
    return box;
}

vec3 objectColor = vec3(1,0,0);
int objectId = 0;
float scene(vec2 p) {
    objectId = 0;    
    float box = centerBox(p);
    float light = light(p);
    if(box > light) {
        objectId = 1;
        objectColor = vec3(0,0,1);
    }
    return min(box, light);
}    

// from iq
vec2 calcNormal(vec2 p) {
    float h = 0.0001;
    vec2 k = vec2(1,-1);
    vec2 n = normalize( vec2(scene(vec2(p.x + h, p.y)) - scene(vec2(p.x - h, p.y)),
                      scene(vec2(p.x, p.y + h)) - scene(vec2(p.x, p.y - h)))) ;    
    return n;
}

float march(vec2 ro, vec2 rd) {
    float t = 0.;
    for(float i=0.; i < MaxSteps; i++) {
        vec2 p = ro + t * rd;
        float dt = scene(p);
        if(dt < MinDistance) return t+0.00001;
        t += dt;
    }       
    return 0.;
}    

float seed = 0.;
void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*U-R)/R.y;
    vec3 col = vec3(0);

    for(float i=0.; i < Samples; i++) {
        
        float r = (i + random(uv + i + time)) / Samples * 2. * 3.1415;
        vec2 rd = vec2(cos(r), sin(r));
        vec3 sampleColor = vec3(0);
        
        float t = march(uv, rd);
        if(t > 0.) {
            vec2 p = uv + t * rd;
            float intensity = 1. / (t*t);
            
            // light
            if(objectId == 1) {
                sampleColor = lightColor;    
            }
            
            // box
            if(objectId == 0) {
                vec2 nor = calcNormal(p);
                vec2 rrd = reflect(rd, nor);
                float rt = march(p, rrd);
                
                if(rt > .0) {
                    if(objectId == 0) {
                        sampleColor = mix(sampleColor, lightColor, 0.5);
                    }
                }
            }
        }
        col += sampleColor;
    }        
    
    
    
    // cant figure out how to fix the 
    // center object color, so its hardcoded here
    if(centerBox(uv) < MinDistance)
        col = vec3(0.);
        // TODO: - sample it from a scene without the object iself
        //       - create a smooth map between the two lights, now it
        //         abruptly jumps because the other light is closer.
    
    

    // Output to screen
    O = vec4(col/Samples*2.,1.0);
    
    glFragColor = O;
}
