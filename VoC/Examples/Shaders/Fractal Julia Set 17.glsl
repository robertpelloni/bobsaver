#version 420

// original https://www.shadertoy.com/view/Nd2cWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based on https://www.shadertoy.com/view/WlcXR4

const float PI=3.14159;
const float TAU=6.28318;
vec2 f(vec2 x, vec2 c) {
    return mat2(x,-x.y,x.x)*x + c;
}

vec3 palette(float loc, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b*cos( TAU*(c*loc+d) );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;uv *= 1.3;uv += 0.5;
    vec4 col = vec4(1.0);
    float time = time;
    
    int u_maxIterations = 200;
    
    //select a point along the cartoid for C
    float angle = mod(time/3.,TAU*2.);
    bool type1 = true;
    
    vec2 c = vec2(-1,0);
    if (angle < PI){type1 = false;}
    if (angle > TAU+PI){type1=false;}
    float a = mod(angle,TAU);
    
    if (type1==true){c = vec2(cos(a),sin(a))/2.01 - vec2(cos(a*2.),sin(a*2.))/4.02;}
    else{c = vec2(cos(PI-a)/4.01-1.,sin(PI-a)/4.01);}
    
    vec2 z = vec2(0.);
    z.x = 3.0 * (uv.x - 0.5);
    z.y = 2.0 * (uv.y - 0.5);
    bool escaped = false;
    int iterations;
    float sum = 0.;
    float closest=1000.;
    for (int i = 0; i < u_maxIterations; i++) {
        //if (i > u_maxIterations) break;
        iterations = i;
        z = f(z, c);
        sum += max(0.,1.5 - length(z));
        float zangle=atan(z.x, z.y);
        
        float zdist = length(z);
        
        
        closest = min(closest, min(abs(cos(zangle+a)*zdist), abs(sin(zangle+a)*zdist)));
        
        if (dot(z,z) > 4.0) {
            escaped = true;
            //break;
        }
    }
            
    vec3 iterationCol = vec3(palette(closest/2., vec3(0.5),vec3(0.5),vec3(1.0, 1.0, 0.0),vec3(0.3, 0.2, 0.2)));
        
    vec3 coreCol = vec3(palette(sum/10., vec3(0.5),vec3(0.5),vec3(1.0, 1.0, 1.0),vec3(0.3, 0.2, 0.2)));
    
    float f_ite = float(iterations);
    float f_maxIte = float(u_maxIterations);
    glFragColor = vec4(escaped ? iterationCol : coreCol, f_ite/f_maxIte );
}

