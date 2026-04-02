#version 420

// original https://www.shadertoy.com/view/3l2XWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Timothy Michael Walsh */
mat2 r2(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(s, c, -c, s);
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
        vec2(12.9898,78.233)))*43758.5453123);
}

vec3 effect(vec2 uv, float zoomSpeed, float ringCount, float size, float rotationSpeed){
    float spacing = 1.3;
    vec2 id = floor(uv/spacing-.5); //*spacing;
    float rrr = random(id.yy);
    rrr *= rrr<.5 ? 1. : -1.;
    uv.x+=rrr*time*1.5;
    
    id = floor(uv/spacing-.5);
    uv = (fract(uv/spacing-.5)-.5)*spacing;
    
    float r = random(id);
    float rr = random(id);

    uv*=r2(rr*rotationSpeed*time+(sin(time*r)*3.*r));
    float s = length(uv)-size; //*(sin(time*zoomSpeed)*.5);
    
    float f = smoothstep(s-.005, s, .2935);
    f -= smoothstep(s,s + 0.005, .27);
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(r+rr+time+uv.xyx+vec3(r*f,3.-rr+r,r+1.)-time*2.);

    float a = atan(uv.x,uv.y);
    //f = f * step(a, sin(time-a*18.0)+cos(3.*time+a*18.0));
    f = f * smoothstep(f,  cos(a*(ringCount+(sin(time*2.*r)*8.*rotationSpeed*r))*sin(r+time)+cos(-time*11.75*rotationSpeed*rr)) +1., .02);   //+cos(time-s*10.)
   
    return col*f;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy)-.5;
    uv.x*=resolution.x/resolution.y;
    uv*=2.25;
    uv*=r2(sin(time/2.));
    uv *= 1.0 + dot(uv,uv)*.5;
    uv.x+=sin(time/5.)*13.;
    uv.y+=sin(time/5.5)*11.;
    
    vec3 col = effect(uv, 4., 11., .125, .75);
    col += effect(uv, 2.5, 8., .2, 1.);
    col += effect(uv, 1.5, 6., .25, 0.5);
    col += effect(uv, 0.5, 7., .34, 0.35);
    col += effect(uv, 0.25, 5., .081, 0.865);
    col += effect(uv, 0.25, 5., .03, 01.1865);
    
    
    //f = f * step(f,sin(a*12.));
    glFragColor = vec4(col,1.0);
}
