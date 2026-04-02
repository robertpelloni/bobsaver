#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141519

float rmax = 1.;
float rmin = 0.5;
float points = 5.0;

float extremelyFast1dNoise(float v){
    return cos(v + cos(v * 90.1415) * 100.1415) * 0.5 + 0.5;
}
 

// shader just before compiled with this one 
void main( void ) {
    
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 st = surfacePos*3.;
    vec2 p= 1000.+( gl_FragCoord.xy / resolution.xy ) / 200.0 + time*0.0005;
    glFragColor = vec4(0);
    for(float i = 0.; i <= 1.; i += 1./3.){
        float angle = atan(st.y, st.x);
        float r = length(st*1.5);
    
        float pointangle = PI * 2.0 / points;
        
        float a = mod(angle-time, pointangle) / pointangle;
        a = a < 0.5 ? a : 1.0 - a;
        
        
        vec2 p0 = rmax * vec2(cos(0.0), sin(0.0));
        vec2 p1 = rmin * vec2(cos(pointangle / 2.0), sin(pointangle / 2.0));
        vec2 d0 = p1 - p0;
        vec2 d1 = r * vec2(cos(a), sin(a)) - p0;
        
        float isin = step(0.0, cross(vec3(d0, 0.0), vec3(d1, 0.0)).z);
        
        glFragColor = max(glFragColor, vec4(vec3(isin), 1.0));
        
        float ww = angle - mod(angle+time, (points+2.886140)/(PI * 2.0));
        float ph = -PI*0.8 + ww;
        st += (rmax+rmin-.3333)*vec2(cos(ph), sin(ph));
        float zz = 3.14/points;
        st *= 3.*mat2(cos(zz), sin(zz), -sin(zz), cos(zz));
    }
    
    if(glFragColor.r > 0.){
        glFragColor = vec4(extremelyFast1dNoise(p.x*p.y)*2.,extremelyFast1dNoise(p.y*p.x),.0,1);
    }else{
        glFragColor = vec4(1,.99,.99,1);
    }
}
