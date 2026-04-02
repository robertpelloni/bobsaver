#version 420

// original https://www.shadertoy.com/view/Wl2XDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 toModArg( in vec2 z) {
    float modulus = sqrt(z.x*z.x + z.y*z.y);
    float argument = atan(z.y/z.x);
    
    return vec2(modulus, argument);
}

vec2 fromModArg( in vec2 z) {
    float a = z.x * cos(z.y);
    float b = z.x * sin(z.y);
    return vec2(a, b);
}

vec2 power( in vec2 z, in float p) {
    vec2 zma = toModArg(z);
    
    float zpm = pow(zma.x, p);
    float zpa = zma.y * p;
    vec2 zpma = vec2(zpm, zpa);
    
    return fromModArg(zpma);
}

float mandel( in vec2 coord){
    vec2 c = coord;
    vec2 z = c;
    
    for (float i=0.0; i<80.0; i+=1.0){
        vec2 zSquared = vec2(0, 0);
        zSquared.x = z.x*z.x - z.y*z.y;
        zSquared.y = 2.0*z.x*z.y;
        
        
        z = zSquared + c;
        
        float modZ = sqrt( z.x*z.x + z.y*z.y);
        
        if (modZ > 2.0){return i;}
    }
    
    return 80.0;
}

float mandelPow( in vec2 coord, in float p) {
    
    vec2 c = coord;
    vec2 z = c;
    
    for (float i=0.0; i<80.0; i+=1.0){
        vec2 zP = power(z, p);
        z = zP + c;
        
        float modZ = sqrt( z.x*z.x + z.y*z.y);
        
        if (modZ > 2.0){return i;}
    }
    
    return 80.0;
    
}

//NOT MINE::::
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    
    vec2 xy = vec2(0.0, 0.0);
    //bottomLeft = mouse*resolution.xy.xy / resolution.xx;
    float ytox = resolution.y / resolution.x;
    float xLen = 6.0;
    
    vec2 bottomLeft = vec2(-3.0, -0.5*xLen*ytox);
    
    
    xy.x = (gl_FragCoord.x/resolution.x)*xLen + bottomLeft.x;
    xy.y = (gl_FragCoord.y/resolution.y)*xLen*ytox + bottomLeft.y ;
    
    float iters = mandelPow(xy, 2.0 * sin(0.25*time));
    
    vec3 hsv = vec3(cos(80.0-iters), cos(80.0-iters), 0.5 );
    vec3 rgb = hsv2rgb(hsv);
    
    glFragColor = vec4(rgb.r, rgb.b, rgb.g, 1);
    
}
