#version 420

// original https://www.shadertoy.com/view/Xdy3RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 2016 Passion */

//Random function
float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

//Noise function
float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

//Fbm function
float fbm(vec2 n) {
    float total = 0.0, amplitude = 1.0;
    //n.x+=time;
    for (int i = 0; i < 5; i++) {
        total += noise(n) * amplitude;
        n += n;
        amplitude *= 0.5;
    }
    return total;
}

//2D Rotation
mat2 rot(float deg){    
    return mat2(cos(deg),-sin(deg),
                sin(deg), cos(deg));
        
}
//Main
void main(void) {
    
    //Center uv coordinates
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    float vinette = 1.-pow(length(uv*uv*uv*uv)*1.01,10.);
    uv.x *= resolution.x / resolution.y;
   
    //uv+=noise(.2*uv-time);
    float t = time*.75;
    
    const int numIter = 5;
    
    //The Fractal
    for(int i = 0; i<numIter; i++){
        
        uv*=rot(t*.16);
        uv = abs(uv) / dot(uv,uv);
        uv.x = abs(uv.x+cos(t*.6)*.5);
        uv.x = abs(uv.x-.8);
        uv = abs(rot(-t*.3)*uv);
        uv.y = abs(uv.y-.5);
        uv.y = abs(uv.y+.03+sin(t)*.25);
        
    }
    
    uv = abs(uv) / float(numIter);

    vec3 c1 = vec3(noise(uv*7.),
                   sin(fbm(uv*.6)), 
                   cos(fbm(uv*8.)));
    
    uv+=abs(.1*t+uv*2.23);
    
    vec3 c2 = vec3(cos(fbm(uv*8.+noise(uv*5.5))), 
                   cos(fbm(7.*uv)), 
                   cos(uv*6. - fbm(5.*uv)));
    //Mix and gama adjustments
    glFragColor = vec4(pow(mix( c1, c2, (noise(2.*uv))), vec3(1.0/0.5)) ,1.0)*vinette;
}
