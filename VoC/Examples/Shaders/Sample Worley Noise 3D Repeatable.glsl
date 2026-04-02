#version 420

// original https://www.shadertoy.com/view/3d3fWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hash33(vec3 p3) {
    vec3 p = fract(p3 * vec3(.1031,.11369,.13787));
    p += dot(p, p.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}

float worley(vec3 p, float scale){

    vec3 id = floor(p*scale);
    vec3 fd = fract(p*scale);

    float n = 0.;

    float minimalDist = 1.;

    for(float x = -1.; x <=1.; x++){
        for(float y = -1.; y <=1.; y++){
            for(float z = -1.; z <=1.; z++){

                vec3 coord = vec3(x,y,z);
                vec3 rId = hash33(mod(id+coord,scale))*0.5+0.5;

                vec3 r = coord + rId - fd; 

                float d = dot(r,r);

                if(d < minimalDist){
                    minimalDist = d;
                }

            }//z
        }//y
    }//x
    
    return 1.0-minimalDist;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;

    vec3 p = vec3(uv, time*0.1);
    // Time varying pixel color
    vec3 col = vec3(worley(p*2.0-1.0, 4.0));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
