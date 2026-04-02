#version 420

// original https://www.shadertoy.com/view/stdGDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float customsin(float x, float offset){
    //sin function
    //float amp = 0.3;
    //float pi = 3.1415926;
    //float y = 0.2*amp * cos((x+offset)*pi*3. + time*2.) + 0.5*amp + 0.25;
    
    //noise fuction
    float y = 0.;
    float xo = x + offset;
    float amplitude = 1.;
    float frequency = 3.;
    y = sin(x * frequency);
    float t = time*1.;
    y += sin(xo*frequency*3. + t)*4.5;
    y += sin(xo*frequency*1.72 + t*1.121)*4.0;
    y += sin(xo*frequency*2.221 + t*0.437)*5.0;
    y += sin(xo*frequency*3.1122+ t*4.269)*2.5;
    y *= amplitude*0.01;
    y += 0.3;
    
    return y; 
}

vec3 wavegraph(vec2 uv){
    float y = customsin(uv.x, 0.);
    y = smoothstep(y, y+0.005, uv.y);
    vec3 col = vec3(y);
    return col;
}

vec3 circle(vec2 uv, float x, float size){
    //calculate y axis value
    float offset = 0.01;
    float y = customsin(x, 0.);
    float prey = customsin(x, offset);
    
    //calculate normal
    vec3 pos = vec3(x, y, 0.);
    vec3 prepos = vec3(x+offset, prey, 0.);
    vec3 dir = prepos - pos;
    vec3 normal = -1.*normalize(cross(dir,vec3(0.,0.,1.)));
    
    //use normal to assign value of offset
    pos += normal * size;
    float len = length(pos - vec3(uv.xy, 0.));
    float s = smoothstep(size, size+0.005, len);
    vec3 col = vec3(s);
    return col;
}

void main(void)
{   
    float scale = resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= scale;
    
    float xpos = 0.5 * scale;    
    float ys = customsin(uv.x, 0.);   
    vec3 s = wavegraph(uv);
    vec3 c = circle(uv, xpos, 0.02*sin(time*2.)+0.02+0.04);    
    vec3 col = c*s;

    glFragColor = vec4(col,1.0);
}
