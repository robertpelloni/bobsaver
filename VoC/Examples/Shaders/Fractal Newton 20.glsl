#version 420

// original https://www.shadertoy.com/view/ssBGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool aa = true; // antialiased. Change to false for better performance

vec2 cmul(vec2 a, vec2 b) { // complex multiplication
    return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}
vec2 cdiv(vec2 a, vec2 b) { // complex division
    float denom = (b.x*b.x+b.y*b.y);
    if (denom < 0.0000000001) denom = 0.0000000001; // avoid division by zero
    return vec2(a.x*b.x+a.y*b.y, -a.x*b.y+a.y*b.x) / denom;
}

vec2 fn(vec2 z) { // f(z) = z^3 - 1
    return cmul(z,cmul(z,z)) - vec2(1,0);
}
vec2 dfn(vec2 z) { // f'(z) = 3*z^2
    return cmul(vec2(3,0),cmul(z,z));
}

vec2 mobius(vec2 a, vec2 b, vec2 c, vec2 d, vec2 z) { // f(z) = (az + b)/(cz + d)
    return cdiv(cmul(a,z) + b, cmul(c,z) + d);
}

vec3 hsl2rgb( in vec3 c ) { // © 2014 Inigo Quilez, MIT license, see https://www.shadertoy.com/view/lsS3Wc
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

float gain(float x, float k) { // https://www.iquilezles.org/www/articles/functions/functions.htm
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}
float ease(float wave, float k) {
    // map cos/sin wave to [0,1], apply the gain function, and map back to [-1,1]
    return gain(wave * 0.5 + 0.5, k) * 2. - 1.;
}

vec3 newton(vec2 z) { // iteratively apply z = z-f(z)/f'(z)
    vec2 prevZ = z;
    float i = 0.;
    float intensity = 0.;
    
    for (i=1.0; i<100.; i++) {
        z -= cdiv(fn(z),dfn(z));
        if (length(z-prevZ) < 0.0001) break;  
        
        // http://www.fractalforums.com/programming/smooth-colouring-of-convergent-fractals/msg33392/#msg33392
        intensity += exp(-length(z) - 0.5/(length(prevZ-z)));       
        
        prevZ = z;
    }
    
    float theta = atan(z.y,z.x);
    float angle = mod(theta/6.2832+1.0, 1.0);
    float hue = mod(angle + time/50.0, 1.0);
    
    return hsl2rgb(vec3(hue, 0.7, intensity/3.-0.2));
}

vec3 draw(vec2 z) {
    float speed = 0.03;
    // The transformation is very fast-moving in the middle, so squash the animation curve to keep it under control.    
    // squashFactor < 1.0 is a "rush in, slow in the middle, rush out" easing function.
    float squashFactor = 0.5; 
    
    return newton(mobius(
        vec2(1,0),
        vec2(0,0), // vec2(0.005*sin(time/6.),0),// adds some rotational movement
        vec2(0, 300.*ease(cos(time*speed), squashFactor)),
        vec2(1,0),
        z
    ));
}

void main(void) {
    float zoom = 10.;
    
    float samples = 0.;
    float sampStart = 0.;
    float sampEnd = 0.1;
    if (aa) {
        sampStart = -0.33;
        sampEnd = 0.34;
    }        
    
    vec3 color = vec3(0,0,0);
    
    for (float x=sampStart; x<sampEnd; x+=0.33) {
        for (float y=sampStart; y<sampEnd; y+=0.33) {
            vec2 pt = (2.*(gl_FragCoord.xy + vec2(x,y)) - resolution.xy)/resolution.y; // [-1,1] vertically    
            pt /= zoom;
            color += draw(pt);
            samples++;
        }
    }
    
    glFragColor = vec4(color/samples,1);
}
