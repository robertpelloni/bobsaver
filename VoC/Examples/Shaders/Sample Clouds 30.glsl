#version 420

// original https://www.shadertoy.com/view/WdS3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 SKYCOLOR = vec3(119.0/255.0, 181.0/255.0, 254.0/255.0) * 0.75;
const vec3 CLOUDCOLOR = vec3(1.0,1.0,1.0);
const vec3 HASHSCALE3 = vec3(.1031, .1030, .0973);
const float SIMULATION_SPEED = 8.0;

//https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec2 randomVec2(in float i, in float j) {
    return vec2(i, j) + hash22(vec2(i, j));   
}

float worley(in vec2 uv, float scale)
{
    vec2 ij = floor(uv / scale);
    
    float minDist = 2.0;
    
    for(float x=-1.0;x<=1.0;x+=1.0) {
        for(float y=-1.0;y<=1.0;y+=1.0) {
            float d = length(randomVec2(ij.x+x, ij.y+y)*scale - uv);
            minDist = min(minDist, d);
        }
    }

    return 1.0 - minDist / scale;
}

float anim(float a, float p) {
    return (cos(time*6.283/p) * 0.5 + 0.5) * a;
}

float cloud(in vec2 uv) {

    float t = time * SIMULATION_SPEED;
    vec2 uv1 = uv + t*0.01;
    vec2 uv2 = uv + vec2(t*0.02, t*0.005);    
    
    float col[] = float[] ( worley(uv1, 0.1) * 0.00 + anim(0.05, 10.0),
                            worley(uv1, 0.2) * 0.15,
                            worley(uv1, 0.4) * 0.2 + anim(0.25, 10.0),
                            worley(uv1, 1.0) * 0.7,            
                            worley(uv2, 0.1) * 0.05,
                            worley(uv2, 0.2) * 0.15,    
                            worley(uv2, 0.4) * 0.2 - anim(0.5, 25.0),        
                            worley(uv2, 1.0) * 0.7);            

    float layer1 = 0.0;
    float layer2 = 0.0;    
    
    for(int l=0; l<4; l++) {
        layer1 += col[l];
    }

    for(int l=4; l<8; l++) {
        layer2 += col[l];
    }
    
    return pow(mix(layer1, layer2, 0.5), 1.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy) * vec2(resolution.x/resolution.y, 1.0);
    float cloudval = pow(cloud(uv), 1.0);
    vec3 color = mix(SKYCOLOR, CLOUDCOLOR, cloudval);
    
    glFragColor = vec4(color, 1.0);  
}
