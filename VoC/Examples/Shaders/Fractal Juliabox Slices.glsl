#version 420

// original https://www.shadertoy.com/view/ltlczH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void sphereFold(inout vec3 z, inout float dz) {
    float r2 = dot(z,z);
    if (r2 < 0.5) { 
        float temp = 1.0/0.5;
        z *= temp;
        dz*= temp;
    }
    if (r2 < 1.0) { 
        // this is the actual sphere inversion
        float temp = 1.0/r2;
        z *= temp;
        dz*= temp;
    }
}
 
void boxFold(inout vec3 z, inout float dz) {
    z = clamp(z, -1.0, 1.0) * 2.0 - z;
}

float map(in vec3 p, in vec3 c, inout vec4 C)
{
    float Scale = 0.5 * sin(time) + 1.5;
    float scalefactor = mix( 
        2.0*(Scale + 1.0f)/(Scale - 1.0f), 
        mix( 
            2.0, 
            1.0f, 
            step(-1.0f, Scale)
        ), 
        1.0f - step(1.0f, Scale)
    );
    
    scalefactor = 1.0;
    vec3 z = p * scalefactor;
    vec3 offset = c * scalefactor;
    C = vec4(1.e20);
    
    float dr = 1.0;
    float bailout = 100.0;
    for (int n = 0; n < 9; n++)
    {
        boxFold(z,dr);       // Reflect
        sphereFold(z,dr);    // Sphere Inversion

        z = Scale * z + offset;  // Scale & Translate
        dr = dr * abs(Scale)+1.0;

        float r2 = dot(z, z);
        if( r2 > bailout )
            break;
        
        C.xyz = min(C.xyz, abs(z));
        C.w = min(C.w, r2);
    }
    
    C.w = sqrt(C.w);
    
    if( dot(z, z) > bailout )
        C = vec4(0.0);
    
    float d = (length(z) - 1.732)/abs(dr);
    return d / scalefactor;
}
    
void main(void)
{
    vec2 p_uv = gl_FragCoord.xy / resolution.xy;
    
    float aspect_ratio = float(resolution.x) / float(resolution.y);
    p_uv = p_uv * 2.0 - 1.0;
    p_uv.x *= aspect_ratio;
    
    //p_uv = (p_uv * 2.0 - vec2(0.0));
    //p_uv = mod(p_uv, vec2(2.001)) - 1.005;
    
       vec3 color;
    vec3 p = vec3(p_uv, sin(time * 0.0));
    vec4 C = vec4(0.0);

    float angle_t = time * 0.5;
    float d = map(p, vec3(1.0 * cos(angle_t), 1.0 * sin(angle_t), 0.0), C);
    float s = dot(C.xyz, C.xyz) / C.w;
    
    color = vec3(0.5) + vec3(0.5) * cos(6.28318 * (vec3(1.0) * s + vec3(0.0, 0.1, 0.2)));
    
    glFragColor = vec4(color, 1.0);
}
