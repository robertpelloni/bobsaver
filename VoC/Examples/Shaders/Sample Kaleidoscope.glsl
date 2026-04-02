#version 420

// original https://www.shadertoy.com/view/dlcGzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;

float atan2(in float y, in float x){
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

float d1(vec2 v, float rad){
    return abs(v.y * sin(rad) + v.x * cos(rad));
}

float d(vec2 v, int n, float ang){
    float t = atan2(v.y,v.x)+ang;
    t = t - floor((t+PI)/(2.0*PI))*2.0*PI;
    float a = -PI;
    for(int i = 0; i < n; i++){
        if(a < t && t < (a+PI*2.0/float(n))){
            float c = a + PI/float(n)+ang;
            return d1(v, c);
        }
        a += PI*2.0/float(n);
    }
    return d1(v, 0.0);
}

float range(float x, float a, float b){
    return step(a, x) * step(-b, -x);
}

void main(void)
{
    vec2 v = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.xx;
    float time = time * 2.0;
    float phase = 2.0*abs(cos(time));
    
    int N = 3;
    
    N = int(floor(3.0+(1.0+cos(time*0.1))*3.0/2.0));
    
    float m = 0.5/pow(abs(d(v, N, time*1.0) - 0.1*(1.0+cos(time))), 0.4);
    float l = d(v, N*2, 0.5*time);
    float n = length(v) * 0.3/pow(abs(d(v, N*2, time*0.4) - 0.08), 0.4);;
    m = m * (2.2-l) * (n+0.1);
    vec3 col = (0.4 + 0.1*cos(time+v.xyx+vec3(0,2,4)))*m + vec3(0.0,l,l*1.4);
    //col = vec3(0.8) * m;
    glFragColor = vec4(col,1.0);
}
