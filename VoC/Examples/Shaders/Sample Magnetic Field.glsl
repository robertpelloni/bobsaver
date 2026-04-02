#version 420

// original https://www.shadertoy.com/view/ltKXDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 calcB(vec2 p)
{
    float R = 0.5;
    float y = p.x;
    float z = p.y;

    
    vec3 B = vec3(0.0);
    const float num = 360.0;
    float dtheta = 2.0*3.1415926/num;
    for (float i = 0.0; i < num; i+=1.0)
    {
        float theta = i*dtheta;
        vec3 l = vec3(-R*sin(theta), R*cos(theta), 0.0);
        vec3 r = vec3(-R*cos(theta), y - R*sin(theta), z);
        
        B += cross(l, r)/pow(length(r), 3.0) * dtheta*R;
    }
    
     return B*6.0;
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x /= resolution.y/resolution.x;
   
    if (length(uv - vec2(0.5, 0.0)) < 0.05) {
        glFragColor = vec4(1.0, 0.0, 1.0, 1.0);
    } else if (length(uv - vec2(-0.5, 0.0)) < 0.05) {
        glFragColor = vec4(0.0, 1.0, 1.0, 1.0);
    } else {
        vec3 B = calcB(uv);
        //float Bb = 5.0*sqrt(length(B)); // magnitude, looks nicer close to the coils
        float Bb = length(B); // magnitude
        //float Bb = B.y;       // y-component
        //float Bb = B.z;       // z-component
        Bb = sin(Bb*(0.7 + 0.5*sin(time))); // time varying color periodicity frequency, to make it pulse

        glFragColor = vec4(Bb, 0.0, -Bb, 1.0);
    }
    
    float m = 1.5;//(2.0*mouse*resolution.y/resolution.x-1.0)/(resolution.y/resolution.x);
    vec3 B0 = calcB(vec2(0.0, 0.0));
    vec3 B1 = calcB(vec2(0.0, uv.x));
    vec3 B2 = calcB(vec2(m, uv.x));
    //B2 = (B2 - B1)*10.0; // difference between expected value of calculated value due to offset
    
    if (uv.y+0.0 < 0.5*B2.z/B0.z && uv.y+0.02 > 0.5*B2.z/B0.z)
        glFragColor = vec4(0.0, 1.0, 0.0, 1.0);
    
}
