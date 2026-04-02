#version 420

// original https://www.shadertoy.com/view/WlfyR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

#define NUM_OCTAVES 4

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2. + shift;
        a *= 0.5;
    }
    return v;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main(void) {
    vec2 R = resolution.xy;
    vec2 st = gl_FragCoord.xy/R.xy;
    
    st -= 0.5;
    st*= time/12.;
    //float s = length(st-1.5);
    // st += st * abs(sin(u_time*0.1)*3.0);
    st.x *= R.x/R.y;
    st = rotate2d(1./length(st*1./(time+10.)/0.002)*(time+10.))*st;
    
    vec3 color = vec3(0.0);
    float cVal = 0.;
    int num = 5;
    for(int i = -2; i<3;i++){
        for(int j = -2; j<3;j++){
            cVal += fbm(st+ vec2(float(i)/R.x*4.,float(j)/R.y*4.)+ fbm(st+ vec2(float(i)/R.x*4.,float(j)/R.y*4.))*10. + time*0.5);
        }
    }
    
    //float val = fbm(st+ fbm(st)*10. + time*0.5);
    float val = cVal/25.;
    
    
    //color = vec3(0.666667,1,1);
    color = hsl2rgb(vec3(length(st)/val,0.5,val));
    
    vec3 c1 = vec3((139./255.),(69./255.),(19./255.));
    float wVal = smoothstep(0.5,0.0,val);
    //color = val*c1+wVal*length(st/time*12.);

    
    
    glFragColor = vec4(color,1.);
}
