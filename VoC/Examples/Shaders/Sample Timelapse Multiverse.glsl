#version 420

// original https://www.shadertoy.com/view/wl2XDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float EPSILON = 0.0001;

vec3 light( vec3 ray,vec3 lightPos,vec3 color) {
    vec3 f = fract( ray ) -0.5;
    vec3 normf = normalize(f);
    vec3 light = lightPos-ray;
    float lighting = normf.x*light.x+normf.y*light.y+normf.z*light.z;
    lighting=lighting<0.0?0.0:lighting;
    float l2 = length(light);
    float brightness = 6.0f;
    return brightness*lighting/pow((l2+0.30),2.5)*color;
}

void main(void) {
    vec2 pos = (gl_FragCoord.xy*2.0 - resolution.xy) / resolution.y;
    float time = time * 0.2f;
    float t = time+0.1;
    
    //camera
    vec3 camPos = vec3(cos(time*0.5), sin(time*0.5), -time*0.5);
    vec3 camTarget = vec3(cos(t*0.5), sin(t*0.5), -t*0.5);
    vec3 camDir = normalize(camTarget-camPos);
    vec3 camUp  = normalize(vec3(0.0, 1.0, 0.0));
    vec3 camSide = cross(camDir, camUp);
    camUp  = cross(camDir, camSide);
    vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*1.5);
    
    vec3 lightPos = camTarget;
    
    //raymarching
    vec3 ray = camPos;
    float cr = 0.2;//circle radius
    bool end = true;
    for(int i=0; i<100; ++i) 
    {
        vec3 c = vec3(1,1,1);
        vec3 q = mod(ray,c)-0.5f*c;
        float d_min = length(q)- cr;
        
        
        if ((d_min<EPSILON)&&(dot(ray-camPos,camDir)>0.0))
        {
            end = false;
            break;
        }
        
        //This does the crazy explody thing for some reason
        ray+=0.8*rayDir;
        ray+=sin(t*0.1)*rayDir;
        //ray+=d_min*rayDir;
    }

    vec3 sphereColor = vec3(0.4, 0.4, 0.8 ); 
    vec3 color = end?vec3(0.0,0.0,0.0):light(ray,lightPos,sphereColor);
    glFragColor = vec4( color*(1.0,1.0,1.0), 1.0 );
}
