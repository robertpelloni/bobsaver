#version 420

// original https://www.shadertoy.com/view/Nl3XD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

vec2 thc(float a, vec2 b) {
    return tanh(a * cos(b)) / tanh(a);
}

vec2 ths(float a, vec2 b) {
    return tanh(a * sin(b)) / tanh(a);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

vec2 rot(vec2 uv, float a) {
    //float s = 2. + cos(a + time);
    //mat2 m = mat2(thc(s,a), ths(s,a), -ths(s,a), thc(s,a));

    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    return m * uv;
}

void main(void)
{
    vec2 uv2 = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    float r = 0.3;
    float s = 0.;
    
    // not consistently using this (given up on keeping things tidy)
    float time = 0.3 * time;
       
    for (float i = 0.; i<20.; i++ ) {
        float n = i / 8. * pi ;
        vec2 uv = rot(uv2, i * 10. + time * (0.1 + i / 40.));
        
        //--
        vec2 p = vec2(r * cos(time) * cos(4. * uv.y), 0.);

        float k = 0.5 * thc(1., time) + 3.;
   

        float y = k * uv.y;
    
        float m = 0.08;
        float se = smoothstep(-m, m, 1. - y) * smoothstep(-m, m, y + 1.);
        //--
        
        
        // circle equation
        float a = mod(y + 1., 2.) - 1.;  
        float b = pow(a, 2.);
        float c = cos(n + time) * sqrt(1. - b);
        float c2 = cos(pi + n + time) * sqrt(1. - b);

        float d = abs(uv.x - 1./k * c);//abs(uv.x - 0.4 * cos(time) * cos(10. * uv.y));
        float d2 = abs(uv.x - 1./k * c2);
   
       
        float k2 = 0.4 + 0.4 * thc(2., 0.1 * i + 4. * uv.y + time);
        
        k2 = 0.4 + 4. * pow(cos(10. * i + uv.y - time), 11.);
        k2 *= 0.2;//0.3 + 0.1 * cos(time + 10. * i);
       
        float s1 = smoothstep(-k2, k2,        
        -d + 0.012 * (1. - 0.5 * thc(4., 20. * uv.y - 10. * n - 8. * time)) );
        s1 -= smoothstep(-0.01,0.01, -d + 0.005 * (1. - 0.5 * thc(4., 20. * uv.y - 10. * n - 8. * time)) );
        s1 *= 3. * s1 * s1 * se;
          
        float s2 = smoothstep(-k2, k2,        
        -d2 + 0.012 * (1. - 0.5 * thc(4., 20. * uv.y - 10. *  n - 8. * time)));
        s2 -= smoothstep(-0.01,0.01, -d2 + 0.005 * (1. - 0.5 * thc(4., 20. * uv.y - 10. *  n - 8. * time)));
        s2 *= 3. * s2 * s2 * se; // 3. * s1 * s2 * se;
        
        s += (s1 + s2) * 0.5 * (1. + thc(4., i + 4. * time));
    }
    
    s = clamp(s, 0., 1.);
    vec3 col = vec3(s);
    col += .25 * s * pal(2. * s + 0.1 * time, vec3(1.), vec3(1.), vec3(1.), 0.5 * vec3(0.,0.33,0.66));
    col += vec3(0.025,0.,0.05);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
