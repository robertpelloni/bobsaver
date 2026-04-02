#version 420

// original https://www.shadertoy.com/view/DljXDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// inspired by @zozuar tweets

mat2 rotate2D(float r) {
    return mat2(cos(r), -sin(r), sin(r), cos(r));
}

void main(void)
{
    vec2 r = resolution.xy;
    vec2 FC = gl_FragCoord.xy;
    float t = time;
    // saturation
    float a = 15.;
    float R = 0.;
    float S = 3.;
    vec2 n = vec2(0);
    vec2 q = n;
    vec2 N = q;
    mat2 m = mat2(0);
    
    vec2 uv = (FC-.5*r)/r.x;
    
    
    for (float j = 0.; j<8.;j++) {
        m=rotate2D(5.5*j);
        n*=m;
        q=uv*m;
        R=length(q+.1);
        q=vec2((log(R)*S*.5-t)*2.,atan(q.y,1.));
        q+=n*.5+q.y;
        a+=dot(sin(q),n);
        q=sin(q*1.3);
        n+=q*1.56;
        N+=q/S;
        N*=.6;
        S/=.99;
    }
    
    
    vec3 col = vec3(0);
    col+=(((.4-a*.04)+.2/length(N))*sqrt(R)*(3.6+sin(vec3(2,4,5)+a*.1)))*.34;
    
    col.rg += uv*.8;
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
