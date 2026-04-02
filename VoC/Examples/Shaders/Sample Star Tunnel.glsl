#version 420

//star tunnel, a somewhat happy accident in picking apart
//and trying to simplify the other starfield effect

uniform float time;  
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    const float stars    = 256.0;
    const float depth    = 256.0;
    const float skew    = 8.0;
    float gradient        = 0.0;
    float speed        = 64.0 * time; //negate to reverse
    
    vec2 pos        = (((gl_FragCoord.xy / resolution.xy)) - 0.5) * skew;
    vec2 pos_center        = pos - vec2(0.5);
    
    for (float i = 1.0; i < stars; i++)
    {
        //i * i will get a typical starfield effect
        float x = sin(i) * 256.0;
        float y = cos(i) * 256.0;
        float z = mod(i - speed, depth);
                
        vec2 blob_coord = vec2(x, y) / z;
        float fade     = (depth - z) / 512.0;        
        gradient     += ((fade / depth) / pow(length(pos_center - blob_coord), 1.5));
    }

    glFragColor = vec4(sin(pos.y)*gradient, sin(pos.x)*gradient, cos(pos.x*pos.y)*gradient, 1.0);
}
