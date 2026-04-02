#version 420

// original https://www.shadertoy.com/view/WldyRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb(vec3 hsv){
    float h = hsv.x, s = hsv.y, v = hsv.z;
    float c = v * s;
    float x = c * (1.0 - abs(mod(h/(1.0/6.0), 2.0) - 1.0));
    float m = v - c;
    vec3 rgb;
         if(h < (1.0/6.0)){rgb = vec3(c,x,0.0);}
    else if(h < (2.0/6.0)){rgb = vec3(x,c,0.0);}
    else if(h < (3.0/6.0)){rgb = vec3(0.0,c,x);}
    else if(h < (4.0/6.0)){rgb = vec3(0.0,x,c);}
    else if(h < (5.0/6.0)){rgb = vec3(x,0.0,c);}
    else                  {rgb = vec3(c,0.0,x);}
    return rgb;
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

void main(void)
{
    float grid = 15.0;
    float speed = 1.0;
    float rate = 2.0;

    vec2 uv = gl_FragCoord.xy/resolution.xy * vec2(resolution.x/resolution.y,1.0) * grid;
    
    uv.x += time * grid / 5.0 * speed;
    
    float rand = random(floor(uv));
    
    uv = fract(uv);
        
    float radius = (1.0 + sin(time * rate + 100.0 * rand))/2.0;
    
    uv = uv * 2.0 - 1.0;
    
    float distance = sqrt(uv.x*uv.x + uv.y*uv.y);
    
    float circle = smoothstep(radius, radius - .03, distance);
    
    vec3 color = hsv2rgb(vec3(rand,1.0,1.0)) * circle;
    
    glFragColor = vec4(color,1.0);
}
