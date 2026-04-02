#version 420

// original https://www.shadertoy.com/view/td33Rl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float R(vec2 uv){
     return fract(sin(dot(uv ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 R2(vec2 uv){
    float a = R(uv);
    return vec2(a, R(vec2(a)));
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

void main(void)
{
    float t = time*2.;
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    uv *= mix(.8, 1., sin(t*.3)*.5+.5);
    uv += sin(t) * vec2(.01, .005) + cos(t*.5) * vec2(.02, .005);
    
    float a = sin(t*.05)*.5;
    float c = cos(a);
    float s = sin(a);
    mat2 rot = mat2(c, -s, s, c);
    uv *= rot;
    
    //3d illusion
    float div = (uv.y * mix(2.5, 2., sin(t*.1+cos(t*.2)*.8)*.5+.5) +1.) * 2.;
    uv /= div;
    
       float size = 25.;
    vec2 gv = fract(uv*size);
    vec2 id = floor(uv*size);
    
    //float minDist = 999.;
    vec3 col = vec3(.1);
    
    for(float x=-1.; x<2.; x++){
        for(float y=-1.; y<2.; y++){
            vec2 id = id +vec2(x,y);
            vec2 p = id/size + (sin(R2(id)*t)*.5+.5 )/size;
               float d = length(uv - p)*size;
           
            
            //minDist = d < minDist ? d : minDist;
            float lum = 1.-d/(1.5);
            col.xz += lum * R2(id);
        }
    }
    
    col *= mix(1., .3, dot(smoothstep(.1, 0., gv) + smoothstep(.9, 1., gv), vec2(1)));
    col *= clamp(1.+uv.y, 0., 1.);
    if(uv.y>.2){
        col *= 0.;
    }
    
    
    
    //vec3 col = vec3(1.-minDist/1.5);
    //col.x += mix(0., 1., step(.98, gv.x)+step(.98, gv.y));
     

    // Output to screen
    glFragColor = vec4(col, 1.);
}
