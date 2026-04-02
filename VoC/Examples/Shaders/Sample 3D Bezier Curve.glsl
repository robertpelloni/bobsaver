#version 420

// original https://www.shadertoy.com/view/ss33D7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define E 2.718281828459

#define SAMPLE_SIZE 20

float t(){
    return pow(E,-1. * pow(2. * cos(time),2.));
}

float line(vec2 uv, vec3 p1, vec3 p2){
    float k = (p1.y-p2.y)/(p1.x-p2.x);
    float b = p1.y - k * p1.x;
    return k*uv.x + b - uv.y;
}

vec3 line_pos(float t, vec3 b0, vec3 b1, vec3 b2){
    return (1.-t)*(1.-t)*b0 + 2.*t*(1.-t)*b1 + t*t*b2;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    // Time varying pixel color
    vec3 col = vec3(0.8);
    
    
    vec3 b0 = vec3(0.25 + 0.1 * sin(time),0.25 + 0.1 * sin(time),0.5);
    vec3 b1 = vec3(0.8,0.5+ 0.1 * t(),0.7);
    vec3 b2 = vec3(1.15 + 0.1 * sin(time),0.15 + 0.1 * sin(time),0.9);
    
    vec3 b3 = vec3(0.5,0.75,-0.1);
    vec3 b4 = vec3(1.05,0.85 + 0.1 * t(),0.);
    vec3 b5 = vec3(1.4,0.6,0.1);
    
    vec3 b6 = vec3(0.7,0.6 + 0.1 * sin(time),-0.9);
    vec3 b7 = vec3(1.15,0.65+ 0.1 * t(),-0.7);
    vec3 b8 = vec3(1.5 + 0.1 * cos(time),0.4 + 0.1 * cos(time),-0.5);
    
    //draw line
    float d = abs(line(uv,b0,b1));
    if(d < 0.005 && uv.x>b0.x && uv.x<b1.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b1,b2));
    if(d < 0.005 && uv.x>b1.x && uv.x<b2.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b3,b4));
    if(d < 0.005 && uv.x>b3.x && uv.x<b4.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b4,b5));
    if(d < 0.005 && uv.x>b4.x && uv.x<b5.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b6,b7));
    if(d < 0.005 && uv.x>b6.x && uv.x<b7.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b7,b8));
    if(d < 0.005 && uv.x>b7.x && uv.x<b8.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b0,b3));
    if(d < 0.005 && uv.x>b0.x && uv.x<b3.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b3,b6));
    if(d < 0.005 && uv.x>b3.x && uv.x<b6.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b1,b4));
    if(d < 0.005 && uv.x>b1.x && uv.x<b4.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b4,b7));
    if(d < 0.005 && uv.x>b4.x && uv.x<b7.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b2,b5));
    if(d < 0.005 && uv.x>b2.x && uv.x<b5.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    d = abs(line(uv,b5,b8));
    if(d < 0.005 && uv.x>b5.x && uv.x<b8.x){
        col *= mix(col, vec3(0.1), smoothstep(-fwidth(d), fwidth(d), d));
    }
    
    // draw point
    float ps = 0.02;
    float r = length(uv-b0.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b1.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b2.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b3.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b4.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b5.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b6.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b7.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    r = length(uv-b8.xy);
    if(r<ps){
        col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
    }
    
    // traverse y axis
    float pm = 1./float(SAMPLE_SIZE);
    for(int i = 0; i<=SAMPLE_SIZE; i+=1){
        vec3 c0 = line_pos(pm*float(i), b0, b3, b6);
        vec3 c1 = line_pos(pm*float(i), b1, b4, b7);
        vec3 c2 = line_pos(pm*float(i), b2, b5, b8);
        
        // traverse x axis
        for(int j = 0; j<=SAMPLE_SIZE; j+=1){
            vec3 p = line_pos(pm*float(j), c0, c1, c2);
            r = length(uv-p.xy);
            if(r< 0.2 * ps){
                col *= mix(col, vec3(0.1,0.1,0.1), smoothstep(-fwidth(r), fwidth(r), r));
            }
        }
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
